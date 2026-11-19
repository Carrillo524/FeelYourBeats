# 09 — Menú Principal, Selector de Canciones Reales, Caché de Charts, BGM/SFX Externos y Pantalla de Resultados

Este documento especifica el flujo completo de entrada, selección de pistas reales, caché persistente de charts, reproducción de música ambiental (BGM) y efectos de sonido (SFX) exclusivamente desde archivos externos, y la pantalla de resultados con sistema de rangos en letras (`D..SSS+`) y persistencia de récords en **FeelYourBeats (FyB)** sobre **Godot 4.7.2 Standard**, cumpliendo estrictamente `AGENTS.md`.

---

## 1. Caché Persistente de Charts y Récords (`core/chart/chart_cache_repository.gd`)

- **Clase y Capa:** `class_name ChartCacheRepository extends RefCounted` (Capa 1 `core/chart/`, completamente aislada de nodos de UI, VFX o gameplay).
- **Caché de Charts (`.tres` en `user://charts_cache/`):**
  - `func build_cache_key(p_audio_path: String, p_difficulty: int, p_note_type_mode: int) -> String`:
    - Genera un hash SHA-256 determinístico combinando `CACHE_SCHEMA_VERSION`, ruta normalizada del archivo, tamaño y timestamp de modificación (si existe en disco), dificultad y modo de notas.
  - `func load_cached_chart(p_key: String) -> ChartData`:
    - Verifica la cabecera `[gd_resource`, carga el `.tres` con `ResourceLoader.CACHE_MODE_IGNORE` y valida `chart.validate()["valid"] == true` y `chart.duration_sec > 0.0`.
    - Ante cualquier archivo corrupto o inválido, lo elimina silenciosamente y retorna `null`.
  - `func save_cached_chart(p_key: String, p_chart: ChartData) -> bool`:
    - Valida `p_chart`, crea `user://charts_cache/` si no existe y guarda el recurso con `ResourceSaver.save(...)`.
- **Integración en `GameSession.start_audio_file_session(...)`:**
  - Consulta primero `ChartCacheRepository.load_cached_chart(cache_key)`. Si hay caché válida, la carga directamente sin re-analizar el audio; si no, ejecuta `AudioAnalyzer.analyze_audio_stream(...)` + `AutoChartGenerator.generate_from_analysis(...)` y guarda el resultado en caché.
- **Persistencia de Récords (`user://song_records.cfg`):**
  - `func load_song_record(p_song_key: String, p_difficulty: int, p_note_type_mode: int) -> Dictionary`
  - `func load_best_rank_for_song(p_song_key: String, p_difficulty: int, p_note_type_mode: int) -> String`
  - `func save_song_record_if_better(p_song_key: String, p_difficulty: int, p_note_type_mode: int, p_rank: String, p_score: int, p_accuracy: float) -> bool`
  - Almacena `best_rank`, `best_score` y `best_accuracy` indexados por `(song_key, difficulty, note_type_mode)`.

---

## 2. Reproductores Externos sin Audio Sintetizado (`ui/`)

### 2.1. `MenuBgmPlayer` (`ui/menu_bgm_player.gd`)
- Escanea archivos externos `.ogg`, `.mp3` y `.wav` en `res://assets/bgm/` (carpetas versionadas con `assets/bgm/.gitkeep`, `assets/songs/.gitkeep` y `assets/sfx/.gitkeep`).
- **Cero síntesis por código:** Si `res://assets/bgm/` está vacía, entra en estado silencioso (`Sin BGM`) sin errores ni advertencias.
- **Control y Rotación:**
  - `is_auto_rotate: bool = true`: al finalizar una pista, avanza secuencialmente a la siguiente; en modo fijo (`false`), repite la pista actual.
  - Métodos públicos: `scan_tracks() -> PackedStringArray`, `select_track(p_index: int) -> bool`, `next_track() -> bool`, `prev_track() -> bool`, `set_auto_rotate(p_enabled: bool) -> void`, `stop_bgm() -> void`.
  - Se detiene limpiamente (`stop_bgm()`) antes de iniciar `GameSession`.

### 2.2. `UiSfxPlayer` (`ui/ui_sfx_player.gd`)
- Carga únicamente archivos externos en `res://assets/sfx/` de forma insensible a mayúsculas/minúsculas (`button_click.{ogg,wav,mp3}` y `cassette_insert.{ogg,wav,mp3}`, aceptando además cualquier variante cuyo nombre base comience por `cassette` como respaldo seguro), tolerando ausencia total sin sintetizar tonos ni emitir errores.
- Configura explícitamente `_click_player` y `_cassette_player` en el bus `&"Master"` con `volume_db = 0.0`.
- Conecta automáticamente `play_button_click()` a todos los botones de `MainMenu` y `SafeHud` (`PAUSA`, `REANUDAR`, `REINICIAR`, `RESULTADOS`, `REINTENTAR`, `MENÚ PRINCIPAL`).
- Reproduce `play_cassette_insert()` exclusivamente al pulsar **JUGAR** durante la transición de difuminado de `2.5 s` hacia `GameSession`.

