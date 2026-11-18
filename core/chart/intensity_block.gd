class_name IntensityBlock
extends Resource

const MIN_TIER: int = 0
const MAX_TIER: int = 3

@export var start_sec: float = 0.0
@export var end_sec: float = 0.0
@export var energy: float = 0.0
@export var tier: int = 0


func _init(
	p_start_sec: float = 0.0,
	p_end_sec: float = 0.0,
	p_energy: float = 0.0,
	p_tier: int = 0
) -> void:
	start_sec = p_start_sec
	end_sec = p_end_sec
	energy = p_energy
	tier = p_tier
