class_name LaneField
extends Control

const DEFAULT_LANE_COUNT: int = 4
const MIN_SPEED_MULTIPLIER: int = 1
const MAX_SPEED_MULTIPLIER: int = 4
const SPEED_MULTIPLIER_FACTORS: Array[float] = [2.0, 3.0, 4.0, 5.0]
const DEFAULT_BASE_SCROLL_SPEED_PX_PER_SEC: float = 550.0
const TOP_SPAWN_MARGIN_PX: float = 64.0
const DEFAULT_PLAY_WIDTH: float = 950.4
const DEFAULT_PLAY_HEIGHT: float = 1920.0
const HIT_LINE_VERTICAL_LIFT_PX: float = 175.0
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

const HIT_EFFECT_CLASSIC: String = GameplayEffectsConfig.HIT_CLASSIC
const MAX_HOLD_ABSORB_RINGS: int = 16
const HOLD_RING_SPAWN_INTERVAL_SEC: float = 0.115
const HOLD_RING_DURATION_SEC: float = 0.40
const HOLD_RING_RISE_SPEED_PX_PER_SEC: float = 175.0
const HOLD_COMPLETE_FLARE_DECAY_RATE: float = 5.2
const COLOR_HOLD_ABSORB_CYAN: Color = Color(0.18, 0.92, 1.0, 1.0)
const COLOR_HOLD_ABSORB_TURQUOISE: Color = Color(0.24, 0.98, 0.86, 1.0)

# Fixed-size preallocated Object Pools for note vanish effects (0 allocations per frame)
const MAX_FIREWORK_RAYS: int = 96
const FIREWORK_RAYS_PERFECT: int = 11
const FIREWORK_RAYS_GREAT: int = 9
const FIREWORK_RAYS_GOOD: int = 8
const FIREWORK_DROPLET_BASE_RADIUS_PX: float = 6.8
const FIREWORK_NEON_COLORS: Array[Color] = [
	Color(1.0, 0.95, 0.10, 1.0),
	Color(0.12, 1.0, 0.42, 1.0),
	Color(1.0, 0.14, 0.76, 1.0),
	Color(0.08, 0.96, 1.0, 1.0),
	Color(0.72, 0.36, 1.0, 1.0),
]

const MAX_ZOOM_FADE_GHOSTS: int = 24
const ZOOM_FADE_DURATION_SEC: float = 0.22
const ZOOM_FADE_MAX_SCALE: float = 1.35

const MAX_FRACTURE_SHARDS: int = 84
const FRACTURE_SHARDS_PERFECT: int = 7
const FRACTURE_SHARDS_GREAT: int = 6
const FRACTURE_SHARDS_GOOD: int = 5
const FRACTURE_DURATION_SEC: float = 0.26
const FRACTURE_GRAVITY_PX_PER_SEC2: float = 560.0

const COLOR_PERFECT_A: Color = Color(0.35, 1.0, 0.96, 1.0)
const COLOR_PERFECT_B: Color = Color(1.0, 0.88, 0.28, 1.0)
const COLOR_PERFECT_C: Color = Color(1.0, 0.36, 0.86, 1.0)
const COLOR_GREAT_A: Color = Color(0.30, 1.0, 0.62, 1.0)
const COLOR_GREAT_B: Color = Color(0.25, 0.90, 1.0, 1.0)
const COLOR_GOOD_A: Color = Color(0.38, 0.76, 1.0, 0.92)
const COLOR_HOLD_SPARK: Color = Color(0.26, 0.98, 0.88, 1.0)
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
var _lane_pending_hold_completion: Array[bool] = [false, false, false, false]
var _lane_hold_phase: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _lane_hold_energy: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _lane_hold_complete_flare: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _touch_ripple_consumed_for_lane: Array[bool] = [false, false, false, false]
var _touch_ripples: Array[Dictionary] = []
var _hold_absorb_rings: Array[Dictionary] = []
var _hit_particles: Array[Dictionary] = []
var _hold_spark_accumulator_sec: float = 0.0
var _hold_ring_accumulator_sec: float = 0.0
var _hit_effect_style: String = GameplayEffectsConfig.HIT_CLASSIC
var _touch_effect_style: String = GameplayEffectsConfig.TOUCH_WAVE
var _vanish_effect_style: String = GameplayEffectsConfig.VANISH_FIREWORK
var _touch_renderer: TouchEffectRenderer = TouchEffectRenderer.new()
var _hold_contact_halo_texture: GradientTexture2D = null
var _fx_seed_counter: int = 1

# Preallocated FireWork droplet pool (fixed size = MAX_FIREWORK_RAYS)
var _fw_active: PackedByteArray = PackedByteArray()
var _fw_age: PackedFloat32Array = PackedFloat32Array()
var _fw_duration: PackedFloat32Array = PackedFloat32Array()
var _fw_origin: PackedVector2Array = PackedVector2Array()
var _fw_dir: PackedVector2Array = PackedVector2Array()
var _fw_max_dist: PackedFloat32Array = PackedFloat32Array()
var _fw_ray_len: PackedFloat32Array = PackedFloat32Array()
var _fw_color: PackedColorArray = PackedColorArray()
var _fw_drop_poly_buf: PackedVector2Array = PackedVector2Array()
var _fw_cursor: int = 0

