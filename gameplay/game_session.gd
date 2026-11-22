class_name GameSession
extends Control

const MAIN_MENU_SCENE_PATH: String = "res://ui/main_menu.tscn"
const DEMO_SONG_KEY: String = ChartCacheRepository.BUILTIN_DEMO_SONG_KEY
const DEMO_BPM: float = 128.0
const DEMO_DURATION_SEC: float = 15.0
const DEMO_SAMPLE_RATE: int = 8000
const BACK_DEBOUNCE_MSEC: int = 300
const SMOOTH_CLOCK_DEADZONE_SEC: float = 0.006
const SMOOTH_CLOCK_DRIFT_CORRECTION_RATE: float = 4.0
const SMOOTH_CLOCK_MAX_CORRECTION_ALPHA: float = 0.08
const SMOOTH_CLOCK_SNAP_THRESHOLD_SEC: float = 0.080
const SMOOTH_CLOCK_MAX_DELTA_SEC: float = 0.05
const ADAPTIVE_VFX_WARMUP_SEC: float = 2.0
const ADAPTIVE_VFX_LOW_FPS_THRESHOLD: float = 52.0
const ADAPTIVE_VFX_TRIGGER_DURATION_SEC: float = 1.5
const ADAPTIVE_VFX_RELIEF_SCALE: float = 0.5

static var pending_session_config: Dictionary = {}

@export var dsp_clock: DSPClock = null
@export var audio_analyzer: AudioAnalyzer = null
@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var input_adapter: RhythmInputAdapter = null
@export var hit_judge: HitJudge = null
@export var lane_field: LaneField = null
@export var reactive_background: ReactiveBackground = null
@export var reactive_particles_layer: ReactiveParticlesLayer = null
@export var safe_hud: SafeHud = null
@export var particles_settings_path: String = ReactiveParticlesConfig.DEFAULT_SETTINGS_PATH
@export var background_settings_path: String = ReactiveBackgroundConfig.DEFAULT_SETTINGS_PATH
@export var effects_settings_path: String = GameplayEffectsConfig.DEFAULT_SETTINGS_PATH
@export var custom_audio_path: String = ""
@export var default_difficulty: int = AutoChartGenerator.Difficulty.NORMAL
@export var default_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
@export var auto_start_demo: bool = true

var _active_chart: ChartData = null
var _active_audio_stream: AudioStream = null
var _active_song_key: String = DEMO_SONG_KEY
var _active_difficulty: int = AutoChartGenerator.Difficulty.NORMAL
var _active_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
var _active_speed_multiplier: int = LaneField.MIN_SPEED_MULTIPLIER
var _chart_cache_repo: ChartCacheRepository = ChartCacheRepository.new()
var _particles_config: ReactiveParticlesConfig = ReactiveParticlesConfig.new()
var _bg_config: ReactiveBackgroundConfig = ReactiveBackgroundConfig.new()
var _effects_config: GameplayEffectsConfig = GameplayEffectsConfig.new()
var _last_chart_loaded_from_cache: bool = false
var _last_back_msec: int = -BACK_DEBOUNCE_MSEC
var _is_app_backgrounded: bool = false
var _master_was_muted_before_bg: bool = false
var smooth_song_time: float = 0.0
var _smooth_song_time_initialized: bool = false
var vfx_relief_scale: float = 1.0
var _adaptive_vfx_elapsed_sec: float = 0.0
var _adaptive_vfx_low_fps_accum_sec: float = 0.0


static func set_pending_session(p_config: Dictionary) -> void:
	pending_session_config = p_config.duplicate()


static func clear_pending_session() -> void:
	pending_session_config.clear()


func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.set_quit_on_go_back(false)
		tree.set_auto_accept_quit(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resolve_and_wire_nodes()
	_connect_viewport_resize()
	sync_responsive_viewport_layout()

	if not pending_session_config.is_empty():
		var launch_cfg: Dictionary = pending_session_config.duplicate()
		clear_pending_session()
		_start_from_pending_config(launch_cfg)
		return

	if not custom_audio_path.is_empty():
		var started: bool = start_audio_file_session(
			custom_audio_path,
			default_difficulty,
			default_note_type_mode
		)
		if not started and auto_start_demo:
			start_demo_session(default_note_type_mode)
	elif auto_start_demo:
		start_demo_session(default_note_type_mode)


func _exit_tree() -> void:
	var vp: Viewport = get_viewport()
	if vp != null and vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.disconnect(_on_viewport_size_changed)
	var tree: SceneTree = get_tree()
	if tree != null and tree.root != null and tree.root.size_changed.is_connected(_on_viewport_size_changed):
		tree.root.size_changed.disconnect(_on_viewport_size_changed)
	if _is_app_backgrounded:
		AudioServer.set_bus_mute(0, _master_was_muted_before_bg)
		_is_app_backgrounded = false


func _connect_viewport_resize() -> void:
	var vp: Viewport = get_viewport()
	if vp != null and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)
	var tree: SceneTree = get_tree()
	if tree != null and tree.root != null and tree.root != vp:
		if not tree.root.size_changed.is_connected(_on_viewport_size_changed):
			tree.root.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	sync_responsive_viewport_layout()


