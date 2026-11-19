# 09 — Menú Principal, Selector de Canciones Reales, Caché de Charts, BGM/SFX Externos y Pantalla de Resultados

Este documento especifica el flujo completo de portada, navegación por pestañas, selección de pistas reales, caché persistente de charts, reproducción de música ambiental (BGM) y efectos de sonido (SFX) exclusivamente desde archivos externos, velocidad de caída `1x..4x`, y pantalla de resultados con sistema de rangos en letras (`D..SSS+`) y persistencia de récords en **FeelYourBeats (FyB)** sobre **Godot 4.7.2 Standard**, cumpliendo estrictamente `AGENTS.md`.

---

## 1. Caché Persistente de Charts y Récords Unificados (`core/chart/chart_cache_repository.gd`)

- **Clase y Capa:** `class_name ChartCacheRepository extends RefCounted` (Capa 1 `core/chart/`, completamente aislada de nodos de UI, VFX o gameplay).
- **Normalización de Identificador de Canción:**
  - `static func normalize_song_key(p_audio_path: String) -> String`: garantiza que `MainMenu` y `GameSession` compartan exactamente el mismo identificador para la Demo Integrada (`"builtin://demo_128bpm"`), pistas en `res://assets/songs/` y archivos importados del dispositivo (normalizando separadores, mayúsculas/minúsculas y barras duplicadas).
- **Caché de Charts (`.tres` en `user://charts_cache/`):**
  - `func build_cache_key(p_audio_path: String, p_difficulty: int, p_note_type_mode: int) -> String`: hash SHA-256 determinístico combinando `CACHE_SCHEMA_VERSION`, clave normalizada, tamaño y fecha de modificación en disco, dificultad y modo de notas.
  - `func load_cached_chart(p_key: String) -> ChartData`: verifica la cabecera `[gd_resource`, carga el `.tres` con `ResourceLoader.CACHE_MODE_IGNORE` y valida `chart.validate()["valid"] == true` y `chart.duration_sec > 0.0`. Descarta silenciosamente archivos corruptos y retorna `null`.
  - `func save_cached_chart(p_key: String, p_chart: ChartData) -> bool`: valida `p_chart`, crea `user://charts_cache/` si no existe y guarda el recurso con `ResourceSaver.save(...)`.
- **Persistencia de Récords y Resumen por Canción (`user://song_records.cfg`):**
  - `save_song_record_if_better(...)` guarda el mejor récord específico por `(song_key, difficulty, note_type_mode)` y actualiza el resumen de la canción (`last_rank`, `last_difficulty`, `best_rank`, `best_difficulty`, `best_score`, `best_accuracy`).
  - `load_song_summary(p_song_key: String) -> Dictionary` entrega la insignia lista para renderizar junto a cada pista en el menú (p. ej. `[SSS · NORMAL]`, `[A+ · DIFÍCIL]`, o `[--]` si aún no se ha jugado).

---

## 2. Reproductores Externos sin Audio Sintetizado y Preferencias (`ui/`)

### 2.1. `MenuBgmPlayer` (`ui/menu_bgm_player.gd`)
- Escanea archivos externos `.ogg`, `.mp3` y `.wav` en `res://assets/bgm/` (carpetas versionadas con `assets/bgm/.gitkeep`, `assets/songs/.gitkeep` y `assets/sfx/.gitkeep`).
- **Cero síntesis por código:** Si `res://assets/bgm/` está vacía, entra en estado silencioso (`Sin BGM`) sin errores ni advertencias.
- **Encendido/Apagado y Persistencia en `user://user_settings.cfg`:**
  - `is_bgm_enabled: bool = true`, `set_bgm_enabled(p_enabled: bool) -> void`, `signal bgm_enabled_changed(p_enabled: bool)`.
  - Persiste y restaura automáticamente `bgm_enabled`, `auto_rotate` y `selected_track_name` en `user://user_settings.cfg` al modificar cualquier ajuste o iniciar la aplicación.
  - Emite audio por el bus `&"Master"` para alimentar en tiempo real a `AudioAnalyzer` mientras el BGM está activo.

### 2.2. `UiSfxPlayer` (`ui/ui_sfx_player.gd`)
- Carga únicamente archivos externos en `res://assets/sfx/` de forma insensible a mayúsculas/minúsculas (`button_click.{ogg,wav,mp3}` y `cassette_insert.{ogg,wav,mp3}`, aceptando cualquier variante cuyo nombre base comience por `cassette` como respaldo seguro), tolerando ausencia total sin sintetizar tonos ni emitir errores.
- Configura explícitamente `_click_player` y `_cassette_player` en el bus `&"Master"` con `volume_db = 0.0`.
- Conecta automáticamente `play_button_click()` a todos los botones de `MainMenu` y `SafeHud` (`PAUSA`, `REANUDAR`, `REINICIAR`, `RESULTADOS`, `REINTENTAR`, `MENÚ PRINCIPAL`).
- Reproduce `play_cassette_insert()` exclusivamente al pulsar **JUGAR** en el modal de canción durante la transición de difuminado de `2.5 s` hacia `GameSession`.

