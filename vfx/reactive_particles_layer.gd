class_name ReactiveParticlesLayer
extends Control

const BEAT_DECAY_RATE: float = 5.5
const BEAT_EPSILON: float = 0.002
const AUDIO_ENERGY_LERP_SPEED: float = 8.0
const AUDIO_TARGET_DECAY_SPEED: float = 4.0
const MAX_EFFECTIVE_DRIVE: float = 1.65

const CIRCLE_SPEED_BEAT_BOOST: float = 1.15
const CIRCLE_MIN_RADIUS_PX: float = 1.2
const CIRCLE_MAX_RADIUS_PX: float = 3.8
const CIRCLE_FADE_IN_END: float = 0.14
const CIRCLE_EDGE_FADE_START: float = 0.72
const CIRCLE_BASE_HALO_SCALE: float = 2.3
const CIRCLE_BEAT_HALO_BOOST: float = 1.75
const SQUARE_SCALE_BEAT_BOOST: float = 0.28
const DEFAULT_VIEWPORT_SIZE: Vector2 = Vector2(1080.0, 1920.0)

const CIRCLE_PALETTE: Array[Color] = [
	Color(0.42, 0.94, 1.0, 1.0),
	Color(0.68, 0.96, 1.0, 1.0),
	Color(0.46, 0.74, 1.0, 1.0),
	Color(0.74, 0.58, 1.0, 1.0),
]

const SQUARE_PALETTE: Array[Color] = [
	Color(0.32, 0.96, 1.0, 1.0),
	Color(0.38, 0.68, 1.0, 1.0),
	Color(0.84, 0.42, 1.0, 1.0),
	Color(0.34, 1.0, 0.84, 1.0),
]

@export var dsp_clock: DSPClock = null
@export var reactive_background: ReactiveBackground = null
@export var audio_analyzer: AudioAnalyzer = null

var _config: ReactiveParticlesConfig = ReactiveParticlesConfig.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _elapsed_time: float = 0.0
var _beat_impulse: float = 0.0
var _target_audio_energy: float = 0.0
var _smoothed_audio_energy: float = 0.0
var _current_drive: float = 0.0
var _current_speed_mult: float = 1.0
var _current_scale_mult: float = 1.0
var _audio_active: bool = true
var _beat_trigger_count: int = 0
var _needs_clear_draw: bool = false

# Pre-allocated typed parallel arrays (0 heap allocations per frame)
var _active_count: int = 0
var _pos: PackedVector2Array = PackedVector2Array()
var _vel: PackedVector2Array = PackedVector2Array()
var _size_param: PackedFloat32Array = PackedFloat32Array()
var _angle: PackedFloat32Array = PackedFloat32Array()
var _ang_vel: PackedFloat32Array = PackedFloat32Array()
var _alpha_base: PackedFloat32Array = PackedFloat32Array()
var _life_phase: PackedFloat32Array = PackedFloat32Array()
var _life_speed: PackedFloat32Array = PackedFloat32Array()
var _sway_phase: PackedFloat32Array = PackedFloat32Array()
var _sway_freq: PackedFloat32Array = PackedFloat32Array()
var _sway_amp: PackedFloat32Array = PackedFloat32Array()
var _color_idx: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	connect_dependencies()
	_rebuild_pool()


func connect_dependencies() -> void:
	if dsp_clock != null:
		if not dsp_clock.beat_pulsed.is_connected(_on_dsp_beat_pulsed):
			dsp_clock.beat_pulsed.connect(_on_dsp_beat_pulsed)

	if reactive_background != null:
		if not reactive_background.bass_kick_pulsed.is_connected(_on_bass_kick_pulsed):
			reactive_background.bass_kick_pulsed.connect(_on_bass_kick_pulsed)

	if audio_analyzer != null:
		if not audio_analyzer.spectrum_updated.is_connected(_on_spectrum_updated):
			audio_analyzer.spectrum_updated.connect(_on_spectrum_updated)


func apply_config(p_config: ReactiveParticlesConfig) -> void:
	if p_config == null:
		_config.reset_to_defaults()
	else:
		_config.copy_from(p_config)
	_rebuild_pool()


func get_config_snapshot() -> ReactiveParticlesConfig:
	return _config.duplicate_config()


func set_audio_active(p_active: bool) -> void:
	_audio_active = p_active
	if not _audio_active:
		_target_audio_energy = 0.0


func is_effectively_active() -> bool:
	return _config.is_rendered_in_phase7a()


func get_active_particle_count() -> int:
	return _active_count


func get_beat_impulse() -> float:
	return _beat_impulse


