# Spec 13 — Fase 4: Barra de Progreso de Canción en Gameplay con Indicador Cuadrado Rotatorio

## 1. Nombre y Objetivo
- **Nombre:** Barra de Progreso Inferior con Indicador Cuadrado Rotatorio en Gameplay (`Fase 4`).
- **Objetivo:** Mostrar al jugador una referencia visual minimalista y no intrusiva del avance actual de la canción en la zona inferior segura durante el gameplay, sincronizada de forma determinística con el reloj maestro `DSPClock` (sin acumular `delta`) y acompañada de un pequeño indicador cuadrado neón que rota continuamente solo mientras el audio se reproduce de forma activa.

---

## 2. Problema que Resuelve
Actualmente, durante una partida en `GameSession`, el HUD superior (`SafeHud`) muestra `SCORE`, `ACC`, el botón `PAUSA` y la barra de peligro/riesgo, pero el jugador no tiene ninguna referencia visual de cuánto falta para terminar la canción. Además, en `v1.0.3` la línea de juicio (`hit_line_y`) se elevó `175.0 px` desde `0.84 * height`, dejando un espacio inferior limpio ideal para una barra de progreso discreta que respete `ScreenSafeAdapter` y no interfiera con notas ni toques.

---

## 3. Alcance Exacto y Dependencias
- **Rama de trabajo:** `main`
- **Dependencias con fases anteriores:**
  - **Fase 1 (`a3cf69d`):** Mantiene intactos `quit_on_go_back=false`, `auto_accept_quit=false` y `v1.0.4` (`version/code=6`).
  - **Fase 2 (`caf695e`):** Sin impacto en menús.
  - **Fase 3 (`d2339e3`):** Sin impacto en la carga no bloqueante de canciones; recibe el `ChartData` ya validado (con `duration_sec`) al iniciar `GameSession`.
  - **Elevación previa de `hit_line_y` (`LaneField.HIT_LINE_VERTICAL_LIFT_PX = 175.0`):** La barra inferior se posiciona siempre por debajo de la línea de juicio y dentro del área segura inferior de `ScreenSafeAdapter`.
- **Archivos inspeccionados (lectura):**
  - `AGENTS.md`
  - `core/audio/dsp_clock.gd`
  - `gameplay/game_session.gd`
  - `gameplay/lane_field.gd`
  - `platform/screen_safe_adapter.gd`
  - `ui/safe_hud.gd`
- **Archivos a crear/modificar en Fase 4:**
  1. `specs/13_gameplay_song_progress_bar.md` (esta especificación)
  2. `core/audio/dsp_clock.gd` (getters de solo lectura `get_total_duration_sec() -> float` e `is_paused() -> bool`)
  3. `ui/safe_hud.gd` (control ligero `_song_progress_bar` construido por código con `_draw`, cálculo determinístico `compute_song_progress()`, rotación condicionada a reproducción activa, congelamiento en pausa y reinicio a `0.0`)
  4. `gameplay/game_session.gd` (pasar `p_chart.duration_sec` a `safe_hud.set_song_duration_sec(...)` al cargar/reiniciar partida en `start_chart_session()`)
- **Exclusiones explícitas:**
  - **Cero modificaciones a archivos `.tscn`** (`ui/game_session.tscn`, `ui/main_menu.tscn`, etc.), en cumplimiento estricto de `AGENTS.md` (§6).
  - Ninguna lógica de DSP/FFT en UI (`AGENTS.md` §4): `SafeHud` únicamente consume señales y lecturas de tiempo/duración desde `DSPClock`.

---

## 4. Diseño Visual y Matemático (Tipado Estático Estricto, solo `.gd`)

### 4.1. Ubicación y Layout Responsivo (`SafeHud.apply_hud_safe_rect`)
- El control `_song_progress_bar: Control` vive dentro de `_safe_container` en `SafeHud` (debajo de `_pause_overlay` y `_results_overlay` en orden de z/hijos) con `mouse_filter = Control.MOUSE_FILTER_IGNORE` para no bloquear jamás toques de carriles en `RhythmInputAdapter`.
- **Dimensiones y márgenes (proporcionales al `hud_safe_rect` entregado por `ScreenSafeAdapter`, sin coordenadas `Y` fijas en píxeles absolutos):**
  - `SONG_PROGRESS_CONTROL_HEIGHT_PX: float = 44.0`
  - `SONG_PROGRESS_SIDE_INSET_PX: float = 24.0`
  - `SONG_PROGRESS_BOTTOM_MARGIN_PX: float = 36.0`
  - `bar_x = SONG_PROGRESS_SIDE_INSET_PX`
  - `bar_w = maxf(160.0, safe_w - (SONG_PROGRESS_SIDE_INSET_PX * 2.0))`
  - `bar_y = clampf(safe_h - SONG_PROGRESS_BOTTOM_MARGIN_PX - SONG_PROGRESS_CONTROL_HEIGHT_PX, 0.0, maxf(0.0, safe_h - SONG_PROGRESS_CONTROL_HEIGHT_PX))`
