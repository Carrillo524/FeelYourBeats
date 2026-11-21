class_name ReactiveBackground
extends ColorRect

enum BackdropMode {
	MENU = 0,
	GAMEPLAY = 1,
}

signal screen_shake_updated(p_offset: Vector2)
signal bass_kick_pulsed(p_strength: float)

const SHADER_PATH: String = "res://vfx/reactive_backdrop.gdshader"
const BEAT_DECAY_PER_SEC: float = 4.5
const LANE_FLASH_DECAY_PER_SEC: float = 5.5
const ENERGY_LERP_SPEED: float = 6.0
const SPECTRUM_ATTACK_SPEED: float = 14.0
const SPECTRUM_DECAY_SPEED: float = 6.5
const ZOOM_DECAY_SPEED: float = 7.0
const MAX_ZOOM_BOUNCE: float = 0.25
const AMBIENT_BREATH_SPEED: float = 1.6
const AMBIENT_ZOOM_AMPLITUDE: float = 0.018
const SHAKE_DECAY_SPEED: float = 8.5
const SHAKE_OSCILLATION_SPEED: float = 42.0
const MAX_SHAKE_PX: float = 6.5
const EDGE_BEAT_DECAY_RATE: float = 14.5
const EDGE_DROP_INTENSITY_DECAY_RATE: float = 6.5
const EDGE_DROP_DECAY_SPEED: float = 5.0
const EDGE_WIDTH_RELAX_SPEED: float = 6.0
const EDGE_BASE_WIDTH: float = 0.008
const EDGE_MAX_REACH_VERTICAL: float = 0.028
const EDGE_MAX_REACH_LATERAL: float = 0.044
const EDGE_LATERAL_WAVE_BOOST: float = 1.60
const EDGE_MAX_OPACITY: float = 0.52
const EDGE_EPSILON: float = 0.004

const MAX_WAVE_RINGS: int = 14
const WAVE_ARC_POINTS: int = 64
const WAVE_AMBIENT_INTERVAL_SEC: float = 1.85
const WAVE_PULSE_COOLDOWN_SEC: float = 0.14
const WAVE_FADE_IN_END: float = 0.08
const WAVE_EDGE_FADE_START: float = 0.60
const WAVE_BASE_TOP_COLOR: Color = Color(0.035, 0.045, 0.11, 1.0)
const WAVE_BASE_BOTTOM_COLOR: Color = Color(0.075, 0.03, 0.145, 1.0)
const WAVE_RING_PALETTE: Array[Color] = [
	Color(0.24, 0.90, 1.0, 1.0),
	Color(0.68, 0.36, 1.0, 1.0),
	Color(0.36, 0.72, 1.0, 1.0),
]

@export var dsp_clock: DSPClock = null
@export var hit_judge: HitJudge = null
@export var audio_analyzer: AudioAnalyzer = null
@export var perimeter_wave_enabled: bool = false
@export var edge_primary_color: Color = Color(0.28, 0.86, 1.0, 1.0)
@export var edge_drop_color: Color = Color(0.46, 0.92, 1.0, 1.0)

var edge_glow_intensity: float = 0.0
var edge_glow_width: float = EDGE_BASE_WIDTH
var edge_drop_boost: float = 0.0
var wave_amplitude: float = 0.65
var wave_blur_intensity: float = 0.10

var _shader_material: ShaderMaterial = null
var _bg_config: ReactiveBackgroundConfig = ReactiveBackgroundConfig.new()
var _backdrop_mode: int = BackdropMode.GAMEPLAY
var _menu_bgm_active: bool = true
var _aspect_ratio: float = 1080.0 / 1920.0
var _beat_pulse: float = 0.0
var _current_energy: float = 0.2
var _target_energy: float = 0.2
var _current_tier: int = 0
var _lane_flashes: Vector4 = Vector4.ZERO
var _target_bass: float = 0.0
var _target_mid: float = 0.0
var _target_high: float = 0.0
var _smoothed_bass: float = 0.0
var _smoothed_mid: float = 0.0
var _smoothed_high: float = 0.0
var _prev_bass_sample: float = 0.0
var _zoom_bounce: float = 0.0
var _ambient_phase: float = 0.0
var _shake_intensity: float = 0.0
var _shake_phase: float = 0.0
var _shake_offset_px: Vector2 = Vector2.ZERO
var _shake_offset_uv: Vector2 = Vector2.ZERO
var _beat_pulse_count: int = 0
var _intensity_change_count: int = 0
var _spectrum_update_count: int = 0

