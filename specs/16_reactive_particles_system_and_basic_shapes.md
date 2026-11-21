# Spec 16 — Sistema Base de Partículas Reactivas, Ajustes y Variantes Básicas (Fase 7A)

## 1. Nombre y Objetivo
- **Nombre:** Sistema base de partículas reactivas + Controles en Ajustes + Variantes `Círculos` y `Cuadrados` (Fase 7A).
- **Objetivo:** Implementar por código GDScript (sin assets externos ni edición de `.tscn`) un sistema modular, configurable y retrocompatible de partículas reactivas al ritmo de la música, visible tanto en `MainMenu` como detrás de los carriles en `GameSession`, con persistencia en `user://user_settings.cfg`, vista previa inmediata desde la pestaña `AJUSTES`, y renderizado procedural completo para las dos variantes iniciales (`Círculos` y `Cuadrados`) dejando el contrato listo para `Neblina` y `Destellos` en Fase 7B.

---

## 2. Problema que Resuelve
Actualmente `FeelYourBeats (FyB)` cuenta con un fondo shader reactivo (`ReactiveBackground`), pero carece de una capa opcional de partículas atmosféricas configurables que:
1. Enriquecen la sensación audiovisual al compás del BGM del menú y del audio/reloj DSP en gameplay sin comprometer la legibilidad de las notas ni de los textos.
2. Permitan al jugador activar, desactivar o personalizar estilo, densidad y reacción musical desde `AJUSTES` con vista previa inmediata y persistencia entre sesiones.
3. Mantengan el comportamiento clásico por defecto (`"Ninguna"`) al actualizar desde `v1.0.3` o instalaciones sin claves previas, sin afectar rendimiento ni requerir archivos `.tscn` modificados ni texturas externas.

---

## 3. Alcance Exacto (Fase 7A)
Incluye exclusivamente:
1. **Contrato base y persistencia retrocompatible (`ReactiveParticlesConfig`):**
   - Sección `[reactive_particles]` en `user://user_settings.cfg` coexistiendo con `[menu_bgm]` sin alterar ni perder claves previas.
   - 4 preferencias con valores por defecto seguros:
     - `enabled: bool = true`
     - `type: String = "none"` (`"Ninguna"` como modo clásico predeterminado)
     - `density: String = "medium"` (`"Media"`)
     - `music_reactivity: String = "medium"` (`"Media"`)
   - Contrato tipado de los 5 tipos soportados: `"none"` (`Ninguna`), `"circles"` (`Círculos`), `"squares"` (`Cuadrados`), `"mist"` (`Neblina`), `"sparkles"` (`Destellos`), y los 3 niveles: `"low"` (`Baja`), `"medium"` (`Media`), `"high"` (`Alta`).
2. **Controles compactos en `AJUSTES` (`MainMenu`):**
   - Sección `"PARTÍCULAS REACTIVAS"` dentro de `SettingsContentVBox` (dentro de `SettingsTabScroll`, heredando el scroll táctil de Fase 2).
   - Toggle de activación (`ACTIVADAS` / `DESACTIVADAS`), selector de 5 Tipos, selector de 3 Densidades y selector de 3 Intensidades de reacción musical.
   - Vista previa inmediata en el fondo de `MainMenu` y guardado automático en `user://user_settings.cfg`.
   - Compatibilidad total con scroll táctil (`MOUSE_FILTER_PASS` + guarda `_consume_suppressed_scroll_press()`).
3. **Capa visual reactiva reutilizable (`ReactiveParticlesLayer`):**
   - `Control` full-bleed (`PRESET_FULL_RECT`) con `mouse_filter = Control.MOUSE_FILTER_IGNORE` y renderizado 100% procedural en `_draw()`.
   - Montada por código inmediatamente encima de `ReactiveBackground` y detrás de toda la UI en `MainMenu`, y detrás de `LaneField` y `SafeHud` en `GameSession`.
   - Consumo exclusivo por señales (`DSPClock.beat_pulsed`, `ReactiveBackground.bass_kick_pulsed`, `AudioAnalyzer.spectrum_updated`) respetando la separación estricta de capas (`AGENTS.md` §4).
   - Movimiento ambiental suave aun sin música ni beats detectados.
