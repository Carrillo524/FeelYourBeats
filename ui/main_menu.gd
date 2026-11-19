class_name MainMenu
extends Control

const GAME_SESSION_SCENE_PATH: String = "res://ui/game_session.tscn"
const SONGS_DIR_PATH: String = "res://assets/songs"
const RECENT_TRACKS_CONFIG_PATH: String = "user://recent_tracks.cfg"
const MAX_RECENT_TRACKS: int = 12
const SUPPORTED_AUDIO_EXTENSIONS: PackedStringArray = ["mp3", "ogg", "wav"]

const MIN_TOUCH_BUTTON_HEIGHT_PX: float = 64.0
const PLAY_BUTTON_HEIGHT_PX: float = 82.0
const TITLE_FONT_SIZE: int = 56
const SUBTITLE_FONT_SIZE: int = 24
const SECTION_FONT_SIZE: int = 24
const BUTTON_FONT_SIZE: int = 26
const PLAY_BUTTON_FONT_SIZE: int = 36
const STATUS_FONT_SIZE: int = 26

const COLOR_BUTTON_SELECTED: Color = Color(0.28, 0.92, 1.0, 1.0)
const COLOR_BUTTON_IDLE: Color = Color(0.86, 0.92, 0.98, 1.0)
const COLOR_PLAY_BUTTON: Color = Color(0.32, 1.0, 0.88, 1.0)

@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var reactive_background: ReactiveBackground = null
@export var menu_bgm_player: MenuBgmPlayer = null
@export var ui_sfx_player: UiSfxPlayer = null
@export var audio_analyzer: AudioAnalyzer = null

var _chart_cache_repo: ChartCacheRepository = ChartCacheRepository.new()
var _recent_tracks_path: String = RECENT_TRACKS_CONFIG_PATH

var _safe_container: Control = null
var _root_vbox: VBoxContainer = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _browse_button: Button = null
var _selected_track_label: Label = null
var _track_scroll: ScrollContainer = null
var _track_list_vbox: VBoxContainer = null

var _diff_easy_button: Button = null
var _diff_normal_button: Button = null
var _diff_hard_button: Button = null
var _mode_tap_hold_button: Button = null
var _mode_tap_only_button: Button = null

var _bgm_label: Label = null
var _bgm_prev_button: Button = null
var _bgm_next_button: Button = null
var _bgm_mode_button: Button = null

var _status_label: Label = null
var _play_button: Button = null
var _file_dialog: FileDialog = null

var _track_entries: Array[Dictionary] = []
var _selected_track_index: int = 0
var _selected_difficulty: int = AutoChartGenerator.Difficulty.NORMAL
var _selected_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
var _is_launching: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resolve_scene_nodes()
	_ensure_ui_nodes()
	_connect_dependencies()
	_reload_track_list()
	_refresh_option_buttons()
	_refresh_bgm_controls()

	if screen_safe_adapter != null:
		apply_hud_safe_rect(screen_safe_adapter.get_hud_safe_rect())
	else:
		apply_hud_safe_rect(Rect2(64.8, 0.0, 950.4, 1920.0))


func apply_hud_safe_rect(p_hud_safe_rect: Rect2) -> void:
	_ensure_ui_nodes()
	_safe_container.position = p_hud_safe_rect.position
	_safe_container.size = p_hud_safe_rect.size

	var pad_x: float = 16.0
	var pad_y: float = 18.0
	var content_w: float = maxf(280.0, p_hud_safe_rect.size.x - (pad_x * 2.0))
	var content_h: float = maxf(480.0, p_hud_safe_rect.size.y - (pad_y * 2.0))
	_root_vbox.position = Vector2(pad_x, pad_y)
	_root_vbox.size = Vector2(content_w, content_h)


func select_difficulty(p_difficulty: int) -> void:
	_selected_difficulty = clampi(
		p_difficulty,
		AutoChartGenerator.Difficulty.EASY,
		AutoChartGenerator.Difficulty.HARD
	)
	_refresh_option_buttons()
	_rebuild_track_list_ui()