func sync_responsive_viewport_layout(p_explicit_size: Vector2 = Vector2.ZERO) -> void:
	var has_explicit: bool = p_explicit_size.x > 1.0 and p_explicit_size.y > 1.0
	var vp_size: Vector2 = p_explicit_size
	if has_explicit:
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		position = Vector2.ZERO
		size = vp_size
	else:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var vp_rect: Rect2 = get_viewport_rect()
		if vp_rect.size.x > 1.0 and vp_rect.size.y > 1.0:
			vp_size = vp_rect.size
		else:
			vp_size = Vector2(ScreenSafeAdapter.DEFAULT_VIEWPORT_WIDTH, ScreenSafeAdapter.DEFAULT_VIEWPORT_HEIGHT)

	var explicit_arg: Vector2 = vp_size if has_explicit else Vector2.ZERO
	if reactive_background != null:
		reactive_background.sync_full_viewport_bounds(explicit_arg)
	if reactive_particles_layer != null:
		reactive_particles_layer.sync_full_viewport_bounds(explicit_arg)
	if safe_hud != null:
		if has_explicit:
			safe_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
			safe_hud.position = Vector2.ZERO
			safe_hud.size = vp_size
		else:
			safe_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if screen_safe_adapter != null:
		screen_safe_adapter.recalculate_for_viewport_size(vp_size)
	_sync_all_effect_controllers_to_lane_field()
	call_deferred(&"_sync_all_effect_controllers_to_lane_field")


func _sync_all_effect_controllers_to_lane_field() -> void:
	sync_lane_geometry_to_background()
	if safe_hud != null and lane_field != null:
		safe_hud.sync_lane_field_geometry(lane_field)


func _process(p_delta: float) -> void:
	if dsp_clock == null or not dsp_clock.is_playing():
		return
	var target_audio_time: float = _sample_real_audio_clock_sec()
	step_smooth_song_time_for_test(p_delta, target_audio_time)
	if lane_field != null:
		lane_field.set_smooth_visual_time(smooth_song_time)
	step_adaptive_vfx_monitor(p_delta, float(Engine.get_frames_per_second()))


func get_vfx_relief_scale() -> float:
	return vfx_relief_scale


func reset_adaptive_vfx_relief() -> void:
	vfx_relief_scale = 1.0
	_adaptive_vfx_elapsed_sec = 0.0
	_adaptive_vfx_low_fps_accum_sec = 0.0
	_apply_vfx_relief_scale(vfx_relief_scale)


func step_adaptive_vfx_monitor(p_delta: float, p_fps: float) -> float:
	var dt: float = clampf(p_delta, 0.0, 0.25)
	_adaptive_vfx_elapsed_sec += dt
	if _adaptive_vfx_elapsed_sec < ADAPTIVE_VFX_WARMUP_SEC:
		return vfx_relief_scale

	if p_fps > 0.0 and p_fps < ADAPTIVE_VFX_LOW_FPS_THRESHOLD:
		_adaptive_vfx_low_fps_accum_sec += dt
		if _adaptive_vfx_low_fps_accum_sec >= ADAPTIVE_VFX_TRIGGER_DURATION_SEC and vfx_relief_scale > ADAPTIVE_VFX_RELIEF_SCALE:
			vfx_relief_scale = ADAPTIVE_VFX_RELIEF_SCALE
			_apply_vfx_relief_scale(vfx_relief_scale)
	elif p_fps >= ADAPTIVE_VFX_LOW_FPS_THRESHOLD:
		_adaptive_vfx_low_fps_accum_sec = maxf(0.0, _adaptive_vfx_low_fps_accum_sec - (dt * 2.0))
	return vfx_relief_scale


func _apply_vfx_relief_scale(p_scale: float) -> void:
	var clamped: float = clampf(p_scale, ADAPTIVE_VFX_RELIEF_SCALE, 1.0)
	if reactive_particles_layer != null:
		reactive_particles_layer.set_vfx_relief_scale(clamped)
	if reactive_background != null:
		reactive_background.set_vfx_relief_scale(clamped)
	if lane_field != null:
		lane_field.set_vfx_relief_scale(clamped)