# Fixed-capacity wave ring pool (0 heap allocations per frame)
var _wave_active_count: int = 0
var _wave_radii: PackedFloat32Array = PackedFloat32Array()
var _wave_speeds: PackedFloat32Array = PackedFloat32Array()
var _wave_widths: PackedFloat32Array = PackedFloat32Array()
var _wave_strengths: PackedFloat32Array = PackedFloat32Array()
var _wave_color_indices: PackedInt32Array = PackedInt32Array()
var _wave_ambient_timer: float = 0.0
var _wave_pulse_cooldown: float = 0.0
var _wave_color_cursor: int = 0
var _wave_pulse_emit_count: int = 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0.05, 0.05, 0.12, 1.0)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_shader_material()
	_allocate_wave_pool()
	_apply_active_style_mode()
	connect_dependencies()
	_sync_shader_parameters()


func connect_dependencies() -> void:
	if dsp_clock != null:
		if not dsp_clock.beat_pulsed.is_connected(_on_beat_pulsed):
			dsp_clock.beat_pulsed.connect(_on_beat_pulsed)
		if not dsp_clock.intensity_changed.is_connected(_on_intensity_changed):
			dsp_clock.intensity_changed.connect(_on_intensity_changed)

	if hit_judge != null:
		if not hit_judge.note_judged.is_connected(_on_note_judged):
			hit_judge.note_judged.connect(_on_note_judged)

	if audio_analyzer != null:
		if not audio_analyzer.spectrum_updated.is_connected(_on_spectrum_updated):
			audio_analyzer.spectrum_updated.connect(_on_spectrum_updated)


func _process(p_delta: float) -> void:
	var dt: float = maxf(0.0, p_delta)
	_ambient_phase += dt * AMBIENT_BREATH_SPEED
	_shake_phase += dt * SHAKE_OSCILLATION_SPEED

	_beat_pulse = maxf(0.0, _beat_pulse - (BEAT_DECAY_PER_SEC * dt))
	_current_energy = lerpf(_current_energy, _target_energy, clampf(ENERGY_LERP_SPEED * dt, 0.0, 1.0))

	var bass_rate: float = SPECTRUM_ATTACK_SPEED if _target_bass > _smoothed_bass else SPECTRUM_DECAY_SPEED
	var mid_rate: float = SPECTRUM_ATTACK_SPEED if _target_mid > _smoothed_mid else SPECTRUM_DECAY_SPEED
	var high_rate: float = SPECTRUM_ATTACK_SPEED if _target_high > _smoothed_high else SPECTRUM_DECAY_SPEED

	_smoothed_bass = lerpf(_smoothed_bass, _target_bass, clampf(bass_rate * dt, 0.0, 1.0))
	_smoothed_mid = lerpf(_smoothed_mid, _target_mid, clampf(mid_rate * dt, 0.0, 1.0))
	_smoothed_high = lerpf(_smoothed_high, _target_high, clampf(high_rate * dt, 0.0, 1.0))

	_target_bass = maxf(0.0, _target_bass - (SPECTRUM_DECAY_SPEED * dt))
	_target_mid = maxf(0.0, _target_mid - (SPECTRUM_DECAY_SPEED * dt))
	_target_high = maxf(0.0, _target_high - (SPECTRUM_DECAY_SPEED * dt))

	var ambient_breath: float = (sin(_ambient_phase) * 0.5 + 0.5) * AMBIENT_ZOOM_AMPLITUDE
	var target_zoom: float = clampf(
		(_smoothed_bass * 0.16) + (_beat_pulse * 0.07) + ambient_breath,
		0.0,
		MAX_ZOOM_BOUNCE
	)
	_zoom_bounce = lerpf(_zoom_bounce, target_zoom, clampf(ZOOM_DECAY_SPEED * dt, 0.0, 1.0))

	_shake_intensity = maxf(0.0, _shake_intensity - (SHAKE_DECAY_SPEED * dt))
	if _shake_intensity > 0.001:
		var tier_mult: float = 1.35 if _current_tier >= 2 else 0.75
		var amp_px: float = _shake_intensity * MAX_SHAKE_PX * tier_mult
		_shake_offset_px = Vector2(
			sin(_shake_phase * 1.73) * amp_px,
			cos(_shake_phase * 2.29) * amp_px * 0.85
		)
		_shake_offset_uv = Vector2(
			_shake_offset_px.x / 1080.0,
			_shake_offset_px.y / 1920.0
		)
	else:
		_shake_offset_px = Vector2.ZERO
		_shake_offset_uv = Vector2.ZERO

	screen_shake_updated.emit(_shake_offset_px)

	var lane_decay: float = LANE_FLASH_DECAY_PER_SEC * dt
	_lane_flashes.x = maxf(0.0, _lane_flashes.x - lane_decay)
	_lane_flashes.y = maxf(0.0, _lane_flashes.y - lane_decay)
	_lane_flashes.z = maxf(0.0, _lane_flashes.z - lane_decay)
	_lane_flashes.w = maxf(0.0, _lane_flashes.w - lane_decay)

	_update_edge_halo(dt)
	if is_waves_style_active():
		step_wave_rings(dt)
	else:
		_sync_shader_parameters()