func select_note_type_mode(p_mode: int) -> void:
	_selected_note_type_mode = clampi(
		p_mode,
		AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD,
		AutoChartGenerator.NoteTypeMode.TAP_ONLY
	)
	_refresh_option_buttons()
	_rebuild_track_list_ui()


func select_track_by_index(p_index: int) -> void:
	if _track_entries.is_empty():
		_selected_track_index = 0
		return
	_selected_track_index = clampi(p_index, 0, _track_entries.size() - 1)
	_rebuild_track_list_ui()
	_refresh_selected_track_label()


func register_external_track(p_audio_path: String) -> void:
	var cleaned: String = p_audio_path.strip_edges()
	if cleaned.is_empty():
		return

	_save_recent_track(cleaned)
	_reload_track_list()

	var count: int = _track_entries.size()
	for i: int in range(count):
		var entry: Dictionary = _track_entries[i]
		if str(entry.get("audio_path", "")) == cleaned:
			select_track_by_index(i)
			return


func get_track_entries() -> Array[Dictionary]:
	return _track_entries


func get_selected_track() -> Dictionary:
	if _track_entries.is_empty():
		return {}
	return _track_entries[clampi(_selected_track_index, 0, _track_entries.size() - 1)]


func get_selected_difficulty() -> int:
	return _selected_difficulty


func get_selected_note_type_mode() -> int:
	return _selected_note_type_mode


func is_play_button_disabled() -> bool:
	return _play_button != null and _play_button.disabled


func get_status_text() -> String:
	return _status_label.text if _status_label != null else ""


func get_safe_container_rect() -> Rect2:
	if _safe_container == null:
		return Rect2()
	return Rect2(_safe_container.position, _safe_container.size)


func set_chart_cache_repository(p_repo: ChartCacheRepository) -> void:
	if p_repo != null:
		_chart_cache_repo = p_repo
		_rebuild_track_list_ui()


func prepare_session_launch_payload() -> Dictionary:
	var selected: Dictionary = get_selected_track()
	var is_demo: bool = selected.get("is_demo", true) as bool
	var audio_path: String = str(selected.get("audio_path", ""))
	var title: String = str(selected.get("title", "FeelYourBeats Demo 128 BPM"))

	var payload: Dictionary = {
		"is_demo": is_demo,
		"audio_path": audio_path,
		"title": title,
		"difficulty": _selected_difficulty,
		"note_type_mode": _selected_note_type_mode,
		"preloaded_chart": null,
		"preloaded_stream": null,
		"from_cache": false,
	}

	if is_demo or audio_path.is_empty() or audio_analyzer == null:
		return payload

	var stream: AudioStream = audio_analyzer.load_audio_stream(audio_path)
	if stream == null:
		payload["error"] = "No se pudo cargar el archivo de audio."
		return payload

	var cache_key: String = _chart_cache_repo.build_cache_key(
		audio_path,
		_selected_difficulty,
		_selected_note_type_mode
	)
	var cached_chart: ChartData = _chart_cache_repo.load_cached_chart(cache_key)
	if cached_chart != null:
		payload["preloaded_chart"] = cached_chart
		payload["preloaded_stream"] = stream
		payload["from_cache"] = true
		return payload

	var analysis: Dictionary = audio_analyzer.analyze_audio_stream(stream)
	var duration_sec: float = analysis.get("duration_sec", 0.0) as float
	if duration_sec <= 0.0:
		payload["error"] = "El audio no contiene muestras válidas."
		return payload

	var generator: AutoChartGenerator = AutoChartGenerator.new()
	var chart: ChartData = generator.generate_from_analysis(
		audio_path.get_file().get_basename(),
		title,
		audio_path,
		analysis,
		_selected_difficulty,
		_selected_note_type_mode
	)
	var validation: Dictionary = chart.validate()
	if not (validation.get("valid", false) as bool):
		payload["error"] = "No se pudo generar un chart válido."
		return payload

	_chart_cache_repo.save_cached_chart(cache_key, chart)
	payload["preloaded_chart"] = chart
	payload["preloaded_stream"] = stream
	payload["from_cache"] = false
	return payload