func get_smooth_song_time() -> float:
	return smooth_song_time


func reset_smooth_song_time(p_time_sec: float = 0.0) -> void:
	smooth_song_time = p_time_sec
	_smooth_song_time_initialized = true
	if lane_field != null:
		lane_field.set_smooth_visual_time(smooth_song_time)


func step_smooth_song_time_for_test(p_delta: float, p_target_audio_time_sec: float) -> float:
	var dt: float = clampf(p_delta, 0.0, SMOOTH_CLOCK_MAX_DELTA_SEC)
	if not _smooth_song_time_initialized:
		smooth_song_time = p_target_audio_time_sec
		_smooth_song_time_initialized = true
		return smooth_song_time

	var prev_time: float = smooth_song_time
	var predicted_time: float = prev_time + dt
	var drift_sec: float = p_target_audio_time_sec - predicted_time
	var abs_drift_sec: float = absf(drift_sec)

	if abs_drift_sec > SMOOTH_CLOCK_SNAP_THRESHOLD_SEC:
		smooth_song_time = p_target_audio_time_sec
	elif abs_drift_sec < SMOOTH_CLOCK_DEADZONE_SEC:
		smooth_song_time = predicted_time
	else:
		var corr_alpha: float = clampf(
			dt * SMOOTH_CLOCK_DRIFT_CORRECTION_RATE,
			0.0,
			SMOOTH_CLOCK_MAX_CORRECTION_ALPHA
		)
		smooth_song_time = maxf(prev_time, lerpf(predicted_time, p_target_audio_time_sec, corr_alpha))
	return smooth_song_time


func _sample_real_audio_clock_sec() -> float:
	if dsp_clock == null:
		return smooth_song_time
	if dsp_clock.audio_player != null and dsp_clock.audio_player.stream != null and dsp_clock.audio_player.playing and not dsp_clock.audio_player.stream_paused:
		var chart_offset: float = _active_chart.offset_sec if _active_chart != null else 0.0
		return (
			dsp_clock.audio_player.get_playback_position()
			+ maxf(0.0, AudioServer.get_time_since_last_mix())
			- AudioServer.get_output_latency()
			- chart_offset
			- dsp_clock.user_offset_sec
		)
	return dsp_clock.get_current_dsp_time()


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_WM_CLOSE_REQUEST:
			handle_back_request()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_handle_app_backgrounded()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_handle_app_foregrounded()


func _handle_app_backgrounded() -> void:
	if _is_app_backgrounded:
		AudioServer.set_bus_mute(0, true)
		return
	_is_app_backgrounded = true
	_master_was_muted_before_bg = AudioServer.is_bus_mute(0)

	var results_open: bool = safe_hud != null and safe_hud.is_results_overlay_open()
	var pause_open: bool = safe_hud != null and safe_hud.is_pause_menu_open()
	var countdown_active: bool = safe_hud != null and safe_hud.is_resume_countdown_active()

	if not results_open:
		if safe_hud != null:
			if not pause_open or countdown_active:
				safe_hud.open_pause_menu()
		elif dsp_clock != null:
			dsp_clock.pause()

		if dsp_clock != null and dsp_clock.audio_player != null and dsp_clock.audio_player.playing:
			dsp_clock.audio_player.stream_paused = true

	AudioServer.set_bus_mute(0, true)


func _handle_app_foregrounded() -> void:
	if not _is_app_backgrounded:
		return
	_is_app_backgrounded = false
	AudioServer.set_bus_mute(0, _master_was_muted_before_bg)


func _input(p_event: InputEvent) -> void:
	if p_event is InputEventKey:
		var key_event: InputEventKey = p_event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var code: Key = key_event.keycode if key_event.keycode != KEY_NONE else key_event.physical_keycode
			if code == KEY_BACK:
				var vp: Viewport = get_viewport()
				if vp != null:
					vp.set_input_as_handled()
				handle_back_request()


func _unhandled_input(p_event: InputEvent) -> void:
	if p_event != null and p_event.is_action_pressed(&"ui_cancel"):
		var vp: Viewport = get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		handle_back_request()


func _consume_back_debounce(p_now_msec: int = -1) -> bool:
	var now_msec: int = p_now_msec if p_now_msec >= 0 else Time.get_ticks_msec()
	if (now_msec - _last_back_msec) < BACK_DEBOUNCE_MSEC:
		return false
	_last_back_msec = now_msec
	return true