# Preallocated Zoom + Fade ghost pool (fixed size = MAX_ZOOM_FADE_GHOSTS)
var _zf_active: PackedByteArray = PackedByteArray()
var _zf_age: PackedFloat32Array = PackedFloat32Array()
var _zf_duration: PackedFloat32Array = PackedFloat32Array()
var _zf_center: PackedVector2Array = PackedVector2Array()
var _zf_base_size: PackedVector2Array = PackedVector2Array()
var _zf_color: PackedColorArray = PackedColorArray()
var _zf_cursor: int = 0

# Preallocated Fracture shard pool (fixed size = MAX_FRACTURE_SHARDS, 0 allocs/frame)
var _fr_active: PackedByteArray = PackedByteArray()
var _fr_age: PackedFloat32Array = PackedFloat32Array()
var _fr_duration: PackedFloat32Array = PackedFloat32Array()
var _fr_pos: PackedVector2Array = PackedVector2Array()
var _fr_vel: PackedVector2Array = PackedVector2Array()
var _fr_angle: PackedFloat32Array = PackedFloat32Array()
var _fr_ang_vel: PackedFloat32Array = PackedFloat32Array()
var _fr_color: PackedColorArray = PackedColorArray()
var _fr_local_polys: Array[PackedVector2Array] = []
var _fr_world_poly_buf: PackedVector2Array = PackedVector2Array()
var _fr_cursor: int = 0
var _divider_beat_pulse: float = 0.0
var _divider_bass_energy: float = 0.0
var _divider_drop_intensity: float = 0.0
var _divider_prev_bass: float = 0.0
var _divider_shake_amp_px: float = 0.0
var _divider_shake_phase: float = 0.0
var _divider_shake_offset_x: float = 0.0
var _divider_tier: int = 0


static func resolve_speed_factor(p_speed_level: int) -> float:
	var clamped_level: int = clampi(p_speed_level, MIN_SPEED_MULTIPLIER, MAX_SPEED_MULTIPLIER)
	var idx: int = clamped_level - MIN_SPEED_MULTIPLIER
	if idx >= 0 and idx < SPEED_MULTIPLIER_FACTORS.size():
		return SPEED_MULTIPLIER_FACTORS[idx]
	return float(clamped_level)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hold_contact_halo_texture = _create_hold_contact_halo_texture()
	_init_vanish_effect_pools()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _hold_contact_halo_texture == null:
		_hold_contact_halo_texture = _create_hold_contact_halo_texture()
	if not _speed_multiplier_configured:
		_base_scroll_speed_px_per_sec = maxf(100.0, scroll_speed_px_per_sec)
	scroll_speed_px_per_sec = _base_scroll_speed_px_per_sec * resolve_speed_factor(_speed_multiplier)
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
			_lane_hold_phase[lane_idx] += dt * 11.5
			_lane_hold_energy[lane_idx] = minf(1.0, _lane_hold_energy[lane_idx] + (dt * 7.5))
			needs_redraw = true
		elif _lane_hold_energy[lane_idx] > 0.002:
			_lane_hold_energy[lane_idx] *= exp(-10.0 * dt)
			if _lane_hold_energy[lane_idx] < 0.002:
				_lane_hold_energy[lane_idx] = 0.0
			needs_redraw = true

		if _lane_hold_complete_flare[lane_idx] > 0.002:
			_lane_hold_complete_flare[lane_idx] *= exp(-HOLD_COMPLETE_FLARE_DECAY_RATE * dt)
			if _lane_hold_complete_flare[lane_idx] < 0.002:
				_lane_hold_complete_flare[lane_idx] = 0.0
			needs_redraw = true

	if any_holding:
		_hold_spark_accumulator_sec += dt
		while _hold_spark_accumulator_sec >= HOLD_SPARK_INTERVAL_SEC:
			_hold_spark_accumulator_sec -= HOLD_SPARK_INTERVAL_SEC
			for lane_idx: int in range(mini(lane_count, _lane_hold_states.size())):
				if _lane_hold_states[lane_idx]:
					_spawn_hold_sparks(lane_idx, 2)
					needs_redraw = true

		_hold_ring_accumulator_sec += dt
		while _hold_ring_accumulator_sec >= HOLD_RING_SPAWN_INTERVAL_SEC:
			_hold_ring_accumulator_sec -= HOLD_RING_SPAWN_INTERVAL_SEC
			for lane_idx: int in range(mini(lane_count, _lane_hold_states.size())):
				if _lane_hold_states[lane_idx]:
					_spawn_hold_absorb_ring(lane_idx, false)
					needs_redraw = true
	else:
		_hold_spark_accumulator_sec = 0.0
		_hold_ring_accumulator_sec = 0.0

	var ring_idx: int = _hold_absorb_rings.size() - 1
	while ring_idx >= 0:
		var ring: Dictionary = _hold_absorb_rings[ring_idx]
		var next_age: float = (ring["age"] as float) + dt
		var duration: float = maxf(0.01, ring["duration"] as float)
		if next_age >= duration:
			_hold_absorb_rings.remove_at(ring_idx)
		else:
			ring["age"] = next_age
			_hold_absorb_rings[ring_idx] = ring
		needs_redraw = true
		ring_idx -= 1

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

	if _step_vanish_effect_pools(dt):
		needs_redraw = true

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

	_draw_hold_consumption_effects(lane_count)
	_draw_touch_ripples()
	_draw_vanish_effects()
	_draw_hit_particles()


