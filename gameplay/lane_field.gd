class_name LaneField
extends Control

const DEFAULT_LANE_COUNT: int = 4
const MIN_SPEED_MULTIPLIER: int = 1
const MAX_SPEED_MULTIPLIER: int = 4
const DEFAULT_BASE_SCROLL_SPEED_PX_PER_SEC: float = 550.0
const TOP_SPAWN_MARGIN_PX: float = 64.0
const DEFAULT_PLAY_WIDTH: float = 950.4
const DEFAULT_PLAY_HEIGHT: float = 1920.0
const HIT_LINE_VERTICAL_LIFT_PX: float = 60.0
const LANE_DIVIDER_COLOR: Color = Color(0.28, 0.88, 1.0, 0.24)
const OUTER_BORDER_COLOR: Color = Color(0.32, 0.92, 1.0, 0.34)
const LANE_DIVIDER_GLOW_COLOR: Color = Color(0.22, 0.86, 1.0, 0.34)
const LANE_DIVIDER_DROP_COLOR: Color = Color(0.54, 0.96, 1.0, 0.65)
const DIVIDER_SHAKE_BEAT_PX: float = 2.2
const DIVIDER_SHAKE_MAX_PX: float = 3.5
const DIVIDER_SHAKE_DECAY_RATE: float = 15.0
const DIVIDER_SHAKE_FREQ_RAD: float = 54.0
const DIVIDER_GLOW_DECAY_RATE: float = 10.5
const DIVIDER_DROP_DECAY_RATE: float = 4.5
const RAIL_CONTINUOUS_CORE_COLOR: Color = Color(0.82, 0.98, 1.0, 0.96)
const RAIL_CONTINUOUS_GLOW_COLOR: Color = Color(0.22, 0.88, 1.0, 0.75)
const RAIL_PRESSED_CORE_COLOR: Color = Color(0.96, 1.0, 1.0, 1.0)
const RAIL_PRESSED_GLOW_COLOR: Color = Color(0.40, 0.96, 1.0, 0.90)
const RAIL_HOLD_CORE_COLOR: Color = Color(0.80, 1.0, 0.94, 1.0)
const RAIL_HOLD_GLOW_COLOR: Color = Color(0.28, 1.0, 0.85, 0.95)
const CONTINUOUS_CORE_THICKNESS: float = 2.6
const CONTINUOUS_GLOW_SCALE: float = 1.25

const MAX_ACTIVE_RIPPLES: int = 16
const RIPPLE_DURATION_SEC: float = 0.34
const RIPPLE_START_RADIUS_PX: float = 14.0
const RIPPLE_END_RADIUS_PX: float = 78.0

const MAX_ACTIVE_PARTICLES: int = 128
const PERFECT_PARTICLE_COUNT: int = 14
const GREAT_PARTICLE_COUNT: int = 8
const GOOD_PARTICLE_COUNT: int = 4
const HOLD_TICK_SPARK_COUNT: int = 6
const HOLD_SPARK_INTERVAL_SEC: float = 0.045
const PARTICLE_GRAVITY_PX_PER_SEC2: float = 340.0

const COLOR_PERFECT_A: Color = Color(0.35, 1.0, 0.96, 1.0)
const COLOR_PERFECT_B: Color = Color(1.0, 0.88, 0.28, 1.0)
const COLOR_PERFECT_C: Color = Color(1.0, 0.36, 0.86, 1.0)
const COLOR_GREAT_A: Color = Color(0.30, 1.0, 0.62, 1.0)
const COLOR_GREAT_B: Color = Color(0.25, 0.90, 1.0, 1.0)
const COLOR_GOOD_A: Color = Color(0.38, 0.76, 1.0, 0.92)
const COLOR_HOLD_SPARK: Color = Color(0.55, 1.0, 0.92, 1.0)
const COLOR_TOUCH_RIPPLE: Color = Color(0.38, 0.94, 1.0, 0.88)

@export var dsp_clock: DSPClock = null
@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var input_adapter: RhythmInputAdapter = null
@export var hit_judge: HitJudge = null
@export var audio_analyzer: AudioAnalyzer = null
@export var hit_line_height_ratio: float = 0.84
@export var scroll_speed_px_per_sec: float = DEFAULT_BASE_SCROLL_SPEED_PX_PER_SEC
@export var pool_size: int = 64
@export var bottom_padding_px: float = 48.0
@export var despawn_past_hit_line_px: float = 220.0

