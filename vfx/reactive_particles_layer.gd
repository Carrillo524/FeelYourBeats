class_name ReactiveParticlesLayer
extends Control

const BEAT_DECAY_RATE: float = 5.5
const SUSTAINED_ATTACK_SPEED: float = 5.5
const SUSTAINED_DECAY_RATE: float = 1.35
const BEAT_EPSILON: float = 0.002
const AUDIO_ENERGY_LERP_SPEED: float = 8.0
const AUDIO_TARGET_DECAY_SPEED: float = 3.2
const MAX_EFFECTIVE_DRIVE: float = 2.20

const CIRCLE_SPEED_BEAT_BOOST: float = 1.15
const CIRCLE_MIN_RADIUS_PX: float = 1.2
const CIRCLE_MAX_RADIUS_PX: float = 3.8
const CIRCLE_FADE_IN_END: float = 0.14
const CIRCLE_EDGE_FADE_START: float = 0.72
const CIRCLE_BASE_HALO_SCALE: float = 2.3
const CIRCLE_BEAT_HALO_BOOST: float = 2.15
const SQUARE_SCALE_BEAT_BOOST: float = 0.34
const SQUARE_MOTION_DROP_BOOST: float = 0.90
const MIST_SPEED_BEAT_BOOST: float = 1.28
const MIST_INTENSITY_BEAT_BOOST: float = 0.72
const STREAK_LENGTH_BEAT_BOOST: float = 0.90
const STREAK_MIN_WIDTH_PX: float = 1.4
const STREAK_MAX_WIDTH_PX: float = 2.6
const STREAK_MIN_LENGTH_PX: float = 22.0
const STREAK_MAX_LENGTH_PX: float = 48.0
const STREAK_GRADIENT_SEGMENTS: int = 5
const SPARKLE_BRIGHTNESS_BEAT_BOOST: float = 0.72
const SPARKLE_MOTION_DROP_BOOST: float = 0.90
const SPARKLE_BASE_HALO_SCALE: float = 4.2
const SPARKLE_HALO_BEAT_BOOST: float = 3.40
const SHOOTING_STAR_MIN_ANGLE_DEG: float = 28.0
const SHOOTING_STAR_MAX_ANGLE_DEG: float = 38.0
const SHOOTING_STAR_SPEED_BEAT_BOOST: float = 1.15
const SHOOTING_STAR_LENGTH_DROP_BOOST: float = 1.02
const SHOOTING_STAR_BRIGHTNESS_BEAT_BOOST: float = 0.74
const SHOOTING_STAR_TAIL_SEGMENTS: int = 6
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

const MIST_PALETTE: Array[Color] = [
	Color(0.32, 0.96, 1.0, 1.0),
	Color(0.70, 0.44, 1.0, 1.0),
	Color(0.88, 0.98, 1.0, 1.0),
	Color(0.42, 0.78, 1.0, 1.0),
]

const SPARKLE_PALETTE: Array[Color] = [
	Color(0.88, 0.98, 1.0, 1.0),
	Color(0.52, 0.96, 1.0, 1.0),
	Color(0.86, 0.68, 1.0, 1.0),
	Color(1.0, 0.94, 0.78, 1.0),
]

const SHOOTING_STAR_PALETTE: Array[Color] = [
	Color(0.92, 0.99, 1.0, 1.0),
	Color(0.42, 0.95, 1.0, 1.0),
	Color(0.76, 0.56, 1.0, 1.0),
]

@export var dsp_clock: DSPClock = null
@export var reactive_background: ReactiveBackground = null
@export var audio_analyzer: AudioAnalyzer = null

var _config: ReactiveParticlesConfig = ReactiveParticlesConfig.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _soft_radial_texture: GradientTexture2D = null

