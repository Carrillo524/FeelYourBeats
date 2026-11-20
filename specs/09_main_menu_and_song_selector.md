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

### 3.1. Multiplicador de Velocidad Visual Recalibrado (`gameplay/lane_field.gd` y `gameplay/game_session.gd`)
- `LaneField.set_speed_multiplier(p_multiplier: int) -> void` (acepta `1`, `2`, `3`, `4`) escala `scroll_speed_px_per_sec = 550.0 * float(multiplier)` (`DEFAULT_BASE_SCROLL_SPEED_PX_PER_SEC = 550.0`), calibrando la curva a la mitad de la velocidad inicial:
  - `1x` (`550 px/s`): caída pausada y muy legible.
  - `2x` (`1100 px/s`): velocidad estándar cómoda.
  - `3x` (`1650 px/s`): punto dulce arcade rápido y legible.
  - `4x` (`2200 px/s`): velocidad alta para expertos sin perder legibilidad.
- Mantiene intacta la sincronización exacta con `DSPClock` y las ventanas de juicio (solo cambia el tiempo de anticipación visual / píxeles por segundo).
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
- Al finalizar `DSPClock.playback_finished`, `GameSession` guarda el mejor récord y el resumen de la canción en `user://song_records.cfg` y presenta el overlay de resultados proporcional (`~90%` ancho × `~84%` alto de `hud_safe_rect`) en `SafeHud` con rango gigante (`250 px` en `rank_font` con `UiFontRegistry.apply_neon_rank_style()`, núcleo casi blanco y halo neón difuminado radial `~46 px`), métricas a `56 px`, rejilla `2x2` de juicios a `46 px` coloreados por grado y botones de `96 px` (`50 px` de fuente).

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

