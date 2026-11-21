# Spec 11 — Fase 2: Corrección del Scroll Táctil y Filtrado Toque vs. Arrastre en Menús

## 1. Nombre y Objetivo
- **Nombre:** Scroll Táctil Fluido y Protección Anti-Toque Accidental en Listas del Menú (`Fase 2`).
- **Objetivo:** Habilitar un desplazamiento vertical táctil fluido, determinístico y sin bloqueos en todas las listas y paneles desplazables del menú principal (`CANCIONES`, `IMPORTAR` / canciones importadas, `AJUSTES` y el modal de configuración de canción), evitando activaciones accidentales de botones al arrastrar con el dedo en Android y conservando intacto el uso con rueda de ratón en escritorio.

---

## 2. Problema que Resuelve
Tras inspeccionar `ui/main_menu.gd` y `ui/main_menu.tscn`:
1. **`SongsTabScroll` (`CANCIONES`) e `ImportedListScroll` (`IMPORTAR`)** se crean con los valores por defecto de Godot 4 (`scroll_deadzone = 0`, `horizontal_scroll_mode` sin deshabilitar explícitamente) y sin gestor táctil de arrastre/umbral.
2. **Los botones de fila (`SongRow_*`, `ImportedRow_*`) y los controles interactivos internos** conservan `mouse_filter = Control.MOUSE_FILTER_STOP` por defecto, interceptando `InputEventScreenTouch` / `InputEventScreenDrag` e impidiendo que el `ScrollContainer` padre reciba el gesto de desplazamiento, o bien disparando `pressed` (abriendo la canción o alternando un ajuste) al levantar el dedo tras arrastrar.
3. **`AJUSTES` (`SettingsTabContainer`) y el modal de configuración (`SongModalPanel` -> `SongModalVBox`)** no están envueltos en un `ScrollContainer`, por lo que no soportarían desplazamiento táctil si su contenido crece en fases posteriores o en pantallas de menor relación de aspecto.

---

## 3. Alcance Exacto y Dependencias
- **Rama de trabajo:** `main`
- **Dependencia con Fase 1:** Parte directamente del commit `a3cf69d` (`fix(android,release): disable quit_on_go_back for back gesture and bump version code for v1.0.4`), manteniendo intactos `config/quit_on_go_back=false`, `config/auto_accept_quit=false`, el debounce de `300 ms` del gesto Atrás y la versión `v1.0.4` (`version/code=6`).
- **Archivos inspeccionados (lectura):**
  - `AGENTS.md`
  - `specs/09_main_menu_and_song_selector.md`
  - `ui/main_menu.gd`
  - `ui/main_menu.tscn`
  - `ui/game_session.tscn`
  - `ui/safe_hud.gd`
- **Archivos a crear/modificar en Fase 2:**
  1. `specs/11_menu_touch_scroll.md` (esta especificación)
  2. `ui/main_menu.gd` (único script `.gd` modificado)
- **Exclusiones explícitas:**
  - **Cero modificaciones a archivos `.tscn`** (`ui/main_menu.tscn`, `ui/game_session.tscn`, etc.), en cumplimiento estricto de `AGENTS.md` (§6).
  - No se modifica `project.godot`, `export_presets.cfg`, ni archivos de `gameplay/` o `core/`.

---

## 4. Diseño Técnico de Scroll Táctil en Godot 4 (`ui/main_menu.gd`, tipado estático estricto)

### 4.1. Constantes y Estado de Control Táctil
```gdscript
const TOUCH_SCROLL_DEADZONE_PX: int = 20
const TOUCH_SCROLL_DRAG_THRESHOLD_PX: float = 18.0
```
Estado interno tipado en `MainMenu`:
- `_touch_scroll_containers: Array[ScrollContainer] = []` — registro de todos los `ScrollContainer` del menú (`SongsTabScroll`, `ImportedListScroll`, `SettingsTabScroll`, `SongModalScroll`).
- `_active_scroll_touch_index: int = -1`
- `_active_scroll_container: ScrollContainer = null`
- `_touch_scroll_start_pos: Vector2 = Vector2.ZERO`
- `_touch_scroll_last_pos: Vector2 = Vector2.ZERO`
- `_touch_scroll_start_v: int = 0`
- `_touch_scroll_accum_y: float = 0.0`
- `_touch_scroll_drag_active: bool = false`
- `_suppress_scroll_button_press: bool = false`

