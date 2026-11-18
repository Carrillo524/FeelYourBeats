# 02 — Implementación de Contratos de Datos del Chart (`core/chart/`)

Este documento especifica las firmas e invariantes implementadas en los 3 recursos de datos congelados dentro de `core/chart/`, cumpliendo con `AGENTS.md` (tipado estático estricto en GDScript para Godot 4.7.2) y `specs/00_architecture_and_contracts.md`.

---

## 1. `NoteData` (`core/chart/note_data.gd`)

- **Herencia:** `class_name NoteData extends Resource`
- **Constantes:**
  - `const MIN_LANE: int = 0`
  - `const MAX_LANE: int = 3`
- **Propiedades Exportadas:**
  - `@export var time_sec: float = 0.0`
  - `@export var lane: int = 0`
  - `@export var duration_sec: float = 0.0`
  - `@export var strength: float = 1.0`
- **Firmas de Métodos:**
  - `func _init(p_time_sec: float = 0.0, p_lane: int = 0, p_duration_sec: float = 0.0, p_strength: float = 1.0) -> void`
  - `func is_hold() -> bool` — Devuelve `true` si `duration_sec > 0.0`, `false` para notas simples (*tap*).

---

## 2. `IntensityBlock` (`core/chart/intensity_block.gd`)

- **Herencia:** `class_name IntensityBlock extends Resource`
- **Constantes:**
  - `const MIN_TIER: int = 0`
  - `const MAX_TIER: int = 3`
- **Propiedades Exportadas:**
  - `@export var start_sec: float = 0.0`
  - `@export var end_sec: float = 0.0`
  - `@export var energy: float = 0.0`
  - `@export var tier: int = 0`
- **Firmas de Métodos:**
  - `func _init(p_start_sec: float = 0.0, p_end_sec: float = 0.0, p_energy: float = 0.0, p_tier: int = 0) -> void`

---

## 3. `ChartData` (`core/chart/chart_data.gd`)

- **Herencia:** `class_name ChartData extends Resource`
- **Propiedades Exportadas:**
  - `@export var song_id: String = ""`
  - `@export var title: String = ""`
  - `@export var audio_path: String = ""`
  - `@export var duration_sec: float = 0.0`
  - `@export var bpm_estimate: float = 120.0`
  - `@export var offset_sec: float = 0.0`
  - `@export var notes: Array[NoteData] = []`
  - `@export var intensity_blocks: Array[IntensityBlock] = []`
- **Firmas de Métodos:**
  - `func _init(p_song_id: String = "", p_title: String = "", p_audio_path: String = "", p_duration_sec: float = 0.0, p_bpm_estimate: float = 120.0, p_offset_sec: float = 0.0, p_notes: Array[NoteData] = [], p_intensity_blocks: Array[IntensityBlock] = []) -> void`
  - `func validate() -> Dictionary`
    - Verifica:
      1. **Rangos válidos:** `lane` en `0..3`, `tier` en `0..3`, `strength` y `energy` en `0.0..1.0`, tiempos no negativos y `end_sec > start_sec`.
      2. **Orden cronológico ascendente:** `notes[i].time_sec <= notes[i + 1].time_sec` e `intensity_blocks[i].end_sec <= intensity_blocks[i + 1].start_sec`.
      3. **No solapamiento por carril:** Ninguna nota en un mismo `lane` inicia antes de que finalice `time_sec + duration_sec` de la nota anterior en ese mismo carril (ni en el mismo timestamp exacto en el mismo carril).
    - **Retorno:** `{"valid": bool, "errors": Array[String]}`.
