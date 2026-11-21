# Spec 19 — Fondos Ondas Continuas y Aurora Boreal + Traslado de Estrellas Fugaces a Partículas Reactivas (Fase 8B)

## 1. Nombre y Objetivo
- **Nombre:** Fondos `Ondas` continuas y `Aurora` boreal + `Estrellas Fugaces` como 6.ª variante de Partículas Reactivas (Fase 8B).
- **Objetivo:** Consolidar una separación arquitectónica y visual clara en **FeelYourBeats (FyB)** entre **fondos atmosféricos de gran escala** (`Clásico`, `Ondas` líquidas continuas de borde a borde, `Aurora` boreal) y **partículas discretas superpuestas** (`Ninguna`, `Círculos`, `Cuadrados`, `Estelas`, `Destellos`, `Estrellas Fugaces`), implementado 100 % en GDScript con tipado estático estricto, 0 assets externos, 0 ediciones de `.tscn` y migración retrocompatible en `user://user_settings.cfg`.

---

## 2. Problema que Resuelve
En la Fase 8A quedaron dos puntos por refinar para lograr una experiencia visual coherente y combinable:
1. **Separación conceptual fondo vs. partículas:** `Estrellas Fugaces` es un elemento discreto en movimiento (similar a `Estelas` y `Destellos`), por lo que ubicarlo en `Partículas Reactivas` permite combinarlo libremente con cualquier fondo atmosférico (`Clásico`, `Ondas` o `Aurora`) en lugar de bloquear la elección de fondo.
2. **Completitud y escala atmosférica de los fondos:** `Ondas` (anteriormente anillos pequeños tipo lluvia) gana mayor identidad como fondo continuo de gran escala con 2–3 ondas líquidas de borde a borde en la zona media-baja, y `Aurora` completa el catálogo de 3 fondos activos eliminando cualquier aviso provisional de "pendiente de Fase 8B" en `AJUSTES`.

---

## 3. Alcance Exacto (Fase 8B)
Incluye exclusivamente:
1. **Fondos Reactivos (`ReactiveBackgroundConfig` y `ReactiveBackground`) — 3 estilos activos:**
   - **`Clásico` (`"classic"`):** conservado 100 % intacto como predeterminado (`vfx/reactive_backdrop.gdshader` sin cambios).
   - **`Túnel` (clave interna retrocompatible `STYLE_WAVES = "waves"`, etiqueta UI `"Túnel"`):** túnel de perspectiva neón compuesto por un pool acotado de `12` marcos octogonales/rectangulares biselados huecos (sin relleno) que nacen diminutos en el centro (`scale = 0.04`) y avanzan exponencialmente hacia los bordes (`scale -> 1.15`) en cian y violeta con halo suave de 3 capas translúcidas y alfa bajo (`0.07–0.22`) para preservar la legibilidad; avanza suavemente en ambiente y acelera e intensifica brillo en beats y Drops.
   - **`Aurora` (`"aurora"`):** 4 cortinas luminosas amplias y difusas (bandas verticales/diagonales con degradados translúcidos en `_draw()`, sin `WorldEnvironment` global) que ondulan lentamente y transicionan suavemente entre cian, violeta y azul neón, intensificando brillo y ondulación en beats y drops.
   - **Migración retrocompatible:** `ReactiveBackgroundConfig` conserva exactamente 3 estilos válidos (`"classic"`, `"waves"`, `"aurora"`). Si un `user://user_settings.cfg` antiguo contenía `style="shooting_stars"` en `[reactive_background]`, `sanitize_style()` lo normaliza silenciosamente a `"classic"` sin errores ni corrupción.