4. **Variantes implementadas en Fase 7A:**
   - **`Círculos` (`"circles"`):** círculos translúcidos de tamaño moderado con caída/deriva suave tipo nieve que aceleran brevemente en cada beat y regresan suavemente a su velocidad base.
   - **`Cuadrados` (`"squares"`):** cuadrados neón flotantes de distintos tamaños que derivan, rotan lentamente, aparecen y desaparecen mediante ciclos de fade aleatorios sin pop-in, y ejecutan un pulso sutil de escala (zoom) en cada beat regresando suavemente a su tamaño base.
   - **`Neblina` (`"mist"`) y `Destellos` (`"sparkles"`):** registrados y persistibles en el contrato base y UI; en Fase 7A actúan como reservado sin renderizado invasivo (0 partículas dibujadas) listos para conectarse en Fase 7B.

### Fuera de Alcance
- Renderizado visual de `Neblina` y `Destellos` (pertenece a Fase 7B).
- Edición de cualquier archivo `.tscn` o `project.godot`.
- Carga de texturas, shaders nuevos o assets externos.

---

## 4. Archivos a Inspeccionar
- `AGENTS.md` — reglas de tipado estático estricto, separación de capas, layout full-bleed y prohibición de editar `.tscn`.
- `project.godot` — resolución virtual `1080x1920`, `keep_width`, `mobile`, `edge_to_edge=true`.
- `ui/menu_bgm_player.gd` — convención existente de persistencia en `user://user_settings.cfg` (sección `[menu_bgm]`).
- `vfx/reactive_background.gd` — señales `bass_kick_pulsed`, consumo de `AudioAnalyzer` y `DSPClock`, orden de z-layer.
- `core/audio/audio_analyzer.gd` — señal `spectrum_updated(bass, mid, high, total)`.
- `ui/main_menu.gd` y `ui/main_menu.tscn` (solo lectura) — jerarquía de `ReactiveBackground`, `_safe_container`, `SettingsTabScroll`, `SettingsContentVBox` y `MOUSE_FILTER_PASS`.
- `gameplay/game_session.gd` y `ui/game_session.tscn` (solo lectura) — jerarquía de `ReactiveBackground`, `LaneField`, `SafeHud` y cableado de `DSPClock` / `AudioAnalyzer`.

---

## 5. Archivos a Crear y Modificar
| Acción | Archivo | Propósito |
| :--- | :--- | :--- |
| **CREAR** | `specs/16_reactive_particles_system_and_basic_shapes.md` | Spec independiente de la Fase 7A. |
| **CREAR** | `vfx/reactive_particles_config.gd` | Contrato tipado `ReactiveParticlesConfig`, constantes de tipos/niveles/presupuestos y carga/guardado retrocompatible en `user://user_settings.cfg`. |
| **CREAR** | `vfx/reactive_particles_layer.gd` | Capa reusable `ReactiveParticlesLayer extends Control` (`PRESET_FULL_RECT`, `MOUSE_FILTER_IGNORE`, `_draw()` procedural, pool sin asignaciones por frame, variantes `Círculos` y `Cuadrados`). |
| **MODIFICAR** | `ui/main_menu.gd` | Montar `ReactiveParticlesLayer` sobre `ReactiveBackground`, cablear señales de audio/beat, agregar controles de partículas en `SettingsContentVBox` con vista previa inmediata y persistencia. |
| **MODIFICAR** | `gameplay/game_session.gd` | Montar `ReactiveParticlesLayer` sobre `ReactiveBackground` (detrás de `LaneField` y `SafeHud`), cargar preferencias persistidas y cablear señales de `DSPClock`, `ReactiveBackground` y `AudioAnalyzer`. |

