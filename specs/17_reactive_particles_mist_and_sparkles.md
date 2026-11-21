# Spec 17 — Variantes Neblina y Destellos del Sistema de Partículas Reactivas (Fase 7B)

## 1. Nombre y Objetivo
- **Nombre:** Variantes `Neblina` (`TYPE_MIST`) y `Destellos` (`TYPE_SPARKLES`) del sistema de partículas reactivas (Fase 7B).
- **Objetivo:** Completar el catálogo de 5 estilos de partículas reactivas en **FeelYourBeats (FyB)** implementando el renderizado procedural (sin assets externos ni edición de `.tscn`) de `Neblina` y `Destellos` dentro de `ReactiveParticlesLayer`, habilitándolos como modos activos en `ReactiveParticlesConfig` y retirando el aviso provisional de "Fase 7B" en la pestaña `AJUSTES` de `MainMenu` para ofrecer vista previa inmediata en el menú y renderizado completo en `GameSession`.

---

## 2. Problema que Resuelve
En la Fase 7A (`specs/16_reactive_particles_system_and_basic_shapes.md`) se construyó la infraestructura de persistencia, controles en `AJUSTES` y renderizado para `Círculos` y `Cuadrados`, dejando `Neblina` y `Destellos` registrados en el contrato como opciones reservadas sin renderizado activo y mostrando un texto provisional de función pendiente. La Fase 7B cierra esta brecha entregando dos estilos atmosféricos de bajo impacto visual y móvil-seguros que complementan la identidad neón del juego sin comprometer la legibilidad de notas, línea de juicio ni botones.

---

## 3. Alcance Exacto (Fase 7B)
Incluye exclusivamente:
1. **Variante `Estelas Neón` (clave interna retrocompatible `TYPE_MIST = "mist"`, etiqueta UI `"Estelas"`):**
   - Filamentos verticales delgados (`1.4 .. 2.6 px` de ancho y `22.0 .. 48.0 px` de largo base) con paralaje (lejanas más tenues/lentas y cercanas más nítidas/rápidas) que **ascienden** (`vy < 0`) por toda la pantalla para contrastar claramente con las notas que caen.
   - Presupuesto estándar de partículas: **`28` en Baja, `48` en Media, `72` en Alta**.
   - Dibujo en `_draw()` por tramos de degradado suave desde cola inferior transparente (`alpha = 0.0`) hasta punta superior brillante en tonos cian, violeta y blanco hielo, coronada con un sutil destello circular usando la textura radial `_soft_radial_texture` precreada en `_init()`.
   - Ascenso ambiental continuo aun sin música; en cada beat acelera la velocidad vertical, estira la longitud (`length_mult = 1.0 + _current_drive * 0.75`) y potencia el brillo de la punta, retornando suavemente al estado base.
2. **Variante `Destellos` (`TYPE_SPARKLES = "sparkles"`):**
   - Puntos de luz / destellos suaves circulares (nunca estrellas con puntas literales ni polígonos estrellados) distribuidos por el fondo con distintos tamaños e intensidades.
   - Presupuesto moderado estándar (`28` en Baja, `48` en Media, `72` en Alta).
   - Aparición y desaparición continua mediante *fades* aleatorios escalonados (`sin(life_phase * PI)^1.45`) con reposicionamiento invisible al completar ciclo, manteniendo actividad agradable incluso sin música.
   - En cada beat incrementa momentáneamente el brillo y el radio del halo circular suave (reutilizando la misma `GradientTexture2D` precreada), retornando gradualmente a su intensidad normal.
3. **Activación completa en contrato y UI (`MainMenu` + `GameSession`):**
   - `ReactiveParticlesConfig` habilita `TYPE_MIST` y `TYPE_SPARKLES` como variantes renderizadas activas, conservando retrocompatibilidad de métodos existentes y añadiendo el cálculo de conteo efectivo (`8/14/20` para `TYPE_MIST`, `28/48/72` para las demás variantes activas).
   - `MainMenu` elimina el texto provisional de "reservado para Fase 7B" al seleccionar `Neblina` o `Destellos` en `AJUSTES`, activando su vista previa en vivo de forma inmediata.
   - `GameSession` renderiza automáticamente `Neblina` y `Destellos` detrás de `LaneField` y `SafeHud` reutilizando el cableado existente de Fase 7A.

### Fuera de Alcance
- Cambios en `TYPE_NONE`, `TYPE_CIRCLES` (refinado en `4c256ed`) o `TYPE_SQUARES`.
- Modificación de `gameplay/game_session.gd` (no requiere cambios estructurales; consume `ReactiveParticlesLayer` y `ReactiveParticlesConfig` directamente).
- Edición de cualquier archivo `.tscn` o `project.godot`, o incorporación de texturas/shaders externos.

