class_name NoteView
extends Control

const DEFAULT_HEAD_HEIGHT_PX: float = 36.0
const HORIZONTAL_PADDING_PX: float = 8.0
const HOLD_OUTER_BEAM_IDLE_RATIO: float = 0.76
const HOLD_OUTER_BEAM_ACTIVE_RATIO: float = 0.90
const HOLD_INNER_BEAM_IDLE_RATIO: float = 0.44
const HOLD_INNER_BEAM_ACTIVE_RATIO: float = 0.54
const HOLD_TAIL_FADE_MAX_PX: float = 46.0
const HOLD_PULSE_FREQ_RAD: float = 18.0

const MOTION_FEATHER_MIN_MULTIPLIER: int = 3
const MOTION_FEATHER_INNER_COLOR: Color = Color(0.45, 0.96, 1.0, 0.16)
const MOTION_FEATHER_OUTER_COLOR: Color = Color(0.32, 0.88, 1.0, 0.07)

# Strictly neon cyan / turquoise diffused palette (no hard white solid bar)
const HOLD_OUTER_IDLE_COLOR: Color = Color(0.10, 0.76, 0.94, 0.28)
const HOLD_OUTER_ACTIVE_COLOR: Color = Color(0.14, 0.92, 0.88, 0.42)
const HOLD_INNER_IDLE_COLOR: Color = Color(0.20, 0.90, 0.96, 0.62)
const HOLD_INNER_ACTIVE_COLOR: Color = Color(0.28, 0.98, 0.90, 0.82)
const HOLD_CAP_IDLE_COLOR: Color = Color(0.24, 0.92, 0.96, 0.58)
const HOLD_CAP_ACTIVE_COLOR: Color = Color(0.32, 0.98, 0.90, 0.78)
const HEAD_IDLE_COLOR: Color = Color(0.35, 0.95, 1.0, 1.0)
const HEAD_HOLD_ACTIVE_COLOR: Color = Color(0.45, 1.0, 0.94, 1.0)

static var _shared_hold_beam_texture: GradientTexture2D = null
static var _shared_hold_tail_cap_texture: GradientTexture2D = null

var note_data: NoteData = null
var lane_width: float = 200.0
var scroll_speed_px_per_sec: float = 550.0
var speed_multiplier: int = 1

var _motion_feather_outer_rect: ColorRect = null
var _motion_feather_inner_rect: ColorRect = null
var _head_rect: ColorRect = null
var _is_hold_visible: bool = false
var _is_hold_active: bool = false
var _hold_pulse_phase: float = 0.0
var _current_tail_height_px: float = 0.0
var _current_outer_glow_width_px: float = 0.0
var _current_motion_feather_height_px: float = 0.0

var _quad_pts_buf: PackedVector2Array = PackedVector2Array()
var _quad_cols_buf: PackedColorArray = PackedColorArray()
var _quad_uvs_buf: PackedVector2Array = PackedVector2Array([
	Vector2(0.0, 0.0),
	Vector2(1.0, 0.0),
	Vector2(1.0, 1.0),
	Vector2(0.0, 1.0),
])


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quad_pts_buf.resize(4)
	_quad_cols_buf.resize(4)
	_ensure_shared_textures()
	_ensure_visual_nodes()


func _ready() -> void:
	_ensure_shared_textures()
	_ensure_visual_nodes()


