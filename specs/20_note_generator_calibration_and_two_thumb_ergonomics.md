# Spec 20 — Diagnóstico, Calibración Temporal y Regla Ergonómica a 2 Pulgares del Generador de Notas (Fase 9)

## 1. Nombre y Objetivo
- **Nombre:** Calibración temporal de sincronización musical, ergonomía estricta a 2 pulgares y curva dinámica por dificultad en el generador automático de charts (Fase 9).
- **Objetivo:** Corregir los desfases temporales detectados entre los ataques reales del audio y las notas generadas, imponer como invariante duro la **regla ergonómica a 2 pulgares** (Carriles `0–1` = pulgar izquierdo; Carriles `2–3` = pulgar derecho) garantizando **`0` colisiones intra-pulgar durante `Hold`** y eliminando trinos imposibles en pantalla táctil, y mejorar la progresión musical entre secciones calmadas y Drops en `Fácil`, `Normal` y `Difícil` sin modificar archivos `.tscn` ni alterar la versión en `project.godot`.

---

## 2. Red de Seguridad Git y Archivos Inspeccionados
- **Tag de respaldo creado:** `pre-fase-9` sobre `main` (`bbbce1d`).
- **Archivos auditados:**
  - `AGENTS.md` y `project.godot` (versión actual `1.0.4`, sin modificar).
  - `core/audio/audio_analyzer.gd` (análisis RMS/sub-bandas, flujo de ataque `onset_frames`, estimación de BPM).
  - `core/audio/dsp_clock.gd` (reloj maestro DSP, compensación de latencia, emisión de beats y bloques de intensidad).
  - `core/chart/auto_chart_generator.gd` (detección de picos, cuantización, asignación de carriles, `Hold`, `IntensityBlock`).
  - `core/chart/chart_cache_repository.gd` (`CACHE_SCHEMA_VERSION = "v1"`, preservación de `user://song_records.cfg`).
  - `core/chart/chart_data.gd` y `core/chart/note_data.gd` (contrato de datos y validación).
  - `gameplay/hit_judge.gd` (ventanas `PERFECT = ±45 ms`, `GREAT = ±90 ms`, `GOOD = ±140 ms`, `hold_release_grace_sec = 120 ms`).
  - `gameplay/game_session.gd` (`build_demo_chart()` y carga de caché).
  - `specs/07_audio_analyzer_and_chart_gen.md`.

---

## 3. Auditoría Técnica — Hallazgos del Diagnóstico

### 3.1 Causas Exactas de Desfase Temporal con los Beats Reales
1. **Cuantización ciega a fase cero (`phase = 0.0`) (`auto_chart_generator.gd:147`):**
   - Actualmente `quantized_time_sec = round(raw_time_sec / p_grid_step_sec) * p_grid_step_sec` asume que el primer beat de toda canción ocurre en `t = 0.000 s`.
   - En pistas `.mp3`/`.ogg` reales con padding de codificador (`25–150 ms`) o intros con fase desplazada ($\phi \in [0, T_{\text{beat}})$), la cuantización contra cero desplaza sistemáticamente las notas entre `±50 ms` y `±250 ms` respecto al golpe real (excediendo `PERFECT ±45 ms` y `GREAT ±90 ms`).
2. **Resolución gruesa de BPM por lag entero (`audio_analyzer.gd:839-875`):**
   - Con `hop_sec = 0.02 s`, un lag entero de `25` da `120.0 BPM`, `24` da `125.0 BPM` y `23` da `130.4 BPM`: **saltos de `5 BPM` por unidad de lag**.
   - Un error de `2.5 BPM` acumula `3.75 s` de deriva en una canción de 3 minutos, desalineando la rejilla rígida respecto a la música conforme avanza la pista.
3. **Sesgo de ventana de ataque y falta de refinamiento sub-frame (`audio_analyzer.gd:810-819`, `auto_chart_generator.gd:146`):**
   - `onset_frames[i]` compara la energía RMS del intervalo `[i*hop, (i+1)*hop]` contra `[ (i-1)*hop, i*hop ]` y asigna `i * hop` sin interpolación parabólica ni compensación del inicio del transiente (`~10 ms`), introduciendo cuantización gruesa de `20 ms` y retraso sobre el inicio del ataque.