### 4.2. Helper Reutilizable `_configure_touch_scroll_container(p_scroll: ScrollContainer) -> void`
Aplicado en tiempo de ejecución sobre `SongsTabScroll`, `ImportedListScroll`, `SettingsTabScroll` (envolviendo `SettingsTabContainer`) y `SongModalScroll` (envolviendo `_modal_vbox` dentro de `_song_modal_panel`):
- `p_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO`
- `p_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED`
- `p_scroll.scroll_deadzone = TOUCH_SCROLL_DEADZONE_PX` (`20`)
- `p_scroll.mouse_filter = Control.MOUSE_FILTER_PASS`
- Registra `p_scroll` en `_touch_scroll_containers` (sin duplicados).
- Aplica `_apply_scroll_children_mouse_filter(p_scroll)` para asegurar que **todos los botones y controles interactivos hijos** dentro del `ScrollContainer` usen `Control.MOUSE_FILTER_PASS` (mientras etiquetas/contenedores decorativos mantienen `MOUSE_FILTER_IGNORE` o `MOUSE_FILTER_PASS`, nunca `MOUSE_FILTER_STOP`).

### 4.3. Desplazamiento Determinístico 1:1 y Protección Anti-Toque Accidental (`> 18.0 px`)
En `_input(p_event: InputEvent) -> void` (conviviendo limpiamente con la intercepción de `KEY_BACK`):
1. **`InputEventScreenTouch` (`pressed == true`):**
   - Restablece siempre el estado de supresión (`_suppress_scroll_button_press = false`, `_touch_scroll_drag_active = false`, `_touch_scroll_accum_y = 0.0`).
   - Identifica el `ScrollContainer` visible superior en jerarquía (priorizando `SongModalScroll` si el modal de canción está abierto; bloqueando la búsqueda si el modal de salida o `_file_dialog` están abiertos) cuyo `get_global_rect().has_point(touch.position)` sea verdadero.
   - Guarda `_active_scroll_touch_index = touch.index`, `_active_scroll_container`, `_touch_scroll_start_pos = touch.position`, `_touch_scroll_last_pos = touch.position`, `_touch_scroll_start_v = p_scroll.scroll_vertical`.
2. **`InputEventScreenDrag` (`index == _active_scroll_touch_index` y `_active_scroll_container != null`):**
   - Calcula `step_y: float = drag.position.y - _touch_scroll_last_pos.y` (respaldo a `drag.relative.y` si las posiciones coinciden).
   - Actualiza `_touch_scroll_last_pos = drag.position`, `_touch_scroll_accum_y += absf(step_y)` y `net_y: float = drag.position.y - _touch_scroll_start_pos.y`.
   - Si `maxf(_touch_scroll_accum_y, absf(net_y)) > TOUCH_SCROLL_DRAG_THRESHOLD_PX` (`18.0 px`):
     - Marca `_touch_scroll_drag_active = true` y `_suppress_scroll_button_press = true`.
     - Calcula el desplazamiento máximo permitido `max_v: int = _get_scroll_max_vertical(_active_scroll_container)` (diferencia entre alto del hijo contenido y alto del `ScrollContainer`, clamped `>= 0`).
     - Si `max_v > 0`, aplica `scroll_vertical = clampi(_touch_scroll_start_v - int(round(net_y)), 0, max_v)` (seguimiento exacto 1:1 con el dedo, sin doble velocidad y respetando estrictamente los topes `[0, max_v]` sin rebotes rotos).
     - Marca el evento de arrastre como manejado (`vp.set_input_as_handled()`).
3. **`InputEventScreenTouch` (`pressed == false` y `index == _active_scroll_touch_index`):**
   - Conserva `_suppress_scroll_button_press = _touch_scroll_drag_active` para que cualquier señal `pressed` disparada en este soltado sea bloqueada.
   - Libera `_active_scroll_touch_index = -1`, `_active_scroll_container = null` y `_touch_scroll_drag_active = false`.