func _on_play_button_pressed() -> void:
	if _is_launching:
		return
	_is_launching = true
	if _play_button != null:
		_play_button.disabled = true

	if menu_bgm_player != null:
		menu_bgm_player.stop_bgm()
	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(false)
	if ui_sfx_player != null:
		ui_sfx_player.play_cassette_insert()

	var selected: Dictionary = get_selected_track()
	var is_demo: bool = selected.get("is_demo", true) as bool
	var audio_path: String = str(selected.get("audio_path", ""))
	var needs_analysis_banner: bool = false
	if not is_demo and not audio_path.is_empty():
		var key: String = _chart_cache_repo.build_cache_key(
			audio_path,
			_selected_difficulty,
			_selected_note_type_mode
		)
		needs_analysis_banner = not _chart_cache_repo.has_cached_file(key)

	if _status_label != null:
		_status_label.text = "Analizando pista..." if needs_analysis_banner else "Iniciando sesión..."

	var tree: SceneTree = get_tree()
	if tree != null:
		await tree.process_frame

	var payload: Dictionary = prepare_session_launch_payload()
	if payload.has("error"):
		if _status_label != null:
			_status_label.text = str(payload["error"])
		_is_launching = false
		if _play_button != null:
			_play_button.disabled = false
		return

	if ui_sfx_player != null and tree != null:
		var delay_sec: float = ui_sfx_player.get_cassette_transition_delay_sec()
		if delay_sec > 0.0:
			await tree.create_timer(delay_sec).timeout

	GameSession.set_pending_session(payload)
	if tree != null and ResourceLoader.exists(GAME_SESSION_SCENE_PATH):
		tree.change_scene_to_file(GAME_SESSION_SCENE_PATH)


func _on_browse_button_pressed() -> void:
	if _file_dialog == null:
		return
	_file_dialog.popup_centered_ratio(0.85)


func _on_file_selected(p_path: String) -> void:
	register_external_track(p_path)
	if _status_label != null:
		_status_label.text = "Pista lista: %s" % p_path.get_file().get_basename()


func _on_bgm_prev_pressed() -> void:
	if menu_bgm_player != null:
		menu_bgm_player.prev_track()
	_refresh_bgm_controls()


func _on_bgm_next_pressed() -> void:
	if menu_bgm_player != null:
		menu_bgm_player.next_track()
	_refresh_bgm_controls()


func _on_bgm_mode_pressed() -> void:
	if menu_bgm_player != null:
		menu_bgm_player.set_auto_rotate(not menu_bgm_player.is_auto_rotate)
	_refresh_bgm_controls()


func _on_bgm_track_changed(_p_index: int, _p_name: String) -> void:
	_refresh_bgm_controls()


func _on_safe_play_rect_changed(_p_play_rect: Rect2, p_hud_safe_rect: Rect2) -> void:
	apply_hud_safe_rect(p_hud_safe_rect)


func _resolve_scene_nodes() -> void:
	if screen_safe_adapter == null:
		screen_safe_adapter = get_node_or_null("ScreenSafeAdapter") as ScreenSafeAdapter
	if reactive_background == null:
		reactive_background = get_node_or_null("ReactiveBackground") as ReactiveBackground
	if menu_bgm_player == null:
		menu_bgm_player = get_node_or_null("MenuBgmPlayer") as MenuBgmPlayer
	if ui_sfx_player == null:
		ui_sfx_player = get_node_or_null("UiSfxPlayer") as UiSfxPlayer
	if audio_analyzer == null:
		audio_analyzer = get_node_or_null("AudioAnalyzer") as AudioAnalyzer

	if screen_safe_adapter == null:
		screen_safe_adapter = ScreenSafeAdapter.new()
		screen_safe_adapter.name = "ScreenSafeAdapter"
		add_child(screen_safe_adapter)

	if reactive_background == null:
		reactive_background = ReactiveBackground.new()
		reactive_background.name = "ReactiveBackground"
		add_child(reactive_background)
		move_child(reactive_background, 0)

	if menu_bgm_player == null:
		menu_bgm_player = MenuBgmPlayer.new()
		menu_bgm_player.name = "MenuBgmPlayer"
		add_child(menu_bgm_player)

	if ui_sfx_player == null:
		ui_sfx_player = UiSfxPlayer.new()
		ui_sfx_player.name = "UiSfxPlayer"
		add_child(ui_sfx_player)

	if audio_analyzer == null:
		audio_analyzer = AudioAnalyzer.new()
		audio_analyzer.name = "AudioAnalyzer"
		add_child(audio_analyzer)