func _draw() -> void:
	if not _is_hold_visible or _current_tail_height_px <= 0.5:
		return
	if _shared_hold_beam_texture == null:
		return

	var cx: float = lane_width * 0.5
	var tail_h: float = _current_tail_height_px
	var cap_fade_h: float = minf(HOLD_TAIL_FADE_MAX_PX, tail_h * 0.44)
	var main_top_y: float = -(tail_h - cap_fade_h)
	var tail_top_y: float = -tail_h
	var pulse: float = _hold_pulse_phase if _is_hold_active else 0.0

	var outer_ratio: float = (
		HOLD_OUTER_BEAM_ACTIVE_RATIO + (pulse * 0.08)
		if _is_hold_active
		else HOLD_OUTER_BEAM_IDLE_RATIO
	)
	var outer_w: float = minf(lane_width * 0.98, maxf(8.0, lane_width * outer_ratio))
	var outer_hw: float = outer_w * 0.5
	var outer_col: Color = HOLD_OUTER_ACTIVE_COLOR if _is_hold_active else HOLD_OUTER_IDLE_COLOR
	var outer_alpha: float = clampf(outer_col.a + (pulse * 0.08), 0.0, 0.52)

	var inner_ratio: float = (
		HOLD_INNER_BEAM_ACTIVE_RATIO + (pulse * 0.06)
		if _is_hold_active
		else HOLD_INNER_BEAM_IDLE_RATIO
	)
	var inner_w: float = minf(lane_width * 0.72, maxf(6.0, lane_width * inner_ratio))
	var inner_hw: float = inner_w * 0.5
	var inner_col: Color = HOLD_INNER_ACTIVE_COLOR if _is_hold_active else HOLD_INNER_IDLE_COLOR
	var inner_alpha: float = clampf(inner_col.a + (pulse * 0.10), 0.0, 0.88)

	# 1. Wide diffused outer neon veil (zero hard vertical edges)
	_draw_diffused_beam_body(cx, outer_hw, main_top_y, tail_top_y, outer_col, outer_alpha)

	# 2. Smooth luminous cyan-turquoise inner energy beam (no solid white stripe)
	_draw_diffused_beam_body(cx, inner_hw, main_top_y, tail_top_y, inner_col, inner_alpha)

	# 3. Soft radial end cap at tail end so it dissolves smoothly instead of ending in a flat block
	if _shared_hold_tail_cap_texture != null:
		var cap_col: Color = HOLD_CAP_ACTIVE_COLOR if _is_hold_active else HOLD_CAP_IDLE_COLOR
		var cap_rx: float = inner_hw * 1.12
		var cap_ry: float = maxf(10.0, minf(cap_rx * 0.85, tail_h * 0.55))
		var cap_cy: float = tail_top_y + (cap_fade_h * 0.38)
		var cap_rect: Rect2 = Rect2(cx - cap_rx, cap_cy - cap_ry, cap_rx * 2.0, cap_ry * 2.0)
		var cap_tint: Color = Color(cap_col.r, cap_col.g, cap_col.b, clampf(cap_col.a + (pulse * 0.10), 0.0, 0.85))
		draw_texture_rect(_shared_hold_tail_cap_texture, cap_rect, false, cap_tint)


func _draw_diffused_beam_body(
	p_cx: float,
	p_hw: float,
	p_main_top_y: float,
	p_tail_top_y: float,
	p_color: Color,
	p_alpha: float
) -> void:
	var c_solid: Color = Color(p_color.r, p_color.g, p_color.b, p_alpha)
	var c_zero: Color = Color(p_color.r, p_color.g, p_color.b, 0.0)

	# Main continuous body segment (from y = 0 up to p_main_top_y)
	if p_main_top_y < -0.5:
		_quad_pts_buf[0] = Vector2(p_cx - p_hw, p_main_top_y)
		_quad_pts_buf[1] = Vector2(p_cx + p_hw, p_main_top_y)
		_quad_pts_buf[2] = Vector2(p_cx + p_hw, 0.0)
		_quad_pts_buf[3] = Vector2(p_cx - p_hw, 0.0)
		_quad_cols_buf[0] = c_solid
		_quad_cols_buf[1] = c_solid
		_quad_cols_buf[2] = c_solid
		_quad_cols_buf[3] = c_solid
		draw_polygon(_quad_pts_buf, _quad_cols_buf, _quad_uvs_buf, _shared_hold_beam_texture)

	# Top smooth fade-out taper (from p_main_top_y up to p_tail_top_y)
	if p_tail_top_y < p_main_top_y - 0.25:
		var taper_hw: float = p_hw * 0.78
		_quad_pts_buf[0] = Vector2(p_cx - taper_hw, p_tail_top_y)
		_quad_pts_buf[1] = Vector2(p_cx + taper_hw, p_tail_top_y)
		_quad_pts_buf[2] = Vector2(p_cx + p_hw, p_main_top_y)
		_quad_pts_buf[3] = Vector2(p_cx - p_hw, p_main_top_y)
		_quad_cols_buf[0] = c_zero
		_quad_cols_buf[1] = c_zero
		_quad_cols_buf[2] = c_solid
		_quad_cols_buf[3] = c_solid
		draw_polygon(_quad_pts_buf, _quad_cols_buf, _quad_uvs_buf, _shared_hold_beam_texture)


func setup(
	p_note: NoteData,
	p_lane_width: float,
	p_scroll_speed_px_per_sec: float,
	p_speed_multiplier: int = 1
) -> void:
	_ensure_shared_textures()
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
	_head_rect.color = HEAD_IDLE_COLOR

	if note_data.is_hold():
		var full_tail_height_px: float = maxf(0.0, note_data.duration_sec) * scroll_speed_px_per_sec
		_is_hold_visible = true
		_update_hold_body_geometry(full_tail_height_px, false, 0.0)
	else:
		_hide_and_clear_hold_layers()

	_update_motion_feather(visual_width, false)
	visible = true


