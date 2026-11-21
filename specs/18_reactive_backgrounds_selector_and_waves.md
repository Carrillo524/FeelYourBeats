# Spec 18 — Selector de Fondos Reactivos, Persistencia y Estilos Clásico y Ondas (Fase 8A)

## 1. Nombre y Objetivo
- **Nombre:** Selector de fondos reactivos + Persistencia retrocompatible + Estilos `Clásico` y `Ondas` (Fase 8A).
- **Objetivo:** Incorporar en **FeelYourBeats (FyB)** un sistema configurable y persistente de fondos reactivos al audio —100 % en GDScript con tipado estático estricto, 0 assets externos y 0 ediciones en archivos `.tscn`— que permita elegir el estilo de fondo e intensidad musical desde la pestaña `AJUSTES` con vista previa inmediata en `MainMenu` y aplicación automática en `GameSession`, manteniendo el modo `Clásico` intacto por defecto, implementando el nuevo estilo procedural `Ondas` (anillos concéntricos sin relleno con halo suave), y registrando en el contrato los estilos `Aurora` y `Estrellas Fugaces` para la Fase 8B.

---

## 2. Problema que Resuelve
Actualmente `ReactiveBackground` ofrece un único estilo visual fijo (el shader clásico `reactive_backdrop.gdshader`). Aunque la Fase 7 incorporó partículas reactivas configurables encima del fondo, el jugador aún no puede elegir la estética base del fondo ni ajustar su intensidad musical de forma persistente. La Fase 8A introduce la arquitectura de selección y persistencia de fondos junto con el primer preset alternativo de alto contraste (`Ondas`), garantizando retrocompatibilidad total con instalaciones previas y preservando la nitidez de las notas, línea de juicio y botones.

---

## 3. Alcance Exacto (Fase 8A)
Incluye exclusivamente:
1. **Contrato de fondos y persistencia retrocompatible (`ReactiveBackgroundConfig`):**
   - Sección `[reactive_background]` dentro de `user://user_settings.cfg`, cargando primero el archivo existente para preservar intactas las secciones `[menu_bgm]` y `[reactive_particles]`.
   - 2 preferencias persistidas con valores por defecto seguros:
     - `style: String = "classic"` (`"Clásico"` como modo predeterminado retrocompatible), soportando `"classic"` (`Clásico`), `"waves"` (`Ondas`), `"aurora"` (`Aurora`) y `"shooting_stars"` (`Estrellas Fugaces`).
     - `reactivity: String = "medium"` (`"Media"`), soportando `"low"` (`Baja`), `"medium"` (`Media`) y `"high"` (`Alta`).
2. **Controles en la pestaña `AJUSTES` (`MainMenu`):**
   - Nueva sección `"FONDO REACTIVO"` dentro de `SettingsContentVBox` (dentro de `SettingsTabScroll`, heredando el scroll táctil de Fase 2 con `MOUSE_FILTER_PASS` y guarda `_consume_suppressed_scroll_press()`).
   - Selector de 4 estilos (`Clásico`, `Ondas`, `Aurora`, `Estrellas Fugaces`) + selector de 3 niveles de intensidad musical (`Baja`, `Media`, `Alta`).
   - Vista previa inmediata en el fondo de `MainMenu` y guardado automático en `user://user_settings.cfg`.
   - Aviso sutil provisional únicamente al seleccionar `Aurora` o `Estrellas Fugaces` indicando que quedan reservados para Fase 8B (manteniendo el fondo `Clásico` mientras tanto).
3. **Estilos operativos en Fase 8A (`ReactiveBackground`, Menú y Gameplay):**
   - **`Clásico` (`"classic"`):** conserva exactamente el shader (`vfx/reactive_backdrop.gdshader`), paleta, parámetros y rendimiento actual sin ninguna alteración visual.
   - **`Ondas` (`"waves"`):** sobre la base oscura del juego (`material = null`, omitiendo el shader clásico), dibuja ondas circulares **sin relleno** (`draw_arc`, `48` segmentos) tipo gotas de lluvia distribuidas en posiciones `(x, y)` independientes por toda la pantalla (`[36, w - 36]` × `[36, h - 36]`), con radio máximo compacto (`65.0`–`135.0 px`) y halo difuminado suave en 4 capas translúcidas en cian y violeta (sin `WorldEnvironment`). Mantiene llovizna ambiental continua (`~2.5` ondas/s) aun sin música, dispara ráfagas de ondas con aceleración y mayor luminosidad en cada beat/drop y se desvanece suavemente al acercarse a su radio máximo sin reducir la legibilidad de notas, línea de juicio ni botones.