var _chart: ChartData = null
var _base_scroll_speed_px_per_sec: float = DEFAULT_BASE_SCROLL_SPEED_PX_PER_SEC
var _speed_multiplier: int = MIN_SPEED_MULTIPLIER
var _speed_multiplier_configured: bool = false
var _hit_line_y: float = (DEFAULT_PLAY_HEIGHT * 0.84) - HIT_LINE_VERTICAL_LIFT_PX
var _lane_width: float = DEFAULT_PLAY_WIDTH / float(DEFAULT_LANE_COUNT)
var _current_dsp_time_sec: float = 0.0
var _visual_time_sec: float = 0.0
var _next_spawn_index: int = 0
var _free_pool: Array[NoteView] = []
var _active_views: Array[NoteView] = []
var _lane_pressed_states: Array[bool] = [false, false, false, false]
var _lane_hold_states: Array[bool] = [false, false, false, false]
var _touch_ripple_consumed_for_lane: Array[bool] = [false, false, false, false]
var _touch_ripples: Array[Dictionary] = []
var _hit_particles: Array[Dictionary] = []
var _hold_spark_accumulator_sec: float = 0.0
var _fx_seed_counter: int = 1
var _divider_beat_pulse: float = 0.0
var _divider_bass_energy: float = 0.0
var _divider_drop_intensity: float = 0.0
var _divider_prev_bass: float = 0.0
var _divider_shake_amp_px: float = 0.0
var _divider_shake_phase: float = 0.0
var _divider_shake_offset_x: float = 0.0
var _divider_tier: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _speed_multiplier_configured:
		_base_scroll_speed_px_per_sec = maxf(100.0, scroll_speed_px_per_sec)
	scroll_speed_px_per_sec = _base_scroll_speed_px_per_sec * float(_speed_multiplier)
	_ensure_pool()
	_connect_dependencies()

	if screen_safe_adapter != null:
		apply_safe_layout(
			screen_safe_adapter.get_play_rect(),
			screen_safe_adapter.get_hud_safe_rect()
		)
	else:
		queue_redraw()


func _process(p_delta: float) -> void:
	var dt: float = maxf(0.0, p_delta)
	var needs_redraw: bool = false

	if _chart != null and dsp_clock != null and dsp_clock.is_playing():
		_visual_time_sec = dsp_clock.get_visual_time_sec()
		_ensure_pool()
		_spawn_visible_notes(_visual_time_sec)
		_update_and_cull_active_views(_visual_time_sec)

	var any_holding: bool = false
	var lane_count: int = _get_active_lane_count()
	for lane_idx: int in range(mini(lane_count, _lane_hold_states.size())):
		if _lane_hold_states[lane_idx]:
			any_holding = true
			break

	if any_holding:
		_hold_spark_accumulator_sec += dt
		while _hold_spark_accumulator_sec >= HOLD_SPARK_INTERVAL_SEC:
			_hold_spark_accumulator_sec -= HOLD_SPARK_INTERVAL_SEC
			for lane_idx: int in range(mini(lane_count, _lane_hold_states.size())):
				if _lane_hold_states[lane_idx]:
					_spawn_hold_sparks(lane_idx, 2)
					needs_redraw = true
	else:
		_hold_spark_accumulator_sec = 0.0

	var ripple_idx: int = _touch_ripples.size() - 1
	while ripple_idx >= 0:
		var ripple: Dictionary = _touch_ripples[ripple_idx]
		var next_age: float = (ripple["age"] as float) + dt
		var duration: float = maxf(0.01, ripple["duration"] as float)
		if next_age >= duration:
			_touch_ripples.remove_at(ripple_idx)
		else:
			ripple["age"] = next_age
			_touch_ripples[ripple_idx] = ripple
		needs_redraw = true
		ripple_idx -= 1

	var particle_idx: int = _hit_particles.size() - 1
	while particle_idx >= 0:
		var particle: Dictionary = _hit_particles[particle_idx]
		var next_age: float = (particle["age"] as float) + dt
		var duration: float = maxf(0.01, particle["duration"] as float)
		if next_age >= duration:
			_hit_particles.remove_at(particle_idx)
		else:
			var pos: Vector2 = particle["pos"] as Vector2
			var vel: Vector2 = particle["vel"] as Vector2
			vel.y += PARTICLE_GRAVITY_PX_PER_SEC2 * dt
			pos += vel * dt
			particle["age"] = next_age
			particle["pos"] = pos
			particle["vel"] = vel
			_hit_particles[particle_idx] = particle
		needs_redraw = true
		particle_idx -= 1

	if _divider_beat_pulse > 0.002 or _divider_bass_energy > 0.002 or _divider_drop_intensity > 0.002 or _divider_shake_amp_px > 0.02:
		_divider_beat_pulse *= exp(-DIVIDER_GLOW_DECAY_RATE * dt)
		if _divider_beat_pulse < 0.002:
			_divider_beat_pulse = 0.0
		_divider_bass_energy = maxf(0.0, _divider_bass_energy - (5.5 * dt))
		_divider_drop_intensity *= exp(-DIVIDER_DROP_DECAY_RATE * dt)
		if _divider_drop_intensity < 0.002:
			_divider_drop_intensity = 0.0
		_divider_shake_amp_px *= exp(-DIVIDER_SHAKE_DECAY_RATE * dt)
		if _divider_shake_amp_px < 0.04:
			_divider_shake_amp_px = 0.0
			_divider_shake_offset_x = 0.0
		else:
			_divider_shake_phase += dt * DIVIDER_SHAKE_FREQ_RAD
			_divider_shake_offset_x = sin(_divider_shake_phase) * _divider_shake_amp_px
		needs_redraw = true

	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	var lane_count: int = _get_active_lane_count()
	var field_width: float = maxf(1.0, size.x)
	var field_height: float = maxf(1.0, size.y)
	var glow_boost: float = get_divider_glow_boost()

	for divider_idx: int in range(lane_count + 1):
		var x_pos: float = (float(divider_idx) * _lane_width) + _divider_shake_offset_x
		var is_outer: bool = divider_idx == 0 or divider_idx == lane_count
		_draw_reactive_lane_divider(x_pos, field_height, is_outer, glow_boost)

	var receptor_half_h: float = NoteView.DEFAULT_HEAD_HEIGHT_PX * 0.5
	var top_rail_y: float = _hit_line_y - receptor_half_h
	var bottom_rail_y: float = _hit_line_y + receptor_half_h

	_draw_glowing_horizontal_line(
		0.0,
		field_width,
		top_rail_y,
		RAIL_CONTINUOUS_CORE_COLOR,
		RAIL_CONTINUOUS_GLOW_COLOR,
		CONTINUOUS_CORE_THICKNESS,
		CONTINUOUS_GLOW_SCALE
	)
	_draw_glowing_horizontal_line(
		0.0,
		field_width,
		bottom_rail_y,
		RAIL_CONTINUOUS_CORE_COLOR,
		RAIL_CONTINUOUS_GLOW_COLOR,
		CONTINUOUS_CORE_THICKNESS,
		CONTINUOUS_GLOW_SCALE
	)

	for lane_idx: int in range(lane_count):
		var is_pressed: bool = lane_idx < _lane_pressed_states.size() and _lane_pressed_states[lane_idx]
		var is_holding: bool = lane_idx < _lane_hold_states.size() and _lane_hold_states[lane_idx]
		if not is_pressed and not is_holding:
			continue

		var lane_start_x: float = float(lane_idx) * _lane_width
		var lane_end_x: float = lane_start_x + _lane_width
		var active_core: Color = RAIL_HOLD_CORE_COLOR if is_holding else RAIL_PRESSED_CORE_COLOR
		var active_glow: Color = RAIL_HOLD_GLOW_COLOR if is_holding else RAIL_PRESSED_GLOW_COLOR
		var active_thickness: float = 3.4 if is_holding else 3.0
		var active_scale: float = 1.55 if is_holding else 1.40

		_draw_glowing_horizontal_line(
			lane_start_x,
			lane_end_x,
			top_rail_y,
			active_core,
			active_glow,
			active_thickness,
			active_scale
		)
		_draw_glowing_horizontal_line(
			lane_start_x,
			lane_end_x,
			bottom_rail_y,
			active_core,
			active_glow,
			active_thickness,
			active_scale
		)

	_draw_touch_ripples()
	_draw_hit_particles()