4. **Aceptación greedy con enfriamiento rígido (`auto_chart_generator.gd:150`):**
   - El bucle acepta el *primer* máximo local sobre el umbral y bloquea `min_note_gap_sec`. Un pre-transiente débil `80 ms` antes de un bombo fuerte descarta el golpe real, generando notas adelantadas y fuera de pulso.
5. **Caché de charts en `v1` (`chart_cache_repository.gd:6`):**
   - Sin incrementar `CACHE_SCHEMA_VERSION` a `"v2"`, los dispositivos con canciones ya analizadas seguirían cargando charts antiguos desincronizados.

### 3.2 Violaciones de Ergonomía a 2 Pulgares Detectadas
1. **Colisión crítica intra-pulgar durante `Hold` (`auto_chart_generator.gd:255-263`):**
   - `_apply_hold_durations()` únicamente limita el final del `Hold` contra la siguiente nota en **el mismo carril** (`p_notes[j].lane == note.lane`). Jamás verifica el carril vecino del **mismo pulgar** (`0 <-> 1` izquierdo o `2 <-> 3` derecho).
   - Además, `HOLD_TAIL_SAFETY_GAP_SEC = 0.08 s` es menor que `hold_release_grace_sec = 0.120 s` de `HitJudge`.
   - En la práctica, el generador emite `Tap` (o incluso otro `Hold`) en Carril 1 mientras el jugador sostiene un `Hold` en Carril 0 con el pulgar izquierdo — patrón físicamente imposible a 2 pulgares.
2. **Colisión presente incluso en `GameSession.build_demo_chart()` (`gameplay/game_session.gd:268-275`):**
   - En `step_idx = 10`, Carril `2` (pulgar derecho) tiene un `Hold` de `1.5 beats` (`beat 11.0 → 12.5`), mientras `step_idx = 11` coloca un `Tap` en Carril `3` (también pulgar derecho) en `beat 12.0`, provocando colisión intra-pulgar dentro de la propia demo.
3. **Trinos imposibles del mismo pulgar (`auto_chart_generator.gd:198-203`):**
   - La asignación de carriles solo evita repetir `last_lane` exacto, permitiendo secuencias `0 -> 1 -> 0` a `110 ms` con el mismo pulgar en lugar de alternar izquierda ↔ derecha.

### 3.3 Debilidades de Curva Musical y Dificultades
1. **`IntensityBlock` ignorado en la generación de notas (`auto_chart_generator.gd:83`):** se calcula *después* de colocar las notas, produciendo la misma sensibilidad en calma (`tier 0–1`) que en Drops (`tier 2–3`).
2. **Ausencia de acordes a dos manos (doubles):** en `Normal` y `Difícil` jamás se generan acentos simultáneos de 2 pulgares (`1 izquierdo + 1 derecho`) en golpes fuertes de coro/Drop.
3. **Holds sin cota superior ergonómica:** en secciones sostenidas un `Hold` puede extenderse varios segundos bloqueando una mano entera durante un Drop rápido.

---

## 4. Diseño Matemático y Reglas Exactas (Fase 9)

### 4.1 Calibración Temporal y Sincronización Real (`AudioAnalyzer` + `AutoChartGenerator`)
1. **Estimación de BPM con interpolación parabólica sub-frame (`AudioAnalyzer`):**
   - En `_estimate_bpm_from_onsets()`, almacenar el vector de puntuaciones de autocorrelación `scores[lag]` (combinando lag $1\times$, $2\times$ con peso `0.35` y $3\times$ con peso `0.15`, más una ponderación perceptual suave centrada en `115–145 BPM` para reducir errores de doble/medio tempo).
   - Refinar `best_lag` mediante interpolación parabólica de sus vecinos `(s_prev, s_curr, s_next)`:
     $$\delta_{\text{lag}} = \mathrm{clamp}\!\left(\frac{0.5 \cdot (s_{\text{prev}} - s_{\text{next}})}{s_{\text{prev}} - 2 s_{\text{curr}} + s_{\text{next}}},\ -0.5,\ 0.5\right)$$
     $$\text{bpm\_estimate} = \mathrm{clamp}\!\left(\frac{60.0}{(\text{best\_lag} + \delta_{\text{lag}}) \cdot \text{hop\_sec}},\ 72.0,\ 185.0\right)$$
   - Precisión mejorada de `±2.5 BPM` a `~±0.15 BPM`.
