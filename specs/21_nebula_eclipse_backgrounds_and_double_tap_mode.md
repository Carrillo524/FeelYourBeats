# Spec 21 — Fondos Difusos Sin Líneas (`Nebulosa` y `Eclipse`) y Modo Independiente `Doble Tap`

## 1. Nombre y Objetivo
- **Nombre:** Catálogo final de 4 fondos reactivos difusos sin líneas (`Clásico`, `Nebulosa`, `Aurora`, `Eclipse`) y modo de notas independiente **`Doble Tap`** (`Tap + Hold`, `Solo Tap`, `Doble Tap`).
- **Objetivo:**
  1. Reemplazar el fondo geométrico `Túnel` (que utilizaba `draw_polyline`) por **`Nebulosa`** y añadir **`Eclipse`**, logrando un catálogo coherente de **4 fondos puramente atmosféricos y difusos** (cero líneas, cero anillos duros, cero ruido visual detrás de los carriles), manteniendo `Clásico` y `Aurora` intactos y conservando el resplandor global suave de acierto de nota.
  2. Separar completamente las **notas dobles simultáneas (acordes a 2 pulgares)** de las dificultades base creando el modo independiente **`Doble Tap`** junto a `Tap + Hold` y `Solo Tap`, de forma que `Tap + Hold` y `Solo Tap` generen estrictamente **`0` acordes** en `Fácil`, `Normal` y `Difícil`, mientras `Doble Tap` habilita acordes ergonómicos (`1 izq {0,1} + 1 der {2,3}`) escalados por dificultad y con `0` colisiones intra-pulgar durante `Hold`, con su propia clave de caché (`v3`) y récords aislados en `user://song_records.cfg`.

---

## 2. Alcance Exacto y Exclusiones

### Archivos Inspeccionados
- `AGENTS.md`
- `vfx/reactive_background_config.gd`
- `vfx/reactive_background.gd`
- `ui/main_menu.gd`
- `core/chart/auto_chart_generator.gd`
- `core/chart/chart_cache_repository.gd`
- `gameplay/game_session.gd`
- `gameplay/hit_judge.gd`

### Archivos a Modificar (Tras Aprobación del Plan)
| Acción | Archivo | Propósito |
| :--- | :--- | :--- |
| **CREAR** | `specs/21_nebula_eclipse_backgrounds_and_double_tap_mode.md` | Spec y contrato previo obligatorio. |
| **MODIFICAR** | `vfx/reactive_background_config.gd` | Reemplazar `Túnel` por `Nebulosa` (`STYLE_NEBULA = "nebula"` migrando retrocompatiblemente `"waves"` / `"ondas"` / `"tunel"` / `"túnel"`), añadir `Eclipse` (`STYLE_ECLIPSE = "eclipse"`), actualizar `SUPPORTED_STYLES` (4 estilos) y `style_to_label()`. |
| **MODIFICAR** | `vfx/reactive_background.gd` | Mantener `Clásico` y `Aurora` intactos; sustituir el dibujado de `Túnel` por `Nebulosa` (nubes amplias de luz radial difusa con `GradientTexture2D` precreada en `_init()`) y añadir `Eclipse` (halo circular radial difuminado amplio centrado sin anillo duro, precreado en `_init()`); extender el resplandor global difuminado de acierto de nota a `Nebulosa`, `Aurora` y `Eclipse`. |
| **MODIFICAR** | `ui/main_menu.gd` | Mostrar los 4 botones de fondo (`Clásico`, `Nebulosa`, `Aurora`, `Eclipse`) en `AJUSTES` en cuadrícula 2×2 con `MOUSE_FILTER_PASS`; añadir botón `DOBLE TAP` como 3.ª opción de modo de notas en el modal de preparación de canción y actualizar `select_note_type_mode()`, `get_modal_option_buttons()` y `_refresh_modal_option_styles()`. |
| **MODIFICAR** | `core/chart/auto_chart_generator.gd` | Añadir `NoteTypeMode.DOUBLE_TAP = 2`; imponer **`0` acordes** en `TAP_AND_HOLD` y `TAP_ONLY` en todas las dificultades; habilitar acordes a 2 pulgares (`1 izq + 1 der`) exclusivamente en `DOUBLE_TAP` escalando su frecuencia con `EASY < NORMAL < HARD`, manteniendo `0` colisiones intra-pulgar durante `Hold`. |
| **MODIFICAR** | `core/chart/chart_cache_repository.gd` | Subir `CACHE_SCHEMA_VERSION` de `"v2"` a `"v3"`, ampliar el escaneo legado de `load_song_summary()` a `range(3)` modos y añadir `note_mode_to_label()`. |
| **MODIFICAR** | `gameplay/game_session.gd` | Actualizar `build_demo_chart(p_note_type_mode)` para generar `0` acordes en `TAP_AND_HOLD` / `TAP_ONLY` y acordes válidos a 2 pulgares (`1 izq + 1 der`, `0` colisiones en `Hold`) en `DOUBLE_TAP`. |