var _elapsed_time: float = 0.0
var _beat_impulse: float = 0.0
var _sustained_energy_target: float = 0.0
var _sustained_energy_drive: float = 0.0
var _drop_tier_level: float = 0.0
var _target_audio_energy: float = 0.0
var _smoothed_audio_energy: float = 0.0
var _current_drive: float = 0.0
var _current_speed_mult: float = 1.0
var _current_scale_mult: float = 1.0
var _current_square_motion_mult: float = 1.0
var _current_mist_speed_mult: float = 1.0
var _current_mist_intensity_mult: float = 1.0
var _current_streak_length_mult: float = 1.0
var _current_sparkle_brightness_mult: float = 1.0
var _current_sparkle_motion_mult: float = 1.0
var _current_sparkle_halo_scale: float = SPARKLE_BASE_HALO_SCALE
var _current_shooting_star_speed_mult: float = 1.0
var _current_shooting_star_length_mult: float = 1.0
var _current_shooting_star_brightness_mult: float = 1.0
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
	_soft_radial_texture = _create_soft_radial_texture()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	connect_dependencies()
	_rebuild_pool()


func connect_dependencies() -> void:
	if dsp_clock != null:
		if not dsp_clock.beat_pulsed.is_connected(_on_dsp_beat_pulsed):
			dsp_clock.beat_pulsed.connect(_on_dsp_beat_pulsed)
		if not dsp_clock.intensity_changed.is_connected(_on_dsp_intensity_changed):
			dsp_clock.intensity_changed.connect(_on_dsp_intensity_changed)

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
		_sustained_energy_target = 0.0
		_drop_tier_level = 0.0


func is_effectively_active() -> bool:
	return _config.is_rendered_type()


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


func get_soft_radial_texture() -> GradientTexture2D:
	return _soft_radial_texture


func get_mist_speed_multiplier() -> float:
	return _current_mist_speed_mult


func get_mist_intensity_multiplier() -> float:
	return _current_mist_intensity_mult


func get_streak_length_multiplier() -> float:
	return _current_streak_length_mult


func get_sparkle_brightness_multiplier() -> float:
	return _current_sparkle_brightness_mult


func get_sparkle_halo_scale() -> float:
	return _current_sparkle_halo_scale


func get_sustained_energy_drive() -> float:
	return _sustained_energy_drive


func get_square_motion_multiplier() -> float:
	return _current_square_motion_mult


func get_sparkle_motion_multiplier() -> float:
	return _current_sparkle_motion_mult


func get_shooting_star_speed_multiplier() -> float:
	return _current_shooting_star_speed_mult


func get_shooting_star_length_multiplier() -> float:
	return _current_shooting_star_length_mult


func get_shooting_star_brightness_multiplier() -> float:
	return _current_shooting_star_brightness_mult


func get_shooting_star_active_flight_count() -> int:
	if _config.particle_type != ReactiveParticlesConfig.TYPE_SHOOTING_STARS:
		return 0
	var flying: int = 0
	for i: int in range(_active_count):
		if _life_phase[i] >= 0.0:
			flying += 1
	return flying


func get_shooting_star_angles_deg_snapshot() -> PackedFloat32Array:
	var result: PackedFloat32Array = PackedFloat32Array()
	if _config.particle_type != ReactiveParticlesConfig.TYPE_SHOOTING_STARS:
		return result
	result.resize(_active_count)
	for i: int in range(_active_count):
		result[i] = rad_to_deg(_angle[i])
	return result


func inject_drop_energy(p_energy: float, p_drop_tier: int = 2) -> void:
	var clamped_e: float = clampf(p_energy, 0.0, 1.0)
	_drop_tier_level = 1.0 if p_drop_tier >= 3 else (0.72 if p_drop_tier >= 2 else 0.0)
	var target_sustained: float = clampf(maxf(clamped_e, _drop_tier_level), 0.0, 1.0)
	_sustained_energy_target = maxf(_sustained_energy_target, target_sustained)
	_sustained_energy_drive = maxf(_sustained_energy_drive, target_sustained)
	_recompute_drive_metrics()