---

## 4. Archivos a Inspeccionar
- `AGENTS.md` — tipado estático estricto, separación de capas, `edge_to_edge` y prohibición de editar `.tscn`.
- `specs/16_reactive_particles_system_and_basic_shapes.md` — contrato base de Fase 7A y criterios de no regresión.
- `vfx/reactive_particles_config.gd` — constantes, presupuestos, persistencia en `user://user_settings.cfg` y predicados de estado.
- `vfx/reactive_particles_layer.gd` — pool en arreglos `Packed*Array`, envolvente `_beat_impulse` / `_current_drive`, `_rebuild_pool()`, `step_simulation()` y `_draw()`.
- `ui/main_menu.gd` — `_refresh_particle_controls()` y `_particles_type_hint_label`.
- `gameplay/game_session.gd` — verificación de carga automática y cableado de señales hacia `ReactiveParticlesLayer`.

---

## 5. Archivos a Modificar
| Acción | Archivo | Propósito |
| :--- | :--- | :--- |
| **CREAR** | `specs/17_reactive_particles_mist_and_sparkles.md` | Spec independiente de la Fase 7B. |
| **MODIFICAR** | `vfx/reactive_particles_config.gd` | Añadir topes de neblina (`8 / 14 / 20`), `get_effective_particle_count()`, `is_rendered_type()` y activar `TYPE_MIST` / `TYPE_SPARKLES` manteniendo compatibilidad con métodos previos. |
| **MODIFICAR** | `vfx/reactive_particles_layer.gd` | Precrear `GradientTexture2D` radial en `_init()`, implementar spawn/step/draw de `TYPE_MIST` y `TYPE_SPARKLES`, y exponer getters de diagnóstico para pruebas headless. |
| **MODIFICAR** | `ui/main_menu.gd` | Retirar el aviso provisional de "Fase 7B" en `AJUSTES` para `Neblina` y `Destellos`, asegurando vista previa limpia e inmediata. |

### Exclusiones Explícitas de `.tscn`
- **NO** se modificará `ui/main_menu.tscn`, `ui/game_session.tscn` ni ningún otro archivo `.tscn`.
- Verificación obligatoria: `git diff -- "*.tscn"` vacío.

---

## 6. Dependencia con Fase 7A
- Construye directamente sobre el contrato `ReactiveParticlesConfig` (`[reactive_particles]` en `user://user_settings.cfg`) y el pool sin asignaciones por frame de `ReactiveParticlesLayer` introducidos en Fase 7A (`5bda94a`) y el refinamiento de `Círculos` (`4c256ed`).
- Reutiliza íntegramente el cableado de señales (`DSPClock.beat_pulsed`, `ReactiveBackground.bass_kick_pulsed`, `AudioAnalyzer.spectrum_updated`), el orden de capas (`ReactiveBackground` -> `ReactiveParticlesLayer` -> UI / `LaneField` / `SafeHud`) y el `MOUSE_FILTER_IGNORE` establecidos en Fase 7A.

---

## 7. Diseño Visual y Presupuesto de Rendimiento Móvil

### 7.1 Textura Radial Procedural Única (0 Assets Externos)
- En `_init()`, `ReactiveParticlesLayer` crea una única instancia de `GradientTexture2D` (`128x128`, `FILL_RADIAL`, centro `(0.5, 0.5)`, borde `(0.5, 0.0)`) con gradiente de alfa suave en 4 paradas (`1.0 -> 0.72 -> 0.24 -> 0.0`).
- Esta única textura en memoria GPU se reutiliza en todas las volutas de `Neblina` y halos de `Destellos`, evitando recreaciones de `Image`/`Texture` o asignaciones por frame.

### 7.2 Presupuestos y Límites por Densidad
| Variante | Baja (`low`) | Media (`medium`) | Alta (`high`) | Primitivas por partícula |
| :--- | :---: | :---: | :---: | :--- |
| `Estelas` (`"mist"`) | `28` | `48` | `72` | `5` segmentos `draw_line` en degradado + `1` destello circular en punta |
| `Destellos` (`"sparkles"`) | `28` | `48` | `72` | `1` `draw_texture_rect` halo circular + `1` `draw_circle` núcleo |
| `Círculos` (`"circles"`) | `28` | `48` | `72` | Sin cambios (Fase 7A + refinamiento) |
| `Cuadrados` (`"squares"`) | `28` | `48` | `72` | Sin cambios (Fase 7A) |