### Exclusiones Explícitas de `.tscn`
- **NO** se modificará `ui/main_menu.tscn`, `ui/game_session.tscn` ni ningún otro archivo `.tscn` del repositorio.
- Verificación obligatoria tras implementación: `git diff -- "*.tscn"` debe retornar vacío.

---

## 6. Dependencias con Fases Anteriores
- **Fase 1 (`specs/10_android_back_and_release_v1_0_4.md`):** mantiene intacto el manejo de botón Atrás y `user://user_settings.cfg`.
- **Fase 2 (`specs/11_menu_touch_scroll.md`):** los nuevos controles dentro de `SettingsTabScroll` deben usar `MOUSE_FILTER_PASS` y proteger sus callbacks `pressed` con `_consume_suppressed_scroll_press()` para que el arrastre vertical táctil siga funcionando sin pulsaciones fantasma.
- **Fase 3 (`specs/12_song_processing_loading_state.md`):** cuando se atenúa el BGM al lanzar una canción, `ReactiveParticlesLayer` continúa su deriva ambiental suave sin saltos ni bloqueos.
- **Fase 4 (`specs/13_gameplay_song_progress_bar.md`):** en `GameSession`, `ReactiveParticlesLayer` se inserta antes de `LaneField` y `SafeHud`, garantizando que la barra de progreso inferior, las notas y la línea de juicio siempre permanezcan encima.
- **Fase 5 (`specs/14_startup_intro_animation.md`):** el velo de intro (`z_index = 95`) cubre limpiamente el menú completo, incluida la capa de partículas.
- **Fase 6 (`specs/15_menu_tab_slider_transitions.md`):** el slider de pestañas opera dentro de `_safe_container`, por delante de `ReactiveParticlesLayer`, manteniendo transiciones fluidas.

---

## 7. Diseño Técnico: Presupuesto de Partículas y Respuesta a Beats

### 7.1 Presupuesto Moderado de Partículas (Mobile-Safe)
| Densidad (`density`) | Etiqueta UI | Máx. partículas activas |
| :--- | :--- | :---: |
| `"low"` | `Baja` | `28` |
| `"medium"` | `Media` | `48` |
| `"high"` | `Alta` | `72` |

- Las partículas residen en arreglos paralelos tipados (`PackedVector2Array`, `PackedFloat32Array`, `PackedInt32Array`) predimensionados únicamente al cambiar densidad/tipo (`_rebuild_pool()`), logrando **0 asignaciones de heap por frame** en `_process()` y `_draw()`.
- Cuando `enabled == false` o `particle_type == "none"` (o variante reservada no renderizada en 7A), la capa no simula partículas ni solicita `queue_redraw()` en bucle (**costo ~0 en modo clásico `"Ninguna"`**).

### 7.2 Envolvente de Reacción Musical (Sin DSP/FFT en VFX)
- Señales consumidas (solo eventos/métricas ya calculadas por capas externas):
  - `DSPClock.beat_pulsed` -> `trigger_beat_impulse(0.82)`
  - `ReactiveBackground.bass_kick_pulsed(strength)` -> `trigger_beat_impulse(strength)`
  - `AudioAnalyzer.spectrum_updated(bass, mid, high, total)` -> actualiza `_target_audio_energy = clampf(bass * 0.65 + total * 0.35, 0.0, 1.0)`
- Envolvente temporal por frame (`dt = maxf(0.0, p_delta)`):
  - En impulso: `_beat_impulse = maxf(_beat_impulse, clampf(strength, 0.0, 1.0))` (evita acumulación excesiva si `beat_pulsed` y `bass_kick_pulsed` coinciden en el mismo frame).
  - Decaimiento suave:
    - `_beat_impulse *= exp(-5.5 * dt)` (a `0.0` si `< 0.002`)
    - `_smoothed_audio_energy = lerpf(_smoothed_audio_energy, _target_audio_energy, clampf(8.0 * dt, 0.0, 1.0))`
    - `_target_audio_energy = maxf(0.0, _target_audio_energy - 4.0 * dt)`
  - Multiplicador por intensidad (`music_reactivity`):
    - `"low"` (`Baja`): `0.45`
    - `"medium"` (`Media`): `1.00`
    - `"high"` (`Alta`): `1.55`
  - Impulso efectivo:
    $$drive = \mathrm{clamp}\big((0.85 \cdot \text{beat\_impulse} + 0.25 \cdot \text{smoothed\_energy}) \cdot \text{reactivity\_mult},\ 0.0,\ 1.65\big)$$

