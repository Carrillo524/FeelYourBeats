# Spec 15 — Fase 6: Transiciones Animadas Tipo Slider y Resaltado Deslizante entre Pestañas del Menú

## 1. Nombre y Objetivo
- **Nombre:** Transiciones Horizontales Tipo Slider con Rebote Sutil y Resaltado Deslizante entre Pestañas (`Fase 6`).
- **Objetivo:** Sustituir el cambio instantáneo entre las pestañas del navegador principal (`CANCIONES`, `IMPORTAR`, `AJUSTES`) por una transición animada limpia de `~220 ms` (`150–300 ms`) con indicador neón deslizante sobre la pestaña activa, desplazamiento direccional horizontal recortado (`clip_contents = true`) y un rebote sutil de asentamiento (`10 px` en `50 ms`), gobernada exclusivamente por los botones de pestaña y preservando el estado de scroll de cada vista.

---

## 2. Problema que Resuelve
Actualmente, en `ui/main_menu.gd`:
1. `_refresh_tab_visuals()` alterna `visible = true/false` de golpe, sin continuidad direccional ni animación en el indicador de pestaña activa.
2. Las tres vistas de pestaña (`SongsTabScroll`, `ImportTabContainer`, `SettingsTabScroll`) son hijas directas de `MarginContainer` (`ContentSheetInner`), que sobrescribe la posición `position.x` de sus hijos en cada paso de layout, impidiendo animaciones horizontales limpias sin un contenedor viewport dedicado con `clip_contents = true`.

---

## 3. Alcance Exacto y Dependencias
- **Rama de trabajo:** `main`
- **Dependencias con fases anteriores:**
  - **Fase 1 (`a3cf69d`):** Mantiene intactos `quit_on_go_back=false`, `auto_accept_quit=false` y `v1.0.4`.
  - **Fase 2 (`caf695e`):** Conserva intactos los `ScrollContainer` táctiles (`SongsTabScroll`, `ImportedListScroll`, `SettingsTabScroll`) y sus valores de `scroll_vertical` antes y después de cada cambio de pestaña; bloquea scroll táctil durante `_is_tab_transitioning == true`.
  - **Fase 3 (`d2339e3`):** Impide cambiar de pestaña mientras `_is_processing_song == true` o `_is_launching == true`.
  - **Fase 5 (`1cd7298` / `644e72c`):** Impide cambiar de pestaña mientras `_is_playing_startup_intro == true` (`1.50 s`).
- **Archivos inspeccionados (lectura):**
  - `AGENTS.md`
  - `specs/09_main_menu_and_song_selector.md`
  - `specs/11_menu_touch_scroll.md`
  - `specs/14_startup_intro_animation.md`
  - `ui/main_menu.gd`
  - `ui/main_menu.tscn`
- **Archivos a crear/modificar en Fase 6:**
  1. `specs/15_menu_tab_slider_transitions.md` (esta especificación)
  2. `ui/main_menu.gd` (único script `.gd` modificado)
- **Exclusiones explícitas:**
  - **Cero modificaciones a archivos `.tscn`** (`ui/main_menu.tscn`, `ui/game_session.tscn`, etc.), cumpliendo `AGENTS.md` (§6).
  - **Sin gestos de swipe lateral:** El cambio de pestañas es controlado exclusivamente por los botones `CANCIONES`, `IMPORTAR` y `AJUSTES` (no se añade swipe táctil horizontal).

---

## 4. Diseño Técnico (`ui/main_menu.gd`, tipado estático estricto)

### 4.1. Jerarquía de Contenedores por Código (Recorte Limpio e Indicador Deslizante)
- **Barra de pestañas con indicador deslizante (`_tabs_bar_wrapper`):**
  - `_tabs_bar_wrapper: Control` (`custom_minimum_size = Vector2(0.0, 92.0)`, `size_flags_horizontal = SIZE_EXPAND_FILL`) dentro de `_browser_screen_container` en reemplazo directo de `_tabs_row` como hijo de primer nivel:
    - `_tabs_row` (`TopTabsRow`, `HBoxContainer`, `PRESET_TOP_WIDE`, alto `84.0`) aloja `TabSongsButton`, `TabImportButton`, `TabSettingsButton`.
    - `_tab_indicator_bar: Panel` (`TabActiveIndicatorBar`, `mouse_filter = MOUSE_FILTER_IGNORE`, alto `5.0 px`, ubicado en `y = 85.0`) con `_style_tab_indicator` (cian neón brillante con sombra difuminada) que se desliza suavemente mediante `Tween` hacia `(target_btn.position.x, target_btn.size.x)`.
