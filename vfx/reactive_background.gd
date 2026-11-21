class_name ReactiveBackground
extends ColorRect

enum BackdropMode {
	MENU = 0,
	GAMEPLAY = 1,
}

signal screen_shake_updated(p_offset: Vector2)
signal bass_kick_pulsed(p_strength: float)

const SHADER_PATH: String = "res://vfx/reactive_backdrop.gdshader"
const HIT_EFFECT_CLASSIC: String = "classic"
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

const NEBULA_CLOUD_COUNT: int = 6
const NEBULA_BEAT_DECAY_RATE: float = 3.8
const NEBULA_DROP_DECAY_RATE: float = 2.0
const NEBULA_MAX_ALPHA: float = 0.26
const NEBULA_MAX_RGB_CHANNEL: float = 0.91
const NEBULA_BASE_TOP_COLOR: Color = Color(0.026, 0.022, 0.088, 1.0)
const NEBULA_BASE_BOTTOM_COLOR: Color = Color(0.068, 0.022, 0.128, 1.0)
const NEBULA_COLOR_VIOLET: Color = Color(0.42, 0.18, 0.86, 1.0)
const NEBULA_COLOR_INDIGO: Color = Color(0.22, 0.24, 0.84, 1.0)
const NEBULA_COLOR_CYAN: Color = Color(0.10, 0.78, 0.91, 1.0)
const NEBULA_CLOUD_ANCHORS_X: PackedFloat32Array = [0.22, 0.78, 0.48, 0.26, 0.74, 0.50]
const NEBULA_CLOUD_ANCHORS_Y: PackedFloat32Array = [0.22, 0.28, 0.46, 0.62, 0.66, 0.36]
const NEBULA_CLOUD_RADII_X: PackedFloat32Array = [0.60, 0.64, 0.72, 0.58, 0.60, 0.54]
const NEBULA_CLOUD_RADII_Y: PackedFloat32Array = [0.34, 0.38, 0.42, 0.32, 0.34, 0.30]
const NEBULA_CLOUD_PHASES: PackedFloat32Array = [0.0, 1.15, 2.30, 3.45, 4.60, 5.45]

const ECLIPSE_BEAT_DECAY_RATE: float = 4.2
const ECLIPSE_DROP_DECAY_RATE: float = 2.2
const ECLIPSE_MAX_ALPHA: float = 0.34
const ECLIPSE_MAX_RGB_CHANNEL: float = 0.91
const ECLIPSE_BASE_TOP_COLOR: Color = Color(0.020, 0.026, 0.072, 1.0)
const ECLIPSE_BASE_BOTTOM_COLOR: Color = Color(0.044, 0.022, 0.098, 1.0)
const ECLIPSE_COLOR_CYAN: Color = Color(0.10, 0.82, 0.91, 1.0)
const ECLIPSE_COLOR_VIOLET: Color = Color(0.54, 0.24, 0.91, 1.0)

const AURORA_CURTAIN_COUNT: int = 7
const AURORA_RIBBON_SEGMENTS: int = 16
const AURORA_BEAT_DECAY_RATE: float = 4.2
const AURORA_MAX_ALPHA: float = 0.26
const AURORA_MAX_RGB_CHANNEL: float = 0.91
const AURORA_BASE_TOP_COLOR: Color = Color(0.022, 0.034, 0.088, 1.0)
const AURORA_BASE_BOTTOM_COLOR: Color = Color(0.048, 0.022, 0.105, 1.0)
const AURORA_COLOR_TURQUOISE: Color = Color(0.06, 0.84, 0.78, 1.0)
const AURORA_COLOR_CYAN: Color = Color(0.08, 0.76, 0.91, 1.0)
const AURORA_COLOR_VIOLET: Color = Color(0.48, 0.24, 0.90, 1.0)

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

# Diffused nebula, aurora & eclipse procedural state (0 heap allocations per frame)
var _nebula_time: float = 0.0
var _nebula_beat_boost: float = 0.0
var _nebula_drop_boost: float = 0.0
var _nebula_pulse_count: int = 0
var _nebula_cloud_texture: GradientTexture2D = null

var _eclipse_time: float = 0.0
var _eclipse_color_phase: float = 0.0
var _eclipse_beat_boost: float = 0.0
var _eclipse_drop_boost: float = 0.0
var _eclipse_pulse_count: int = 0
var _eclipse_halo_texture: GradientTexture2D = null
var _eclipse_core_shadow_texture: GradientTexture2D = null

var _aurora_time: float = 0.0
var _aurora_color_phase: float = 0.0
var _aurora_beat_boost: float = 0.0
var _aurora_drop_boost: float = 0.0
var _aurora_pulse_count: int = 0
var _aurora_vertical_texture: GradientTexture2D = null
var _aurora_horizontal_texture: GradientTexture2D = null
var _hit_effect_style: String = HIT_EFFECT_CLASSIC
var _hit_beam_texture: GradientTexture2D = null
var _hit_radial_texture: GradientTexture2D = null
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
	color = Color(0.05, 0.05, 0.12, 1.0)
	_quad_pts_buf.resize(4)
	_quad_cols_buf.resize(4)
	_nebula_cloud_texture = _create_nebula_cloud_texture()
	_eclipse_halo_texture = _create_eclipse_halo_texture()
	_eclipse_core_shadow_texture = _create_eclipse_core_shadow_texture()
	_aurora_vertical_texture = _create_aurora_vertical_texture()
	_aurora_horizontal_texture = _create_aurora_horizontal_texture()
	_hit_beam_texture = _create_hit_beam_texture()
	_hit_radial_texture = _create_hit_radial_texture()


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
	if is_nebula_style_active():
		step_nebula(dt)
	elif is_aurora_style_active():
		step_aurora(dt)
	elif is_eclipse_style_active():
		step_eclipse(dt)
	else:
		_sync_shader_parameters()