func _draw() -> void:
	if not is_waves_style_active():
		return
	_draw_waves_backdrop()


func apply_background_config(p_config: ReactiveBackgroundConfig) -> void:
	if p_config == null:
		_bg_config.reset_to_defaults()
	else:
		_bg_config.copy_from(p_config)
	_apply_active_style_mode()


func get_background_config_snapshot() -> ReactiveBackgroundConfig:
	return _bg_config.duplicate_config()


func get_active_style() -> String:
	return _bg_config.style


func is_waves_style_active() -> bool:
	return _bg_config.style == ReactiveBackgroundConfig.STYLE_WAVES


func get_active_wave_ring_count() -> int:
	return _wave_active_count


func get_wave_pulse_emit_count() -> int:
	return _wave_pulse_emit_count


func get_wave_ring_radii_snapshot() -> PackedFloat32Array:
	var result: PackedFloat32Array = PackedFloat32Array()
	result.resize(_wave_active_count)
	for i: int in range(_wave_active_count):
		result[i] = _wave_radii[i]
	return result


func get_wave_ring_alphas_snapshot() -> PackedFloat32Array:
	var result: PackedFloat32Array = PackedFloat32Array()
	result.resize(_wave_active_count)
	var max_r: float = _compute_wave_max_radius(_resolve_draw_bounds())
	for i: int in range(_wave_active_count):
		result[i] = _compute_wave_ring_alpha(_wave_radii[i], _wave_strengths[i], max_r)
	return result


func trigger_wave_pulse(p_strength: float = 0.85, p_is_drop: bool = false, p_bypass_cooldown: bool = false) -> void:
	if not is_waves_style_active():
		return
	if not p_bypass_cooldown and _wave_pulse_cooldown > 0.0:
		return

	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var s: float = clampf(p_strength, 0.25, 1.0)
	var speed: float = lerpf(225.0, 340.0, s) * (1.18 if p_is_drop else 1.0) * lerpf(0.78, 1.24, (react_mult - 0.55) / 0.90)
	var width_px: float = lerpf(2.2, 3.6, s) * (1.25 if p_is_drop else 1.0)
	var strength: float = clampf((0.36 + (0.20 * s) + (0.08 if p_is_drop else 0.0)) * lerpf(0.75, 1.15, (react_mult - 0.55) / 0.90), 0.26, 0.58)
	var col_idx: int = 1 if p_is_drop else (_wave_color_cursor % WAVE_RING_PALETTE.size())
	_wave_color_cursor += 1
	_spawn_wave_ring(16.0, speed, width_px, strength, col_idx)
	_wave_pulse_cooldown = WAVE_PULSE_COOLDOWN_SEC
	_wave_pulse_emit_count += 1
	queue_redraw()


func step_wave_rings(p_delta: float) -> void:
	if not is_waves_style_active():
		return
	var dt: float = clampf(p_delta, 0.0, 0.1)
	var bounds: Vector2 = _resolve_draw_bounds()
	var max_r: float = _compute_wave_max_radius(bounds)
	var react_mult: float = _bg_config.get_reactivity_multiplier()

	_wave_pulse_cooldown = maxf(0.0, _wave_pulse_cooldown - dt)
	_wave_ambient_timer += dt
	if _wave_ambient_timer >= WAVE_AMBIENT_INTERVAL_SEC:
		_wave_ambient_timer = fmod(_wave_ambient_timer, WAVE_AMBIENT_INTERVAL_SEC)
		var col_idx: int = _wave_color_cursor % WAVE_RING_PALETTE.size()
		_wave_color_cursor += 1
		_spawn_wave_ring(10.0, 152.0, 2.0, 0.34, col_idx)

	var dynamic_boost: float = 1.0 + (((_beat_pulse * 0.45) + (_smoothed_bass * 0.30)) * react_mult)
	var write_idx: int = 0
	for read_idx: int in range(_wave_active_count):
		var next_r: float = _wave_radii[read_idx] + (_wave_speeds[read_idx] * dynamic_boost * dt)
		if next_r < max_r:
			_wave_radii[write_idx] = next_r
			_wave_speeds[write_idx] = _wave_speeds[read_idx]
			_wave_widths[write_idx] = _wave_widths[read_idx]
			_wave_strengths[write_idx] = _wave_strengths[read_idx]
			_wave_color_indices[write_idx] = _wave_color_indices[read_idx]
			write_idx += 1
	_wave_active_count = write_idx
	queue_redraw()


