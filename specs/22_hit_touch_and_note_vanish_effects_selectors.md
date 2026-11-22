# Spec 22 — Selectores Cosméticos Simétricos (`3 × 3 × 3`) en Ajustes

## 1. Nombre y Objetivo
- **Nombre:** Selectores cosméticos simétricos (`3 × 3 × 3`) de **Efecto de Acierto**, **Efecto Táctil** (con vista previa inmediata en menú) y **Efecto de Desvanecimiento** de notas con Object Pooling de tamaño fijo.
- **Objetivo:** Permitir al jugador personalizar en `AJUSTES` tres capas visuales independientes del feedback jugable (`3` opciones por categoría) con persistencia en `user://user_settings.cfg` (`[gameplay_effects]`), 100 % procedurales en GDScript 4 tipado estricto, sin assets externos, sin editar `.tscn` ni versiones en `project.godot`, y manteniendo 60+ FPS estables en lluvias densas de notas en Android mediante pools preasignados.

---

## 2. Alcance Exacto y Exclusiones

### Archivos Inspeccionados
- `AGENTS.md`
- `specs/22_hit_touch_and_note_vanish_effects_selectors.md`
- `vfx/reactive_backdrop.gdshader`
- `vfx/reactive_background.gd`
- `vfx/reactive_background_config.gd`
- `vfx/gameplay_effects_config.gd`
- `vfx/touch_effect_renderer.gd`
- `gameplay/lane_field.gd`
- `gameplay/note_view.gd`
- `gameplay/game_session.gd`
- `ui/main_menu.gd`

### Archivos Creados / Modificados
| Acción | Archivo | Propósito |
| :--- | :--- | :--- |
| **ACTUALIZAR** | `specs/22_hit_touch_and_note_vanish_effects_selectors.md` | Contrato completo `3 × 3 × 3` actualizado con `Estrella` en `X` (45°), `Corona`, `FireWork` en gotas alargadas y `Fractura` descendente. |
| **MODIFICAR** | `vfx/gameplay_effects_config.gd` | Modelo `GameplayEffectsConfig` con las `3 × 3 × 3` opciones (`classic`/`star`/`crown`, `wave`/`double_diamond`/`musical_note`, `firework`/`zoom_fade`/`fracture`) persistidas en `[gameplay_effects]` preservando `[menu_bgm]`, `[reactive_particles]` y `[reactive_background]`. |
| **CONSERVAR** | `vfx/touch_effect_renderer.gd` | Renderizador procedural compartido `TouchEffectRenderer` para `Onda`, `Doble Rombo` (delantero sólido horario + trasero contorno antihorario) y `Figura Musical` (4 figuras vectoriales aleatorias de pentagrama). |
| **MODIFICAR** | `vfx/reactive_background.gd` | Implementar `EFECTO DE ACIERTO` (`Clásico` bidireccional, `Estrella` en `X` rotada 45° y `Corona` confinada a un solo carril `<= lane_width` con blur neón cian/turquesa-violeta) sobre los 4 fondos (`Clásico`, `Nebulosa`, `Aurora`, `Eclipse`) mediante `GradientTexture2D` precreadas en `_init()` y 0 primitivas de línea, sin alterar `reactive_backdrop.gdshader`. |
| **MODIFICAR** | `gameplay/lane_field.gd` | Refinar `FireWork` (8–11 partículas en gota alargada gruesa con cabeza brillante redondeada + estela cónica corta en neón saturado, pool fijo `96`), mantener `Zoom + Fade` (`1.0 -> 1.35`, pool `24`) y refinar `Fractura` (5–7 polígonos irregulares pequeños cayendo hacia abajo `vy > 0` con gravedad suave y desvanecimiento `~0.26 s`, pool preasignado `84`). |
| **CONSERVAR** | `gameplay/game_session.gd` | Cargar `GameplayEffectsConfig` desde `user://user_settings.cfg`, aplicarlo a `ReactiveBackground` y `LaneField`, y sincronizar la posición normalizada dinámica de `hit_line_y`. |
| **MODIFICAR** | `ui/main_menu.gd` | Mostrar en `AJUSTES` las 3 secciones simétricas (`3 × 3 × 3`) con 3 botones por sección, `MOUSE_FILTER_PASS`, `_consume_suppressed_scroll_press()` y vista previa táctil inmediata al tocar en `MainMenu`. |

### Exclusiones Explícitas
- **NO** se edita ningún archivo `.tscn` (`git diff -- "*.tscn"` vacío).
- **NO** se modifica la versión en `project.godot` (conserva `"1.0.4"`).
- **NO** se modifica `vfx/reactive_backdrop.gdshader` ni el generador de charts (`core/chart/`).
- **NO** se añaden texturas, fuentes ni assets binarios externos.

---

## 3. Estructura de Configuración y Persistencia