func _draw() -> void:
	if is_nebula_style_active():
		_draw_nebula_backdrop()
	elif is_aurora_style_active():
		_draw_aurora_backdrop()
	elif is_eclipse_style_active():
		_draw_eclipse_backdrop()


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


func is_nebula_style_active() -> bool:
	return _bg_config.style == ReactiveBackgroundConfig.STYLE_NEBULA


func is_waves_style_active() -> bool:
	return is_nebula_style_active()


func is_aurora_style_active() -> bool:
	return _bg_config.style == ReactiveBackgroundConfig.STYLE_AURORA


func is_eclipse_style_active() -> bool:
	return _bg_config.style == ReactiveBackgroundConfig.STYLE_ECLIPSE


func get_nebula_cloud_count() -> int:
	return NEBULA_CLOUD_COUNT if is_nebula_style_active() else 0


func get_nebula_cloud_texture() -> GradientTexture2D:
	return _nebula_cloud_texture


func _compute_nebula_musical_drive() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var tier_drop: float = 0.72 if _current_tier >= 3 else (0.46 if _current_tier >= 2 else 0.0)
	return clampf(
		((_nebula_beat_boost * 0.85) + maxf(_nebula_drop_boost * 0.80, tier_drop) + (_smoothed_bass * 0.62) + (_smoothed_mid * 0.18)) * react_mult,
		0.0,
		2.10
	)


func get_nebula_brightness_multiplier() -> float:
	var drive: float = _compute_nebula_musical_drive()
	return 1.0 + (drive * 0.95)


func get_nebula_breath_scale() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var bass_breath: float = clampf(((_smoothed_bass * 0.16) + (_nebula_beat_boost * 0.10)) * react_mult, 0.0, 0.30)
	return 1.0 + bass_breath


func get_nebula_core_boost() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var tier_drop: float = 0.82 if _current_tier >= 3 else (0.55 if _current_tier >= 2 else 0.0)
	return clampf(
		(maxf(_nebula_drop_boost, tier_drop) + (_nebula_beat_boost * 0.45) + (_smoothed_bass * 0.32)) * react_mult,
		0.0,
		1.60
	)


func get_nebula_pulse_count() -> int:
	return _nebula_pulse_count


func get_eclipse_halo_texture() -> GradientTexture2D:
	return _eclipse_halo_texture


func get_eclipse_core_shadow_texture() -> GradientTexture2D:
	return _eclipse_core_shadow_texture


func _compute_eclipse_musical_drive() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var tier_drop: float = 0.75 if _current_tier >= 3 else (0.48 if _current_tier >= 2 else 0.0)
	return clampf(
		((_eclipse_beat_boost * 0.90) + maxf(_eclipse_drop_boost * 0.82, tier_drop) + (_smoothed_bass * 0.56)) * react_mult,
		0.0,
		2.15
	)


func get_eclipse_breath_scale() -> float:
	var drive: float = _compute_eclipse_musical_drive()
	var ambient_swell: float = sin(_eclipse_time * 0.90) * 0.03
	return clampf(1.0 + ambient_swell + (drive * 0.14), 0.94, 1.36)


func get_eclipse_color_mix() -> float:
	var slow_wave: float = (sin(_eclipse_color_phase) * 0.5) + 0.5
	var beat_push: float = clampf((_eclipse_beat_boost * 0.38) + (_eclipse_drop_boost * 0.48), 0.0, 0.65)
	return clampf(lerpf(slow_wave, 1.0 - slow_wave, beat_push), 0.0, 1.0)


func get_eclipse_current_color() -> Color:
	var col: Color = ECLIPSE_COLOR_CYAN.lerp(ECLIPSE_COLOR_VIOLET, get_eclipse_color_mix())
	return Color(
		minf(col.r, ECLIPSE_MAX_RGB_CHANNEL),
		minf(col.g, ECLIPSE_MAX_RGB_CHANNEL),
		minf(col.b, ECLIPSE_MAX_RGB_CHANNEL),
		1.0
	)


func get_eclipse_pulse_count() -> int:
	return _eclipse_pulse_count


func get_global_hit_flash_energy() -> float:
	return maxf(maxf(_lane_flashes.x, _lane_flashes.y), maxf(_lane_flashes.z, _lane_flashes.w))


func is_custom_hit_flash_rendering() -> bool:
	return (
		(is_nebula_style_active() or is_aurora_style_active() or is_eclipse_style_active())
		and get_global_hit_flash_energy() > 0.004
	)