func get_beat_trigger_count() -> int:
	return _beat_trigger_count


func get_current_drive() -> float:
	return _current_drive


func get_current_speed_multiplier() -> float:
	return _current_speed_mult


func get_current_scale_multiplier() -> float:
	return _current_scale_mult


func get_particle_positions_snapshot() -> PackedVector2Array:
	return _pos.duplicate()


func get_particle_angles_snapshot() -> PackedFloat32Array:
	return _angle.duplicate()


func get_particle_life_phases_snapshot() -> PackedFloat32Array:
	return _life_phase.duplicate()


func get_circle_halo_scale() -> float:
	return CIRCLE_BASE_HALO_SCALE + (_current_drive * CIRCLE_BEAT_HALO_BOOST)


func get_circle_halo_alpha_factor() -> float:
	return clampf(0.24 + (_current_drive * 0.22), 0.0, 0.56)


func get_circle_effective_radius(p_index: int) -> float:
	if p_index < 0 or p_index >= _active_count:
		return 0.0
	var bounds: Vector2 = _resolve_bounds()
	var edge_norm: float = _compute_rect_edge_norm(_pos[p_index], bounds)
	var depth_t: float = clampf(edge_norm, 0.0, 1.0)
	var max_r: float = clampf(_size_param[p_index], CIRCLE_MIN_RADIUS_PX, CIRCLE_MAX_RADIUS_PX)
	return clampf(lerpf(CIRCLE_MIN_RADIUS_PX, max_r, depth_t), CIRCLE_MIN_RADIUS_PX, CIRCLE_MAX_RADIUS_PX)


func compute_circle_edge_fade(p_pos: Vector2, p_bounds: Vector2 = Vector2.ZERO) -> float:
	var bounds: Vector2 = p_bounds if (p_bounds.x > 1.0 and p_bounds.y > 1.0) else _resolve_bounds()
	var edge_norm: float = _compute_rect_edge_norm(p_pos, bounds)
	return 1.0 - smoothstep(CIRCLE_EDGE_FADE_START, 1.0, edge_norm)


func get_circle_effective_alpha(p_index: int) -> float:
	if p_index < 0 or p_index >= _active_count:
		return 0.0
	var bounds: Vector2 = _resolve_bounds()
	var edge_norm: float = _compute_rect_edge_norm(_pos[p_index], bounds)
	var spawn_fade: float = clampf(_life_phase[p_index], 0.0, 1.0)
	var center_fade: float = smoothstep(0.02, CIRCLE_FADE_IN_END, edge_norm)
	var in_fade: float = minf(spawn_fade, center_fade)
	var edge_fade: float = 1.0 - smoothstep(CIRCLE_EDGE_FADE_START, 1.0, edge_norm)
	var alpha_boost: float = minf(0.14, _current_drive * 0.10)
	return clampf((_alpha_base[p_index] + alpha_boost) * in_fade * edge_fade, 0.0, 0.72)


func trigger_beat_impulse(p_strength: float = 0.85) -> void:
	var clamped: float = clampf(p_strength, 0.0, 1.0)
	if clamped <= 0.0:
		return
	_beat_impulse = maxf(_beat_impulse, clamped)
	_beat_trigger_count += 1
	_recompute_drive_metrics()


func inject_audio_energy(p_energy: float) -> void:
	_target_audio_energy = clampf(p_energy, 0.0, 1.0)


func _process(p_delta: float) -> void:
	step_simulation(p_delta)


func step_simulation(p_delta: float) -> void:
	var dt: float = clampf(p_delta, 0.0, 0.1)
	_elapsed_time += dt

	_beat_impulse *= exp(-BEAT_DECAY_RATE * dt)
	if _beat_impulse < BEAT_EPSILON:
		_beat_impulse = 0.0

	var energy_target: float = _target_audio_energy if _audio_active else 0.0
	_smoothed_audio_energy = lerpf(
		_smoothed_audio_energy,
		energy_target,
		clampf(AUDIO_ENERGY_LERP_SPEED * dt, 0.0, 1.0)
	)
	if _smoothed_audio_energy < BEAT_EPSILON and energy_target <= 0.0:
		_smoothed_audio_energy = 0.0
	_target_audio_energy = maxf(0.0, _target_audio_energy - (AUDIO_TARGET_DECAY_SPEED * dt))

	_recompute_drive_metrics()

	if not is_effectively_active() or _active_count <= 0:
		if _needs_clear_draw:
			_needs_clear_draw = false
			queue_redraw()
		return

	var bounds: Vector2 = _resolve_bounds()
	if _config.particle_type == ReactiveParticlesConfig.TYPE_CIRCLES:
		_step_circles(dt, bounds)
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_SQUARES:
		_step_squares(dt, bounds)

	queue_redraw()