---

## 3. Escala de Rangos `D..SSS+` y Pantalla de Resultados (`ui/safe_hud.gd`, `gameplay/hit_judge.gd`, `gameplay/game_session.gd`)

### 3.1. Función Estática `SafeHud.compute_letter_rank(p_accuracy_percent: float) -> String`
| Precisión (`accuracy %`) | Rango |
| :--- | :--- |
| `>= 100.0` | `SSS+` |
| `>= 95.0` | `SSS` |
| `>= 90.0` | `SS` |
| `>= 85.0` | `S` |
| `>= 80.0` | `A+` |
| `>= 75.0` | `A` |
| `>= 65.0` | `B` |
| `>= 50.0` | `C` |
| `< 50.0` | `D` |

### 3.2. Desglose de Juicios y Overlay de Resultados
- `HitJudge` contabiliza `perfect_count`, `great_count`, `good_count` y `miss_count` expuestos en `get_judgment_breakdown() -> Dictionary`.
- Al finalizar una canción (`DSPClock.playback_finished`) o desde el botón `RESULTADOS` en el menú de Pausa:
  - `GameSession` presenta `SafeHud.show_results_overlay(...)` con la letra de rango en tamaño gigante (`124 px`) y color destacado por grado, puntaje final, accuracy %, combo máximo, desglose (`PERFECT / GREAT / GOOD / MISS`) y botones táctiles grandes (`>= 68 px`) para **REINTENTAR** y **MENÚ PRINCIPAL**.
  - Cuando la canción termina de forma natural (`playback_finished`), `GameSession` persiste automáticamente el mejor récord en `user://song_records.cfg`.

---

## 4. Menú Principal y Flujo `MainMenu <-> GameSession` (`ui/main_menu.gd` y `ui/main_menu.tscn`)

### 4.1. Jerarquía de `ui/main_menu.tscn` (creada vía servidor MCP de Godot)
Configurada como escena principal `application/run/main_scene="res://ui/main_menu.tscn"` en `project.godot`:
- `root` (`MainMenu`, `ui/main_menu.gd`)
  - `ReactiveBackground` (`vfx/reactive_background.gd`, full-bleed `PRESET_FULL_RECT`)
  - `ScreenSafeAdapter` (`platform/screen_safe_adapter.gd`)
  - `MenuBgmPlayer` (`ui/menu_bgm_player.gd`)
  - `UiSfxPlayer` (`ui/ui_sfx_player.gd`)
  - `AudioAnalyzer` (`core/audio/audio_analyzer.gd`)

### 4.2. Controles Táctiles Responsivos (1.5K / 20:9 / Moto Edge)
Toda la UI interactiva se ancla dentro de `SafeAreaContainer` adaptado a `ScreenSafeAdapter.get_hud_safe_rect()` con botones táctiles de al menos `64 px` de alto:
1. **Elegir canción del dispositivo:** Abre `FileDialog` nativo (`FILE_MODE_OPEN_FILE`, `ACCESS_FILESYSTEM`, `use_native_dialog = true`, filtros `*.mp3, *.ogg, *.wav`) y registra la pista en `user://recent_tracks.cfg`.
2. **Lista rápida scrollable:** Muestra la demo integrada (`128 BPM`), canciones en `res://assets/songs/` e historial reciente de `user://recent_tracks.cfg`, exhibiendo junto a cada pista su **mejor letra de rango** (`best_rank`) para la dificultad y modo seleccionados.
3. **Selectores de Dificultad y Modo de Notas:** `FÁCIL / NORMAL / DIFÍCIL` y `TAP + HOLD / SOLO TAP` (respetado también por `GameSession.start_demo_session(p_note_type_mode)`).
4. **Mini-control de BGM:** Muestra la pista actual, navegación anterior/siguiente (`<`, `>`) y conmutación `AUTO / FIJA`.
5. **Botón `JUGAR` con cortina de difuminado de `2.5 s` y blindaje anti doble toque:** En `_ready()`, `MainMenu` crea por código `_transition_fade_rect: ColorRect` negro full-rect en primer plano (`z_index = 100`, `modulate.a = 0.0`, `mouse_filter = Control.MOUSE_FILTER_IGNORE`). Al pulsar `JUGAR`:
   - Bloquea inmediatamente la entrada (`_play_button.disabled = true` y `_transition_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP`).
   - Detiene `MenuBgmPlayer` (`stop_bgm()`) y dispara `ui_sfx_player.play_cassette_insert()`.
   - Ejecuta un `Tween` suave de difuminado a negro (`modulate.a: 0.0 -> 1.0` durante `2.5 s`, `TRANSITION_FADE_DURATION_SEC`) mientras prepara el payload de sesión (mostrando `"Analizando pista..."` si no está cacheada sin interrumpir el reproductor del casete).
   - Solo al cumplirse el difuminado y los `2.5 s` completos (garantizando la reproducción íntegra de `cassette_insert`), transfiere la configuración vía `GameSession.set_pending_session(...)` y ejecuta `get_tree().change_scene_to_file("res://ui/game_session.tscn")`.
