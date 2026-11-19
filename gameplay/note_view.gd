class_name NoteView
extends Control

const DEFAULT_HEAD_HEIGHT_PX: float = 36.0
const HORIZONTAL_PADDING_PX: float = 8.0
const HOLD_WIDTH_RATIO: float = 0.52
const HOLD_CORE_BEAM_RATIO: float = 0.28
const HOLD_INNER_GLOW_IDLE_SCALE: float = 1.36
const HOLD_OUTER_GLOW_IDLE_SCALE: float = 1.78
const HOLD_INNER_GLOW_ACTIVE_SCALE: float = 1.62
const HOLD_OUTER_GLOW_ACTIVE_SCALE: float = 2.18
const HOLD_PULSE_FREQ_RAD: float = 20.0

const MOTION_FEATHER_MIN_MULTIPLIER: int = 3
const MOTION_FEATHER_INNER_COLOR: Color = Color(0.45, 0.96, 1.0, 0.16)
const MOTION_FEATHER_OUTER_COLOR: Color = Color(0.32, 0.88, 1.0, 0.07)

const HOLD_BODY_IDLE_COLOR: Color = Color(0.24, 0.86, 1.0, 0.38)
const HOLD_BODY_ACTIVE_COLOR: Color = Color(0.38, 0.98, 0.92, 0.54)
const HOLD_CORE_BEAM_IDLE_COLOR: Color = Color(0.72, 0.98, 1.0, 0.78)
const HOLD_CORE_BEAM_ACTIVE_COLOR: Color = Color(0.92, 1.0, 0.98, 0.98)
const HOLD_INNER_GLOW_IDLE_COLOR: Color = Color(0.20, 0.82, 1.0, 0.18)
const HOLD_INNER_GLOW_ACTIVE_COLOR: Color = Color(0.32, 0.98, 0.90, 0.32)
const HOLD_OUTER_GLOW_IDLE_COLOR: Color = Color(0.16, 0.72, 1.0, 0.08)
const HOLD_OUTER_GLOW_ACTIVE_COLOR: Color = Color(0.22, 0.94, 0.86, 0.16)

var note_data: NoteData = null
var lane_width: float = 200.0
var scroll_speed_px_per_sec: float = 550.0
var speed_multiplier: int = 1

var _hold_outer_glow_rect: ColorRect = null
var _hold_inner_glow_rect: ColorRect = null
var _hold_body_rect: ColorRect = null
var _hold_core_beam_rect: ColorRect = null
var _motion_feather_outer_rect: ColorRect = null
var _motion_feather_inner_rect: ColorRect = null
var _head_rect: ColorRect = null
var _current_tail_height_px: float = 0.0
var _current_outer_glow_width_px: float = 0.0
var _current_motion_feather_height_px: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_visual_nodes()


func _ready() -> void:
	_ensure_visual_nodes()


func setup(
	p_note: NoteData,
	p_lane_width: float,
	p_scroll_speed_px_per_sec: float,
	p_speed_multiplier: int = 1
) -> void:
	_ensure_visual_nodes()
	note_data = p_note
	lane_width = maxf(1.0, p_lane_width)
	scroll_speed_px_per_sec = maxf(1.0, p_scroll_speed_px_per_sec)
	speed_multiplier = maxi(1, p_speed_multiplier)

	if note_data == null:
		reset_for_pool()
		return

	var visual_width: float = maxf(4.0, lane_width - (HORIZONTAL_PADDING_PX * 2.0))
	size = Vector2(lane_width, DEFAULT_HEAD_HEIGHT_PX)

	_head_rect.position = Vector2(HORIZONTAL_PADDING_PX, -DEFAULT_HEAD_HEIGHT_PX * 0.5)
	_head_rect.size = Vector2(visual_width, DEFAULT_HEAD_HEIGHT_PX)

	if note_data.is_hold():
		var full_tail_height_px: float = maxf(0.0, note_data.duration_sec) * scroll_speed_px_per_sec
		_hold_outer_glow_rect.visible = true
		_hold_inner_glow_rect.visible = true
		_hold_body_rect.visible = true
		_hold_core_beam_rect.visible = true
		_update_hold_body_geometry(full_tail_height_px, false, 0.0)
	else:
		_hide_and_clear_hold_layers()

	_update_motion_feather(visual_width, false)
	visible = true


func set_speed_multiplier(p_multiplier: int) -> void:
	speed_multiplier = maxi(1, p_multiplier)
	if note_data != null:
		var visual_width: float = maxf(4.0, lane_width - (HORIZONTAL_PADDING_PX * 2.0))
		_update_motion_feather(visual_width, false)