- **Verificación de holgura respecto a `hit_line_y`:**
  - En `1080x1920` (9:16): `hit_line_y = 1437.8 px` (riel inferior en `1455.8 px`); la barra ocupa `Y ∈ [1840.0, 1884.0]` (> `384 px` debajo del riel inferior, respetando `36 px` sobre el margen inferior seguro).
  - En `1080x2400` (20:9 con barra de gestos inferior ~`80 px`, `hud_safe_rect.end.y = 2320`): `hit_line_y = 1841.0 px` (`bottom_rail = 1859.0 px`); la barra ocupa `Y ∈ [2240.0, 2284.0]` (> `380 px` debajo del riel inferior y completamente encima de la zona de gestos Android).

### 4.2. Cálculo Determinístico del Progreso (Sin Acumulación de `delta`)
En `SafeHud`:
```gdscript
static func compute_song_progress(p_current_sec: float, p_total_sec: float) -> float:
	if p_total_sec <= 0.0:
		return 0.0
	return clampf(p_current_sec / maxf(p_total_sec, 0.001), 0.0, 1.0)
```
- **Durante `lead_in` (`current_sec < 0.0`) y en `0.0`:** `compute_song_progress` retorna exactamente **`0.0`**.
- **Durante la reproducción (`0.0 <= current_sec <= total_sec`):** se actualiza en cada frame / señal `dsp_clock.dsp_time_updated` directamente desde `dsp_clock.get_current_dsp_time()` y `total_duration_sec` (`dsp_clock.get_total_duration_sec()` o el valor entregado por `set_song_duration_sec()`).
- **Al finalizar (`dsp_clock.playback_finished`):** marca `_song_progress_completed = true` y fija `_song_progress = 1.0`.
- **En pausa (`dsp_clock.is_playing() == false`, `is_pause_menu_open()`, `is_resume_countdown_active()` o `is_results_overlay_open()`):** el progreso y el ángulo de rotación quedan **congelados** en sus valores actuales; al reanudar, continúan fluidamente desde ese punto.
- **Al reiniciar o cargar una nueva partida (`reset_hud_display()`):** restablece `_song_progress = 0.0`, `_song_progress_completed = false` y `_progress_square_angle_rad = 0.0`.

### 4.3. Estética Neón del Riel y del Cuadrado Rotatorio (`_draw_song_progress_bar()`)
- Riel horizontal delgado (`rail_left = 14.0`, `rail_right = size.x - 14.0`, `center_y = size.y * 0.5`):
  - **Tramo restante:** línea sutil translúcida `Color(0.55, 0.78, 0.96, 0.22)` (`3.0 px`).
  - **Tramo recorrido (`rail_left -> marker_x`):** halo neón cian suave (`Color(0.22, 0.88, 1.0, 0.26)`, `8.0 px`) + trazo nítido cian (`Color(0.45, 0.96, 1.0, 0.88)`, `3.0 px`).
- **Indicador cuadrado rotatorio en `(marker_x, center_y)`:**
  - `marker_x = lerpf(rail_left, rail_right, _song_progress)`.
  - Ángulo `_progress_square_angle_rad`: avanza a `SONG_PROGRESS_ROTATION_SPEED_RAD = 2.4 rad/s` (`fmod(..., TAU)`) **únicamente cuando la reproducción está activa** (`dsp_clock.is_playing() and not paused/countdown/results/completed`).
  - Se dibujan 4 vértices rotados para un halo cuadrado suave (`20.0 px`, `Color(0.28, 0.94, 1.0, 0.34)`), núcleo cuadrado brillante (`14.0 px`, `Color(0.84, 0.99, 1.0, 0.98)`) y borde cian (`1.8 px`, `Color(0.32, 0.96, 1.0, 1.0)`).

---

## 5. Casos Límite Cubiertos
| Caso Límite | Comportamiento Esperado |
| :--- | :--- |
| **Duración `<= 0.0`** | `compute_song_progress(current, 0.0)` retorna `0.0` de forma segura sin división por cero ni `NaN`/`INF`. |
| **Tiempo negativo (`lead_in`)** | `clampf` fija el progreso exactamente en `0.0` hasta que inicia el audio en `t = 0.0`. |
| **Pausa y reanudación** | Tanto `_song_progress` como `_progress_square_angle_rad` se congelan durante Pausa y el conteo regresivo `3-2-1`, continuando sin saltos al reanudar. |
| **Reinicio de canción / nueva partida** | `reset_hud_display()` + `set_song_duration_sec()` reinician progreso y rotación a `0.0` de inmediato. |
| **Fin de pista (`playback_finished`)** | El indicador alcanza `1.0` exactamente y detiene su rotación. |
| **Pantallas `20:9` y `16:9` (curvas / barra de gestos)** | Ubicada dentro de `hud_safe_rect`, siempre por debajo de `hit_line_y` y por encima del `safe_bottom` del dispositivo, sin interceptar toques (`MOUSE_FILTER_IGNORE`). |

---

