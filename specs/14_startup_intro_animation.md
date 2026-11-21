# Spec 14 — Fase 5: Animación de Entrada Inicial (`Cold Start`) con Onda Neón Sutil

## 1. Nombre y Objetivo
- **Nombre:** Animación de Entrada Inicial Única del Menú Principal (`Fase 5`).
- **Objetivo:** Dotar a **FeelYourBeats (FyB)** de una presentación inicial breve, elegante y fluida (`~0.95 s`) la primera vez que se abre la aplicación (*cold start*), revelando progresivamente el título/logotipo (`FEEL YOUR BEATS`), los controles principales y los elementos secundarios junto con una onda circular neón expansiva sutil dibujada por código, bloqueando interacciones accidentales durante la transición y evitando su repetición al volver desde una partida (`GameSession`).

---

## 2. Problema que Resuelve
Al abrir la aplicación actualmente, `MainMenu` aparece de golpe en un solo frame sin transición visual de entrada. Introducir una secuencia ligera de entrada únicamente en el primer arranque mejora notablemente la sensación de acabado del juego sin retrasar la disponibilidad ni reaparecer de forma molesta al regresar al selector tras cada partida.

---

## 3. Alcance Exacto y Dependencias
- **Rama de trabajo:** `main`
- **Dependencias con fases anteriores:**
  - **Fase 1 (`a3cf69d`):** Respeta `quit_on_go_back=false`, `auto_accept_quit=false` y el debounce de `300 ms` del gesto Atrás; bloquea `handle_back_request()` durante los `~0.95 s` de la intro.
  - **Fase 2 (`caf695e`):** Mantiene intacto el scroll táctil (`_find_touch_scroll_container_at()` retorna `null` mientras `_is_playing_startup_intro == true`).
  - **Fase 3 (`d2339e3`):** Convive limpiamente con `_loading_overlay` (`z_index = 90`) y `_transition_fade_rect` (`z_index = 100`), utilizando una capa temporal de intro (`z_index = 95`) que se elimina por completo al finalizar.
  - **Fase 4 (`d22bf2a`):** Sin impacto en `GameSession` ni `SafeHud`.
- **Archivos inspeccionados (lectura):**
  - `AGENTS.md`
  - `specs/09_main_menu_and_song_selector.md`
  - `ui/main_menu.gd`
  - `ui/main_menu.tscn`
- **Archivos a crear/modificar en Fase 5:**
  1. `specs/14_startup_intro_animation.md` (esta especificación)
  2. `ui/main_menu.gd` (único script `.gd` modificado)
- **Exclusiones explícitas:**
  - **Cero modificaciones a archivos `.tscn`** (`ui/main_menu.tscn`, `ui/game_session.tscn`, etc.), cumpliendo estrictamente `AGENTS.md` (§6).
  - La intro no depende de cargas de audio ni de disco para progresar ni finalizar.

---

## 4. Diseño Técnico y Línea de Tiempo (`~0.95 s`, `ui/main_menu.gd`, tipado estático estricto)

### 4.1. Control de Ejecución Única (`Cold Start`)
- Bandera estática en `MainMenu`:
  - `static var _has_played_startup_intro: bool = false`
  - `static func reset_startup_intro_for_tests() -> void`
  - `static func has_played_startup_intro() -> bool`
  - `func is_playing_startup_intro() -> bool`
- En `_ready()`:
  - Si `open_directly_to_selector == true` (retorno desde `GameSession` / Resultados): marca `_has_played_startup_intro = true` y omite la intro inmediatamente.
  - Si `not _has_played_startup_intro`: marca `_has_played_startup_intro = true` y ejecuta `_start_startup_intro()`.
  - En cualquier segunda instanciación de `MainMenu` dentro de la misma ejecución, `_has_played_startup_intro` ya es `true` y la intro se omite por completo.