func _connect_dependencies() -> void:
	if screen_safe_adapter != null:
		if not screen_safe_adapter.safe_play_rect_changed.is_connected(_on_safe_play_rect_changed):
			screen_safe_adapter.safe_play_rect_changed.connect(_on_safe_play_rect_changed)

	if reactive_background != null and audio_analyzer != null:
		reactive_background.audio_analyzer = audio_analyzer
		reactive_background.connect_dependencies()
		if menu_bgm_player != null and menu_bgm_player.get_track_count() > 0:
			audio_analyzer.set_live_monitoring(true)

	if menu_bgm_player != null:
		if not menu_bgm_player.track_changed.is_connected(_on_bgm_track_changed):
			menu_bgm_player.track_changed.connect(_on_bgm_track_changed)

	if ui_sfx_player != null and _safe_container != null:
		var excluded: Array[BaseButton] = []
		if _play_button != null:
			excluded.append(_play_button)
		ui_sfx_player.bind_buttons_in_tree(_safe_container, excluded)


func _reload_track_list() -> void:
	_track_entries.clear()
	var seen_paths: Dictionary = {}

	_track_entries.append({
		"is_demo": true,
		"song_key": GameSession.DEMO_SONG_KEY,
		"audio_path": "",
		"title": "Demo Integrada (128 BPM)",
		"source_tag": "DEMO",
	})

	var bundled_paths: PackedStringArray = _scan_bundled_songs()
	for i: int in range(bundled_paths.size()):
		var song_path: String = bundled_paths[i]
		if not seen_paths.has(song_path):
			seen_paths[song_path] = true
			_track_entries.append({
				"is_demo": false,
				"song_key": song_path,
				"audio_path": song_path,
				"title": song_path.get_file().get_basename(),
				"source_tag": "LOCAL",
			})

	var recent_paths: PackedStringArray = _load_recent_tracks()
	for j: int in range(recent_paths.size()):
		var recent_path: String = recent_paths[j]
		if not seen_paths.has(recent_path) and FileAccess.file_exists(recent_path):
			seen_paths[recent_path] = true
			_track_entries.append({
				"is_demo": false,
				"song_key": recent_path,
				"audio_path": recent_path,
				"title": recent_path.get_file().get_basename(),
				"source_tag": "RECIENTE",
			})

	if _selected_track_index >= _track_entries.size():
		_selected_track_index = 0

	_rebuild_track_list_ui()
	_refresh_selected_track_label()


func _scan_bundled_songs() -> PackedStringArray:
	var found: Array[String] = []
	var seen: Dictionary = {}
	var dir: DirAccess = DirAccess.open(SONGS_DIR_PATH)
	if dir != null:
		dir.list_dir_begin()
		var entry: String = dir.get_next()
		while not entry.is_empty():
			if not dir.current_is_dir() and not entry.begins_with("."):
				var cleaned: String = entry
				if cleaned.ends_with(".import"):
					cleaned = cleaned.trim_suffix(".import")
				elif cleaned.ends_with(".remap"):
					cleaned = cleaned.trim_suffix(".remap")
				var ext: String = cleaned.get_extension().to_lower()
				if SUPPORTED_AUDIO_EXTENSIONS.has(ext):
					var full_path: String = "%s/%s" % [SONGS_DIR_PATH, cleaned]
					if not seen.has(full_path):
						seen[full_path] = true
						found.append(full_path)
			entry = dir.get_next()
		dir.list_dir_end()

	found.sort()
	return PackedStringArray(found)