func _draw_hold_consumption_effects(p_lane_count: int) -> void:
	match _hit_effect_style:
		HIT_EFFECT_CLASSIC, _:
			_draw_classic_hold_consumption_effects(p_lane_count)


func _draw_classic_hold_consumption_effects(p_lane_count: int) -> void:
	if _hold_contact_halo_texture != null:
		for lane_idx: int in range(mini(p_lane_count, _lane_hold_energy.size())):
			var energy: float = _lane_hold_energy[lane_idx]
			var flare: float = _lane_hold_complete_flare[lane_idx]
			if energy <= 0.004 and flare <= 0.004:
				continue

			var cx: float = (float(lane_idx) + 0.5) * _lane_width
			var pulse: float = (sin(_lane_hold_phase[lane_idx]) * 0.5) + 0.5
			var active_strength: float = clampf(maxf(energy, flare), 0.0, 1.0)
			var halo_col: Color = COLOR_HOLD_ABSORB_CYAN.lerp(
				COLOR_HOLD_ABSORB_TURQUOISE,
				clampf((pulse * 0.55) + (flare * 0.45), 0.0, 1.0)
			)

			# Outer pulsing cyan-turquoise radial halo centered on contact point
			var outer_rx: float = _lane_width * (0.58 + (pulse * 0.14) + (flare * 0.28))
			var outer_ry: float = outer_rx * 0.64
			var outer_alpha: float = clampf((energy * 0.36) + (flare * 0.42), 0.0, 0.56)
			var outer_rect: Rect2 = Rect2(cx - outer_rx, _hit_line_y - outer_ry, outer_rx * 2.0, outer_ry * 2.0)
			draw_texture_rect(
				_hold_contact_halo_texture,
				outer_rect,
				false,
				Color(halo_col.r, halo_col.g, halo_col.b, outer_alpha)
			)

			# Inner concentrated absorption core at hit line
			var inner_rx: float = _lane_width * (0.28 + (pulse * 0.08) + (flare * 0.18))
			var inner_ry: float = inner_rx * 0.56
			var inner_alpha: float = clampf((active_strength * 0.54) + (flare * 0.24), 0.0, 0.76)
			var inner_rect: Rect2 = Rect2(cx - inner_rx, _hit_line_y - inner_ry, inner_rx * 2.0, inner_ry * 2.0)
			draw_texture_rect(
				_hold_contact_halo_texture,
				inner_rect,
				false,
				Color(halo_col.r, halo_col.g, halo_col.b, inner_alpha)
			)

	# Soft ascending cyan/turquoise absorption rings drifting upward from contact point
	var ring_count: int = _hold_absorb_rings.size()
	for i: int in range(ring_count):
		var ring: Dictionary = _hold_absorb_rings[i]
		var origin: Vector2 = ring["origin"] as Vector2
		var age: float = ring["age"] as float
		var duration: float = maxf(0.01, ring["duration"] as float)
		var is_completion: bool = ring["is_completion"] as bool
		var t: float = clampf(age / duration, 0.0, 1.0)
		var eased_t: float = 1.0 - pow(1.0 - t, 2.2)
		var rise_speed: float = HOLD_RING_RISE_SPEED_PX_PER_SEC * (1.35 if is_completion else 1.0)
		var ring_pos: Vector2 = Vector2(origin.x, origin.y - (rise_speed * age))
		var start_r: float = _lane_width * (0.16 if is_completion else 0.13)
		var end_r: float = _lane_width * (0.48 if is_completion else 0.34)
		var radius: float = lerpf(start_r, end_r, eased_t)
		var fade: float = sin(t * PI) * (1.0 - (t * 0.45))
		var alpha: float = clampf(fade * (0.68 if is_completion else 0.44), 0.0, 0.72)
		var col: Color = COLOR_HOLD_ABSORB_TURQUOISE if is_completion else COLOR_HOLD_ABSORB_CYAN
		var stroke_w: float = lerpf(3.4 if is_completion else 2.2, 1.0, t)

		draw_arc(ring_pos, radius, 0.0, TAU, 28, Color(col.r, col.g, col.b, alpha * 0.30), stroke_w * 3.0)
		draw_arc(ring_pos, radius, 0.0, TAU, 28, Color(col.r, col.g, col.b, alpha), stroke_w)


func _draw_touch_ripples() -> void:
	var ripple_count: int = _touch_ripples.size()
	for i: int in range(ripple_count):
		var ripple: Dictionary = _touch_ripples[i]
		var pos: Vector2 = ripple["pos"] as Vector2
		var age: float = ripple["age"] as float
		var duration: float = maxf(0.01, ripple["duration"] as float)
		var base_color: Color = ripple["color"] as Color
		var variant: int = int(ripple.get("variant", 0))
		var t: float = clampf(age / duration, 0.0, 1.0)
		_touch_renderer.draw_touch_effect(self, pos, t, _touch_effect_style, base_color, variant)


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
	scroll_speed_px_per_sec = maxf(100.0, _base_scroll_speed_px_per_sec) * resolve_speed_factor(_speed_multiplier)

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