func _draw() -> void:
	if not is_effectively_active() or _active_count <= 0:
		return

	if _config.particle_type == ReactiveParticlesConfig.TYPE_CIRCLES:
		_draw_circles()
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_SQUARES:
		_draw_squares()


func _recompute_drive_metrics() -> void:
	var reactivity_mult: float = _config.get_reactivity_multiplier()
	_current_drive = clampf(
		((_beat_impulse * 0.85) + (_smoothed_audio_energy * 0.25)) * reactivity_mult,
		0.0,
		MAX_EFFECTIVE_DRIVE
	)
	_current_speed_mult = 1.0 + (_current_drive * CIRCLE_SPEED_BEAT_BOOST)
	_current_scale_mult = 1.0 + (_current_drive * SQUARE_SCALE_BEAT_BOOST)


func _rebuild_pool() -> void:
	if not is_effectively_active():
		_active_count = 0
		_resize_arrays(0)
		_needs_clear_draw = true
		queue_redraw()
		return

	var target_count: int = _config.get_max_particle_count()
	_active_count = target_count
	_resize_arrays(target_count)

	var bounds: Vector2 = _resolve_bounds()
	for i: int in range(target_count):
		if _config.particle_type == ReactiveParticlesConfig.TYPE_CIRCLES:
			_spawn_circle(i, bounds, true)
		elif _config.particle_type == ReactiveParticlesConfig.TYPE_SQUARES:
			_spawn_square(i, bounds, true)

	_needs_clear_draw = false
	queue_redraw()


func _resize_arrays(p_count: int) -> void:
	_pos.resize(p_count)
	_vel.resize(p_count)
	_size_param.resize(p_count)
	_angle.resize(p_count)
	_ang_vel.resize(p_count)
	_alpha_base.resize(p_count)
	_life_phase.resize(p_count)
	_life_speed.resize(p_count)
	_sway_phase.resize(p_count)
	_sway_freq.resize(p_count)
	_sway_amp.resize(p_count)
	_color_idx.resize(p_count)


func _spawn_circle(p_index: int, p_bounds: Vector2, p_initial_fill: bool) -> void:
	var center: Vector2 = p_bounds * 0.5
	var half_w: float = maxf(1.0, p_bounds.x * 0.5)
	var half_h: float = maxf(1.0, p_bounds.y * 0.5)
	var theta: float = _rng.randf_range(0.0, TAU)
	var radial_dir: Vector2 = Vector2(cos(theta), sin(theta))

	var ray_edge_dist: float = _compute_ray_edge_distance(radial_dir, half_w, half_h)
	var norm_dist: float = _rng.randf_range(0.06, 0.92) if p_initial_fill else _rng.randf_range(0.02, 0.09)
	var start_pos: Vector2 = center + (radial_dir * (ray_edge_dist * norm_dist))

	var base_speed: float = _rng.randf_range(58.0, 128.0)
	var max_radius: float = _rng.randf_range(1.9, CIRCLE_MAX_RADIUS_PX)

	_pos[p_index] = start_pos
	_vel[p_index] = radial_dir * base_speed
	_size_param[p_index] = max_radius
	_angle[p_index] = theta
	_ang_vel[p_index] = base_speed
	_alpha_base[p_index] = _rng.randf_range(0.28, 0.56)
	_life_phase[p_index] = 1.0 if p_initial_fill else 0.0
	_life_speed[p_index] = _rng.randf_range(1.6, 2.6)
	_sway_phase[p_index] = 0.0
	_sway_freq[p_index] = 0.0
	_sway_amp[p_index] = 0.0
	_color_idx[p_index] = _rng.randi_range(0, CIRCLE_PALETTE.size() - 1)