func get_hit_effect_style() -> String:
	return _hit_effect_style


func get_hit_beam_texture() -> GradientTexture2D:
	return _hit_beam_texture


func get_hit_radial_texture() -> GradientTexture2D:
	return _hit_radial_texture


func get_aurora_curtain_count() -> int:
	return AURORA_CURTAIN_COUNT if is_aurora_style_active() else 0


func get_aurora_brightness_multiplier() -> float:
	var drive: float = _compute_aurora_musical_drive()
	return 1.0 + (drive * 1.10)


func get_aurora_blur_scale() -> float:
	var drive: float = _compute_aurora_musical_drive()
	return 1.0 + (drive * 0.58)


func get_aurora_vertical_stretch() -> float:
	var drive: float = _compute_aurora_musical_drive()
	return clampf(1.0 + (drive * 0.20), 1.0, 1.38)


func get_aurora_peak_alpha() -> float:
	var bright_mult: float = get_aurora_brightness_multiplier()
	return clampf(0.125 * bright_mult, 0.0, AURORA_MAX_ALPHA)


func get_aurora_vertical_texture() -> GradientTexture2D:
	return _aurora_vertical_texture


func get_aurora_horizontal_texture() -> GradientTexture2D:
	return _aurora_horizontal_texture


func get_aurora_undulation_multiplier() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var tier_drop: float = 0.65 if _current_tier >= 3 else (0.42 if _current_tier >= 2 else 0.0)
	var drive: float = clampf(
		((_aurora_beat_boost * 0.90) + maxf(_aurora_drop_boost * 0.72, tier_drop) + (_smoothed_mid * 0.42) + (_smoothed_bass * 0.28)) * react_mult,
		0.0,
		2.00
	)
	return 1.0 + (drive * 1.44)


func _compute_aurora_musical_drive() -> float:
	var react_mult: float = _bg_config.get_reactivity_multiplier()
	var tier_drop: float = 0.72 if _current_tier >= 3 else (0.48 if _current_tier >= 2 else 0.0)
	return clampf(
		((_aurora_beat_boost * 0.95) + maxf(_aurora_drop_boost * 0.80, tier_drop) + (_smoothed_bass * 0.52) + (_smoothed_high * 0.18)) * react_mult,
		0.0,
		2.15
	)


func get_aurora_primary_color() -> Color:
	return _sample_aurora_color(_aurora_color_phase)


func get_aurora_pulse_count() -> int:
	return _aurora_pulse_count


func trigger_wave_pulse(p_strength: float = 0.85, p_is_drop: bool = false, _p_bypass_cooldown: bool = false) -> void:
	var s: float = clampf(p_strength, 0.20, 1.0)
	if is_nebula_style_active():
		_nebula_beat_boost = maxf(_nebula_beat_boost, s)
		if p_is_drop:
			_nebula_drop_boost = maxf(_nebula_drop_boost, s)
		_nebula_pulse_count += 1
		queue_redraw()
	elif is_aurora_style_active():
		_aurora_beat_boost = maxf(_aurora_beat_boost, s)
		if p_is_drop:
			_aurora_drop_boost = maxf(_aurora_drop_boost, s)
		_aurora_pulse_count += 1
		queue_redraw()
	elif is_eclipse_style_active():
		_eclipse_beat_boost = maxf(_eclipse_beat_boost, s)
		if p_is_drop:
			_eclipse_drop_boost = maxf(_eclipse_drop_boost, s)
		_eclipse_color_phase = wrapf(_eclipse_color_phase + (0.62 if p_is_drop else 0.34), 0.0, TAU)
		_eclipse_pulse_count += 1
		queue_redraw()


func step_nebula(p_delta: float) -> void:
	if not is_nebula_style_active():
		return
	var dt: float = clampf(p_delta, 0.0, 0.1)
	_nebula_beat_boost *= exp(-NEBULA_BEAT_DECAY_RATE * dt)
	if _nebula_beat_boost < 0.002:
		_nebula_beat_boost = 0.0
	_nebula_drop_boost *= exp(-NEBULA_DROP_DECAY_RATE * dt)
	if _nebula_drop_boost < 0.002:
		_nebula_drop_boost = 0.0

	var drift_speed: float = 0.48 + (_compute_nebula_musical_drive() * 0.22)
	_nebula_time += dt * drift_speed
	queue_redraw()