### Sección `[gameplay_effects]` en `user://user_settings.cfg`
```ini
[gameplay_effects]
hit_effect="classic"
touch_effect="wave"
vanish_effect="firework"
```
- **Preservación de secciones existentes:** `save_to_file()` carga primero `user://user_settings.cfg` si existe y solo escribe `[gameplay_effects]`, dejando intactas `[menu_bgm]`, `[reactive_particles]` y `[reactive_background]`.
- **Valores válidos y sanitización (`3 × 3 × 3`):**
  - `hit_effect`: `"classic"` (`"Clásico"`, defecto) | `"star"` (`"Estrella"`) | `"crown"` (`"Corona"`).
  - `touch_effect`: `"wave"` (`"Onda"`, defecto) | `"double_diamond"` (`"Doble Rombo"`) | `"musical_note"` (`"Figura Musical"`).
  - `vanish_effect`: `"firework"` (`"FireWork"`, defecto) | `"zoom_fade"` (`"Zoom + Fade"`) | `"fracture"` (`"Fractura"`).
  - Valores desconocidos o corruptos caen al valor por defecto de cada campo sin errores.

---

## 4. Diseño Detallado de Efectos y Pools Acotados

### 4.1 `EFECTO DE ACIERTO` (`vfx/reactive_background.gd`)
- Precrea en `_init()` todas las `GradientTexture2D` necesarias (`_hit_beam_texture`, `_hit_beam_vertical_texture`, `_hit_radial_texture`, `_hit_crown_fan_texture`) y usa **0 llamadas** a `draw_line()`, `draw_polyline()` o `draw_arc()`.
- Usa el nodo hijo `_hit_effect_overlay: Control` (`PRESET_FULL_RECT`, `MOUSE_FILTER_IGNORE`, `material = null`) para que **`Estrella`** y **`Corona`** (y el refuerzo en Drop de **`Clásico`**) funcionen de forma uniforme en los **4 fondos** (`Clásico`, `Nebulosa`, `Aurora`, `Eclipse`) sin editar `reactive_backdrop.gdshader`. Cuando `hit_effect` es `"star"` o `"crown"` en fondo `Clásico`, pasa `lane_hit_energies = Vector4.ZERO` al shader.
- **`Clásico` (`"classic"`):** Destello difuminado bidireccional suave (arriba y abajo del carril acertado centrado en `hit_line_y`), intensificando alcance y brillo en Drops.
- **`Estrella` (`"star"`):** Destello difuminado en **4 direcciones diagonales formando una `X`** rotada **45°** (`45°, 135°, 225°, 315°`, vectores unitarios `(±0.7071, ±0.7071)`) centrado en `(lane_cx, hit_line_y)` para no solaparse con los separadores verticales de los carriles ni con la línea horizontal de juicio; varía intensidad y alcance (`1.0x -> 1.45x`) durante los Drops.
- **`Corona` (`"crown"`):** Resplandor neón (cian/turquesa-violeta) con **perfil horizontal en "U" pegado a las líneas del carril** precreado una sola vez en `_init()` (`alpha = 1.0` en `0.00` y `1.00`, decaimiento suave `0.55` en `0.18`/`0.82` y valle tenue `0.14` en `0.50`), alineado exactamente a `[lane_rect.position.x, lane_rect.end.x]` (`0 px` de separación interior y `0 px` de desborde), con máxima intensidad en la banda de `judgment_y`, proyección ascendente hacia arriba y **cobertura inferior completa hasta `lane_rect.end.y`** (`alpha -> 0.0` en `lane_rect.end.y`), escalando brillo y altura durante los Drops.

### 4.2 `EFECTO TÁCTIL` (`vfx/touch_effect_renderer.gd`, `gameplay/lane_field.gd`, `ui/main_menu.gd`)
- Pool fijo: `MAX_ACTIVE_RIPPLES = 16` en `LaneField`, `MAX_MENU_TOUCH_PREVIEWS = 12` en `MainMenu`.
- **`Onda` (`"wave"`):** Anillo circular expansivo brillante en **tono azul neón luminoso** (`14 -> 78 px`, `0.34 s`) con halo difuminado multicapa (`b > r`) para contrastar nítidamente sobre los 4 fondos y frente a `Clásico`, `Estrella` y `Corona`.
- **`Doble Rombo` (`"double_diamond"`):** Dos rombos concéntricos (cuadrados rotados 45°), `duration = 0.38 s`, buffers preasignados (`0` asignaciones/frame):
  - Delantero sólido en color claro cian-blanco con **giro en sentido horario** (`45° + t * 1.85 rad`).
  - Trasero solo contorno con **giro en sentido antihorario** (`45° - t * 1.45 rad`).
- **`Figura Musical` (`"musical_note"`):** Figura aleatoria de pentagrama por toque (`0`: corchea, `1`: doble corchea, `2`: negra, `3`: blanca) dibujada vectorialmente en neón claro con halo suave flotando hacia arriba (`-58 px`, `0.50 s`).
- **Vista previa inmediata en `MainMenu`:** `TouchPreviewLayer` (`MOUSE_FILTER_IGNORE`, `z_index = 85`) dispara el efecto táctil seleccionado al tocar en cualquier punto de `MainMenu` o al cambiar la opción en `AJUSTES`.