### 4.2. Fondo Reactivo al BGM, Retorno Directo al Selector y Flujo de 2 Pantallas + Modal Flotante (1.5K / 20:9 / Moto Edge)
- **Fondo y Portada Reactivos al BGM (sin onda perimetral en bordes):** `MainMenu` configura `ReactiveBackground` en `BackdropMode.MENU` con **`perimeter_wave_enabled = false`** (la onda neón difuminada del borde es exclusiva de `GameSession`) y conecta `AudioAnalyzer` (`set_live_monitoring(true)` y `reactive_background.set_menu_bgm_active(true)` mientras el BGM está activo) para alimentar en cada frame `bass_energy`, `mid_energy`, `high_energy` y los picos de beat: el fondo, el título `FEEL YOUR BEATS` (`104 px`, `title_font`) y el botón flotante `JUGAR` (`82 px`, `global_font` con borde neón) pulsan visiblemente (`1.0x -> 1.14x` con brillo cian/blanco), volviendo a respiración ambiental suave al apagar el BGM.
- **Retorno Directo al Selector (`MainMenu.open_directly_to_selector`):** Cuando el jugador pulsa `MENÚ PRINCIPAL` desde Pausa o Resultados en `GameSession`, se establece `MainMenu.open_directly_to_selector = true` antes de cargar `res://ui/main_menu.tscn`, haciendo que `MainMenu` omita la portada y abra directamente la pantalla de pestañas/selector de canciones (reiniciando la bandera a `false`).
- **Pantalla 2 — Navegador con 3 Pestañas Superiores (`CANCIONES` | `IMPORTAR` | `AJUSTES`, `34 px`, `84 px` de alto) y Lámina Translúcida Blanquecina Unificada (`_content_sheet_panel`):**
  - Debajo de la barra de 3 pestañas, todo el contenido se aloja dentro de un único `PanelContainer` (`ContentSheetPanel`, `SIZE_EXPAND_FILL` horizontal y vertical hasta el margen inferior seguro, `clip_contents = true`) con máscara translúcida blanquecina (`StyleBoxFlat` relleno `Color(0.84, 0.92, 1.0, 0.12)`, borde sutil `Color(1.0, 1.0, 1.0, 0.26)` y esquinas redondeadas `22 px`) que deja ver el `ReactiveBackground` animado detrás.
  1. **`CANCIONES` e `IMPORTAR`:** `ScrollContainer` con `SIZE_EXPAND_FILL` y `VBoxContainer` con `separation = 0`, alojando únicamente las `N` filas de canción con altura fija idéntica (`SONG_ROW_HEIGHT_PX = 252.0 px` en resolución base `1080x1920`, llenando la altura vertical de pantalla con 5–6 pistas y manteniendo scroll táctil fluido si hay más). Sin nodos separadores sueltos entre pistas: cada fila `i < N - 1` integra en su propio `StyleBoxFlat` un borde inferior blanco translúcido (`border_width_bottom = 3`, `border_color = Color(1.0, 1.0, 1.0, 0.28)` y `content_margin = 0`), mientras que la última fila (`i == N - 1`) usa `border_width_bottom = 0`; el relleno es transparente en reposo (`Color(1.0, 1.0, 1.0, 0.0)`) y muestra un destello blanquecino suave (`Color(1.0, 1.0, 1.0, 0.14)`) en hover/presión sin alterar el grosor del borde inferior. Cada fila aplica un margen interior horizontal uniforme de `28.0 px` (`RowInnerMargin`) y `24.0 px` de separación (`RowContentHBox`) entre dos zonas no solapadas:
     - **Zona izquierda con carrusel condicional alineado a la izquierda (`RowTitleClip`):** contenedor `Control` con `clip_contents = true` y `SIZE_EXPAND_FILL` (alineado a `28.0 px` del borde izquierdo) que aloja una **única etiqueta** (`RowTitleLabel`, `38 px`, `global_font`) inicializada siempre en `position.x = 0.0`. Si `label_width <= clip_width`, el título permanece fijo en `position.x = 0.0` sin desplazarse; si `label_width > clip_width`, espera una pausa inicial de `1.2 s` en `x = 0.0`, se desliza suavemente hacia la izquierda hasta salir por completo del borde recortado y vuelve a entrar desde el borde derecho (`x = clip_width`) hasta regresar a `x = 0.0` repitiendo el ciclo limpio sin duplicarse.
     - **Zona derecha fija (`RowRankZone`):** separada `24.0 px` del área recortada del título, muestra la letra de rango grande (`58 px`, `rank_font`) estilizada con `UiFontRegistry.apply_neon_rank_style()` (núcleo casi blanco, contorno saturado y halo radial difuminado `~19 px`) acompañada de `· DIFICULTAD` (`30 px`, `global_font` brillante). En `IMPORTAR`, botón grande `IMPORTAR CANCIÓN DEL DISPOSITIVO` (`36 px`), separador lineal blanco y recientes con el mismo formato que abren el modal tras importar.
  2. **`AJUSTES`:** Integrado dentro de la misma lámina translúcida blanquecina (`_content_sheet_panel`), con etiquetas grandes (`36 px`), encendido/apagado de BGM (`38 px`), pista actual, `< ANTERIOR` / `SIGUIENTE >` y `MODO: AUTO / FIJA` separados entre secciones por líneas horizontales blancas (`Color(1.0, 1.0, 1.0, 0.24)`), persistidos al instante en `user://user_settings.cfg`.
- **Modal Flotante de Configuración y Sincronización Exacta del Casete:** Al tocar cualquier pista se abre el panel flotante centrado (`CERRAR` o toque fuera para cancelar) con título (`42 px`), récord con rango neón (`46 px` mediante `UiFontRegistry.apply_neon_rank_style()`), 3 grupos con resaltado activo permanente (`StyleBoxFlat` cian iluminado vs. oscuro atenuado, opciones a `36 px`) para **Dificultad**, **Modo de Notas** y **Velocidad (`1x..4x`)**, y botón grande **`JUGAR`** (`42 px`, `94 px` de alto):
  1. Bloquea la interacción de la UI, detiene `MenuBgmPlayer` y muestra `"ANALIZANDO PISTA..."` (cediendo `await get_tree().process_frame` para pintar el texto).
  2. Ejecuta primero la búsqueda en caché o análisis/generación del `ChartData` (dejándolo guardado en caché y listo en `GameSession.pending_session_config`).
  3. **Solo después** de tener el chart listo (sin congelamientos de CPU pendientes), dispara simultáneamente `ui_sfx_player.play_cassette_insert()` y el difuminado visual de `2.5 s` (`_transition_fade_rect` de `0.0 -> 1.0`), cambiando a `res://ui/game_session.tscn` al cumplirse los `2.5 s`.