### 7.3 Comportamiento de Variantes Fase 7A
1. **`Círculos` (`"circles"`):**
   - **Aspecto:** círculos translúcidos de radio `6.0 .. 18.0 px` en tonos cian, celeste hielo y violeta suave. Cada partícula dibuja un halo exterior muy sutil (`radius * 1.65`, `alpha * 0.24`) y un núcleo translúcido (`alpha = 0.22 .. 0.46`, más un realce máximo de `+0.10` en beat).
   - **Movimiento ambiental (sin música):** caída vertical constante `vy_base = 42.0 .. 108.0 px/s` + deriva horizontal sinusoidal suave `vx = sin(time * sway_freq + phase) * 26.0 px/s`.
   - **Reacción al beat:** la velocidad de caída multiplica suavemente por `speed_mult = 1.0 + (drive * 1.15)` y retorna exponencialmente a `1.0` al decaer `drive`.
   - **Reciclado:** envolvente toroidal limpia (`y > bounds.y + margin` -> reaparece en `y = -margin` con X aleatoria).
2. **`Cuadrados` (`"squares"`):**
   - **Aspecto:** cuadrados neón de semilado `7.0 .. 22.0 px` en paleta cian, azul eléctrico, violeta/magenta y menta neón. Relleno translúcido (`alpha * 0.26`) + borde nítido neón (`2.0 px`, `alpha * 0.62`), nunca saturando ni compitiendo con las notas.
   - **Movimiento ambiental (sin música):** flotación multidireccional suave (`vx = -22..22 px/s`, `vy = -34..18 px/s`) + rotación lenta (`ang_vel = -0.65..0.65 rad/s`).
   - **Ciclo de fade aleatorio:** cada cuadrado avanza `life_phase` a velocidad `0.14 .. 0.30 ciclos/s` (`~3.3–7.1 s`). Su opacidad sigue una campana suave `sin(life_phase * PI)^1.2` (`0` al nacer, pico en `0.5`, `0` al morir). Al llegar a `1.0`, se reubica con tamaño/rotación frescos en `life_phase = 0.0` (sin saltos visuales).
   - **Reacción al beat:** pulso de escala (zoom) `scale_mult = 1.0 + (drive * 0.28)` centrado en el cuadrado (`draw_set_transform(pos, angle, Vector2(scale_mult, scale_mult))`) que regresa suavemente a `1.0` tras el beat.

### 7.4 Jerarquía Visual (Z-Order)
- **`MainMenu`:**
  `ReactiveBackground (0)` -> `ReactiveParticlesLayer (1)` -> `_safe_container` (Título, Pestañas, Filas, Modales, Loading, Intro).
- **`GameSession`:**
  `... -> ReactiveBackground (idx)` -> `ReactiveParticlesLayer (idx + 1)` -> `LaneField` -> `SafeHud`.

---