func get_lane_global_rect(p_lane: int) -> Rect2:
	var lane_count: int = _get_active_lane_count()
	var clamped_lane: int = clampi(p_lane, 0, lane_count - 1)
	var field_global_pos: Vector2 = global_position if is_inside_tree() else position
	var field_height: float = size.y if size.y > 1.0 else DEFAULT_PLAY_HEIGHT
	var lane_left_x: float = field_global_pos.x + (float(clamped_lane) * _lane_width)
	return Rect2(lane_left_x, field_global_pos.y, _lane_width, field_height)


func get_judgment_line_global_y() -> float:
	var field_global_pos: Vector2 = global_position if is_inside_tree() else position
	return field_global_pos.y + _hit_line_y


func get_active_note_views() -> Array[NoteView]:
	return _active_views


func get_free_pool_count() -> int:
	return _free_pool.size()


func get_active_ripple_count() -> int:
	return _touch_ripples.size()


func get_active_particle_count() -> int:
	return _hit_particles.size()


func apply_gameplay_effects_config(p_config: GameplayEffectsConfig) -> void:
	if p_config == null:
		_hit_effect_style = GameplayEffectsConfig.HIT_CLASSIC
		_touch_effect_style = GameplayEffectsConfig.TOUCH_WAVE
		_vanish_effect_style = GameplayEffectsConfig.VANISH_FIREWORK
	else:
		_hit_effect_style = GameplayEffectsConfig.sanitize_hit_effect(p_config.hit_effect)
		_touch_effect_style = GameplayEffectsConfig.sanitize_touch_effect(p_config.touch_effect)
		_vanish_effect_style = GameplayEffectsConfig.sanitize_vanish_effect(p_config.vanish_effect)
	queue_redraw()


func get_hit_effect_style() -> String:
	return _hit_effect_style


func get_touch_effect_style() -> String:
	return _touch_effect_style


func get_vanish_effect_style() -> String:
	return _vanish_effect_style


func get_active_firework_ray_count() -> int:
	var active: int = 0
	for i: int in range(_fw_active.size()):
		if _fw_active[i] != 0:
			active += 1
	return active


func get_active_zoom_fade_count() -> int:
	var active: int = 0
	for i: int in range(_zf_active.size()):
		if _zf_active[i] != 0:
			active += 1
	return active


func get_active_fracture_shard_count() -> int:
	var active: int = 0
	for i: int in range(_fr_active.size()):
		if _fr_active[i] != 0:
			active += 1
	return active


func get_active_fracture_min_vy() -> float:
	var has_any: bool = false
	var min_vy: float = 0.0
	for i: int in range(_fr_active.size()):
		if _fr_active[i] == 0:
			continue
		var vy: float = _fr_vel[i].y
		if not has_any or vy < min_vy:
			min_vy = vy
			has_any = true
	return min_vy


func get_active_fracture_avg_y() -> float:
	var count: int = 0
	var sum_y: float = 0.0
	for i: int in range(_fr_active.size()):
		if _fr_active[i] == 0:
			continue
		sum_y += _fr_pos[i].y
		count += 1
	if count == 0:
		return 0.0
	return sum_y / float(count)


static func get_firework_droplet_base_radius() -> float:
	return FIREWORK_DROPLET_BASE_RADIUS_PX


static func compute_zoom_fade_scale(p_progress: float) -> float:
	var t: float = clampf(p_progress, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - t, 2.2)
	return lerpf(1.0, ZOOM_FADE_MAX_SCALE, eased)


func get_hold_contact_halo_texture() -> GradientTexture2D:
	return _hold_contact_halo_texture


static func get_hold_beam_width_ratio() -> float:
	return NoteView.HOLD_INNER_BEAM_IDLE_RATIO


func get_lane_hold_energy(p_lane: int) -> float:
	if p_lane < 0 or p_lane >= _lane_hold_energy.size():
		return 0.0
	return _lane_hold_energy[p_lane]


func get_lane_hold_complete_flare(p_lane: int) -> float:
	if p_lane < 0 or p_lane >= _lane_hold_complete_flare.size():
		return 0.0
	return _lane_hold_complete_flare[p_lane]


func get_active_hold_absorb_ring_count() -> int:
	return _hold_absorb_rings.size()


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
			_lane_pending_hold_completion[p_lane] = false
			_lane_hold_energy[p_lane] = maxf(_lane_hold_energy[p_lane], 0.72)
			_spawn_hold_absorb_ring(p_lane, false)
			_spawn_hold_sparks(p_lane, 4)
		else:
			_lane_pending_hold_completion[p_lane] = true
		queue_redraw()


func _on_note_judged(p_lane: int, p_grade: int, _p_error_ms: float, _p_combo: int) -> void:
	if p_lane < 0 or p_lane >= _get_active_lane_count():
		return
	if p_lane < _lane_pending_hold_completion.size() and _lane_pending_hold_completion[p_lane]:
		_lane_pending_hold_completion[p_lane] = false
		if p_grade != HitJudge.JudgmentGrade.MISS:
			_trigger_hold_completion_flare(p_lane)
	_spawn_judgment_particles(p_lane, p_grade)


func _on_hold_combo_ticked(p_lane: int, _p_new_combo: int) -> void:
	if p_lane < 0 or p_lane >= _get_active_lane_count():
		return
	_spawn_hold_absorb_ring(p_lane, false)
	_spawn_hold_sparks(p_lane, HOLD_TICK_SPARK_COUNT)