2. **Detección de fase de beat (`beat_phase_sec`) (`AudioAnalyzer` + fallback en `AutoChartGenerator`):**
   - Añadir `"beat_phase_sec"` al diccionario de análisis retornado por `AudioAnalyzer` (retrocompatible: si no existe en diccionarios externos/sintéticos, `AutoChartGenerator` la estima con el mismo método).
   - Evaluar fases candidatas $\phi \in [0, T_{\text{beat}})$ en pasos de `0.005 s` maximizando la energía de `onset_frames` alineada a $\phi + k \cdot T_{\text{beat}}$ (peso `1.0`) y $\phi + (k + 0.5) \cdot T_{\text{beat}}$ (peso `0.30`).
   - En `DSPClock._evaluate_beats()` (si `ChartData` conserva `offset_sec = 0.0` para no alterar sincronización de reproducción), las notas se alinean a la fase real $\phi$ directamente en sus timestamps `NoteData.time_sec`.
3. **Refinamiento sub-frame del ataque y cuantización elástica (`AutoChartGenerator`):**
   - Para cada pico local `i` de `onset_frames`:
     $$\delta_i = \mathrm{clamp}\!\left(\frac{0.5 \cdot (o_{i-1} - o_{i+1})}{o_{i-1} - 2 o_i + o_{i+1}},\ -0.5,\ 0.5\right)$$
     $$t_{\text{raw}} = \max\!\big(0.0,\ (i + \delta_i) \cdot \text{hop\_sec} - 0.010\big)$$
   - Proyectar sobre la rejilla en fase real:
     $$t_{\text{grid}} = \phi + \mathrm{round}\!\left(\frac{t_{\text{raw}} - \phi}{g}\right) \cdot g$$
   - **Cuantización elástica:** si $|t_{\text{raw}} - t_{\text{grid}}| \le \min(0.42 \cdot g,\ 0.045\text{ s})$, usar $t_{\text{final}} = t_{\text{grid}}$; si excede el umbral (p. ej. tresillo real, síncopa o rubato), conservar $t_{\text{final}} = t_{\text{raw}}$ para **no arrastrar jamás una nota lejos del golpe real**.
4. **Supresión de pre-transientes (pico dominante en ventana):**
   - Si aparece un candidato nuevo a menos de `min_gap_sec` del último aceptado y su fuerza `strength` supera al anterior (`curr_strength > prev_strength * 1.08`), **reemplaza** al candidato débil anterior en lugar de descartarse.

### 4.2 Regla Ergonómica Dura a 2 Pulgares (Inviolable)
- **Mapeo físico de carriles:**
  - Pulgar Izquierdo (`THUMB_LEFT = 0`): carriles `0` y `1` (Carriles 1–2 visuales).
  - Pulgar Derecho (`THUMB_RIGHT = 1`): carriles `2` y `3` (Carriles 3–4 visuales).
  - `lane_to_thumb(lane) = 0 if lane <= 1 else 1`
  - `get_sibling_lane(lane) = (1 - lane) if lane <= 1 else (5 - lane)`
- **Invariante 1 — Bloqueo total intra-pulgar durante `Hold`:**
  - Para toda nota `Hold` $h$ en carril $L$ con intervalo $[t_h, t_h + d_h]$ ($d_h > 0$), ninguna otra nota $n$ (`Tap` o `Hold`) perteneciente al mismo pulgar ($\text{thumb}(n.\text{lane}) == \text{thumb}(L)$) puede tener:
    $$t_h \le t_n < t_h + d_h + M_{\text{rel}}$$
    donde el margen ergonómico de liberación $M_{\text{rel}}$ es:
    - `EASY`: `0.16 s`
    - `NORMAL`: `0.14 s`
    - `HARD`: `0.12 s`
    (siempre $\ge 0.12\text{ s} = \text{HitJudge.hold\_release\_grace\_sec}$).
  - Solo el pulgar opuesto ($1 - \text{thumb}(L)$) puede recibir notas `Tap` (o un `Hold` paralelo breve en `HARD` si no colisiona consigo mismo) durante ese intervalo.