func _load_recent_tracks() -> PackedStringArray:
	var result: Array[String] = []
	if not FileAccess.file_exists(_recent_tracks_path):
		return PackedStringArray()

	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(_recent_tracks_path) != OK:
		return PackedStringArray()

	var raw_list: Variant = cfg.get_value("recent", "paths", PackedStringArray())
	if raw_list is PackedStringArray:
		var packed: PackedStringArray = raw_list as PackedStringArray
		for i: int in range(packed.size()):
			var p: String = packed[i].strip_edges()
			if not p.is_empty():
				result.append(p)
	elif raw_list is Array:
		var arr: Array = raw_list as Array
		for i: int in range(arr.size()):
			var p: String = str(arr[i]).strip_edges()
			if not p.is_empty():
				result.append(p)

	return PackedStringArray(result)


func _save_recent_track(p_audio_path: String) -> void:
	var existing: PackedStringArray = _load_recent_tracks()
	var updated: Array[String] = [p_audio_path]
	for i: int in range(existing.size()):
		var item: String = existing[i]
		if item != p_audio_path and updated.size() < MAX_RECENT_TRACKS:
			updated.append(item)

	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("recent", "paths", PackedStringArray(updated))
	cfg.save(_recent_tracks_path)


func _rebuild_track_list_ui() -> void:
	if _track_list_vbox == null:
		return

	var old_children: Array[Node] = _track_list_vbox.get_children()
	for i: int in range(old_children.size()):
		old_children[i].queue_free()

	var entry_count: int = _track_entries.size()
	for idx: int in range(entry_count):
		var entry: Dictionary = _track_entries[idx]
		var song_key: String = str(entry.get("song_key", ""))
		var title: String = str(entry.get("title", "Pista"))
		var tag: String = str(entry.get("source_tag", ""))
		var best_rank: String = _chart_cache_repo.load_best_rank_for_song(
			song_key,
			_selected_difficulty,
			_selected_note_type_mode
		)
		var rank_badge: String = "[%s]" % best_rank if not best_rank.is_empty() else "[--]"
		var prefix: String = "▶ " if idx == _selected_track_index else "   "

		var row_btn: Button = Button.new()
		row_btn.name = "TrackButton_%d" % idx
		row_btn.text = "%s%s  (%s)  %s" % [prefix, title, tag, rank_badge]
		row_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row_btn.clip_text = true
		row_btn.custom_minimum_size = Vector2(0.0, 68.0)
		row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
		row_btn.modulate = COLOR_BUTTON_SELECTED if idx == _selected_track_index else COLOR_BUTTON_IDLE
		row_btn.pressed.connect(select_track_by_index.bind(idx))
		if ui_sfx_player != null:
			ui_sfx_player.bind_button(row_btn)
		_track_list_vbox.add_child(row_btn)


func _refresh_selected_track_label() -> void:
	if _selected_track_label == null:
		return
	var selected: Dictionary = get_selected_track()
	var title: String = str(selected.get("title", "Sin selección"))
	_selected_track_label.text = "SELECCIONADA: %s" % title


func _refresh_option_buttons() -> void:
	if _diff_easy_button != null:
		_diff_easy_button.modulate = (
			COLOR_BUTTON_SELECTED
			if _selected_difficulty == AutoChartGenerator.Difficulty.EASY
			else COLOR_BUTTON_IDLE
		)
	if _diff_normal_button != null:
		_diff_normal_button.modulate = (
			COLOR_BUTTON_SELECTED
			if _selected_difficulty == AutoChartGenerator.Difficulty.NORMAL
			else COLOR_BUTTON_IDLE
		)
	if _diff_hard_button != null:
		_diff_hard_button.modulate = (
			COLOR_BUTTON_SELECTED
			if _selected_difficulty == AutoChartGenerator.Difficulty.HARD
			else COLOR_BUTTON_IDLE
		)
	if _mode_tap_hold_button != null:
		_mode_tap_hold_button.modulate = (
			COLOR_BUTTON_SELECTED
			if _selected_note_type_mode == AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
			else COLOR_BUTTON_IDLE
		)
	if _mode_tap_only_button != null:
		_mode_tap_only_button.modulate = (
			COLOR_BUTTON_SELECTED
			if _selected_note_type_mode == AutoChartGenerator.NoteTypeMode.TAP_ONLY
			else COLOR_BUTTON_IDLE
		)