func handle_back_request(p_now_msec: int = -1) -> void:
	if safe_hud == null:
		return
	if not _consume_back_debounce(p_now_msec):
		return
	if safe_hud.is_results_overlay_open():
		_on_main_menu_requested()
		return
	if safe_hud.is_pause_menu_open():
		safe_hud.close_pause_menu_and_resume()
		return
	safe_hud.open_pause_menu()


func start_demo_session(
	p_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
) -> void:
	_resolve_and_wire_nodes()
	_active_song_key = ChartCacheRepository.normalize_song_key(DEMO_SONG_KEY)
	_active_note_type_mode = p_note_type_mode
	_last_chart_loaded_from_cache = false

	if lane_field != null:
		lane_field.set_speed_multiplier(_active_speed_multiplier)
	if hit_judge != null:
		hit_judge.set_difficulty(_active_difficulty)

	var demo_chart: ChartData = build_demo_chart(p_note_type_mode)
	_active_audio_stream = _generate_metronome_stream(
		demo_chart.duration_sec,
		demo_chart.bpm_estimate
	)
	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(true)
	start_chart_session(demo_chart)


func start_audio_file_session(
	p_audio_path: String,
	p_difficulty: int = AutoChartGenerator.Difficulty.NORMAL,
	p_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD,
	p_title: String = ""
) -> bool:
	_resolve_and_wire_nodes()
	if audio_analyzer == null or p_audio_path.is_empty():
		return false

	var stream: AudioStream = audio_analyzer.load_audio_stream(p_audio_path)
	if stream == null:
		return false

	_active_song_key = ChartCacheRepository.normalize_song_key(p_audio_path)
	_active_difficulty = p_difficulty
	_active_note_type_mode = p_note_type_mode

	if lane_field != null:
		lane_field.set_speed_multiplier(_active_speed_multiplier)
	if hit_judge != null:
		hit_judge.set_difficulty(_active_difficulty)

	var cache_key: String = _chart_cache_repo.build_cache_key(
		p_audio_path,
		p_difficulty,
		p_note_type_mode
	)
	var chart: ChartData = _chart_cache_repo.load_cached_chart(cache_key)
	if chart != null:
		_last_chart_loaded_from_cache = true
		if not p_title.is_empty():
			chart.title = p_title
	else:
		_last_chart_loaded_from_cache = false
		var analysis: Dictionary = audio_analyzer.analyze_audio_stream(stream)
		var duration_sec: float = analysis.get("duration_sec", 0.0) as float
		if duration_sec <= 0.0:
			return false

		var file_basename: String = p_audio_path.get_file().get_basename()
		var song_id: String = file_basename if not file_basename.is_empty() else "custom_track"
		var decoded_title: String = file_basename.uri_decode().uri_decode().strip_edges()
		var fallback_title: String = decoded_title if not decoded_title.is_empty() else song_id
		var resolved_title: String = p_title if not p_title.is_empty() else fallback_title

		var generator: AutoChartGenerator = AutoChartGenerator.new()
		chart = generator.generate_from_analysis(
			song_id,
			resolved_title,
			p_audio_path,
			analysis,
			p_difficulty,
			p_note_type_mode
		)
		AudioAnalyzer.release_analysis_buffers(analysis)

		var validation: Dictionary = chart.validate()
		if not (validation.get("valid", false) as bool):
			return false

		_chart_cache_repo.save_cached_chart(cache_key, chart)

	_active_audio_stream = stream
	audio_analyzer.set_live_monitoring(true)
	return start_chart_session(chart)


func start_chart_session(p_chart: ChartData) -> bool:
	_resolve_and_wire_nodes()
	if p_chart == null:
		return false

	var validation: Dictionary = p_chart.validate()
	if not (validation.get("valid", false) as bool):
		return false

	_active_chart = p_chart

	if input_adapter != null:
		input_adapter.reset_input_state()

	if dsp_clock != null:
		if not dsp_clock.load_chart(p_chart):
			return false
		if dsp_clock.audio_player != null:
			if _active_audio_stream != null:
				dsp_clock.audio_player.stream = _active_audio_stream
			elif dsp_clock.audio_player.stream == null:
				dsp_clock.audio_player.stream = _generate_metronome_stream(
					p_chart.duration_sec,
					p_chart.bpm_estimate
				)

	if lane_field != null:
		lane_field.set_speed_multiplier(_active_speed_multiplier)
	if hit_judge != null:
		hit_judge.set_difficulty(_active_difficulty)
		if not lane_field.load_chart(p_chart):
			return false
	elif hit_judge != null:
		if not hit_judge.load_chart(p_chart):
			return false

	if safe_hud != null:
		safe_hud.reset_hud_display()
		safe_hud.set_song_duration_sec(p_chart.duration_sec)

	if screen_safe_adapter != null:
		screen_safe_adapter.recalculate_layout()
	sync_lane_geometry_to_background()

	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(true)

	if dsp_clock != null:
		dsp_clock.start()
		reset_smooth_song_time(dsp_clock.get_current_dsp_time())
	reset_adaptive_vfx_relief()

	return true


