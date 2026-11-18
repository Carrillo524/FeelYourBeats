# 03 — Reloj Maestro de Audio DSP (`core/audio/dsp_clock.gd`)

Este documento especifica el diseño e implementación del **Reloj Maestro de Audio DSP** (`class_name DSPClock extends Node`) dentro de la Capa 1 (`core/audio/`), cumpliendo con las reglas de `AGENTS.md` (Godot 4.7.2, tipado estático estricto, cero dependencias visuales y sincronización determinística).

---

## 1. Propósito y Aislamiento de Capa

`DSPClock` es la fuente única de verdad temporal para todo el sistema:
- **Aislamiento Total:** Extiende `Node` y opera exclusivamente con `AudioServer`, `AudioStreamPlayer`, `Time` y los contratos de `core/chart/` (`ChartData`, `IntensityBlock`). No importa ni referencia `Control`, `Node2D`, `DisplayServer` ni lógica visual o táctil.
- **Consumidores por Señal:** Las capas `gameplay/` y `vfx/` consumen el tiempo musical autoritativo `current_dsp_time_sec` y los eventos rítmicos mediante señales tipadas.

---

## 2. Ecuación DSP Compensada por Latencia y Guarda Monotónica

Durante la reproducción activa del `AudioStreamPlayer`, el tiempo musical bruto se calcula en cada frame combinando la posición de reproducción del stream, el tiempo transcurrido desde la última mezcla del servidor de audio (acotado inferiormente a `0.0`) y la compensación de latencia de salida más los offsets del chart y del usuario:

$$t_{\text{since\_mix}} = \max(0.0, \text{AudioServer.get\_time\_since\_last\_mix}())$$

$$t_{\text{raw}} = t_{\text{playback}} + t_{\text{since\_mix}} - t_{\text{output\_latency}} - t_{\text{chart\_offset}} - t_{\text{user\_offset}}$$

$$t_{\text{dsp}} = \max(t_{\text{dsp\_prev}}, t_{\text{raw}})$$

- **Acotación `maxf(0.0, AudioServer.get_time_since_last_mix())`:** Evita lecturas negativas transitorias justo en la frontera de sincronización del hilo de mezcla.
- **Protección Monotónica (`maxf(current_dsp_time_sec, raw_time)`):** Garantiza que `current_dsp_time_sec` nunca retroceda entre dos frames consecutivos debido a jitter del driver de audio en dispositivos Android, evitando micro-saltos visuales hacia arriba en la caída de las notas.

---

## 3. *Lead-In* Monotónico y Compensación de Pre-Disparo (*Pre-Trigger*)

### 3.1. Fase de *Lead-In* (`current_dsp_time_sec < t_trigger`)
Al invocar `start(p_lead_in_sec)`, el reloj inicia en tiempo negativo (`current_dsp_time_sec = -effective_lead_in`, por defecto `-2.0 s`) para permitir que las notas cercanas a `0.0 s` desciendan suavemente hacia `hit_line_y`. Durante esta fase, el tiempo avanza midiendo microsegundos reales con el reloj monotónico del sistema (`Time.get_ticks_usec() * 0.000001`).

### 3.2. Compensación de Pre-Disparo (*Pre-Trigger*)
Se define el offset total de latencia:

$$\text{total\_offset\_sec} = \text{AudioServer.get\_output\_latency}() + \text{chart.offset\_sec} + \text{user\_offset\_sec}$$

y el umbral de pre-disparo:

$$t_{\text{trigger}} = -\max(0.0, \text{total\_offset\_sec})$$

