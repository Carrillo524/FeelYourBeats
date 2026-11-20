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
   - Mientras un *hold* está activo en un carril (`_active_holds[lane] != null`), acumula el tiempo retenido respecto a `_hold_last_tick_times[lane]` y cada **`0.25 s`** (`HOLD_COMBO_TICK_INTERVAL_SEC`) incrementa `combo += 1`, actualiza `max_combo` y suma `SCORE_HOLD_TICK = 150` a `score`, emitiendo `hold_combo_ticked(lane, combo)` y `score_changed`.
   - Si un *hold* activo alcanza o supera `end_time_sec`, se completa automáticamente con `JudgmentGrade.PERFECT`, reinicia `_hold_last_tick_times[lane] = 0.0` y emite `hold_state_changed(lane, false)`.
   - Expira con `JudgmentGrade.MISS` toda nota no golpeada cuya ventana `note.time_sec + miss_window_sec` haya vencido.

### 2.3. Medidor de Pérdida / Riesgo Escalado por Dificultad (Estilo MELOBEAT)
- `HitJudge` mantiene `danger_ratio: float = 0.0` (`0.0..1.0`) y `active_difficulty: int` (`set_difficulty(p_difficulty: int) -> void`), actualizado en cada juicio:
  - **`EASY` (`FÁCIL`):** `+0.08` por `MISS`, `-0.045` por acierto (`PERFECT`, `GREAT`, `GOOD`).
  - **`NORMAL`:** `+0.11` por `MISS`, `-0.035` por acierto (`PERFECT`, `GREAT`, `GOOD`).
  - **`HARD` (`DIFÍCIL`):** `+0.15` por `MISS`, `-0.025` por acierto (`PERFECT`, `GREAT`, `GOOD`).
- Emite `danger_changed(p_ratio: float)` en cada cambio y `danger_overflowed()` **una única vez** al alcanzar `danger_ratio >= 1.0` (reiniciado a `0.0` en `reset_state()`).

### 2.4. Contrato Público de `HitJudge`
- **Señales:**
  - `signal note_judged(lane: int, grade: int, error_ms: float, combo: int)`
  - `signal score_changed(score: int, combo: int, max_combo: int, accuracy: float)`
  - `signal hold_state_changed(lane: int, is_holding: bool)`
  - `signal hold_combo_ticked(p_lane: int, p_new_combo: int)`
  - `signal danger_changed(p_ratio: float)`
  - `signal danger_overflowed()`
- **Métodos Públicos:**
  - `func load_chart(p_chart: ChartData) -> bool`
  - `func reset_state() -> void`
  - `func set_difficulty(p_difficulty: int) -> void`
  - `func get_danger_ratio() -> float`
  - `func has_danger_overflowed() -> bool`
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

### 3.2. Estela Superior de Movimiento (*Motion Feather*) para Velocidades Altas (`3x` y `4x`)
- Cuando `speed_multiplier >= 3` y la nota no está siendo retenida (`not p_is_holding`), `NoteView` muestra dos franjas translúcidas sutiles degradadas por encima de la cabeza (`MotionFeatherInnerRect` y `MotionFeatherOuterRect`) con altura proporcional a `scroll_speed_px_per_sec` para suavizar el contraste de barrido en pantallas de 60/90 Hz.
- En velocidades `1x` y `2x`, durante retención activa o al reciclar la vista en `reset_for_pool()`, ambas capas se ocultan explícitamente (`visible = false`, `size = Vector2.ZERO`).

### 3.3. Contrato Público de `NoteView`
- `func setup(p_note: NoteData, p_lane_width: float, p_scroll_speed_px_per_sec: float, p_speed_multiplier: int = 1) -> void`
- `func set_speed_multiplier(p_multiplier: int) -> void`
- `func update_position(p_dsp_time_sec: float, p_hit_line_y: float, p_is_holding: bool = false) -> void`
- `func reset_for_pool() -> void`
- `func get_tail_height_px() -> float`
- `func is_motion_feather_visible() -> bool`

---

## 4. `LaneField` (`gameplay/lane_field.gd`)