func build_demo_chart(
	p_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
) -> ChartData:
	var beat_sec: float = 60.0 / DEMO_BPM
	var notes: Array[NoteData] = []
	var allow_holds: bool = (
		p_note_type_mode == AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
		or p_note_type_mode == AutoChartGenerator.NoteTypeMode.HOLD_AND_DOUBLE_TAP
	)
	var allow_double_taps: bool = (
		p_note_type_mode == AutoChartGenerator.NoteTypeMode.DOUBLE_TAP
		or p_note_type_mode == AutoChartGenerator.NoteTypeMode.HOLD_AND_DOUBLE_TAP
	)
	var is_combined_mode: bool = p_note_type_mode == AutoChartGenerator.NoteTypeMode.HOLD_AND_DOUBLE_TAP
	var lane_pattern: PackedInt32Array = PackedInt32Array([0, 2, 1, 3])

	for step_idx: int in range(28):
		var note_time_sec: float = float(step_idx + 1) * beat_sec
		var lane_idx: int = lane_pattern[step_idx % 4]
		var strength: float = 1.0 if (step_idx % 4) == 0 else 0.75

		if is_combined_mode:
			var cycle_pos: int = step_idx % 7
			var is_combined_hold: bool = cycle_pos == 1 or cycle_pos == 4
			var is_combined_double: bool = cycle_pos == 0 or cycle_pos == 3
			var combined_dur: float = beat_sec * 1.25 if is_combined_hold else 0.0
			if is_combined_double:
				var opp_lane: int = (2 if (step_idx % 4) == 0 else 3) if lane_idx <= 1 else (0 if (step_idx % 4) == 1 else 1)
				var first_lane: int = mini(lane_idx, opp_lane)
				var second_lane: int = maxi(lane_idx, opp_lane)
				notes.append(NoteData.new(note_time_sec, first_lane, 0.0, strength))
				notes.append(NoteData.new(note_time_sec, second_lane, 0.0, strength))
			else:
				notes.append(NoteData.new(note_time_sec, lane_idx, combined_dur, strength))
			continue

		var is_hold_step: bool = allow_holds and ((step_idx % 7) == 3)
		var duration_sec: float = beat_sec * 1.5 if is_hold_step else 0.0
		var note: NoteData = NoteData.new(note_time_sec, lane_idx, duration_sec, strength)
		notes.append(note)

		if allow_double_taps and not is_hold_step and (step_idx == 0 or step_idx == 8 or step_idx == 16 or step_idx == 20):
			var partner_lane: int = 3 if step_idx == 20 else 2
			notes.append(NoteData.new(note_time_sec, partner_lane, 0.0, strength))

	var blocks: Array[IntensityBlock] = [
		IntensityBlock.new(0.0, 3.75, 0.25, 0),
		IntensityBlock.new(3.75, 7.50, 0.50, 1),
		IntensityBlock.new(7.50, 11.25, 0.78, 2),
		IntensityBlock.new(11.25, DEMO_DURATION_SEC, 1.00, 3),
	]

	var chart: ChartData = ChartData.new(
		DEMO_SONG_KEY,
		"FeelYourBeats Demo 128 BPM",
		"",
		DEMO_DURATION_SEC,
		DEMO_BPM,
		0.0,
		notes,
		blocks
	)
	return chart


func get_active_chart() -> ChartData:
	return _active_chart


func get_chart_cache_repository() -> ChartCacheRepository:
	return _chart_cache_repo


func set_chart_cache_repository(p_repo: ChartCacheRepository) -> void:
	if p_repo != null:
		_chart_cache_repo = p_repo


func was_last_chart_from_cache() -> bool:
	return _last_chart_loaded_from_cache


func get_active_speed_multiplier() -> int:
	return _active_speed_multiplier


func get_reactive_particles_layer() -> ReactiveParticlesLayer:
	return reactive_particles_layer


func reload_particle_settings() -> void:
	_particles_config.load_from_file(particles_settings_path)
	if reactive_particles_layer != null:
		reactive_particles_layer.apply_config(_particles_config)


