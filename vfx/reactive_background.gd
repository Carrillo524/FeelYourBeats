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

const TUNNEL_FRAME_COUNT: int = 12
const TUNNEL_MIN_SCALE: float = 0.04
const TUNNEL_MAX_SCALE: float = 1.15
const TUNNEL_BASE_DEPTH_SPEED: float = 0.28
const TUNNEL_BEAT_DECAY_RATE: float = 4.8
const TUNNEL_DROP_DECAY_RATE: float = 2.2
const TUNNEL_CHAMFER_RATIO: float = 0.20
const WAVE_BASE_TOP_COLOR: Color = Color(0.032, 0.042, 0.105, 1.0)
const WAVE_BASE_BOTTOM_COLOR: Color = Color(0.068, 0.028, 0.138, 1.0)
const TUNNEL_FRAME_COLORS: Array[Color] = [
	Color(0.22, 0.90, 1.0, 1.0),
	Color(0.66, 0.34, 1.0, 1.0),
	Color(0.32, 0.68, 1.0, 1.0),
]

const AURORA_CURTAIN_COUNT: int = 4
const AURORA_RIBBON_SEGMENTS: int = 16
const AURORA_BEAT_DECAY_RATE: float = 4.2
const AURORA_BASE_TOP_COLOR: Color = Color(0.024, 0.036, 0.092, 1.0)
const AURORA_BASE_BOTTOM_COLOR: Color = Color(0.052, 0.024, 0.112, 1.0)
const AURORA_COLOR_CYAN: Color = Color(0.18, 0.90, 0.96, 1.0)
const AURORA_COLOR_VIOLET: Color = Color(0.64, 0.30, 0.98, 1.0)
const AURORA_COLOR_BLUE: Color = Color(0.24, 0.56, 1.0, 1.0)

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

# Perspective neon tunnel & aurora procedural state (0 heap allocations per frame)
var _tunnel_depths: PackedFloat32Array = PackedFloat32Array()
var _tunnel_beat_boost: float = 0.0
var _tunnel_drop_boost: float = 0.0
var _tunnel_frame_pts: PackedVector2Array = PackedVector2Array()
var _tunnel_pulse_count: int = 0

var _aurora_time: float = 0.0
var _aurora_color_phase: float = 0.0
var _aurora_beat_boost: float = 0.0
var _aurora_drop_boost: float = 0.0
var _aurora_pulse_count: int = 0
var _quad_pts_buf: PackedVector2Array = PackedVector2Array()
var _quad_cols_buf: PackedColorArray = PackedColorArray()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0.05, 0.05, 0.12, 1.0)
	_quad_pts_buf.resize(4)
	_quad_cols_buf.resize(4)
	_tunnel_frame_pts.resize(9)
	_init_tunnel_depths()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_shader_material()
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
		step_tunnel(dt)
	elif is_aurora_style_active():
		step_aurora(dt)
	else:
		_sync_shader_parameters()


func _draw() -> void:
	if is_waves_style_active():
		_draw_tunnel_backdrop()
	elif is_aurora_style_active():
		_draw_aurora_backdrop()


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


func is_aurora_style_active() -> bool:
	return _bg_config.style == ReactiveBackgroundConfig.STYLE_AURORA


func get_tunnel_frame_count() -> int:
	return TUNNEL_FRAME_COUNT if is_waves_style_active() else 0


func get_tunnel_speed_multiplier() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var tier_drop: float = 0.55 if _current_tier >= 2 else 0.0
	var drive: float = clampf(
		((_tunnel_beat_boost * 0.72) + maxf(_tunnel_drop_boost * 0.65, tier_drop) + (_smoothed_bass * 0.35)) * react_mult,
		0.0,
		1.85
	)
	return 1.0 + (drive * 1.45)


func get_tunnel_brightness_multiplier() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var tier_drop: float = 0.45 if _current_tier >= 2 else 0.0
	var drive: float = clampf(
		((_tunnel_beat_boost * 0.72) + maxf(_tunnel_drop_boost * 0.65, tier_drop) + (_smoothed_bass * 0.30)) * react_mult,
		0.0,
		1.75
	)
	return 1.0 + (drive * 0.65)


func get_tunnel_scales_snapshot() -> PackedFloat32Array:
	var result: PackedFloat32Array = PackedFloat32Array()
	if not is_waves_style_active():
		return result
	result.resize(_tunnel_depths.size())
	for i: int in range(_tunnel_depths.size()):
		result[i] = _depth_to_tunnel_scale(_tunnel_depths[i])
	return result


func get_tunnel_pulse_count() -> int:
	return _tunnel_pulse_count


func get_aurora_curtain_count() -> int:
	return AURORA_CURTAIN_COUNT if is_aurora_style_active() else 0