- **Viewport de vistas de pestaña (`_tab_content_viewport`):**
  - Dentro de `ContentSheetInner` (`MarginContainer`), se añade `_tab_content_viewport: Control` (`name = "TabContentViewport"`, `clip_contents = true`, `SIZE_EXPAND_FILL` horizontal y vertical).
  - `_songs_tab_container`, `_import_tab_container` y `_settings_tab_container` pasan a ser hijos directos de `_tab_content_viewport` con `PRESET_FULL_RECT`, permitiendo desplazar libremente `position.x` durante la transición sin conflictos con `MarginContainer` y recortando perfectamente ambos paneles dentro de los bordes de la lámina translúcida.

### 4.2. Constantes, Estado y Bloqueo Anti-Solapamiento
```gdscript
const TAB_SLIDE_MAIN_DURATION_SEC: float = 0.17
const TAB_SLIDE_SETTLE_DURATION_SEC: float = 0.05
const TAB_SLIDE_OVERSHOOT_PX: float = 10.0
const TAB_INDICATOR_HEIGHT_PX: float = 5.0
```
- Duración total: `0.17 + 0.05 = 0.22 s` (`220 ms`, dentro de `150–300 ms`).
- Estado tipado:
  - `var _is_tab_transitioning: bool = false` (getter `is_tab_transitioning() -> bool`)
  - `var _tab_transition_tween: Tween = null`
  - `var _tab_transition_outgoing: Control = null`
  - `var _tab_transition_incoming: Control = null`
- **Guardias estrictos en `select_tab(p_tab: int, p_animate: bool = true) -> void`:**
  - Ignora inmediatamente la llamada si `_is_playing_startup_intro`, `_is_processing_song`, `_is_launching` o `_is_tab_transitioning` es `true`.
  - Si `clamped_tab == _active_tab`: sincroniza el indicador en reposo sin disparar transición.
  - Si `not p_animate` o `_browser_screen_container` no está visible (p. ej. al abrir el navegador por primera vez desde portada): aplica el cambio de forma inmediata (`_refresh_tab_visuals()` + `_snap_tab_indicator_to_active()`).

### 4.3. Animación Direccional Slider + Rebote Sutil (`220 ms`)
Sea `old_tab: int = _active_tab` y `target_tab: int = clampi(p_tab, MenuTab.SONGS, MenuTab.SETTINGS)`:
- `var direction: float = 1.0 if target_tab > old_tab else -1.0`
  - `target_tab > old_tab` (`CANCIONES -> IMPORTAR`, `CANCIONES -> AJUSTES`, `IMPORTAR -> AJUSTES`): desliza hacia la **izquierda** (`outgoing: 0 -> -w`, `incoming: +w -> -10 -> 0`).
  - `target_tab < old_tab` (`AJUSTES -> IMPORTAR`, `AJUSTES -> CANCIONES`, `IMPORTAR -> CANCIONES`): desliza hacia la **derecha** (`outgoing: 0 -> +w`, `incoming: -w -> +10 -> 0`).
- **Fase 1 (`0.00 s -> 0.17 s`, paralelo, `TRANS_CUBIC`, `EASE_OUT`):**
  - `outgoing.position:x`: `0.0 -> -direction * slide_w`
  - `incoming.position:x`: `direction * slide_w -> -direction * TAB_SLIDE_OVERSHOOT_PX` (`±10 px`)
  - `_tab_indicator_bar.position:x` y `size:x` hacia el botón de la pestaña destino (en `0.22 s` totales con `TRANS_CUBIC`, `EASE_OUT`).
- **Fase 2 (`0.17 s -> 0.22 s`, rebote/asentamiento de `50 ms`, `TRANS_SINE`, `EASE_OUT`):**
  - `incoming.position:x`: `-direction * TAB_SLIDE_OVERSHOOT_PX -> 0.0`.