func reload_background_settings() -> void:
	_bg_config.load_from_file(background_settings_path)
	if reactive_background != null:
		reactive_background.apply_background_config(_bg_config)


func reload_gameplay_effects_settings() -> void:
	_effects_config.load_from_file(effects_settings_path)
	if reactive_background != null:
		reactive_background.apply_gameplay_effects_config(_effects_config)
	if lane_field != null:
		lane_field.apply_gameplay_effects_config(_effects_config)
	sync_lane_geometry_to_background()


func sync_lane_geometry_to_background() -> void:
	if lane_field == null or reactive_background == null:
		return
	reactive_background.sync_lane_geometry_from_lane_field(lane_field)


func _start_from_pending_config(p_cfg: Dictionary) -> void:
	var is_demo: bool = p_cfg.get("is_demo", false) as bool
	var difficulty: int = int(p_cfg.get("difficulty", default_difficulty))
	var note_type_mode: int = int(p_cfg.get("note_type_mode", default_note_type_mode))
	var speed_multiplier: int = clampi(
		int(p_cfg.get("speed_multiplier", LaneField.MIN_SPEED_MULTIPLIER)),
		LaneField.MIN_SPEED_MULTIPLIER,
		LaneField.MAX_SPEED_MULTIPLIER
	)
	var audio_path: String = str(p_cfg.get("audio_path", ""))
	var title: String = str(p_cfg.get("title", ""))

	_active_difficulty = difficulty
	_active_note_type_mode = note_type_mode
	_active_speed_multiplier = speed_multiplier
	if lane_field != null:
		lane_field.set_speed_multiplier(_active_speed_multiplier)
	if hit_judge != null:
		hit_judge.set_difficulty(_active_difficulty)

	if is_demo or audio_path.is_empty():
		start_demo_session(note_type_mode)
		return

	var preloaded_chart: ChartData = p_cfg.get("preloaded_chart", null) as ChartData
	var preloaded_stream: AudioStream = p_cfg.get("preloaded_stream", null) as AudioStream
	if preloaded_chart != null and preloaded_stream != null:
		_active_song_key = ChartCacheRepository.normalize_song_key(audio_path)
		_active_audio_stream = preloaded_stream
		_last_chart_loaded_from_cache = p_cfg.get("from_cache", false) as bool
		if audio_analyzer != null:
			audio_analyzer.set_live_monitoring(true)
		if start_chart_session(preloaded_chart):
			return

	var started: bool = start_audio_file_session(audio_path, difficulty, note_type_mode, title)
	if not started and auto_start_demo:
		start_demo_session(note_type_mode)