### Exclusiones Explícitas
- **NO** se crea ni edita ningún archivo `.tscn` (`git diff -- "*.tscn"` vacío).
- **NO** se cambia la versión en `project.godot` (permanece en `"1.0.4"`).
- **NO** se modifican `vfx/reactive_backdrop.gdshader` (`Clásico`), la lógica de `Aurora`, ni `vfx/reactive_particles_layer.gd`.
- **NO** se crean assets binarios externos (100 % procedural en GDScript con `GradientTexture2D` precreadas en `_init()`).

---

## 3. Contratos Técnicos y Diseño Detallado

### 3.1 Catálogo de 4 Fondos Difusos Sin Líneas

#### A. `ReactiveBackgroundConfig` (`vfx/reactive_background_config.gd`)
- Constantes de estilo:
  - `STYLE_CLASSIC = "classic"` → `"Clásico"`
  - `STYLE_NEBULA = "nebula"` → `"Nebulosa"` (se mantiene `const STYLE_WAVES: String = "waves"` como alias legado que `sanitize_style()` migra limpiamente a `STYLE_NEBULA`)
  - `STYLE_AURORA = "aurora"` → `"Aurora"`
  - `STYLE_ECLIPSE = "eclipse"` → `"Eclipse"`
- `SUPPORTED_STYLES = [STYLE_CLASSIC, STYLE_NEBULA, STYLE_AURORA, STYLE_ECLIPSE]`.
- Migración retrocompatible en `sanitize_style()`:
  - `"waves"`, `"ondas"`, `"tunel"`, `"túnel"`, `"nebulosa"`, `"nebula"` → `STYLE_NEBULA`.
  - `"eclipse"` → `STYLE_ECLIPSE`.
  - `"shooting_stars"` o desconocidos → `STYLE_CLASSIC`.

#### B. `Nebulosa` (`STYLE_NEBULA` en `vfx/reactive_background.gd`)
- **0 líneas, 0 polilíneas, 0 bordes duros:** elimina por completo `_draw_tunnel_backdrop()` y `draw_polyline`.
- **Textura radial precreada en `_init()` (`_nebula_cloud_texture`):** `GradientTexture2D` `FILL_RADIAL` (`128×128`), caída gaussiana ultra suave (`alpha: 1.0 → 0.56 → 0.20 → 0.05 → 0.0` en `[0.0, 0.26, 0.54, 0.78, 1.0]`).
- **Composición visual (0 asignaciones en heap por frame):**
  - Fondo base vertical cósmico oscuro (`#070616` → `#110620`).
  - `NEBULA_CLOUD_COUNT = 6` nubes amplias elípticas solapadas con deriva orgánica lenta (`sin`/`cos`) en paleta controlada de violeta profundo, índigo y destellos cian (RGB acotado `<= 0.92`, alpha por nube acotado `<= NEBULA_MAX_ALPHA = 0.26`).
  - **Reacción musical:** respiración radial suave impulsada por graves (`_smoothed_bass`) y beat (`_nebula_beat_boost`), más un núcleo luminoso central cian-violeta que se enciende progresivamente durante Drops (`_nebula_drop_boost` / `_current_tier >= 2`).