func step_eclipse(p_delta: float) -> void:
	if not is_eclipse_style_active():
		return
	var dt: float = clampf(p_delta, 0.0, 0.1)
	_eclipse_beat_boost *= exp(-ECLIPSE_BEAT_DECAY_RATE * dt)
	if _eclipse_beat_boost < 0.002:
		_eclipse_beat_boost = 0.0
	_eclipse_drop_boost *= exp(-ECLIPSE_DROP_DECAY_RATE * dt)
	if _eclipse_drop_boost < 0.002:
		_eclipse_drop_boost = 0.0

	_eclipse_time += dt * (0.72 + (_eclipse_drop_boost * 0.35))
	_eclipse_color_phase = wrapf(
		_eclipse_color_phase + (dt * (0.36 + (_eclipse_drop_boost * 0.55) + (_eclipse_beat_boost * 0.30))),
		0.0,
		TAU
	)
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
	elif is_aurora_style_active() and _current_tier >= 2:
		_aurora_drop_boost = maxf(_aurora_drop_boost, 0.82 if _current_tier >= 3 else 0.62)
		queue_redraw()
	elif is_nebula_style_active() and _current_tier >= 2:
		_nebula_drop_boost = maxf(_nebula_drop_boost, 0.84 if _current_tier >= 3 else 0.62)
		queue_redraw()
	elif is_eclipse_style_active() and _current_tier >= 2:
		_eclipse_drop_boost = maxf(_eclipse_drop_boost, 0.85 if _current_tier >= 3 else 0.64)
		queue_redraw()
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
	elif is_aurora_style_active() and (bass_jump >= 0.075 or clamped_bass >= 0.36):
		var aurora_swell: float = clampf((clamped_bass * 0.78) + (maxf(0.0, bass_jump) * 1.15), 0.22, 0.92)
		_aurora_beat_boost = maxf(_aurora_beat_boost, aurora_swell)
		if clamped_bass >= 0.64 and clamped_total >= 0.62:
			_aurora_drop_boost = maxf(_aurora_drop_boost, clampf(clamped_total, 0.55, 1.0))
		queue_redraw()
	elif is_nebula_style_active() and (bass_jump >= 0.08 or clamped_bass >= 0.38):
		var nebula_swell: float = clampf((clamped_bass * 0.75) + (maxf(0.0, bass_jump) * 1.05), 0.20, 0.90)
		_nebula_beat_boost = maxf(_nebula_beat_boost, nebula_swell)
		if clamped_bass >= 0.66 and clamped_total >= 0.62:
			_nebula_drop_boost = maxf(_nebula_drop_boost, clampf(clamped_total, 0.55, 1.0))
		queue_redraw()
	elif is_eclipse_style_active() and (bass_jump >= 0.08 or clamped_bass >= 0.38):
		var eclipse_swell: float = clampf((clamped_bass * 0.76) + (maxf(0.0, bass_jump) * 1.08), 0.20, 0.92)
		_eclipse_beat_boost = maxf(_eclipse_beat_boost, eclipse_swell)
		if clamped_bass >= 0.65 and clamped_total >= 0.62:
			_eclipse_drop_boost = maxf(_eclipse_drop_boost, clampf(clamped_total, 0.55, 1.0))
		queue_redraw()

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

	if is_nebula_style_active() or is_aurora_style_active() or is_eclipse_style_active():
		queue_redraw()
	else:
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


func _apply_active_style_mode() -> void:
	if is_nebula_style_active():
		material = null
		color = NEBULA_BASE_TOP_COLOR
		queue_redraw()
	elif is_aurora_style_active():
		material = null
		color = AURORA_BASE_TOP_COLOR
		queue_redraw()
	elif is_eclipse_style_active():
		material = null
		color = ECLIPSE_BASE_TOP_COLOR
		queue_redraw()
	else:
		_setup_shader_material()
		material = _shader_material
		_nebula_beat_boost = 0.0
		_nebula_drop_boost = 0.0
		_aurora_beat_boost = 0.0
		_aurora_drop_boost = 0.0
		_eclipse_beat_boost = 0.0
		_eclipse_drop_boost = 0.0
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


