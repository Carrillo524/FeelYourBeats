# Spec 12 — Fase 3: Estado de Carga No Bloqueante al Procesar Canciones y Transición de Audio

## 1. Nombre y Objetivo
- **Nombre:** Estado de Carga No Bloqueante al Procesar Canciones y Transición Suave de BGM a Cassette (`Fase 3`).
- **Objetivo:** Eliminar el congelamiento del hilo principal al pulsar **Jugar** en canciones nuevas o importadas trasladando el análisis de audio y la generación del chart a un hilo secundario (`WorkerThreadPool`), mostrando una interfaz neón de carga fluida con progreso real, manteniendo vivo el BGM del menú durante todo el procesamiento y aplicando un *fade-out* breve del BGM justo antes de reproducir el efecto de cassette y cambiar a `GameSession`.

---

## 2. Problema que Resuelve
Tras inspeccionar `ui/main_menu.gd`, `ui/menu_bgm_player.gd`, `ui/ui_sfx_player.gd`, `core/audio/audio_analyzer.gd`, `core/chart/auto_chart_generator.gd` y `core/chart/chart_cache_repository.gd`:
1. **Congelamiento de UI al analizar:** `_on_play_button_pressed()` invoca `prepare_session_launch_payload()` de forma síncrona sobre el hilo principal, bloqueando `_process()` durante todo `AudioAnalyzer.analyze_audio_stream()` y `AutoChartGenerator.generate_from_analysis()`.
2. **Silencio abrupto del BGM antes de tiempo:** `_on_play_button_pressed()` llama inmediatamente a `menu_bgm_player.stop_bgm()` al pulsar **Jugar**, cortando la música en seco durante segundos de espera y dejando el menú en silencio si el archivo falla.
3. **Ausencia de feedback visual de progreso animado:** Solo se cambiaba el texto de `_status_label` sin un overlay de carga con indicador animado ni barra de progreso real por etapa.
4. **Sin transición gradual BGM -> Cassette:** `MenuBgmPlayer` carece de `fade_out_and_stop()`, por lo que el paso del BGM al sonido de inserción del cassette era abrupto.

---

## 3. Alcance Exacto y Dependencias
- **Rama de trabajo:** `main`
- **Dependencias con fases anteriores:**
  - **Fase 1 (`a3cf69d`):** Mantiene intactos `config/quit_on_go_back=false`, `config/auto_accept_quit=false`, `v1.0.4` (`version/code=6`) y el bloqueo del gesto Atrás durante la carga.
  - **Fase 2 (`caf695e`):** Mantiene intacto el scroll táctil de `CANCIONES`, `IMPORTAR`, `AJUSTES` y `SongModalScroll`, bloqueando el tracking táctil mientras el overlay de carga está visible.
- **Archivos inspeccionados (lectura):**
  - `AGENTS.md`
  - `specs/09_main_menu_and_song_selector.md`
  - `specs/11_menu_touch_scroll.md`
  - `ui/main_menu.gd`
  - `ui/menu_bgm_player.gd`
  - `ui/ui_sfx_player.gd`
  - `core/audio/audio_analyzer.gd`
  - `core/chart/auto_chart_generator.gd`
  - `core/chart/chart_cache_repository.gd`
- **Archivos a crear/modificar en Fase 3:**
  1. `specs/12_song_processing_loading_state.md` (esta especificación)
  2. `core/audio/audio_analyzer.gd` (método puro estático thread-safe `analyze_audio_stream_data()` con reporte de progreso opcional)
  3. `ui/menu_bgm_player.gd` (`fade_out_and_stop()`, `resume_bgm()`, `get_volume_db()` con limpieza segura de `Tween`)
  4. `ui/main_menu.gd` (overlay neón de carga por código, bandera `_is_processing_song`, ejecución asíncrona con `WorkerThreadPool`, reporte vía `call_deferred`, transición BGM -> cassette -> `GameSession` y recuperación ante error)
