# 06 — Capas VFX Reactivos, HUD Seguro y Escena Jugable Integrada (`vfx/`, `ui/`, `gameplay/`)

Este documento especifica la implementación de la **Capa 3 (`vfx/` y `ui/`)** y el orquestador de sesión **`GameSession`** (`gameplay/game_session.gd` + `ui/game_session.tscn`) de **FeelYourBeats (FyB)** en Godot 4.7.2 Standard, siguiendo las directrices de `AGENTS.md` y `specs/00_architecture_and_contracts.md`.

---

## 1. Separación Full-Bleed vs. Zona Segura en Pantallas 1.5K y Curvas

En cumplimiento con `AGENTS.md`:
1. **Full-Bleed (`ReactiveBackground` en `vfx/`):**
   - Configurado con `Control.PRESET_FULL_RECT` y `mouse_filter = Control.MOUSE_FILTER_IGNORE`.
   - Cubre el **100% del viewport activo** (incluyendo recortes de cámara frontal y bordes laterales curvos bajo `window/size/edge_to_edge=true`) para eliminar cualquier franja negra.
2. **Zona Táctil Centrada (`LaneField` en `gameplay/`):**
   - Posicionado sobre `play_rect` (100% del alto, centrado horizontalmente con `lateral_margin_ratio` + `safe_area` horizontal) para proteger contra toques fantasma con la palma en bordes curvos (Moto Edge) y conflictos con el gesto *Atrás* de Android.
3. **HUD Seguro (`SafeHud` en `ui/`):**
   - Su contenedor raíz usa `Control.PRESET_FULL_RECT` con `mouse_filter = Control.MOUSE_FILTER_IGNORE`, pero aloja todos los elementos visibles e interactivos dentro de `SafeAreaContainer`, cuyas coordenadas `position` y `size` se sincronizan exactamente con `hud_safe_rect` para esquivar la cámara frontal (*punch-hole* / *notch*) y la barra inferior de gestos.

---

## 2. VFX Reactivos por Señales (`vfx/reactive_backdrop.gdshader` y `vfx/reactive_background.gd`)

### 2.1. Parámetros `uniform` del Shader (`reactive_backdrop.gdshader`)
- `base_color_top: vec4` y `base_color_bottom: vec4`: Gradiente vertical base.
- `accent_color: vec4`: Color de realce rítmico.
- `beat_pulse: float` (`0.0..1.0`): Pulso disparado por `DSPClock.beat_pulsed` con decaimiento lineal en `_process`.
- `energy_level: float` (`0.0..1.0`) e `intensity_tier: int` (`0..3`): Nivel energético y tier discreto recibidos desde `DSPClock.intensity_changed(block)`.
- `lane_hit_energies: vec4`: Energía de destello por carril (`x = lane 0`, `y = lane 1`, `z = lane 2`, `w = lane 3`) modulada exclusivamente por `HitJudge.note_judged(lane, grade, error_ms, combo)`.
- **Halo Neón Difuminado Perimetral (`aspect_ratio`, `edge_glow_intensity`, `edge_glow_width`, `edge_drop_boost`, `edge_primary_color`, `edge_drop_color`):**
  - Calcula la distancia al borde corregida por `aspect_ratio` (`dist_y = min(UV.y, 1.0 - UV.y) / aspect_ratio`) para que los 4 bordes tengan exactamente el mismo grosor visual en pantallas 20:9 / 9:16, proyectando un halo neón difuminado multicapa hacia el interior y manteniendo el centro 100 % limpio y oscuro para máxima legibilidad.
  - **Base `0.0` en reposo:** sin brillo constante en los bordes; en silencio, con BGM apagado o entre golpes, `edge_glow_intensity` decae exponencialmente hasta `0.0` (borde completamente limpio e invisible).
  - **Impulsos por Beat:** cada golpe (`beat_pulsed` o pico transitorio de `bass_energy`) dispara un destello difuminado (`~0.42–0.58` en el BGM de `MainMenu` y `~0.50–0.68` en `GameSession`) con decaimiento exponencial rápido (`~160–220 ms` hacia `0.0`), latiendo únicamente al ritmo de los beats.
  - **Drops en `GameSession`:** cuando `AudioAnalyzer` detecta un *drop* (alta energía espectral + graves sostenidos o `intensity_tier >= 2`), eleva el pulso del borde (`0.85–1.0`), amplía `edge_glow_width` (`~0.21–0.25`) y vira el tono hacia magenta/dorado neón eléctrico, decayendo limpiamente de vuelta a `0.0` al finalizar el drop.

### 2.2. Aislamiento de Audio
- `ReactiveBackground` **no accede** a `AudioServer`, buses de audio ni buffers FFT; únicamente consume señales de `DSPClock` y `HitJudge`.

---

