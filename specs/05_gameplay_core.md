# 05 — Capa Gameplay: Juez de Precisión, Pool Determinístico de Notas y Campo de Carriles (`gameplay/`)

Este documento especifica la implementación de la **Capa 2 (`gameplay/`)** de **FeelYourBeats (FyB)** en Godot 4.7.2 Standard, siguiendo estrictamente las reglas de `AGENTS.md` y `specs/00_architecture_and_contracts.md`.

---

## 1. Propósito y Aislamiento de Capa

La capa `gameplay/` implementa el núcleo jugable de 4 carriles:
1. **`HitJudge` (`gameplay/hit_judge.gd`):** Evaluación de precisión temporal para notas simples (*tap*) y sostenidas (*hold*) con complejidad $O(1)$ amortizada por frame.
2. **`NoteView` (`gameplay/note_view.gd`):** Representación visual reutilizable (*Object Pooling*) de una nota cuya posición vertical `Y` es una función pura y determinística del reloj maestro DSP y de `hit_line_y` (cero acumulación de `delta`).
3. **`LaneField` (`gameplay/lane_field.gd`):** Contenedor responsivo de los 4 carriles que se ajusta a `play_rect` (respetando márgenes curvos), calcula dinámicamente `hit_line_y` según la altura virtual del viewport y coordina el ciclo de vida del pool de `NoteView`.

- **Aislamiento Total:** Ningún script en `gameplay/` importa ni referencia nodos de `vfx/` ni `ui/`. Las capas visuales y de interfaz se suscriben a las señales emitidas por `HitJudge`.

---

## 2. `HitJudge` (`gameplay/hit_judge.gd`)

### 2.1. Grados de Juicio y Ventanas Temporales
- `enum JudgmentGrade { PERFECT = 0, GREAT = 1, GOOD = 2, MISS = 3 }`
- Ventanas configurables por `@export`:
  - `perfect_window_sec: float = 0.045` ($\pm 45\text{ ms}$)
  - `great_window_sec: float = 0.090` ($\pm 90\text{ ms}$)
  - `good_window_sec: float = 0.140` ($\pm 140\text{ ms}$)
  - `miss_window_sec: float = 0.180` ($\pm 180\text{ ms}$)
  - `hold_release_grace_sec: float = 0.120` ($120\text{ ms}$ de tolerancia de liberación anticipada antes del final de una nota *hold*)

### 2.2. Máquina de Estados y Colas $O(1)$ por Carril (`0..3`)
Al invocar `load_chart(p_chart: ChartData) -> bool`, las notas se particionan en 4 colas independientes (`_lane_queues[0..3]`) con cursores enteros `_lane_cursors[0..3]`:
1. **`on_lane_pressed(p_lane: int, p_dsp_time_sec: float) -> void`:**
   - Expira primero cualquier nota rezagada (`p_dsp_time_sec > note.time_sec + miss_window_sec`) como `MISS`.
   - Evalúa la nota pendiente en `_lane_cursors[p_lane]`. Si `absf(p_dsp_time_sec - note.time_sec) > miss_window_sec`, ignora el toque temprano.
   - Si está dentro de `miss_window_sec`, clasifica el grado y avanza `_lane_cursors[p_lane]`.
   - Para notas *tap* (`not note.is_hold()`): marca la nota como resuelta y emite `note_judged` y `score_changed`.
   - Para notas *hold* (`note.is_hold()`): emite el juicio de la cabeza; si no fue `MISS`, activa `_active_holds[p_lane] = note` y emite `hold_state_changed(p_lane, true)`.
2. **`on_lane_released(p_lane: int, p_dsp_time_sec: float) -> void`:**
   - Si existe un *hold* activo en `p_lane`, lo cierra (`_active_holds[p_lane] = null`), marca la nota como resuelta, emite `hold_state_changed(p_lane, false)` y evalúa el instante de liberación respecto a `end_time_sec = note.time_sec + note.duration_sec`:
     - Si `p_dsp_time_sec >= end_time_sec - hold_release_grace_sec`: otorga `JudgmentGrade.PERFECT`.
     - Si se soltó antes de la ventana de gracia pero dentro de `great_window_sec` o `good_window_sec`: otorga `GREAT` o `GOOD`.
     - Si se soltó demasiado pronto: emite `JudgmentGrade.MISS` y reinicia `combo = 0`.
3. **`update_dsp_time(p_dsp_time_sec: float) -> void`:**
   - Si un *hold* activo alcanza o supera `end_time_sec`, se completa automáticamente con `JudgmentGrade.PERFECT` y emite `hold_state_changed(lane, false)`.
   - Expira con `JudgmentGrade.MISS` toda nota no golpeada cuya ventana `note.time_sec + miss_window_sec` haya vencido.

### 2.3. Contrato Público de `HitJudge`
- **Señales:**
  - `signal note_judged(lane: int, grade: int, error_ms: float, combo: int)`
  - `signal score_changed(score: int, combo: int, max_combo: int, accuracy: float)`
  - `signal hold_state_changed(lane: int, is_holding: bool)`
