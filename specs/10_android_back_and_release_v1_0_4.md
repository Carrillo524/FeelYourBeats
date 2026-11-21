# Spec 10 — Fase 1: Configuración de Retroceso en Android y Versionamiento `v1.0.4`

## 1. Objetivo
Evitar el cierre inmediato de **FeelYourBeats (FyB)** al realizar el gesto o pulsar el botón **Atrás** en Android deshabilitando `quit_on_go_back` y `auto_accept_quit` tanto en `project.godot` como en el `SceneTree` en tiempo de ejecución (`MainMenu` y `GameSession`), y publicar el incremento de versión a **`v1.0.4`** con incremento automático `+1` en `version/code` para actualización directa en dispositivo.

---

## 2. Alcance y Rama
- **Rama de trabajo:** `main`
- **Fase cubierta:** Únicamente **Fase 1 (Configuración de Android y versionamiento `v1.0.4`)**.
- **Archivos a crear/modificar:**
  1. `specs/10_android_back_and_release_v1_0_4.md` (este documento de especificación)
  2. `project.godot`
  3. `ui/main_menu.gd`
  4. `gameplay/game_session.gd`
  5. `export_presets.cfg`
- **Exclusión explícita de escenas `.tscn`:**
  - En cumplimiento estricto de `AGENTS.md` (§6), **ningún archivo `.tscn` será creado ni modificado** en esta fase.

---

## 3. Línea Base Leída Antes de Modificar
- `project.godot` (`[application]`):
  - `config/version="1.0.3"`
  - `config/quit_on_go_back`: no declarado (valor por defecto de Godot = `true`, lo que causa cierre automático ante `NOTIFICATION_WM_GO_BACK_REQUEST`).
  - `config/auto_accept_quit`: no declarado (valor por defecto de Godot = `true`).
- `export_presets.cfg` (preset `"Android"`, `[preset.0]` / `[preset.0.options]`):
  - **Valor inicial leído de `version/code`:** `5`
  - **Valor inicial leído de `version/name`:** `"1.0.3"`
  - `export_path`: `"builds/FeelYourBeats_v1.0.3.apk"`
- `ui/main_menu.gd` y `gameplay/game_session.gd`:
  - `_ready()` llamaba únicamente a `tree.set_auto_accept_quit(false)` sin llamar a `tree.set_quit_on_go_back(false)`.

---

## 4. Cambios Esperados
1. **`project.godot` (`[application]`):**
   - `config/version="1.0.4"`
   - `config/auto_accept_quit=false`
   - `config/quit_on_go_back=false`
2. **`ui/main_menu.gd` (`_ready()` y `_notification()`):**
   - Configurar conjuntamente en `_ready()` (tipado estático estricto):
     - `tree.set_quit_on_go_back(false)`
     - `tree.set_auto_accept_quit(false)`
   - Mantener la intercepción de `NOTIFICATION_WM_GO_BACK_REQUEST` (con debounce de `300 ms`) abriendo el modal `"¿SALIR DE FEEL YOUR BEATS?"` sin cerrar el `SceneTree`; solo la confirmación explícita (`SALIR` / `SÍ`) invoca `tree.quit()`, mientras que `CANCELAR` / `NO` o un segundo retroceso posterior ocultan el modal sin salir.
3. **`gameplay/game_session.gd` (`_ready()`):**
   - Configurar conjuntamente en `_ready()` (tipado estático estricto):
     - `tree.set_quit_on_go_back(false)`
     - `tree.set_auto_accept_quit(false)`
4. **`export_presets.cfg` (preset `"Android"`):**
   - `version/code=6` (incremento exacto `+1` sobre el valor inicial `5`).
   - `version/name="1.0.4"`.
   - `export_path="builds/FeelYourBeats_v1.0.4.apk"`.

---

## 5. Criterios de Aceptación
- [ ] `specs/10_android_back_and_release_v1_0_4.md` guardado antes de editar código o configuración.
- [ ] `project.godot` declara `config/quit_on_go_back=false`, `config/auto_accept_quit=false` y `config/version="1.0.4"` bajo `[application]`.
- [ ] `ui/main_menu.gd` y `gameplay/game_session.gd` llaman a `set_quit_on_go_back(false)` y `set_auto_accept_quit(false)` juntos en `_ready()`, cumpliendo tipado estático estricto (`AGENTS.md`).
- [ ] En `MainMenu`, `NOTIFICATION_WM_GO_BACK_REQUEST` abre `"¿SALIR DE FEEL YOUR BEATS?"` sin cerrar la aplicación, un retroceso posterior o cancelar cierra el modal sin salir, y únicamente confirmar salida invoca `get_tree().quit()`.
- [ ] `export_presets.cfg` tiene `version/code=6` (`5 + 1`) y `version/name="1.0.4"`.
- [ ] Ningún archivo `.tscn` presenta cambios en `git diff` / `git status`.
- [ ] `--headless --quit --check-only` sobre `res://ui/main_menu.gd` y `res://gameplay/game_session.gd` finaliza con **0 errores y 0 advertencias**.
- [ ] Prueba headless temporal en `scratch/` valida todas las aserciones con salida `0` y el directorio `scratch/` queda eliminado al concluir.

---

## 6. Comandos de Validación
```powershell
$godot = "C:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://ui/main_menu.gd"
& $godot --headless --quit --check-only --path "c:\GODOT\FeelYourBeats" -s "res://gameplay/game_session.gd"
& $godot --headless --path "c:\GODOT\FeelYourBeats" -s "res://scratch/verify_phase1_v104.gd"
git status -s
git diff -- "*.tscn"
```

---

## 7. Riesgos y Mitigación
- **Riesgo 1: Cierre accidental por Android predictive back si `quit_on_go_back` permanece activo en alguna escena.**
  - *Mitigación:* Se deshabilita de forma global en `project.godot` (`config/quit_on_go_back=false`) y de forma defensiva en `_ready()` de `MainMenu` y `GameSession`.
- **Riesgo 2: Regresión en el incremento de `version/code` impidiendo instalar la actualización encima del APK anterior.**
  - *Mitigación:* Lectura explícita del valor actual (`5`), incremento determinístico a `6` y aserción directa en el test headless.
- **Riesgo 3: Residuos temporales en `scratch/`.**
  - *Mitigación:* Eliminación forzada de `scratch/` garantizada al final del comando de ejecución incluso ante fallo.

---

## 8. Procedimiento de Reversión
En caso de requerir revertir esta fase en `main`:
```powershell
git revert <commit_hash_fase_1>
```
O restaurar los archivos individuales al commit anterior (`e19af65`):
```powershell
git checkout e19af65 -- project.godot export_presets.cfg ui/main_menu.gd gameplay/game_session.gd
Remove-Item "specs/10_android_back_and_release_v1_0_4.md"
```
