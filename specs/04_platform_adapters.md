# 04 — Adaptadores de Plataforma: Zona Táctil Segura y Entrada Unificada (`platform/`)

Este documento especifica la implementación de la **Capa 4 (`platform/`)** de **FeelYourBeats (FyB)** en Godot 4.7.2 Standard, siguiendo las directrices de `AGENTS.md` y `specs/00_architecture_and_contracts.md`.

---

## 1. Propósito y Aislamiento de Capa

La capa `platform/` abstrae las particularidades físicas del dispositivo Android (pantallas alargadas 20:9 / 1.5K con `edge_to_edge=true`, recortes de cámara frontal y pantallas con bordes curvos tipo Moto Edge) y unifica la entrada multitáctil móvil con el teclado de pruebas en escritorio (`D`, `F`, `J`, `K`).
- **Aislamiento Total:** Ningún script en `platform/` importa ni referencia nodos de `gameplay/`, `vfx/` ni `ui/`. La comunicación hacia las capas superiores ocurre exclusivamente mediante señales tipadas.

---

## 2. `ScreenSafeAdapter` (`platform/screen_safe_adapter.gd`)

### 2.1. Conversión de Píxeles Físicos a Coordenadas Virtuales del Viewport
Dado que el proyecto utiliza `stretch/mode="canvas_items"` y `stretch/aspect="keep_width"` sobre una base de diseño `1080x1920` con `window/size/edge_to_edge=true`:
1. `DisplayServer.get_display_safe_area()` y `DisplayServer.window_get_size()` reportan dimensiones en **píxeles físicos de pantalla** (`Rect2i`, `Vector2i`).
2. `get_viewport().get_visible_rect().size` reporta las **dimensiones virtuales activas** $(W_{\text{vp}}, H_{\text{vp}})$, donde $W_{\text{vp}} = 1080$ y $H_{\text{vp}}$ crece dinámicamente (p. ej. `2400` en pantallas 20:9) o se reduce en tablets.
3. Protegiendo contra división por cero en modo `--headless` (`window_size.x > 0 and window_size.y > 0`), los factores de conversión son:

$$s_x = \frac{W_{\text{vp}}}{W_{\text{win}}}, \quad s_y = \frac{H_{\text{vp}}}{H_{\text{win}}}$$

y los márgenes físicos del `safe_area` se proyectan al espacio virtual:

$$\text{safe\_left} = x_{\text{safe}} \cdot s_x, \quad \text{safe\_right} = (W_{\text{win}} - x_{\text{safe\_end}}) \cdot s_x$$

$$\text{safe\_top} = y_{\text{safe}} \cdot s_y, \quad \text{safe\_bottom} = (H_{\text{win}} - y_{\text{safe\_end}}) \cdot s_y$$

### 2.2. Cálculo de `play_rect` (Soporte Pantallas Curvas y Gesto *Atrás*)
- Ocupa el **100% del alto virtual** ($y = 0.0, h = H_{\text{vp}}$).
- Combina simétricamente el margen lateral configurable `lateral_margin_ratio` (`0.06` por defecto, acotado en `0.0..0.25`) con el `safe_area` horizontal escalado:

$$m_{\text{side}} = \text{clamp}\left(W_{\text{vp}} \cdot r_{\text{lateral}} + \max(\text{safe\_left}, \text{safe\_right}), \; 0.0, \; 0.35 \cdot W_{\text{vp}}\right)$$

$$W_{\text{play}} = W_{\text{vp}} - 2 \cdot m_{\text{side}}, \quad X_{\text{play}} = \frac{W_{\text{vp}} - W_{\text{play}}}{2}$$

- En una pantalla base `1080` sin recorte horizontal adicional y con `lateral_margin_ratio = 0.06`, cada borde lateral reserva `64.8 px`, dejando un `play_rect` centrado de `950.4 px` de ancho (`237.6 px` por cada uno de los 4 carriles).