func _draw_touch_ripples() -> void:
	var ripple_count: int = _touch_ripples.size()
	for i: int in range(ripple_count):
		var ripple: Dictionary = _touch_ripples[i]
		var pos: Vector2 = ripple["pos"] as Vector2
		var age: float = ripple["age"] as float
		var duration: float = maxf(0.01, ripple["duration"] as float)
		var base_color: Color = ripple["color"] as Color
		var t: float = clampf(age / duration, 0.0, 1.0)
		var eased_t: float = 1.0 - pow(1.0 - t, 2.4)
		var radius: float = lerpf(RIPPLE_START_RADIUS_PX, RIPPLE_END_RADIUS_PX, eased_t)
		var alpha: float = (1.0 - t) * base_color.a
		var stroke_w: float = lerpf(4.2, 1.4, t)

		var halo_col: Color = Color(base_color.r, base_color.g, base_color.b, alpha * 0.34)
		var core_col: Color = Color(
			minf(1.0, base_color.r + 0.25),
			minf(1.0, base_color.g + 0.25),
			minf(1.0, base_color.b + 0.25),
			alpha
		)
		draw_arc(pos, radius, 0.0, TAU, 28, halo_col, stroke_w * 2.6)
		draw_arc(pos, radius, 0.0, TAU, 28, core_col, stroke_w)


func _draw_hit_particles() -> void:
	var particle_count: int = _hit_particles.size()
	for i: int in range(particle_count):
		var particle: Dictionary = _hit_particles[i]
		var pos: Vector2 = particle["pos"] as Vector2
		var vel: Vector2 = particle["vel"] as Vector2
		var age: float = particle["age"] as float
		var duration: float = maxf(0.01, particle["duration"] as float)
		var radius: float = particle["radius"] as float
		var base_color: Color = particle["color"] as Color
		var t: float = clampf(age / duration, 0.0, 1.0)
		var fade: float = 1.0 - (t * t)
		var curr_radius: float = maxf(1.2, radius * (1.0 - t * 0.55))

		var glow_col: Color = Color(base_color.r, base_color.g, base_color.b, fade * 0.32)
		var core_col: Color = Color(
			minf(1.0, base_color.r + 0.22),
			minf(1.0, base_color.g + 0.22),
			minf(1.0, base_color.b + 0.22),
			fade * base_color.a
		)
		var tail_offset: Vector2 = -vel * 0.024
		draw_circle(pos, curr_radius * 2.1, glow_col)
		draw_line(pos, pos + tail_offset, core_col, curr_radius * 1.15)
		draw_circle(pos, curr_radius, core_col)