- **Invariante 2 — Separación mínima entre golpes consecutivos del mismo pulgar (anti-trinos):**
  - Mínimo entre dos notas consecutivas asignadas al mismo pulgar (`same_thumb_min_gap_sec`):
    - `EASY`: `0.32 s` (+`0.04 s` si cambia al carril vecino `0 <-> 1` o `2 <-> 3`)
    - `NORMAL`: `0.21 s` (+`0.03 s` en cambio de carril vecino)
    - `HARD`: `0.15 s` (+`0.025 s` en cambio de carril vecino)
  - Cuando la separación entre dos eventos musicales consecutivos es menor que `same_thumb_min_gap_sec`, el generador **alterna obligatoriamente al pulgar opuesto** (izquierda ↔ derecha).
- **Invariante 3 — Acordes a 2 manos válidos:**
  - En un mismo timestamp (`|t_a - t_b| <= 0.005 s`), máximo **2 notas**: estrictamente `1` en pulgar izquierdo (`0` o `1`) y `1` en pulgar derecho (`2` o `3`), nunca `0+1` ni `2+3`, y nunca mientras alguno de los dos pulgares esté ocupado por un `Hold` activo + $M_{\text{rel}}$.
- **Pasada final de garantía determinista + Validador público:**
  - Tras asignar duraciones `Hold`, una pasada final audita cronológicamente cada pulgar: si alguna nota cae dentro de un `Hold` del mismo pulgar (más $M_{\text{rel}}$), se intenta mover al pulgar opuesto (si está libre y respeta `same_thumb_min_gap_sec`); si no es posible, se recorta el `Hold` (si conserva `>= MIN_HOLD_DURATION_SEC`) o se convierte a `Tap` (`duration_sec = 0.0`), garantizando **`0` violaciones**.
  - Método estático verificable: `AutoChartGenerator.validate_two_thumb_ergonomics(p_chart: ChartData, p_release_margin_sec: float = 0.12) -> Dictionary` retornando `{"valid": bool, "violations": Array[String], "hold_thumb_collisions": int, "same_thumb_chords": int}`.

### 4.3 Curva Musical por `IntensityBlock` y Dificultades
- `intensity_blocks` se construye **antes** de seleccionar notas para modular la generación por sección (`tier 0`: calma/intro, `tier 1`: verso, `tier 2`: clímax/coro, `tier 3`: Drop):

| Parámetro | `Fácil` (`EASY`) | `Normal` (`NORMAL`) | `Difícil` (`HARD`) |
| :--- | :--- | :--- | :--- |
| Rejilla rítmica (`grid_step`) | `1.0 * beat` | `0.5 * beat` | `0.25 * beat` (tier 2–3) / `0.5 * beat` (tier 0–1) |
| Gap mínimo global (calma / Drop) | `0.38 s` / `0.30 s` | `0.22 s` / `0.16 s` | `0.16 s` / `0.11 s` |
| Gap mínimo mismo pulgar | `0.32 s` (+`0.04 s` vecino) | `0.21 s` (+`0.03 s` vecino) | `0.15 s` (+`0.025 s` vecino) |
| Sesgo de umbral (calma / Drop) | `0.26` / `0.18` | `0.16` / `0.09` | `0.10` / `0.04` |
| Acordes a 2 manos (`1 izq + 1 der`) | No (`0%`) | Solo picos muy fuertes en `tier 2–3` (cooldown `1.2 s`) | Picos fuertes en `tier 2–3` (cooldown `0.65 s`) |
| Duración de `Hold` (min / max) | `0.45 s` / `1.45 s` | `0.45 s` / `1.75 s` | `0.45 s` / `1.50 s` |
| Margen liberación `Hold` ($M_{\text{rel}}$) | `0.16 s` | `0.14 s` | `0.12 s` |

- **Actualización de la demo integrada (`GameSession.build_demo_chart()`):** ajustar el carril/duración de los `Hold` en `build_demo_chart()` para que la demo también cumpla `validate_two_thumb_ergonomics()` con `0` violaciones.
- **Invalidación de caché (`ChartCacheRepository`):** subir `CACHE_SCHEMA_VERSION = "v2"` para regenerar automáticamente charts antiguos manteniendo intacto `user://song_records.cfg`.