2. **Partículas Reactivas (`ReactiveParticlesConfig` y `ReactiveParticlesLayer`) — añadir `Estrellas Fugaces`:**
   - Nueva 6.ª variante mutuamente excluyente: `TYPE_SHOOTING_STARS = "shooting_stars"` (`"Estrellas Fugaces"`), junto a `Ninguna`, `Círculos`, `Cuadrados`, `Estelas` y `Destellos`.
   - Presupuesto estrictamente acotado para elegancia y legibilidad: **`3` en Baja, `6` en Media, `10` en Alta**.
   - Renderizado en `_draw()` como trazo diagonal fino (`28°–38°`), cola larga degradada en segmentos suaves (`alpha = 0.0` → brillante) y cabeza luminosa circular usando la textura compartida `_soft_radial_texture`. Aparición esporádica en ambiente sin música, lanzamientos más veloces y luminosos en beats/drops y desvanecimiento suave al salir de los bordes.
   - `Ninguna`, `Círculos`, `Cuadrados`, `Estelas` y `Destellos` permanecen 100 % intactos.
3. **Controles en `AJUSTES` (`MainMenu`) y carga en `GameSession`:**
   - Sección **FONDO REACTIVO:** muestra únicamente los 3 estilos (**Clásico**, **Ondas**, **Aurora**) sin ningún texto provisional de función pendiente.
   - Sección **PARTÍCULAS REACTIVAS:** añade el botón **Estrellas Fugaces** (6 botones dispuestos en 3 filas limpias de 2 para evitar recortes en móvil) con `MOUSE_FILTER_PASS`, guarda `_consume_suppressed_scroll_press()` y vista previa en vivo inmediata.
   - `GameSession` recarga y renderiza automáticamente cualquiera de los 3 fondos y las 6 partículas sin requerir cambios estructurales.

### Fuera de Alcance
- Cambios en `vfx/reactive_backdrop.gdshader`, `gameplay/game_session.gd` o cualquier archivo `.tscn`.
- Modificación del comportamiento visual de `Clásico`, `Círculos`, `Cuadrados`, `Estelas` o `Destellos`.
- Uso de `WorldEnvironment` o assets externos.

---

## 4. Archivos a Inspeccionar
- `AGENTS.md` — tipado estático estricto, separación de capas, `edge_to_edge` y prohibición de `.tscn`.
- `specs/17_reactive_particles_mist_and_sparkles.md` y `specs/18_reactive_backgrounds_selector_and_waves.md` — contratos actuales de partículas y fondos.
- `vfx/reactive_background_config.gd` y `vfx/reactive_background.gd` — selector de estilos, señales `bass_kick_pulsed`/`screen_shake_updated` y dibujo de `Ondas`.
- `vfx/reactive_particles_config.gd` y `vfx/reactive_particles_layer.gd` — contrato de variantes, presupuestos, `_soft_radial_texture` y pool en `PackedArrays`.
- `ui/main_menu.gd` — secciones `PARTÍCULAS REACTIVAS` y `FONDO REACTIVO` dentro de `SettingsTabScroll`.

---

## 5. Archivos a Modificar
| Acción | Archivo | Propósito |
| :--- | :--- | :--- |
| **CREAR** | `specs/19_reactive_backgrounds_aurora_and_shooting_stars_particle.md` | Spec independiente de la Fase 8B. |
| **MODIFICAR** | `vfx/reactive_background_config.gd` | Dejar exactamente 3 estilos (`classic`, `waves`, `aurora`), normalizar legacy `"shooting_stars"` → `"classic"` en `sanitize_style()` y marcar todos los estilos como activos. |
| **MODIFICAR** | `vfx/reactive_background.gd` | Reemplazar anillos dispersos de `"waves"` por 3 ondas líquidas continuas de borde a borde e implementar `"aurora"` (4 cortinas boreales difusas con transición de color y respuesta a beats/drops), dejando `"classic"` intacto. |
| **MODIFICAR** | `vfx/reactive_particles_config.gd` | Añadir `TYPE_SHOOTING_STARS = "shooting_stars"` (`"Estrellas Fugaces"`) con presupuesto `3 / 6 / 10` en `get_effective_particle_count()`. |
| **MODIFICAR** | `vfx/reactive_particles_layer.gd` | Implementar spawn/step/draw de `TYPE_SHOOTING_STARS` (trazos diagonales `28°–38°` con cabeza `_soft_radial_texture` y estela degradada) sin alterar las variantes existentes. |
| **MODIFICAR** | `ui/main_menu.gd` | Actualizar `FONDO REACTIVO` a 3 botones (`Clásico`, `Ondas`, `Aurora`) eliminando el aviso provisional de Fase 8B, y añadir `Estrellas Fugaces` a `PARTÍCULAS REACTIVAS` con `MOUSE_FILTER_PASS` y vista previa en vivo. |