func _draw_nebula_backdrop() -> void:
	var bounds: Vector2 = _resolve_draw_bounds()
	var w: float = bounds.x
	var h: float = bounds.y
	_draw_vertical_dark_gradient(w, h, NEBULA_BASE_TOP_COLOR, NEBULA_BASE_BOTTOM_COLOR)

	if _nebula_cloud_texture == null:
		_draw_global_note_hit_flashes(bounds)
		return

	var bright_mult: float = get_nebula_brightness_multiplier()
	var breath_scale: float = get_nebula_breath_scale()
	var core_boost: float = get_nebula_core_boost()

	# 6 wide overlapping elliptical radial clouds (deep violet, indigo, subtle cyan accents, zero lines)
	for i: int in range(NEBULA_CLOUD_COUNT):
		var phase: float = NEBULA_CLOUD_PHASES[i]
		var drift_x: float = sin((_nebula_time * 0.42) + phase) * (w * 0.065)
		var drift_y: float = cos((_nebula_time * 0.34) + (phase * 1.18)) * (h * 0.042)
		var cx: float = (w * NEBULA_CLOUD_ANCHORS_X[i]) + drift_x
		var cy: float = (h * NEBULA_CLOUD_ANCHORS_Y[i]) + drift_y

		var local_swell: float = 1.0 + (0.06 * sin((_nebula_time * 0.65) + phase))
		var rx: float = w * NEBULA_CLOUD_RADII_X[i] * breath_scale * local_swell
		var ry: float = h * NEBULA_CLOUD_RADII_Y[i] * breath_scale * local_swell

		var base_col: Color = NEBULA_COLOR_VIOLET
		var mod_idx: int = i % 3
		if mod_idx == 1:
			base_col = NEBULA_COLOR_INDIGO
		elif mod_idx == 2:
			base_col = NEBULA_COLOR_INDIGO.lerp(NEBULA_COLOR_CYAN, clampf(0.42 + (core_boost * 0.25), 0.0, 0.85))

		var cloud_alpha: float = clampf((0.115 + (0.02 * float(i % 2))) * bright_mult, 0.0, NEBULA_MAX_ALPHA)
		var cloud_tint: Color = Color(
			minf(base_col.r, NEBULA_MAX_RGB_CHANNEL),
			minf(base_col.g, NEBULA_MAX_RGB_CHANNEL),
			minf(base_col.b, NEBULA_MAX_RGB_CHANNEL),
			cloud_alpha
		)
		var cloud_rect: Rect2 = Rect2(cx - rx, cy - ry, rx * 2.0, ry * 2.0)
		draw_texture_rect(_nebula_cloud_texture, cloud_rect, false, cloud_tint)

	# Centered cosmic core glow that blooms smoothly during Drops
	var core_center: Vector2 = Vector2(
		(w * 0.5) + (sin(_nebula_time * 0.30) * w * 0.025),
		(h * 0.46) + (cos(_nebula_time * 0.26) * h * 0.02)
	)
	var core_rx: float = w * lerpf(0.38, 0.64, clampf(core_boost * 0.65, 0.0, 1.0)) * breath_scale
	var core_ry: float = h * lerpf(0.22, 0.36, clampf(core_boost * 0.65, 0.0, 1.0)) * breath_scale
	var core_col: Color = NEBULA_COLOR_VIOLET.lerp(NEBULA_COLOR_CYAN, clampf(0.35 + (core_boost * 0.42), 0.0, 0.88))
	var core_alpha: float = clampf(0.08 + (core_boost * 0.14), 0.0, NEBULA_MAX_ALPHA)
	var core_tint: Color = Color(
		minf(core_col.r, NEBULA_MAX_RGB_CHANNEL),
		minf(core_col.g, NEBULA_MAX_RGB_CHANNEL),
		minf(core_col.b, NEBULA_MAX_RGB_CHANNEL),
		core_alpha
	)
	var core_rect: Rect2 = Rect2(
		core_center.x - core_rx,
		core_center.y - core_ry,
		core_rx * 2.0,
		core_ry * 2.0
	)
	draw_texture_rect(_nebula_cloud_texture, core_rect, false, core_tint)

	_draw_global_note_hit_flashes(bounds)


func _draw_eclipse_backdrop() -> void:
	var bounds: Vector2 = _resolve_draw_bounds()
	var w: float = bounds.x
	var h: float = bounds.y
	_draw_vertical_dark_gradient(w, h, ECLIPSE_BASE_TOP_COLOR, ECLIPSE_BASE_BOTTOM_COLOR)

	if _eclipse_halo_texture == null:
		_draw_global_note_hit_flashes(bounds)
		return

	var drive: float = _compute_eclipse_musical_drive()
	var breath_scale: float = get_eclipse_breath_scale()
	var primary_col: Color = get_eclipse_current_color()
	var secondary_col: Color = ECLIPSE_COLOR_VIOLET.lerp(ECLIPSE_COLOR_CYAN, get_eclipse_color_mix())
	var center: Vector2 = Vector2(w * 0.5, h * 0.47)
	var min_dim: float = minf(w, h)

	# 1. Wide outer atmospheric nebula veil behind the eclipse
	if _nebula_cloud_texture != null:
		var outer_r: float = min_dim * 0.72 * breath_scale
		var outer_alpha: float = clampf(0.11 + (drive * 0.09), 0.0, 0.24)
		var outer_tint: Color = Color(
			minf(secondary_col.r, ECLIPSE_MAX_RGB_CHANNEL),
			minf(secondary_col.g, ECLIPSE_MAX_RGB_CHANNEL),
			minf(secondary_col.b, ECLIPSE_MAX_RGB_CHANNEL),
			outer_alpha
		)
		var outer_rect: Rect2 = Rect2(center.x - outer_r, center.y - outer_r, outer_r * 2.0, outer_r * 2.0)
		draw_texture_rect(_nebula_cloud_texture, outer_rect, false, outer_tint)

	# 2. Secondary counter-hue diffused halo slightly shifted for chromatic depth
	var shift_vec: Vector2 = Vector2(
		cos(_eclipse_time * 0.55) * (min_dim * 0.018),
		sin(_eclipse_time * 0.48) * (min_dim * 0.018)
	)
	var sec_r: float = min_dim * 0.56 * breath_scale
	var sec_alpha: float = clampf(0.10 + (drive * 0.085), 0.0, 0.24)
	var sec_tint: Color = Color(
		minf(secondary_col.r, ECLIPSE_MAX_RGB_CHANNEL),
		minf(secondary_col.g, ECLIPSE_MAX_RGB_CHANNEL),
		minf(secondary_col.b, ECLIPSE_MAX_RGB_CHANNEL),
		sec_alpha
	)
	var sec_rect: Rect2 = Rect2(
		center.x + shift_vec.x - sec_r,
		center.y + shift_vec.y - sec_r,
		sec_r * 2.0,
		sec_r * 2.0
	)
	draw_texture_rect(_eclipse_halo_texture, sec_rect, false, sec_tint)

	# 3. Main centered wide diffused circular halo (smooth radial falloff, zero hard ring)
	var main_r: float = min_dim * 0.50 * breath_scale
	var main_alpha: float = clampf(0.17 + (drive * 0.11), 0.0, ECLIPSE_MAX_ALPHA)
	var main_tint: Color = Color(
		minf(primary_col.r, ECLIPSE_MAX_RGB_CHANNEL),
		minf(primary_col.g, ECLIPSE_MAX_RGB_CHANNEL),
		minf(primary_col.b, ECLIPSE_MAX_RGB_CHANNEL),
		main_alpha
	)
	var main_rect: Rect2 = Rect2(center.x - main_r, center.y - main_r, main_r * 2.0, main_r * 2.0)
	draw_texture_rect(_eclipse_halo_texture, main_rect, false, main_tint)

	# 4. Soft dark center umbra giving depth without any hard circle contour
	if _eclipse_core_shadow_texture != null:
		var umbra_r: float = min_dim * 0.24 * lerpf(1.0, 1.06, clampf(drive * 0.35, 0.0, 1.0))
		var umbra_tint: Color = Color(0.025, 0.022, 0.070, 0.72)
		var umbra_rect: Rect2 = Rect2(center.x - umbra_r, center.y - umbra_r, umbra_r * 2.0, umbra_r * 2.0)
		draw_texture_rect(_eclipse_core_shadow_texture, umbra_rect, false, umbra_tint)

	_draw_global_note_hit_flashes(bounds)