### 2.3. Cálculo de `hud_safe_rect` (Protección de Cámara Frontal y Barra de Gestos)
- Desplaza el borde superior en $\text{safe\_top}$ (esquivando *punch-hole* / *notch* en modo `edge_to_edge=true`) y el borde inferior en $\text{safe\_bottom}$, respetando horizontalmente $\max(\text{safe\_left}, W_{\text{vp}} \cdot r_{\text{lateral}})$.

### 2.4. Contrato Público de `ScreenSafeAdapter`
- **Herencia:** `class_name ScreenSafeAdapter extends Node`
- **Señal:** `signal safe_play_rect_changed(play_rect: Rect2, hud_safe_rect: Rect2)`
- **Propiedades Exportadas:**
  - `@export_range(0.0, 0.25, 0.005) var lateral_margin_ratio: float = 0.06`
  - `@export var lane_count: int = 4`
- **Métodos Públicos:**
  - `func recalculate_layout() -> void`
  - `func get_play_rect() -> Rect2`
  - `func get_hud_safe_rect() -> Rect2`
  - `func get_lane_width() -> float`
  - `func get_lane_at_x(p_viewport_x: float) -> int` (devuelve `0..3` dentro de `play_rect`, o `-1` si cae fuera).

---

## 3. `RhythmInputAdapter` (`platform/rhythm_input_adapter.gd`)

### 3.1. Entrada Multitáctil Android (`InputEventScreenTouch`)
- **Coordenadas Directas en `canvas_items`:** En Godot 4 con `stretch/mode="canvas_items"`, el motor entrega `touch_event.position` ya escalado al espacio de coordenadas virtuales del `Viewport`, por lo que se utiliza directamente sin transformaciones redundantes.
- **Rastreo por Índice de Dedo (`touch_event.index`):**
  - Al presionar (`pressed == true`): verifica que `touch_event.position` caiga dentro de `play_rect` y obtiene el carril mediante `screen_safe_adapter.get_lane_at_x(touch_event.position.x)`. Si el toque ocurre en los márgenes curvos excluidos (`-1`), se ignora. Si es válido (`0..3`), asocia `_active_touches[touch_event.index] = lane` y emite `lane_input_pressed(lane, dsp_time_sec)`.
  - Al soltar (`pressed == false`): busca `touch_event.index` en `_active_touches`, elimina la entrada y emite `lane_input_released(registered_lane, dsp_time_sec)` para el carril originalmente presionado por ese dedo, incluso si el dedo se deslizó ligeramente fuera del carril durante un *hold*.

### 3.2. Limpieza de Estado ante Pérdida de Foco (`reset_input_state`)
- El método público `reset_input_state() -> void` está conectado automáticamente a `_notification(p_what: int)` cuando ocurre `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- Si el jugador minimiza la aplicación o cambia de ventana manteniendo uno o varios dedos presionados, `reset_input_state()` emite `lane_input_released` para cada toque activo y limpia `_active_touches.clear()`, evitando carriles bloqueados al regresar al juego.

### 3.3. Entrada de Teclado para Pruebas en PC (`InputEventKey`)
- Filtra estrictamente repeticiones automáticas del sistema (`if p_key_event.echo: return`) para no corromper notas sostenidas (*hold*).
- Mapea `KEY_D -> 0`, `KEY_F -> 1`, `KEY_J -> 2`, `KEY_K -> 3` y emite `lane_input_pressed` / `lane_input_released` con el timestamp actual de `DSPClock`.

### 3.4. Contrato Público de `RhythmInputAdapter`
- **Herencia:** `class_name RhythmInputAdapter extends Node`
- **Señales:**
  - `signal lane_input_pressed(lane: int, dsp_time_sec: float)`
  - `signal lane_input_released(lane: int, dsp_time_sec: float)`
- **Propiedades Exportadas:**
  - `@export var dsp_clock: DSPClock = null`
  - `@export var screen_safe_adapter: ScreenSafeAdapter = null`
- **Métodos Públicos:**
  - `func process_input_event(p_event: InputEvent) -> void`
  - `func reset_input_state() -> void`
