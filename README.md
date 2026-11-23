<div align="center">

# FeelYourBeats

**Un sucesor espiritual de código abierto para sentir tu propia música, nota a nota.**

[![Version](https://img.shields.io/badge/release-v1.1.2-00e5ff?style=for-the-badge)](https://github.com/Carrillo524/FeelYourBeats/releases/latest)
[![Engine](https://img.shields.io/badge/Godot-4.x-478cbf?style=for-the-badge&logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Platform](https://img.shields.io/badge/Plataformas-Android%20%7C%20PC-7c4dff?style=for-the-badge)](https://github.com/Carrillo524/FeelYourBeats/releases/latest)
[![Status](https://img.shields.io/badge/Proyecto-Independiente%20%26%20Abierto-00c853?style=for-the-badge)](#)

[**Descargar última versión (Android / PC)**](https://github.com/Carrillo524/FeelYourBeats/releases/latest)

</div>

---

## La historia detrás del proyecto

**FeelYourBeats** es un proyecto independiente que nació de una idea sencilla pero muy personal: **revivir la magia de un clásico juego de ritmo de mi infancia**, de esos que se quedaban grabados en la memoria por lo simple y adictivo que era jugar al compás de tus canciones favoritas.

Con el paso del tiempo ese tipo de experiencias fueron desapareciendo o volviéndose difíciles de encontrar. Por eso decidí construir desde cero un **sucesor espiritual de código abierto**, pensado para que cualquier persona que extrañara esa sensación pueda volver a disfrutarla libremente **importando su propia música**, sin depender de catálogos cerrados ni servidores externos.

---

## Características principales

| Característica | Descripción |
| :--- | :--- |
| **Tu propia música, sin límites** | Importa tus archivos de audio directamente desde el selector de canciones o juega con la pista incluida; los carriles se generan proceduralmente siguiendo el ritmo de cada tema. |
| **4 modos de juego** | Adapta el reto a tu nivel y estilo de partida desde el menú principal. |
| **Fondos reactivos al audio** | 4 escenarios dinámicos (**Clásico**, **Nebulosa**, **Aurora** y **Eclipse**) que pulsan y reaccionan en tiempo real a la energía musical. |
| **Efectos visuales personalizables** | Combina partículas neón (círculos, cuadrados, estelas, destellos y estrellas fugaces), ajusta su densidad e intensidad reactiva o activa el modo seguro para fotosensibilidad. |
| **Multiplataforma y responsivo** | Diseñado para **Android** (orientación vertical y horizontal sin bordes negros) y **PC** (ventana redimensionable y controles de teclado), optimizado para correr con fluidez a **60 y 120 FPS**. |
| **Aviso de actualizaciones integrado** | Campanita de notificaciones en el menú principal conectada a *GitHub Releases* para enterarte de nuevas versiones al instante. |

---

## Controles

* **Android (Táctil):** Toca y mantén pulsado directamente sobre cada uno de los **4 carriles** en la línea de juicio (soporte multitáctil completo).
* **PC (Teclado):** Usa las teclas **`D`**, **`F`**, **`J`**, **`K`** (o las flechas **`←`**, **`↓`**, **`↑`**, **`→`**) para los carriles del 1 al 4.

---

## Descarga e instalación

1. Entra a la sección de [**Releases**](https://github.com/Carrillo524/FeelYourBeats/releases/latest).
2. Descarga el archivo correspondiente a tu dispositivo:
   * **Android:** `FeelYourBeats_v1.1.2.apk` (habilita *Instalar aplicaciones de orígenes desconocidos* si tu teléfono lo solicita).
   * **Windows (PC):** `FeelYourBeats_v1.1.2_Windows.exe` (ejecutable autónomo, no requiere instalación).

---

## Arquitectura del proyecto (Godot 4)

El código está escrito en **GDScript 4 con tipado estático estricto** y organizado por responsabilidades para facilitar su mantenimiento y evolución:

```text
FeelYourBeats/
├── core/        # Reloj de audio, análisis rítmico procedural, estado global y ajustes persistentes
├── gameplay/    # Pista de 4 carriles, generación/vista de notas y evaluación de precisión (HitJudge)
├── platform/    # Adaptadores de entrada (multitáctil móvil y teclado PC) y gestión de archivos
├── ui/          # Menú principal, selector de canciones, HUD seguro, pausa y notas de versión
├── vfx/         # Fondos reactivos al audio, partículas dinámicas y efectos de acierto/juicio
└── specs/       # Especificaciones técnicas del proyecto
```

### Ejecutar desde el código fuente

1. Clona este repositorio:
   ```bash
   git clone [https://github.com/Carrillo524/FeelYourBeats.git](https://github.com/Carrillo524/FeelYourBeats.git)
   ```
2. Abre **Godot Engine 4** (4.3 o superior), pulsa **Importar** y selecciona el archivo `project.godot`.
3. Pulsa **F5** para ejecutar el proyecto directamente en tu equipo.

---

<div align="center">

Hecho de forma independiente con cariño por la música y los juegos de ritmo.

</div>