func _trigger_hold_completion_flare(p_lane: int) -> void:
	if p_lane < 0 or p_lane >= _lane_hold_complete_flare.size():
		return
	_lane_hold_complete_flare[p_lane] = 1.0
	_spawn_hold_absorb_ring(p_lane, true)
	_spawn_hold_sparks(p_lane, 8)
	queue_redraw()


func _spawn_hold_absorb_ring(p_lane: int, p_is_completion: bool) -> void:
	if _hold_absorb_rings.size() >= MAX_HOLD_ABSORB_RINGS:
		_hold_absorb_rings.remove_at(0)
	var origin: Vector2 = Vector2((float(p_lane) + 0.5) * _lane_width, _hit_line_y)
	_hold_absorb_rings.append({
		"origin": origin,
		"age": 0.0,
		"duration": HOLD_RING_DURATION_SEC * (1.20 if p_is_completion else 1.0),
		"is_completion": p_is_completion,
	})
	queue_redraw()


func _create_hold_contact_halo_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.30, 0.65, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.56),
		Color(1.0, 1.0, 1.0, 0.16),
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


func _spawn_touch_ripple(p_pos: Vector2, p_color: Color) -> void:
	if _touch_ripples.size() >= MAX_ACTIVE_RIPPLES:
		_touch_ripples.remove_at(0)

	_fx_seed_counter += 1
	var variant: int = posmod((_fx_seed_counter * 7) + int(p_pos.x), TouchEffectRenderer.NOTE_VARIANT_COUNT)
	_touch_ripples.append({
		"pos": p_pos,
		"age": 0.0,
		"duration": TouchEffectRenderer.get_duration_for_style(_touch_effect_style),
		"color": p_color,
		"variant": variant,
	})
	queue_redraw()


func _spawn_judgment_particles(p_lane: int, p_grade: int) -> void:
	if p_grade == HitJudge.JudgmentGrade.MISS:
		return

	match _vanish_effect_style:
		GameplayEffectsConfig.VANISH_ZOOM_FADE:
			_spawn_zoom_fade_ghost(p_lane, p_grade)
		GameplayEffectsConfig.VANISH_FRACTURE:
			_spawn_fracture_shards(p_lane, p_grade)
		_:
			_spawn_firework_rays(p_lane, p_grade)

	queue_redraw()


func _init_vanish_effect_pools() -> void:
	_fw_active.resize(MAX_FIREWORK_RAYS)
	_fw_age.resize(MAX_FIREWORK_RAYS)
	_fw_duration.resize(MAX_FIREWORK_RAYS)
	_fw_origin.resize(MAX_FIREWORK_RAYS)
	_fw_dir.resize(MAX_FIREWORK_RAYS)
	_fw_max_dist.resize(MAX_FIREWORK_RAYS)
	_fw_ray_len.resize(MAX_FIREWORK_RAYS)
	_fw_color.resize(MAX_FIREWORK_RAYS)
	for i: int in range(MAX_FIREWORK_RAYS):
		_fw_active[i] = 0
		_fw_age[i] = 0.0
		_fw_duration[i] = 0.30
		_fw_origin[i] = Vector2.ZERO
		_fw_dir[i] = Vector2.UP
		_fw_max_dist[i] = 90.0
		_fw_ray_len[i] = 24.0
		_fw_color[i] = Color.WHITE

	_fw_drop_poly_buf.resize(4)
	_zf_active.resize(MAX_ZOOM_FADE_GHOSTS)
	_zf_age.resize(MAX_ZOOM_FADE_GHOSTS)
	_zf_duration.resize(MAX_ZOOM_FADE_GHOSTS)
	_zf_center.resize(MAX_ZOOM_FADE_GHOSTS)
	_zf_base_size.resize(MAX_ZOOM_FADE_GHOSTS)
	_zf_color.resize(MAX_ZOOM_FADE_GHOSTS)
	for j: int in range(MAX_ZOOM_FADE_GHOSTS):
		_zf_active[j] = 0
		_zf_age[j] = 0.0
		_zf_duration[j] = ZOOM_FADE_DURATION_SEC
		_zf_center[j] = Vector2.ZERO
		_zf_base_size[j] = Vector2(180.0, NoteView.DEFAULT_HEAD_HEIGHT_PX)
		_zf_color[j] = COLOR_PERFECT_A

	_fr_active.resize(MAX_FRACTURE_SHARDS)
	_fr_age.resize(MAX_FRACTURE_SHARDS)
	_fr_duration.resize(MAX_FRACTURE_SHARDS)
	_fr_pos.resize(MAX_FRACTURE_SHARDS)
	_fr_vel.resize(MAX_FRACTURE_SHARDS)
	_fr_angle.resize(MAX_FRACTURE_SHARDS)
	_fr_ang_vel.resize(MAX_FRACTURE_SHARDS)
	_fr_color.resize(MAX_FRACTURE_SHARDS)
	_fr_local_polys.clear()
	for k: int in range(MAX_FRACTURE_SHARDS):
		_fr_active[k] = 0
		_fr_age[k] = 0.0
		_fr_duration[k] = FRACTURE_DURATION_SEC
		_fr_pos[k] = Vector2.ZERO
		_fr_vel[k] = Vector2.ZERO
		_fr_angle[k] = 0.0
		_fr_ang_vel[k] = 0.0
		_fr_color[k] = COLOR_PERFECT_A
		var poly_slot: PackedVector2Array = PackedVector2Array()
		poly_slot.resize(4)
		_fr_local_polys.append(poly_slot)
	_fr_world_poly_buf.resize(4)