func _refresh_bgm_controls() -> void:
	var track_name: String = menu_bgm_player.get_current_track_name() if menu_bgm_player != null else MenuBgmPlayer.EMPTY_TRACK_LABEL
	var auto_rotate: bool = menu_bgm_player.is_auto_rotate if menu_bgm_player != null else true
	if _bgm_label != null:
		_bgm_label.text = "BGM: %s" % track_name
	if _bgm_mode_button != null:
		_bgm_mode_button.text = "AUTO" if auto_rotate else "FIJA"


func _ensure_ui_nodes() -> void:
	if _safe_container != null:
		return

	_safe_container = Control.new()
	_safe_container.name = "SafeAreaContainer"
	_safe_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_container)

	_root_vbox = VBoxContainer.new()
	_root_vbox.name = "MenuRootVBox"
	_root_vbox.add_theme_constant_override("separation", 18)
	_safe_container.add_child(_root_vbox)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "FEEL YOUR BEATS"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_title_label.modulate = Color(0.45, 0.96, 1.0, 1.0)
	_root_vbox.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "SubtitleLabel"
	_subtitle_label.text = "Juega con cualquier canción de tu dispositivo"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	_subtitle_label.modulate = Color(0.84, 0.90, 1.0, 0.90)
	_root_vbox.add_child(_subtitle_label)

	_browse_button = Button.new()
	_browse_button.name = "BrowseAudioButton"
	_browse_button.text = "ELEGIR CANCIÓN DEL DISPOSITIVO"
	_browse_button.custom_minimum_size = Vector2(0.0, 72.0)
	_browse_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_browse_button.pressed.connect(_on_browse_button_pressed)
	_root_vbox.add_child(_browse_button)

	_selected_track_label = Label.new()
	_selected_track_label.name = "SelectedTrackLabel"
	_selected_track_label.text = "SELECCIONADA: Demo Integrada (128 BPM)"
	_selected_track_label.clip_text = true
	_selected_track_label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	_selected_track_label.modulate = Color(0.96, 0.98, 1.0, 1.0)
	_root_vbox.add_child(_selected_track_label)

	_track_scroll = ScrollContainer.new()
	_track_scroll.name = "TrackListScroll"
	_track_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_track_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_vbox.add_child(_track_scroll)

	_track_list_vbox = VBoxContainer.new()
	_track_list_vbox.name = "TrackListVBox"
	_track_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_track_list_vbox.add_theme_constant_override("separation", 10)
	_track_scroll.add_child(_track_list_vbox)

	var diff_header: Label = Label.new()
	diff_header.name = "DifficultyHeader"
	diff_header.text = "DIFICULTAD"
	diff_header.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	_root_vbox.add_child(diff_header)

	var diff_row: HBoxContainer = HBoxContainer.new()
	diff_row.name = "DifficultyRow"
	diff_row.add_theme_constant_override("separation", 12)
	_root_vbox.add_child(diff_row)

	_diff_easy_button = _create_option_button("DiffEasyButton", "FÁCIL")
	_diff_easy_button.pressed.connect(select_difficulty.bind(AutoChartGenerator.Difficulty.EASY))
	diff_row.add_child(_diff_easy_button)

	_diff_normal_button = _create_option_button("DiffNormalButton", "NORMAL")
	_diff_normal_button.pressed.connect(select_difficulty.bind(AutoChartGenerator.Difficulty.NORMAL))
	diff_row.add_child(_diff_normal_button)

	_diff_hard_button = _create_option_button("DiffHardButton", "DIFÍCIL")
	_diff_hard_button.pressed.connect(select_difficulty.bind(AutoChartGenerator.Difficulty.HARD))
	diff_row.add_child(_diff_hard_button)

	var mode_header: Label = Label.new()
	mode_header.name = "NoteModeHeader"
	mode_header.text = "MODO DE NOTAS"
	mode_header.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	_root_vbox.add_child(mode_header)

	var mode_row: HBoxContainer = HBoxContainer.new()
	mode_row.name = "NoteModeRow"
	mode_row.add_theme_constant_override("separation", 12)
	_root_vbox.add_child(mode_row)

	_mode_tap_hold_button = _create_option_button("ModeTapHoldButton", "TAP + HOLD")
	_mode_tap_hold_button.pressed.connect(select_note_type_mode.bind(AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD))
	mode_row.add_child(_mode_tap_hold_button)

	_mode_tap_only_button = _create_option_button("ModeTapOnlyButton", "SOLO TAP")
	_mode_tap_only_button.pressed.connect(select_note_type_mode.bind(AutoChartGenerator.NoteTypeMode.TAP_ONLY))
	mode_row.add_child(_mode_tap_only_button)

	var bgm_row: HBoxContainer = HBoxContainer.new()
	bgm_row.name = "BgmControlRow"
	bgm_row.add_theme_constant_override("separation", 10)
	_root_vbox.add_child(bgm_row)

	_bgm_label = Label.new()
	_bgm_label.name = "BgmTrackLabel"
	_bgm_label.text = "BGM: Sin BGM"
	_bgm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bgm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bgm_label.clip_text = true
	_bgm_label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	bgm_row.add_child(_bgm_label)

	_bgm_prev_button = Button.new()
	_bgm_prev_button.name = "BgmPrevButton"
	_bgm_prev_button.text = "<"
	_bgm_prev_button.custom_minimum_size = Vector2(72.0, MIN_TOUCH_BUTTON_HEIGHT_PX)
	_bgm_prev_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_bgm_prev_button.pressed.connect(_on_bgm_prev_pressed)
	bgm_row.add_child(_bgm_prev_button)

	_bgm_next_button = Button.new()
	_bgm_next_button.name = "BgmNextButton"
	_bgm_next_button.text = ">"
	_bgm_next_button.custom_minimum_size = Vector2(72.0, MIN_TOUCH_BUTTON_HEIGHT_PX)
	_bgm_next_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_bgm_next_button.pressed.connect(_on_bgm_next_pressed)
	bgm_row.add_child(_bgm_next_button)

	_bgm_mode_button = Button.new()
	_bgm_mode_button.name = "BgmModeButton"
	_bgm_mode_button.text = "AUTO"
	_bgm_mode_button.custom_minimum_size = Vector2(128.0, MIN_TOUCH_BUTTON_HEIGHT_PX)
	_bgm_mode_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	_bgm_mode_button.pressed.connect(_on_bgm_mode_pressed)
	bgm_row.add_child(_bgm_mode_button)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", STATUS_FONT_SIZE)
	_status_label.modulate = Color(1.0, 0.90, 0.42, 1.0)
	_root_vbox.add_child(_status_label)

	_play_button = Button.new()
	_play_button.name = "PlayButton"
	_play_button.text = "JUGAR"
	_play_button.custom_minimum_size = Vector2(0.0, PLAY_BUTTON_HEIGHT_PX)
	_play_button.add_theme_font_size_override("font_size", PLAY_BUTTON_FONT_SIZE)
	_play_button.modulate = COLOR_PLAY_BUTTON
	_play_button.pressed.connect(_on_play_button_pressed)
	_root_vbox.add_child(_play_button)

	_file_dialog = FileDialog.new()
	_file_dialog.name = "AudioFileDialog"
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	_file_dialog.filters = PackedStringArray(["*.mp3, *.ogg, *.wav ; Pistas de Audio"])
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


func _create_option_button(p_name: String, p_text: String) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.text = p_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, 68.0)
	btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	return btn