## 3. HUD Seguro, Tipografía 1.5K, Combo Dinámico Acotado y Flujo de Pausa (`ui/safe_hud.gd`)

- **Herencia:** `class_name SafeHud extends Control`
- **Señales:** `pause_requested()`, `resume_requested()`, `restart_requested()` y `main_menu_requested()`.
- **Propiedades Exportadas:** `screen_safe_adapter: ScreenSafeAdapter`, `hit_judge: HitJudge`, `dsp_clock: DSPClock`, `input_adapter: RhythmInputAdapter` y `reactive_background: ReactiveBackground`.
- **Tipografía y Controles para Pantallas 1.5K (`UiFontRegistry` en `ui/ui_font_registry.gd`):**
  - `SCORE` (`50 px`, `SCORE_FONT_SIZE`), `ACC` (`40 px`, `ACCURACY_FONT_SIZE`) y botón `PAUSA` (`38 px`, `212x82 px`) aplican explícitamente **`global_font.{ttf,otf}`** (`UiFontRegistry.get_global_font()`) además del `Theme` raíz (`get_tree().root.theme`).
  - `COMBO xN` (`52 px`, `COMBO_FONT_SIZE`) y etiqueta de juicio `PERFECT / GREAT / GOOD / MISS` (`48 px`, `JUDGMENT_FONT_SIZE`) usan exclusivamente **`combo_font.{ttf,otf}`** con borde oscuro nítido (`outline_size`) para máxima legibilidad sobre las notas.
  - En el overlay de Resultados (`ResultsOverlay` / `ResultsPanel`, ocupando `~90%` del ancho y `~84%` del alto de `hud_safe_rect` con estilo neón translúcido y bloques verticales equilibrados con `SIZE_EXPAND_FILL`): título de canción (`54 px`, `global_font`, `OVERRUN_TRIM_ELLIPSIS`), etiqueta `¡NUEVO RÉCORD!` (`40 px`, `global_font`), letra de rango gigante (`250 px`, **`rank_font.{ttf,otf}`** estilizada con `UiFontRegistry.apply_neon_rank_style()` — núcleo casi blanco luminoso, contorno saturado y halo radial difuminado con `shadow_offset = Vector2.ZERO` y `shadow_outline_size` ~`46 px`), métricas principales `SCORE / ACCURACY / COMBO MÁX` (`56 px`, `global_font`), desglose en `GridContainer` de **2 columnas (`2x2`)** (`46 px`, `global_font`, colores diferenciados por juicio: cian en `PERFECT`, verde en `GREAT`, ámbar en `GOOD`, rojo coral en `MISS`) y botones `REINTENTAR / MENÚ PRINCIPAL` (`50 px`, `global_font`, altura mínima `96 px` con borde neón interactivo).
  - Si falta cualquiera de los archivos `.ttf`/`.otf` en `res://assets/fonts/`, `UiFontRegistry` mantiene la fuente por defecto de Godot sin emitir errores ni advertencias.
- **Escala Progresiva Acotada, Rebote al Bombo y Auto-Fade de `1.0 s`:**
  - `COMBO xN` incrementa su escala base progresivamente con cada `+1` de combo desde `1.0x` hasta un **tope máximo estricto de `1.30x`** (`COMBO_MAX_SCALE`), sumando un micro-rebote en cada golpe de bombo (`ReactiveBackground.bass_kick_pulsed`) y un *pop* en `note_judged` y `hold_combo_ticked` sin superar jamás `1.30x`.
  - Su contenedor horizontal está acotado a `COMBO_MAX_WIDTH_RATIO = 0.44` (`<= 44%` del ancho jugable seguro, estrictamente menor que los 2 carriles centrales) con `clip_text = true` y `pivot_offset` centrado para no tapar las notas en caída.
  - Tras `1.0 s` (`HUD_AUTO_FADE_DELAY_SEC`) sin nuevas notas juzgadas ni retenciones *hold* activas, tanto `COMBO xN` como el texto de juicio se desvanecen suavemente (`modulate.a -> 0.0`).
- **Inicialización Inmediata en `_ready()`:**
  - Lee `screen_safe_adapter.get_hud_safe_rect()` de inmediato en `_ready()` y se suscribe a `safe_play_rect_changed`.