### 4.3 `EFECTO DE DESVANECIMIENTO` (`gameplay/lane_field.gd`)
Todos operan con **Object Pools preasignados de tamaño fijo (`0` asignaciones por frame)**:
- **`FireWork` (`"firework"`, defecto):**
  - Pool fijo `MAX_FIREWORK_RAYS = 96` + buffer poligonal `_fw_drop_poly_buf` preasignado.
  - **`8`–`11` partículas en forma de gota alargada gruesa** por nota (`GOOD = 8`, `GREAT = 9`, `PERFECT = 11`): cabeza brillante redondeada (`head_r` inicial `~6.8 px`) + estela cónica corta detrás, más halo exterior y núcleo especular.
  - Colores neón intensos y bien saturados: amarillo eléctrico, verde neón, magenta/fucsia, cian eléctrico y violeta claro.
- **`Zoom + Fade` (`"zoom_fade"`):**
  - Pool fijo `MAX_ZOOM_FADE_GHOSTS = 24`.
  - Escala la nota acertada en su punto de impacto de **`1.0 -> 1.35`** mientras desvanece **`alpha: 1.0 -> 0.0`** en `0.22 s`.
- **`Fractura` (`"fracture"`):**
  - Pool fijo `MAX_FRACTURE_SHARDS = 84` (`5`–`7` polígonos irregulares pequeños por nota: `GOOD = 5`, `GREAT = 6`, `PERFECT = 7`, buffers `PackedVector2Array` preasignados).
  - **Desplazamiento descendente (`vy > 0`):** todos los fragmentos caen hacia abajo por debajo de la línea de juicio (`vy` inicial `+150..+310 px/s` + gravedad suave `+560 px/s²`, ligera apertura lateral y rotación) para no quedar tapados por `Doble Rombo`, desvaneciéndose rápido (`~0.26 s`).

---

## 5. Casos Límite
- **`user://user_settings.cfg` inexistente o corrupto:** carga defaults (`classic`, `wave`, `firework`) sin error.
- **Lluvia intensa de notas (`> 20` aciertos en `< 0.2 s`):** pools circulares acotados (`<= 96`, `<= 24`, `<= 84`) sin fugas ni asignaciones de heap por frame.
- **Scroll táctil en `AJUSTES`:** los **9 botones (`3 × 3 × 3`)** usan `MOUSE_FILTER_PASS` dentro de `SettingsTabScroll` y llaman `_consume_suppressed_scroll_press()`.
- **Pantallas alargadas o curvas (`keep_width` + `safe_area`):** `Clásico`, `Estrella` en `X` y `Corona` se anclan al `hit_line_y` proporcional dinámico sincronizado desde `LaneField`.

---

## 6. Criterios de Aceptación Verificables
1. `GameplayEffectsConfig` persiste y recarga los 9 valores válidos (`3 × 3 × 3`) en `[gameplay_effects]` preservando `[menu_bgm]`, `[reactive_particles]` y `[reactive_background]`, y sanitiza entradas inválidas.
2. `ReactiveBackground` soporta `Clásico`, `Estrella` (4 direcciones diagonales en `X` a 45°) y `Corona` (`GradientTexture2D` precreada en `_init()`, ancho confinado `<= lane_width`, blur neón intenso cian/turquesa-violeta sin bordes duros ni primitivas de línea) sobre los 4 fondos variando alcance/altura e intensidad en Drops.
3. `TouchEffectRenderer`, `LaneField` y `MainMenu` renderizan `Onda` (brillante con tono azul neón `b > r` y halo suave), `Doble Rombo` (CW delantero sólido / CCW trasero contorno) y `Figura Musical` con vista previa inmediata en `MainMenu`.
4. `LaneField` renderiza `FireWork` (8–11 gotas alargadas gruesas neón, pool `96`), `Zoom + Fade` (`1.0 -> 1.35`, pool `24`) y `Fractura` (5–7 polígonos cayendo hacia abajo `vy > 0`, `~0.26 s`, pool `84`), pasando estrés de 40 impactos consecutivos.
5. `MainMenu` expone las 3 secciones (`3 × 3 × 3` = 9 botones) con `MOUSE_FILTER_PASS`.
6. `--headless --quit --check-only` pasa con `0` errores y `0` advertencias; `git diff -- "*.tscn"` vacío; `project.godot` permanece en `"1.0.4"`.

---

## 7. Plan de Pruebas Headless y Reversión
1. `--headless --quit --check-only` sobre todos los scripts creados/modificados (`0` errores, `0` advertencias).
2. Suite temporal en `scratch/` (`quit(0)`, eliminada en `finally`) cubriendo persistencia, los 9 estilos (`Estrella` en `X` 45°, `Corona` `alpha <= 0.30`, `FireWork` gotas gruesas, `Fractura` `vy > 0` y caída por debajo de `hit_line_y`), lluvia de notas, `MOUSE_FILTER_PASS` en los 9 botones de `AJUSTES`, `git diff -- "*.tscn"` vacío y versión `"1.0.4"`.
3. **Reversión:** `git revert <commit>` sobre `main` sin afectar récords ni ajustes previos.
