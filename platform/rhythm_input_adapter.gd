class_name RhythmInputAdapter
extends Node

signal lane_input_pressed(lane: int, dsp_time_sec: float)
signal lane_input_released(lane: int, dsp_time_sec: float)

const INVALID_LANE: int = -1
const LANE_0: int = 0
const LANE_1: int = 1
const LANE_2: int = 2
const LANE_3: int = 3

@export var dsp_clock: DSPClock = null
@export var screen_safe_adapter: ScreenSafeAdapter = null

var _active_touches: Dictionary = {}
var _warned_missing_clock: bool = false


func _input(p_event: InputEvent) -> void:
	process_input_event(p_event)


func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset_input_state()


func process_input_event(p_event: InputEvent) -> void:
	if p_event == null:
		return

	if p_event is InputEventScreenTouch:
		_handle_screen_touch(p_event as InputEventScreenTouch)
	elif p_event is InputEventKey:
		_handle_key_input(p_event as InputEventKey)


func reset_input_state() -> void:
	if _active_touches.is_empty():
		return

	var timestamp_sec: float = _read_dsp_time_sec()
	var touch_indices: Array = _active_touches.keys()
	var touch_count: int = touch_indices.size()
	for i: int in range(touch_count):
		var touch_index: int = touch_indices[i] as int
		var registered_lane: int = _active_touches[touch_index] as int
		lane_input_released.emit(registered_lane, timestamp_sec)

	_active_touches.clear()


func _handle_screen_touch(p_touch_event: InputEventScreenTouch) -> void:
	var touch_index: int = p_touch_event.index
	var timestamp_sec: float = _read_dsp_time_sec()

	if p_touch_event.pressed:
		var viewport_pos: Vector2 = p_touch_event.position
		var lane: int = _resolve_touch_lane(viewport_pos)
		if lane == INVALID_LANE:
			return

		if _active_touches.has(touch_index):
			var previous_lane: int = _active_touches[touch_index] as int
			if previous_lane != lane:
				lane_input_released.emit(previous_lane, timestamp_sec)

		_active_touches[touch_index] = lane
		lane_input_pressed.emit(lane, timestamp_sec)
	else:
		if not _active_touches.has(touch_index):
			return

		var registered_lane: int = _active_touches[touch_index] as int
		_active_touches.erase(touch_index)
		lane_input_released.emit(registered_lane, timestamp_sec)


func _handle_key_input(p_key_event: InputEventKey) -> void:
	if p_key_event.echo:
		return

	var lane: int = _map_key_to_lane(p_key_event)
	if lane == INVALID_LANE:
		return

	var timestamp_sec: float = _read_dsp_time_sec()
	if p_key_event.pressed:
		lane_input_pressed.emit(lane, timestamp_sec)
	else:
		lane_input_released.emit(lane, timestamp_sec)


func _resolve_touch_lane(p_viewport_pos: Vector2) -> int:
	if screen_safe_adapter == null:
		return INVALID_LANE

	var play_rect: Rect2 = screen_safe_adapter.get_play_rect()
	if p_viewport_pos.y < play_rect.position.y or p_viewport_pos.y > play_rect.end.y:
		return INVALID_LANE

	return screen_safe_adapter.get_lane_at_x(p_viewport_pos.x)


func _map_key_to_lane(p_key_event: InputEventKey) -> int:
	var code: Key = p_key_event.keycode if p_key_event.keycode != KEY_NONE else p_key_event.physical_keycode
	match code:
		KEY_D:
			return LANE_0
		KEY_F:
			return LANE_1
		KEY_J:
			return LANE_2
		KEY_K:
			return LANE_3
		_:
			return INVALID_LANE


func _read_dsp_time_sec() -> float:
	if dsp_clock != null:
		return dsp_clock.get_current_dsp_time()

	if not _warned_missing_clock:
		_warned_missing_clock = true
		push_warning("RhythmInputAdapter: dsp_clock is not assigned; defaulting input timestamp to 0.0.")
	return 0.0