- **Flujo de Pausa, Cuenta Regresiva de 3 Segundos, Reinicio y Resultados:**
  - `PauseOverlay` contiene **exclusivamente** los 3 botones legítimos: **`REANUDAR`**, **`REINICIAR`** y **`MENÚ PRINCIPAL`** (sin atajo hacia Resultados).
  - `ResultsOverlay` y el guardado de récords (`save_song_record_if_better`) se disparan únicamente al finalizar naturalmente la reproducción de la pista (`DSPClock.playback_finished` -> `GameSession._on_playback_finished`). Si el total de notas juzgadas en `HitJudge` es `0` (`get_total_judged() <= 0`), la precisión devuelta es estrictamente `0.0%` (rango `D`), nunca `100.0%` (`SSS+`).
  - `open_pause_menu() -> void`: cancela cualquier cuenta regresiva activa, invoca `input_adapter.reset_input_state()` para liberar cualquier dedo o tecla retenida, llama a `dsp_clock.pause()`, muestra `PauseOverlay` y emite `pause_requested`.
  - `close_pause_menu_and_resume() -> void`: oculta `PauseOverlay`, deshabilita `PauseButton` durante el conteo y muestra `CountdownLabel` centrado dentro de `SafeAreaContainer` (`font_size = 110`, `mouse_filter = Control.MOUSE_FILTER_IGNORE`, `pivot_offset` centrado). Anima secuencialmente los pasos `3`, `2`, `1` durante `1.0 s` cada uno mediante un `Tween` de escala (`1.35 -> 1.0`) y opacidad manteniendo `DSPClock` en pausa; al concluir el `1`, oculta `CountdownLabel`, rehabilita `PauseButton`, invoca `dsp_clock.resume()` y emite `resume_requested`.
  - `request_restart() -> void` y `_exit_tree() -> void`: cancelan cualquier `Tween` activo de cuenta regresiva (`_cancel_resume_countdown()`), ocultan `CountdownLabel` y `PauseOverlay`, rehabilitan `PauseButton`, limpian `input_adapter.reset_input_state()` y (en el caso de `request_restart()`) emiten `restart_requested`.

---

## 4. Orquestador `GameSession` y Jerarquía de `ui/game_session.tscn`

### 4.1. Jerarquía de Escena (Generada vía Servidor MCP de Godot)
La escena principal `res://ui/game_session.tscn` (configurada como `run/main_scene` en `project.godot`) se construye con las herramientas del servidor MCP de Godot (`create_scene`, `add_node`, `save_scene`, `update_project_uids`) con la siguiente estructura:
- `GameSession` (`class_name GameSession extends Control`, nodo raíz)
  - `DSPClock` (`core/audio/dsp_clock.gd`)
  - `ScreenSafeAdapter` (`platform/screen_safe_adapter.gd`)
  - `RhythmInputAdapter` (`platform/rhythm_input_adapter.gd`)
  - `HitJudge` (`gameplay/hit_judge.gd`)
  - `ReactiveBackground` (`vfx/reactive_background.gd`)
  - `LaneField` (`gameplay/lane_field.gd`)
  - `SafeHud` (`ui/safe_hud.gd`)

### 4.2. Sesión Demo Integrada (`start_demo_session() -> void`)
- Construye un `ChartData` validado a `128.0 BPM` (`15.0 s` de duración) con 28 notas (*tap* y *hold*) distribuidas en los 4 carriles sin solapamiento y 4 bloques `IntensityBlock` contiguos que recorren los tiers `0`, `1`, `2` y `3`.
- Genera un stream `AudioStreamWAV` en memoria con pulsos de metrónomo a `128.0 BPM`, lo carga en `DSPClock` y `LaneField`, sincroniza `ScreenSafeAdapter` y arranca la partida.

### 4.3. Vista Previa en Escritorio (`window_width_override` / `window_height_override`)
- En `project.godot` (sección `[display]`), se definen `window/size/window_width_override=450` y `window/size/window_height_override=800`.
- Esto permite que al ejecutar la escena en Windows (`F5`) la ventana física quepa íntegramente en monitores horizontales conservando la relación 9:16 y el espacio lógico virtual de `1080x1920` escalado mediante `canvas_items` + `keep_width`, sin alterar el despliegue a pantalla completa nativa en dispositivos Android.

### 4.4. Protección del Gesto / Botón Atrás de Android (`NOTIFICATION_WM_GO_BACK_REQUEST` y `ui_cancel`)
- En `_ready()`, `GameSession` ejecuta `get_tree().set_auto_accept_quit(false)` para evitar cierres abruptos de la aplicación.
- Al recibir `NOTIFICATION_WM_GO_BACK_REQUEST` (o `ui_cancel` en escritorio), `handle_back_request()` aplica la máquina de estados:
  1. **Resultados abiertos (`safe_hud.is_results_overlay_open()`):** retorna directamente al selector de canciones del menú principal (`MainMenu.open_directly_to_selector = true` -> `res://ui/main_menu.tscn`).
  2. **Pausa abierta (`safe_hud.is_pause_menu_open()`):** reanuda la partida mediante `safe_hud.close_pause_menu_and_resume()` (cuenta regresiva 3-2-1).
  3. **Partida en curso (o cuenta regresiva activa):** abre el menú de **Pausa** (`safe_hud.open_pause_menu()`), equivalente a pulsar `PAUSA`.