4. **Reset limpio en ratón (`InputEventMouseButton` con `pressed == true`):**
   - Si no hay arrastre táctil activo, limpia `_suppress_scroll_button_press = false` para no interferir nunca con clics de escritorio ni con la rueda del mouse (`MOUSE_BUTTON_WHEEL_UP` / `MOUSE_BUTTON_WHEEL_DOWN`), que siguen gestionados de forma nativa por `ScrollContainer`.
5. **Activación protegida en filas y botones dentro de `ScrollContainer`:**
   - Las filas de `CANCIONES` e `IMPORTAR` conectan a `_on_song_row_pressed(p_entry: Dictionary) -> void`: si `_consume_suppressed_scroll_press()` retorna `true`, cancela la apertura del modal y evita reproducir SFX fantasma; si es un toque válido, reproduce `ui_sfx_player.play_button_click()` y abre `open_song_setup_modal(p_entry)`.
   - Los botones de `AJUSTES` dentro de `SettingsTabScroll` (`_bgm_toggle_button`, `_bgm_prev_button`, `_bgm_next_button`, `_bgm_mode_button`) aplican el mismo guard `_consume_suppressed_scroll_press()` al inicio de sus callbacks.

---

## 5. Casos Límite Cubiertos
| Caso Límite | Comportamiento Esperado |
| :--- | :--- |
| **Lista corta (contenido <= alto visible)** | `max_v == 0`; `scroll_vertical` permanece en `0`, el layout queda intacto y sin saltos ni barras innecesarias (`SCROLL_MODE_AUTO`). |
| **Lista extensa (10+ canciones)** | Arrastrar verticalmente `> 18 px` desplaza `scroll_vertical` de forma fluida 1:1 sin activar ninguna fila; barra vertical automática visible cuando corresponde. |
| **Toque estático (`< 8 px` de jitter)** | No supera el umbral de `18.0 px`; al soltar el dedo la fila abre el modal de configuración y reproduce el SFX de clic. |
| **Arrastre sobre botón de canción (`> 25 px`)** | `scroll_vertical` avanza y `_suppress_scroll_button_press` bloquea la activación al soltar; el siguiente toque normal vuelve a funcionar limpiamente. |
| **Límites superior (`0`) e inferior (`max_v`)** | `clampi(..., 0, max_v)` impide valores negativos o sobre-desplazamiento roto más allá de la última fila. |
| **Rueda del mouse en PC** | `MOUSE_BUTTON_WHEEL_UP` / `MOUSE_BUTTON_WHEEL_DOWN` siguen funcionando nativamente en `ScrollContainer`. |
| **Cambio de pestaña / cierre de modal** | Reinicia el estado de toque activo (`_reset_touch_scroll_state()`) para evitar arrastres huérfanos entre vistas. |

---

## 6. Impacto en Rendimiento
- Complejidad **O(1)** por evento de toque/arrastre (`<= 4` contenedores registrados en `_touch_scroll_containers`), cero asignaciones de memoria por frame en `_process()`, sin nodos adicionales por fila y sin impacto en el rendimiento de gameplay (`GameSession` no se toca).

---

## 7. Criterios de Aceptación Verificables
- [ ] Todos los `ScrollContainer` del menú (`SongsTabScroll`, `ImportedListScroll`, `SettingsTabScroll`, `SongModalScroll`) pasan por `_configure_touch_scroll_container()` con `vertical_scroll_mode == SCROLL_MODE_AUTO`, `horizontal_scroll_mode == SCROLL_MODE_DISABLED` y `scroll_deadzone == 20` (`>= 16`).
- [ ] Todos los botones de fila (`SongRow_*`, `ImportedRow_*`) y controles hijos dentro de cada `ScrollContainer` tienen `mouse_filter == Control.MOUSE_FILTER_PASS`.
- [ ] Un arrastre vertical simulado de `> 25 px` sobre una lista larga desplaza `scroll_vertical > 0` y **no** abre el modal de configuración al soltar el dedo.
- [ ] Un toque estático (`< 8 px`) sobre una fila **sí** abre el modal de configuración con la pista correspondiente.
- [ ] El desplazamiento queda acotado a `[0, max_v]` en listas largas y fijado en `0` en listas cortas.
- [ ] `git diff -- "*.tscn"` está vacío (ningún `.tscn` alterado).
- [ ] `--headless --quit --check-only` sobre `res://ui/main_menu.gd` retorna código `0` con 0 errores y 0 advertencias.