func _clear_vanish_effect_pools() -> void:
	for i: int in range(_fw_active.size()):
		_fw_active[i] = 0
	for j: int in range(_zf_active.size()):
		_zf_active[j] = 0
	for k: int in range(_fr_active.size()):
		_fr_active[k] = 0
	_fw_cursor = 0
	_zf_cursor = 0
	_fr_cursor = 0


func _step_vanish_effect_pools(p_dt: float) -> bool:
	var any_active: bool = false

	for i: int in range(_fw_active.size()):
		if _fw_active[i] == 0:
			continue
		var next_age: float = _fw_age[i] + p_dt
		if next_age >= _fw_duration[i]:
			_fw_active[i] = 0
		else:
			_fw_age[i] = next_age
		any_active = true

	for j: int in range(_zf_active.size()):
		if _zf_active[j] == 0:
			continue
		var next_age: float = _zf_age[j] + p_dt
		if next_age >= _zf_duration[j]:
			_zf_active[j] = 0
		else:
			_zf_age[j] = next_age
		any_active = true

	for k: int in range(_fr_active.size()):
		if _fr_active[k] == 0:
			continue
		var next_age: float = _fr_age[k] + p_dt
		if next_age >= _fr_duration[k]:
			_fr_active[k] = 0
		else:
			_fr_age[k] = next_age
			var vel: Vector2 = _fr_vel[k]
			vel.y += FRACTURE_GRAVITY_PX_PER_SEC2 * p_dt
			_fr_vel[k] = vel
			_fr_pos[k] = _fr_pos[k] + (vel * p_dt)
			_fr_angle[k] = _fr_angle[k] + (_fr_ang_vel[k] * p_dt)
		any_active = true

	return any_active


func _spawn_firework_rays(p_lane: int, p_grade: int) -> void:
	var ray_count: int = FIREWORK_RAYS_GOOD
	var max_dist_base: float = 82.0
	var ray_len_base: float = 22.0
	var dur_sec: float = 0.26
	match p_grade:
		HitJudge.JudgmentGrade.PERFECT:
			ray_count = FIREWORK_RAYS_PERFECT
			max_dist_base = 122.0
			ray_len_base = 34.0
			dur_sec = 0.34
		HitJudge.JudgmentGrade.GREAT:
			ray_count = FIREWORK_RAYS_GREAT
			max_dist_base = 100.0
			ray_len_base = 28.0
			dur_sec = 0.30
		HitJudge.JudgmentGrade.GOOD:
			ray_count = FIREWORK_RAYS_GOOD
			max_dist_base = 82.0
			ray_len_base = 22.0
			dur_sec = 0.26
		_:
			return

	var origin: Vector2 = Vector2((float(p_lane) + 0.5) * _lane_width, _hit_line_y)
	var palette_len: int = FIREWORK_NEON_COLORS.size()
	var phase_rot: float = _pseudo_rand_signed(_fx_seed_counter + (p_lane * 37)) * 0.35

	for i: int in range(ray_count):
		_fx_seed_counter += 1
		var slot: int = _fw_cursor
		_fw_cursor = (_fw_cursor + 1) % MAX_FIREWORK_RAYS

		var angle_rad: float = ((float(i) / float(ray_count)) * TAU) + phase_rot + (_pseudo_rand_signed(_fx_seed_counter * 13) * 0.16)
		var dist_jitter: float = 0.80 + (0.40 * (0.5 + 0.5 * _pseudo_rand_signed(_fx_seed_counter * 29)))
		var col: Color = FIREWORK_NEON_COLORS[posmod(i + _fx_seed_counter, palette_len)]

		_fw_active[slot] = 1
		_fw_age[slot] = 0.0
		_fw_duration[slot] = dur_sec * (0.90 + (0.18 * (0.5 + 0.5 * _pseudo_rand_signed(_fx_seed_counter * 17))))
		_fw_origin[slot] = origin
		_fw_dir[slot] = Vector2(cos(angle_rad), sin(angle_rad))
		_fw_max_dist[slot] = max_dist_base * dist_jitter
		_fw_ray_len[slot] = ray_len_base * dist_jitter
		_fw_color[slot] = col


func _spawn_zoom_fade_ghost(p_lane: int, p_grade: int) -> void:
	var col: Color = COLOR_GOOD_A
	match p_grade:
		HitJudge.JudgmentGrade.PERFECT:
			col = COLOR_PERFECT_A
		HitJudge.JudgmentGrade.GREAT:
			col = COLOR_GREAT_B
		HitJudge.JudgmentGrade.GOOD:
			col = COLOR_GOOD_A
		_:
			return

	var slot: int = _zf_cursor
	_zf_cursor = (_zf_cursor + 1) % MAX_ZOOM_FADE_GHOSTS
	var visual_w: float = maxf(12.0, _lane_width - (NoteView.HORIZONTAL_PADDING_PX * 2.0))
	_zf_active[slot] = 1
	_zf_age[slot] = 0.0
	_zf_duration[slot] = ZOOM_FADE_DURATION_SEC
	_zf_center[slot] = Vector2((float(p_lane) + 0.5) * _lane_width, _hit_line_y)
	_zf_base_size[slot] = Vector2(visual_w, NoteView.DEFAULT_HEAD_HEIGHT_PX)
	_zf_color[slot] = col