func trigger_beat_impulse(p_strength: float = 0.85) -> void:
	var clamped: float = clampf(p_strength, 0.0, 1.0)
	if clamped <= 0.0:
		return
	_beat_impulse = maxf(_beat_impulse, clamped)
	_sustained_energy_drive = clampf(
		maxf(_sustained_energy_drive, clamped * 0.52) + (clamped * 0.24),
		0.0,
		1.0
	)
	_beat_trigger_count += 1
	_recompute_drive_metrics()
	if is_effectively_active() and _config.particle_type == ReactiveParticlesConfig.TYPE_SHOOTING_STARS:
		_wake_dormant_shooting_stars(clamped)


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

	var sustained_goal: float = maxf(_sustained_energy_target, _drop_tier_level) if _audio_active else 0.0
	if sustained_goal > _sustained_energy_drive:
		_sustained_energy_drive = lerpf(
			_sustained_energy_drive,
			sustained_goal,
			clampf(SUSTAINED_ATTACK_SPEED * dt, 0.0, 1.0)
		)
	else:
		_sustained_energy_drive = maxf(sustained_goal, _sustained_energy_drive * exp(-SUSTAINED_DECAY_RATE * dt))
	if _sustained_energy_drive < BEAT_EPSILON and sustained_goal <= 0.0:
		_sustained_energy_drive = 0.0
	_sustained_energy_target = maxf(0.0, _sustained_energy_target - (1.8 * dt))

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
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_MIST:
		_step_mist(dt, bounds)
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_SPARKLES:
		_step_sparkles(dt, bounds)
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_SHOOTING_STARS:
		_step_shooting_stars(dt, bounds)

	queue_redraw()


func _draw() -> void:
	if not is_effectively_active() or _active_count <= 0:
		return

	if _config.particle_type == ReactiveParticlesConfig.TYPE_CIRCLES:
		_draw_circles()
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_SQUARES:
		_draw_squares()
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_MIST:
		_draw_mist()
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_SPARKLES:
		_draw_sparkles()
	elif _config.particle_type == ReactiveParticlesConfig.TYPE_SHOOTING_STARS:
		_draw_shooting_stars()


func _recompute_drive_metrics() -> void:
	var reactivity_mult: float = _config.get_reactivity_multiplier()
	var sustained_component: float = maxf(_sustained_energy_drive, _smoothed_audio_energy * 0.85)
	_current_drive = clampf(
		((_beat_impulse * 0.72) + (sustained_component * 0.98)) * reactivity_mult,
		0.0,
		MAX_EFFECTIVE_DRIVE
	)
	_current_speed_mult = clampf(1.0 + (_current_drive * CIRCLE_SPEED_BEAT_BOOST), 1.0, 2.90)
	_current_scale_mult = clampf(1.0 + (_current_drive * SQUARE_SCALE_BEAT_BOOST), 1.0, 1.68)
	_current_square_motion_mult = clampf(1.0 + (_current_drive * SQUARE_MOTION_DROP_BOOST), 1.0, 2.55)
	_current_mist_speed_mult = clampf(1.0 + (_current_drive * MIST_SPEED_BEAT_BOOST), 1.0, 3.10)
	_current_mist_intensity_mult = clampf(1.0 + (_current_drive * MIST_INTENSITY_BEAT_BOOST), 1.0, 2.35)
	_current_streak_length_mult = clampf(1.0 + (_current_drive * STREAK_LENGTH_BEAT_BOOST), 1.0, 2.50)
	_current_sparkle_brightness_mult = clampf(1.0 + (_current_drive * SPARKLE_BRIGHTNESS_BEAT_BOOST), 1.0, 2.35)
	_current_sparkle_motion_mult = clampf(1.0 + (_current_drive * SPARKLE_MOTION_DROP_BOOST), 1.0, 2.50)
	_current_sparkle_halo_scale = clampf(SPARKLE_BASE_HALO_SCALE + (_current_drive * SPARKLE_HALO_BEAT_BOOST), SPARKLE_BASE_HALO_SCALE, 11.2)
	_current_shooting_star_speed_mult = clampf(1.0 + (_current_drive * SHOOTING_STAR_SPEED_BEAT_BOOST), 1.0, 2.95)
	_current_shooting_star_length_mult = clampf(1.0 + (_current_drive * SHOOTING_STAR_LENGTH_DROP_BOOST), 1.0, 2.65)
	_current_shooting_star_brightness_mult = clampf(1.0 + (_current_drive * SHOOTING_STAR_BRIGHTNESS_BEAT_BOOST), 1.0, 2.40)