### 4.2. Línea de Tiempo Exacta (`STARTUP_INTRO_TOTAL_SEC = 1.50`)
| Ventana (`s`) | Elemento | Animación (`Tween` / `_draw`) |
| :--- | :--- | :--- |
| `0.00 -> 0.40` | **Velo oscuro base** (`_intro_veil_rect`) | `modulate:a` de `1.0` a `0.0` (`TRANS_SINE`, `EASE_OUT`), independiente de audio/disco. |
| `0.18 -> 0.78` | **Título / Logotipo** (`_hero_title_label` en portada o `_browser_header_label` en navegador) | `modulate:a` `0.0 -> 1.0`, `scale` `0.94 -> 1.0` y ligera elevación vertical (`+22 px -> 0 px`) con `TRANS_CUBIC`, `EASE_OUT`. |
| `0.28 -> 1.00` (`0.72 s`) | **Onda circular neón / "boom"** (`_intro_wave_fx`) | Dibujada por código (`_draw()` / `queue_redraw()`) centrada en el título/logotipo: anillo exterior cian con halo suave + anillo interior violeta/cian que se expanden de `24 px` a `~340 px` desvaneciéndose suavemente a `alpha = 0.0` sin saturar la pantalla ni mover el layout. |
| `0.54 -> 1.08` | **Botón principal / Fila de pestañas** (`_hero_play_button` o `_tabs_row`) | `modulate:a` `0.0 -> 1.0` y `scale` `0.94 -> 1.0` (`TRANS_CUBIC`, `EASE_OUT`). |
| `0.82 -> 1.50` | **Elementos secundarios / Listado inferior** (`_hero_subtitle_label` o `_content_sheet_panel`) | `modulate:a` `0.0 -> 1.0` (`TRANS_CUBIC`, `EASE_OUT`). |
| `1.50` | **Finalización y limpieza** (`_finish_startup_intro()`) | `_is_playing_startup_intro = false`, garantiza `modulate = Color(1, 1, 1, 1)` y `scale = Vector2.ONE` en todos los nodos revelados, reaplica layout base exacto y libera (`queue_free()`) la capa temporal `_intro_overlay`. |

### 4.3. Bloqueo de Interacción y Convivencia con `_process()`
- Mientras `_is_playing_startup_intro == true`:
  - `_intro_overlay` (`PRESET_FULL_RECT`, `z_index = 95`, `mouse_filter = Control.MOUSE_FILTER_STOP`) intercepta todos los clics y toques sobre la pantalla.
  - Los handlers clave (`_on_hero_play_pressed()`, `select_tab()`, `_on_song_row_pressed()`, `open_song_setup_modal()`, `_on_play_button_pressed()`, `handle_back_request()`, `_find_touch_scroll_container_at()`) verifican `if _is_playing_startup_intro: return` como defensa en profundidad.
  - En `_process()`, el pulso reactivo al BGM sobre `_hero_title_label` y `_hero_play_button` se pausa únicamente mientras `_is_playing_startup_intro == true` para no sobrescribir `modulate`/`scale` del `Tween` de entrada, retomando suavemente al terminar.
  - El progreso de la onda neón (`_intro_wave_progress: float`, `0.0..1.0`) se anima mediante `tween_method(_set_intro_wave_progress, 0.0, 1.0, 0.45)` disparando `_intro_wave_fx.queue_redraw()` en cada paso.
- En `_exit_tree()`: si `_intro_tween != null`, se llama a `_intro_tween.kill()` y se libera la referencia limpiamente.

---

## 5. Casos Límite Cubiertos
| Caso Límite | Comportamiento Esperado |
| :--- | :--- |
| **Regreso desde `GameSession` / Resultados** | `open_directly_to_selector == true` y/o `_has_played_startup_intro == true`: se omite por completo la intro y el selector queda interactivo desde el frame 0. |
| **Gesto Atrás durante la intro (`< 0.95 s`)** | `handle_back_request()` ignora el gesto mientras `_is_playing_startup_intro == true`, evitando abrir el modal de salida sobre la animación. |
| **Clics/toques durante la intro** | Bloqueados tanto por `_intro_overlay` (`MOUSE_FILTER_STOP`) como por guards en los callbacks; al terminar (`0.95 s`) la capa temporal se elimina y el menú responde al 100 %. |
| **Recursos lentos o ausencia de BGM/SFX** | El `Tween` depende únicamente del reloj de escena de Godot; nunca espera audio, disco ni red para completarse. |
| **Cambio de tamaño de viewport durante la intro** | `_intro_overlay` cubre el viewport completo y `_finish_startup_intro()` restaura `modulate = Color.WHITE`, `scale = Vector2.ONE` y la geometría exacta del layout seguro. |

---

## 6. Impacto en Rendimiento
- Complejidad **O(1)** durante `0.95 s` (1 `Tween`, 3 `draw_arc` + 1 `draw_circle` durante `0.45 s`).
- Al finalizar (`0.95 s`), `_intro_overlay` se elimina con `queue_free()`, dejando **0 sobrecarga permanente** de nodos, memoria o CPU en el menú.

---