func get_aurora_brightness_multiplier() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var drive: float = clampf(((_aurora_beat_boost * 0.75) + (_aurora_drop_boost * 0.50) + (_smoothed_bass * 0.25)) * react_mult, 0.0, 1.55)
	return 1.0 + (drive * 0.58)


func get_aurora_undulation_multiplier() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var drive: float = clampf(((_aurora_beat_boost * 0.75) + (_aurora_drop_boost * 0.50) + (_smoothed_mid * 0.25)) * react_mult, 0.0, 1.55)
	return 1.0 + (drive * 0.48)


func get_aurora_primary_color() -> Color:
	return _sample_aurora_color(_aurora_color_phase)


func get_aurora_pulse_count() -> int:
	return _aurora_pulse_count


func trigger_wave_pulse(p_strength: float = 0.85, p_is_drop: bool = false, _p_bypass_cooldown: bool = false) -> void:
	var s: float = clampf(p_strength, 0.20, 1.0)
	if is_waves_style_active():
		_tunnel_beat_boost = maxf(_tunnel_beat_boost, s)
		if p_is_drop:
			_tunnel_drop_boost = maxf(_tunnel_drop_boost, s)
		_tunnel_pulse_count += 1
		queue_redraw()
	elif is_aurora_style_active():
		_aurora_beat_boost = maxf(_aurora_beat_boost, s)
		if p_is_drop:
			_aurora_drop_boost = maxf(_aurora_drop_boost, s)
		_aurora_pulse_count += 1
		queue_redraw()


func step_tunnel(p_delta: float) -> void:
	if not is_waves_style_active():
		return
	var dt: float = clampf(p_delta, 0.0, 0.1)
	_tunnel_beat_boost *= exp(-TUNNEL_BEAT_DECAY_RATE * dt)
	if _tunnel_beat_boost < 0.002:
		_tunnel_beat_boost = 0.0
	_tunnel_drop_boost *= exp(-TUNNEL_DROP_DECAY_RATE * dt)
	if _tunnel_drop_boost < 0.002:
		_tunnel_drop_boost = 0.0

	var speed_mult: float = get_tunnel_speed_multiplier()
	var advance: float = TUNNEL_BASE_DEPTH_SPEED * speed_mult * dt
	for i: int in range(_tunnel_depths.size()):
		_tunnel_depths[i] = fposmod(_tunnel_depths[i] + advance, 1.0)
	queue_redraw()


func step_aurora(p_delta: float) -> void:
	if not is_aurora_style_active():
		return
	var dt: float = clampf(p_delta, 0.0, 0.1)
	_aurora_beat_boost *= exp(-AURORA_BEAT_DECAY_RATE * dt)
	if _aurora_beat_boost < 0.002:
		_aurora_beat_boost = 0.0
	_aurora_drop_boost *= exp(-3.0 * dt)
	if _aurora_drop_boost < 0.002:
		_aurora_drop_boost = 0.0

	var undul_mult: float = get_aurora_undulation_multiplier()
	_aurora_time += dt * (0.65 + (0.35 * undul_mult))
	_aurora_color_phase = wrapf(_aurora_color_phase + (dt * 0.28 * (1.0 + (_aurora_drop_boost * 0.5))), 0.0, TAU)
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


func _init_tunnel_depths() -> void:
	_tunnel_depths.resize(TUNNEL_FRAME_COUNT)
	for i: int in range(TUNNEL_FRAME_COUNT):
		_tunnel_depths[i] = float(i) / float(TUNNEL_FRAME_COUNT)


func _depth_to_tunnel_scale(p_depth: float) -> float:
	var t: float = clampf(p_depth, 0.0, 1.0)
	return lerpf(TUNNEL_MIN_SCALE, TUNNEL_MAX_SCALE, pow(t, 2.35))


func _apply_active_style_mode() -> void:
	if is_waves_style_active():
		material = null
		color = WAVE_BASE_TOP_COLOR
		if _tunnel_depths.size() != TUNNEL_FRAME_COUNT:
			_init_tunnel_depths()
		queue_redraw()
	elif is_aurora_style_active():
		material = null
		color = AURORA_BASE_TOP_COLOR
		queue_redraw()
	else:
		_setup_shader_material()
		material = _shader_material
		_tunnel_beat_boost = 0.0
		_tunnel_drop_boost = 0.0
		_aurora_beat_boost = 0.0
		_aurora_drop_boost = 0.0
		_sync_shader_parameters()
		queue_redraw()