func set_perimeter_wave_enabled(p_enabled: bool) -> void:
	perimeter_wave_enabled = p_enabled
	if not perimeter_wave_enabled:
		edge_glow_intensity = 0.0
		edge_drop_boost = 0.0
		edge_glow_width = EDGE_BASE_WIDTH
		wave_blur_intensity = 0.0
	_sync_shader_parameters()


func is_perimeter_wave_enabled() -> bool:
	return perimeter_wave_enabled


func set_backdrop_mode(p_mode: int) -> void:
	_backdrop_mode = clampi(p_mode, BackdropMode.MENU, BackdropMode.GAMEPLAY)
	if _backdrop_mode == BackdropMode.MENU:
		edge_drop_boost = 0.0
	_sync_shader_parameters()


func set_menu_bgm_active(p_active: bool) -> void:
	_menu_bgm_active = p_active
	if not _menu_bgm_active and _backdrop_mode == BackdropMode.MENU:
		_target_bass = 0.0
		_target_mid = 0.0
		_target_high = 0.0
		_beat_pulse = 0.0
	_sync_shader_parameters()


func inject_audio_metrics(
	p_bass_energy: float,
	p_mid_energy: float,
	p_high_energy: float,
	p_total_energy: float,
	p_beat_pulsed: bool = false
) -> void:
	_on_spectrum_updated(p_bass_energy, p_mid_energy, p_high_energy, p_total_energy)
	if p_beat_pulsed:
		_on_beat_pulsed(_beat_pulse_count + 1, 0.0)


func get_edge_glow_intensity() -> float:
	return edge_glow_intensity


func get_edge_glow_width() -> float:
	return edge_glow_width


func get_edge_drop_boost() -> float:
	return edge_drop_boost


func get_aspect_ratio() -> float:
	return _aspect_ratio


func get_wave_amplitude() -> float:
	return wave_amplitude


func get_wave_blur_intensity() -> float:
	return wave_blur_intensity


func get_effective_wave_reach() -> float:
	return get_effective_lateral_wave_reach()


func get_effective_lateral_wave_reach() -> float:
	if not perimeter_wave_enabled:
		return 0.0
	var spectral_max: float = ((_smoothed_bass * 0.0075) + (_smoothed_mid * 0.0055) + (_smoothed_high * 0.0035)) * wave_amplitude
	var beat_max: float = (edge_glow_intensity * 0.013) + (edge_drop_boost * 0.015)
	return clampf(0.015 + ((spectral_max + beat_max) * EDGE_LATERAL_WAVE_BOOST), 0.005, EDGE_MAX_REACH_LATERAL)


func get_effective_vertical_wave_reach() -> float:
	if not perimeter_wave_enabled:
		return 0.0
	var spectral_max: float = ((_smoothed_bass * 0.0075) + (_smoothed_mid * 0.0055) + (_smoothed_high * 0.0035)) * wave_amplitude
	var beat_max: float = (edge_glow_intensity * 0.013) + (edge_drop_boost * 0.015)
	return clampf(0.010 + spectral_max + beat_max, 0.006, EDGE_MAX_REACH_VERTICAL)


func get_effective_wave_opacity() -> float:
	if not perimeter_wave_enabled:
		return 0.0
	return clampf(
		wave_blur_intensity + (edge_glow_intensity * 0.16) + (edge_drop_boost * 0.22),
		0.0,
		EDGE_MAX_OPACITY
	)


func get_smoothed_mid_energy() -> float:
	return _smoothed_mid


func get_smoothed_high_energy() -> float:
	return _smoothed_high


func reset_shake() -> void:
	_shake_intensity = 0.0
	_shake_offset_px = Vector2.ZERO
	_shake_offset_uv = Vector2.ZERO
	_sync_shader_parameters()
	screen_shake_updated.emit(Vector2.ZERO)


func get_shake_offset() -> Vector2:
	return _shake_offset_px


