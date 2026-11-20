# 10 — Exportación Android 1.5K (`20:9`), Permisos en Tiempo de Ejecución y Checklist de APK

Este documento especifica el empaquetado final de **FeelYourBeats (FyB)** para **Android móvil vertical 1.5K (`20:9`)** en **Godot 4.7.2 Standard** (`config_version=5`, renderizador `mobile`), siguiendo las reglas rectoras de `AGENTS.md`.

---

## 1. Configuración de Pantalla y Preset de Exportación (`project.godot` y `export_presets.cfg`)

### 1.1. Parámetros de Proyecto (`project.godot`)
- **Escena principal:** `application/run/main_scene="res://ui/main_menu.tscn"`
- **Resolución base virtual y escalado:** `viewport_width=1080`, `viewport_height=1920`, `stretch/mode="canvas_items"`, `stretch/aspect="keep_width"` (el alto virtual se expande dinámicamente en pantallas `20:9` / `1.5K` como Moto Edge sin franjas negras).
- **Orientación y modo inmersivo:** `window/handheld/orientation=1` (`portrait`) y `window/size/edge_to_edge=true`.
- **Vista previa en escritorio:** `window_width_override=450` y `window_height_override=800` (solo afecta pruebas locales en PC; Android despliega a pantalla completa nativa).
- **Renderizador:** `renderer/rendering_method="mobile"`.

### 1.2. Preset `"Android"` (`export_presets.cfg`)
- **Identificador de paquete:** `com.feelyourbeats.game` (`FeelYourBeats`, versión `1.0.0`, `code=1`).
- **Formato y arquitectura:** APK estándar (`gradle_build/export_format=0`) compilado para dispositivos modernos de 64 bits (`architectures/arm64-v8a=true`).
- **Ruta de salida:** `builds/FeelYourBeats.apk` (excluido de Git mediante `.gitignore` junto con `export/` y `*.apk`, preservando siempre todos los archivos `.import` y `.uid`).
- **Bordes curvos y áreas seguras:** `screen/immersive_mode=true` y `screen/edge_to_edge=true`, coordinados con `ScreenSafeAdapter` (`lateral_margin_ratio=0.06` + `DisplayServer.get_display_safe_area()`).
- **Firma de pruebas:** firma debug estándar sin credenciales ni contraseñas privadas quemadas en `export_presets.cfg`.
- **Permisos declarados en manifiesto:**
  - `permissions/read_media_audio=true` (`android.permission.READ_MEDIA_AUDIO`, Android 13+ / API 33+)
  - `permissions/read_external_storage=true` (`android.permission.READ_EXTERNAL_STORAGE`, Android <= 12 / API <= 32)

---

## 2. Permisos de Audio en Tiempo de Ejecución (`ui/main_menu.gd`)

Al pulsar **`IMPORTAR CANCIÓN DEL DISPOSITIVO`** en la pestaña `IMPORTAR`:
1. **Escritorio (`Windows` / `Linux` / `macOS`):**
   - Abre directamente `AudioFileDialog` (`FileDialog.ACCESS_FILESYSTEM`, `use_native_dialog = true`, filtros `*.mp3, *.ogg, *.wav`) sin bloqueos por permisos móviles.
2. **Android (`OS.get_name() == "Android"`):**
   - Consulta `OS.get_granted_permissions()` y verifica `has_android_audio_permission(...)` para `android.permission.READ_MEDIA_AUDIO` o `android.permission.READ_EXTERNAL_STORAGE`.
   - Si ya cuenta con permiso: posiciona `current_dir` en `OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)` (si existe) y abre el selector nativo de archivos (`ACCESS_FILESYSTEM`, `use_native_dialog = true`).
   - Si aún no está concedido: muestra `"Solicitando permiso de acceso a audio..."` en `ImportStatusLabel`, llama a `OS.request_permissions()` y escucha la señal `SceneTree.on_request_permissions_result(permission, granted)`:
     - **Concedido:** limpia el aviso y abre el selector de archivos automáticamente.
     - **Denegado:** muestra un mensaje claro en pantalla (`"Permiso de audio denegado. Habilita el acceso a música y audio en los Ajustes de Android para importar canciones."`) sin colgar ni cerrar la aplicación.

---

## 3. Checklist de Verificación Pre-Lanzamiento y APK

### 3.1. Validación Automatizada (CI / Local Headless)
- [x] `--headless --quit --check-only` con **0 errores y 0 advertencias** en los 19 scripts `.gd` del proyecto (`core/`, `gameplay/`, `platform/`, `vfx/`, `ui/`).
- [x] Prueba headless E2E verificando arranque de `MainMenu`, permisos de importación Android/PC, gesto Atrás (`NOTIFICATION_WM_GO_BACK_REQUEST`), `GameSession`, `HitJudge` (rangos `D..SSS+`, guardia `0.0%` en pistas vacías, medidor de riesgo `EASY`/`NORMAL`/`HARD` y `danger_overflowed`), `LaneField`, `ReactiveBackground`, `SafeHud` (`SCORE` sin recorte y barra de riesgo bajo `PAUSA`) y validez de `export_presets.cfg`.
- [x] Todos los assets incluidos (`assets/fonts/`, `assets/sfx/`, `assets/bgm/`, `assets/songs/`) con sus archivos `.import` y `.uid` íntegros en el repositorio.

### 3.2. Generación y Prueba en Dispositivo Físico Android (`20:9` / 1.5K)
1. Abrir el proyecto en **Godot 4.7.2 Standard** → **Proyecto → Exportar... → Android → Exportar Proyecto** → guardar en `builds/FeelYourBeats.apk` (requiere Android SDK + plantillas de exportación de Godot 4.7.2 instaladas).
2. Instalar el APK en el dispositivo (`adb install -r builds/FeelYourBeats.apk`).
3. Verificar en pantalla real (`20:9` / bordes curvos):
   - Fondo `ReactiveBackground` cubre 100 % del viewport (`edge_to_edge=true`) sin franjas negras; onda neón perimetral inactiva en `MainMenu` y suave/sutil en `GameSession`.
   - `MainMenu`: portada centrada, lámina translúcida unificada, rangos neón difuminados, modal de canción con sonido de casete sincronizado de `2.5 s` y gesto Atrás mostrando `"¿SALIR DE FEEL YOUR BEATS?"`.
   - Pestaña `IMPORTAR`: solicitud de permiso de audio en tiempo de ejecución, selección de `.mp3`/`.ogg`/`.wav` desde el dispositivo y mensaje limpio si se deniega.
   - `GameSession`: multitáctil simultáneo en los 4 carriles con margen curvo seguro, `SCORE` completo sin recortar a la izquierda, `PAUSA` y barra neón de riesgo alineados a la derecha, menú de Pausa con 3 botones (`REANUDAR`, `REINICIAR`, `MENÚ PRINCIPAL`) y pantalla de Resultados / Pista Fallida funcional.