### 4.1. Geometría Responsiva, Cálculo Dinámico de `hit_line_y` e Interpolación del Reloj Visual en `_process(delta)`
- En `_ready()`, `LaneField` inicializa el pool de `NoteView`, conecta automáticamente las señales de `dsp_clock` (`dsp_time_updated` → `_on_dsp_time_updated`), `screen_safe_adapter` (`safe_play_rect_changed`) e `input_adapter` (`lane_input_pressed`, `lane_input_released`) hacia `hit_judge` y `LaneField` (verificando `not signal.is_connected(...)`), y consulta inmediatamente `screen_safe_adapter.get_play_rect()` y `screen_safe_adapter.get_hud_safe_rect()`.
- **Eliminación de Judder / Doble Imagen a Altas Velocidades (`3x` y `4x`):**
  - `DSPClock` mantiene un reloj visual interpolado por lazo de enganche de fase (`_visual_time_sec: float`, expuesto vía `get_visual_time_sec()` y `visual_time_updated`) que avanza de manera continua con `delta` en cada frame de renderizado (60 / 90 / 120 / 144 Hz) y se corrige suavemente hacia el reloj maestro de `AudioServer` dentro de una banda de tolerancia de `±6 ms` (`VISUAL_PHASE_LOCK_TOLERANCE_SEC = 0.006`), haciendo *snap* instantáneo solo en discontinuidades mayores (`>= 45 ms`, como `seek`/`start`).
  - **`HitJudge` permanece 100% anclado al reloj maestro DSP (`current_dsp_time_sec`)** recibido en `_on_dsp_time_updated(p_dsp_time_sec)`, sin alterar jamás las ventanas de precisión ni la detección de impactos.
  - Toda actualización de `NoteView.position.y` en `LaneField` ocurre exclusivamente dentro de `_process(delta)` (nunca en `_physics_process`) leyendo `dsp_clock.get_visual_time_sec()`, evitando el desfase entre los 60 Hz de física y pantallas de 90/120 Hz.
- Se posiciona sobre `play_rect` y calcula `hit_line_y` sin coordenadas fijas en píxeles:
  $$\text{hit\_line\_y} = \text{clamp}\left(H_{\text{play\_rect}} \cdot r_{\text{hit\_line}}, \; 0.0, \; Y_{\text{hud\_safe\_end}} - \text{bottom\_padding\_px}\right)$$

### 4.2. Carga de Chart y *Object Pooling*
- `load_chart(p_chart: ChartData) -> bool` valida el chart, delega en `hit_judge.load_chart(p_chart)` si `hit_judge != null`, recicla todas las vistas activas al pool (`_free_pool`) y reinicia el cursor `_next_spawn_index = 0`.
- En `update_field_at_time(p_dsp_time_sec: float)`, activa desde `_free_pool` únicamente las notas dentro de la ventana de visibilidad superior y recicla inmediatamente aquellas que `hit_judge` reporta como resueltas o que superaron el límite inferior de pantalla.

### 4.3. Renderizado de Divisores Reactivos con Halo Blur y Micro-Shake, Líneas Paralelas, Ondas de Toque y Partículas en `_draw()`
- Sin agregar nodos hijos adicionales ni modificar `.tscn`, `LaneField` implementa `_draw() -> void` para dibujar:
  1. **Divisores Verticales Reactivos con Halo Blur y Micro-Shake:** Las 5 líneas verticales de los 4 carriles permanecen siempre visibles con trazo fino cian neón translúcido (`alpha ~0.24` en reposo) respaldado por un halo blur multicapa suave. Al recibir señales de `DSPClock` (`beat_pulsed`, `intensity_changed`) y `AudioAnalyzer` (`spectrum_updated`), aumentan su brillo en beats/drops y aplican un **micro-shake horizontal amortiguado** (`~2.0–3.5 px` con decaimiento rápido) exclusivamente sobre el dibujo visual de las líneas sin desplazar jamás las zonas táctiles de entrada.
  2. **Dos Líneas Horizontales Paralelas Continuas en `_hit_line_y`:** Dos líneas continuas que cruzan de extremo a extremo todo el ancho de `LaneField` (`x = 0.0` hasta `x = size.x`), ubicadas en `_hit_line_y \pm \text{DEFAULT\_HEAD\_HEIGHT\_PX} / 2` para enmarcar la altura visual de las notas.
  3. **Halo Luminoso Permanente (*Fake Blur*):** Debajo de cada línea continua se dibujan permanentemente 3 capas más anchas con alfa decreciente (`6.0x`, `3.5x` y `1.9x` del grosor central) y un núcleo nítido de alto contraste, añadiendo un refuerzo luminoso adicional sobre el tramo del carril cuando se presiona o retiene (`lane_input_pressed` / `lane_input_released` y `hold_state_changed`).
  4. **Ondas de Toque (*Touch Ripples*):** Pool circular en `_touch_ripples` (`MAX_ACTIVE_RIPPLES = 16`) alimentado por `RhythmInputAdapter.touch_ripple_triggered(p_local_pos, p_lane)` al tocar la pantalla (o centrado en `_hit_line_y` del carril correspondiente al presionar las teclas `D`, `F`, `J`, `K`).
  5. **Partículas por Precisión en Todas las Notas:** Pool ligero en `_hit_particles` (`MAX_ACTIVE_PARTICLES = 128`) disparado en `HitJudge.note_judged` para **todas las notas (*tap* y *hold*), exista o no un *drop***:
     - `PERFECT`: explosión saturada de `14` partículas (cian, dorado y magenta) más onda radial en `_hit_line_y`.
     - `GREAT`: ráfaga media de `8` partículas (verde neón y cian).
     - `GOOD`: destello sutil de `4` partículas (azul claro).
     - `MISS`: `0` partículas.
     - **Chispas Continuas en *Hold*:** Emisión continua de micro-chispas en `_hit_line_y` mientras una nota *hold* permanece retenida y ráfagas de refuerzo en cada `hold_combo_ticked`.