### 7.3 Detalle de `Estelas Neón` (`TYPE_MIST = "mist"`)
- **Geometría y paralaje:** filamentos verticales delgados (`1.4 .. 2.6 px` de ancho, `22.0 .. 48.0 px` de largo base) con profundidad de paralaje que modula velocidad ascendente (`vy = -72 .. -215 px/s`), grosor y nitidez.
- **Movimiento ascendente:** todas las estelas suben suavemente (`vy < 0`) por toda la pantalla para distinguirse inmediatamente de las notas que caen, reciclándose por el borde inferior al salir por el borde superior.
- **Degradado y punta brillante:** tramos conectados desde cola inferior transparente (`alpha = 0.0`) hasta la punta superior brillante en paleta cian, violeta y blanco hielo, rematada con un halo circular sutil (`_soft_radial_texture`) y núcleo luminoso.
- **Reacción al beat:**
  - `mist_speed_mult = 1.0 + (_current_drive * 0.95)`
  - `streak_length_mult = 1.0 + (_current_drive * 0.75)`
  - `mist_intensity_mult = 1.0 + (_current_drive * 0.65)` (potencia el brillo de la punta y retorna suavemente al estado base).

### 7.4 Detalle de `Destellos` (`TYPE_SPARKLES`)
- **Aspecto (cero estrellas con puntas):** cada partícula consta únicamente de un halo circular suave (`draw_texture_rect` cuadrado centrado usando `_soft_radial_texture`, radio `core_r * halo_scale`) y un núcleo circular limpio (`draw_circle`, radio `1.4 .. 4.2 px`). Paleta de blancos fríos, cian hielo, lavanda suave y destello champán cálido.
- **Ciclo de fade escalonado:** `life_phase` inicial aleatorio en `[0.0, 1.0)` avanzando a `0.22 .. 0.58 ciclos/s` (`~1.7–4.5 s`), con curva `fade = pow(sin(life_phase * PI), 1.45)`. Al completar (`>= 1.0`), reaparece de forma invisible (`life_phase = 0.0`) en nueva posición, tamaño e intensidad.
- **Deriva ambiental:** deriva casi imperceptible (`-8 .. +8 px/s`) para aportar vida sin distraer la lectura de carriles.
- **Reacción al beat:**
  - `sparkle_brightness_mult = 1.0 + (_current_drive * 0.65)` (con alfa acotado en `<= 0.92` en núcleo y `<= 0.52` en halo).
  - `sparkle_halo_scale = 4.2 + (_current_drive * 2.6)` (expansión suave del halo circular al beat, regresando gradualmente a `4.2x`).

### 7.5 Impacto en Rendimiento Móvil
- **Muy bajo:** en `Neblina` son como máximo `20` quads translúcidos con una sola textura `128x128` compartida (sobrecarga de *overdraw* limitada a la franja inferior); en `Destellos` son como máximo `72` halos pequeños + `72` círculos mínimos, manteniendo 60+ FPS en renderizador `mobile` de Godot `4.7.2` con 0 asignaciones por frame.

---

## 8. Criterios de Aceptación Verificables
1. **Activación en contrato y UI:** `ReactiveParticlesConfig.is_rendered_type()` retorna `true` para `TYPE_MIST` y `TYPE_SPARKLES` (cuando `enabled == true`); al seleccionarlos en `AJUSTES`, no aparece ningún texto de función pendiente y el menú muestra vista previa inmediata.
2. **Presupuestos exactos:** `TYPE_MIST` asigna exactamente `8` (Baja), `14` (Media) y `20` (Alta) volutas; `TYPE_SPARKLES` asigna exactamente `28` (Baja), `48` (Media) y `72` (Alta) destellos.
3. **Confinamiento y reacción de `Neblina`:** Todas las volutas de `TYPE_MIST` permanecen en la zona inferior / media-baja (`pos.y >= bounds.y * 0.56`), se desplazan/ondulan aun sin música, usan la `GradientTexture2D` precreada una sola vez en `_init()`, y al disparar `trigger_beat_impulse()` aumentan `get_mist_speed_multiplier()` y `get_mist_intensity_multiplier()` decayendo suavemente después.
4. **Ciclos y reacción de `Destellos`:** Las partículas de `TYPE_SPARKLES` avanzan su `life_phase` y completan *fades* continuos sin música, aumentan `get_sparkle_brightness_multiplier()` y `get_sparkle_halo_scale()` tras `trigger_beat_impulse()` regresando a su base, y se renderizan exclusivamente como puntos/halos circulares suaves (sin estrellas con puntas).
5. **Renderizado en Menú y Gameplay:** `MainMenu` y `GameSession` activan y renderizan `TYPE_MIST` y `TYPE_SPARKLES` con `MOUSE_FILTER_IGNORE` detrás de la UI, `LaneField` y `SafeHud`.
6. **No regresión y cero `.tscn`:** `TYPE_NONE`, `TYPE_CIRCLES` y `TYPE_SQUARES` mantienen exactamente su comportamiento previo; `--check-only` retorna 0 errores y 0 advertencias; `git diff -- "*.tscn"` vacío.