func _draw_reactive_lane_divider(
	p_x: float,
	p_height: float,
	p_is_outer: bool,
	p_glow_boost: float
) -> void:
	var p_from: Vector2 = Vector2(p_x, 0.0)
	var p_to: Vector2 = Vector2(p_x, p_height)
	var base_core: Color = OUTER_BORDER_COLOR if p_is_outer else LANE_DIVIDER_COLOR
	var glow_tint: Color = LANE_DIVIDER_GLOW_COLOR.lerp(LANE_DIVIDER_DROP_COLOR, clampf(_divider_drop_intensity, 0.0, 1.0))

	# Soft multi-layer blur halo behind each lane divider line
	var halo_strength: float = clampf(0.42 + (p_glow_boost * 0.95), 0.35, 1.45)
	var outer_alpha: float = clampf(0.08 * halo_strength, 0.0, 0.28)
	var mid_alpha: float = clampf(0.14 * halo_strength, 0.0, 0.42)
	var inner_alpha: float = clampf(0.22 * halo_strength, 0.0, 0.56)

	var width_scale: float = 1.0 + (p_glow_boost * 0.45)
	draw_line(p_from, p_to, Color(glow_tint.r, glow_tint.g, glow_tint.b, outer_alpha), 15.0 * width_scale)
	draw_line(p_from, p_to, Color(glow_tint.r, glow_tint.g, glow_tint.b, mid_alpha), 8.0 * width_scale)
	draw_line(p_from, p_to, Color(glow_tint.r, glow_tint.g, glow_tint.b, inner_alpha), 4.0 * width_scale)

	# Crisp thin neon cyan divider stroke (~0.24 alpha at rest, brighter on beats & drops)
	var core_alpha: float = clampf(base_core.a + (p_glow_boost * 0.40), base_core.a, 0.78)
	var core_color: Color = Color(
		lerpf(base_core.r, 0.80, p_glow_boost * 0.45),
		lerpf(base_core.g, 0.98, p_glow_boost * 0.45),
		1.0,
		core_alpha
	)
	var core_width: float = (2.1 if p_is_outer else 1.6) + (p_glow_boost * 0.5)
	draw_line(p_from, p_to, core_color, core_width)


func _draw_glowing_horizontal_line(
	p_x_start: float,
	p_x_end: float,
	p_y: float,
	p_core_color: Color,
	p_glow_color: Color,
	p_core_thickness: float,
	p_glow_scale: float
) -> void:
	var p_from: Vector2 = Vector2(p_x_start, p_y)
	var p_to: Vector2 = Vector2(p_x_end, p_y)

	var outer_halo: Color = Color(p_glow_color.r, p_glow_color.g, p_glow_color.b, p_glow_color.a * 0.18)
	var mid_halo: Color = Color(p_glow_color.r, p_glow_color.g, p_glow_color.b, p_glow_color.a * 0.36)
	var inner_halo: Color = Color(p_glow_color.r, p_glow_color.g, p_glow_color.b, p_glow_color.a * 0.60)

	draw_line(p_from, p_to, outer_halo, p_core_thickness * 6.0 * p_glow_scale)
	draw_line(p_from, p_to, mid_halo, p_core_thickness * 3.5 * p_glow_scale)
	draw_line(p_from, p_to, inner_halo, p_core_thickness * 1.9 * p_glow_scale)
	draw_line(p_from, p_to, p_core_color, p_core_thickness)


func load_chart(p_chart: ChartData) -> bool:
	if p_chart == null:
		return false

	var validation: Dictionary = p_chart.validate()
	var is_valid: bool = validation.get("valid", false) as bool
	if not is_valid:
		return false

	if hit_judge != null:
		if not hit_judge.load_chart(p_chart):
			return false

	_ensure_pool()
	_recycle_all_active_views()
	_reset_lane_visual_states()
	_chart = p_chart
	_next_spawn_index = 0
	_visual_time_sec = dsp_clock.get_visual_time_sec() if dsp_clock != null else 0.0
	queue_redraw()
	return true


func apply_safe_layout(p_play_rect: Rect2, p_hud_safe_rect: Rect2) -> void:
	position = p_play_rect.position
	size = p_play_rect.size

	var lane_count: int = _get_active_lane_count()
	_lane_width = maxf(1.0, p_play_rect.size.x / float(lane_count))

	var max_hit_line_y: float = maxf(0.0, p_hud_safe_rect.end.y - bottom_padding_px - HIT_LINE_VERTICAL_LIFT_PX)
	var target_hit_line_y: float = (p_play_rect.size.y * hit_line_height_ratio) - HIT_LINE_VERTICAL_LIFT_PX
	_hit_line_y = clampf(target_hit_line_y, 0.0, max_hit_line_y)

	var active_count: int = _active_views.size()
	for i: int in range(active_count):
		var view: NoteView = _active_views[i]
		var note: NoteData = view.note_data
		if note != null:
			view.lane_width = _lane_width
			view.scroll_speed_px_per_sec = scroll_speed_px_per_sec
			view.set_speed_multiplier(_speed_multiplier)
			var is_holding: bool = hit_judge != null and hit_judge.is_note_actively_held(note)
			view.update_position(_visual_time_sec, _hit_line_y, is_holding)

	queue_redraw()