- **Resplandor de acierto de nota:** invoca `_draw_global_note_hit_flashes(bounds)` al final.

#### C. `Eclipse` (`STYLE_ECLIPSE` en `vfx/reactive_background.gd`)
- **0 líneas, 0 anillos duros:** precrea una sola vez en `_init()` dos `GradientTexture2D` radiales (`FILL_RADIAL`):
  1. `_eclipse_halo_texture` (`256×256`): corona radial difuminada amplia con caída suave tanto hacia el núcleo oscuro interior como hacia el borde exterior (`alpha: 0.0 → 0.14 → 0.88 → 1.0 → 0.52 → 0.16 → 0.0` en `[0.0, 0.14, 0.34, 0.46, 0.64, 0.82, 1.0]`), sin ningún corte o línea fina.
  2. `_eclipse_core_shadow_texture` (`128×128`): sombra central suave nocturna (`alpha: 0.82 → 0.45 → 0.0` en `[0.0, 0.32, 0.62]`) para dar profundidad de eclipse sin contornos rígidos.
- **Composición visual:**
  - Base vertical nocturna oscura (`#050712` → `#0B0618`).
  - Halo amplio centrado en pantalla (`bounds.x * 0.5`, `bounds.y * 0.47`) compuesto por un velo atmosférico exterior, la corona radial principal difusa y la umbra suave interior.
  - **Reacción musical:** respira en radio y luminosidad con graves/beats (`_eclipse_beat_boost`, `_smoothed_bass`) y transiciona suavemente entre **cian** (`Color(0.10, 0.82, 0.92)`) y **violeta** (`Color(0.56, 0.24, 0.92)`) al compás del beat y Drop (`_eclipse_drop_boost`, `_current_tier >= 2`), respetando `ECLIPSE_MAX_ALPHA = 0.34` y RGB `<= 0.92`.
- **Resplandor de acierto de nota:** invoca `_draw_global_note_hit_flashes(bounds)` al final.

#### D. `Clásico` y `Aurora`
- `Clásico` (`STYLE_CLASSIC`) conserva intacto su `ShaderMaterial` (`reactive_backdrop.gdshader`).
- `Aurora` (`STYLE_AURORA`) conserva intactas sus 7 cortinas verticales suaves y su física/paleta actual.

---

### 3.2 Modo Independiente `Doble Tap`

#### A. Enumeración y Reglas de Generación (`core/chart/auto_chart_generator.gd`)
```gdscript
enum NoteTypeMode {
	TAP_AND_HOLD = 0,
	TAP_ONLY = 1,
	DOUBLE_TAP = 2,
}
```
| Modo | `Hold` | Notas Dobles (Acordes a 2 Pulgares) | Ergonomía 2 Pulgares |
| :--- | :--- | :--- | :--- |
| `TAP_AND_HOLD` (`0`) | Sí (acotados) | **No (`0` en `EASY`, `NORMAL`, `HARD`)** | 1 nota a la vez; `0` colisiones intra-pulgar en `Hold` |
| `TAP_ONLY` (`1`) | No (`0`) | **No (`0` en `EASY`, `NORMAL`, `HARD`)** | 1 nota a la vez; separación mínima por pulgar |
| `DOUBLE_TAP` (`2`) | Sí (en notas no-acorde, acotados) | **Sí (`1 izq {0,1} + 1 der {2,3}`)** escalado por dificultad | `0` acordes en misma mano; `0` colisiones intra-pulgar en `Hold` |