---

## 3. Velocidad de Caída `1x..4x`, Escala `D..SSS+` y Resultados (`gameplay/`, `ui/`)

### 3.1. Multiplicador de Velocidad Visual (`gameplay/lane_field.gd` y `gameplay/game_session.gd`)
- `LaneField.set_speed_multiplier(p_multiplier: int) -> void` (acepta `1`, `2`, `3`, `4`) escala `scroll_speed_px_per_sec = _base_scroll_speed_px_per_sec * float(multiplier)`, reduciendo proporcionalmente la ventana visual de anticipación y aumentando los píxeles por segundo **sin modificar el reloj DSP (`DSPClock`) ni los tiempos de impacto**.
- `GameSession` propaga `speed_multiplier` desde `pending_session_config` hacia `LaneField` tanto para canciones reales como para la demo integrada.

### 3.2. Función Estática `SafeHud.compute_letter_rank(p_accuracy_percent: float) -> String`
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

- `HitJudge` expone `get_judgment_breakdown()` (`PERFECT / GREAT / GOOD / MISS`).
- Al finalizar `DSPClock.playback_finished`, `GameSession` guarda el mejor récord y el resumen de la canción en `user://song_records.cfg` y presenta el overlay de resultados en `SafeHud`.

---

## 4. Menú Principal Rediseñado (`ui/main_menu.gd` y `ui/main_menu.tscn`)

### 4.1. Jerarquía de `ui/main_menu.tscn` (vía servidor MCP de Godot)
Configurada como `application/run/main_scene="res://ui/main_menu.tscn"` en `project.godot`:
- `root` (`MainMenu`, `ui/main_menu.gd`)
  - `ReactiveBackground` (`vfx/reactive_background.gd`, full-bleed `PRESET_FULL_RECT`)
  - `ScreenSafeAdapter` (`platform/screen_safe_adapter.gd`)
  - `MenuBgmPlayer` (`ui/menu_bgm_player.gd`)
  - `UiSfxPlayer` (`ui/ui_sfx_player.gd`)
  - `AudioAnalyzer` (`core/audio/audio_analyzer.gd`)

### 4.2. Fondo Reactivo al BGM y Flujo de 2 Pantallas + Modal Flotante (1.5K / 20:9 / Moto Edge)
- **Fondo Reactivo al BGM:** `MainMenu` conecta `AudioAnalyzer` (con `set_live_monitoring(true)` cuando el BGM está activado y tiene pistas) hacia `ReactiveBackground` para que el fondo y el título `FEEL YOUR BEATS` pulsen al ritmo del BGM, volviendo a la respiración ambiental suave cuando el BGM se apaga.
- **Pantalla 1 — Portada Minimalista:** Título grande `FEEL YOUR BEATS` (`72 px`) y botón flotante suspendido `JUGAR` (`50 px`, sin caja, con animación suave de pulso) que al tocarse reproduce `button_click` y entra a la Pantalla 2.
- **Pantalla 2 — Navegador con 3 Pestañas Superiores (`CANCIONES` | `IMPORTAR` | `AJUSTES`):**
  1. **`CANCIONES`:** Lista scrollable de la Demo Integrada y las pistas en `res://assets/songs/`, cada una con su insignia de récord (`[SSS · NORMAL]`, `[--]`) alineada a la derecha.
  2. **`IMPORTAR`:** Botón grande `IMPORTAR CANCIÓN DEL DISPOSITIVO` (`FileDialog` nativo `ACCESS_FILESYSTEM`, `*.mp3, *.ogg, *.wav`) + lista de pistas importadas recientes (`user://recent_tracks.cfg`) con sus insignias; al importar una pista nueva, se abre automáticamente su modal de configuración.
  3. **`AJUSTES`:** Encendido/apagado de BGM (`BGM: ACTIVADO / APAGADO`), nombre de pista actual, botones `< ANTERIOR` / `SIGUIENTE >` y `MODO: AUTO / FIJA`, persistidos al instante en `user://user_settings.cfg`.
- **Modal Flotante de Configuración de Canción:** Al tocar cualquier pista se abre un panel centrado sobre una capa atenuada (cancelable con `CERRAR` o tocando fuera) con:
  - Título de la canción y récord actual.
  - 3 grupos con resaltado activo permanente (`StyleBoxFlat` cian iluminado vs. oscuro atenuado):
    - **Dificultad:** `FÁCIL` | `NORMAL` | `DIFÍCIL`
    - **Modo de Notas:** `TAP + HOLD` | `SOLO TAP`
    - **Velocidad:** `1x` | `2x` | `3x` | `4x`
  - Botón grande **`JUGAR`** (`84 px` de alto): bloquea la UI (`_play_button.disabled = true` y `_transition_fade_rect.mouse_filter = MOUSE_FILTER_STOP`), detiene `MenuBgmPlayer`, dispara `cassette_insert`, anima el difuminado a negro de `2.5 s` mientras prepara el payload/análisis offline sin interrumpir el SFX y luego cambia a `res://ui/game_session.tscn`.