---

## 5. Archivos a Modificar (Tras Aprobación del Plan)
| Acción | Archivo | Propósito |
| :--- | :--- | :--- |
| **CREAR** | `specs/20_note_generator_calibration_and_two_thumb_ergonomics.md` | Spec y diagnóstico previo de la Fase 9. |
| **MODIFICAR** | `core/audio/audio_analyzer.gd` | Interpolación parabólica de BPM sub-frame + detección de `beat_phase_sec` (expuesta en el diccionario de análisis). |
| **MODIFICAR** | `core/chart/auto_chart_generator.gd` | Fase real + refinamiento sub-frame + cuantización elástica + reemplazo por pico dominante + bloques previos + curva por tier/dificultad + acordes a 2 manos + regla dura de 2 pulgares + `validate_two_thumb_ergonomics()`. |
| **MODIFICAR** | `core/chart/chart_cache_repository.gd` | Subir `CACHE_SCHEMA_VERSION` de `"v1"` a `"v2"` sin tocar `song_records.cfg`. |
| **MODIFICAR** | `gameplay/game_session.gd` | Corregir la colisión intra-pulgar detectada en `build_demo_chart()` para que pase `validate_two_thumb_ergonomics()` con `0` violaciones. |

### Exclusiones Explícitas
- **NO** se modifica ningún archivo `.tscn`.
- **NO** se modifican números de versión en `project.godot` (`1.0.4` permanece intacto hasta el cierre de `v1.1.0`).
- **NO** se modifica `vfx/` ni la UI de `AJUSTES`.

---

## 6. Criterios de Aceptación Verificables
1. **Sincronización temporal precisa (fase no cero):** Dada una pista WAV sintética a `128.0 BPM` con desplazamiento inicial de fase `0.23 s`, `AudioAnalyzer` estima `bpm_estimate` con error `<= 1.0 BPM` y `beat_phase_sec` con error `<= 0.025 s`, y `AutoChartGenerator` ubica las notas sobre los golpes reales con error medio `<= 0.025 s` (muy dentro de `PERFECT ±0.045 s`).
2. **Supresión de pre-transientes:** Un pre-pico débil `70 ms` antes de un golpe principal fuerte es reemplazado por el golpe principal y no desplaza la nota fuera de pulso.
3. **`0` colisiones intra-pulgar durante `Hold` (invariante duro):** `AutoChartGenerator.validate_two_thumb_ergonomics()` retorna `valid == true`, `hold_thumb_collisions == 0` y `same_thumb_chords == 0` en `EASY`, `NORMAL` y `HARD` (en `TAP_AND_HOLD` y `TAP_ONLY`), tanto en pistas sintéticas complejas (con sostén largo y ráfagas) como en todas las canciones integradas en `res://assets/songs/` y en `GameSession.build_demo_chart()`.
4. **Separación mínima anti-trino por pulgar:** Ninguna pareja de notas consecutivas del mismo pulgar incumple `same_thumb_min_gap_sec` (y el margen adicional de cambio de carril vecino).
5. **Curva musical y dificultades diferenciadas:**
   - Densidad estrictamente ordenada: `EASY < NORMAL < HARD` sobre la misma pista.
   - En Drops (`tier 2–3`) la densidad es mayor que en secciones calmadas (`tier 0–1`), `EASY` produce `0` acordes, y `NORMAL`/`HARD` generan acordes estrictamente válidos (`1 izq + 1 der`).
6. **Caché limpia sin perder récords:** `ChartCacheRepository.CACHE_SCHEMA_VERSION == "v2"` genera claves distintas a `"v1"` manteniendo `load_song_record()` y `load_song_summary()` 100 % compatibles.
7. **Tipado estricto y cero `.tscn`:** `--headless --quit --check-only` con 0 errores y 0 advertencias en todos los scripts modificados; `git diff -- "*.tscn"` vacío; `project.godot` sin cambio de versión.

---

## 7. Plan de Pruebas Automatizadas y Manuales

### Pruebas Automatizadas (`--headless`)
1. `--headless --quit --check-only` sobre:
   - `res://core/audio/audio_analyzer.gd`
   - `res://core/chart/auto_chart_generator.gd`
   - `res://core/chart/chart_cache_repository.gd`
   - `res://gameplay/game_session.gd`