- **Exclusiones explícitas:**
  - **Cero modificaciones a archivos `.tscn`** (`ui/main_menu.tscn`, `ui/game_session.tscn`, etc.), cumpliendo `AGENTS.md` (§6).
  - No se modifica lógica de DSP de `gameplay/` ni se viola la separación de capas de `AGENTS.md` (§4): `AudioAnalyzer` permanece en `core/audio/` sin depender de nodos UI.

---

## 4. Diseño Técnico (Tipado Estático Estricto, solo `.gd`)

### 4.1. Análisis Puro Thread-Safe con Progreso Real (`core/audio/audio_analyzer.gd`)
- Se extrae lógica pura de análisis en funciones estáticas que **no acceden al `SceneTree` ni a propiedades de nodo**:
  - `static func analyze_audio_stream_data(p_stream: AudioStream, p_mix_rate: float, p_bass_max_hz: float = 200.0, p_mid_max_hz: float = 2200.0, p_hop_sec: float = DEFAULT_HOP_SEC, p_progress_cb: Callable = Callable()) -> Dictionary`
  - `static func analyze_wav_stream_data(p_wav: AudioStreamWAV, p_bass_max_hz: float = 200.0, p_mid_max_hz: float = 2200.0, p_hop_sec: float = DEFAULT_HOP_SEC, p_progress_cb: Callable = Callable()) -> Dictionary`
- `analyze_audio_stream()` y `analyze_wav_stream()` existentes delegan directamente a estas funciones estáticas (preservando 100 % de compatibilidad con `GameSession` y tests previos).
- Durante el bucle de mezcla/decodificación de hops, si `p_progress_cb.is_valid()`, reporta progreso real `0.0 .. 1.0` en incrementos discretos (`>= 0.03` o finalización) para evitar saturar la cola diferida.

### 4.2. Fade-Out Suave y Reanudación en `MenuBgmPlayer` (`ui/menu_bgm_player.gd`)
- Constantes: `DEFAULT_FADE_OUT_SEC: float = 0.35`, `FADE_OUT_SILENCE_DB: float = -42.0`.
- Señal: `signal bgm_fade_out_finished()`.
- `func fade_out_and_stop(p_duration_sec: float = DEFAULT_FADE_OUT_SEC) -> void`:
  - Si `_player == null` o no está reproduciendo, marca `_is_stopped_manually = true`, asegura `volume_db = 0.0`, emite `bgm_fade_out_finished` y retorna inmediatamente.
  - En caso activo, crea un `Tween` que atenúa `_player.volume_db` hasta `FADE_OUT_SILENCE_DB` en `p_duration_sec` (`TRANS_SINE`, `EASE_IN_OUT`), detiene el reproductor, restaura `_player.volume_db = 0.0` y emite `bgm_fade_out_finished`.
- `func resume_bgm() -> void`: si `is_bgm_enabled` y hay pistas, cancela cualquier fade en curso, restablece `volume_db = 0.0` y reanuda si estaba detenido.
- `stop_bgm()` y `select_track()` cancelan cualquier `_fade_tween` pendiente y restablecen `_player.volume_db = 0.0`.

### 4.3. Overlay Neón de Carga y Orquestación Asíncrona (`ui/main_menu.gd`)
- **Estado y Bloqueo contra Doble Pulsación:**
  - `var _is_processing_song: bool = false` (getter público `is_processing_song() -> bool`).
  - `var _active_worker_task_id: int = -1` y `var _active_processing_job_id: int = 0`.
  - Al pulsar **Jugar** (`_on_play_button_pressed()`): si `_is_launching or _is_processing_song`, retorna inmediatamente sin lanzar un segundo trabajo. Activa `_is_launching = true`, `_is_processing_song = true`, deshabilita `_play_button` y `_modal_close_button`, y bloquea `handle_back_request()` / cierre del modal / scroll táctil mientras dura el procesamiento.