func _spawn_fracture_shards(p_lane: int, p_grade: int) -> void:
	var shard_count: int = FRACTURE_SHARDS_GOOD
	var tint: Color = COLOR_GOOD_A
	match p_grade:
		HitJudge.JudgmentGrade.PERFECT:
			shard_count = FRACTURE_SHARDS_PERFECT
			tint = Color(0.42, 0.98, 1.0, 1.0)
		HitJudge.JudgmentGrade.GREAT:
			shard_count = FRACTURE_SHARDS_GREAT
			tint = Color(0.32, 0.94, 0.88, 1.0)
		HitJudge.JudgmentGrade.GOOD:
			shard_count = FRACTURE_SHARDS_GOOD
			tint = COLOR_GOOD_A
		_:
			return

	var origin: Vector2 = Vector2((float(p_lane) + 0.5) * _lane_width, _hit_line_y)
	var visual_w: float = maxf(24.0, _lane_width - (NoteView.HORIZONTAL_PADDING_PX * 2.0))
	var half_w: float = visual_w * 0.5
	var half_h: float = NoteView.DEFAULT_HEAD_HEIGHT_PX * 0.5
	var step_w: float = visual_w / float(shard_count)

	var prev_top_x: float = -half_w
	var prev_bot_x: float = -half_w
	for i: int in range(shard_count):
		_fx_seed_counter += 1
		var slot: int = _fr_cursor
		_fr_cursor = (_fr_cursor + 1) % MAX_FRACTURE_SHARDS

		var next_top_x: float = half_w
		var next_bot_x: float = half_w
		if i < shard_count - 1:
			var base_cut: float = -half_w + (float(i + 1) * step_w)
			next_top_x = clampf(base_cut + (_pseudo_rand_signed(_fx_seed_counter * 11) * step_w * 0.34), prev_top_x + 4.0, half_w - 4.0)
			next_bot_x = clampf(base_cut + (_pseudo_rand_signed(_fx_seed_counter * 23) * step_w * 0.34), prev_bot_x + 4.0, half_w - 4.0)

		var top_y_l: float = -half_h + (_pseudo_rand_signed(_fx_seed_counter * 7) * 3.0)
		var top_y_r: float = -half_h + (_pseudo_rand_signed(_fx_seed_counter * 19) * 3.0)
		var bot_y_r: float = half_h + (_pseudo_rand_signed(_fx_seed_counter * 31) * 3.0)
		var bot_y_l: float = half_h + (_pseudo_rand_signed(_fx_seed_counter * 41) * 3.0)

		var cx: float = (prev_top_x + next_top_x + next_bot_x + prev_bot_x) * 0.25
		var cy: float = (top_y_l + top_y_r + bot_y_r + bot_y_l) * 0.25

		var local_poly: PackedVector2Array = _fr_local_polys[slot]
		local_poly[0] = Vector2(prev_top_x - cx, top_y_l - cy)
		local_poly[1] = Vector2(next_top_x - cx, top_y_r - cy)
		local_poly[2] = Vector2(next_bot_x - cx, bot_y_r - cy)
		local_poly[3] = Vector2(prev_bot_x - cx, bot_y_l - cy)

		var norm_x: float = clampf(cx / maxf(1.0, half_w), -1.0, 1.0)
		var vx: float = (norm_x * 135.0) + (_pseudo_rand_signed(_fx_seed_counter * 53) * 48.0)
		var vy: float = lerpf(150.0, 310.0, 0.5 + 0.5 * _pseudo_rand_signed(_fx_seed_counter * 61))

		_fr_active[slot] = 1
		_fr_age[slot] = 0.0
		_fr_duration[slot] = FRACTURE_DURATION_SEC * (0.90 + (0.18 * (0.5 + 0.5 * _pseudo_rand_signed(_fx_seed_counter * 71))))
		_fr_pos[slot] = origin + Vector2(cx, cy + 4.0)
		_fr_vel[slot] = Vector2(vx, vy)
		_fr_angle[slot] = 0.0
		_fr_ang_vel[slot] = _pseudo_rand_signed(_fx_seed_counter * 79) * 5.2
		_fr_color[slot] = tint.lerp(Color(0.84, 0.99, 1.0, 1.0), 0.28 if (i % 2) == 0 else 0.0)

		prev_top_x = next_top_x
		prev_bot_x = next_bot_x