func _resolve_and_wire_nodes() -> void:
	if dsp_clock == null:
		dsp_clock = get_node_or_null("DSPClock") as DSPClock
	if audio_analyzer == null:
		audio_analyzer = get_node_or_null("AudioAnalyzer") as AudioAnalyzer
	if screen_safe_adapter == null:
		screen_safe_adapter = get_node_or_null("ScreenSafeAdapter") as ScreenSafeAdapter
	if input_adapter == null:
		input_adapter = get_node_or_null("RhythmInputAdapter") as RhythmInputAdapter
	if hit_judge == null:
		hit_judge = get_node_or_null("HitJudge") as HitJudge
	if reactive_background == null:
		reactive_background = get_node_or_null("ReactiveBackground") as ReactiveBackground
	if reactive_particles_layer == null:
		reactive_particles_layer = get_node_or_null("ReactiveParticlesLayer") as ReactiveParticlesLayer
	if lane_field == null:
		lane_field = get_node_or_null("LaneField") as LaneField
	if safe_hud == null:
		safe_hud = get_node_or_null("SafeHud") as SafeHud

	if reactive_particles_layer == null:
		reactive_particles_layer = ReactiveParticlesLayer.new()
		reactive_particles_layer.name = "ReactiveParticlesLayer"
		add_child(reactive_particles_layer)

	if reactive_background != null and reactive_particles_layer.get_parent() == self:
		var bg_idx: int = reactive_background.get_index()
		if reactive_particles_layer.get_index() != bg_idx + 1:
			move_child(reactive_particles_layer, bg_idx + 1)
	elif lane_field != null and reactive_particles_layer.get_parent() == self:
		var lane_idx: int = lane_field.get_index()
		if reactive_particles_layer.get_index() > lane_idx:
			move_child(reactive_particles_layer, lane_idx)

	if dsp_clock != null:
		if not dsp_clock.playback_finished.is_connected(_on_playback_finished):
			dsp_clock.playback_finished.connect(_on_playback_finished)

	if input_adapter != null:
		input_adapter.dsp_clock = dsp_clock
		input_adapter.screen_safe_adapter = screen_safe_adapter

	if reactive_background != null:
		reactive_background.set_backdrop_mode(ReactiveBackground.BackdropMode.GAMEPLAY)
		reactive_background.set_perimeter_wave_enabled(true)
		reactive_background.dsp_clock = dsp_clock
		reactive_background.hit_judge = hit_judge
		reactive_background.audio_analyzer = audio_analyzer
		reactive_background.connect_dependencies()
		reload_background_settings()
		if not reactive_background.screen_shake_updated.is_connected(_on_screen_shake_updated):
			reactive_background.screen_shake_updated.connect(_on_screen_shake_updated)

	if reactive_particles_layer != null:
		reactive_particles_layer.dsp_clock = dsp_clock
		reactive_particles_layer.reactive_background = reactive_background
		reactive_particles_layer.audio_analyzer = audio_analyzer
		reactive_particles_layer.connect_dependencies()
		reload_particle_settings()

	if lane_field != null:
		lane_field.dsp_clock = dsp_clock
		lane_field.screen_safe_adapter = screen_safe_adapter
		lane_field.input_adapter = input_adapter
		lane_field.hit_judge = hit_judge
		lane_field.audio_analyzer = audio_analyzer
		lane_field.connect_dependencies()
		if not lane_field.resized.is_connected(_sync_all_effect_controllers_to_lane_field):
			lane_field.resized.connect(_sync_all_effect_controllers_to_lane_field)
		if not lane_field.lane_geometry_changed.is_connected(_sync_all_effect_controllers_to_lane_field):
			lane_field.lane_geometry_changed.connect(_sync_all_effect_controllers_to_lane_field)
		if screen_safe_adapter != null:
			lane_field.apply_safe_layout(
				screen_safe_adapter.get_play_rect(),
				screen_safe_adapter.get_hud_safe_rect()
			)
			if not screen_safe_adapter.safe_play_rect_changed.is_connected(_on_safe_play_rect_changed_for_background):
				screen_safe_adapter.safe_play_rect_changed.connect(_on_safe_play_rect_changed_for_background)
		_sync_all_effect_controllers_to_lane_field()

	reload_gameplay_effects_settings()

	if hit_judge != null:
		hit_judge.set_difficulty(_active_difficulty)
		if not hit_judge.danger_overflowed.is_connected(_on_danger_overflowed):
			hit_judge.danger_overflowed.connect(_on_danger_overflowed)
		if not hit_judge.note_judged.is_connected(_on_note_judged_sync_background):
			hit_judge.note_judged.connect(_on_note_judged_sync_background)

	if safe_hud != null:
		safe_hud.screen_safe_adapter = screen_safe_adapter
		safe_hud.hit_judge = hit_judge
		safe_hud.dsp_clock = dsp_clock
		safe_hud.input_adapter = input_adapter
		safe_hud.reactive_background = reactive_background
		safe_hud.lane_field = lane_field
		safe_hud.connect_dependencies()
		if not safe_hud.pause_requested.is_connected(_on_pause_requested):
			safe_hud.pause_requested.connect(_on_pause_requested)
		if not safe_hud.restart_requested.is_connected(_on_restart_requested):
			safe_hud.restart_requested.connect(_on_restart_requested)
		if not safe_hud.main_menu_requested.is_connected(_on_main_menu_requested):
			safe_hud.main_menu_requested.connect(_on_main_menu_requested)
		if screen_safe_adapter != null:
			safe_hud.apply_hud_safe_rect(screen_safe_adapter.get_hud_safe_rect())
		safe_hud.sync_lane_field_geometry(lane_field)


func _on_screen_shake_updated(p_offset: Vector2) -> void:
	if lane_field == null:
		return
	var base_pos: Vector2 = screen_safe_adapter.get_play_rect().position if screen_safe_adapter != null else Vector2.ZERO
	var is_paused_or_overlay: bool = (
		safe_hud != null
		and (
			safe_hud.is_pause_menu_open()
			or safe_hud.is_resume_countdown_active()
			or safe_hud.is_results_overlay_open()
		)
	)
	if is_paused_or_overlay:
		lane_field.position = base_pos
	else:
		lane_field.position = base_pos + p_offset
	_sync_all_effect_controllers_to_lane_field()


func _on_safe_play_rect_changed_for_background(_p_play_rect: Rect2, _p_hud_safe_rect: Rect2) -> void:
	_sync_all_effect_controllers_to_lane_field()