---

## 8. Plan de Pruebas (Automatizadas y Manuales)

### 8.1. Automatizadas (Headless, eliminando `scratch/` al terminar)
1. Validación estática:
   ```powershell
   & "C:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://ui/main_menu.gd"
   ```
2. Prueba funcional rápida `scratch/verify_phase2_touch_scroll.gd` (terminando con `quit(0)`):
   - Monta `MainMenu`, abre la vista de pestañas (`CANCIONES`), puebla 12 entradas para asegurar lista larga (`content_h > scroll_h`) y aplica `apply_hud_safe_rect(Rect2(64.8, 0.0, 950.4, 1920.0))`.
   - Verifica `scroll_deadzone == 20` (`>= 16`), `vertical_scroll_mode == SCROLL_MODE_AUTO`, `horizontal_scroll_mode == SCROLL_MODE_DISABLED` en los `ScrollContainer` del menú, y `mouse_filter == Control.MOUSE_FILTER_PASS` en todas las filas.
   - Simula `InputEventScreenTouch(pressed=true)` -> `InputEventScreenDrag` vertical de `40 px` (`> 25 px`) -> `InputEventScreenTouch(pressed=false)` + `row_btn.pressed.emit()` -> comprueba `scroll_vertical > 0` y `is_song_modal_open() == false`.
   - Simula un nuevo toque estático (`< 8 px`, desplazamiento `4 px`) -> `InputEventScreenTouch(pressed=false)` + `row_btn.pressed.emit()` -> comprueba `is_song_modal_open() == true`.
   - Verifica topes superior (`0`) e inferior (`max_v`) y comportamiento en lista corta (`scroll_vertical == 0`).
   - Elimina `scratch/` en bloque `finally`.
3. Comprobación Git:
   ```powershell
   git diff -- "*.tscn"
   git status -s
   ```

### 8.2. Pruebas Manuales (Android y PC)
- **Android:** Arrastrar hacia arriba/abajo sobre `CANCIONES`, `IMPORTAR` (con varias pistas) y `AJUSTES` confirmando desplazamiento suave sin abrir pistas por error; luego tocar brevemente una pista para abrir el modal.
- **PC (`F5`):** Desplazar con rueda del ratón en `CANCIONES` e `IMPORTAR` y hacer clic izquierdo en una canción para abrir el modal.

---

## 9. Diff Esperado (Resumen)
- **`ui/main_menu.gd`:**
  - Nuevas constantes `TOUCH_SCROLL_DEADZONE_PX = 20`, `TOUCH_SCROLL_DRAG_THRESHOLD_PX = 18.0`.
  - Nuevas propiedades de estado para tracking táctil y referencias `_songs_scroll`, `_import_scroll`, `_settings_scroll`, `_modal_scroll`.
  - Nuevo helper `_configure_touch_scroll_container(p_scroll: ScrollContainer) -> void`, `_apply_scroll_children_mouse_filter(p_root: Node) -> void`, `_handle_touch_scroll_input(p_event: InputEvent) -> void`, `_get_scroll_max_vertical(p_scroll: ScrollContainer) -> int`, `_consume_suppressed_scroll_press() -> bool` y `_on_song_row_pressed(p_entry: Dictionary) -> void`.
  - Envoltura de `SettingsTabContainer` en `SettingsTabScroll` y de `_modal_vbox` en `SongModalScroll`, manteniendo el mismo layout visual.
  - `row_btn.mouse_filter = Control.MOUSE_FILTER_PASS` y conexión protegida en `_rebuild_entry_list()`.

---

## 10. Procedimiento de Reversión
```powershell
git revert <commit_hash_fase_2>
```
O restaurar al commit de Fase 1 (`a3cf69d`):
```powershell
git checkout a3cf69d -- ui/main_menu.gd
Remove-Item "specs/11_menu_touch_scroll.md"
```