4. **Carga automática en `GameSession`:**
   - Al inicializar `GameSession`, se recarga `[reactive_background]` desde `user://user_settings.cfg` y se aplica a `ReactiveBackground` (detrás de `ReactiveParticlesLayer`, `LaneField` y `SafeHud`).

### Fuera de Alcance
- Renderizado visual definitivo de `Aurora` y `Estrellas Fugaces` (pertenece a Fase 8B).
- Modificación de `vfx/reactive_backdrop.gdshader`, `vfx/reactive_particles_layer.gd`, `vfx/reactive_particles_config.gd` o cualquier archivo `.tscn`.
- Uso de `WorldEnvironment`, glow global, texturas o assets externos.

---

## 4. Archivos a Inspeccionar
- `AGENTS.md` — reglas de tipado estático estricto, separación de capas, `edge_to_edge` y prohibición de editar `.tscn`.
- `project.godot` — resolución base `1080x1920`, `keep_width`, renderizador `mobile`.
- `vfx/reactive_background.gd` y `vfx/reactive_backdrop.gdshader` — funcionamiento actual del fondo `Clásico`, señales (`bass_kick_pulsed`, `screen_shake_updated`) y consumo de `DSPClock`, `HitJudge` y `AudioAnalyzer`.
- `vfx/reactive_particles_config.gd` — patrón establecido de persistencia compartida en `user://user_settings.cfg`.
- `ui/main_menu.gd` — sección `SettingsContentVBox`, scroll táctil (`SettingsTabScroll`) y aplicación de estilos a botones de opciones.
- `gameplay/game_session.gd` — cableado de `ReactiveBackground`, `DSPClock`, `AudioAnalyzer` y `ReactiveParticlesLayer`.

---

## 5. Archivos a Crear y Modificar
| Acción | Archivo | Propósito |
| :--- | :--- | :--- |
| **CREAR** | `specs/18_reactive_backgrounds_selector_and_waves.md` | Spec independiente de la Fase 8A. |
| **CREAR** | `vfx/reactive_background_config.gd` | Clase `ReactiveBackgroundConfig` con constantes de estilos/niveles, sanitización y carga/guardado retrocompatible en `[reactive_background]` de `user://user_settings.cfg`. |
| **MODIFICAR** | `vfx/reactive_background.gd` | Añadir soporte de configuración de estilo/intensidad, conservar `Clásico` bit-a-bit intacto e implementar el modo procedural `Ondas` (`draw_arc` multicapa sin relleno, pool acotado, expansión ambiental y pulsos al beat/drop). |
| **MODIFICAR** | `ui/main_menu.gd` | Añadir sección `"FONDO REACTIVO"` en `AJUSTES` dentro de `SettingsTabScroll` con vista previa en vivo, persistencia y compatibilidad táctil (`MOUSE_FILTER_PASS` + `_consume_suppressed_scroll_press()`). |
| **MODIFICAR** | `gameplay/game_session.gd` | Cargar y aplicar `[reactive_background]` desde `user://user_settings.cfg` sobre `ReactiveBackground` al iniciar la sesión de juego. |

### Exclusiones Explícitas de `.tscn`
- **NO** se modificará `ui/main_menu.tscn`, `ui/game_session.tscn` ni ningún otro archivo `.tscn`.
- Verificación obligatoria: `git diff -- "*.tscn"` vacío.

---

## 6. Dependencias con Fases Anteriores
- **Fase 2 (`specs/11_menu_touch_scroll.md`):** los botones del selector de fondo en `SettingsTabScroll` deben construirse antes de `_configure_touch_scroll_container(_settings_scroll)` para heredar `MOUSE_FILTER_PASS` y proteger sus handlers con `_consume_suppressed_scroll_press()`.
- **Fases 7A y 7B (`specs/16` y `specs/17`):** `ReactiveParticlesLayer` permanece inmediatamente encima de `ReactiveBackground` y consume `reactive_background.bass_kick_pulsed`; `ReactiveBackground` seguirá emitiendo `bass_kick_pulsed` y `screen_shake_updated` en todos los estilos de fondo, permitiendo combinar libremente cualquier fondo con cualquier preset de partículas.
- **Fase 1 (`user://user_settings.cfg`):** `[reactive_background]` coexiste pacíficamente con `[menu_bgm]` y `[reactive_particles]`.

---

## 7. Diseño Técnico: Rendimiento y Contraste Móvil