## 6. Impacto en Rendimiento
- Un único nodo `Control` ligero con `_draw()` personalizado (3 `draw_line` + 2 `draw_colored_polygon` + 1 `draw_polyline`, complejidad **O(1)**), `queue_redraw()` invocado solo cuando el progreso o la rotación cambian (0 redibujos innecesarios en pausa), cero shaders y cero asignaciones de nodos por frame.

---

## 7. Criterios de Aceptación Verificables
- [ ] `SafeHud.compute_song_progress(0.0, 120.0) == 0.0`, `compute_song_progress(60.0, 120.0) == 0.5`, `compute_song_progress(120.0, 120.0) == 1.0`, y `compute_song_progress(10.0, 0.0) == 0.0` (sin división por cero).
- [ ] En `GameSession`, al iniciar la pista el progreso arranca en `0.0`, avanza de forma determinística con `DSPClock` (`seek`/`dsp_time_updated`) y llega a `1.0` al finalizar.
- [ ] Al pausar (`open_pause_menu()`), tanto el progreso como el ángulo de rotación del cuadrado se congelan durante varios frames `_process()`, y al reanudar continúan.
- [ ] Al reiniciar la partida (`_on_restart_requested()` / `start_chart_session()`), el progreso vuelve exactamente a `0.0`.
- [ ] El rectángulo global de `_song_progress_bar` queda estrictamente por debajo de `hit_line_y` (`bar_rect.position.y > hit_line_global_y + 20.0`), dentro de `hud_safe_rect` tanto en `16:9` (`1080x1920`) como en `20:9` (`1080x2400`), y con `mouse_filter == Control.MOUSE_FILTER_IGNORE`.
- [ ] `--headless --quit --check-only` sobre `res://core/audio/dsp_clock.gd`, `res://ui/safe_hud.gd` y `res://gameplay/game_session.gd` termina con 0 errores y 0 advertencias.
- [ ] `git diff -- "*.tscn"` está completamente vacío.

---

## 8. Plan de Pruebas (Automatizadas y Manuales)

### 8.1. Automatizadas (Headless, eliminando `scratch/` siempre en `finally`)
1. Validación estática:
   ```powershell
   $godot = "C:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
   & $godot --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://core/audio/dsp_clock.gd"
   & $godot --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://ui/safe_hud.gd"
   & $godot --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://gameplay/game_session.gd"
   ```
2. Prueba headless temporal `scratch/verify_phase4_progress_bar.gd` (terminando con `quit(0)`):
   - **(a)** Verifica `compute_song_progress()` en `0.0`, `0.5`, `1.0`, tiempo negativo (`-2.0 -> 0.0`) y duración `0.0` / negativa (`-> 0.0`, sin división por cero).
   - **(b)** Instancia `GameSession` con la demo (`15.0 s`), verifica progreso `0.0` al inicio, mueve `dsp_clock.seek(7.5)` y comprueba progreso `0.5`, comprueba que el ángulo del cuadrado rota mientras reproduce, pausa (`open_pause_menu()`) y verifica que ni progreso ni ángulo cambian tras varios `_process(0.05)`, luego simula `playback_finished` -> `1.0`, y finalmente reinicia (`_on_restart_requested()`) -> progreso `0.0`.
   - **(c)** Verifica posicionamiento inferior en `1080x1920` (9:16) y `1080x2400` (20:9 con safe bottom `80 px`): `bar_rect.position.y > hit_line_y + 20.0`, `bar_rect.end.y <= hud_safe_rect.end.y` y `mouse_filter == MOUSE_FILTER_IGNORE`.
   - **(d)** Comprueba `git diff -- "*.tscn"` vacío y elimina `scratch/` en `finally`.

### 8.2. Pruebas Manuales (Android y PC)
- Iniciar una canción en PC (`F5`) y en Android: confirmar que el riel inferior y el cuadrado neón rotatorio avanzan de izquierda a derecha de forma suave debajo de la línea de juicio sin estorbar al tocar, se congelan en Pausa y vuelven a `0.0` al reiniciar.

---

## 9. Diff Esperado (Resumen)
- **`core/audio/dsp_clock.gd`:** Nuevos getters `get_total_duration_sec() -> float` e `is_paused() -> bool`.
- **`ui/safe_hud.gd`:** Constantes visuales/de rotación, control `_song_progress_bar` creado por código en `_ensure_ui_nodes()`, posicionado en `apply_hud_safe_rect()`, sincronizado con `dsp_clock` en `_process()` y señales `dsp_time_updated` / `playback_finished`, y dibujado en `_draw_song_progress_bar()`.
- **`gameplay/game_session.gd`:** Llamada a `safe_hud.set_song_duration_sec(p_chart.duration_sec)` en `start_chart_session()`.

---

## 10. Procedimiento de Reversión
```powershell
git revert <commit_hash_fase_4>
```
O restaurar al commit de Fase 3 (`d2339e3`):
```powershell
git checkout d2339e3 -- core/audio/dsp_clock.gd ui/safe_hud.gd gameplay/game_session.gd
Remove-Item "specs/13_gameplay_song_progress_bar.md"
```
