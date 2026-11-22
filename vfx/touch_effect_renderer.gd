class_name TouchEffectRenderer
extends RefCounted

const WAVE_DURATION_SEC: float = 0.34
const WAVE_START_RADIUS_PX: float = 14.0
const WAVE_END_RADIUS_PX: float = 78.0

const DIAMOND_DURATION_SEC: float = 0.38
const DIAMOND_FRONT_SPIN_RAD: float = 1.85
const DIAMOND_BACK_SPIN_RAD: float = -1.45

const NOTE_DURATION_SEC: float = 0.50
const NOTE_VARIANT_COUNT: int = 4
const NOTE_FLOAT_RISE_PX: float = 58.0
const OVAL_SEGMENTS: int = 14

const COLOR_LIGHT_CYAN_WHITE: Color = Color(0.84, 0.99, 1.0, 1.0)
const COLOR_NEON_CYAN_HALO: Color = Color(0.24, 0.90, 1.0, 1.0)
const WAVE_OUTER_BLUE_NEON: Color = Color(0.18, 0.56, 1.0, 1.0)
const WAVE_INNER_BLUE_NEON: Color = Color(0.32, 0.74, 1.0, 1.0)
const WAVE_CORE_BLUE_BRIGHT: Color = Color(0.70, 0.91, 1.0, 1.0)

var _poly4_buf: PackedVector2Array = PackedVector2Array()
var _line5_buf: PackedVector2Array = PackedVector2Array()
var _oval_poly_buf: PackedVector2Array = PackedVector2Array()
var _oval_line_buf: PackedVector2Array = PackedVector2Array()
var _flag_pts_buf: PackedVector2Array = PackedVector2Array()


func _init() -> void:
	_poly4_buf.resize(4)
	_line5_buf.resize(5)
	_oval_poly_buf.resize(OVAL_SEGMENTS)
	_oval_line_buf.resize(OVAL_SEGMENTS + 1)
	_flag_pts_buf.resize(5)


static func get_duration_for_style(p_style: String) -> float:
	match GameplayEffectsConfig.sanitize_touch_effect(p_style):
		GameplayEffectsConfig.TOUCH_DOUBLE_DIAMOND:
			return DIAMOND_DURATION_SEC
		GameplayEffectsConfig.TOUCH_MUSICAL_NOTE:
			return NOTE_DURATION_SEC
		_:
			return WAVE_DURATION_SEC


static func compute_diamond_angles(p_t: float) -> Vector2:
	var t: float = clampf(p_t, 0.0, 1.0)
	var base_angle: float = PI * 0.25
	return Vector2(
		base_angle + (t * DIAMOND_FRONT_SPIN_RAD),
		base_angle + (t * DIAMOND_BACK_SPIN_RAD)
	)


func draw_touch_effect(
	p_canvas: CanvasItem,
	p_pos: Vector2,
	p_progress: float,
	p_style: String,
	p_color: Color,
	p_variant: int = 0
) -> void:
	if p_canvas == null:
		return
	var t: float = clampf(p_progress, 0.0, 1.0)
	if t >= 1.0:
		return

	match GameplayEffectsConfig.sanitize_touch_effect(p_style):
		GameplayEffectsConfig.TOUCH_DOUBLE_DIAMOND:
			_draw_double_diamond(p_canvas, p_pos, t, p_color)
		GameplayEffectsConfig.TOUCH_MUSICAL_NOTE:
			_draw_musical_note(p_canvas, p_pos, t, p_color, p_variant)
		_:
			_draw_wave(p_canvas, p_pos, t, p_color)


static func get_wave_halo_color() -> Color:
	return WAVE_INNER_BLUE_NEON


static func get_wave_core_color() -> Color:
	return WAVE_CORE_BLUE_BRIGHT