func _spawn_square(p_index: int, p_bounds: Vector2, p_initial_fill: bool) -> void:
	var half_extent: float = _rng.randf_range(7.0, 22.0)
	var pad_x: float = half_extent * 1.5
	var pad_y: float = half_extent * 1.5
	var min_x: float = minf(pad_x, p_bounds.x * 0.25)
	var max_x: float = maxf(min_x + 1.0, p_bounds.x - pad_x)
	var min_y: float = minf(pad_y, p_bounds.y * 0.25)
	var max_y: float = maxf(min_y + 1.0, p_bounds.y - pad_y)

	_pos[p_index] = Vector2(
		_rng.randf_range(min_x, max_x),
		_rng.randf_range(min_y, max_y)
	)
	_vel[p_index] = Vector2(
		_rng.randf_range(-22.0, 22.0),
		_rng.randf_range(-34.0, 18.0)
	)
	_size_param[p_index] = half_extent
	_angle[p_index] = _rng.randf_range(0.0, TAU)
	var spin_dir: float = -1.0 if _rng.randf() < 0.5 else 1.0
	_ang_vel[p_index] = spin_dir * _rng.randf_range(0.18, 0.65)
	_alpha_base[p_index] = _rng.randf_range(0.30, 0.60)
	_life_phase[p_index] = _rng.randf() if p_initial_fill else 0.0
	_life_speed[p_index] = _rng.randf_range(0.14, 0.30)
	_sway_phase[p_index] = _rng.randf_range(0.0, TAU)
	_sway_freq[p_index] = _rng.randf_range(0.45, 1.15)
	_sway_amp[p_index] = _rng.randf_range(6.0, 16.0)
	_color_idx[p_index] = _rng.randi_range(0, SQUARE_PALETTE.size() - 1)


func _step_circles(p_dt: float, p_bounds: Vector2) -> void:
	var center: Vector2 = p_bounds * 0.5
	var speed_mult: float = _current_speed_mult

	for i: int in range(_active_count):
		var pos: Vector2 = _pos[i]
		var offset: Vector2 = pos - center
		var radial_dir: Vector2 = offset.normalized() if offset.length_squared() > 0.01 else _vel[i].normalized()
		if radial_dir.length_squared() <= 0.01:
			radial_dir = Vector2(cos(_angle[i]), sin(_angle[i]))

		var edge_norm: float = _compute_rect_edge_norm(pos, p_bounds)
		var depth_accel: float = 0.45 + (1.85 * pow(clampf(edge_norm, 0.0, 1.2), 1.35))
		var base_speed: float = maxf(24.0, _ang_vel[i])

		pos += radial_dir * (base_speed * depth_accel * speed_mult) * p_dt
		_life_phase[i] = minf(1.0, _life_phase[i] + (_life_speed[i] * p_dt))

		var next_edge_norm: float = _compute_rect_edge_norm(pos, p_bounds)
		if next_edge_norm >= 1.02:
			_spawn_circle(i, p_bounds, false)
		else:
			_pos[i] = pos


func _step_squares(p_dt: float, p_bounds: Vector2) -> void:
	var drift_boost: float = 1.0 + (_current_drive * 0.30)
	var spin_boost: float = 1.0 + (_current_drive * 0.35)

	for i: int in range(_active_count):
		var phase: float = _life_phase[i] + (_life_speed[i] * p_dt)
		if phase >= 1.0:
			_spawn_square(i, p_bounds, false)
			continue
		_life_phase[i] = phase

		var pos: Vector2 = _pos[i]
		var vel: Vector2 = _vel[i]
		var half_extent: float = _size_param[i]
		var sway_x: float = cos((_elapsed_time * _sway_freq[i]) + _sway_phase[i]) * _sway_amp[i]

		pos.x += (vel.x + sway_x) * drift_boost * p_dt
		pos.y += vel.y * drift_boost * p_dt

		var margin: float = half_extent * 2.5
		if pos.x < -margin:
			pos.x = p_bounds.x + margin
		elif pos.x > p_bounds.x + margin:
			pos.x = -margin

		if pos.y < -margin:
			pos.y = p_bounds.y + margin
		elif pos.y > p_bounds.y + margin:
			pos.y = -margin

		_pos[i] = pos
		_angle[i] = wrapf(_angle[i] + (_ang_vel[i] * spin_boost * p_dt), 0.0, TAU)