func update_field_at_time(p_dsp_time_sec: float) -> void:
	_current_dsp_time_sec = p_dsp_time_sec
	_visual_time_sec = p_dsp_time_sec

	if hit_judge != null:
		hit_judge.update_dsp_time(p_dsp_time_sec)

	if _chart == null:
		return

	_ensure_pool()
	_spawn_visible_notes(_visual_time_sec)
	_update_and_cull_active_views(_visual_time_sec)


func _on_dsp_time_updated(p_dsp_time_sec: float) -> void:
	_current_dsp_time_sec = p_dsp_time_sec
	if hit_judge != null:
		hit_judge.update_dsp_time(p_dsp_time_sec)


func set_speed_multiplier(p_multiplier: int) -> void:
	_speed_multiplier = clampi(p_multiplier, MIN_SPEED_MULTIPLIER, MAX_SPEED_MULTIPLIER)
	_speed_multiplier_configured = true
	scroll_speed_px_per_sec = maxf(100.0, _base_scroll_speed_px_per_sec) * float(_speed_multiplier)

	var active_count: int = _active_views.size()
	for i: int in range(active_count):
		var view: NoteView = _active_views[i]
		var note: NoteData = view.note_data
		if note != null:
			view.scroll_speed_px_per_sec = scroll_speed_px_per_sec
			view.set_speed_multiplier(_speed_multiplier)
			var is_holding: bool = hit_judge != null and hit_judge.is_note_actively_held(note)
			view.update_position(_visual_time_sec, _hit_line_y, is_holding)


func get_speed_multiplier() -> int:
	return _speed_multiplier


func get_effective_scroll_speed() -> float:
	return scroll_speed_px_per_sec


func get_hit_line_y() -> float:
	return _hit_line_y


func get_lane_width() -> float:
	return _lane_width


func get_active_note_views() -> Array[NoteView]:
	return _active_views


func get_free_pool_count() -> int:
	return _free_pool.size()


func get_active_ripple_count() -> int:
	return _touch_ripples.size()


func get_active_particle_count() -> int:
	return _hit_particles.size()


func get_divider_shake_offset_x() -> float:
	return _divider_shake_offset_x


func get_divider_shake_amplitude_px() -> float:
	return _divider_shake_amp_px


func get_divider_glow_boost() -> float:
	return clampf(
		(_divider_beat_pulse * 0.52) + (_divider_bass_energy * 0.28) + (_divider_drop_intensity * 0.55),
		0.0,
		1.0
	)


func inject_audio_pulse(p_bass_energy: float, p_drop_intensity: float, p_beat_pulsed: bool) -> void:
	_divider_bass_energy = clampf(maxf(_divider_bass_energy, p_bass_energy), 0.0, 1.0)
	_divider_drop_intensity = clampf(maxf(_divider_drop_intensity, p_drop_intensity), 0.0, 1.0)
	if p_beat_pulsed:
		_trigger_divider_beat_shake(clampf(maxf(p_bass_energy, p_drop_intensity), 0.35, 1.0))
	queue_redraw()


func _ensure_pool() -> void:
	var target_count: int = maxi(1, pool_size)
	var current_total: int = _free_pool.size() + _active_views.size()
	while current_total < target_count:
		var view: NoteView = NoteView.new()
		view.reset_for_pool()
		add_child(view)
		_free_pool.append(view)
		current_total += 1


func connect_dependencies() -> void:
	_connect_dependencies()