func _draw_wave(p_canvas: CanvasItem, p_pos: Vector2, p_t: float, p_color: Color) -> void:
	var eased_t: float = 1.0 - pow(1.0 - p_t, 2.4)
	var radius: float = lerpf(WAVE_START_RADIUS_PX, WAVE_END_RADIUS_PX, eased_t)
	var fade: float = (1.0 - p_t) * (1.0 - (p_t * 0.16))
	var alpha: float = clampf(fade * maxf(0.92, p_color.a), 0.0, 1.0)
	var stroke_w: float = lerpf(4.8, 1.6, p_t)

	# Luminous blue-neon expanding ring with soft multi-layer diffused halo
	var outer_halo_col: Color = Color(
		WAVE_OUTER_BLUE_NEON.r,
		WAVE_OUTER_BLUE_NEON.g,
		WAVE_OUTER_BLUE_NEON.b,
		alpha * 0.30
	)
	var inner_halo_col: Color = Color(
		WAVE_INNER_BLUE_NEON.r,
		WAVE_INNER_BLUE_NEON.g,
		WAVE_INNER_BLUE_NEON.b,
		alpha * 0.56
	)
	var core_col: Color = Color(
		WAVE_CORE_BLUE_BRIGHT.r,
		WAVE_CORE_BLUE_BRIGHT.g,
		WAVE_CORE_BLUE_BRIGHT.b,
		minf(1.0, alpha * 1.15)
	)
	p_canvas.draw_arc(p_pos, radius, 0.0, TAU, 32, outer_halo_col, stroke_w * 3.8, true)
	p_canvas.draw_arc(p_pos, radius, 0.0, TAU, 32, inner_halo_col, stroke_w * 2.0, true)
	p_canvas.draw_arc(p_pos, radius, 0.0, TAU, 32, core_col, stroke_w * 1.1, true)


func _draw_double_diamond(p_canvas: CanvasItem, p_pos: Vector2, p_t: float, p_color: Color) -> void:
	var eased_t: float = 1.0 - pow(1.0 - p_t, 2.3)
	var fade: float = (1.0 - p_t) * (1.0 - (p_t * 0.25)) * p_color.a
	if fade <= 0.004:
		return

	var angles: Vector2 = compute_diamond_angles(p_t)
	var front_angle_cw: float = angles.x
	var back_angle_ccw: float = angles.y

	# 1. Back diamond: outline only, spinning counter-clockwise
	var back_r: float = lerpf(18.0, 66.0, eased_t)
	_fill_rotated_diamond_line(_line5_buf, p_pos, back_r, back_angle_ccw)
	var back_stroke: float = lerpf(3.4, 1.3, p_t)
	var back_halo_col: Color = Color(p_color.r, p_color.g, p_color.b, fade * 0.28)
	var back_core_col: Color = Color(
		lerpf(p_color.r, 0.85, 0.35),
		lerpf(p_color.g, 1.0, 0.35),
		1.0,
		fade * 0.92
	)
	p_canvas.draw_polyline(_line5_buf, back_halo_col, back_stroke * 3.0, true)
	p_canvas.draw_polyline(_line5_buf, back_core_col, back_stroke, true)

	# 2. Front diamond: solid bright light-cyan-white, spinning clockwise
	var front_r: float = lerpf(11.0, 38.0, eased_t)
	_fill_rotated_diamond_poly(_poly4_buf, p_pos, front_r * 1.24, front_angle_cw)
	var front_glow_col: Color = Color(
		COLOR_NEON_CYAN_HALO.r,
		COLOR_NEON_CYAN_HALO.g,
		COLOR_NEON_CYAN_HALO.b,
		fade * 0.24
	)
	p_canvas.draw_colored_polygon(_poly4_buf, front_glow_col)

	_fill_rotated_diamond_poly(_poly4_buf, p_pos, front_r, front_angle_cw)
	var front_solid_col: Color = Color(
		COLOR_LIGHT_CYAN_WHITE.r,
		COLOR_LIGHT_CYAN_WHITE.g,
		COLOR_LIGHT_CYAN_WHITE.b,
		fade * 0.88
	)
	p_canvas.draw_colored_polygon(_poly4_buf, front_solid_col)


func _fill_rotated_diamond_poly(
	p_buf: PackedVector2Array,
	p_center: Vector2,
	p_radius: float,
	p_angle: float
) -> void:
	for i: int in range(4):
		var a: float = p_angle + (float(i) * (PI * 0.5))
		p_buf[i] = p_center + Vector2(cos(a) * p_radius, sin(a) * p_radius)