func get_current_tier() -> int:
	return _current_tier


func get_target_energy() -> float:
	return _target_energy


func get_beat_pulse_value() -> float:
	return _beat_pulse


func get_lane_flashes() -> Vector4:
	return _lane_flashes


func get_zoom_bounce_value() -> float:
	return _zoom_bounce


func get_smoothed_bass_energy() -> float:
	return _smoothed_bass


func get_beat_pulse_count() -> int:
	return _beat_pulse_count


func get_intensity_change_count() -> int:
	return _intensity_change_count


func get_spectrum_update_count() -> int:
	return _spectrum_update_count


func _on_beat_pulsed(_p_beat_index: int, _p_beat_time_sec: float) -> void:
	_beat_pulse = 1.0
	_zoom_bounce = clampf(_zoom_bounce + 0.05, 0.0, MAX_ZOOM_BOUNCE)
	_beat_pulse_count += 1

	var tier_norm: float = float(_current_tier) / 3.0
	var kick_strength: float = clampf(0.42 + (0.38 * maxf(_smoothed_bass, _target_bass)) + (0.20 * tier_norm), 0.25, 1.0)
	_shake_intensity = clampf(maxf(_shake_intensity, kick_strength * (0.45 + 0.55 * tier_norm)), 0.0, 1.0)
	_trigger_edge_beat_impulse(kick_strength)
	trigger_wave_pulse(kick_strength, false)
	bass_kick_pulsed.emit(kick_strength)
	_sync_shader_parameters()


func _on_intensity_changed(p_block: IntensityBlock) -> void:
	if p_block == null:
		return
	var prev_tier: int = _current_tier
	_target_energy = clampf(p_block.energy, 0.0, 1.0)
	_current_tier = clampi(p_block.tier, IntensityBlock.MIN_TIER, IntensityBlock.MAX_TIER)
	_intensity_change_count += 1
	if _current_tier >= 2 and _current_tier > prev_tier:
		_shake_intensity = clampf(maxf(_shake_intensity, 0.85), 0.0, 1.0)
		_trigger_edge_beat_impulse(0.95)
		trigger_wave_pulse(0.95, true)
		bass_kick_pulsed.emit(0.95)
	_sync_shader_parameters()


func _on_spectrum_updated(
	p_bass_energy: float,
	p_mid_energy: float,
	p_high_energy: float,
	p_total_energy: float
) -> void:
	var clamped_bass: float = clampf(p_bass_energy, 0.0, 1.0)
	var clamped_total: float = clampf(p_total_energy, 0.0, 1.0)
	var bass_jump: float = clamped_bass - _prev_bass_sample
	_prev_bass_sample = clamped_bass

	_target_bass = clamped_bass
	_target_mid = clampf(p_mid_energy, 0.0, 1.0)
	_target_high = clampf(p_high_energy, 0.0, 1.0)
	_target_energy = clampf(maxf(_target_energy * 0.75, clamped_total), 0.0, 1.0)
	_spectrum_update_count += 1

	var is_bass_transient: bool = bass_jump >= 0.14 or (clamped_bass >= 0.58 and bass_jump >= 0.06)
	var is_gameplay_drop: bool = (
		_backdrop_mode == BackdropMode.GAMEPLAY
		and clamped_bass >= 0.78
		and clamped_total >= 0.78
	)

	if is_bass_transient:
		var tier_norm: float = float(_current_tier) / 3.0
		var kick_strength: float = clampf(clamped_bass * 0.72 + bass_jump * 0.65, 0.25, 1.0)
		_shake_intensity = clampf(maxf(_shake_intensity, kick_strength * (0.45 + 0.55 * tier_norm)), 0.0, 1.0)
		_trigger_edge_beat_impulse(kick_strength)
		trigger_wave_pulse(kick_strength, is_gameplay_drop)
		bass_kick_pulsed.emit(kick_strength)
	elif is_gameplay_drop:
		var drop_strength: float = clampf((clamped_bass * 0.55) + (clamped_total * 0.45), 0.75, 1.0)
		_trigger_edge_drop_impulse(drop_strength)
		trigger_wave_pulse(drop_strength, true)

	_sync_shader_parameters()