### Exclusiones Explícitas de `.tscn`
- **NO** se modificará `ui/main_menu.tscn`, `ui/game_session.tscn` ni ningún otro archivo `.tscn`.
- Verificación obligatoria: `git diff -- "*.tscn"` vacío.

---

## 6. Migración Retrocompatible de `user://user_settings.cfg`
- Las secciones `[menu_bgm]`, `[reactive_particles]` y `[reactive_background]` siguen coexistiendo en `user://user_settings.cfg`.
- Si un archivo previo guardó `style="shooting_stars"` bajo `[reactive_background]`, `ReactiveBackgroundConfig.sanitize_style("shooting_stars")` retorna `"classic"` de forma segura y silenciosa, evitando estados inválidos sin tocar `[menu_bgm]` ni `[reactive_particles]`.
- En `[reactive_particles]`, `type="shooting_stars"` pasa a ser una clave válida y persistible con etiqueta `"Estrellas Fugaces"`.

---

## 7. Diseño Técnico y Rendimiento Móvil

### 7.1 Fondo `Túnel` en Perspectiva (`style == "waves"`, etiqueta `"Túnel"`)
- **Base:** `material = null` + degradado oscuro vertical (`Color(0.032, 0.042, 0.105)` → `Color(0.068, 0.028, 0.138)`).
- **12 marcos huecos en perspectiva:** octógonos biselados sin relleno (`draw_polyline` cerrado de 9 vértices) que nacen en el centro (`scale = 0.04`) y crecen exponencialmente (`pow(t, 2.35)` hasta `scale = 1.15`) hacia los bordes en cian y violeta, con 3 capas de halo suave translúcido (`5.2x`, `2.6x`, `1.0x`) y alfa bajo (`0.07–0.22` base, tope `<= 0.30` en picos) sin reducir legibilidad.
- **Reacción musical:** avance constante en ambiente sin música (`0.28` u/s); en beats y Drops acelera (`1.0 + drive * 1.45`) e intensifica el brillo (`1.0 + drive * 0.65`).

### 7.3b Dinámica Sostenida de `Drop` en Todas las Partículas
- `ReactiveParticlesLayer` combina `_beat_impulse` instantáneo con un envolvente suavizado de energía sostenida (`_sustained_energy_drive`) alimentado por `DSPClock.intensity_changed` (`tier >= 2`), `AudioAnalyzer.spectrum_updated` y `trigger_beat_impulse()`, logrando durante todo el Drop:
  - **`Círculos`:** aceleración hacia adelante hasta `~2.8x` + mayor radio/suavidad de halo blur.
  - **`Cuadrados`:** flotación y rotación hasta `~2.4x` + pulso de escala y halo neón ampliado.
  - **`Estelas`:** ascenso hasta `~3.0x`, **alargamiento de estela hasta `2.4x`** y halo de punta más amplio.
  - **`Destellos`:** ciclo de parpadeo/deriva hasta `~2.4x` + expansión del halo circular blur (`4.2x -> 11.2x`).
  - **`Estrellas Fugaces`:** cruce diagonal hasta `~2.8x`, **alargamiento de estela `2.2x–2.6x`**, halo/blur reforzado en cabeza y trazo, y reducción de espera entre apariciones.

### 7.2 Fondo `Aurora` Boreal (`style == "aurora"`)
- **Base:** `material = null` + cielo nocturno profundo (`Color(0.024, 0.036, 0.092)` → `Color(0.052, 0.024, 0.112)`).
- **4 cortinas amplias verticales/diagonales (`16` bandas por cortina):** mallas de quads translúcidos con opacidad nula en bordes superior e inferior y doble capa de ancho (cortina difusa amplia + núcleo luminoso suave), evitando bordes duros y manteniendo opacidad contenida (`<= 0.24` por cortina) para máxima legibilidad.
- **Transición de color y ondulación:** ciclo sinusoidal continuo entre **cian** (`Color(0.18, 0.90, 0.96)`), **violeta** (`Color(0.64, 0.30, 0.98)`) y **azul neón** (`Color(0.24, 0.56, 1.0)`). En beats y drops aumenta brillo (`1.0 + drive * 0.58`) y amplitud de ondulación (`1.0 + drive * 0.48`), regresando suavemente al reposo.