func update_position(p_dsp_time_sec: float, p_hit_line_y: float, p_is_holding: bool = false) -> void:
	if note_data == null:
		return

	position.x = float(note_data.lane) * lane_width
	var pulse_phase: float = (sin(p_dsp_time_sec * HOLD_PULSE_FREQ_RAD) * 0.5 + 0.5) if p_is_holding else 0.0
	var visual_width: float = maxf(4.0, lane_width - (HORIZONTAL_PADDING_PX * 2.0))

	if p_is_holding and note_data.is_hold():
		position.y = p_hit_line_y
		var end_time_sec: float = note_data.time_sec + maxf(0.0, note_data.duration_sec)
		var remaining_sec: float = maxf(0.0, end_time_sec - p_dsp_time_sec)
		var remaining_tail_height_px: float = remaining_sec * scroll_speed_px_per_sec
		_update_hold_body_geometry(remaining_tail_height_px, true, pulse_phase)
		_update_motion_feather(visual_width, true)
	else:
		position.y = p_hit_line_y - (note_data.time_sec - p_dsp_time_sec) * scroll_speed_px_per_sec
		if note_data.is_hold():
			var full_tail_height_px: float = maxf(0.0, note_data.duration_sec) * scroll_speed_px_per_sec
			_update_hold_body_geometry(full_tail_height_px, false, 0.0)
		_update_motion_feather(visual_width, false)


func reset_for_pool() -> void:
	note_data = null
	speed_multiplier = 1
	visible = false
	position = Vector2.ZERO
	_hide_and_clear_hold_layers()
	_hide_and_clear_motion_feather()


func get_tail_height_px() -> float:
	return _current_tail_height_px


func get_hold_glow_width_px() -> float:
	return _current_outer_glow_width_px


func is_hold_glow_visible() -> bool:
	return (
		_hold_outer_glow_rect != null
		and _hold_outer_glow_rect.visible
		and _hold_inner_glow_rect != null
		and _hold_inner_glow_rect.visible
		and _hold_core_beam_rect != null
		and _hold_core_beam_rect.visible
	)


func is_motion_feather_visible() -> bool:
	return (
		_motion_feather_outer_rect != null
		and _motion_feather_outer_rect.visible
		and _motion_feather_inner_rect != null
		and _motion_feather_inner_rect.visible
	)


func get_motion_feather_height_px() -> float:
	return _current_motion_feather_height_px


func _ensure_visual_nodes() -> void:
	if _hold_outer_glow_rect == null:
		_hold_outer_glow_rect = ColorRect.new()
		_hold_outer_glow_rect.name = "HoldOuterGlowRect"
		_hold_outer_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hold_outer_glow_rect.color = HOLD_OUTER_GLOW_IDLE_COLOR
		_hold_outer_glow_rect.visible = false
		add_child(_hold_outer_glow_rect)

	if _hold_inner_glow_rect == null:
		_hold_inner_glow_rect = ColorRect.new()
		_hold_inner_glow_rect.name = "HoldInnerGlowRect"
		_hold_inner_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hold_inner_glow_rect.color = HOLD_INNER_GLOW_IDLE_COLOR
		_hold_inner_glow_rect.visible = false
		add_child(_hold_inner_glow_rect)

	if _hold_body_rect == null:
		_hold_body_rect = ColorRect.new()
		_hold_body_rect.name = "HoldBodyRect"
		_hold_body_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hold_body_rect.color = HOLD_BODY_IDLE_COLOR
		_hold_body_rect.visible = false
		add_child(_hold_body_rect)

	if _hold_core_beam_rect == null:
		_hold_core_beam_rect = ColorRect.new()
		_hold_core_beam_rect.name = "HoldCoreBeamRect"
		_hold_core_beam_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hold_core_beam_rect.color = HOLD_CORE_BEAM_IDLE_COLOR
		_hold_core_beam_rect.visible = false
		add_child(_hold_core_beam_rect)

	if _motion_feather_outer_rect == null:
		_motion_feather_outer_rect = ColorRect.new()
		_motion_feather_outer_rect.name = "MotionFeatherOuterRect"
		_motion_feather_outer_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_motion_feather_outer_rect.color = MOTION_FEATHER_OUTER_COLOR
		_motion_feather_outer_rect.visible = false
		add_child(_motion_feather_outer_rect)

	if _motion_feather_inner_rect == null:
		_motion_feather_inner_rect = ColorRect.new()
		_motion_feather_inner_rect.name = "MotionFeatherInnerRect"
		_motion_feather_inner_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_motion_feather_inner_rect.color = MOTION_FEATHER_INNER_COLOR
		_motion_feather_inner_rect.visible = false
		add_child(_motion_feather_inner_rect)

	if _head_rect == null:
		_head_rect = ColorRect.new()
		_head_rect.name = "HeadRect"
		_head_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_head_rect.color = Color(0.35, 0.95, 1.0, 1.0)
		add_child(_head_rect)