func _draw_vertical_dark_gradient(p_w: float, p_h: float, p_top: Color, p_bottom: Color) -> void:
	_quad_pts_buf[0] = Vector2(0.0, 0.0)
	_quad_pts_buf[1] = Vector2(p_w, 0.0)
	_quad_pts_buf[2] = Vector2(p_w, p_h)
	_quad_pts_buf[3] = Vector2(0.0, p_h)
	_quad_cols_buf[0] = p_top
	_quad_cols_buf[1] = p_top
	_quad_cols_buf[2] = p_bottom
	_quad_cols_buf[3] = p_bottom
	draw_polygon(_quad_pts_buf, _quad_cols_buf)


func _draw_tunnel_backdrop() -> void:
	var bounds: Vector2 = _resolve_draw_bounds()
	var w: float = bounds.x
	var h: float = bounds.y
	_draw_vertical_dark_gradient(w, h, WAVE_BASE_TOP_COLOR, WAVE_BASE_BOTTOM_COLOR)

	var center: Vector2 = bounds * 0.5
	var half_w_max: float = w * 0.52
	var half_h_max: float = h * 0.52
	var bright_mult: float = get_tunnel_brightness_multiplier()
	var palette_len: int = TUNNEL_FRAME_COLORS.size()

	if _tunnel_frame_pts.size() != 9:
		_tunnel_frame_pts.resize(9)

	for i: int in range(_tunnel_depths.size()):
		var depth_t: float = clampf(_tunnel_depths[i], 0.0, 1.0)
		var scale_f: float = _depth_to_tunnel_scale(depth_t)
		var hw: float = half_w_max * scale_f
		var hh: float = half_h_max * scale_f
		if hw < 2.0 or hh < 2.0:
			continue

		var fade_in: float = smoothstep(0.0, 0.16, depth_t)
		var fade_out: float = 1.0 - smoothstep(0.86, 1.0, depth_t)
		var base_alpha: float = lerpf(0.07, 0.22, depth_t) * fade_in * fade_out
		var final_alpha: float = clampf(base_alpha * bright_mult, 0.0, 0.30)
		if final_alpha <= 0.004:
			continue

		# Beveled hollow neon octagon / rounded-corner frame in perspective (no fill)
		var cx: float = center.x
		var cy: float = center.y
		var ch_x: float = hw * TUNNEL_CHAMFER_RATIO
		var ch_y: float = hh * TUNNEL_CHAMFER_RATIO

		_tunnel_frame_pts[0] = Vector2(cx - hw + ch_x, cy - hh)
		_tunnel_frame_pts[1] = Vector2(cx + hw - ch_x, cy - hh)
		_tunnel_frame_pts[2] = Vector2(cx + hw, cy - hh + ch_y)
		_tunnel_frame_pts[3] = Vector2(cx + hw, cy + hh - ch_y)
		_tunnel_frame_pts[4] = Vector2(cx + hw - ch_x, cy + hh)
		_tunnel_frame_pts[5] = Vector2(cx - hw + ch_x, cy + hh)
		_tunnel_frame_pts[6] = Vector2(cx - hw, cy + hh - ch_y)
		_tunnel_frame_pts[7] = Vector2(cx - hw, cy - hh + ch_y)
		_tunnel_frame_pts[8] = _tunnel_frame_pts[0]

		var col: Color = TUNNEL_FRAME_COLORS[i % palette_len]
		var core_w: float = lerpf(1.1, 2.5, depth_t)

		# 3-layer soft translucent halo (no WorldEnvironment)
		var outer_col: Color = Color(col.r, col.g, col.b, final_alpha * 0.24)
		var mid_col: Color = Color(col.r, col.g, col.b, final_alpha * 0.48)
		var core_col: Color = Color(
			lerpf(col.r, 1.0, 0.30),
			lerpf(col.g, 1.0, 0.30),
			lerpf(col.b, 1.0, 0.30),
			final_alpha
		)

		draw_polyline(_tunnel_frame_pts, outer_col, core_w * 5.2, true)
		draw_polyline(_tunnel_frame_pts, mid_col, core_w * 2.6, true)
		draw_polyline(_tunnel_frame_pts, core_col, core_w, true)


func _sample_aurora_color(p_phase: float) -> Color:
	var norm: float = fposmod(p_phase / TAU, 1.0)
	if norm < 0.3333:
		return AURORA_COLOR_CYAN.lerp(AURORA_COLOR_VIOLET, smoothstep(0.0, 0.3333, norm))
	elif norm < 0.6666:
		return AURORA_COLOR_VIOLET.lerp(AURORA_COLOR_BLUE, smoothstep(0.3333, 0.6666, norm))
	return AURORA_COLOR_BLUE.lerp(AURORA_COLOR_CYAN, smoothstep(0.6666, 1.0, norm))


