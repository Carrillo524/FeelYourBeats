class_name RhythmInputAdapter
extends Node

signal lane_input_pressed(lane: int, dsp_time_sec: float)
signal lane_input_released(lane: int, dsp_time_sec: float)
signal touch_ripple_triggered(p_local_pos: Vector2, p_lane: int)

const INVALID_LANE: int = -1
const LANE_0: int = 0
const LANE_1: int = 1
const LANE_2: int = 2
const LANE_3: int = 3

@export var dsp_clock: DSPClock = null
@export var screen_safe_adapter: ScreenSafeAdapter = null

var _active_touches: Dictionary[int, int] = {}
var _active_keys: Dictionary[int, int] = {}
var _warned_missing_clock: bool = false


func _input(p_event: InputEvent) -> void:
	process_input_event(p_event)


func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_APPLICATION_FOCUS_OUT or p_what == NOTIFICATION_APPLICATION_PAUSED:
		reset_input_state()


func process_input_event(p_event: InputEvent) -> void:
	if p_event == null:
		return

	if p_event is InputEventScreenTouch:
		_handle_screen_touch(p_event as InputEventScreenTouch)
	elif p_event is InputEventKey:
		_handle_key_input(p_event as InputEventKey)


func reset_input_state() -> void:
	if _active_touches.is_empty() and _active_keys.is_empty():
		return

	var timestamp_sec: float = _read_dsp_time_sec()
	var lanes_to_release: Dictionary[int, bool] = {}

	for touch_index: int in _active_touches:
		lanes_to_release[_active_touches[touch_index]] = true

	for key_code: int in _active_keys:
		lanes_to_release[_active_keys[key_code]] = true

	_active_touches.clear()
	_active_keys.clear()

	for lane: int in lanes_to_release:
		lane_input_released.emit(lane, timestamp_sec)


func _is_lane_held_by_any_source(p_lane: int) -> bool:
	for touch_index: int in _active_touches:
		if _active_touches[touch_index] == p_lane:
			return true
	for key_code: int in _active_keys:
		if _active_keys[key_code] == p_lane:
			return true
	return false


func _handle_screen_touch(p_touch_event: InputEventScreenTouch) -> void:
	var touch_index: int = p_touch_event.index
	var timestamp_sec: float = _read_dsp_time_sec()

	if p_touch_event.pressed:
		var viewport_pos: Vector2 = p_touch_event.position
		var lane: int = _resolve_touch_lane(viewport_pos)
		if lane == INVALID_LANE:
			return

		if _active_touches.has(touch_index):
			var previous_lane: int = _active_touches[touch_index]
			if previous_lane != lane:
				_active_touches.erase(touch_index)
				if not _is_lane_held_by_any_source(previous_lane):
					lane_input_released.emit(previous_lane, timestamp_sec)

		_active_touches[touch_index] = lane
		var local_pos: Vector2 = viewport_pos
		if screen_safe_adapter != null:
			var play_rect: Rect2 = screen_safe_adapter.get_play_rect()
			local_pos = viewport_pos - play_rect.position
		touch_ripple_triggered.emit(local_pos, lane)
		lane_input_pressed.emit(lane, timestamp_sec)
	else:
		if not _active_touches.has(touch_index):
			return

		var registered_lane: int = _active_touches[touch_index]
		_active_touches.erase(touch_index)
		if not _is_lane_held_by_any_source(registered_lane):
			lane_input_released.emit(registered_lane, timestamp_sec)


func _handle_key_input(p_key_event: InputEventKey) -> void:
	if p_key_event.echo:
		return

	var code: Key = p_key_event.keycode if p_key_event.keycode != KEY_NONE else p_key_event.physical_keycode
	var lane: int = _map_key_code_to_lane(code)
	if lane == INVALID_LANE:
		return

	var code_int: int = int(code)
	var timestamp_sec: float = _read_dsp_time_sec()
	if p_key_event.pressed:
		if _active_keys.has(code_int):
			return
		_active_keys[code_int] = lane
		lane_input_pressed.emit(lane, timestamp_sec)
	else:
		if not _active_keys.has(code_int):
			return
		var registered_lane: int = _active_keys[code_int]
		_active_keys.erase(code_int)
		if not _is_lane_held_by_any_source(registered_lane):
			lane_input_released.emit(registered_lane, timestamp_sec)


func _resolve_touch_lane(p_viewport_pos: Vector2) -> int:
	if screen_safe_adapter == null:
		return INVALID_LANE

	var play_rect: Rect2 = screen_safe_adapter.get_play_rect()
	if p_viewport_pos.y < play_rect.position.y or p_viewport_pos.y > play_rect.end.y:
		return INVALID_LANE

	return screen_safe_adapter.get_lane_at_x(p_viewport_pos.x)


func _map_key_code_to_lane(p_code: Key) -> int:
	match p_code:
		KEY_D, KEY_LEFT:
			return LANE_0
		KEY_F, KEY_DOWN:
			return LANE_1
		KEY_J, KEY_UP:
			return LANE_2
		KEY_K, KEY_RIGHT:
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