- **Continuidad del BGM durante la Carga:**
  - **No** se invoca `menu_bgm_player.stop_bgm()` ni `audio_analyzer.set_live_monitoring(false)` al iniciar el procesamiento; el BGM y el fondo reactivo continúan sonando y animándose con normalidad mientras el hilo secundario trabaja.
- **Overlay Visual de Carga (construido en GDScript en `_build_loading_overlay_ui()`):**
  - `_loading_overlay: ColorRect` a pantalla completa (`z_index = 90`, `mouse_filter = MOUSE_FILTER_STOP`, fondo oscuro translúcido `Color(0.02, 0.03, 0.08, 0.82)`).
  - `_loading_panel: PanelContainer` centrado con estilo neón coherente (`_style_modal_panel`).
  - `_loading_spinner: Control` con `draw` conectado a `_draw_loading_spinner()` (arcos cian/violeta giratorios y núcleo pulsante actualizados cada frame en `_process(dt)`).
  - `_loading_title_label: Label` (`"PROCESANDO CANCIÓN..."` para análisis nuevo / `"CARGANDO..."` para caché o demo).
  - `_loading_stage_label: Label` (etapa actual: `"Leyendo archivo de audio..."`, `"Analizando espectro y ritmo..."`, `"Generando notas..."`, `"Cargando pista en caché..."`).
  - Barra de progreso neón (`_loading_progress_track` + `_loading_progress_fill` + `_loading_percent_label`):
    - En modo determinado (análisis con progreso `0.0..1.0`): interpola suavemente el ancho y muestra porcentaje (`0%..100%`).
    - En modo indeterminado (lectura inicial / demo / caché breve): desplaza una franja brillante fluida en bucle en `_process(dt)`.
- **Procesamiento en `WorkerThreadPool` (sin tocar `SceneTree` desde el hilo secundario):**
  - Antes de lanzar la tarea, el hilo principal captura en un `Dictionary` de datos puros: `job_id`, `is_demo`, `audio_path`, `title`, `difficulty`, `note_type_mode`, `speed_multiplier`, `mix_rate`, `bass_max_hz`, `mid_max_hz`, `cache_key`, `has_cache`, y (solo si `audio_path.begins_with("res://")`) el `AudioStream` precargado vía `ResourceLoader`.
  - Si el chart ya está en caché (`has_cache == true`) o es demo, carga rápidamente sin congelar la UI mostrando brevemente `"CARGANDO..."` con BGM activo.
  - Si requiere decodificación/análisis externo o generación de chart, se encola en `WorkerThreadPool.add_task(_run_song_processing_worker.bind(job_cfg), true, "FyB_SongProcessing")`:
    - El hilo secundario carga bytes (`FileAccess.get_file_as_bytes` -> `AudioStream`), ejecuta `AudioAnalyzer.analyze_audio_stream_data(...)` reportando progreso vía `call_deferred(&"_on_song_processing_progress", job_id, pct, stage)` y genera el `ChartData` con `AutoChartGenerator.generate_from_analysis(...)` (todo sobre datos puros y `RefCounted`/`Resource`, cero acceso a `Node`/`SceneTree`).
    - Al concluir (éxito o error), notifica al hilo principal vía `call_deferred(&"_on_song_processing_completed", job_id, result_payload)`.
  - En `_on_song_processing_completed()` (hilo principal):
    - Cosecha limpiamente la tarea con `WorkerThreadPool.wait_for_task_completion(_active_worker_task_id)` y limpia `_active_worker_task_id = -1`. (También protegido en `_exit_tree()`).
    - Si hubo éxito y el chart no venía de caché, guarda el `.tres` en `_chart_cache_repo.save_cached_chart(cache_key, chart)`.