func _rebuild_pool() -> void:
	if not is_effectively_active():
		_active_count = 0
		_resize_arrays(0)
		_needs_clear_draw = true
		queue_redraw()
		return

	var target_count: int = _config.get_effective_particle_count()
	_active_count = target_count
	_resize_arrays(target_count)

	var bounds: Vector2 = _resolve_bounds()
	for i: int in range(target_count):
		if _config.particle_type == ReactiveParticlesConfig.TYPE_CIRCLES:
			_spawn_circle(i, bounds, true)
		elif _config.particle_type == ReactiveParticlesConfig.TYPE_SQUARES:
			_spawn_square(i, bounds, true)
		elif _config.particle_type == ReactiveParticlesConfig.TYPE_MIST:
			_spawn_mist(i, bounds, true)
		elif _config.particle_type == ReactiveParticlesConfig.TYPE_SPARKLES:
			_spawn_sparkle(i, bounds, true)
		elif _config.particle_type == ReactiveParticlesConfig.TYPE_SHOOTING_STARS:
			_spawn_shooting_star(i, bounds, true)

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
	var drift_boost: float = _current_square_motion_mult
	var spin_boost: float = _current_square_motion_mult

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
		var outer_glow_col: Color = Color(base_col.r, base_col.g, base_col.b, alpha * (0.14 + minf(0.16, _current_drive * 0.10)))
		var glow_col: Color = Color(base_col.r, base_col.g, base_col.b, alpha * (0.28 + minf(0.20, _current_drive * 0.12)))
		var edge_col: Color = Color(base_col.r, base_col.g, base_col.b, minf(0.76, alpha * 1.08))
		var sq_rect: Rect2 = Rect2(-half_extent, -half_extent, half_extent * 2.0, half_extent * 2.0)
		var glow_w: float = 5.0 + (_current_drive * 2.6)

		draw_set_transform(_pos[i], _angle[i], scale_vec)
		draw_rect(sq_rect, fill_col, true)
		draw_rect(sq_rect, outer_glow_col, false, glow_w * 1.7)
		draw_rect(sq_rect, glow_col, false, glow_w)
		draw_rect(sq_rect, edge_col, false, 2.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _spawn_mist(p_index: int, p_bounds: Vector2, p_initial_fill: bool) -> void:
	# Neon Streaks (reusing TYPE_MIST = "mist" for config compatibility)
	var depth: float = _rng.randf()
	var width_px: float = lerpf(STREAK_MIN_WIDTH_PX, STREAK_MAX_WIDTH_PX, depth)
	var base_len_px: float = lerpf(STREAK_MIN_LENGTH_PX, STREAK_MAX_LENGTH_PX, clampf((depth * 0.72) + _rng.randf_range(0.0, 0.28), 0.0, 1.0))
	var rise_speed: float = lerpf(30.0, 92.0, depth) * _rng.randf_range(0.88, 1.14)

	var start_x: float = _rng.randf_range(12.0, maxf(13.0, p_bounds.x - 12.0))
	var start_y: float = (
		_rng.randf_range(0.0, p_bounds.y + base_len_px)
		if p_initial_fill
		else (p_bounds.y + _rng.randf_range(18.0, 96.0))
	)

	_pos[p_index] = Vector2(start_x, start_y)
	_vel[p_index] = Vector2(0.0, -rise_speed)
	_size_param[p_index] = base_len_px
	_angle[p_index] = width_px
	_ang_vel[p_index] = depth
	_alpha_base[p_index] = lerpf(0.24, 0.66, depth)
	_life_phase[p_index] = _rng.randf_range(0.0, TAU)
	_life_speed[p_index] = _rng.randf_range(1.2, 2.8)
	_sway_phase[p_index] = 0.0
	_sway_freq[p_index] = 0.0
	_sway_amp[p_index] = 0.0
	_color_idx[p_index] = _rng.randi_range(0, MIST_PALETTE.size() - 1)


func _step_mist(p_dt: float, p_bounds: Vector2) -> void:
	var speed_mult: float = _current_mist_speed_mult
	var length_mult: float = _current_streak_length_mult

	for i: int in range(_active_count):
		var pos: Vector2 = _pos[i]
		var vy: float = _vel[i].y
		var current_len: float = _size_param[i] * length_mult

		pos.y += vy * speed_mult * p_dt
		if pos.y + current_len < -24.0:
			_spawn_mist(i, p_bounds, false)
		else:
			if pos.x < 0.0 or pos.x > p_bounds.x:
				pos.x = wrapf(pos.x, 8.0, maxf(16.0, p_bounds.x - 8.0))
			_pos[i] = pos


func _draw_mist() -> void:
	var length_mult: float = _current_streak_length_mult
	var intensity_mult: float = _current_mist_intensity_mult
	var flare_scale: float = 3.2 + (_current_drive * 2.45)
	var palette_len: int = MIST_PALETTE.size()
	var seg_count: int = STREAK_GRADIENT_SEGMENTS

	for i: int in range(_active_count):
		var tip: Vector2 = _pos[i]
		var total_len: float = _size_param[i] * length_mult
		var width_px: float = _angle[i]
		var base_col: Color = MIST_PALETTE[_color_idx[i] % palette_len]
		var shimmer: float = 0.90 + (0.10 * sin((_elapsed_time * _life_speed[i]) + _life_phase[i]))
		var tip_alpha: float = clampf(_alpha_base[i] * shimmer * intensity_mult, 0.0, 0.88)
		if tip_alpha <= 0.01:
			continue

		# Smooth segmented trail from transparent lower tail (t=0) up to bright leading tip (t=1)
		for seg_idx: int in range(seg_count):
			var t_tail: float = float(seg_idx) / float(seg_count)
			var t_head: float = float(seg_idx + 1) / float(seg_count)
			var t_mid: float = (t_tail + t_head) * 0.5
			var seg_alpha: float = tip_alpha * pow(t_mid, 1.85)
			if seg_alpha <= 0.004:
				continue

			var y_bottom: float = tip.y + ((1.0 - t_tail) * total_len)
			var y_top: float = tip.y + ((1.0 - t_head) * total_len)
			var seg_col: Color = Color(
				lerpf(base_col.r, 1.0, t_mid * 0.28),
				lerpf(base_col.g, 1.0, t_mid * 0.28),
				lerpf(base_col.b, 1.0, t_mid * 0.28),
				seg_alpha
			)
			draw_line(
				Vector2(tip.x, y_bottom),
				Vector2(tip.x, y_top),
				seg_col,
				width_px,
				true
			)

		# Subtle circular glow flare at the leading top tip using shared _soft_radial_texture
		if _soft_radial_texture != null:
			var flare_r: float = width_px * flare_scale
			var flare_alpha: float = clampf(tip_alpha * (0.58 + minf(0.24, _current_drive * 0.18)), 0.0, 0.72)
			var flare_rect: Rect2 = Rect2(tip.x - flare_r, tip.y - flare_r, flare_r * 2.0, flare_r * 2.0)
			var flare_tint: Color = Color(base_col.r, base_col.g, base_col.b, flare_alpha)
			draw_texture_rect(_soft_radial_texture, flare_rect, false, flare_tint)

		var core_col: Color = Color(
			lerpf(base_col.r, 1.0, 0.65),
			lerpf(base_col.g, 1.0, 0.65),
			lerpf(base_col.b, 1.0, 0.65),
			minf(0.95, tip_alpha * 1.12)
		)
		draw_circle(tip, width_px * 0.62, core_col)


func _spawn_sparkle(p_index: int, p_bounds: Vector2, p_initial_fill: bool) -> void:
	var pad: float = 24.0
	var max_x: float = maxf(pad + 1.0, p_bounds.x - pad)
	var max_y: float = maxf(pad + 1.0, p_bounds.y - pad)

	_pos[p_index] = Vector2(
		_rng.randf_range(pad, max_x),
		_rng.randf_range(pad, max_y)
	)
	_vel[p_index] = Vector2(
		_rng.randf_range(-8.0, 8.0),
		_rng.randf_range(-8.0, 8.0)
	)
	_size_param[p_index] = _rng.randf_range(1.4, 4.2)
	_angle[p_index] = 0.0
	_ang_vel[p_index] = 0.0
	_alpha_base[p_index] = _rng.randf_range(0.28, 0.78)
	_life_phase[p_index] = _rng.randf() if p_initial_fill else 0.0
	_life_speed[p_index] = _rng.randf_range(0.22, 0.58)
	_sway_phase[p_index] = _rng.randf_range(0.0, TAU)
	_sway_freq[p_index] = _rng.randf_range(0.5, 1.3)
	_sway_amp[p_index] = _rng.randf_range(3.0, 8.0)
	_color_idx[p_index] = _rng.randi_range(0, SPARKLE_PALETTE.size() - 1)


func _step_sparkles(p_dt: float, p_bounds: Vector2) -> void:
	var motion_mult: float = _current_sparkle_motion_mult
	for i: int in range(_active_count):
		var phase: float = _life_phase[i] + (_life_speed[i] * motion_mult * p_dt)
		if phase >= 1.0:
			_spawn_sparkle(i, p_bounds, false)
			continue
		_life_phase[i] = phase

		var pos: Vector2 = _pos[i]
		var vel: Vector2 = _vel[i]
		pos.x += vel.x * motion_mult * p_dt
		pos.y += vel.y * motion_mult * p_dt

		var margin: float = 28.0
		if pos.x < -margin:
			pos.x = p_bounds.x + margin
		elif pos.x > p_bounds.x + margin:
			pos.x = -margin

		if pos.y < -margin:
			pos.y = p_bounds.y + margin
		elif pos.y > p_bounds.y + margin:
			pos.y = -margin

		_pos[i] = pos


func _draw_sparkles() -> void:
	var brightness_mult: float = _current_sparkle_brightness_mult
	var halo_scale: float = _current_sparkle_halo_scale
	var palette_len: int = SPARKLE_PALETTE.size()

	for i: int in range(_active_count):
		var life_t: float = clampf(_life_phase[i], 0.0, 1.0)
		var fade_raw: float = sin(life_t * PI)
		if fade_raw <= 0.006:
			continue

		var fade: float = pow(fade_raw, 1.45)
		var core_r: float = _size_param[i]
		var pos: Vector2 = _pos[i]
		var base_col: Color = SPARKLE_PALETTE[_color_idx[i] % palette_len]

		var core_alpha: float = clampf(_alpha_base[i] * fade * brightness_mult, 0.0, 0.92)
		var halo_alpha: float = clampf(core_alpha * (0.48 + minf(0.18, _current_drive * 0.14)), 0.0, 0.56)
		var halo_r: float = core_r * halo_scale

		if _soft_radial_texture != null:
			var halo_rect: Rect2 = Rect2(pos.x - halo_r, pos.y - halo_r, halo_r * 2.0, halo_r * 2.0)
			var halo_tint: Color = Color(base_col.r, base_col.g, base_col.b, halo_alpha)
			draw_texture_rect(_soft_radial_texture, halo_rect, false, halo_tint)

		var core_col: Color = Color(
			lerpf(base_col.r, 1.0, 0.55),
			lerpf(base_col.g, 1.0, 0.55),
			lerpf(base_col.b, 1.0, 0.55),
			core_alpha
		)
		draw_circle(pos, core_r, core_col)


func _spawn_shooting_star(p_index: int, p_bounds: Vector2, p_initial_fill: bool, p_force_active: bool = false, p_beat_strength: float = 0.0) -> void:
	var angle_deg: float = _rng.randf_range(SHOOTING_STAR_MIN_ANGLE_DEG, SHOOTING_STAR_MAX_ANGLE_DEG)
	var angle_rad: float = deg_to_rad(angle_deg)
	var dir: Vector2 = Vector2(cos(angle_rad), sin(angle_rad))
	var base_speed: float = _rng.randf_range(210.0, 350.0) * (1.0 + (p_beat_strength * 0.35))
	var tail_len: float = _rng.randf_range(125.0, 235.0) * (1.0 + (p_beat_strength * 0.25))
	var width_px: float = _rng.randf_range(1.6, 2.6)

	var start_pos: Vector2 = Vector2.ZERO
	if p_initial_fill and p_index < 2:
		# Pre-seed 1-2 active streaks inside viewport for immediate live preview
		start_pos = Vector2(
			_rng.randf_range(p_bounds.x * 0.12, p_bounds.x * 0.58),
			_rng.randf_range(p_bounds.y * 0.08, p_bounds.y * 0.45)
		)
	elif _rng.randf() < 0.65:
		# Enter along top edge
		start_pos = Vector2(_rng.randf_range(-p_bounds.x * 0.15, p_bounds.x * 0.72), -24.0)
	else:
		# Enter along left edge
		start_pos = Vector2(-24.0, _rng.randf_range(p_bounds.y * 0.04, p_bounds.y * 0.46))

	var is_active_now: bool = p_force_active or (p_initial_fill and p_index < 2)
	var dormant_delay: float = -_rng.randf_range(0.55, 2.60)

	_pos[p_index] = start_pos
	_vel[p_index] = dir * base_speed
	_size_param[p_index] = tail_len
	_angle[p_index] = angle_rad
	_ang_vel[p_index] = width_px
	_alpha_base[p_index] = clampf(_rng.randf_range(0.58, 0.86) + (p_beat_strength * 0.14), 0.45, 0.96)
	_life_phase[p_index] = 0.0 if is_active_now else dormant_delay
	_life_speed[p_index] = 1.0
	_sway_phase[p_index] = 0.0
	_sway_freq[p_index] = 0.0
	_sway_amp[p_index] = 0.0
	_color_idx[p_index] = _rng.randi_range(0, SHOOTING_STAR_PALETTE.size() - 1)


func _wake_dormant_shooting_stars(p_strength: float) -> void:
	var bounds: Vector2 = _resolve_bounds()
	var react_mult: float = _config.get_reactivity_multiplier()
	var wake_limit: int = 2 if react_mult >= 1.3 else 1
	var woken: int = 0
	for i: int in range(_active_count):
		if _life_phase[i] < 0.0:
			_spawn_shooting_star(i, bounds, false, true, p_strength)
			woken += 1
			if woken >= wake_limit:
				break


func _step_shooting_stars(p_dt: float, p_bounds: Vector2) -> void:
	var speed_mult: float = _current_shooting_star_speed_mult
	var length_mult: float = _current_shooting_star_length_mult
	var cooldown_rate: float = 1.0 + (_current_drive * 1.45)
	for i: int in range(_active_count):
		if _life_phase[i] < 0.0:
			_life_phase[i] += p_dt * cooldown_rate
			if _life_phase[i] >= 0.0:
				_spawn_shooting_star(i, p_bounds, false, true, clampf(_sustained_energy_drive, 0.0, 1.0))
			continue

		_life_phase[i] += p_dt * (1.4 + (_current_drive * 0.45))
		var pos: Vector2 = _pos[i] + (_vel[i] * speed_mult * p_dt)
		var tail_len: float = _size_param[i] * length_mult
		var exit_margin: float = tail_len + 48.0
		if pos.x > p_bounds.x + exit_margin or pos.y > p_bounds.y + exit_margin:
			_spawn_shooting_star(i, p_bounds, false, false, 0.0)
		else:
			_pos[i] = pos


func _draw_shooting_stars() -> void:
	var bright_mult: float = _current_shooting_star_brightness_mult
	var length_mult: float = _current_shooting_star_length_mult
	var bounds: Vector2 = _resolve_bounds()
	var palette_len: int = SHOOTING_STAR_PALETTE.size()
	var seg_count: int = SHOOTING_STAR_TAIL_SEGMENTS

	for i: int in range(_active_count):
		if _life_phase[i] < 0.0:
			continue

		var head: Vector2 = _pos[i]
		var angle_rad: float = _angle[i]
		var dir: Vector2 = Vector2(cos(angle_rad), sin(angle_rad))
		var tail_len: float = _size_param[i] * length_mult
		var width_px: float = _ang_vel[i]

		var fade_in: float = smoothstep(0.0, 0.18, _life_phase[i])
		var edge_x: float = 1.0 - smoothstep(bounds.x * 0.80, bounds.x + (tail_len * 0.65), head.x)
		var edge_y: float = 1.0 - smoothstep(bounds.y * 0.80, bounds.y + (tail_len * 0.65), head.y)
		var edge_fade: float = minf(edge_x, edge_y)
		var head_alpha: float = clampf(_alpha_base[i] * fade_in * edge_fade * bright_mult, 0.0, 0.96)
		if head_alpha <= 0.01:
			continue

		var base_col: Color = SHOOTING_STAR_PALETTE[_color_idx[i] % palette_len]
		var blur_width_mult: float = 2.6 + (_current_drive * 1.4)

		# Tapered multi-segment diagonal tail with soft blur halo behind sharp streak
		for seg_idx: int in range(seg_count):
			var t0: float = float(seg_idx) / float(seg_count)
			var t1: float = float(seg_idx + 1) / float(seg_count)
			var t_mid: float = (t0 + t1) * 0.5
			var seg_alpha: float = head_alpha * pow(t_mid, 1.85)
			if seg_alpha <= 0.004:
				continue

			var p0: Vector2 = head - (dir * ((1.0 - t0) * tail_len))
			var p1: Vector2 = head - (dir * ((1.0 - t1) * tail_len))
			var seg_w: float = lerpf(0.75, width_px, t_mid)
			var halo_seg_col: Color = Color(base_col.r, base_col.g, base_col.b, seg_alpha * (0.24 + minf(0.18, _current_drive * 0.10)))
			var seg_col: Color = Color(
				lerpf(base_col.r, 1.0, t_mid * 0.38),
				lerpf(base_col.g, 1.0, t_mid * 0.38),
				lerpf(base_col.b, 1.0, t_mid * 0.38),
				seg_alpha
			)
			draw_line(p0, p1, halo_seg_col, seg_w * blur_width_mult, true)
			draw_line(p0, p1, seg_col, seg_w, true)

		# Glowing circular head flare using shared _soft_radial_texture
		if _soft_radial_texture != null:
			var flare_r: float = width_px * (4.6 + (_current_drive * 3.0))
			var flare_alpha: float = clampf(head_alpha * (0.64 + minf(0.28, _current_drive * 0.18)), 0.0, 0.88)
			var flare_rect: Rect2 = Rect2(head.x - flare_r, head.y - flare_r, flare_r * 2.0, flare_r * 2.0)
			var flare_tint: Color = Color(base_col.r, base_col.g, base_col.b, flare_alpha)
			draw_texture_rect(_soft_radial_texture, flare_rect, false, flare_tint)

		var core_col: Color = Color(
			lerpf(base_col.r, 1.0, 0.72),
			lerpf(base_col.g, 1.0, 0.72),
			lerpf(base_col.b, 1.0, 0.72),
			minf(0.98, head_alpha * 1.1)
		)
		draw_circle(head, width_px * 0.78, core_col)


func _create_soft_radial_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.28, 0.62, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.72),
		Color(1.0, 1.0, 1.0, 0.24),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 128
	tex.height = 128
	tex.use_hdr = false
	return tex