### 7.3 Partícula `Estrellas Fugaces` (`TYPE_SHOOTING_STARS = "shooting_stars"`)
- **Presupuesto acotado:** `3` (Baja), `6` (Media), `10` (Alta) slots en los arreglos paralelos `Packed*Array` existentes (0 asignaciones por frame).
- **Trayectoria diagonal y aspecto:**
  - Ángulo diagonal fino entre `28°` y `38°` descendiendo a través de la pantalla (`dx > 0`, `dy > 0`, `atan2(dy, dx) ∈ [28°, 38°]`).
  - Estela larga (`120–240 px`) en `6` segmentos `draw_line` desde cola transparente (`alpha = 0.0`) hasta cabeza brillante en tonos blanco hielo, cian y violeta suave, coronada con un halo circular `_soft_radial_texture` y núcleo `draw_circle`.
- **Aparición esporádica y ráfagas al beat:**
  - Sin música: cada slot entra en espera aleatoria (`0.6–2.6 s`) tras salir del borde (presembrando 1–2 activas al seleccionar para vista previa inmediata) generando cruces elegantes y espaciados.
  - En beats/drops: `trigger_beat_impulse()` despierta slots en espera (`1`–`2` según reactividad) con velocidad y brillo aumentados, y acelera/ilumina las estrellas en vuelo actual, desvaneciéndose suavemente al cruzar el borde.

### 7.4 Impacto en Rendimiento Móvil
- **Muy bajo:** en `Ondas` (`3 × 32 = 96` quads + `9` polylines) y `Aurora` (`4 × 16 × 2 = 128` quads), `material = null` elimina el costo por píxel del shader clásico; en `Estrellas Fugaces` hay como máximo `10` estrellas (`60` líneas + `10` texturas compartidas). Mantiene 60+ FPS estables en renderizador `mobile`.

---

## 8. Criterios de Aceptación Verificables
1. **3 Fondos limpios + migración:** `ReactiveBackgroundConfig.SUPPORTED_STYLES` tiene exactamente `["classic", "waves", "aurora"]`; cargar un `.cfg` con `style="shooting_stars"` devuelve `"classic"` sin errores y preserva `[menu_bgm]` y `[reactive_particles]`.
2. **Fondo `Ondas` continuo:** `style == "waves"` renderiza 3 ondas continuas de borde a borde confinadas a la zona media-baja (`min_crest_y >= 0.50 * h`), con flujo continuo sin música y aumento de amplitud/brillo tras beat/drop.
3. **Fondo `Aurora`:** `style == "aurora"` renderiza 4 cortinas difusas (`material == null`), transiciona suavemente su color a lo largo del tiempo sin música y aumenta brillo/ondulación tras beat/drop.
4. **Fondo `Clásico` intacto:** mantiene `material != null` (`ShaderMaterial` original) y `0` trazos 2D adicionales.
5. **6 Partículas incluyendo `Estrellas Fugaces`:** `ReactiveParticlesConfig.SUPPORTED_TYPES` incluye los 6 tipos; `TYPE_SHOOTING_STARS` asigna `3 / 6 / 10` slots, vuela en diagonal (`28°–38°`), tiene movimiento/apariciones esporádicas sin música y acelera/lanza estrellas tras `trigger_beat_impulse()`. `Círculos`, `Cuadrados`, `Estelas` y `Destellos` sin regresión.
6. **UI `AJUSTES` limpia y táctil:** `FONDO REACTIVO` tiene exactamente 3 botones (`Clásico`, `Ondas`, `Aurora`) sin aviso provisional (`BackgroundStyleHintLabel` ausente); `PARTÍCULAS REACTIVAS` incluye el botón `Estrellas Fugaces`; todos los botones tienen `MOUSE_FILTER_PASS` y vista previa en vivo.
7. **Tipado estricto y cero `.tscn`:** `--check-only` con 0 errores y 0 advertencias en los 5 scripts y `git diff -- "*.tscn"` vacío.

