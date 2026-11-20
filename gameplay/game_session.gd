class_name GameSession
extends Control

const MAIN_MENU_SCENE_PATH: String = "res://ui/main_menu.tscn"
const DEMO_SONG_KEY: String = ChartCacheRepository.BUILTIN_DEMO_SONG_KEY
const DEMO_BPM: float = 128.0
const DEMO_DURATION_SEC: float = 15.0
const DEMO_SAMPLE_RATE: int = 8000

static var pending_session_config: Dictionary = {}

@export var dsp_clock: DSPClock = null
@export var audio_analyzer: AudioAnalyzer = null
@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var input_adapter: RhythmInputAdapter = null
@export var hit_judge: HitJudge = null
@export var lane_field: LaneField = null
@export var reactive_background: ReactiveBackground = null
@export var safe_hud: SafeHud = null
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
var _last_chart_loaded_from_cache: bool = false


static func set_pending_session(p_config: Dictionary) -> void:
	pending_session_config = p_config.duplicate()


static func clear_pending_session() -> void:
	pending_session_config.clear()


func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.set_auto_accept_quit(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resolve_and_wire_nodes()

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


func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_WM_GO_BACK_REQUEST or p_what == NOTIFICATION_WM_CLOSE_REQUEST:
		handle_back_request()


func _unhandled_input(p_event: InputEvent) -> void:
	if p_event != null and p_event.is_action_pressed(&"ui_cancel"):
		var vp: Viewport = get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		handle_back_request()


func handle_back_request() -> void:
	if safe_hud == null:
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

	if screen_safe_adapter != null:
		screen_safe_adapter.recalculate_layout()

	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(true)

	if dsp_clock != null:
		dsp_clock.start()

	return true


func build_demo_chart(
	p_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
) -> ChartData:
	var beat_sec: float = 60.0 / DEMO_BPM
	var notes: Array[NoteData] = []
	var allow_holds: bool = p_note_type_mode != AutoChartGenerator.NoteTypeMode.TAP_ONLY

	for step_idx: int in range(28):
		var note_time_sec: float = float(step_idx + 1) * beat_sec
		var lane_idx: int = step_idx % 4
		var is_hold_step: bool = allow_holds and ((step_idx % 7) == 3)
		var duration_sec: float = beat_sec * 1.5 if is_hold_step else 0.0
		var strength: float = 1.0 if (step_idx % 4) == 0 else 0.75
		var note: NoteData = NoteData.new(note_time_sec, lane_idx, duration_sec, strength)
		notes.append(note)

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
	if lane_field == null:
		lane_field = get_node_or_null("LaneField") as LaneField
	if safe_hud == null:
		safe_hud = get_node_or_null("SafeHud") as SafeHud

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
		if not reactive_background.screen_shake_updated.is_connected(_on_screen_shake_updated):
			reactive_background.screen_shake_updated.connect(_on_screen_shake_updated)

	if lane_field != null:
		lane_field.dsp_clock = dsp_clock
		lane_field.screen_safe_adapter = screen_safe_adapter
		lane_field.input_adapter = input_adapter
		lane_field.hit_judge = hit_judge
		lane_field.audio_analyzer = audio_analyzer
		lane_field.connect_dependencies()
		if screen_safe_adapter != null:
			lane_field.apply_safe_layout(
				screen_safe_adapter.get_play_rect(),
				screen_safe_adapter.get_hud_safe_rect()
			)

	if hit_judge != null:
		hit_judge.set_difficulty(_active_difficulty)
		if not hit_judge.danger_overflowed.is_connected(_on_danger_overflowed):
			hit_judge.danger_overflowed.connect(_on_danger_overflowed)

	if safe_hud != null:
		safe_hud.screen_safe_adapter = screen_safe_adapter
		safe_hud.hit_judge = hit_judge
		safe_hud.dsp_clock = dsp_clock
		safe_hud.input_adapter = input_adapter
		safe_hud.reactive_background = reactive_background
		safe_hud.connect_dependencies()
		if not safe_hud.pause_requested.is_connected(_on_pause_requested):
			safe_hud.pause_requested.connect(_on_pause_requested)
		if not safe_hud.restart_requested.is_connected(_on_restart_requested):
			safe_hud.restart_requested.connect(_on_restart_requested)
		if not safe_hud.main_menu_requested.is_connected(_on_main_menu_requested):
			safe_hud.main_menu_requested.connect(_on_main_menu_requested)
		if screen_safe_adapter != null:
			safe_hud.apply_hud_safe_rect(screen_safe_adapter.get_hud_safe_rect())


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
	if _active_chart != null:
		start_chart_session(_active_chart)
	else:
		start_demo_session(_active_note_type_mode)


func _on_main_menu_requested() -> void:
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
		tree.change_scene_to_file(MAIN_MENU_SCENE_PATH)


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