- **Escalado de frecuencia de acordes en `DOUBLE_TAP` según dificultad:**
  - `EASY`: beats fuertes (`tier >= 1`), percentil `0.78` (`clamp [0.42, 0.76]`), cooldown `1.85 s` (`1.55 s` en Drop `tier >= 2`).
  - `NORMAL`: beats fuertes y Drops (`tier >= 1`), percentil `0.60` (`clamp [0.34, 0.66]`), cooldown `1.00 s` (`0.80 s` en Drop `tier >= 2`).
  - `HARD`: beats fuertes y Drops intensos (`tier >= 1`), percentil `0.42` (`clamp [0.26, 0.56]`), cooldown `0.55 s` (`0.42 s` en Drop `tier >= 2`).
- **Garantía estricta en `_sanitize_two_thumb_ergonomics()`:** recibe `p_allow_chords: bool`; cuando `p_allow_chords == false` (`TAP_AND_HOLD` y `TAP_ONLY`), impide además que cualquier reubicación cree una nota simultánea, garantizando `0` acordes en esos dos modos.

#### B. Caché `v3` y Récords Aislados (`core/chart/chart_cache_repository.gd`)
- `CACHE_SCHEMA_VERSION = "v3"` (invalida charts `v2` para que `Tap + Hold` y `Solo Tap` se regeneren sin acordes).
- `build_cache_key(audio_path, difficulty, note_type_mode)` ya incluye `note_type_mode`, generando claves únicas para `m0`, `m1` y `m2`.
- `build_record_key(song_key, difficulty, note_type_mode)` genera `song_<hash>_d<diff>_m2` para `DOUBLE_TAP`, completamente aislado de `m0` (`Tap + Hold`) y `m1` (`Solo Tap`) dentro de `user://song_records.cfg` sin borrar récords previos.
- `load_song_summary()` actualiza su escaneo de respaldo de `range(2)` a `range(3)` modos.

#### C. UI en `MainMenu` (`ui/main_menu.gd`)
- **AJUSTES → `ESTILO DE FONDO`:** 2 filas × 2 columnas (`[Clásico, Nebulosa]`, `[Aurora, Eclipse]`) para lectura cómoda en móvil `1080×1920` / PC `450×800`, pasando por `_configure_touch_scroll_container(_settings_scroll)` (`MOUSE_FILTER_PASS`).
- **Modal de preparación → `MODO DE NOTAS`:** fila horizontal con 3 botones iguales (`TAP + HOLD`, `SOLO TAP`, `DOBLE TAP`) con `font_size = 30` para evitar recortes; `select_note_type_mode()` permite `0..2` y actualiza `_refresh_modal_record_label()` mostrando el récord específico de `(canción, dificultad, modo)`.

---

## 4. Casos Límite
- **Configuración legada `style = "waves"` / `"tunel"` / `"ondas"` en `user://user_settings.cfg`:** se migra automáticamente a `"nebula"` sin romper ni perder la selección de intensidad musical.
- **Configuración legada `style = "shooting_stars"` o corrupta:** cae limpiamente a `"classic"`.
- **Pista silenciosa o muy corta en `DOUBLE_TAP`:** devuelve chart válido con `0` violaciones ergonómicas y sin divisiones por cero.
- **Cambio rápido entre los 4 estilos de fondo en tiempo real:** limpia los boosts transitorios y actualiza `material` (`ShaderMaterial` solo en `Clásico`, `null` en `Nebulosa`, `Aurora`, `Eclipse`) sin fugas ni asignaciones por frame.
- **Demo integrada (`GameSession.build_demo_chart()`):** `TAP_AND_HOLD` y `TAP_ONLY` tienen `0` acordes; `DOUBLE_TAP` genera acordes válidos `1 izq + 1 der` con `0` colisiones durante `Hold`.

---