### 7.1 Persistencia Compartida (`user://user_settings.cfg`)
```ini
[reactive_background]
style="classic"
reactivity="medium"
```
- `reactivity` mapea a multiplicadores: `"low"` → `0.55`, `"medium"` → `1.00`, `"high"` → `1.45`.
- Valores desconocidos o corruptos se normalizan con `sanitize_style()` → `"classic"` y `sanitize_level()` → `"medium"`.

### 7.2 Estilo `Clásico` (`"classic"`)
- `ReactiveBackground.material` apunta a `_shader_material` (`vfx/reactive_backdrop.gdshader`).
- `_draw()` retorna en la primera línea (`0` llamadas 2D adicionales).
- Todos los uniforms, colores, pulso de horizonte y ondas perimetrales del gameplay permanecen 100 % idénticos a la versión anterior.

### 7.3 Estilo `Ondas` (`"waves"`) — Ondas de Lluvia Compactas sin Relleno
- **Base oscura limpia:** `material = null` (ahorra evaluación del shader clásico en GPU móvil) y fondo degradado oscuro sutil (`Color(0.035, 0.045, 0.11, 1.0)` arriba → `Color(0.075, 0.03, 0.145, 1.0)` abajo) coherente con la paleta del juego.
- **Pool acotado sin asignaciones por frame:** máximo `MAX_WAVE_RINGS = 22` ondas activas simultáneas en arreglos paralelos tipados (`PackedVector2Array`, `PackedFloat32Array`, `PackedInt32Array`).
- **Posiciones independientes y tamaño compacto:** cada onda nace en una coordenada aleatoria `(x, y)` dentro de `[36.0, width - 36.0]` × `[36.0, height - 36.0]` con un radio inicial `2.0 px` y un `max_radius` compacto entre `65.0` y `135.0 px` (`14 %–28 %` del ancho), disolviéndose localmente sin saturar toda la pantalla.
- **Llovizna ambiental y ráfagas musicales:**
  - **Sin música / ambiente:** llovizna suave y continua de `~2.5` ondas/segundo (`WAVE_AMBIENT_INTERVAL_SEC = 0.40 s`), presembrando 6 ondas escalonadas al activar `"waves"`.
  - **Con beat o drop:** `_on_beat_pulsed`, `_on_intensity_changed` (drop) y `_on_spectrum_updated` (transiente de bajos / drop) invocan `trigger_wave_pulse()` (enfriamiento `0.14 s`) emitiendo ráfagas de `1` a `4` ondas simultáneas en distintos puntos según `reactivity` (`Baja` / `Media` / `Alta`), acelerando su expansión radial y aumentando la luminosidad del halo.
- **Halo difuminado simulado (sin `WorldEnvironment`):** cada onda activa dibuja **4 arcos circulares sin relleno** (`draw_arc(..., 0.0, TAU, 48, col, width, true)`):
  1. Halo exterior: `width * 6.5`, `alpha * 0.12`
  2. Halo medio: `width * 3.8`, `alpha * 0.24`
  3. Halo interior: `width * 2.0`, `alpha * 0.44`
  4. Núcleo nítido: `width * 1.0`, `alpha * 0.92`
- **Desvanecimiento local:** *fade-in* breve (`0.0 -> 0.12` de su `max_radius`) y *fade-out* suave (`0.52 -> 1.0` de su `max_radius`), manteniendo opacidad contenida para preservar nitidez de notas, carriles y botones.
- **Costo móvil:** máximo `22 × 4 = 88` arcos compactos 2D con `material = null`, 0 texturas nuevas y 0 `WorldEnvironment`, manteniendo 60+ FPS estables en renderizador `mobile`.

---

## 8. Criterios de Aceptación Verificables
1. **Persistencia retrocompatible:** Sin claves previas (o con `user://user_settings.cfg` que solo tiene `[menu_bgm]` y `[reactive_particles]`), carga por defecto `style = "classic"` y `reactivity = "medium"`; al guardar `[reactive_background]`, preserva intactas `[menu_bgm]` y `[reactive_particles]`.
2. **Clásico intacto:** Con `style == "classic"`, `ReactiveBackground.material` mantiene el `ShaderMaterial` clásico activo y `get_active_wave_ring_count() == 0`.
3. **Ondas activas en Menú y Gameplay:** Con `style == "waves"`, `ReactiveBackground` desactiva el shader clásico (`material == null`), presembra anillos que se expanden radialmente sin música (`radius` estrictamente creciente), emite anillos más marcados al recibir beats/drops, reduce `alpha` progresivamente hacia el borde y sigue emitiendo `bass_kick_pulsed` y `screen_shake_updated`.
4. **Selector en `AJUSTES`:** Existen los botones de los 4 estilos (`Clásico`, `Ondas`, `Aurora`, `Estrellas Fugaces`) y 3 intensidades (`Baja`, `Media`, `Alta`) dentro de `SettingsTabScroll`, todos con `MOUSE_FILTER_PASS`, vista previa inmediata en `MainMenu` y persistencia recargada en `GameSession`.
5. **Tipado estricto y cero `.tscn`:** `--check-only` con 0 errores y 0 advertencias en todos los scripts creados/modificados y `git diff -- "*.tscn"` vacío.

