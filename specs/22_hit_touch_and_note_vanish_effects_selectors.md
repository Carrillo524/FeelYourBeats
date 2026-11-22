# Spec 22 — Selectores Cosméticos en Ajustes: Efecto de Acierto, Efecto Táctil y Efecto de Desvanecimiento

## 1. Nombre y Objetivo
- **Nombre:** Selectores cosméticos persistentes de **Efecto de Acierto**, **Efecto Táctil** (con vista previa inmediata en menú) y **Efecto de Desvanecimiento** de notas con Object Pooling de tamaño fijo.
- **Objetivo:** Permitir al jugador personalizar en `AJUSTES` tres capas visuales independientes del feedback jugable con persistencia en `user://user_settings.cfg` (`[gameplay_effects]`), 100 % procedurales en GDScript 4 tipado estricto, sin assets externos, sin editar `.tscn` ni versiones en `project.godot`, y manteniendo 60+ FPS estables en lluvias densas de notas en Android mediante pools preasignados.

---

## 2. Alcance Exacto y Exclusiones

### Archivos Inspeccionados
- `AGENTS.md`
- `vfx/reactive_backdrop.gdshader`
- `vfx/reactive_background.gd`
- `vfx/reactive_background_config.gd`
- `vfx/reactive_particles_config.gd`
- `gameplay/lane_field.gd`
- `gameplay/note_view.gd`
- `gameplay/game_session.gd`
- `ui/main_menu.gd`

### Archivos a Crear / Modificar (Tras Aprobación del Plan)
| Acción | Archivo | Propósito |
| :--- | :--- | :--- |
| **CREAR** | `specs/22_hit_touch_and_note_vanish_effects_selectors.md` | Spec y contrato previo obligatorio. |
| **CREAR** | `vfx/gameplay_effects_config.gd` | Modelo `GameplayEffectsConfig` con persistencia en sección `[gameplay_effects]` de `user://user_settings.cfg` (preservando `[menu_bgm]`, `[reactive_particles]` y `[reactive_background]`). |
| **CREAR** | `vfx/touch_effect_renderer.gd` | Renderizador procedural compartido `TouchEffectRenderer` para las 3 variantes táctiles (`Onda`, `Doble Rombo`, `Figura Musical`) usado por `LaneField` y por la vista previa inmediata de `MainMenu`. |
| **MODIFICAR** | `vfx/reactive_background.gd` | Soportar `EFECTO DE ACIERTO` (`Clásico` bidireccional intensificado en Drops y `Estrella` difuminada en 4 direcciones intensificada en Drops) sobre los 4 estilos de fondo (`Clásico`, `Nebulosa`, `Aurora`, `Eclipse`) mediante overlay interno y `GradientTexture2D` precreadas en `_init()`, sin modificar `reactive_backdrop.gdshader`. |
| **MODIFICAR** | `gameplay/lane_field.gd` | Integrar `GameplayEffectsConfig`: usar `TouchEffectRenderer` para los 3 efectos táctiles y reemplazar el burst multicolor por el selector `EFECTO DE DESVANECIMIENTO` (`FireWork`, `Zoom + Fade`, `Fractura`) con Object Pools preasignados de tamaño fijo (`0` asignaciones por frame). |
| **MODIFICAR** | `gameplay/game_session.gd` | Cargar `GameplayEffectsConfig` desde `user://user_settings.cfg`, aplicarlo a `ReactiveBackground` y `LaneField`, y sincronizar la posición normalizada dinámica de `hit_line_y` para centrar el impacto en cualquier relación de aspecto. |
| **MODIFICAR** | `ui/main_menu.gd` | Añadir en `AJUSTES` las 3 secciones (`EFECTO DE ACIERTO`, `EFECTO TÁCTIL`, `EFECTO DE DESVANECIMIENTO`) con `MOUSE_FILTER_PASS` y `_consume_suppressed_scroll_press()`, y añadir capa ligera de vista previa táctil inmediata al tocar la pantalla. |