func _fill_rotated_diamond_line(
	p_buf: PackedVector2Array,
	p_center: Vector2,
	p_radius: float,
	p_angle: float
) -> void:
	for i: int in range(4):
		var a: float = p_angle + (float(i) * (PI * 0.5))
		p_buf[i] = p_center + Vector2(cos(a) * p_radius, sin(a) * p_radius)
	p_buf[4] = p_buf[0]


func _draw_musical_note(
	p_canvas: CanvasItem,
	p_pos: Vector2,
	p_t: float,
	p_color: Color,
	p_variant: int
) -> void:
	var eased_t: float = 1.0 - pow(1.0 - p_t, 2.0)
	var pop_in: float = smoothstep(0.0, 0.14, p_t)
	var fade_out: float = 1.0 - smoothstep(0.28, 1.0, p_t)
	var alpha: float = pop_in * fade_out * p_color.a
	if alpha <= 0.004:
		return

	var scale_f: float = lerpf(0.80, 1.14, eased_t)
	var sway_dir: float = 1.0 if (p_variant % 2) == 0 else -1.0
	var center: Vector2 = Vector2(
		p_pos.x + (sin(p_t * PI) * 8.0 * sway_dir),
		p_pos.y - (eased_t * NOTE_FLOAT_RISE_PX)
	)

	var halo_col: Color = Color(
		lerpf(p_color.r, COLOR_NEON_CYAN_HALO.r, 0.5),
		lerpf(p_color.g, COLOR_NEON_CYAN_HALO.g, 0.5),
		1.0,
		alpha * 0.28
	)
	var core_col: Color = Color(
		COLOR_LIGHT_CYAN_WHITE.r,
		COLOR_LIGHT_CYAN_WHITE.g,
		COLOR_LIGHT_CYAN_WHITE.b,
		alpha * 0.96
	)

	# Soft ambient halo behind note glyph
	p_canvas.draw_circle(center + Vector2(0.0, -8.0 * scale_f), 26.0 * scale_f, Color(halo_col.r, halo_col.g, halo_col.b, alpha * 0.14))

	var variant: int = posmod(p_variant, NOTE_VARIANT_COUNT)
	match variant:
		0:
			# Corchea (eighth note: solid head + stem + curved flag)
			var head_pos: Vector2 = center + Vector2(-4.0 * scale_f, 10.0 * scale_f)
			_draw_note_head(p_canvas, head_pos, 9.8 * scale_f, 7.2 * scale_f, true, halo_col, core_col, scale_f)
			var stem_bot: Vector2 = head_pos + Vector2(8.2 * scale_f, -2.0 * scale_f)
			var stem_top: Vector2 = stem_bot + Vector2(0.0, -34.0 * scale_f)
			_draw_glow_line(p_canvas, stem_bot, stem_top, 3.0 * scale_f, halo_col, core_col)
			_flag_pts_buf[0] = stem_top
			_flag_pts_buf[1] = stem_top + Vector2(10.0 * scale_f, 6.0 * scale_f)
			_flag_pts_buf[2] = stem_top + Vector2(15.0 * scale_f, 14.0 * scale_f)
			_flag_pts_buf[3] = stem_top + Vector2(13.0 * scale_f, 22.0 * scale_f)
			_flag_pts_buf[4] = stem_top + Vector2(6.5 * scale_f, 26.0 * scale_f)
			p_canvas.draw_polyline(_flag_pts_buf, halo_col, 7.2 * scale_f, true)
			p_canvas.draw_polyline(_flag_pts_buf, core_col, 3.2 * scale_f, true)
		1:
			# Doble corchea (beamed eighth notes pair)
			var left_head: Vector2 = center + Vector2(-13.0 * scale_f, 12.0 * scale_f)
			var right_head: Vector2 = center + Vector2(9.0 * scale_f, 8.0 * scale_f)
			_draw_note_head(p_canvas, left_head, 8.6 * scale_f, 6.4 * scale_f, true, halo_col, core_col, scale_f)
			_draw_note_head(p_canvas, right_head, 8.6 * scale_f, 6.4 * scale_f, true, halo_col, core_col, scale_f)
			var l_bot: Vector2 = left_head + Vector2(7.0 * scale_f, -1.5 * scale_f)
			var l_top: Vector2 = l_bot + Vector2(0.0, -31.0 * scale_f)
			var r_bot: Vector2 = right_head + Vector2(7.0 * scale_f, -1.5 * scale_f)
			var r_top: Vector2 = r_bot + Vector2(0.0, -32.0 * scale_f)
			_draw_glow_line(p_canvas, l_bot, l_top, 2.8 * scale_f, halo_col, core_col)
			_draw_glow_line(p_canvas, r_bot, r_top, 2.8 * scale_f, halo_col, core_col)
			_draw_glow_line(p_canvas, l_top, r_top, 5.2 * scale_f, halo_col, core_col)
		2:
			# Negra (quarter note: solid head + stem)
			var head_pos: Vector2 = center + Vector2(-2.0 * scale_f, 10.0 * scale_f)
			_draw_note_head(p_canvas, head_pos, 10.2 * scale_f, 7.5 * scale_f, true, halo_col, core_col, scale_f)
			var stem_bot: Vector2 = head_pos + Vector2(8.6 * scale_f, -2.0 * scale_f)
			var stem_top: Vector2 = stem_bot + Vector2(0.0, -35.0 * scale_f)
			_draw_glow_line(p_canvas, stem_bot, stem_top, 3.2 * scale_f, halo_col, core_col)
		_:
			# Blanca (half note: hollow oval head + stem)
			var head_pos: Vector2 = center + Vector2(-2.0 * scale_f, 10.0 * scale_f)
			_draw_note_head(p_canvas, head_pos, 10.4 * scale_f, 7.6 * scale_f, false, halo_col, core_col, scale_f)
			var stem_bot: Vector2 = head_pos + Vector2(8.8 * scale_f, -2.0 * scale_f)
			var stem_top: Vector2 = stem_bot + Vector2(0.0, -35.0 * scale_f)
			_draw_glow_line(p_canvas, stem_bot, stem_top, 3.0 * scale_f, halo_col, core_col)