---

## 9. Pruebas Automatizadas y Manuales

### Pruebas Automatizadas (Headless)
1. `--headless --quit --check-only` sobre:
   - `res://vfx/reactive_background_config.gd`
   - `res://vfx/reactive_background.gd`
   - `res://ui/main_menu.gd`
   - `res://gameplay/game_session.gd`
2. Prueba temporal en `scratch/verify_phase8a_backgrounds.gd` (`get_tree().quit(0)`), eliminando `scratch/` en `finally`:
   - **(a) Persistencia y coexistencia:** crea `.cfg` temporal con `[menu_bgm]` y `[reactive_particles]`, verifica defaults (`style="classic"`, `reactivity="medium"`), guarda `"waves"` + `"high"`, recarga y confirma preservación íntegra de las 3 secciones.
   - **(b) Clásico intacto:** verifica `material != null` y `0` anillos de ondas en `"classic"`.
   - **(c) `Ondas` en `MainMenu` y `GameSession`:** selecciona `"waves"` desde los botones de `AJUSTES` (verificando `MOUSE_FILTER_PASS`), confirma activación inmediata en `MainMenu`, expansión radial sin música, emisión adicional al beat (`trigger_wave_pulse` / `DSPClock.beat_pulsed`), *fade-out* hacia el borde y carga automática al instanciar `GameSession`.
   - **(d) Reservados Fase 8B:** al seleccionar `Aurora` o `Estrellas Fugaces`, persiste la elección, muestra aviso discreto y mantiene el shader clásico sin errores.
   - **(e) Exclusión `.tscn`:** `git diff -- "*.tscn"` vacío.

### Pruebas Manuales (PC `450x800` y Android)
1. En `AJUSTES`, hacer scroll táctil sobre la nueva sección `FONDO REACTIVO` confirmando ausencia de pulsaciones fantasma.
2. Alternar entre `Clásico` y `Ondas` con BGM activado y luego apagado, comprobando la expansión ambiental suave y el pulso de anillos en los beats.
3. Combinar `Ondas` con partículas (`Círculos`, `Cuadrados`, `Estelas`, `Destellos`) y jugar una partida en `GameSession` verificando lectura limpia de notas, línea de juicio y barra inferior.

---

## 10. Casos Límite
- **Sin música / BGM apagado:** `Ondas` sigue emitiendo y expandiendo anillos ambientales suaves cada `~1.85 s`.
- **Actualización desde versiones previas (`v1.0.3` / Fase 7):** ausencia de `[reactive_background]` carga `"classic"` + `"medium"` sin tocar `[menu_bgm]` ni `[reactive_particles]`.
- **Valores inválidos en `.cfg`:** se sanitizan automáticamente a `"classic"` y `"medium"`.
- **Pantallas `20:9` y `16:9`:** `max_radius` se calcula dinámicamente desde el tamaño real del viewport (`_resolve_bounds()`), evitando cortes abruptos en las esquinas.
- **Selección de `Aurora` o `Estrellas Fugaces` en Fase 8A:** persisten en disco y conservan el fondo clásico de forma segura hasta Fase 8B.

---

## 11. Procedimiento de Reversión
1. Ejecutar `git revert <commit_fase_8a>` sobre `main`.
2. La sección `[reactive_background]` en `user://user_settings.cfg` es ignorada de manera inofensiva por versiones previas.

---

## 12. Diff Esperado
- **Nuevos archivos:**
  - `specs/18_reactive_backgrounds_selector_and_waves.md`
  - `vfx/reactive_background_config.gd` (~165 líneas)
- **Modificaciones acotadas:**
  - `vfx/reactive_background.gd` (+~220 líneas para config + preset `Ondas` sin alterar `Clásico`)
  - `ui/main_menu.gd` (+~140 líneas para selector de fondo e intensidad en `AJUSTES`)
  - `gameplay/game_session.gd` (+~20 líneas para cargar `[reactive_background]` al iniciar)
- **Archivos `.tscn` modificados:** `0`.