- **Métodos Públicos:**
  - `func load_chart(p_chart: ChartData) -> bool`
  - `func reset_state() -> void`
  - `func on_lane_pressed(p_lane: int, p_dsp_time_sec: float) -> void`
  - `func on_lane_released(p_lane: int, p_dsp_time_sec: float) -> void`
  - `func update_dsp_time(p_dsp_time_sec: float) -> void`
  - `func is_note_resolved(p_note: NoteData) -> bool`
  - `func is_note_actively_held(p_note: NoteData) -> bool`
  - `func is_lane_holding(p_lane: int) -> bool`

---

## 3. `NoteView` (`gameplay/note_view.gd`)

### 3.1. Posicionamiento Determinístico y Consumo Visual de Notas *Hold*
- **Cero `_process(delta)`:** La posición vertical se calcula exclusivamente en `update_position(p_dsp_time_sec: float, p_hit_line_y: float, p_is_holding: bool = false) -> void`:
  - **En caída libre (`not p_is_holding`):**
    $$Y(t_{\text{dsp}}) = y_{\text{hit\_line}} - (t_{\text{nota}} - t_{\text{dsp}}) \cdot v_{\text{scroll}}$$
    y si `note_data.is_hold()`, el cuerpo vertical mantiene su longitud completa `note_data.duration_sec * scroll_speed_px_per_sec`.
  - **En retención activa (`p_is_holding == true`):**
    - Fija la cabeza visual exactamente sobre la línea de juicio:
      $$Y(t_{\text{dsp}}) = y_{\text{hit\_line}}$$
    - Acorta dinámicamente la altura del cuerpo cola según el tiempo restante:
      $$H_{\text{cola}}(t_{\text{dsp}}) = \max(0.0, (t_{\text{end}} - t_{\text{dsp}}) \cdot v_{\text{scroll}})$$
      de modo que la barra se consume limpiamente sobre `hit_line_y` sin atravesarla hacia abajo.

### 3.2. Contrato Público de `NoteView`
- `func setup(p_note: NoteData, p_lane_width: float, p_scroll_speed_px_per_sec: float) -> void`
- `func update_position(p_dsp_time_sec: float, p_hit_line_y: float, p_is_holding: bool = false) -> void`
- `func reset_for_pool() -> void`
- `func get_tail_height_px() -> float`

---

## 4. `LaneField` (`gameplay/lane_field.gd`)

### 4.1. Geometría Responsiva y Cálculo Dinámico de `hit_line_y`
- En `_ready()`, `LaneField` inicializa el pool de `NoteView`, conecta automáticamente las señales de `dsp_clock` (`dsp_time_updated`), `screen_safe_adapter` (`safe_play_rect_changed`) e `input_adapter` (`lane_input_pressed`, `lane_input_released`) hacia `hit_judge` y `LaneField` (verificando `not signal.is_connected(...)`), y consulta inmediatamente `screen_safe_adapter.get_play_rect()` y `screen_safe_adapter.get_hud_safe_rect()`.
- Se posiciona sobre `play_rect` y calcula `hit_line_y` sin coordenadas fijas en píxeles:
  $$\text{hit\_line\_y} = \text{clamp}\left(H_{\text{play\_rect}} \cdot r_{\text{hit\_line}}, \; 0.0, \; Y_{\text{hud\_safe\_end}} - \text{bottom\_padding\_px}\right)$$

### 4.2. Carga de Chart y *Object Pooling*
- `load_chart(p_chart: ChartData) -> bool` valida el chart, delega en `hit_judge.load_chart(p_chart)` si `hit_judge != null`, recicla todas las vistas activas al pool (`_free_pool`) y reinicia el cursor `_next_spawn_index = 0`.
- En `update_field_at_time(p_dsp_time_sec: float)`, activa desde `_free_pool` únicamente las notas dentro de la ventana de visibilidad superior y recicla inmediatamente aquellas que `hit_judge` reporta como resueltas o que superaron el límite inferior de pantalla.

### 4.3. Renderizado de Divisores y Líneas Paralelas Continuas con Halo Brillante Permanente en `_draw()`
- Sin agregar nodos hijos adicionales ni modificar `.tscn`, `LaneField` implementa `_draw() -> void` para dibujar:
  1. **Divisores Verticales de Carril:** Líneas sutiles que delimitan los 4 carriles dentro de `play_rect`.
  2. **Dos Líneas Horizontales Paralelas Continuas en `_hit_line_y`:** Dos líneas continuas que cruzan de extremo a extremo todo el ancho de `LaneField` (`x = 0.0` hasta `x = size.x`), ubicadas en `_hit_line_y \pm \text{DEFAULT\_HEAD\_HEIGHT\_PX} / 2` para enmarcar la altura visual de las notas.
  3. **Halo Luminoso Permanente (*Fake Blur*):** Debajo de cada línea continua se dibujan permanentemente 3 capas más anchas con alfa decreciente (`6.0x`, `3.5x` y `1.9x` del grosor central) y un núcleo nítido de alto contraste, añadiendo un refuerzo luminoso adicional sobre el tramo del carril cuando se presiona o retiene (`lane_input_pressed` / `lane_input_released` y `hold_state_changed`).