## 5. Criterios de Aceptación Verificables
1. `ReactiveBackgroundConfig.SUPPORTED_STYLES` contiene exactamente `["classic", "nebula", "aurora", "eclipse"]` con etiquetas `"Clásico"`, `"Nebulosa"`, `"Aurora"`, `"Eclipse"`, y `"waves"` / `"tunel"` migran a `"nebula"`.
2. `ReactiveBackground` renderiza los 4 fondos sin errores; `Nebulosa` y `Eclipse` utilizan exclusivamente texturas radiales difusas `GradientTexture2D` precreadas en `_init()` (cero `draw_line`, `draw_polyline` o `draw_arc`), reaccionan a beats/graves/Drops y dibujan el resplandor global de acierto de nota; `Clásico` y `Aurora` permanecen intactos.
3. En `MainMenu`: `AJUSTES` expone los 4 botones de estilo de fondo con `MOUSE_FILTER_PASS`; el modal de canción expone `TAP + HOLD`, `SOLO TAP` y `DOBLE TAP`, permite seleccionar `DOUBLE_TAP` independientemente de `Fácil`/`Normal`/`Difícil` y muestra récords independientes por modo.
4. `AutoChartGenerator`:
   - `TAP_AND_HOLD` y `TAP_ONLY` generan estrictamente **`0` acordes** en `EASY`, `NORMAL` y `HARD` (en pista sintética, las 6 canciones de `res://assets/songs/` y `build_demo_chart()`).
   - `DOUBLE_TAP` genera acordes válidos estrictamente a 2 pulgares (`1 izq + 1 der`, `0` acordes en misma mano) en `EASY`, `NORMAL` y `HARD`, con frecuencia creciente según dificultad (`chords(EASY) <= chords(NORMAL) <= chords(HARD)` y `chords(EASY) < chords(HARD)`), manteniendo `0` colisiones intra-pulgar durante `Hold`.
5. `ChartCacheRepository.CACHE_SCHEMA_VERSION == "v3"`, las claves de caché y récords de `DOUBLE_TAP` (`m2`) están aisladas de `m0` y `m1`, `git diff -- "*.tscn"` está vacío y `project.godot` permanece en `"1.0.4"`.
6. `--headless --quit --check-only` pasa con 0 errores y 0 advertencias en todos los scripts modificados.

---

## 6. Plan de Pruebas Headless y Reversión
1. `--headless --quit --check-only` en los 6 `.gd` modificados.
2. Script temporal `scratch/verify_phase21_backgrounds_and_double_tap.gd` (`get_tree().quit(0)`), eliminando `scratch/` en `finally`:
   - Verificación de los 4 fondos (`ReactiveBackgroundConfig` + `ReactiveBackground` + inspección de ausencia de `draw_polyline`/`draw_line`/`draw_arc` en `Nebulosa`/`Eclipse` + reacción musical + hit flash + migración `"waves" -> "nebula"`).
   - Verificación de `MainMenu` (4 botones de fondo con `MOUSE_FILTER_PASS` + 3 botones de modo de notas y selección independiente).
   - Verificación de `AutoChartGenerator` y `GameSession.build_demo_chart()` en `EASY`/`NORMAL`/`HARD` × `TAP_AND_HOLD`/`TAP_ONLY`/`DOUBLE_TAP` (pista sintética + canciones de `res://assets/songs/`): `0` acordes en `TAP_AND_HOLD`/`TAP_ONLY`, acordes 2-pulgares crecientes en `DOUBLE_TAP`, `0` colisiones intra-pulgar en `Hold`.
   - Verificación de caché `v3`, récords aislados `m0`/`m1`/`m2`, `git diff -- "*.tscn"` vacío y `project.godot` en `"1.0.4"`.
3. **Reversión:** revertir limpiamente con `git revert <commit>` sobre `main` sin pérdida de `user://song_records.cfg` (los récords previos `m0`/`m1` siguen intactos).