- **Problema que resuelve:** Si `audio_player.play(0.0)` se invocara recién cuando `current_dsp_time_sec == 0.0` en un dispositivo Android con latencia positiva (`total_offset_sec > 0.0`), el primer valor calculado de `raw_time` sería `-total_offset_sec`. Por la guarda monotónica `maxf(0.0, raw_time)`, el reloj maestro quedaría congelado en `0.0 s` durante `total_offset_sec` segundos mientras el buffer de audio de hardware se llena.
- **Solución:** Tanto en `start()` como en `_process()`, `DSPClock` dispara `audio_player.play(stream_pos)` en cuanto `current_dsp_time_sec >= -maxf(0.0, total_offset_sec)`, con:
  $$\text{stream\_pos} = \max(0.0, t_{\text{dsp}} + \text{total\_offset\_sec})$$
  De este modo, `raw_time` arranca en continuidad exacta con `current_dsp_time_sec` y cruza `0.0 s` en el instante físico en que el primer sample de audio sale por el altavoz.

---

## 4. Detección de Beats, Cursor $O(1)$ de `IntensityBlock` y Cierre Limpio

1. **Detección de Beats (`beat_pulsed`):**
   - Con período `beat_period_sec = 60.0 / _chart.bpm_estimate`, calcula para `current_dsp_time_sec >= 0.0` el índice `target_beat_index = int(floor(current_dsp_time_sec / beat_period_sec))`.
   - Emite `beat_pulsed(beat_index, beat_index * beat_period_sec)` exactamente una vez por cada pulso entero cruzado (`_last_emitted_beat_index < target_beat_index`).
2. **Cursor Incremental $O(1)$ para `IntensityBlock` (`intensity_changed`):**
   - Aprovechando que `ChartData.validate()` garantiza orden cronológico sin solapamientos en `intensity_blocks`, `DSPClock` mantiene el cursor `_current_block_index: int`.
   - En cada frame (`current_dsp_time_sec >= 0.0`), avanza `_current_block_index` solo cuando `current_dsp_time_sec >= blocks[_current_block_index].end_sec` (complejidad $O(1)$ amortizada por frame).
   - Emite `intensity_changed(block)` únicamente cuando el bloque vigente `[start_sec, end_sec)` cambia respecto a `_active_intensity_block`.
3. **Cierre Limpio en `audio_player.finished` o al alcanzar `_chart.duration_sec`:**
   - Al recibir la señal `finished` del `AudioStreamPlayer` o cuando `current_dsp_time_sec >= _chart.duration_sec` en `_process()` (incluso si el `AudioStream` activo contiene silencio residual al final), `_finalize_playback()` consolida `current_dsp_time_sec = maxf(current_dsp_time_sec, _chart.duration_sec)`, evalúa beats y bloques finales, emite una última actualización `dsp_time_updated(current_dsp_time_sec)`, detiene el estado activo y emite `playback_finished()`.
4. **Reposicionamiento Seguro (`seek`):**
   - `seek(p_time_sec)` acota el tiempo solicitado con `clampf(p_time_sec, -default_lead_in_sec, maxf(0.0, _chart.duration_sec))`, reubica el índice de beat y el cursor `_current_block_index`, sincroniza el estado de reproducción/`lead-in` e invoca `_evaluate_intensity_blocks()` inmediatamente para emitir el bloque vigente en la nueva posición.

---

## 5. Contrato de Señales, Propiedades y Métodos de `DSPClock`

### Señales
- `signal dsp_time_updated(current_time_sec: float)`
- `signal beat_pulsed(beat_index: int, beat_time_sec: float)`
- `signal intensity_changed(block: IntensityBlock)`
- `signal playback_finished()`

### Propiedades
- `@export var audio_player: AudioStreamPlayer = null`
- `@export var user_offset_sec: float = 0.0`
- `@export var default_lead_in_sec: float = 2.0`
- `var current_dsp_time_sec: float = 0.0`

### Métodos Públicos
- `func load_chart(p_chart: ChartData) -> bool`
- `func start(p_lead_in_sec: float = -1.0) -> void`
- `func pause() -> void`
- `func resume() -> void`
- `func stop() -> void`
- `func seek(p_time_sec: float) -> void`
- `func get_current_dsp_time() -> float`
- `func is_playing() -> bool`