## 8. Criterios de Aceptación Verificables
1. **Valores por defecto y retrocompatibilidad:** Sin archivo `user://user_settings.cfg` o con un archivo `v1.0.3` que solo contiene `[menu_bgm]`, las preferencias cargan con `enabled = true`, `type = "none"`, `density = "medium"`, `music_reactivity = "medium"`, y guardar partículas preserva intacta la sección `[menu_bgm]`.
2. **Persistencia completa:** Modificar cualquiera de las 4 opciones desde `MainMenu` guarda en `user://user_settings.cfg` y recarga exactamente los mismos valores en una nueva instancia de `ReactiveParticlesConfig`, `MainMenu` y `GameSession`.
3. **Controles en `AJUSTES`:** `SettingsContentVBox` contiene controles funcionales para Activado/Desactivado, 5 Tipos, 3 Densidades y 3 Niveles de reacción musical; todos tienen `mouse_filter == MOUSE_FILTER_PASS` dentro de `SettingsTabScroll` y actualizan la capa del menú de forma inmediata.
4. **Capa visual segura en Menú y Gameplay:** `ReactiveParticlesLayer` existe en `MainMenu` y `GameSession`, usa `PRESET_FULL_RECT`, `mouse_filter == Control.MOUSE_FILTER_IGNORE`, y su índice en el árbol está inmediatamente después de `ReactiveBackground` y estrictamente antes de `_safe_container` / `LaneField` / `SafeHud`.
5. **Presupuesto de partículas:** El conteo activo nunca supera `28` (Baja), `48` (Media) ni `72` (Alta), y es `0` cuando está desactivado o en `"none"`.
6. **Variantes `Círculos` y `Cuadrados`:**
   - En `"circles"`: con música silenciosa las posiciones avanzan suavemente hacia abajo; al recibir un beat, el factor de velocidad (`get_current_speed_multiplier()`) sube por encima de `1.0` y decae hacia `1.0` en frames posteriores.
   - En `"squares"`: las posiciones, rotaciones y fases de fade avanzan suavemente sin música; al recibir un beat, el factor de escala (`get_current_scale_multiplier()`) sube por encima de `1.0` y regresa hacia `1.0`.
7. **Cero cambios en `.tscn` y tipado estricto:** `git diff -- "*.tscn"` vacío y `--headless --quit --check-only` con 0 errores y 0 advertencias en todos los scripts tocados.

---

## 9. Pruebas Automatizadas y Manuales

### Pruebas Automatizadas (Headless)
1. **Verificación sintáctica y de tipado estricto (`--check-only`):**
   - `vfx/reactive_particles_config.gd`
   - `vfx/reactive_particles_layer.gd`
   - `ui/main_menu.gd`
   - `gameplay/game_session.gd`
2. **Suite temporal headless en `scratch/verify_phase7a_particles.gd` (finalizando con `get_tree().quit(0)` y eliminando `scratch/` al terminar):**
   - **(a) Persistencia y retrocompatibilidad `v1.0.3`:** crea un `.cfg` temporal solo con `[menu_bgm]`, verifica defaults (`enabled=true`, `type="none"`, `density="medium"`, `music_reactivity="medium"`), modifica las 4 claves, guarda, recarga y comprueba persistencia + preservación de `[menu_bgm]`.
   - **(b) Integración en `MainMenu` y `GameSession`:** instancia ambas escenas con `.cfg` aislado, verifica `ReactiveParticlesLayer` presente con `MOUSE_FILTER_IGNORE`, z-order detrás de UI / `LaneField` / `SafeHud`, controles de `AJUSTES` con `MOUSE_FILTER_PASS`, activación inmediata de `"circles"` y `"squares"`, y topes `28/48/72`.
   - **(c) Reacción a beat y movimiento ambiental sin música:** simula frames sin audio comprobando desplazamiento/rotación/fade activos; inyecta beat y verifica incremento y decaimiento suave de `speed_multiplier` (`circles`) y `scale_multiplier` (`squares`); comprueba modo `"none"` con `0` partículas activas.
   - **(d) Exclusión `.tscn`:** `git diff -- "*.tscn"` sin salida.