func _connect_dependencies() -> void:
	if screen_safe_adapter != null:
		if not screen_safe_adapter.safe_play_rect_changed.is_connected(apply_safe_layout):
			screen_safe_adapter.safe_play_rect_changed.connect(apply_safe_layout)

	if dsp_clock != null:
		if not dsp_clock.dsp_time_updated.is_connected(_on_dsp_time_updated):
			dsp_clock.dsp_time_updated.connect(_on_dsp_time_updated)
		if not dsp_clock.beat_pulsed.is_connected(_on_beat_pulsed):
			dsp_clock.beat_pulsed.connect(_on_beat_pulsed)
		if not dsp_clock.intensity_changed.is_connected(_on_intensity_changed):
			dsp_clock.intensity_changed.connect(_on_intensity_changed)

	if audio_analyzer != null:
		if not audio_analyzer.spectrum_updated.is_connected(_on_spectrum_updated):
			audio_analyzer.spectrum_updated.connect(_on_spectrum_updated)

	if input_adapter != null:
		if not input_adapter.touch_ripple_triggered.is_connected(_on_touch_ripple_triggered):
			input_adapter.touch_ripple_triggered.connect(_on_touch_ripple_triggered)
		if not input_adapter.lane_input_pressed.is_connected(_on_lane_input_pressed):
			input_adapter.lane_input_pressed.connect(_on_lane_input_pressed)
		if not input_adapter.lane_input_released.is_connected(_on_lane_input_released):
			input_adapter.lane_input_released.connect(_on_lane_input_released)

	if hit_judge != null:
		if not hit_judge.hold_state_changed.is_connected(_on_hold_state_changed):
			hit_judge.hold_state_changed.connect(_on_hold_state_changed)
		if not hit_judge.note_judged.is_connected(_on_note_judged):
			hit_judge.note_judged.connect(_on_note_judged)
		if not hit_judge.hold_combo_ticked.is_connected(_on_hold_combo_ticked):
			hit_judge.hold_combo_ticked.connect(_on_hold_combo_ticked)

	if input_adapter != null and hit_judge != null:
		if not input_adapter.lane_input_pressed.is_connected(hit_judge.on_lane_pressed):
			input_adapter.lane_input_pressed.connect(hit_judge.on_lane_pressed)
		if not input_adapter.lane_input_released.is_connected(hit_judge.on_lane_released):
			input_adapter.lane_input_released.connect(hit_judge.on_lane_released)


func _on_beat_pulsed(_p_beat_index: int, _p_beat_time_sec: float) -> void:
	var strength: float = clampf(0.45 + (_divider_bass_energy * 0.35) + (0.25 if _divider_tier >= 2 else 0.0), 0.40, 1.0)
	_trigger_divider_beat_shake(strength)


func _on_intensity_changed(p_block: IntensityBlock) -> void:
	if p_block == null:
		return
	_divider_tier = clampi(p_block.tier, IntensityBlock.MIN_TIER, IntensityBlock.MAX_TIER)
	if _divider_tier >= 2:
		_divider_drop_intensity = maxf(_divider_drop_intensity, clampf(p_block.energy, 0.65, 1.0))
		_trigger_divider_beat_shake(0.95)


func _on_spectrum_updated(
	p_bass_energy: float,
	_p_mid_energy: float,
	_p_high_energy: float,
	p_total_energy: float
) -> void:
	var bass: float = clampf(p_bass_energy, 0.0, 1.0)
	var total: float = clampf(p_total_energy, 0.0, 1.0)
	var bass_jump: float = bass - _divider_prev_bass
	_divider_prev_bass = bass
	_divider_bass_energy = maxf(_divider_bass_energy, bass)

	var is_drop: bool = (bass >= 0.72 and total >= 0.72) or (_divider_tier >= 2 and bass >= 0.55)
	if is_drop:
		_divider_drop_intensity = maxf(_divider_drop_intensity, clampf((bass * 0.55) + (total * 0.45), 0.70, 1.0))

	if bass_jump >= 0.14 or (bass >= 0.60 and bass_jump >= 0.06):
		var kick_strength: float = clampf((bass * 0.70) + (bass_jump * 0.60), 0.35, 1.0)
		_trigger_divider_beat_shake(kick_strength)


func _trigger_divider_beat_shake(p_strength: float) -> void:
	var s: float = clampf(p_strength, 0.0, 1.0)
	_divider_beat_pulse = maxf(_divider_beat_pulse, clampf(0.55 + (0.45 * s), 0.0, 1.0))
	var target_shake: float = lerpf(DIVIDER_SHAKE_BEAT_PX, DIVIDER_SHAKE_MAX_PX, maxf(s, _divider_drop_intensity))
	_divider_shake_amp_px = clampf(maxf(_divider_shake_amp_px, target_shake), 0.0, DIVIDER_SHAKE_MAX_PX)
	_divider_shake_phase += 1.45
	_divider_shake_offset_x = sin(_divider_shake_phase) * _divider_shake_amp_px
	queue_redraw()


func _on_touch_ripple_triggered(p_local_pos: Vector2, p_lane: int) -> void:
	if p_lane >= 0 and p_lane < _touch_ripple_consumed_for_lane.size():
		_touch_ripple_consumed_for_lane[p_lane] = true
	var clamped_pos: Vector2 = Vector2(
		clampf(p_local_pos.x, 0.0, maxf(1.0, size.x)),
		clampf(p_local_pos.y, 0.0, maxf(1.0, size.y))
	)
	_spawn_touch_ripple(clamped_pos, COLOR_TOUCH_RIPPLE)


func _on_lane_input_pressed(p_lane: int, _p_dsp_time_sec: float) -> void:
	if p_lane < 0 or p_lane >= _lane_pressed_states.size():
		return

	if _touch_ripple_consumed_for_lane[p_lane]:
		_touch_ripple_consumed_for_lane[p_lane] = false
	else:
		var lane_center_x: float = (float(p_lane) + 0.5) * _lane_width
		_spawn_touch_ripple(Vector2(lane_center_x, _hit_line_y), COLOR_TOUCH_RIPPLE)

	if not _lane_pressed_states[p_lane]:
		_lane_pressed_states[p_lane] = true
		queue_redraw()