- **Máquina de Estados del Gesto / Botón Atrás de Android (`NOTIFICATION_WM_GO_BACK_REQUEST` y `ui_cancel`):**
  - En `_ready()`, `MainMenu` invoca `get_tree().set_auto_accept_quit(false)` para interceptar la navegación atrás del sistema sin cerrar abruptamente la aplicación.
  - Al recibir `NOTIFICATION_WM_GO_BACK_REQUEST` (o `ui_cancel` en escritorio), `handle_back_request()` evalúa en orden estricto de prioridad:
    1. **Transición en curso (`_is_launching == true`):** ignora la petición para no interrumpir la carga ni el audio del casete (`2.5 s`).
    2. **Modal de salida abierto (`_exit_confirm_backdrop.visible`):** cierra el modal de confirmación de salida (equivalente a `CANCELAR`).
    3. **`FileDialog` de importación o modal flotante de canción visible:** cierra el diálogo/modal activo y devuelve al selector de canciones.
    4. **Cualquier otra vista (portada o pestañas `CANCIONES`, `IMPORTAR`, `AJUSTES`):** despliega el modal flotante neón translúcido `"¿SALIR DE FEEL YOUR BEATS?"` (`global_font`) con dos botones táctiles grandes (`CANCELAR` con `button_click` para cerrar el modal, y `SALIR` con `button_click`, detención limpia de `MenuBgmPlayer` y `get_tree().quit()`).

---

## 5. Registro Centralizado de Tipografías Externas por Rol (`ui/ui_font_registry.gd`)

`UiFontRegistry` (`class_name UiFontRegistry extends RefCounted`) escanea `res://assets/fonts/` de forma insensible a mayúsculas/minúsculas soportando `.ttf` y `.otf` (tolerando ausencia parcial o total sin errores) para asignar 4 roles estrictamente separados:

| Rol | Archivo en `res://assets/fonts/` | Aplicación Exclusiva |
| :--- | :--- | :--- |
| **Global** | `global_font.{ttf,otf}` | Fuente base del `Theme` raíz (`get_tree().root.theme`) para pestañas, listas, modal, botones, `SCORE`, `ACC`, `PAUSA` y explícitamente el botón flotante `JUGAR` de la portada (que nunca usa `title_font`). |
| **Título** | `title_font.{ttf,otf}` | Exclusivamente en `FEEL YOUR BEATS` (portada y encabezado del menú), con borde luminoso (`outline_size` / `font_outline_color`) y sombra sutil. |
| **Combo y Juicios** | `combo_font.{ttf,otf}` | Exclusivamente en `COMBO xN` y la etiqueta de juicio (`PERFECT`, `GREAT`, `GOOD`, `MISS`) en `SafeHud`, con borde nítido sobre las notas. |
| **Letras de Rango** | `rank_font.{ttf,otf}` | Exclusivamente en las letras de rango (`D`..`SSS+`), estilizadas con `UiFontRegistry.apply_neon_rank_style(label, rank, font_size)` (núcleo casi blanco, contorno saturado y halo radial difuminado con `shadow_offset = Vector2.ZERO` y `shadow_outline_size` proporcional al tamaño: `~19 px` en tarjetas de `58 px` y `~46 px` en Resultados de `250 px`), tanto en `ResultsOverlay` (`SafeHud`) como en las tarjetas y el modal de `MainMenu`. |