### Exclusiones Explícitas
- **NO** se edita ningún archivo `.tscn` (`git diff -- "*.tscn"` vacío).
- **NO** se modifica la versión en `project.godot` (conserva `"1.0.4"`).
- **NO** se modifica `vfx/reactive_backdrop.gdshader` ni la lógica del generador de charts (`core/chart/`).
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
- **Preservación de secciones existentes:** `save_to_file()` carga primero `user://user_settings.cfg` si existe y solo escribe la sección `[gameplay_effects]`, dejando intactas `[menu_bgm]`, `[reactive_particles]` y `[reactive_background]`.
- **Valores válidos y sanitización:**
  - `hit_effect`: `"classic"` (`"Clásico"`, defecto) | `"star"` (`"Estrella"`).
  - `touch_effect`: `"wave"` (`"Onda"`, defecto) | `"double_diamond"` (`"Doble Rombo"`) | `"musical_note"` (`"Figura Musical"`).
  - `vanish_effect`: `"firework"` (`"FireWork"`, defecto) | `"zoom_fade"` (`"Zoom + Fade"`) | `"fracture"` (`"Fractura"`).
  - Valores desconocidos o corruptos caen al valor por defecto de cada campo sin errores.

---

## 4. Diseño Detallado de Efectos y Pools Acotados

### 4.1 `EFECTO DE ACIERTO` (`vfx/reactive_background.gd`)
- Precrea en `_init()` las texturas `GradientTexture2D` necesarias (además de `_hit_beam_texture` horizontal y `_hit_radial_texture` radial, añade `_hit_beam_vertical_texture` con campana vertical `alpha: 0.0 -> 0.28 -> 1.0 -> 0.28 -> 0.0` para brazos horizontales sin bordes duros).
- Usa un nodo hijo ligero `_hit_effect_overlay: Control` (`PRESET_FULL_RECT`, `MOUSE_FILTER_IGNORE`, `material = null`) para que **`Estrella`** y el refuerzo bidireccional de **`Clásico`** funcionen de forma idéntica sobre los **4 fondos** (`Clásico`, `Nebulosa`, `Aurora`, `Eclipse`) sin alterar `reactive_backdrop.gdshader`.
- **`Clásico` (`"classic"`):**
  - Haz difuminado bidireccional suave (hacia arriba y hacia abajo del carril acertado centrado en `hit_line_y`) + halo radial en la línea de juicio.
  - Durante Drops (`_current_tier >= 2` o `_is_gameplay_drop_active()`), amplía alcance vertical y brillo (`drop_boost` controlado, sin saturar a blanco sólido).
- **`Estrella` (`"star"`):**
  - En fondo `Clásico`, pasa `lane_hit_energies = Vector4.ZERO` al shader para evitar choque con la columna vertical clásica.
  - Dibuja una **cruz difuminada de 4 puntas** centrada en `(lane_cx, hit_line_y)`:
    - Brazos verticales (arriba y abajo desde `hit_line_y`) con caída suave a `0.0` en ambos extremos.
    - Brazos horizontales (izquierda y derecha desde `lane_cx`) usando `_hit_beam_vertical_texture` con caída suave a `0.0` en ambos extremos.
    - Núcleo radial suave (`_hit_radial_texture`) en la intersección.
  - Durante Drops, escala el alcance de las 4 puntas (`1.0x -> 1.45x`) y su luminosidad suavemente.