func _on_note_judged_sync_background(_p_lane: int, _p_grade: int, _p_error_ms: float, _p_combo: int) -> void:
	_sync_all_effect_controllers_to_lane_field()


func _on_pause_requested() -> void:
	if reactive_background != null:
		reactive_background.reset_shake()
	if lane_field != null:
		var base_pos: Vector2 = screen_safe_adapter.get_play_rect().position if screen_safe_adapter != null else Vector2.ZERO
		lane_field.position = base_pos


func _on_playback_finished() -> void:
	if safe_hud != null and safe_hud.is_results_overlay_open():
		return
	_present_results(false)


func _on_danger_overflowed() -> void:
	if safe_hud != null and safe_hud.is_results_overlay_open():
		return
	if dsp_clock != null:
		dsp_clock.stop()
	if input_adapter != null:
		input_adapter.reset_input_state()
	_present_results(true)


func _present_results(p_is_failed: bool = false) -> void:
	if reactive_background != null:
		reactive_background.reset_shake()
	if lane_field != null:
		var base_pos: Vector2 = screen_safe_adapter.get_play_rect().position if screen_safe_adapter != null else Vector2.ZERO
		lane_field.position = base_pos

	var final_score: int = hit_judge.score if hit_judge != null else 0
	var final_max_combo: int = hit_judge.max_combo if hit_judge != null else 0
	var accuracy_percent: float = hit_judge.get_accuracy_percent() if hit_judge != null else 0.0
	var breakdown: Dictionary = hit_judge.get_judgment_breakdown() if hit_judge != null else {}
	var title: String = _active_chart.title if _active_chart != null else "RESULTADOS"
	var rank: String = SafeHud.compute_letter_rank(accuracy_percent)

	var is_new_record: bool = false
	if not p_is_failed and not _active_song_key.is_empty():
		is_new_record = _chart_cache_repo.save_song_record_if_better(
			_active_song_key,
			_active_difficulty,
			_active_note_type_mode,
			rank,
			final_score,
			accuracy_percent
		)

	if safe_hud != null:
		safe_hud.show_results_overlay(
			title,
			final_score,
			accuracy_percent,
			final_max_combo,
			breakdown,
			is_new_record,
			p_is_failed
		)


func _on_restart_requested() -> void:
	reset_adaptive_vfx_relief()
	if _active_chart != null:
		start_chart_session(_active_chart)
	else:
		start_demo_session(_active_note_type_mode)


func _on_main_menu_requested() -> void:
	reset_adaptive_vfx_relief()
	# Ensure persistent root click SFX is already playing before scene change
	# (without duplicating if a wired button already fired it)
	var global_sfx: UiSfxPlayer = get_node_or_null("/root/GlobalUiSfx") as UiSfxPlayer
	if global_sfx == null and safe_hud != null:
		global_sfx = safe_hud.ui_sfx_player
	if global_sfx != null and not global_sfx.is_click_playing():
		global_sfx.play_button_click()

	if dsp_clock != null:
		dsp_clock.stop()
	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(false)
	if input_adapter != null:
		input_adapter.reset_input_state()
	clear_pending_session()
	MainMenu.open_directly_to_selector = true

	var tree: SceneTree = get_tree()
	if tree != null and ResourceLoader.exists(MAIN_MENU_SCENE_PATH):
		tree.call_deferred(&"change_scene_to_file", MAIN_MENU_SCENE_PATH)


func _generate_metronome_stream(p_duration_sec: float, p_bpm: float) -> AudioStreamWAV:
	var total_samples: int = maxi(1, int(ceil(p_duration_sec * float(DEMO_SAMPLE_RATE))))
	var pcm_bytes: PackedByteArray = PackedByteArray()
	pcm_bytes.resize(total_samples)

	var samples_per_beat: int = maxi(1, int(round((60.0 / maxf(1.0, p_bpm)) * float(DEMO_SAMPLE_RATE))))
	var click_samples: int = mini(160, samples_per_beat / 4)

	for i: int in range(total_samples):
		var phase_in_beat: int = i % samples_per_beat
		if phase_in_beat < click_samples:
			var envelope: float = 1.0 - (float(phase_in_beat) / float(click_samples))
			var carrier: float = sin(float(phase_in_beat) * 0.55)
			var signed_val: int = clampi(int(round(carrier * envelope * 42.0)), -127, 127)
			pcm_bytes[i] = (signed_val + 256) % 256
		else:
			pcm_bytes[i] = 0

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.mix_rate = DEMO_SAMPLE_RATE
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.stereo = false
	wav.data = pcm_bytes
	return wav