- **Secuencia Exacta al Finalizar con Éxito:**
  1. `_is_processing_song = false`, oculta `_loading_overlay` (`_hide_loading_overlay()`).
  2. Registra `"analysis_done"`, ejecuta *fade-out* suave del BGM (`menu_bgm_player.fade_out_and_stop(BGM_FADEOUT_DURATION_SEC)` — `0.35 s`), aguarda su finalización y desactiva `audio_analyzer.set_live_monitoring(false)` (registrando `"bgm_fade_started"` y `"bgm_stopped"`).
  3. Reproduce `ui_sfx_player.play_cassette_insert()` (`"cassette_started"`) junto con el fundido a negro de `2.5 s` (`"fade_started"`) y cambia a `res://ui/game_session.tscn`.
- **Recuperación Limpia ante Error:**
  1. `_is_processing_song = false`, `_is_launching = false`, oculta `_loading_overlay`.
  2. Restaura `_transition_fade_rect` (`alpha = 0.0`, `MOUSE_FILTER_IGNORE`), rehabilita `_play_button` y `_modal_close_button`.
  3. Garantiza que el BGM del menú continúe activo (`resume_bgm()` si el usuario lo tiene habilitado) y sincroniza `_sync_live_audio_monitoring()`.
  4. Muestra el mensaje de error comprensible en `_status_label` sin cerrar ni bloquear la app.

---

## 5. Casos Límite Cubiertos
| Caso Límite | Comportamiento Esperado |
| :--- | :--- |
| **Canción nueva sin caché** | Muestra `"PROCESANDO CANCIÓN..."` con spinner giratorio y barra de progreso real (`15% -> 80% -> 95% -> 100%`) ejecutándose en `WorkerThreadPool` mientras el BGM sigue sonando; luego oculta overlay -> fade-out BGM -> cassette -> `GameSession`. |
| **Canción ya cacheada / Demo** | Muestra `"CARGANDO..."` brevemente con BGM activo, sin re-analizar audio; oculta overlay -> fade-out BGM -> cassette -> `GameSession`. |
| **Error de lectura o decodificación** | Archivo inexistente, vacío o corrupto: oculta overlay, rehabilita **Jugar** y **CERRAR**, mantiene/reanuda BGM del menú y muestra mensaje claro en `_status_label`. |
| **Doble pulsación rápida en Jugar** | El segundo clic/toque es ignorado de inmediato (`_is_launching or _is_processing_song`), sin crear dos tareas en `WorkerThreadPool` ni duplicar el sonido de cassette. |
| **Gesto Atrás durante la carga** | `handle_back_request()` ignora el gesto mientras `_is_processing_song` o `_is_launching` estén activos, evitando cerrar el modal o salir a mitad del procesamiento. |
| **Salida forzada del árbol (`_exit_tree`)** | Si existe `_active_worker_task_id != -1`, espera limpiamente `WorkerThreadPool.wait_for_task_completion()` antes de liberar memoria. |

---

## 6. Requisitos de Fluidez de UI
- El hilo principal ejecuta únicamente la animación del spinner, el lerp de la barra de progreso y la reactividad del fondo en `_process(dt)` (`< 0.5 ms/frame`).
- Ningún análisis de muestras ni autocorrelación de BPM ocurre en el hilo principal para pistas no cacheadas.

---

## 7. Criterios de Aceptación Verificables
- [ ] Al pulsar **Jugar**, `_play_button.disabled == true` y `_is_processing_song == true` de inmediato; una segunda pulsación rápida no inicia una segunda tarea ni duplica lanzamientos.
- [ ] Durante todo `_is_processing_song == true`, `menu_bgm_player` permanece reproduciendo (`is_playing() == true` cuando el BGM está habilitado).
- [ ] El overlay de carga neón se muestra durante el procesamiento con spinner animado en `_process` y barra de progreso actualizada por `call_deferred`.
- [ ] Al finalizar con éxito, el orden verificado es: overlay oculto -> fade-out y detención del BGM -> inicio del efecto de cassette -> fundido y cambio a `GameSession`.
- [ ] Ante archivo inválido/corrupto, el overlay se oculta, `_play_button.disabled == false`, `_is_processing_song == false`, el BGM sigue/reanuda activo y `_status_label.text` muestra un mensaje comprensible.
- [ ] `--headless --quit --check-only` sobre `res://core/audio/audio_analyzer.gd`, `res://ui/menu_bgm_player.gd` y `res://ui/main_menu.gd` finaliza con 0 errores y 0 advertencias.
- [ ] `git diff -- "*.tscn"` está completamente vacío.

