class_name NoteData
extends Resource

const MIN_LANE: int = 0
const MAX_LANE: int = 3

@export var time_sec: float = 0.0
@export var lane: int = 0
@export var duration_sec: float = 0.0
@export var strength: float = 1.0


func _init(
	p_time_sec: float = 0.0,
	p_lane: int = 0,
	p_duration_sec: float = 0.0,
	p_strength: float = 1.0
) -> void:
	time_sec = p_time_sec
	lane = p_lane
	duration_sec = p_duration_sec
	strength = p_strength


func is_hold() -> bool:
	return duration_sec > 0.0