- **Finalización (`_finish_tab_transition()`):**
  - Oculta `outgoing` (`visible = false`) y restaura su geometría exacta (`_restore_tab_panel_geometry(outgoing)` -> `position = Vector2.ZERO`, `size = viewport_size`).
  - Mantiene `incoming` visible y estático en `position.x == 0.0` (`_restore_tab_panel_geometry(incoming)`).
  - Sincroniza `_snap_tab_indicator_to_active()`, limpia `_tab_transition_tween = null` y restablece `_is_tab_transitioning = false`.
- **En `_exit_tree()`:** Cancela `_tab_transition_tween` si existe.

### 4.4. Preservación de Estado y Redimensionamiento
- Al cambiar de pestaña nunca se destruyen ni reinician `SongsTabScroll.scroll_vertical`, `ImportedListScroll.scroll_vertical` ni `SettingsTabScroll.scroll_vertical`; al regresar a una pestaña previa, el desplazamiento y controles permanecen exactamente donde los dejó el usuario.
- Al redimensionar la ventana o invocar `apply_hud_safe_rect()` / `_on_tab_viewport_resized()`, si no hay transición en curso se sincronizan las geometrías de los paneles (`position = Vector2.ZERO`, `size = viewport_size`) y del `_tab_indicator_bar`; si hay transición en curso, `_finish_tab_transition()` restaura las geometrías actualizadas al terminar.

---

## 5. Casos Límite Cubiertos
| Caso Límite | Comportamiento Esperado |
| :--- | :--- |
| **Pulsación repetida en medio de la transición** | `_is_tab_transitioning == true` ignora clics adicionales hasta concluir los `220 ms`, evitando animaciones superpuestas o paneles huérfanos visibles. |
| **Salto de A a C (`CANCIONES -> AJUSTES` o `AJUSTES -> CANCIONES`)** | Calcula la dirección con `target > old` / `target < old`; únicamente el panel saliente (`A`) y el entrante (`C`) se animan mientras `B` permanece oculto (`visible = false`), y el indicador neón recorre limpiamente de `A` a `C`. |
| **Preservación de scroll de Fase 2** | `scroll_vertical` en `SongsTabScroll`, `ImportedListScroll` y `SettingsTabScroll` permanece inalterado tras viajar a otra pestaña y volver. |
| **Intento de swipe táctil horizontal** | Un arrastre horizontal (`InputEventScreenDrag` con `delta.x = -240 px`) NO cambia la pestaña activa; solo los botones de pestaña disparan `select_tab()`. |
| **Redimensionamiento de pantalla** | `_tab_content_viewport.resized` y `apply_hud_safe_rect()` reajustan tamaño de paneles y posición/ancho de `_tab_indicator_bar` sin desalineación. |
| **Intro inicial (Fase 5) o carga de canción (Fase 3) activa** | `select_tab()` ignora cambios mientras `_is_playing_startup_intro`, `_is_processing_song` o `_is_launching` estén activos. |

---

## 6. Impacto en Rendimiento
- Complejidad **O(1)** durante `220 ms` (1 `Tween` ligero sobre `position.x` y `size.x`, sin shaders ni reconstrucción de listas); costo **0** en reposo.

---

## 7. Criterios de Aceptación Verificables
- [ ] El cambio de pestaña animado dura `~220 ms` (`150–300 ms`), desliza en la dirección correcta con rebote sutil (`10 px`) y finaliza dejando el panel entrante estático en `position.x == 0.0` y el saliente con `visible == false`.
- [ ] `_tab_indicator_bar` se anima suavemente hasta alinearse con la `position.x` y `size.x` del botón de la pestaña activa.
- [ ] Mientras `is_tab_transitioning() == true`, las pulsaciones repetidas sobre otros botones de pestaña son ignoradas.
- [ ] Al desplazar `SongsTabScroll` (`scroll_vertical > 0`), cambiar de `CANCIONES` a `AJUSTES` (saltando `IMPORTAR`) y volver a `CANCIONES`, `scroll_vertical` conserva exactamente su valor original.
- [ ] Un arrastre táctil horizontal (`InputEventScreenDrag`) no cambia la pestaña activa (control exclusivo por botones).
- [ ] `_tab_content_viewport.clip_contents == true`.
- [ ] `--headless --quit --check-only` sobre `res://ui/main_menu.gd` retorna 0 errores y 0 advertencias.
- [ ] `git diff -- "*.tscn"` está completamente vacío.