func _create_nebula_cloud_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.26, 0.54, 0.78, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.56),
		Color(1.0, 1.0, 1.0, 0.20),
		Color(1.0, 1.0, 1.0, 0.05),
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


func _create_eclipse_halo_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.14, 0.34, 0.46, 0.64, 0.82, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.14),
		Color(1.0, 1.0, 1.0, 0.88),
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.52),
		Color(1.0, 1.0, 1.0, 0.16),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 256
	tex.height = 256
	tex.use_hdr = false
	return tex


func _create_eclipse_core_shadow_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.32, 0.62, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.82),
		Color(1.0, 1.0, 1.0, 0.44),
		Color(1.0, 1.0, 1.0, 0.0),
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


func _sample_aurora_color(p_phase: float) -> Color:
	var norm: float = fposmod(p_phase / TAU, 1.0)
	var col: Color = AURORA_COLOR_TURQUOISE
	if norm < 0.3333:
		col = AURORA_COLOR_TURQUOISE.lerp(AURORA_COLOR_CYAN, smoothstep(0.0, 0.3333, norm))
	elif norm < 0.6666:
		col = AURORA_COLOR_CYAN.lerp(AURORA_COLOR_VIOLET, smoothstep(0.3333, 0.6666, norm))
	else:
		col = AURORA_COLOR_VIOLET.lerp(AURORA_COLOR_TURQUOISE, smoothstep(0.6666, 1.0, norm))
	return Color(
		minf(col.r, AURORA_MAX_RGB_CHANNEL),
		minf(col.g, AURORA_MAX_RGB_CHANNEL),
		minf(col.b, AURORA_MAX_RGB_CHANNEL),
		1.0
	)