---

## 9. Pruebas Automatizadas y Manuales

### Pruebas Automatizadas (Headless)
1. `--headless --quit --check-only` sobre:
   - `res://vfx/reactive_particles_config.gd`
   - `res://vfx/reactive_particles_layer.gd`
   - `res://ui/main_menu.gd`
2. Script temporal `scratch/verify_phase7b_mist_sparkles.gd` (terminando con `get_tree().quit(0)` y eliminando `scratch/` en `finally`):
   - **(a) `TYPE_MIST`:** verifica textura radial única (`get_soft_radial_texture() != null`, misma instancia tras múltiples steps), conteos exactos `8/14/20`, confinamiento vertical (`pos.y >= bounds.y * 0.56` en todas las volutas antes y después de simular sin música), desplazamiento continuo sin música, aumento de `mist_speed_multiplier` e `mist_intensity_multiplier` tras `trigger_beat_impulse()` y decaimiento suave.
   - **(b) `TYPE_SPARKLES`:** verifica conteos `28/48/72`, avance continuo de `life_phase` y reciclado de fade sin música, aumento y decaimiento de `sparkle_brightness_multiplier` y `sparkle_halo_scale` tras `trigger_beat_impulse()`.
   - **(c) `MainMenu` (`AJUSTES`) y `GameSession`:** selecciona `Neblina` y `Destellos` vía botones de `AJUSTES`, verifica que no haya texto de aviso pendiente visible, que se activen inmediatamente en `MainMenu`, persistan en `.cfg` aislado y se carguen activos en `GameSession` con `MOUSE_FILTER_IGNORE`.
   - **(d) No regresión:** verifica `TYPE_CIRCLES` (radial saliente, `max_r <= 4.5 px`), `TYPE_SQUARES` (rotación, fade, pulso de escala) y `TYPE_NONE` (`0` activas).
   - **(e) Exclusión `.tscn`:** `git diff -- "*.tscn"` vacío.

### Pruebas Manuales (PC `450x800` y Android)
1. Ir a `AJUSTES`, seleccionar `Neblina` y comprobar la capa etérea en la zona inferior/media-baja reaccionando al BGM del menú y manteniéndose suave al apagar el BGM.
2. Seleccionar `Destellos` y comprobar puntos de luz suaves con parpadeo aleatorio escalonado (sin puntas de estrella) y pulso luminoso al beat.
3. Probar `Baja` / `Media` / `Alta` en Densidad y Reacción Musical y jugar una canción con cada estilo verificando nitidez total de notas, línea de juicio y barra de progreso inferior.

---

## 10. Casos Límite
- **Sin música / BGM apagado:** `Neblina` mantiene deriva y ondulación suave; `Destellos` continúa sus ciclos de fade aleatorios sin quedarse congelado.
- **Cambio rápido entre los 5 tipos y 3 densidades:** `_rebuild_pool()` redimensiona los arreglos paralelos limpiamente sin recrear `GradientTexture2D` ni filtrar partículas de una variante anterior.
- **Pantallas alargadas (`20:9`) o más anchas (`16:9`):** la banda inferior de `Neblina` y los radios relativos escalan proporcionalmente a `bounds`, evitando huecos o invasión de la mitad superior.
- **Regreso desde `GameSession` / reinicio de app:** las selecciones `mist` y `sparkles` persisten y restauran su estado exacto en `user://user_settings.cfg`.

---

## 11. Procedimiento de Reversión
1. Ejecutar `git revert <commit_fase_7b>` sobre `main`.
2. Las claves `"mist"` y `"sparkles"` ya eran válidas en `ReactiveParticlesConfig` desde Fase 7A, por lo que una reversión volvería de forma limpia al estado reservado sin corrupción de `user://user_settings.cfg`.

---

## 12. Diff Esperado
- **Nuevo archivo:** `specs/17_reactive_particles_mist_and_sparkles.md`
- **Modificaciones acotadas:**
  - `vfx/reactive_particles_config.gd` (+~30 líneas)
  - `vfx/reactive_particles_layer.gd` (+~210 líneas)
  - `ui/main_menu.gd` (-~15 líneas al retirar el aviso provisional de Fase 7B)
- **Archivos `.tscn` modificados:** `0`.