func _draw_circles() -> void:
	var bounds: Vector2 = _resolve_bounds()
	var halo_scale: float = get_circle_halo_scale()
	var halo_alpha_factor: float = get_circle_halo_alpha_factor()
	var alpha_boost: float = minf(0.14, _current_drive * 0.10)
	var palette_len: int = CIRCLE_PALETTE.size()

	for i: int in range(_active_count):
		var pos: Vector2 = _pos[i]
		var edge_norm: float = _compute_rect_edge_norm(pos, bounds)
		var spawn_fade: float = clampf(_life_phase[i], 0.0, 1.0)
		var center_fade: float = smoothstep(0.02, CIRCLE_FADE_IN_END, edge_norm)
		var in_fade: float = minf(spawn_fade, center_fade)
		var edge_fade: float = 1.0 - smoothstep(CIRCLE_EDGE_FADE_START, 1.0, edge_norm)
		var core_alpha: float = clampf((_alpha_base[i] + alpha_boost) * in_fade * edge_fade, 0.0, 0.72)
		if core_alpha <= 0.005:
			continue

		var max_r: float = clampf(_size_param[i], CIRCLE_MIN_RADIUS_PX, CIRCLE_MAX_RADIUS_PX)
		var radius: float = clampf(
			lerpf(CIRCLE_MIN_RADIUS_PX, max_r, clampf(edge_norm, 0.0, 1.0)),
			CIRCLE_MIN_RADIUS_PX,
			CIRCLE_MAX_RADIUS_PX
		)
		var base_col: Color = CIRCLE_PALETTE[_color_idx[i] % palette_len]

		var outer_blur_col: Color = Color(base_col.r, base_col.g, base_col.b, core_alpha * halo_alpha_factor * 0.42)
		var inner_blur_col: Color = Color(base_col.r, base_col.g, base_col.b, core_alpha * halo_alpha_factor)
		var core_col: Color = Color(base_col.r, base_col.g, base_col.b, core_alpha)

		draw_circle(pos, radius * halo_scale * 1.45, outer_blur_col)
		draw_circle(pos, radius * halo_scale, inner_blur_col)
		draw_circle(pos, radius, core_col)


func _compute_rect_edge_norm(p_pos: Vector2, p_bounds: Vector2) -> float:
	var half_w: float = maxf(1.0, p_bounds.x * 0.5)
	var half_h: float = maxf(1.0, p_bounds.y * 0.5)
	var nx: float = absf(p_pos.x - half_w) / half_w
	var ny: float = absf(p_pos.y - half_h) / half_h
	return maxf(nx, ny)


func _compute_ray_edge_distance(p_dir: Vector2, p_half_w: float, p_half_h: float) -> float:
	var abs_x: float = absf(p_dir.x)
	var abs_y: float = absf(p_dir.y)
	var tx: float = (p_half_w / abs_x) if abs_x > 0.0001 else 1e9
	var ty: float = (p_half_h / abs_y) if abs_y > 0.0001 else 1e9
	return minf(tx, ty)


func _draw_squares() -> void:
	var scale_mult: float = _current_scale_mult
	var scale_vec: Vector2 = Vector2(scale_mult, scale_mult)
	var palette_len: int = SQUARE_PALETTE.size()

	for i: int in range(_active_count):
		var life_t: float = clampf(_life_phase[i], 0.0, 1.0)
		var fade_raw: float = sin(life_t * PI)
		if fade_raw <= 0.008:
			continue

		var fade: float = pow(fade_raw, 1.2)
		var half_extent: float = _size_param[i]
		var base_col: Color = SQUARE_PALETTE[_color_idx[i] % palette_len]
		var alpha: float = clampf(_alpha_base[i] * fade, 0.0, 0.64)

		var fill_col: Color = Color(base_col.r, base_col.g, base_col.b, alpha * 0.28)
		var glow_col: Color = Color(base_col.r, base_col.g, base_col.b, alpha * 0.26)
		var edge_col: Color = Color(base_col.r, base_col.g, base_col.b, minf(0.72, alpha * 1.05))
		var sq_rect: Rect2 = Rect2(-half_extent, -half_extent, half_extent * 2.0, half_extent * 2.0)

		draw_set_transform(_pos[i], _angle[i], scale_vec)
		draw_rect(sq_rect, fill_col, true)
		draw_rect(sq_rect, glow_col, false, 5.0)
		draw_rect(sq_rect, edge_col, false, 2.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _resolve_bounds() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	var vp_rect: Rect2 = get_viewport_rect()
	if vp_rect.size.x > 1.0 and vp_rect.size.y > 1.0:
		return vp_rect.size
	return DEFAULT_VIEWPORT_SIZE


func _on_dsp_beat_pulsed(_p_beat_index: int, _p_beat_time_sec: float) -> void:
	trigger_beat_impulse(0.82)


func _on_bass_kick_pulsed(p_strength: float) -> void:
	trigger_beat_impulse(p_strength)


func _on_spectrum_updated(
	p_bass_energy: float,
	_p_mid_energy: float,
	_p_high_energy: float,
	p_total_energy: float
) -> void:
	if not _audio_active:
		return
	var combined: float = clampf(
		(clampf(p_bass_energy, 0.0, 1.0) * 0.65) + (clampf(p_total_energy, 0.0, 1.0) * 0.35),
		0.0,
		1.0
	)
	_target_audio_energy = maxf(_target_audio_energy * 0.65, combined)