---

## 8. Plan de Pruebas (Automatizadas y Manuales)

### 8.1. Automatizadas (Headless, eliminando `scratch/` siempre en `finally`)
1. Validación estática:
   ```powershell
   $godot = "C:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
   & $godot --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://core/audio/audio_analyzer.gd"
   & $godot --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://ui/menu_bgm_player.gd"
   & $godot --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://ui/main_menu.gd"
   ```
2. Prueba headless temporal `scratch/verify_phase3_loading_state.gd` (terminando con `quit(0)`):
   - **(a) Doble pulsación rápida y análisis en hilo secundario:** Selecciona una pista real sin caché en un repositorio temporal de caché (`user://verify_phase3_tmp`), invoca `_on_play_button_pressed()` dos veces seguidas -> verifica `_play_button.disabled == true`, `is_processing_song() == true`, overlay visible y que solo se inició 1 trabajo (`_active_processing_job_id == 1`).
   - **(b) Continuidad de BGM y orden de transición:** Mientras `is_processing_song() == true`, verifica que `menu_bgm_player.is_playing() == true` y que `_process()` avanza la animación sin congelarse; al completarse el worker y la transición, verifica la secuencia exacta `["processing_started", "analysis_done", "bgm_fade_started", "bgm_stopped", "cassette_started", "fade_started"]` y que `menu_bgm_player.is_playing() == false` antes del cassette.
   - **(c) Recuperación ante error:** Selecciona una pista con ruta inexistente (`user://verify_phase3_tmp/missing_track.mp3`), pulsa **Jugar** y espera la respuesta -> verifica `is_processing_song() == false`, `_play_button.disabled == false`, overlay oculto, `menu_bgm_player.is_playing() == true` y `not get_status_text().is_empty()`.
   - **(d) Integridad `.tscn` y limpieza:** Verifica `git diff -- "*.tscn"` vacío y elimina `scratch/` y `user://verify_phase3_tmp`.

### 8.2. Pruebas Manuales (Android y PC)
- Seleccionar una canción importada nueva (sin caché) y pulsar **Jugar**: comprobar que el spinner y la barra de progreso se mueven fluidamente mientras la música del menú sigue sonando, que al completar el análisis el BGM baja de volumen suavemente, suena el cassette y arranca la partida.
- Probar con una canción ya cacheada y con un archivo dañado para verificar rapidez y recuperación limpia.

---

## 9. Diff Esperado (Resumen)
- **`core/audio/audio_analyzer.gd`:** Nuevos métodos estáticos `analyze_audio_stream_data()` y `analyze_wav_stream_data()` con callback de progreso opcional (`Callable`), delegando `analyze_audio_stream()` y `analyze_wav_stream()` a ellos.
- **`ui/menu_bgm_player.gd`:** Nuevos métodos `fade_out_and_stop(p_duration_sec: float)`, `resume_bgm()`, `get_volume_db()`, señal `bgm_fade_out_finished` y limpieza segura de `_fade_tween`.
- **`ui/main_menu.gd`:** Overlay neón `_loading_overlay` + spinner dibujado en `_process`, bandera `_is_processing_song`, encolado en `WorkerThreadPool.add_task(...)` con `call_deferred` para progreso y finalización, *fade-out* del BGM antes del cassette, y recuperación completa ante errores.

---

## 10. Procedimiento de Reversión
```powershell
git revert <commit_hash_fase_3>
```
O restaurar al commit de Fase 2 (`caf695e`):
```powershell
git checkout caf695e -- core/audio/audio_analyzer.gd ui/menu_bgm_player.gd ui/main_menu.gd
Remove-Item "specs/12_song_processing_loading_state.md"
```