func _on_note_judged(p_lane: int, p_grade: int, _p_error_ms: float, _p_combo: int) -> void:
	var flash_strength: float = 0.0
	match p_grade:
		HitJudge.JudgmentGrade.PERFECT:
			flash_strength = 1.0
		HitJudge.JudgmentGrade.GREAT:
			flash_strength = 0.72
		HitJudge.JudgmentGrade.GOOD:
			flash_strength = 0.45
		_:
			flash_strength = 0.0

	if flash_strength <= 0.0:
		return

	match p_lane:
		0:
			_lane_flashes.x = maxf(_lane_flashes.x, flash_strength)
		1:
			_lane_flashes.y = maxf(_lane_flashes.y, flash_strength)
		2:
			_lane_flashes.z = maxf(_lane_flashes.z, flash_strength)
		3:
			_lane_flashes.w = maxf(_lane_flashes.w, flash_strength)
		_:
			pass

	_sync_shader_parameters()


func _setup_shader_material() -> void:
	if _shader_material != null:
		return

	_shader_material = ShaderMaterial.new()
	if ResourceLoader.exists(SHADER_PATH):
		var loaded_shader: Resource = ResourceLoader.load(SHADER_PATH)
		if loaded_shader is Shader:
			_shader_material.shader = loaded_shader as Shader
	material = _shader_material


func _is_gameplay_drop_active() -> bool:
	if _backdrop_mode != BackdropMode.GAMEPLAY:
		return false
	var peak_bass: float = maxf(_smoothed_bass, _target_bass)
	var peak_energy: float = maxf(_current_energy, _target_energy)
	if peak_bass >= 0.72 and peak_energy >= 0.72:
		return true
	if _current_tier >= 2 and peak_bass >= 0.55:
		return true
	return false


func _trigger_edge_beat_impulse(p_strength: float) -> void:
	if not perimeter_wave_enabled:
		return
	var s: float = clampf(p_strength, 0.0, 1.0)
	if _backdrop_mode == BackdropMode.MENU:
		return

	if _is_gameplay_drop_active():
		_trigger_edge_drop_impulse(s)
		return

	var beat_peak: float = lerpf(0.55, 0.78, s)
	var beat_width: float = lerpf(0.014, 0.020, s)
	edge_glow_intensity = maxf(edge_glow_intensity, beat_peak)
	edge_glow_width = maxf(edge_glow_width, beat_width)


func _trigger_edge_drop_impulse(p_strength: float) -> void:
	if not perimeter_wave_enabled:
		return
	var s: float = clampf(p_strength, 0.0, 1.0)
	var drop_peak: float = lerpf(0.85, 1.0, s)
	var drop_width: float = lerpf(0.032, EDGE_MAX_REACH_LATERAL, s)
	var drop_mix: float = lerpf(0.85, 1.0, s)
	edge_glow_intensity = maxf(edge_glow_intensity, drop_peak)
	edge_glow_width = maxf(edge_glow_width, drop_width)
	edge_drop_boost = maxf(edge_drop_boost, drop_mix)


func _update_edge_halo(p_delta: float) -> void:
	var ref_size: Vector2 = size
	if ref_size.x <= 1.0 or ref_size.y <= 1.0:
		var vp_rect: Rect2 = get_viewport_rect()
		if vp_rect.size.x > 1.0 and vp_rect.size.y > 1.0:
			ref_size = vp_rect.size
		else:
			ref_size = Vector2(1080.0, 1920.0)
	_aspect_ratio = clampf(ref_size.x / maxf(1.0, ref_size.y), 0.25, 4.0)

	if not perimeter_wave_enabled:
		edge_glow_intensity = 0.0
		edge_drop_boost = 0.0
		edge_glow_width = EDGE_BASE_WIDTH
		wave_blur_intensity = 0.0
		return

	# Zero idle glow spike: impulses decay exponentially between beats and after drops
	var decay_rate: float = EDGE_DROP_INTENSITY_DECAY_RATE if edge_drop_boost > 0.25 else EDGE_BEAT_DECAY_RATE
	edge_glow_intensity *= exp(-decay_rate * p_delta)
	if edge_glow_intensity < EDGE_EPSILON:
		edge_glow_intensity = 0.0

	edge_drop_boost *= exp(-EDGE_DROP_DECAY_SPEED * p_delta)
	if edge_drop_boost < EDGE_EPSILON:
		edge_drop_boost = 0.0

	edge_glow_width = lerpf(
		edge_glow_width,
		EDGE_BASE_WIDTH,
		clampf(EDGE_WIDTH_RELAX_SPEED * p_delta, 0.0, 1.0)
	)

	var spectral_activity: float = clampf(
		(_smoothed_bass * 0.45) + (_smoothed_mid * 0.35) + (_smoothed_high * 0.25),
		0.0,
		1.0
	)
	var target_wave_amp: float = clampf(
		0.45 + (spectral_activity * 0.35) + (edge_glow_intensity * 0.18) + (edge_drop_boost * 0.25),
		0.40,
		1.15
	)
	# Base blur opacity (~0.10..0.15) so normal beats land at ~0.20..0.28 and drops cap at <= 0.52
	var target_blur_intensity: float = clampf(
		0.09 + (spectral_activity * 0.05) + (edge_drop_boost * 0.02),
		0.08,
		0.16
	)

	var wave_lerp: float = clampf(8.5 * p_delta, 0.0, 1.0)
	wave_amplitude = lerpf(wave_amplitude, target_wave_amp, wave_lerp)
	wave_blur_intensity = lerpf(wave_blur_intensity, target_blur_intensity, wave_lerp)