func _draw_aurora_backdrop() -> void:
	var bounds: Vector2 = _resolve_draw_bounds()
	var w: float = bounds.x
	var h: float = bounds.y
	_draw_vertical_dark_gradient(w, h, AURORA_BASE_TOP_COLOR, AURORA_BASE_BOTTOM_COLOR)

	var bright_mult: float = get_aurora_brightness_multiplier()
	var undul_mult: float = get_aurora_undulation_multiplier()

	var x_anchors: PackedFloat32Array = PackedFloat32Array([0.16, 0.42, 0.66, 0.86])
	var slants: PackedFloat32Array = PackedFloat32Array([0.14, -0.10, 0.12, -0.13])
	var half_widths: PackedFloat32Array = PackedFloat32Array([0.24, 0.28, 0.25, 0.22])
	var y_starts: PackedFloat32Array = PackedFloat32Array([0.04, 0.08, 0.05, 0.10])
	var y_ends: PackedFloat32Array = PackedFloat32Array([0.74, 0.82, 0.78, 0.72])
	var phase_offsets: PackedFloat32Array = PackedFloat32Array([0.0, 1.55, 3.10, 4.65])

	for c_idx: int in range(AURORA_CURTAIN_COUNT):
		var col_top: Color = _sample_aurora_color(_aurora_color_phase + (float(c_idx) * 1.15))
		var col_bot: Color = _sample_aurora_color(_aurora_color_phase + (float(c_idx) * 1.15) + 1.65)
		var base_alpha: float = clampf((0.11 + (0.025 * float(c_idx % 2))) * bright_mult, 0.0, 0.24)
		var y_top_px: float = h * y_starts[c_idx]
		var y_bot_px: float = h * y_ends[c_idx]
		var span_y: float = maxf(1.0, y_bot_px - y_top_px)
		var base_hw: float = w * half_widths[c_idx]
		var sway_amp: float = w * 0.065 * undul_mult

		# Two soft passes per curtain (wide outer veil + inner luminous core) for diffuse blur
		for pass_idx: int in range(2):
			var width_scale: float = 1.48 if pass_idx == 0 else 0.72
			var pass_alpha_scale: float = 0.52 if pass_idx == 0 else 0.92
			for s_idx: int in range(AURORA_RIBBON_SEGMENTS):
				var t0: float = float(s_idx) / float(AURORA_RIBBON_SEGMENTS)
				var t1: float = float(s_idx + 1) / float(AURORA_RIBBON_SEGMENTS)

				var y0: float = y_top_px + (t0 * span_y)
				var y1: float = y_top_px + (t1 * span_y)

				var sway0: float = sin((_aurora_time * 0.75) + (t0 * 3.4) + phase_offsets[c_idx]) * sway_amp
				var sway1: float = sin((_aurora_time * 0.75) + (t1 * 3.4) + phase_offsets[c_idx]) * sway_amp

				var cx0: float = (w * (x_anchors[c_idx] + (slants[c_idx] * (t0 - 0.5)))) + sway0
				var cx1: float = (w * (x_anchors[c_idx] + (slants[c_idx] * (t1 - 0.5)))) + sway1

				var hw0: float = base_hw * width_scale * (0.78 + (0.28 * sin(t0 * PI)))
				var hw1: float = base_hw * width_scale * (0.78 + (0.28 * sin(t1 * PI)))

				var env0: float = pow(sin(clampf(t0, 0.0, 1.0) * PI), 1.35)
				var env1: float = pow(sin(clampf(t1, 0.0, 1.0) * PI), 1.35)

				var c0_rgb: Color = col_top.lerp(col_bot, t0)
				var c1_rgb: Color = col_top.lerp(col_bot, t1)
				var c0: Color = Color(c0_rgb.r, c0_rgb.g, c0_rgb.b, base_alpha * pass_alpha_scale * env0)
				var c1: Color = Color(c1_rgb.r, c1_rgb.g, c1_rgb.b, base_alpha * pass_alpha_scale * env1)

				_quad_pts_buf[0] = Vector2(cx0 - hw0, y0)
				_quad_pts_buf[1] = Vector2(cx0 + hw0, y0)
				_quad_pts_buf[2] = Vector2(cx1 + hw1, y1)
				_quad_pts_buf[3] = Vector2(cx1 - hw1, y1)
				_quad_cols_buf[0] = c0
				_quad_cols_buf[1] = c0
				_quad_cols_buf[2] = c1
				_quad_cols_buf[3] = c1
				draw_polygon(_quad_pts_buf, _quad_cols_buf)


func _resolve_draw_bounds() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	var vp_rect: Rect2 = get_viewport_rect()
	if vp_rect.size.x > 1.0 and vp_rect.size.y > 1.0:
		return vp_rect.size
	return Vector2(1080.0, 1920.0)