func _draw_aurora_backdrop() -> void:
	var bounds: Vector2 = _resolve_draw_bounds()
	var w: float = bounds.x
	var h: float = bounds.y
	_draw_vertical_dark_gradient(w, h, AURORA_BASE_TOP_COLOR, AURORA_BASE_BOTTOM_COLOR)

	if _aurora_vertical_texture == null or _aurora_horizontal_texture == null:
		_draw_global_note_hit_flashes(bounds)
		return

	var vert_grad: Gradient = _aurora_vertical_texture.gradient
	var bright_mult: float = get_aurora_brightness_multiplier()
	var blur_scale: float = get_aurora_blur_scale()
	var stretch_v: float = get_aurora_vertical_stretch()
	var undul_mult: float = get_aurora_undulation_multiplier()

	# Subtle colored upper-sky ambient glow (kept strictly colored, never white, leaving lower hit zone clean)
	var wash_col: Color = _sample_aurora_color(_aurora_color_phase)
	var wash_alpha: float = clampf(0.045 * bright_mult, 0.0, 0.09)
	_quad_pts_buf[0] = Vector2(0.0, 0.0)
	_quad_pts_buf[1] = Vector2(w, 0.0)
	_quad_pts_buf[2] = Vector2(w, h * 0.66)
	_quad_pts_buf[3] = Vector2(0.0, h * 0.66)
	_quad_cols_buf[0] = Color(wash_col.r, wash_col.g, wash_col.b, wash_alpha)
	_quad_cols_buf[1] = Color(wash_col.r, wash_col.g, wash_col.b, wash_alpha)
	_quad_cols_buf[2] = Color(wash_col.r, wash_col.g, wash_col.b, 0.0)
	_quad_cols_buf[3] = Color(wash_col.r, wash_col.g, wash_col.b, 0.0)
	draw_polygon(_quad_pts_buf, _quad_cols_buf)

	# 7 ethereal vertical curtains in mid-upper region (hit-line area below ~74% stays clean)
	var x_anchors: PackedFloat32Array = PackedFloat32Array([0.08, 0.22, 0.37, 0.51, 0.65, 0.79, 0.92])
	var half_widths: PackedFloat32Array = PackedFloat32Array([0.15, 0.18, 0.16, 0.20, 0.17, 0.18, 0.15])
	var y_starts: PackedFloat32Array = PackedFloat32Array([0.03, 0.06, 0.02, 0.05, 0.03, 0.07, 0.04])
	var y_spans: PackedFloat32Array = PackedFloat32Array([0.48, 0.54, 0.50, 0.56, 0.52, 0.49, 0.46])
	var phase_offsets: PackedFloat32Array = PackedFloat32Array([0.0, 0.95, 1.90, 2.85, 3.80, 4.75, 5.70])
	var pass_widths: PackedFloat32Array = PackedFloat32Array([2.15 * blur_scale, 0.96 * blur_scale])
	var pass_alphas: PackedFloat32Array = PackedFloat32Array([0.52, 1.00])

	for c_idx: int in range(AURORA_CURTAIN_COUNT):
		var col_top: Color = _sample_aurora_color(_aurora_color_phase + (float(c_idx) * 0.92))
		var col_bot: Color = _sample_aurora_color(_aurora_color_phase + (float(c_idx) * 0.92) + 1.85)
		var base_alpha: float = clampf((0.10 + (0.025 * float(c_idx % 2))) * bright_mult, 0.0, AURORA_MAX_ALPHA)

		var breath: float = 1.0 + (0.06 * sin((_aurora_time * 0.85) + phase_offsets[c_idx]))
		var y_top_px: float = h * y_starts[c_idx]
		var span_ratio: float = minf(0.68, y_spans[c_idx] * breath * stretch_v)
		var span_y: float = maxf(1.0, h * span_ratio)
		var base_hw: float = w * half_widths[c_idx]
		var sway_amp: float = w * 0.042 * undul_mult

		# Double-layer soft textured curtains (wide diffused neon veil + smooth vertical core, zero hard edges)
		for pass_idx: int in range(2):
			var width_scale: float = pass_widths[pass_idx]
			var pass_alpha_scale: float = pass_alphas[pass_idx]
			var pass_top: float = maxf(0.0, y_top_px - (h * 0.03 if pass_idx == 0 else 0.0))
			var pass_span: float = minf(h * 0.74 - pass_top, span_y * (1.10 if pass_idx == 0 else 1.0))
			if pass_span <= 4.0:
				continue

			for s_idx: int in range(AURORA_RIBBON_SEGMENTS):
				var t0: float = float(s_idx) / float(AURORA_RIBBON_SEGMENTS)
				var t1: float = float(s_idx + 1) / float(AURORA_RIBBON_SEGMENTS)

				var y0: float = pass_top + (t0 * pass_span)
				var y1: float = pass_top + (t1 * pass_span)

				var sway0: float = sin((_aurora_time * 0.72) + (t0 * 2.8) + phase_offsets[c_idx]) * sway_amp
				var sway1: float = sin((_aurora_time * 0.72) + (t1 * 2.8) + phase_offsets[c_idx]) * sway_amp

				var cx0: float = (w * x_anchors[c_idx]) + sway0
				var cx1: float = (w * x_anchors[c_idx]) + sway1

				var hw0: float = base_hw * width_scale * (0.82 + (0.24 * sin(t0 * PI)))
				var hw1: float = base_hw * width_scale * (0.82 + (0.24 * sin(t1 * PI)))

				var v_env0: float = vert_grad.sample(t0).a if vert_grad != null else sin(t0 * PI)
				var v_env1: float = vert_grad.sample(t1).a if vert_grad != null else sin(t1 * PI)

				var c0_rgb: Color = col_top.lerp(col_bot, t0)
				var c1_rgb: Color = col_top.lerp(col_bot, t1)
				var a0: float = clampf(base_alpha * pass_alpha_scale * v_env0, 0.0, AURORA_MAX_ALPHA)
				var a1: float = clampf(base_alpha * pass_alpha_scale * v_env1, 0.0, AURORA_MAX_ALPHA)

				_quad_pts_buf[0] = Vector2(cx0 - hw0, y0)
				_quad_pts_buf[1] = Vector2(cx0 + hw0, y0)
				_quad_pts_buf[2] = Vector2(cx1 + hw1, y1)
				_quad_pts_buf[3] = Vector2(cx1 - hw1, y1)
				_quad_cols_buf[0] = Color(minf(c0_rgb.r, AURORA_MAX_RGB_CHANNEL), minf(c0_rgb.g, AURORA_MAX_RGB_CHANNEL), minf(c0_rgb.b, AURORA_MAX_RGB_CHANNEL), a0)
				_quad_cols_buf[1] = _quad_cols_buf[0]
				_quad_cols_buf[2] = Color(minf(c1_rgb.r, AURORA_MAX_RGB_CHANNEL), minf(c1_rgb.g, AURORA_MAX_RGB_CHANNEL), minf(c1_rgb.b, AURORA_MAX_RGB_CHANNEL), a1)
				_quad_cols_buf[3] = _quad_cols_buf[2]
				draw_polygon(_quad_pts_buf, _quad_cols_buf, _quad_uvs_buf, _aurora_horizontal_texture)

	_draw_global_note_hit_flashes(bounds)