func _sync_shader_parameters() -> void:
	if _shader_material == null:
		return

	_shader_material.set_shader_parameter("beat_pulse", _beat_pulse)
	_shader_material.set_shader_parameter("energy_level", _current_energy)
	_shader_material.set_shader_parameter("intensity_tier", _current_tier)
	_shader_material.set_shader_parameter("lane_hit_energies", _lane_flashes)
	_shader_material.set_shader_parameter("bass_energy", _smoothed_bass)
	_shader_material.set_shader_parameter("mid_energy", _smoothed_mid)
	_shader_material.set_shader_parameter("high_energy", _smoothed_high)
	_shader_material.set_shader_parameter("zoom_bounce", _zoom_bounce)
	_shader_material.set_shader_parameter("shake_offset", _shake_offset_uv)
	_shader_material.set_shader_parameter("aspect_ratio", _aspect_ratio)
	_shader_material.set_shader_parameter("perimeter_wave_enabled", 1.0 if perimeter_wave_enabled else 0.0)
	_shader_material.set_shader_parameter("edge_glow_intensity", edge_glow_intensity)
	_shader_material.set_shader_parameter("edge_glow_width", edge_glow_width)
	_shader_material.set_shader_parameter("edge_drop_boost", edge_drop_boost)
	_shader_material.set_shader_parameter("wave_amplitude", wave_amplitude)
	_shader_material.set_shader_parameter("lateral_wave_boost", EDGE_LATERAL_WAVE_BOOST)
	_shader_material.set_shader_parameter("wave_blur_intensity", wave_blur_intensity)
	_shader_material.set_shader_parameter("edge_primary_color", edge_primary_color)
	_shader_material.set_shader_parameter("edge_drop_color", edge_drop_color)


func _allocate_wave_pool() -> void:
	if _wave_radii.size() == MAX_WAVE_RINGS:
		return
	_wave_radii.resize(MAX_WAVE_RINGS)
	_wave_speeds.resize(MAX_WAVE_RINGS)
	_wave_widths.resize(MAX_WAVE_RINGS)
	_wave_strengths.resize(MAX_WAVE_RINGS)
	_wave_color_indices.resize(MAX_WAVE_RINGS)


func _apply_active_style_mode() -> void:
	_allocate_wave_pool()
	if is_waves_style_active():
		material = null
		color = WAVE_BASE_TOP_COLOR
		if _wave_active_count <= 0:
			_seed_ambient_wave_rings()
		queue_redraw()
	else:
		_setup_shader_material()
		material = _shader_material
		_wave_active_count = 0
		_wave_ambient_timer = 0.0
		_wave_pulse_cooldown = 0.0
		_sync_shader_parameters()
		queue_redraw()


func _seed_ambient_wave_rings() -> void:
	var bounds: Vector2 = _resolve_draw_bounds()
	var max_r: float = _compute_wave_max_radius(bounds)
	_wave_active_count = 0
	_wave_ambient_timer = 0.0
	_wave_pulse_cooldown = 0.0
	var seed_fractions: PackedFloat32Array = PackedFloat32Array([0.16, 0.44, 0.72])
	for i: int in range(seed_fractions.size()):
		_spawn_wave_ring(
			max_r * seed_fractions[i],
			152.0,
			2.0,
			0.34,
			i % WAVE_RING_PALETTE.size()
		)
	_wave_color_cursor = seed_fractions.size()