func set_speed_multiplier(p_multiplier: int) -> void:
	speed_multiplier = maxi(1, p_multiplier)
	if note_data != null:
		var visual_width: float = maxf(4.0, lane_width - (HORIZONTAL_PADDING_PX * 2.0))
		_update_motion_feather(visual_width, _is_hold_active)


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
		_head_rect.color = HEAD_HOLD_ACTIVE_COLOR
		_update_hold_body_geometry(remaining_tail_height_px, true, pulse_phase)
		_update_motion_feather(visual_width, true)
	else:
		position.y = p_hit_line_y - (note_data.time_sec - p_dsp_time_sec) * scroll_speed_px_per_sec
		_head_rect.color = HEAD_IDLE_COLOR
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
	return _is_hold_visible and _current_tail_height_px > 0.5


func is_hold_actively_consuming() -> bool:
	return _is_hold_visible and _is_hold_active


func get_hold_beam_texture() -> GradientTexture2D:
	return _shared_hold_beam_texture


func get_hold_tail_cap_texture() -> GradientTexture2D:
	return _shared_hold_tail_cap_texture


func is_motion_feather_visible() -> bool:
	return (
		_motion_feather_outer_rect != null
		and _motion_feather_outer_rect.visible
		and _motion_feather_inner_rect != null
		and _motion_feather_inner_rect.visible
	)


func get_motion_feather_height_px() -> float:
	return _current_motion_feather_height_px


static func _ensure_shared_textures() -> void:
	if _shared_hold_beam_texture == null:
		var beam_grad: Gradient = Gradient.new()
		beam_grad.offsets = PackedFloat32Array([0.0, 0.16, 0.34, 0.50, 0.66, 0.84, 1.0])
		beam_grad.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 0.0),
			Color(1.0, 1.0, 1.0, 0.14),
			Color(1.0, 1.0, 1.0, 0.62),
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.62),
			Color(1.0, 1.0, 1.0, 0.14),
			Color(1.0, 1.0, 1.0, 0.0),
		])
		var beam_tex: GradientTexture2D = GradientTexture2D.new()
		beam_tex.gradient = beam_grad
		beam_tex.fill = GradientTexture2D.FILL_LINEAR
		beam_tex.fill_from = Vector2(0.0, 0.5)
		beam_tex.fill_to = Vector2(1.0, 0.5)
		beam_tex.width = 128
		beam_tex.height = 8
		beam_tex.use_hdr = false
		_shared_hold_beam_texture = beam_tex

	if _shared_hold_tail_cap_texture == null:
		var cap_grad: Gradient = Gradient.new()
		cap_grad.offsets = PackedFloat32Array([0.0, 0.35, 0.70, 1.0])
		cap_grad.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.58),
			Color(1.0, 1.0, 1.0, 0.16),
			Color(1.0, 1.0, 1.0, 0.0),
		])
		var cap_tex: GradientTexture2D = GradientTexture2D.new()
		cap_tex.gradient = cap_grad
		cap_tex.fill = GradientTexture2D.FILL_RADIAL
		cap_tex.fill_from = Vector2(0.5, 0.5)
		cap_tex.fill_to = Vector2(0.5, 0.0)
		cap_tex.width = 96
		cap_tex.height = 96
		cap_tex.use_hdr = false
		_shared_hold_tail_cap_texture = cap_tex


func _ensure_visual_nodes() -> void:
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
		_head_rect.color = HEAD_IDLE_COLOR
		add_child(_head_rect)


func _hide_and_clear_hold_layers() -> void:
	_is_hold_visible = false
	_is_hold_active = false
	_hold_pulse_phase = 0.0
	_current_tail_height_px = 0.0
	_current_outer_glow_width_px = 0.0
	queue_redraw()


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
	_is_hold_visible = _current_tail_height_px > 0.5
	_is_hold_active = p_is_holding and _is_hold_visible
	_hold_pulse_phase = clampf(p_pulse_phase, 0.0, 1.0)

	var outer_ratio: float = (
		HOLD_OUTER_BEAM_ACTIVE_RATIO + (_hold_pulse_phase * 0.08)
		if _is_hold_active
		else HOLD_OUTER_BEAM_IDLE_RATIO
	)
	_current_outer_glow_width_px = minf(lane_width * 0.98, maxf(8.0, lane_width * outer_ratio))
	queue_redraw()