func _draw_vanish_effects() -> void:
	# 1. FireWork thick elongated neon droplets (rounded glowing head + short tapered conical tail)
	for i: int in range(_fw_active.size()):
		if _fw_active[i] == 0:
			continue
		var dur: float = maxf(0.01, _fw_duration[i])
		var t: float = clampf(_fw_age[i] / dur, 0.0, 1.0)
		var eased_head: float = 1.0 - pow(1.0 - t, 2.4)
		var head_dist: float = _fw_max_dist[i] * eased_head
		var tail_len: float = _fw_ray_len[i] * (1.0 - (t * 0.58))
		var tail_dist: float = maxf(0.0, head_dist - tail_len)
		var dir: Vector2 = _fw_dir[i]
		var perp: Vector2 = Vector2(-dir.y, dir.x)
		var origin: Vector2 = _fw_origin[i]
		var p_tail: Vector2 = origin + (dir * tail_dist)
		var p_head: Vector2 = origin + (dir * head_dist)
		var fade: float = (1.0 - t) * (1.0 - (t * 0.22))
		var head_r: float = lerpf(FIREWORK_DROPLET_BASE_RADIUS_PX, 2.8, t)
		var base_col: Color = _fw_color[i]
		var halo_col: Color = Color(base_col.r, base_col.g, base_col.b, fade * 0.30)
		var body_col: Color = Color(base_col.r, base_col.g, base_col.b, fade * 0.96)
		var core_col: Color = Color(
			lerpf(base_col.r, 1.0, 0.62),
			lerpf(base_col.g, 1.0, 0.62),
			lerpf(base_col.b, 1.0, 0.62),
			fade * 0.98
		)

		# Outer neon halo (teardrop cone + rounded glow)
		var halo_r: float = head_r * 1.72
		_fw_drop_poly_buf[0] = p_tail
		_fw_drop_poly_buf[1] = p_head + (perp * halo_r)
		_fw_drop_poly_buf[2] = p_head + (dir * (halo_r * 0.65))
		_fw_drop_poly_buf[3] = p_head - (perp * halo_r)
		draw_colored_polygon(_fw_drop_poly_buf, halo_col)
		draw_circle(p_head, head_r * 2.05, halo_col)

		# Saturated neon elongated droplet body (tapered conical wake + rounded head)
		_fw_drop_poly_buf[0] = p_tail
		_fw_drop_poly_buf[1] = p_head + (perp * head_r)
		_fw_drop_poly_buf[2] = p_head + (dir * (head_r * 0.55))
		_fw_drop_poly_buf[3] = p_head - (perp * head_r)
		draw_colored_polygon(_fw_drop_poly_buf, body_col)
		draw_circle(p_head, head_r, body_col)

		# Bright specular highlight inside the rounded droplet head
		draw_circle(p_head, head_r * 0.48, core_col)

	# 2. Zoom + Fade expanding ghosts (scale 1.0 -> 1.35, alpha 1.0 -> 0.0)
	for j: int in range(_zf_active.size()):
		if _zf_active[j] == 0:
			continue
		var dur: float = maxf(0.01, _zf_duration[j])
		var t: float = clampf(_zf_age[j] / dur, 0.0, 1.0)
		var scale_f: float = compute_zoom_fade_scale(t)
		var fade: float = (1.0 - t) * (1.0 - (t * 0.30))
		var sz: Vector2 = _zf_base_size[j] * scale_f
		var center: Vector2 = _zf_center[j]
		var col: Color = _zf_color[j]

		var halo_sz: Vector2 = sz + Vector2(16.0, 12.0)
		draw_rect(
			Rect2(center - (halo_sz * 0.5), halo_sz),
			Color(col.r, col.g, col.b, fade * 0.26),
			true
		)
		draw_rect(
			Rect2(center - (sz * 0.5), sz),
			Color(lerpf(col.r, 1.0, 0.25), lerpf(col.g, 1.0, 0.25), lerpf(col.b, 1.0, 0.25), fade * 0.85),
			true
		)

	# 3. Fracture polygonal shards (zero allocations via reused _fr_world_poly_buf)
	for k: int in range(_fr_active.size()):
		if _fr_active[k] == 0:
			continue
		var dur: float = maxf(0.01, _fr_duration[k])
		var t: float = clampf(_fr_age[k] / dur, 0.0, 1.0)
		var fade: float = (1.0 - t) * (1.0 - (t * 0.35))
		var pos: Vector2 = _fr_pos[k]
		var cos_a: float = cos(_fr_angle[k])
		var sin_a: float = sin(_fr_angle[k])
		var local_poly: PackedVector2Array = _fr_local_polys[k]
		for v_idx: int in range(4):
			var lp: Vector2 = local_poly[v_idx]
			_fr_world_poly_buf[v_idx] = pos + Vector2(
				(lp.x * cos_a) - (lp.y * sin_a),
				(lp.x * sin_a) + (lp.y * cos_a)
			)
		var col: Color = _fr_color[k]
		draw_colored_polygon(
			_fr_world_poly_buf,
			Color(col.r, col.g, col.b, fade * 0.90)
		)


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
		var col: Color = COLOR_HOLD_SPARK if (i % 2) == 0 else COLOR_HOLD_ABSORB_CYAN
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
		_lane_pending_hold_completion[j] = false
		_lane_hold_phase[j] = 0.0
		_lane_hold_energy[j] = 0.0
		_lane_hold_complete_flare[j] = 0.0
	for k: int in range(_touch_ripple_consumed_for_lane.size()):
		_touch_ripple_consumed_for_lane[k] = false
	_touch_ripples.clear()
	_hold_absorb_rings.clear()
	_hit_particles.clear()
	_clear_vanish_effect_pools()
	_hold_spark_accumulator_sec = 0.0
	_hold_ring_accumulator_sec = 0.0
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