---

## 8. Plan de Pruebas (Automatizadas y Manuales)

### 8.1. Automatizadas (Headless, eliminando `scratch/` siempre en `finally`)
1. Validación estática:
   ```powershell
   & "C:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://ui/main_menu.gd"
   ```
2. Prueba headless temporal `scratch/verify_phase6_tab_transitions.gd` (terminando con `quit(0)`):
   - **(a) Slider + indicador + rebote (`150–300 ms`) y posición final `x == 0.0`:** Monta `MainMenu` en `BrowserScreen` (`CANCIONES`), establece `SongsTabScroll.scroll_vertical = 180` sobre una lista larga de 12 pistas, pulsa `TabSettingsButton` (`CANCIONES -> AJUSTES` saltando `IMPORTAR`) -> verifica `is_tab_transitioning() == true`, `_tab_content_viewport.clip_contents == true`.
   - **(b) Bloqueo de clics repetidos en medio de transición:** Intenta pulsar `TabImportButton` mientras `is_tab_transitioning() == true` -> verifica que `_active_tab` sigue siendo `AJUSTES` y que no se inicia otra transición.
   - **(c) Finalización y preservación de scroll:** Espera a que termine el `Tween` (`150–300 ms`) -> verifica `is_tab_transitioning() == false`, `_settings_tab_container.visible == true`, `absf(_settings_tab_container.position.x) < 0.01`, `_songs_tab_container.visible == false` y `_tab_indicator_bar` alineado con `TabSettingsButton`. Luego cambia de vuelta a `CANCIONES` y comprueba al finalizar que `SongsTabScroll.scroll_vertical == 180` y `absf(_songs_tab_container.position.x) < 0.01`.
   - **(d) Ausencia de swipe horizontal:** Envía `InputEventScreenTouch` + `InputEventScreenDrag` horizontal de `-260 px` sobre `_tab_content_viewport` -> verifica que `get_active_tab()` sigue en `MenuTab.SONGS`.
   - **(e) Integridad `.tscn`:** Verifica `git diff -- "*.tscn"` vacío y elimina `scratch/` en `finally`.

### 8.2. Pruebas Manuales (Android y PC)
- Alternar entre `CANCIONES`, `IMPORTAR` y `AJUSTES` (incluyendo saltos `CANCIONES <-> AJUSTES`) en Android y PC (`F5`), confirmando deslizamiento suave con rebote sutil, desplazamiento del indicador neón inferior, preservación del scroll y ausencia de cambio por swipe lateral.

---

## 9. Diff Esperado (Resumen)
- **`ui/main_menu.gd`:**
  - Constantes `TAB_SLIDE_MAIN_DURATION_SEC = 0.17`, `TAB_SLIDE_SETTLE_DURATION_SEC = 0.05`, `TAB_SLIDE_OVERSHOOT_PX = 10.0`, `TAB_INDICATOR_HEIGHT_PX = 5.0`.
  - Nuevas referencias `_tabs_bar_wrapper`, `_tab_indicator_bar`, `_style_tab_indicator`, `_tab_content_viewport`, `_is_tab_transitioning`, `_tab_transition_tween`, `_tab_transition_outgoing`, `_tab_transition_incoming`.
  - Nuevos métodos `is_tab_transitioning()`, `get_tab_indicator_bar()`, `_get_tab_container(p_tab)`, `_get_tab_button(p_tab)`, `_restore_tab_panel_geometry()`, `_snap_tab_indicator_to_active()`, `_start_tab_transition()`, `_finish_tab_transition()`, `_on_tab_viewport_resized()`.
  - Actualización de `select_tab()`, `_refresh_tab_visuals()`, `_build_browser_screen_ui()`, `apply_hud_safe_rect()` y `_exit_tree()`.

---

## 10. Procedimiento de Reversión
```powershell
git revert <commit_hash_fase_6>
```
O restaurar al commit previo (`644e72c`):
```powershell
git checkout 644e72c -- ui/main_menu.gd
Remove-Item "specs/15_menu_tab_slider_transitions.md"
```