func _spawn_wave_ring(
	p_radius: float,
	p_speed: float,
	p_width: float,
	p_strength: float,
	p_color_index: int
) -> void:
	_allocate_wave_pool()
	var slot: int = _wave_active_count
	if slot >= MAX_WAVE_RINGS:
		# Replace the oldest (largest radius) ring to stay strictly within budget
		var oldest_idx: int = 0
		var max_existing_r: float = _wave_radii[0]
		for i: int in range(1, MAX_WAVE_RINGS):
			if _wave_radii[i] > max_existing_r:
				max_existing_r = _wave_radii[i]
				oldest_idx = i
		slot = oldest_idx
	else:
		_wave_active_count += 1

	_wave_radii[slot] = maxf(2.0, p_radius)
	_wave_speeds[slot] = maxf(40.0, p_speed)
	_wave_widths[slot] = clampf(p_width, 1.2, 5.0)
	_wave_strengths[slot] = clampf(p_strength, 0.12, 0.62)
	_wave_color_indices[slot] = posmod(p_color_index, WAVE_RING_PALETTE.size())


func _draw_waves_backdrop() -> void:
	var bounds: Vector2 = _resolve_draw_bounds()
	var w: float = bounds.x
	var h: float = bounds.y

	# Dark base vertical gradient matching the classic palette without glare
	var quad_pts: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(w, 0.0),
		Vector2(w, h),
		Vector2(0.0, h),
	])
	var quad_cols: PackedColorArray = PackedColorArray([
		WAVE_BASE_TOP_COLOR,
		WAVE_BASE_TOP_COLOR,
		WAVE_BASE_BOTTOM_COLOR,
		WAVE_BASE_BOTTOM_COLOR,
	])
	draw_polygon(quad_pts, quad_cols)

	var center: Vector2 = bounds * 0.5
	var max_r: float = _compute_wave_max_radius(bounds)
	var palette_len: int = WAVE_RING_PALETTE.size()
	var beat_glow_lift: float = 1.0 + (_beat_pulse * 0.18 * _bg_config.get_reactivity_multiplier())

	# 4-layer translucent soft halo per ring using unfilled draw_arc (no WorldEnvironment)
	for i: int in range(_wave_active_count):
		var radius: float = _wave_radii[i]
		if radius <= 2.0 or radius >= max_r:
			continue

		var base_alpha: float = _compute_wave_ring_alpha(radius, _wave_strengths[i], max_r)
		if base_alpha <= 0.004:
			continue

		var col: Color = WAVE_RING_PALETTE[_wave_color_indices[i] % palette_len]
		var width_px: float = _wave_widths[i] * beat_glow_lift

		var outer_halo_col: Color = Color(col.r, col.g, col.b, base_alpha * 0.12)
		var mid_halo_col: Color = Color(col.r, col.g, col.b, base_alpha * 0.24)
		var inner_halo_col: Color = Color(col.r, col.g, col.b, base_alpha * 0.44)
		var core_col: Color = Color(
			lerpf(col.r, 1.0, 0.32),
			lerpf(col.g, 1.0, 0.32),
			lerpf(col.b, 1.0, 0.32),
			minf(0.66, base_alpha * 0.92)
		)

		draw_arc(center, radius, 0.0, TAU, WAVE_ARC_POINTS, outer_halo_col, width_px * 6.5, true)
		draw_arc(center, radius, 0.0, TAU, WAVE_ARC_POINTS, mid_halo_col, width_px * 3.8, true)
		draw_arc(center, radius, 0.0, TAU, WAVE_ARC_POINTS, inner_halo_col, width_px * 2.0, true)
		draw_arc(center, radius, 0.0, TAU, WAVE_ARC_POINTS, core_col, width_px, true)


func _compute_wave_ring_alpha(p_radius: float, p_strength: float, p_max_radius: float) -> float:
	if p_max_radius <= 1.0:
		return 0.0
	var norm_r: float = clampf(p_radius / p_max_radius, 0.0, 1.0)
	var fade_in: float = smoothstep(0.0, WAVE_FADE_IN_END, norm_r)
	var edge_fade: float = pow(1.0 - smoothstep(WAVE_EDGE_FADE_START, 1.0, norm_r), 1.35)
	return clampf(p_strength * fade_in * edge_fade, 0.0, 0.62)


func _compute_wave_max_radius(p_bounds: Vector2) -> float:
	var half_w: float = maxf(1.0, p_bounds.x * 0.5)
	var half_h: float = maxf(1.0, p_bounds.y * 0.5)
	return sqrt((half_w * half_w) + (half_h * half_h)) * 1.04


func _resolve_draw_bounds() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	var vp_rect: Rect2 = get_viewport_rect()
	if vp_rect.size.x > 1.0 and vp_rect.size.y > 1.0:
		return vp_rect.size
	return Vector2(1080.0, 1920.0)