---

## 9. Pruebas Automatizadas y Manuales

### Pruebas Automatizadas (Headless)
1. `--headless --quit --check-only` sobre:
   - `res://vfx/reactive_background_config.gd`
   - `res://vfx/reactive_background.gd`
   - `res://vfx/reactive_particles_config.gd`
   - `res://vfx/reactive_particles_layer.gd`
   - `res://ui/main_menu.gd`
2. Script temporal `scratch/verify_phase8b_backgrounds_and_stars.gd` (`get_tree().quit(0)`), eliminando `scratch/` en `finally`:
   - **(a) Los 3 fondos:** verifica `classic` intacto (`material != null`), `waves` continuo (`3` ondas de borde a borde, `min_crest_y_ratio >= 0.50`, flujo sin música y boost de amplitud en beat), y `aurora` (`4` cortinas, transición suave de color al avanzar tiempo, boost de brillo/ondulación en beat).
   - **(b) Las 6 partículas:** verifica `shooting_stars` (`3 / 6 / 10`), ángulos diagonales en `[28°, 38°]`, vuelo diagonal sin música y aceleración/despertar al beat, más no regresión en `circles`, `squares`, `mist` (`Estelas`), `sparkles` y `none`.
   - **(c) Migración retrocompatible:** archivo `.cfg` con `[reactive_background] style="shooting_stars"` carga como `"classic"` sin perder `[menu_bgm]` ni `[reactive_particles]`.
   - **(d) `AJUSTES` en `MainMenu` y `GameSession`:** verifica 3 botones de fondo sin hint provisional, botón `Estrellas Fugaces` en partículas, `MOUSE_FILTER_PASS` en todos y activación inmediata en `MainMenu` y `GameSession`.
   - **(e) Exclusión `.tscn`:** `git diff -- "*.tscn"` vacío.

### Pruebas Manuales (PC `450x800` y Android)
1. En `AJUSTES`, probar los 3 fondos (`Clásico`, `Ondas`, `Aurora`) y comprobar el contraste con los textos y la vista previa en vivo con y sin BGM.
2. Combinar `Aurora` + `Estrellas Fugaces` (y `Ondas` + `Estrellas Fugaces`) en `MainMenu` y en una partida de `GameSession`, verificando legibilidad completa de notas, línea de juicio y barra de progreso inferior.

---

## 10. Casos Límite
- **Sin música / BGM apagado:** `Ondas` fluye suavemente, `Aurora` ondula y rota colores con calma, y `Estrellas Fugaces` realiza cruces esporádicos sin congelarse.
- **Migración desde Fase 8A con `"shooting_stars"` en `[reactive_background]`:** se normaliza limpiamente a `"classic"`.
- **Cambio rápido entre presets:** buffers y fases se reinician limpiamente sin fugas ni destellos bruscos.
- **Pantallas `20:9` y `16:9`:** las ondas abarcan siempre `0 .. bounds.x` y las estrellas fugaces ajustan su spawn/salida al tamaño real del viewport.

---

## 11. Procedimiento de Reversión
1. Ejecutar `git revert <commit_fase_8b>` sobre `main`.
2. Las claves desconocidas en `user://user_settings.cfg` se sanitizan automáticamente a sus valores por defecto seguros (`"classic"` / `"none"`).

---

## 12. Diff Esperado
- **Nuevo archivo:** `specs/19_reactive_backgrounds_aurora_and_shooting_stars_particle.md`
- **Modificaciones acotadas:**
  - `vfx/reactive_background_config.gd` (-~10 / +~10 líneas)
  - `vfx/reactive_background.gd` (~+260 / -190 líneas sustituyendo anillos por ondas continuas y añadiendo aurora)
  - `vfx/reactive_particles_config.gd` (+~25 líneas)
  - `vfx/reactive_particles_layer.gd` (+~175 líneas)
  - `ui/main_menu.gd` (-~35 / +~25 líneas: 3 botones de fondo sin hint + 6 botones de partículas en 3 filas de 2)
- **Archivos `.tscn` modificados:** `0`.