### 4.2 `EFECTO TÁCTIL` (`vfx/touch_effect_renderer.gd`, `gameplay/lane_field.gd`, `ui/main_menu.gd`)
- Pool fijo de eventos táctiles: `MAX_ACTIVE_RIPPLES = 16` en `LaneField`, `MAX_MENU_TOUCH_PREVIEWS = 12` en `MainMenu`.
- **`Onda` (`"wave"`):** anillo circular expansivo neón (`14 -> 78 px`, `0.34 s`, halo exterior + trazo nítido).
- **`Doble Rombo` (`"double_diamond"`):** dos rombos concéntricos (cuadrados rotados 45°), `duration = 0.38 s`, usando buffers preasignados de vértices (`0` asignaciones por frame):
  - **Rombo trasero (solo contorno):** gira en sentido **antihorario** (`45° - t * 1.45 rad`), radio `16 -> 62 px`, trazo cian neón con halo difuso.
  - **Rombo delantero (sólido en color claro):** gira en sentido **horario** (`45° + t * 1.85 rad`), radio `10 -> 38 px`, relleno cian claro casi blanco (`Color(0.84, 0.99, 1.0)`) desvaneciéndose suavemente.
- **`Figura Musical` (`"musical_note"`):** elige aleatoriamente una de 4 figuras de pentagrama por toque (`0`: corchea, `1`: doble corchea, `2`: negra, `3`: blanca), dibujada vectorialmente (cabeza ovalada inclinada sólida/hueca, plica y corchete/barra) en color claro neón con halo suave, flotando hacia arriba (`-58 px`) mientras se desvanece (`0.50 s`).
- **Vista previa inmediata en `MainMenu`:** capa `TouchPreviewLayer` (`MOUSE_FILTER_IGNORE`, `z_index = 85`) dibuja el efecto táctil activo en cualquier toque en pantalla (`InputEventScreenTouch` o clic izquierdo en PC) y al pulsar una opción en `AJUSTES → EFECTO TÁCTIL`.

### 4.3 `EFECTO DE DESVANECIMIENTO` (`gameplay/lane_field.gd`)
Reemplaza el burst multicolor anterior por 3 modos seleccionables con **Object Pools preasignados de tamaño fijo (`0` asignaciones de heap por frame)**:
- **`FireWork` (`"firework"`, defecto):**
  - Pool fijo `MAX_FIREWORK_RAYS = 96` (arrays paralelos tipados: `PackedByteArray`/`PackedFloat32Array`/`PackedVector2Array`/`PackedColorArray`, escritura circular si se satura).
  - **Cantidad moderada por nota:** `PERFECT = 11`, `GREAT = 9`, `GOOD = 8` rayos radiales.
  - Paleta de 5 colores neón vibrantes: amarillo neón, verde neón, magenta/rosa neón, cian neón y violeta claro.
  - Trazos radiales brillantes con desaceleración suave y estela corta (`0.26–0.34 s`) para nitidez máxima incluso en lluvias de notas.
- **`Zoom + Fade` (`"zoom_fade"`):**
  - Pool fijo `MAX_ZOOM_FADE_GHOSTS = 24` (arrays paralelos tipados, `0` asignaciones por frame).
  - Dibuja el rectángulo de la nota acertada en su punto de impacto `(lane_cx, _hit_line_y)` haciendo zoom suave **`scale: 1.0 -> 1.35`** mientras se desvanece **`alpha: 1.0 -> 0.0`** en `0.22 s` con halo neón suave.
- **`Fractura` (`"fracture"`):**
  - Pool fijo `MAX_FRACTURE_SHARDS = 84` (`12` notas simultáneas × `7` fragmentos, sobrescritura circular si se excede, **buffers de vértices preasignados por slot -> `0` asignaciones por frame**).
  - Fragmenta la geometría de la nota (`visual_width × 36 px`) en **`5`–`7` polígonos irregulares pequeños** (`GOOD = 5`, `GREAT = 6`, `PERFECT = 7`) que se separan con leve rotación y se desvanecen rápido (`~0.22 s`).

---