func _create_aurora_vertical_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.28, 0.68, 0.86, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.35),
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.45),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 128
	tex.use_hdr = false
	return tex


func _create_aurora_horizontal_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.24, 0.50, 0.76, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.26),
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.26),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 8
	tex.use_hdr = false
	return tex


func _draw_global_note_hit_flashes(p_bounds: Vector2) -> void:
	if get_global_hit_flash_energy() <= 0.004:
		return

	match _hit_effect_style:
		HIT_EFFECT_CLASSIC, _:
			_draw_classic_diffused_hit_flashes(p_bounds)


func _draw_classic_diffused_hit_flashes(p_bounds: Vector2) -> void:
	if _hit_beam_texture == null:
		return

	var w: float = p_bounds.x
	var h: float = p_bounds.y
	var lane_w: float = w * 0.25
	var top_y: float = h * 0.08
	var hit_zone_y: float = h * 0.84
	var energies: PackedFloat32Array = PackedFloat32Array([
		_lane_flashes.x,
		_lane_flashes.y,
		_lane_flashes.z,
		_lane_flashes.w,
	])

	for lane_idx: int in range(4):
		var e: float = clampf(energies[lane_idx], 0.0, 1.0)
		if e <= 0.004:
			continue

		var perfect_boost: float = smoothstep(0.75, 1.0, e)
		var accent_col: Color = Color(0.20, 0.85, 1.0, 1.0)
		var beam_col: Color = accent_col.lerp(Color(0.55, 1.0, 0.96, 1.0), perfect_boost * 0.65)
		var cx: float = (float(lane_idx) + 0.5) * lane_w

		# 1. Wide continuous Gaussian-like diffused vertical glow (wider than lane, zero hard edges)
		var wide_hw: float = lane_w * 0.98
		var wide_alpha: float = clampf(e * 0.46, 0.0, 0.48)
		_quad_pts_buf[0] = Vector2(cx - wide_hw, top_y)
		_quad_pts_buf[1] = Vector2(cx + wide_hw, top_y)
		_quad_pts_buf[2] = Vector2(cx + wide_hw, h)
		_quad_pts_buf[3] = Vector2(cx - wide_hw, h)
		_quad_cols_buf[0] = Color(beam_col.r, beam_col.g, beam_col.b, 0.0)
		_quad_cols_buf[1] = Color(beam_col.r, beam_col.g, beam_col.b, 0.0)
		_quad_cols_buf[2] = Color(beam_col.r, beam_col.g, beam_col.b, wide_alpha)
		_quad_cols_buf[3] = Color(beam_col.r, beam_col.g, beam_col.b, wide_alpha)
		draw_polygon(_quad_pts_buf, _quad_cols_buf, _quad_uvs_buf, _hit_beam_texture)

		# 2. Inner luminous soft core on stronger / PERFECT hits matching reactive_backdrop.gdshader
		if perfect_boost > 0.01:
			var core_hw: float = lane_w * 0.46
			var core_alpha: float = clampf(perfect_boost * 0.38, 0.0, 0.42)
			_quad_pts_buf[0] = Vector2(cx - core_hw, top_y + (h * 0.14))
			_quad_pts_buf[1] = Vector2(cx + core_hw, top_y + (h * 0.14))
			_quad_pts_buf[2] = Vector2(cx + core_hw, h)
			_quad_pts_buf[3] = Vector2(cx - core_hw, h)
			_quad_cols_buf[0] = Color(beam_col.r, beam_col.g, beam_col.b, 0.0)
			_quad_cols_buf[1] = Color(beam_col.r, beam_col.g, beam_col.b, 0.0)
			_quad_cols_buf[2] = Color(beam_col.r, beam_col.g, beam_col.b, core_alpha)
			_quad_cols_buf[3] = Color(beam_col.r, beam_col.g, beam_col.b, core_alpha)
			draw_polygon(_quad_pts_buf, _quad_cols_buf, _quad_uvs_buf, _hit_beam_texture)

		# 3. Soft radial halo glow centered on the hit line
		if _hit_radial_texture != null:
			var halo_rx: float = lane_w * (0.78 + (perfect_boost * 0.24))
			var halo_ry: float = halo_rx * 0.72
			var halo_alpha: float = clampf((e * 0.34) + (perfect_boost * 0.20), 0.0, 0.52)
			var halo_rect: Rect2 = Rect2(cx - halo_rx, hit_zone_y - halo_ry, halo_rx * 2.0, halo_ry * 2.0)
			var halo_tint: Color = Color(beam_col.r, beam_col.g, beam_col.b, halo_alpha)
			draw_texture_rect(_hit_radial_texture, halo_rect, false, halo_tint)


func _create_hit_beam_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 0.50, 0.75, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.28),
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.28),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 8
	tex.use_hdr = false
	return tex


func _create_hit_radial_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.30, 0.65, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.58),
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


func _resolve_draw_bounds() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	var vp_rect: Rect2 = get_viewport_rect()
	if vp_rect.size.x > 1.0 and vp_rect.size.y > 1.0:
		return vp_rect.size
	return Vector2(1080.0, 1920.0)
