# 07 — Motor de Análisis de Audio Real y Generador Automático de Charts (`core/audio/`, `core/chart/`)

Este documento especifica el diseño e implementación de **`AudioAnalyzer`** (`core/audio/audio_analyzer.gd`) y **`AutoChartGenerator`** (`core/chart/auto_chart_generator.gd`) dentro de la Capa 1 (`core/`) de **FeelYourBeats (FyB)** en Godot 4.7.2 Standard, cumpliendo con `AGENTS.md` (tipado estático estricto y aislamiento total respecto a `gameplay/`, `vfx/`, `ui/` y `platform/`).

---

## 1. `AudioAnalyzer` (`core/audio/audio_analyzer.gd`)

### 1.1. Carga Multi-Formato (`load_audio_stream`)
- `func load_audio_stream(p_path: String) -> AudioStream`
  - Para rutas `res://` registradas en el proyecto, utiliza `ResourceLoader.load(p_path)`.
  - Para archivos externos (`user://` o sistema de archivos en Android/PC), selecciona por extensión entre `AudioStreamWAV.load_from_file`, `AudioStreamOggVorbis.load_from_file` y `AudioStreamMP3.load_from_file`.

### 1.2. Análisis Offline Unificado (`analyze_audio_stream` y `analyze_wav_stream`)
- `func analyze_audio_stream(p_stream: AudioStream, p_hop_sec: float = 0.02) -> Dictionary`
  - Si `p_stream is AudioStreamWAV`, delega directamente en `analyze_wav_stream(p_stream as AudioStreamWAV, p_hop_sec)` para decodificar muestras PCM de 8 bits (`FORMAT_8_BITS`) o 16 bits (`FORMAT_16_BITS`), mono o estéreo, en una sola pasada lineal.
  - Si `p_stream` es `AudioStreamOggVorbis` o `AudioStreamMP3`, instancia un reproductor offline mediante `p_stream.instantiate_playback()`, invoca `playback.start(0.0)` y extrae bloques PCM con `playback.mix_audio(1.0, samples_per_hop)` ejecutando el mismo pipeline de sub-bandas.
- **Separación de Sub-Bandas en Tiempo Discreto:**
  - Dos filtros IIR pasa-bajos de primer orden en cascada con frecuencias de corte en `bass_max_hz` (`200.0 Hz`) y `mid_max_hz` (`2200.0 Hz`) dividen cada muestra en graves (`s_bass`), medios (`s_mid`) y agudos (`s_high`).
  - Por cada ventana `p_hop_sec` (`0.02 s`), calcula la energía RMS normalizada en `[0.0, 1.0]` (`rms_frames`, `bass_frames`, `mid_frames`, `high_frames`) y el flujo de ataque espectral positivo `onset_frames`.
- **Estimación de BPM:**
  - Calcula la autocorrelación de `onset_frames` en el rango `[72.0, 185.0]` BPM ponderando el período fundamental y su múltiplo $2\times$.
- **Diccionario Retornado:**
  - `duration_sec: float`
  - `bpm_estimate: float`
  - `frame_hop_sec: float`
  - `rms_frames: PackedFloat32Array`
  - `bass_frames: PackedFloat32Array`
  - `mid_frames: PackedFloat32Array`
  - `high_frames: PackedFloat32Array`
  - `onset_frames: PackedFloat32Array`

### 1.3. Monitoreo de Espectro en Tiempo Real (`spectrum_updated`)
- `signal spectrum_updated(bass_energy: float, mid_energy: float, high_energy: float, total_energy: float)`
- Al activar `set_live_monitoring(true)`, inspecciona primero los efectos existentes en `analysis_bus_name` (`&"Master"` por defecto) para **reutilizar cualquier `AudioEffectSpectrumAnalyzer` ya presente** sin duplicarlo, o agrega uno si no existe.

---

## 2. `AutoChartGenerator` (`core/chart/auto_chart_generator.gd`)

### 2.1. Enumeraciones y Firma Principal
- `enum Difficulty { EASY = 0, NORMAL = 1, HARD = 2 }`
- `enum NoteTypeMode { TAP_AND_HOLD = 0, TAP_ONLY = 1 }`
- `func generate_from_analysis(p_song_id: String, p_title: String, p_audio_path: String, p_analysis: Dictionary, p_difficulty: int = Difficulty.NORMAL, p_note_type_mode: int = NoteTypeMode.TAP_AND_HOLD, p_seed: int = 1337) -> ChartData`

### 2.2. Detección Adaptativa de Picos, Cuantización y Deduplicación
1. **Umbral Adaptativo y Cuantización:**
   - Detecta máximos locales en `onset_frames` que superen la media móvil local (`LOCAL_WINDOW_RADIUS_FRAMES`) más un sesgo por dificultad (`EASY`: `0.22`, `NORMAL`: `0.12`, `HARD`: `0.06`).
   - Cuantiza cada ataque a la rejilla del `bpm_estimate` (`EASY`: negras, `NORMAL`: corcheas, `HARD`: semicorcheas) respetando `min_note_gap_sec`.
2. **Asignación Determinística de Carriles y Deduplicación Previa:**
   - Asigna carriles (`0..3`) de forma determinística con `RandomNumberGenerator` inicializado con `p_seed` y el balance espectral (`bass`, `mid`, `high`), evitando repeticiones consecutivas en el mismo carril.
   - Ordena cronológicamente `notes` por `time_sec` y filtra cualquier duplicado exacto en el mismo `(time_sec, lane)` antes de calcular las duraciones *hold* y ejecutar `chart.validate()`.

### 2.3. Modos de Tipo de Nota (`NoteTypeMode`)
- **`NoteTypeMode.TAP_AND_HOLD`:** Evalúa la energía `rms_frames` posterior a cada nota; si se mantiene por encima del umbral de sostenimiento durante al menos `0.25 s` sin solapar la siguiente nota en el mismo carril ni el margen final de la pista, asigna `duration_sec >= 0.25`.
- **`NoteTypeMode.TAP_ONLY`:** Fija `duration_sec = 0.0` en todos los ataques detectados para conservar intacto el ritmo y la densidad cuando se desactivan las notas mantenidas.

### 2.4. Segmentación de `IntensityBlock` y Validación
- Construye bloques `IntensityBlock` contiguos desde `0.0` hasta `duration_sec` clasificando su `tier` (`0..3`) según la energía RMS media y verifica `chart.validate()` antes de retornar.