## 5. Casos Límite
- **`user://user_settings.cfg` inexistente o sin `[gameplay_effects]`:** carga defaults (`classic`, `wave`, `firework`) sin error.
- **Lluvia intensa de notas (`> 20` aciertos en `< 0.2 s`) en `FireWork` o `Fractura`:** los pools circulares reciclan los slots más antiguos manteniendo memoria estrictamente acotada (`<= 96` rayos, `<= 24` fantasmas, `<= 84` fragmentos) sin fugas ni picos de GC.
- **Scroll táctil en `AJUSTES`:** los 8 nuevos botones (`2 + 3 + 3`) quedan dentro de `SettingsTabScroll` con `MOUSE_FILTER_PASS` y llaman `_consume_suppressed_scroll_press()` al inicio de sus handlers.
- **Pantallas alargadas o curvas (`keep_width` + `safe_area`):** `Estrella` y `Clásico` usan `hit_line_y` proporcional dinámico sincronizado desde `LaneField` y nunca coordenadas `Y` fijas en píxeles.

---

## 6. Criterios de Aceptación Verificables
1. `GameplayEffectsConfig` persiste y recarga `[gameplay_effects]` en `user://user_settings.cfg` sin alterar `[menu_bgm]`, `[reactive_particles]` ni `[reactive_background]`, y sanitiza valores inválidos.
2. `ReactiveBackground` soporta `hit_effect = "classic"` y `"star"` sobre los 4 fondos (`Clásico`, `Nebulosa`, `Aurora`, `Eclipse`) variando alcance y brillo en Drops, con `GradientTexture2D` precreadas en `_init()` y `reactive_backdrop.gdshader` intacto.
3. `TouchEffectRenderer`, `LaneField` y `MainMenu` renderizan sin errores `Onda`, `Doble Rombo` (delantero sólido horario + trasero contorno antihorario) y `Figura Musical` (4 figuras vectoriales aleatorias), con vista previa inmediata al tocar en `MainMenu`.
4. `LaneField` renderiza sin errores `FireWork` (`8–11` rayos/nota, pool fijo `96`), `Zoom + Fade` (`1.0 -> 1.35`, pool fijo `24`) y `Fractura` (`5–7` polígonos/nota, `~0.22 s`, pool fijo `84`), sobreviviendo estrés de `40` impactos consecutivos sin exceder el tamaño de pool.
5. `MainMenu` muestra las 3 secciones en `AJUSTES` con todos sus botones en `MOUSE_FILTER_PASS`.
6. `--headless --quit --check-only` pasa con `0` errores y `0` advertencias en todos los scripts nuevos/modificados; `git diff -- "*.tscn"` vacío; `project.godot` permanece en `"1.0.4"`.

---

## 7. Plan de Pruebas Headless y Reversión
1. `--headless --import --quit` (para registrar `GameplayEffectsConfig` y `TouchEffectRenderer` en `global_script_class_cache.cfg`).
2. `--headless --quit --check-only` sobre los 6 scripts (2 nuevos + 4 modificados).
3. Suite temporal `scratch/verify_phase22_cosmetic_effects.gd` (`quit(0)`, eliminando `scratch/` en `finally`):
   - Persistencia y aislamiento de secciones en `user://` temporal.
   - `ReactiveBackground`: `Clásico` y `Estrella` en los 4 fondos + incremento de alcance/brillo en Drop.
   - `TouchEffectRenderer` + `MainMenu` preview: `Onda`, `Doble Rombo` (sentidos de giro opuestos) y `Figura Musical` (4 variantes) + `MOUSE_FILTER_PASS` en los 8 botones nuevos de `AJUSTES`.
   - `LaneField`: `FireWork` (`8–11` rayos/nota), `Zoom + Fade` (`1.0 -> 1.35`), `Fractura` (`5–7` polígonos/nota, `~0.22 s`), y prueba de estrés de lluvia de 40 notas verificando límites estrictos de pool.
   - Verificación de `git diff -- "*.tscn"` vacío y versión `"1.0.4"` en `project.godot`.
4. **Reversión:** `git revert <commit>` sobre `main` sin afectar récords (`user://song_records.cfg`) ni ajustes previos en `user://user_settings.cfg`.