## 7. Criterios de Aceptación Verificables
- [ ] En el primer arranque (`cold start`), `is_playing_startup_intro() == true` al completar `_ready()` y las pulsaciones sobre botones (`_hero_play_button` / pestañas) quedan bloqueadas mientras la intro está activa.
- [ ] La onda circular neón se dibuja por código (`_draw()`) sin nodos externos ni archivos `.tscn` y avanza de `0.0` a `1.0`.
- [ ] Al completarse la intro (`~0.95 s`), `is_playing_startup_intro() == false`, `_intro_overlay` queda liberado, todos los elementos revelados terminan con `modulate.a == 1.0` y `scale == Vector2.ONE`, y los botones vuelven a responder al instante.
- [ ] Al instanciar `MainMenu` una segunda vez (simulando regreso desde `GameSession`), `is_playing_startup_intro() == false` desde el instante inicial y todos los controles están habilitados de inmediato.
- [ ] `MainMenu.reset_startup_intro_for_tests()` permite reiniciar la bandera estática en pruebas automatizadas.
- [ ] `--headless --quit --check-only` sobre `res://ui/main_menu.gd` retorna 0 errores y 0 advertencias.
- [ ] `git diff -- "*.tscn"` está completamente vacío.

---

## 8. Plan de Pruebas (Automatizadas y Manuales)

### 8.1. Automatizadas (Headless, eliminando `scratch/` siempre en `finally`)
1. Validación estática:
   ```powershell
   & "C:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://ui/main_menu.gd"
   ```
2. Prueba headless temporal `scratch/verify_phase5_startup_intro.gd` (terminando con `quit(0)`):
   - **(a) Primer arranque (`cold start`):** Llama a `MainMenu.reset_startup_intro_for_tests()`, instancia `MainMenu` y lo añade al árbol -> verifica `is_playing_startup_intro() == true`, intenta pulsar `_hero_play_button` y ejecutar `handle_back_request()` -> verifica que el botón fue bloqueado (`is_title_screen_visible() == true`, `is_browser_screen_visible() == false`, `is_exit_confirm_modal_open() == false`).
   - **(b) Finalización completa (`~1.05 s`):** Avanza frames hasta completar la intro -> verifica `is_playing_startup_intro() == false`, onda neón completada, `modulate.a == 1.0` en título/botón/subtítulo, capa temporal `_intro_overlay` limpiada, y ahora pulsar `_hero_play_button` sí abre la pantalla de pestañas (`is_browser_screen_visible() == true`).
   - **(c) Segundo arranque (regreso desde `GameSession`):** Libera la primera instancia e instancia un nuevo `MainMenu` -> verifica `is_playing_startup_intro() == false` inmediatamente desde `_ready()`, `modulate.a == 1.0` y botones interactivos al instante.
   - **(d) Integridad `.tscn`:** Verifica `git diff -- "*.tscn"` vacío y elimina `scratch/` en `finally`.

### 8.2. Pruebas Manuales (Android y PC)
- Abrir el juego desde cero (`F5` o ícono en Android): observar el fade-in breve, la revelación escalonada de `FEEL YOUR BEATS` -> `JUGAR` -> subtítulo y la onda circular neón sutil; entrar a una canción y volver al menú principal verificando que la intro **no** vuelve a reproducirse.

---

## 9. Diff Esperado (Resumen)
- **`ui/main_menu.gd`:**
  - Constantes de tiempos de intro (`STARTUP_INTRO_Z_INDEX = 95`, `STARTUP_INTRO_VEIL_SEC = 0.25`, `STARTUP_INTRO_WAVE_SEC = 0.45`, `STARTUP_INTRO_TOTAL_SEC = 0.95`).
  - Bandera estática `_has_played_startup_intro: bool = false` + `reset_startup_intro_for_tests()` + `has_played_startup_intro()`.
  - Estado y nodos temporales de intro (`_is_playing_startup_intro`, `_intro_overlay`, `_intro_veil_rect`, `_intro_wave_fx`, `_intro_tween`, `_intro_wave_progress`, `_intro_wave_center`, `_tabs_row`).
  - Métodos `_start_startup_intro()`, `_set_intro_wave_progress()`, `_draw_intro_wave()`, `_finish_startup_intro()`, `is_playing_startup_intro()` y guards de interacción durante la intro.

---

## 10. Procedimiento de Reversión
```powershell
git revert <commit_hash_fase_5>
```
O restaurar al commit de Fase 4 (`d22bf2a`):
```powershell
git checkout d22bf2a -- ui/main_menu.gd
Remove-Item "specs/14_startup_intro_animation.md"
```