func _resolve_bounds() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	var vp_rect: Rect2 = get_viewport_rect()
	if vp_rect.size.x > 1.0 and vp_rect.size.y > 1.0:
		return vp_rect.size
	return DEFAULT_VIEWPORT_SIZE


func _on_dsp_beat_pulsed(_p_beat_index: int, _p_beat_time_sec: float) -> void:
	trigger_beat_impulse(0.82)


func _on_dsp_intensity_changed(p_block: IntensityBlock) -> void:
	if p_block == null:
		return
	var energy: float = clampf(p_block.energy, 0.0, 1.0)
	_drop_tier_level = 1.0 if p_block.tier >= 3 else (0.72 if p_block.tier >= 2 else 0.0)
	_sustained_energy_target = maxf(energy * 0.65, _drop_tier_level)
	if p_block.tier >= 2:
		_sustained_energy_drive = maxf(_sustained_energy_drive, _drop_tier_level)
		trigger_beat_impulse(0.95)
	_recompute_drive_metrics()


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
	var clamped_bass: float = clampf(p_bass_energy, 0.0, 1.0)
	var clamped_total: float = clampf(p_total_energy, 0.0, 1.0)
	var combined: float = clampf((clamped_bass * 0.65) + (clamped_total * 0.35), 0.0, 1.0)
	_target_audio_energy = maxf(_target_audio_energy * 0.65, combined)
	if combined >= 0.62:
		var drop_norm: float = clampf((combined - 0.55) / 0.35, 0.0, 1.0)
		_sustained_energy_target = maxf(_sustained_energy_target, drop_norm)