func _on_lane_input_released(p_lane: int, _p_dsp_time_sec: float) -> void:
	if p_lane < 0 or p_lane >= _lane_pressed_states.size():
		return
	_touch_ripple_consumed_for_lane[p_lane] = false
	if _lane_pressed_states[p_lane]:
		_lane_pressed_states[p_lane] = false
		queue_redraw()


func _on_hold_state_changed(p_lane: int, p_is_holding: bool) -> void:
	if p_lane < 0 or p_lane >= _lane_hold_states.size():
		return
	if _lane_hold_states[p_lane] != p_is_holding:
		_lane_hold_states[p_lane] = p_is_holding
		if p_is_holding:
			_spawn_hold_sparks(p_lane, 4)
		queue_redraw()


func _on_note_judged(p_lane: int, p_grade: int, _p_error_ms: float, _p_combo: int) -> void:
	if p_lane < 0 or p_lane >= _get_active_lane_count():
		return
	_spawn_judgment_particles(p_lane, p_grade)


func _on_hold_combo_ticked(p_lane: int, _p_new_combo: int) -> void:
	if p_lane < 0 or p_lane >= _get_active_lane_count():
		return
	_spawn_hold_sparks(p_lane, HOLD_TICK_SPARK_COUNT)


func _spawn_touch_ripple(p_pos: Vector2, p_color: Color) -> void:
	if _touch_ripples.size() >= MAX_ACTIVE_RIPPLES:
		_touch_ripples.remove_at(0)

	_touch_ripples.append({
		"pos": p_pos,
		"age": 0.0,
		"duration": RIPPLE_DURATION_SEC,
		"color": p_color,
	})
	queue_redraw()


func _spawn_judgment_particles(p_lane: int, p_grade: int) -> void:
	var count: int = 0
	var min_speed: float = 0.0
	var max_speed: float = 0.0
	var min_radius: float = 3.0
	var max_radius: float = 5.0
	var duration_sec: float = 0.25

	match p_grade:
		HitJudge.JudgmentGrade.PERFECT:
			count = PERFECT_PARTICLE_COUNT
			min_speed = 230.0
			max_speed = 460.0
			min_radius = 5.2
			max_radius = 8.4
			duration_sec = 0.36
		HitJudge.JudgmentGrade.GREAT:
			count = GREAT_PARTICLE_COUNT
			min_speed = 155.0
			max_speed = 310.0
			min_radius = 4.2
			max_radius = 6.4
			duration_sec = 0.29
		HitJudge.JudgmentGrade.GOOD:
			count = GOOD_PARTICLE_COUNT
			min_speed = 95.0
			max_speed = 190.0
			min_radius = 3.2
			max_radius = 4.8
			duration_sec = 0.22
		_:
			return

	var origin: Vector2 = Vector2((float(p_lane) + 0.5) * _lane_width, _hit_line_y)
	if p_grade == HitJudge.JudgmentGrade.PERFECT:
		_spawn_touch_ripple(origin, COLOR_PERFECT_B)

	for i: int in range(count):
		_fx_seed_counter += 1
		var angle_norm: float = float(i) / float(maxi(1, count))
		var jitter: float = _pseudo_rand_signed(_fx_seed_counter + i * 17) * 0.28
		var angle_rad: float = lerpf(-PI * 0.92, -PI * 0.08, angle_norm) + jitter
		var speed_ratio: float = 0.5 + 0.5 * _pseudo_rand_signed(_fx_seed_counter * 13 + i * 31)
		var speed: float = lerpf(min_speed, max_speed, speed_ratio)
		var vel: Vector2 = Vector2(cos(angle_rad), sin(angle_rad)) * speed
		var radius: float = lerpf(min_radius, max_radius, speed_ratio)

		var col: Color = COLOR_GOOD_A
		if p_grade == HitJudge.JudgmentGrade.PERFECT:
			var mod3: int = i % 3
			if mod3 == 0:
				col = COLOR_PERFECT_A
			elif mod3 == 1:
				col = COLOR_PERFECT_B
			else:
				col = COLOR_PERFECT_C
		elif p_grade == HitJudge.JudgmentGrade.GREAT:
			col = COLOR_GREAT_A if (i % 2) == 0 else COLOR_GREAT_B

		_append_particle(origin, vel, radius, duration_sec, col)

	queue_redraw()


func _spawn_hold_sparks(p_lane: int, p_count: int) -> void:
	var origin: Vector2 = Vector2((float(p_lane) + 0.5) * _lane_width, _hit_line_y)
	for i: int in range(p_count):
		_fx_seed_counter += 1
		var spread: float = _pseudo_rand_signed(_fx_seed_counter * 19 + i * 23)
		var angle_rad: float = (-PI * 0.5) + (spread * PI * 0.36)
		var speed_t: float = 0.5 + 0.5 * _pseudo_rand_signed(_fx_seed_counter * 29 + i * 7)
		var speed: float = lerpf(135.0, 290.0, speed_t)
		var vel: Vector2 = Vector2(cos(angle_rad), sin(angle_rad)) * speed
		var radius: float = lerpf(3.4, 5.8, speed_t)
		var col: Color = COLOR_HOLD_SPARK if (i % 2) == 0 else COLOR_PERFECT_B
		_append_particle(origin, vel, radius, 0.24, col)

	queue_redraw()


