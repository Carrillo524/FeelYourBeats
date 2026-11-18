# AGENTS.md — Reglas Rectoras del Proyecto FeelYourBeats (FyB)

Este archivo define las reglas arquitectónicas y técnicas **obligatorias** para cualquier agente o desarrollador que trabaje en **FeelYourBeats (FyB)**. Ninguna tarea futura puede violar estas directrices.

---

## 1. Motor y Lenguaje
- **Motor:** Godot `4.7.2` Standard (`config_version=5`, renderizador `mobile`).
- **Lenguaje:** GDScript con **tipado estático estricto obligatorio** en todo el código:
  - Todas las variables locales, propiedades de clase y constantes deben declarar su tipo explícitamente (`var speed: float = 0.0`).
  - Todos los parámetros de funciones y métodos deben estar tipados.
  - Todas las funciones y métodos deben declarar su tipo de retorno explícitamente (`-> void`, `-> float`, `-> Array[NoteData]`, etc.).
  - Prohibido el uso de tipos implícitos o variantes sin tipar salvo cuando la API nativa de Godot lo exija estrictamente.

---

## 2. Target y Entrada
- **Plataforma Principal:** Android móvil vertical (`viewport_width=1080`, `viewport_height=1920`, orientación `portrait`, `stretch/mode="canvas_items"`, `stretch/aspect="keep_width"`, `edge_to_edge=true`).
- **Ventana de Vista Previa en Escritorio (PC):** `window/size/window_width_override=450` y `window/size/window_height_override=800` en `project.godot` para que al ejecutar en monitores horizontales (`F5`) la ventana quepa completa manteniendo la proporción 9:16 sobre el espacio virtual `1080x1920`, sin afectar la resolución nativa en Android.
- **Entrada Multitáctil (Android):** Soporte completo para múltiples toques simultáneos mediante `InputEventScreenTouch` (rastreando el índice de dedo `index` por carril).
- **Entrada de Teclado (Pruebas en PC):** Soporte simultáneo para las teclas `D`, `F`, `J`, `K` mapeadas directamente a los 4 carriles (`0`, `1`, `2`, `3`).

---

## 3. UI, Layout Responsivo y Pantallas Curvas
- **Espacio Base Dinámico (`keep_width`):** La resolución `1080x1920` es únicamente el espacio base de diseño con `keep_width`; el alto virtual del viewport crecerá dinámicamente en pantallas alargadas (p. ej. 20:9 / 1.5K) o se reducirá en pantallas más cuadradas/tablets.
- **Separación Full-Bleed vs. Zona Táctil Segura (Soporte Pantallas Curvas tipo Moto Edge):**
  - Únicamente el fondo y los shaders de VFX deben cubrir el **100% del viewport** (`PRESET_FULL_RECT`) para aprovechar `edge_to_edge=true` y evitar bordes o franjas negras.
  - El contenedor de los 4 carriles y sus zonas táctiles (`InputEventScreenTouch`) debe ocupar el 100% del alto, pero **centrarse horizontalmente** dejando un margen lateral de seguridad configurable (`lateral_margin_ratio`, por defecto `0.06` por cada borde, combinado con el `safe_area` horizontal) para evitar toques fantasma con la palma en bordes curvos y conflictos con el gesto *Atrás* del sistema Android.
- **Prohibido Usar Coordenadas `Y` Fijas en Píxeles:**
  - La línea de juicio (`hit_line_y`) debe calcularse siempre de forma proporcional al alto actual del viewport (`get_viewport_rect().size.y`).
  - Los controles superiores del HUD (pausa, score, indicadores) deben respetar `DisplayServer.get_display_safe_area()` para esquivar la cámara frontal (*punch-hole* / *notch*) y bordes redondeados del dispositivo.

---

## 4. Arquitectura por Capas Desacoplada
- El sistema se divide estrictamente en las capas definidas en `specs/`:
  - `core/audio/` y `core/chart/`
  - `gameplay/`
  - `vfx/` y `ui/`
  - `platform/`
- La comunicación entre capas se realiza **exclusivamente mediante señales** y contratos de datos tipados.
- **Prohibición estricta:** Está terminantemente prohibido mezclar lógica de análisis de audio, FFT o DSP dentro de nodos visuales, controladores de UI o shaders. Los nodos de `vfx/` y `ui/` solo consumen señales emitidas por las capas de dominio.

---

## 5. Sincronización Determinística con Reloj Maestro DSP
- **Prohibición estricta:** Está prohibido mover notas acumulando tiempo o desplazamientos con `_process(delta)` (p. ej. `position.y += speed * delta`).
- La posición vertical `Y` de toda nota activa debe calcularse en cada frame como una **función pura y determinística** respecto al reloj maestro de audio DSP (`AudioServer.get_time_since_last_mix()` y compensación de `AudioServer.get_output_latency()`) y al `hit_line_y` dinámico actual.

---

## 6. Gestión de Escenas (`.tscn`)
- **Prohibición estricta:** Está prohibido crear o editar archivos `.tscn` manualmente como texto plano.
- La construcción de escenas y elementos visuales dinámicos debe realizarse **por código en GDScript** o utilizando las **herramientas del servidor MCP de Godot** (`create_scene`, `add_node`, `save_scene`, `load_sprite`, `update_project_uids`).