2. Suite temporal `scratch/verify_phase9_chart_generator.gd` (`get_tree().quit(0)`), eliminando `scratch/` en `finally`:
   - **Test 1 — Precisión BPM + fase desplazada (`0.23 s`):** genera un `AudioStreamWAV` sintético a `128 BPM` con padding inicial `0.23 s` (sección calma + Drop), valida error de BPM, error de `beat_phase_sec` y error de alineación de las notas generadas contra los pulsos reales (`<= 25 ms`).
   - **Test 2 — Pre-transiente débil vs. golpe fuerte:** valida que el golpe fuerte reemplaza al pre-transiente débil.
   - **Test 3 — Estrés ergonómico a 2 pulgares (`0` violaciones):** genera charts en `EASY`/`NORMAL`/`HARD` × `TAP_AND_HOLD`/`TAP_ONLY` sobre audio sintético denso + sobre las canciones reales de `res://assets/songs/` + sobre `GameSession.build_demo_chart()`, certificando `chart.validate().valid == true`, `validate_two_thumb_ergonomics().valid == true`, `hold_thumb_collisions == 0`, `same_thumb_chords == 0` y cumplimiento de `same_thumb_min_gap_sec`.
   - **Test 4 — Curva de dificultades y Drops:** verifica `count(EASY) < count(NORMAL) < count(HARD)`, `chords(EASY) == 0`, presencia de acordes válidos `1 izq + 1 der` en Drops de `NORMAL`/`HARD`, y `TAP_ONLY` con `0` holds.
   - **Test 5 — Caché `v2` y preservación de récords + exclusiones:** valida nueva firma `"v2"`, versión de `project.godot == "1.0.4"` y `git diff -- "*.tscn"` vacío.

### Pruebas Manuales (PC `450x800` y Android)
1. Jugar `Demo Integrada` y 2–3 canciones de `assets/songs/` (y una pista importada `.mp3`) en `Fácil`, `Normal` y `Difícil`.
2. Verificar al oído y visualmente que los golpes caen justo sobre los bombos/cajas reales (incluso en canciones con silencio inicial) y que durante cualquier `Hold` jamás aparezca una nota en el carril vecino del mismo pulgar.
3. Confirmar que el incremento de energía entre verso y Drop se siente natural y jugable a 2 pulgares en pantalla táctil.

---

## 8. Casos Límite
- **Pista muy corta (`< 2 s`) o silenciosa:** `beat_phase_sec = 0.0`, `bpm_estimate = 120.0`, `validate()` y `validate_two_thumb_ergonomics()` válidos sin divisiones por cero.
- **Análisis sintético legado sin clave `"beat_phase_sec"`:** `AutoChartGenerator` detecta la ausencia y estima la fase automáticamente desde `onset_frames`.
- **Canción con sostenido continuo muy largo (`rms` alto constante):** los `Hold` se acotan a `max_hold_sec` por dificultad (`1.45–1.75 s`) y se recortan antes de cualquier nota futura del mismo pulgar menos $M_{\text{rel}}$.
- **Modo `TAP_ONLY`:** todas las notas conservan `duration_sec == 0.0`, manteniendo la sincronización de fase, alternancia anti-trino y acordes válidos a 2 manos.

---

## 9. Impacto en Rendimiento
- **Muy bajo / únicamente offline en hilo de trabajo (`WorkerThreadPool`):**
  - La estimación de fase evalúa `~100` fases candidatas sobre `onset_frames` (`~9000` floats en una pista de 3 min) en `< 4 ms` en el worker de Fase 3, sin afectar el hilo principal ni los FPS de gameplay.
  - En runtime durante `GameSession`, el costo adicional es `0` (los charts validados se leen directamente desde `ChartData` / caché `"v2"`).

---

## 10. Procedimiento de Reversión
1. Gracias al tag `pre-fase-9` creado en `main`, es posible inspeccionar o revertir limpiamente mediante `git revert <commit_fase_9>` o comparar contra `pre-fase-9`.
2. Los récords del jugador en `user://song_records.cfg` no sufren ninguna alteración de esquema.