func _hide_and_clear_hold_layers() -> void:
	_current_tail_height_px = 0.0
	_current_outer_glow_width_px = 0.0
	if _hold_outer_glow_rect != null:
		_hold_outer_glow_rect.visible = false
		_hold_outer_glow_rect.size = Vector2.ZERO
	if _hold_inner_glow_rect != null:
		_hold_inner_glow_rect.visible = false
		_hold_inner_glow_rect.size = Vector2.ZERO
	if _hold_body_rect != null:
		_hold_body_rect.visible = false
		_hold_body_rect.size = Vector2.ZERO
	if _hold_core_beam_rect != null:
		_hold_core_beam_rect.visible = false
		_hold_core_beam_rect.size = Vector2.ZERO


func _hide_and_clear_motion_feather() -> void:
	_current_motion_feather_height_px = 0.0
	if _motion_feather_outer_rect != null:
		_motion_feather_outer_rect.visible = false
		_motion_feather_outer_rect.size = Vector2.ZERO
	if _motion_feather_inner_rect != null:
		_motion_feather_inner_rect.visible = false
		_motion_feather_inner_rect.size = Vector2.ZERO


func _update_motion_feather(p_visual_width: float, p_is_holding: bool) -> void:
	if p_is_holding or speed_multiplier < MOTION_FEATHER_MIN_MULTIPLIER:
		_hide_and_clear_motion_feather()
		return

	var head_top_y: float = -DEFAULT_HEAD_HEIGHT_PX * 0.5
	var inner_h: float = clampf(scroll_speed_px_per_sec * 0.014, 16.0, 38.0)
	var outer_h: float = inner_h * 1.95
	_current_motion_feather_height_px = outer_h

	_motion_feather_inner_rect.position = Vector2(HORIZONTAL_PADDING_PX, head_top_y - inner_h)
	_motion_feather_inner_rect.size = Vector2(p_visual_width, inner_h)
	_motion_feather_inner_rect.visible = true

	var outer_width: float = maxf(4.0, p_visual_width * 0.92)
	var outer_x: float = (lane_width - outer_width) * 0.5
	_motion_feather_outer_rect.position = Vector2(outer_x, head_top_y - outer_h)
	_motion_feather_outer_rect.size = Vector2(outer_width, outer_h)
	_motion_feather_outer_rect.visible = true


func _update_hold_body_geometry(
	p_tail_height_px: float,
	p_is_holding: bool = false,
	p_pulse_phase: float = 0.0
) -> void:
	_current_tail_height_px = maxf(0.0, p_tail_height_px)
	var pulse_scale: float = 1.0 + (p_pulse_phase * 0.14) if p_is_holding else 1.0
	var body_width: float = maxf(4.0, lane_width * HOLD_WIDTH_RATIO * pulse_scale)
	var body_x: float = (lane_width - body_width) * 0.5
	_hold_body_rect.position = Vector2(body_x, -_current_tail_height_px)
	_hold_body_rect.size = Vector2(body_width, _current_tail_height_px)
	_hold_body_rect.color = HOLD_BODY_ACTIVE_COLOR if p_is_holding else HOLD_BODY_IDLE_COLOR

	var core_ratio: float = HOLD_CORE_BEAM_RATIO * (1.28 + p_pulse_phase * 0.22 if p_is_holding else 1.0)
	var core_width: float = maxf(2.0, body_width * core_ratio)
	var core_x: float = (lane_width - core_width) * 0.5
	_hold_core_beam_rect.position = Vector2(core_x, -_current_tail_height_px)
	_hold_core_beam_rect.size = Vector2(core_width, _current_tail_height_px)
	_hold_core_beam_rect.color = HOLD_CORE_BEAM_ACTIVE_COLOR if p_is_holding else HOLD_CORE_BEAM_IDLE_COLOR

	var inner_scale: float = HOLD_INNER_GLOW_ACTIVE_SCALE if p_is_holding else HOLD_INNER_GLOW_IDLE_SCALE
	var outer_scale: float = HOLD_OUTER_GLOW_ACTIVE_SCALE if p_is_holding else HOLD_OUTER_GLOW_IDLE_SCALE

	var inner_width: float = minf(lane_width, body_width * inner_scale)
	var inner_x: float = (lane_width - inner_width) * 0.5
	_hold_inner_glow_rect.position = Vector2(inner_x, -_current_tail_height_px)
	_hold_inner_glow_rect.size = Vector2(inner_width, _current_tail_height_px)
	_hold_inner_glow_rect.color = HOLD_INNER_GLOW_ACTIVE_COLOR if p_is_holding else HOLD_INNER_GLOW_IDLE_COLOR

	var outer_width: float = minf(lane_width, body_width * outer_scale)
	var outer_x: float = (lane_width - outer_width) * 0.5
	_current_outer_glow_width_px = outer_width
	_hold_outer_glow_rect.position = Vector2(outer_x, -_current_tail_height_px)
	_hold_outer_glow_rect.size = Vector2(outer_width, _current_tail_height_px)
	_hold_outer_glow_rect.color = HOLD_OUTER_GLOW_ACTIVE_COLOR if p_is_holding else HOLD_OUTER_GLOW_IDLE_COLOR
