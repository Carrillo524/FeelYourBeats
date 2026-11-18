# 08 — Espectro Real en VFX, Halo en Notas Hold e Integración de Sesión (`vfx/`, `gameplay/`, `ui/`)

Este documento especifica la integración de **`AudioAnalyzer`** y **`AutoChartGenerator`** con **`ReactiveBackground`**, **`NoteView`** y **`GameSession`** en **FeelYourBeats (FyB)** sobre Godot 4.7.2 Standard, respetando `AGENTS.md` (tipado estático estricto y desacoplamiento total por señales).

---

## 1. Acoplamiento por Señales `AudioAnalyzer -> ReactiveBackground`

### 1.1. Nuevos Uniforms del Shader (`vfx/reactive_backdrop.gdshader`)
- `bass_energy: float` (`0.0..1.0`): Energía suavizada de graves (`20..200 Hz`).
- `mid_energy: float` (`0.0..1.0`): Energía suavizada de medios (`200..2200 Hz`).
- `high_energy: float` (`0.0..1.0`): Energía suavizada de agudos (`2200..12000 Hz`).
- `zoom_bounce: float` (`0.0..0.25`): Factor de rebote de escala UV centrado en `vec2(0.5, 0.5)` con `clamp` en `[0.0, 1.0]` para preservar cobertura *full-bleed* sin repeticiones en bordes curvos ni pantallas 1.5K (20:9).

### 1.2. Suavizado y Respiración Ambiental (`vfx/reactive_background.gd`)
- `ReactiveBackground` recibe `@export var audio_analyzer: AudioAnalyzer = null` y se conecta a `audio_analyzer.spectrum_updated(bass_energy, mid_energy, high_energy, total_energy)`.
- En `_process(p_delta: float)`, interpola las tres sub-bandas con ataque rápido (`SPECTRUM_ATTACK_SPEED = 14.0`) y caída suave (`SPECTRUM_DECAY_SPEED = 6.5`), combinando `_smoothed_bass` y `_beat_pulse` con una oscilación sinusoidal de baja amplitud (`_ambient_phase`) para que el fondo conserve una respiración visual sutil incluso durante pausas o silencios.

---

## 2. Halo / Blur Concéntrico en Notas Sostenidas (`gameplay/note_view.gd`)

- `NoteView` incorpora dos capas translúcidas concéntricas detrás de `_hold_body_rect`:
  - `HoldOuterGlowRect` (`_hold_outer_glow_rect: ColorRect`)
  - `HoldInnerGlowRect` (`_hold_inner_glow_rect: ColorRect`)
- Cuando `note_data.is_hold() == true`, ambas capas envuelven el haz vertical de la nota sostenida.
- Durante la retención activa (`p_is_holding == true` en `update_position`), el ancho del halo se expande (`1.68x -> 2.05x` en la capa exterior y `1.32x -> 1.54x` en la interior) y aumenta su luminosidad mientras la barra se consume sobre `hit_line_y`.
- **Blindaje para Object Pooling:** Tanto al configurar una nota simple (`not note_data.is_hold()`) en `setup()` como al reciclar la vista en `reset_for_pool()`, `_hold_outer_glow_rect.visible`, `_hold_inner_glow_rect.visible` y `_hold_body_rect.visible` se fijan explícitamente en `false` (con tamaño `Vector2.ZERO`) para impedir cualquier residuo visual entre notas recicladas.

---

## 3. Pipeline de Sesión con Audio Real (`gameplay/game_session.gd` y `ui/game_session.tscn`)

### 3.1. Jerarquía Actualizada en `ui/game_session.tscn` (vía MCP de Godot)
Se agrega el nodo hijo `AudioAnalyzer` bajo la raíz `GameSession`:
- `GameSession` (`gameplay/game_session.gd`)
  - `DSPClock` (`core/audio/dsp_clock.gd`)
  - `AudioAnalyzer` (`core/audio/audio_analyzer.gd`)
  - `ScreenSafeAdapter` (`platform/screen_safe_adapter.gd`)
  - `RhythmInputAdapter` (`platform/rhythm_input_adapter.gd`)
  - `HitJudge` (`gameplay/hit_judge.gd`)
  - `ReactiveBackground` (`vfx/reactive_background.gd`)
  - `LaneField` (`gameplay/lane_field.gd`)
  - `SafeHud` (`ui/safe_hud.gd`)

### 3.2. Flujo de `start_audio_file_session` y Preservación en Reinicio
- `func start_audio_file_session(p_audio_path: String, p_difficulty: int = AutoChartGenerator.Difficulty.NORMAL, p_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD, p_title: String = "") -> bool`:
  1. Carga el `AudioStream` mediante `audio_analyzer.load_audio_stream(p_audio_path)`.
  2. Extrae sub-bandas, onsets y BPM con `audio_analyzer.analyze_audio_stream(stream)`.
  3. Genera y valida el `ChartData` con `AutoChartGenerator.generate_from_analysis(...)`.
  4. Almacena `_active_audio_stream = stream`, activa `audio_analyzer.set_live_monitoring(true)` e inicia `start_chart_session(chart)`.
- Al recibir `restart_requested` desde `SafeHud`, `_on_restart_requested()` reinicia directamente `start_chart_session(_active_chart)` conservando `_active_audio_stream` para nunca sobrescribir una canción personalizada con el chart demo.