func _append_particle(
	p_pos: Vector2,
	p_vel: Vector2,
	p_radius: float,
	p_duration: float,
	p_color: Color
) -> void:
	if _hit_particles.size() >= MAX_ACTIVE_PARTICLES:
		_hit_particles.remove_at(0)

	_hit_particles.append({
		"pos": p_pos,
		"vel": p_vel,
		"age": 0.0,
		"duration": p_duration,
		"radius": p_radius,
		"color": p_color,
	})


func _pseudo_rand_signed(p_seed: int) -> float:
	var h: int = (p_seed * 1103515245 + 12345) & 0x7fffffff
	return (float(h % 2000) / 1000.0) - 1.0


func _get_active_lane_count() -> int:
	if screen_safe_adapter != null:
		return maxi(1, screen_safe_adapter.lane_count)
	return DEFAULT_LANE_COUNT


func _reset_lane_visual_states() -> void:
	for i: int in range(_lane_pressed_states.size()):
		_lane_pressed_states[i] = false
	for j: int in range(_lane_hold_states.size()):
		_lane_hold_states[j] = false
	for k: int in range(_touch_ripple_consumed_for_lane.size()):
		_touch_ripple_consumed_for_lane[k] = false
	_touch_ripples.clear()
	_hit_particles.clear()
	_hold_spark_accumulator_sec = 0.0
	_divider_beat_pulse = 0.0
	_divider_bass_energy = 0.0
	_divider_drop_intensity = 0.0
	_divider_prev_bass = 0.0
	_divider_shake_amp_px = 0.0
	_divider_shake_offset_x = 0.0
	_divider_tier = 0


func _spawn_visible_notes(p_dsp_time_sec: float) -> void:
	var safe_speed: float = maxf(1.0, scroll_speed_px_per_sec)
	var lookahead_sec: float = (_hit_line_y + TOP_SPAWN_MARGIN_PX) / safe_speed
	var max_spawn_time_sec: float = p_dsp_time_sec + lookahead_sec

	var notes: Array[NoteData] = _chart.notes
	var note_count: int = notes.size()
	while _next_spawn_index < note_count:
		var candidate: NoteData = notes[_next_spawn_index]
		if candidate == null:
			_next_spawn_index += 1
			continue

		if candidate.time_sec > max_spawn_time_sec:
			break

		_next_spawn_index += 1

		if hit_judge != null and hit_judge.is_note_resolved(candidate):
			continue

		var tail_end_sec: float = candidate.time_sec + maxf(0.0, candidate.duration_sec)
		var tail_y: float = _hit_line_y - (tail_end_sec - p_dsp_time_sec) * safe_speed
		if tail_y > _hit_line_y + despawn_past_hit_line_px:
			continue

		var view: NoteView = _acquire_note_view()
		view.setup(candidate, _lane_width, safe_speed, _speed_multiplier)
		var is_holding: bool = hit_judge != null and hit_judge.is_note_actively_held(candidate)
		view.update_position(p_dsp_time_sec, _hit_line_y, is_holding)
		_active_views.append(view)


func _update_and_cull_active_views(p_dsp_time_sec: float) -> void:
	var safe_speed: float = maxf(1.0, scroll_speed_px_per_sec)
	var i: int = _active_views.size() - 1
	while i >= 0:
		var view: NoteView = _active_views[i]
		var note: NoteData = view.note_data
		if note == null:
			_recycle_view_at_index(i)
			i -= 1
			continue

		var is_holding: bool = hit_judge != null and hit_judge.is_note_actively_held(note)
		var is_resolved: bool = hit_judge != null and hit_judge.is_note_resolved(note)
		var tail_end_sec: float = note.time_sec + maxf(0.0, note.duration_sec)
		var tail_y: float = _hit_line_y - (tail_end_sec - p_dsp_time_sec) * safe_speed

		if (is_resolved and not is_holding) or tail_y > _hit_line_y + despawn_past_hit_line_px:
			_recycle_view_at_index(i)
		else:
			view.update_position(p_dsp_time_sec, _hit_line_y, is_holding)

		i -= 1


func _acquire_note_view() -> NoteView:
	if _free_pool.is_empty():
		var extra_view: NoteView = NoteView.new()
		extra_view.reset_for_pool()
		add_child(extra_view)
		return extra_view

	var view: NoteView = _free_pool.pop_back()
	return view


func _recycle_view_at_index(p_active_index: int) -> void:
	var view: NoteView = _active_views[p_active_index]
	_active_views.remove_at(p_active_index)
	view.reset_for_pool()
	_free_pool.append(view)


func _recycle_all_active_views() -> void:
	var i: int = _active_views.size() - 1
	while i >= 0:
		_recycle_view_at_index(i)
		i -= 1