func _draw_note_head(
	p_canvas: CanvasItem,
	p_center: Vector2,
	p_rx: float,
	p_ry: float,
	p_filled: bool,
	p_halo_col: Color,
	p_core_col: Color,
	p_scale: float
) -> void:
	var tilt: float = -0.40
	var cos_t: float = cos(tilt)
	var sin_t: float = sin(tilt)

	if p_filled:
		for i: int in range(OVAL_SEGMENTS):
			var a: float = (float(i) / float(OVAL_SEGMENTS)) * TAU
			var lx: float = cos(a) * p_rx * 1.24
			var ly: float = sin(a) * p_ry * 1.24
			_oval_poly_buf[i] = p_center + Vector2((lx * cos_t) - (ly * sin_t), (lx * sin_t) + (ly * cos_t))
		p_canvas.draw_colored_polygon(_oval_poly_buf, p_halo_col)

		for i: int in range(OVAL_SEGMENTS):
			var a: float = (float(i) / float(OVAL_SEGMENTS)) * TAU
			var lx: float = cos(a) * p_rx
			var ly: float = sin(a) * p_ry
			_oval_poly_buf[i] = p_center + Vector2((lx * cos_t) - (ly * sin_t), (lx * sin_t) + (ly * cos_t))
		p_canvas.draw_colored_polygon(_oval_poly_buf, p_core_col)
	else:
		for i: int in range(OVAL_SEGMENTS):
			var a: float = (float(i) / float(OVAL_SEGMENTS)) * TAU
			var lx: float = cos(a) * p_rx
			var ly: float = sin(a) * p_ry
			_oval_line_buf[i] = p_center + Vector2((lx * cos_t) - (ly * sin_t), (lx * sin_t) + (ly * cos_t))
		_oval_line_buf[OVAL_SEGMENTS] = _oval_line_buf[0]
		p_canvas.draw_polyline(_oval_line_buf, p_halo_col, 6.4 * p_scale, true)
		p_canvas.draw_polyline(_oval_line_buf, p_core_col, 2.8 * p_scale, true)


func _draw_glow_line(
	p_canvas: CanvasItem,
	p_from: Vector2,
	p_to: Vector2,
	p_width: float,
	p_halo_col: Color,
	p_core_col: Color
) -> void:
	p_canvas.draw_line(p_from, p_to, p_halo_col, p_width * 2.6, true)
	p_canvas.draw_line(p_from, p_to, p_core_col, p_width, true)
