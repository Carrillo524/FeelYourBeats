class_name NoteView
extends Control

const DEFAULT_HEAD_HEIGHT_PX: float = 36.0
const HORIZONTAL_PADDING_PX: float = 8.0
const HOLD_WIDTH_RATIO: float = 0.56

var note_data: NoteData = null
var lane_width: float = 200.0
var scroll_speed_px_per_sec: float = 1100.0

var _head_rect: ColorRect = null
var _hold_body_rect: ColorRect = null
var _current_tail_height_px: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_visual_nodes()


func _ready() -> void:
	_ensure_visual_nodes()


func setup(p_note: NoteData, p_lane_width: float, p_scroll_speed_px_per_sec: float) -> void:
	_ensure_visual_nodes()
	note_data = p_note
	lane_width = maxf(1.0, p_lane_width)
	scroll_speed_px_per_sec = maxf(1.0, p_scroll_speed_px_per_sec)

	if note_data == null:
		reset_for_pool()
		return

	var visual_width: float = maxf(4.0, lane_width - (HORIZONTAL_PADDING_PX * 2.0))
	size = Vector2(lane_width, DEFAULT_HEAD_HEIGHT_PX)

	_head_rect.position = Vector2(HORIZONTAL_PADDING_PX, -DEFAULT_HEAD_HEIGHT_PX * 0.5)
	_head_rect.size = Vector2(visual_width, DEFAULT_HEAD_HEIGHT_PX)

	if note_data.is_hold():
		var full_tail_height_px: float = maxf(0.0, note_data.duration_sec) * scroll_speed_px_per_sec
		_hold_body_rect.visible = true
		_update_hold_body_geometry(full_tail_height_px)
	else:
		_current_tail_height_px = 0.0
		_hold_body_rect.visible = false
		_hold_body_rect.size = Vector2.ZERO

	visible = true


func update_position(p_dsp_time_sec: float, p_hit_line_y: float, p_is_holding: bool = false) -> void:
	if note_data == null:
		return

	position.x = float(note_data.lane) * lane_width

	if p_is_holding and note_data.is_hold():
		position.y = p_hit_line_y
		var end_time_sec: float = note_data.time_sec + maxf(0.0, note_data.duration_sec)
		var remaining_sec: float = maxf(0.0, end_time_sec - p_dsp_time_sec)
		var remaining_tail_height_px: float = remaining_sec * scroll_speed_px_per_sec
		_update_hold_body_geometry(remaining_tail_height_px)
	else:
		position.y = p_hit_line_y - (note_data.time_sec - p_dsp_time_sec) * scroll_speed_px_per_sec
		if note_data.is_hold():
			var full_tail_height_px: float = maxf(0.0, note_data.duration_sec) * scroll_speed_px_per_sec
			_update_hold_body_geometry(full_tail_height_px)


func reset_for_pool() -> void:
	note_data = null
	visible = false
	position = Vector2.ZERO
	_current_tail_height_px = 0.0
	if _hold_body_rect != null:
		_hold_body_rect.visible = false
		_hold_body_rect.size = Vector2.ZERO


func get_tail_height_px() -> float:
	return _current_tail_height_px


func _ensure_visual_nodes() -> void:
	if _hold_body_rect == null:
		_hold_body_rect = ColorRect.new()
		_hold_body_rect.name = "HoldBodyRect"
		_hold_body_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hold_body_rect.color = Color(0.25, 0.85, 1.0, 0.55)
		_hold_body_rect.visible = false
		add_child(_hold_body_rect)

	if _head_rect == null:
		_head_rect = ColorRect.new()
		_head_rect.name = "HeadRect"
		_head_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_head_rect.color = Color(0.35, 0.95, 1.0, 1.0)
		add_child(_head_rect)


func _update_hold_body_geometry(p_tail_height_px: float) -> void:
	_current_tail_height_px = maxf(0.0, p_tail_height_px)
	var body_width: float = maxf(4.0, lane_width * HOLD_WIDTH_RATIO)
	var body_x: float = (lane_width - body_width) * 0.5
	_hold_body_rect.position = Vector2(body_x, -_current_tail_height_px)
	_hold_body_rect.size = Vector2(body_width, _current_tail_height_px)