### Pruebas Manuales (PC `450x800` y Android)
1. Abrir `MainMenu` -> pestaña `AJUSTES`, hacer scroll táctil sobre la nueva sección sin activar botones por error.
2. Alternar entre `Ninguna`, `Círculos` y `Cuadrados`, observando vista previa inmediata detrás del panel translúcido.
3. Probar `Baja` / `Media` / `Alta` en Densidad y Reacción Musical con BGM activado y luego con BGM apagado (confirmando deriva ambiental suave).
4. Iniciar una canción (`JUGAR`) y comprobar que las partículas elegidas aparecen detrás de los carriles y notas en `GameSession`, reaccionan al beat, no obstruyen notas ni barra de progreso inferior, y no bloquean toques en carriles ni el botón de pausa.
5. Cerrar y reabrir la app verificando persistencia de las 4 opciones.

---

## 10. Casos Límite
- **Sin música / BGM apagado / sin pistas en `assets/bgm/`:** `_beat_impulse` y `_smoothed_audio_energy` permanecen en `0.0`; `Círculos` caen y derivan con suavidad constante, `Cuadrados` flotan, rotan y hacen fade suavemente.
- **Modo `"Ninguna"` (`"none"`) o `enabled == false`:** el pool queda inactivo (`active_count == 0`), `_draw()` retorna inmediatamente y `_process()` omite trabajo innecesario.
- **Actualización desde `v1.0.3`:** si `user://user_settings.cfg` solo posee `[menu_bgm]`, los getters con default devuelven el modo clásico `"none"` sin borrar ni corromper `bgm_enabled`, `auto_rotate` ni `selected_track_name`.
- **Valores corruptos o desconocidos en `.cfg`:** `sanitize_type()` / `sanitize_level()` normalizan cualquier valor inválido al valor por defecto seguro (`"none"` / `"medium"`).
- **Redimensionamiento de pantalla (`16:9`, `20:9`, `9:16`):** al cambiar `size` del viewport, el envolvente de coordenadas reposiciona partículas fuera de rango en el siguiente paso sin dejar bandas vacías.
- **Selección de `Neblina` o `Destellos` durante Fase 7A:** el ajuste se persiste y resalta correctamente en `AJUSTES`, sin errores ni bloqueos (renderizado diferido a Fase 7B).

---

## 11. Impacto en Rendimiento Móvil
- **Muy bajo / controlado:**
  - En modo por defecto (`"Ninguna"`): costo prácticamente nulo (`0` llamadas de dibujo).
  - En densidad máxima (`Alta = 72` partículas): máximo `72–144` primitivas 2D simples (`draw_circle` / `draw_rect`) en un único `CanvasItem` con arreglos `Packed*Array` sin asignaciones de memoria por frame.
  - Compatible con el renderizador `mobile` de Godot `4.7.2` manteniendo 60+ FPS estables en dispositivos Android de gama media.

---

## 12. Procedimiento de Reversión
Si se requiere revertir la Fase 7A:
1. Ejecutar `git revert <commit_fase_7a>` sobre `main` (o revertir manualmente `ui/main_menu.gd` y `gameplay/game_session.gd`, y eliminar `vfx/reactive_particles_config.gd`, `vfx/reactive_particles_layer.gd` y `specs/16_reactive_particles_system_and_basic_shapes.md`).
2. La sección opcional `[reactive_particles]` en `user://user_settings.cfg` es ignorada de forma inofensiva por versiones anteriores.

---

## 13. Diff Esperado
- **Nuevos archivos:**
  - `specs/16_reactive_particles_system_and_basic_shapes.md`
  - `vfx/reactive_particles_config.gd` (~165 líneas, tipado estático estricto)
  - `vfx/reactive_particles_layer.gd` (~360 líneas, tipado estático estricto)
- **Modificaciones acotadas:**
  - `ui/main_menu.gd`: exportación/montaje de `ReactiveParticlesLayer`, carga/guardado de `ReactiveParticlesConfig`, controles compactos en `SettingsContentVBox` (+~190 líneas).
  - `gameplay/game_session.gd`: exportación/montaje de `ReactiveParticlesLayer`, carga de `ReactiveParticlesConfig` y cableado de señales (+~50 líneas).
- **Archivos `.tscn` modificados:** `0`.
