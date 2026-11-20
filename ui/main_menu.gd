class_name MainMenu
extends Control

enum MenuTab {
	SONGS = 0,
	IMPORT = 1,
	SETTINGS = 2,
}

const GAME_SESSION_SCENE_PATH: String = "res://ui/game_session.tscn"
const SONGS_DIR_PATH: String = "res://assets/songs"
const RECENT_TRACKS_CONFIG_PATH: String = "user://recent_tracks.cfg"
const MAX_RECENT_TRACKS: int = 16
const SUPPORTED_AUDIO_EXTENSIONS: PackedStringArray = ["mp3", "ogg", "wav"]
const ANDROID_PERM_READ_MEDIA_AUDIO: String = "android.permission.READ_MEDIA_AUDIO"
const ANDROID_PERM_READ_EXTERNAL_STORAGE: String = "android.permission.READ_EXTERNAL_STORAGE"
const ANDROID_PERMISSION_DENIED_MESSAGE: String = "Permiso de audio denegado. Habilita el acceso a música y audio en los Ajustes de Android para importar canciones."

const MIN_TOUCH_BUTTON_HEIGHT_PX: float = 68.0
const SONG_ROW_HEIGHT_PX: float = 252.0
const DIVIDER_HEIGHT_PX: float = 2.0
const ROW_BOTTOM_BORDER_PX: int = 3
const ROW_INNER_MARGIN_X: int = 28
const ROW_TITLE_RANK_GAP_PX: int = 24
const MODAL_OPTION_HEIGHT_PX: float = 80.0
const PLAY_BUTTON_HEIGHT_PX: float = 94.0
const TRANSITION_FADE_DURATION_SEC: float = 2.5
const TRANSITION_FADE_Z_INDEX: int = 100
const USEC_TO_SEC: float = 0.000001

const TITLE_HERO_FONT_SIZE: int = 104
const TITLE_SUBTITLE_FONT_SIZE: int = 32
const TITLE_PLAY_FONT_SIZE: int = 82
const HEADER_TITLE_FONT_SIZE: int = 48
const TAB_FONT_SIZE: int = 34
const SECTION_FONT_SIZE: int = 34
const SETTINGS_LABEL_FONT_SIZE: int = 36
const SONG_ROW_FONT_SIZE: int = 38
const SONG_BADGE_FONT_SIZE: int = 36
const SONG_RANK_FONT_SIZE: int = 58
const SONG_DIFF_FONT_SIZE: int = 30
const MODAL_TITLE_FONT_SIZE: int = 42
const MODAL_RECORD_FONT_SIZE: int = 30
const MODAL_RANK_FONT_SIZE: int = 46
const MODAL_OPTION_FONT_SIZE: int = 36
const PRIMARY_BUTTON_FONT_SIZE: int = 42
const STATUS_FONT_SIZE: int = 32
const MARQUEE_SPEED_PX_PER_SEC: float = 60.0
const MARQUEE_EDGE_PAD_PX: float = 16.0
const MARQUEE_INITIAL_PAUSE_SEC: float = 1.2

static var open_directly_to_selector: bool = false

const COLOR_TEXT_ACTIVE: Color = Color(0.98, 1.0, 1.0, 1.0)
const COLOR_TEXT_INACTIVE: Color = Color(0.76, 0.84, 0.94, 0.90)
const COLOR_TEXT_ACCENT: Color = Color(0.38, 0.96, 1.0, 1.0)
const COLOR_TEXT_GOLD: Color = Color(1.0, 0.88, 0.34, 1.0)
const COLOR_SHEET_BG: Color = Color(0.84, 0.92, 1.0, 0.12)
const COLOR_SHEET_BORDER: Color = Color(1.0, 1.0, 1.0, 0.26)
const COLOR_ROW_REST_BG: Color = Color(1.0, 1.0, 1.0, 0.0)
const COLOR_ROW_HOVER_BG: Color = Color(1.0, 1.0, 1.0, 0.14)
const COLOR_ROW_BOTTOM_BORDER: Color = Color(1.0, 1.0, 1.0, 0.28)
const COLOR_WHITE_DIVIDER: Color = Color(1.0, 1.0, 1.0, 0.24)

@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var reactive_background: ReactiveBackground = null
@export var menu_bgm_player: MenuBgmPlayer = null
@export var ui_sfx_player: UiSfxPlayer = null
@export var audio_analyzer: AudioAnalyzer = null

var _chart_cache_repo: ChartCacheRepository = ChartCacheRepository.new()
var _font_registry: UiFontRegistry = null
var _recent_tracks_path: String = RECENT_TRACKS_CONFIG_PATH

var _safe_container: Control = null

# Screen 1: Title Screen
var _title_screen_container: Control = null
var _hero_title_label: Label = null
var _hero_subtitle_label: Label = null
var _hero_play_button: Button = null

# Screen 2: Tabbed Browser
var _browser_screen_container: VBoxContainer = null
var _browser_header_label: Label = null
var _tab_songs_button: Button = null
var _tab_import_button: Button = null
var _tab_settings_button: Button = null
var _content_sheet_panel: PanelContainer = null

var _songs_tab_container: Control = null
var _songs_list_vbox: VBoxContainer = null

var _import_tab_container: Control = null
var _browse_button: Button = null
var _import_status_label: Label = null
var _import_list_vbox: VBoxContainer = null

var _settings_tab_container: Control = null
var _bgm_toggle_button: Button = null
var _bgm_track_label: Label = null
var _bgm_prev_button: Button = null
var _bgm_next_button: Button = null
var _bgm_mode_button: Button = null

# Floating Song Setup Modal
var _song_modal_backdrop: ColorRect = null
var _song_modal_panel: Panel = null
var _modal_vbox: VBoxContainer = null
var _modal_song_title_label: Label = null
var _modal_close_button: Button = null
var _modal_record_row: HBoxContainer = null
var _modal_record_label: Label = null
var _modal_record_rank_label: Label = null
var _modal_record_detail_label: Label = null
var _diff_easy_button: Button = null
var _diff_normal_button: Button = null
var _diff_hard_button: Button = null
var _mode_tap_hold_button: Button = null
var _mode_tap_only_button: Button = null
var _speed_1x_button: Button = null
var _speed_2x_button: Button = null
var _speed_3x_button: Button = null
var _speed_4x_button: Button = null
var _status_label: Label = null
var _play_button: Button = null

# Floating Exit Confirmation Modal
var _exit_confirm_backdrop: ColorRect = null
var _exit_confirm_panel: PanelContainer = null
var _exit_confirm_title: Label = null
var _exit_cancel_button: Button = null
var _exit_confirm_button: Button = null

var _file_dialog: FileDialog = null
var _transition_fade_rect: ColorRect = null
var _transition_tween: Tween = null

var _style_option_active: StyleBoxFlat = null
var _style_option_inactive: StyleBoxFlat = null
var _style_content_sheet: StyleBoxFlat = null
var _style_song_row_divider_normal: StyleBoxFlat = null
var _style_song_row_divider_hover: StyleBoxFlat = null
var _style_song_row_last_normal: StyleBoxFlat = null
var _style_song_row_last_hover: StyleBoxFlat = null
var _style_modal_panel: StyleBoxFlat = null
var _style_play_cta: StyleBoxFlat = null
var _style_exit_danger: StyleBoxFlat = null
var _style_floating_play: StyleBoxEmpty = null

var _song_entries: Array[Dictionary] = []
var _imported_entries: Array[Dictionary] = []
var _songs_marquee_items: Array[Dictionary] = []
var _imported_marquee_items: Array[Dictionary] = []
var _selected_entry: Dictionary = {}
var _active_tab: int = MenuTab.SONGS
var _selected_difficulty: int = AutoChartGenerator.Difficulty.NORMAL
var _selected_note_type_mode: int = AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD
var _selected_speed_multiplier: int = LaneField.MIN_SPEED_MULTIPLIER
var _is_launching: bool = false
var _pending_import_after_permission: bool = false

var _pulse_phase: float = 0.0
var _title_bass_boost: float = 0.0
var _live_menu_bass: float = 0.0
var _last_launch_sequence: Array[String] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.set_auto_accept_quit(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_theme_styles()
	_resolve_scene_nodes()
	_ensure_ui_nodes()
	_apply_external_fonts()
	_connect_dependencies()
	_reload_all_track_lists()
	_refresh_tab_visuals()
	_refresh_modal_option_styles()
	_refresh_bgm_controls()
	_sync_live_audio_monitoring()
	if open_directly_to_selector:
		open_directly_to_selector = false
		show_browser_screen(MenuTab.SONGS)
	else:
		show_title_screen()

	if screen_safe_adapter != null:
		apply_hud_safe_rect(screen_safe_adapter.get_hud_safe_rect())
	else:
		apply_hud_safe_rect(Rect2(64.8, 0.0, 950.4, 1920.0))


func _process(p_delta: float) -> void:
	var dt: float = maxf(0.0, p_delta)
	_pulse_phase += dt * 2.8
	_title_bass_boost = maxf(0.0, _title_bass_boost - (4.8 * dt))
	_live_menu_bass = maxf(0.0, _live_menu_bass - (3.8 * dt))

	var bgm_active: bool = menu_bgm_player != null and menu_bgm_player.is_bgm_enabled and menu_bgm_player.get_track_count() > 0
	var combined_energy: float = clampf(maxf(_title_bass_boost, _live_menu_bass), 0.0, 1.0) if bgm_active else 0.0

	if _title_screen_container != null and _title_screen_container.visible:
		var ambient_wave: float = sin(_pulse_phase) * 0.5 + 0.5
		if _hero_title_label != null:
			_hero_title_label.pivot_offset = _hero_title_label.size * 0.5
			var title_scale: float = clampf(1.0 + (combined_energy * 0.14) + (ambient_wave * 0.018), 1.0, 1.14)
			_hero_title_label.scale = Vector2(title_scale, title_scale)
			var title_glow: float = clampf(0.35 + (combined_energy * 0.65), 0.35, 1.0)
			_hero_title_label.modulate = Color(
				lerpf(0.55, 1.0, title_glow),
				lerpf(0.95, 1.0, title_glow),
				1.0,
				1.0
			)

		if _hero_play_button != null:
			_hero_play_button.pivot_offset = _hero_play_button.size * 0.5
			var btn_scale: float = clampf(1.0 + (ambient_wave * 0.045) + (combined_energy * 0.12), 1.0, 1.14)
			_hero_play_button.scale = Vector2(btn_scale, btn_scale)
			var glow_mix: float = clampf((ambient_wave * 0.35) + (combined_energy * 0.65), 0.0, 1.0)
			_hero_play_button.modulate = Color(
				lerpf(0.45, 1.0, glow_mix),
				lerpf(0.94, 1.0, glow_mix),
				1.0,
				lerpf(0.84, 1.0, glow_mix)
			)

	if _browser_screen_container != null and _browser_screen_container.visible:
		if _active_tab == MenuTab.SONGS:
			_step_marquee_items(_songs_marquee_items, dt)
		elif _active_tab == MenuTab.IMPORT:
			_step_marquee_items(_imported_marquee_items, dt)


func _exit_tree() -> void:
	if _transition_tween != null:
		_transition_tween.kill()
		_transition_tween = null


func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back_request()


func _unhandled_input(p_event: InputEvent) -> void:
	if p_event != null and p_event.is_action_pressed(&"ui_cancel"):
		var vp: Viewport = get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		handle_back_request()


func handle_back_request() -> void:
	if _is_launching:
		return
	if is_exit_confirm_modal_open():
		close_exit_confirm_modal()
		return
	if _file_dialog != null and _file_dialog.visible:
		_file_dialog.hide()
		return
	if is_song_modal_open():
		close_song_setup_modal()
		return
	open_exit_confirm_modal()


func apply_hud_safe_rect(p_hud_safe_rect: Rect2) -> void:
	_ensure_ui_nodes()
	_safe_container.position = p_hud_safe_rect.position
	_safe_container.size = p_hud_safe_rect.size

	var safe_w: float = maxf(320.0, p_hud_safe_rect.size.x)
	var safe_h: float = maxf(480.0, p_hud_safe_rect.size.y)

	_title_screen_container.position = Vector2.ZERO
	_title_screen_container.size = Vector2(safe_w, safe_h)

	var title_w: float = maxf(240.0, safe_w - 24.0)
	_hero_title_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hero_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hero_title_label.size = Vector2(title_w, 120.0)
	_hero_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var line_count: int = maxi(1, _hero_title_label.get_line_count())
	var line_h: float = float(maxi(TITLE_HERO_FONT_SIZE, _hero_title_label.get_line_height()))
	var computed_title_h: float = (float(line_count) * line_h) + 20.0
	_hero_title_label.size = Vector2(title_w, computed_title_h)
	_hero_title_label.position = Vector2(12.0, safe_h * 0.22)
	_hero_title_label.pivot_offset = _hero_title_label.size * 0.5

	_hero_subtitle_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hero_subtitle_label.size = Vector2(maxf(220.0, safe_w - 48.0), 56.0)
	_hero_subtitle_label.position = Vector2(
		24.0,
		_hero_title_label.position.y + _hero_title_label.size.y + 16.0
	)

	var hero_btn_w: float = minf(560.0, safe_w - 48.0)
	var hero_btn_h: float = 128.0
	_hero_play_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hero_play_button.size = Vector2(hero_btn_w, hero_btn_h)
	_hero_play_button.position = Vector2((safe_w - hero_btn_w) * 0.5, safe_h * 0.62)
	_hero_play_button.pivot_offset = _hero_play_button.size * 0.5

	var pad_x: float = 16.0
	var pad_y: float = 18.0
	_browser_screen_container.position = Vector2(pad_x, pad_y)
	_browser_screen_container.size = Vector2(
		maxf(280.0, safe_w - (pad_x * 2.0)),
		maxf(440.0, safe_h - (pad_y * 2.0))
	)

	_song_modal_backdrop.position = Vector2.ZERO
	_song_modal_backdrop.size = Vector2(safe_w, safe_h)

	var modal_w: float = minf(900.0, safe_w - 24.0)
	var modal_h: float = minf(1140.0, safe_h - 48.0)
	_song_modal_panel.size = Vector2(modal_w, modal_h)
	_song_modal_panel.position = Vector2((safe_w - modal_w) * 0.5, (safe_h - modal_h) * 0.5)

	_modal_vbox.position = Vector2(26.0, 24.0)
	_modal_vbox.size = Vector2(maxf(240.0, modal_w - 52.0), maxf(400.0, modal_h - 48.0))

	if _exit_confirm_backdrop != null:
		_exit_confirm_backdrop.position = Vector2.ZERO
		_exit_confirm_backdrop.size = Vector2(safe_w, safe_h)

	_layout_exit_confirm_panel(safe_w, safe_h)


func _layout_exit_confirm_panel(p_safe_w: float, p_safe_h: float) -> void:
	if _exit_confirm_panel == null:
		return
	var safe_w: float = maxf(320.0, p_safe_w)
	var safe_h: float = maxf(480.0, p_safe_h)
	var target_w: float = minf(860.0, safe_w - 48.0)
	var inner_w: float = maxf(200.0, target_w - 78.0)
	if _exit_confirm_title != null:
		_exit_confirm_title.autowrap_mode = TextServer.AUTOWRAP_OFF
		_exit_confirm_title.custom_minimum_size = Vector2(inner_w, 0.0)
		_exit_confirm_title.size = Vector2(inner_w, 56.0)
		_exit_confirm_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var lines: int = maxi(1, _exit_confirm_title.get_line_count())
		var line_h: float = float(maxi(42, _exit_confirm_title.get_line_height()))
		var title_h: float = (float(lines) * line_h) + 8.0
		_exit_confirm_title.custom_minimum_size = Vector2(inner_w, title_h)
		_exit_confirm_title.size = Vector2(inner_w, title_h)
	_exit_confirm_panel.custom_minimum_size = Vector2(target_w, 0.0)
	var min_size: Vector2 = _exit_confirm_panel.get_combined_minimum_size()
	var panel_w: float = maxf(target_w, min_size.x)
	var panel_h: float = minf(safe_h - 64.0, maxf(min_size.y, 240.0))
	_exit_confirm_panel.size = Vector2(panel_w, panel_h)
	_exit_confirm_panel.position = Vector2((safe_w - panel_w) * 0.5, (safe_h - panel_h) * 0.5)


func show_title_screen() -> void:
	_ensure_ui_nodes()
	_title_screen_container.visible = true
	_browser_screen_container.visible = false
	_song_modal_backdrop.visible = false
	if _exit_confirm_backdrop != null:
		_exit_confirm_backdrop.visible = false


func show_browser_screen(p_tab: int = MenuTab.SONGS) -> void:
	_ensure_ui_nodes()
	_title_screen_container.visible = false
	_browser_screen_container.visible = true
	_song_modal_backdrop.visible = false
	if _exit_confirm_backdrop != null:
		_exit_confirm_backdrop.visible = false
	select_tab(p_tab)


func select_tab(p_tab: int) -> void:
	_active_tab = clampi(p_tab, MenuTab.SONGS, MenuTab.SETTINGS)
	if _active_tab == MenuTab.SONGS:
		_reset_marquee_items(_songs_marquee_items)
	elif _active_tab == MenuTab.IMPORT:
		_reset_marquee_items(_imported_marquee_items)
	_refresh_tab_visuals()


func get_active_tab() -> int:
	return _active_tab


func is_title_screen_visible() -> bool:
	return _title_screen_container != null and _title_screen_container.visible


func is_browser_screen_visible() -> bool:
	return _browser_screen_container != null and _browser_screen_container.visible


func is_song_modal_open() -> bool:
	return _song_modal_backdrop != null and _song_modal_backdrop.visible


func is_exit_confirm_modal_open() -> bool:
	return _exit_confirm_backdrop != null and _exit_confirm_backdrop.visible


func open_exit_confirm_modal() -> void:
	_ensure_ui_nodes()
	if _is_launching:
		return
	if _exit_confirm_backdrop != null:
		_exit_confirm_backdrop.visible = true
		if _safe_container != null:
			_layout_exit_confirm_panel(_safe_container.size.x, _safe_container.size.y)


func close_exit_confirm_modal() -> void:
	if _exit_confirm_backdrop != null:
		_exit_confirm_backdrop.visible = false


func open_song_setup_modal(p_entry: Dictionary) -> void:
	_ensure_ui_nodes()
	if p_entry.is_empty():
		return
	_selected_entry = p_entry.duplicate()
	_modal_song_title_label.text = str(_selected_entry.get("title", "Pista"))
	_refresh_modal_record_label()
	_refresh_modal_option_styles()
	if _status_label != null:
		_status_label.text = ""
	if _play_button != null and not _is_launching:
		_play_button.disabled = false
	_song_modal_backdrop.visible = true


func close_song_setup_modal() -> void:
	if _is_launching:
		return
	if _song_modal_backdrop != null:
		_song_modal_backdrop.visible = false


func select_difficulty(p_difficulty: int) -> void:
	_selected_difficulty = clampi(
		p_difficulty,
		AutoChartGenerator.Difficulty.EASY,
		AutoChartGenerator.Difficulty.HARD
	)
	_refresh_modal_option_styles()
	_refresh_modal_record_label()


func select_note_type_mode(p_mode: int) -> void:
	_selected_note_type_mode = clampi(
		p_mode,
		AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD,
		AutoChartGenerator.NoteTypeMode.TAP_ONLY
	)
	_refresh_modal_option_styles()
	_refresh_modal_record_label()


func select_speed_multiplier(p_multiplier: int) -> void:
	_selected_speed_multiplier = clampi(
		p_multiplier,
		LaneField.MIN_SPEED_MULTIPLIER,
		LaneField.MAX_SPEED_MULTIPLIER
	)
	_refresh_modal_option_styles()


func select_track_by_index(p_index: int) -> void:
	if _song_entries.is_empty():
		return
	var clamped: int = clampi(p_index, 0, _song_entries.size() - 1)
	open_song_setup_modal(_song_entries[clamped])


func register_external_track(p_audio_path: String, p_open_modal: bool = true) -> void:
	var cleaned: String = p_audio_path.strip_edges()
	if cleaned.is_empty():
		return

	_save_recent_track(cleaned)
	_reload_all_track_lists()

	var norm_target: String = ChartCacheRepository.normalize_song_key(cleaned)
	var count: int = _imported_entries.size()
	for i: int in range(count):
		var entry: Dictionary = _imported_entries[i]
		if str(entry.get("song_key", "")) == norm_target:
			_selected_entry = entry.duplicate()
			if p_open_modal:
				show_browser_screen(MenuTab.IMPORT)
				open_song_setup_modal(entry)
			return


func get_track_entries() -> Array[Dictionary]:
	var combined: Array[Dictionary] = []
	combined.append_array(_song_entries)
	combined.append_array(_imported_entries)
	return combined


func get_song_entries() -> Array[Dictionary]:
	return _song_entries


func get_imported_entries() -> Array[Dictionary]:
	return _imported_entries


func get_selected_track() -> Dictionary:
	if not _selected_entry.is_empty():
		return _selected_entry
	if not _song_entries.is_empty():
		return _song_entries[0]
	return {}


func get_selected_difficulty() -> int:
	return _selected_difficulty


func get_selected_note_type_mode() -> int:
	return _selected_note_type_mode


func get_selected_speed_multiplier() -> int:
	return _selected_speed_multiplier


func is_play_button_disabled() -> bool:
	return _play_button != null and _play_button.disabled


func get_transition_fade_rect() -> ColorRect:
	return _transition_fade_rect


func get_status_text() -> String:
	return _status_label.text if _status_label != null else ""


func get_safe_container_rect() -> Rect2:
	if _safe_container == null:
		return Rect2()
	return Rect2(_safe_container.position, _safe_container.size)


func set_chart_cache_repository(p_repo: ChartCacheRepository) -> void:
	if p_repo != null:
		_chart_cache_repo = p_repo
		_rebuild_songs_list_ui()
		_rebuild_imported_list_ui()
		_refresh_modal_record_label()


func is_option_button_highlighted(p_button: Button) -> bool:
	if p_button == null or _style_option_active == null:
		return false
	return p_button.get_theme_stylebox("normal") == _style_option_active


func get_font_registry() -> UiFontRegistry:
	return _font_registry


func get_role_control_fonts() -> Dictionary:
	var first_rank_font: Font = null
	if _songs_list_vbox != null and _songs_list_vbox.get_child_count() > 0:
		var first_row: Node = _songs_list_vbox.get_child(0)
		var rank_lbl: Label = first_row.find_child("RowRankBadge", true, false) as Label
		if rank_lbl != null:
			first_rank_font = rank_lbl.get_theme_font("font")

	return {
		"title": _hero_title_label.get_theme_font("font") if _hero_title_label != null else null,
		"header_title": _browser_header_label.get_theme_font("font") if _browser_header_label != null else null,
		"hero_play": _hero_play_button.get_theme_font("font") if _hero_play_button != null else null,
		"tab": _tab_songs_button.get_theme_font("font") if _tab_songs_button != null else null,
		"rank_badge": first_rank_font,
	}


func get_first_song_marquee_state() -> Dictionary:
	return get_song_marquee_state(0)


func get_song_marquee_state(p_index: int) -> Dictionary:
	if p_index < 0 or p_index >= _songs_marquee_items.size():
		return {}
	var item: Dictionary = _songs_marquee_items[p_index]
	var clip: Control = item.get("clip", null) as Control
	var label: Label = item.get("label", null) as Label
	return {
		"clip_contents": clip.clip_contents if clip != null else false,
		"child_count": clip.get_child_count() if clip != null else 0,
		"offset": float(item.get("offset", 0.0)),
		"pause_remaining": float(item.get("pause_remaining", 0.0)),
		"label_x": label.position.x if label != null else 0.0,
		"text_width": float(item.get("text_width", 0.0)),
		"clip_width": clip.size.x if clip != null else 0.0,
		"clip_left_inset": clip.global_position.x - (clip.get_parent().get_parent().get_parent() as Control).global_position.x if clip != null and clip.get_parent() != null and clip.get_parent().get_parent() != null and clip.get_parent().get_parent().get_parent() is Control else 0.0,
	}


func get_modal_option_buttons() -> Dictionary:
	return {
		"diff_easy": _diff_easy_button,
		"diff_normal": _diff_normal_button,
		"diff_hard": _diff_hard_button,
		"mode_tap_hold": _mode_tap_hold_button,
		"mode_tap_only": _mode_tap_only_button,
		"speed_1x": _speed_1x_button,
		"speed_2x": _speed_2x_button,
		"speed_3x": _speed_3x_button,
		"speed_4x": _speed_4x_button,
	}


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
		"speed_multiplier": _selected_speed_multiplier,
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


func _on_hero_play_pressed() -> void:
	show_browser_screen(MenuTab.SONGS)


func get_last_launch_sequence() -> Array[String]:
	return _last_launch_sequence


func _on_play_button_pressed() -> void:
	if _is_launching:
		return
	_is_launching = true
	_last_launch_sequence.clear()

	if _play_button != null:
		_play_button.disabled = true
	if _modal_close_button != null:
		_modal_close_button.disabled = true
	if _transition_fade_rect != null:
		_transition_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		_transition_fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)

	if menu_bgm_player != null:
		menu_bgm_player.stop_bgm()
	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(false)

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
		_status_label.text = "ANALIZANDO PISTA..." if needs_analysis_banner else "PREPARANDO PISTA..."

	var tree: SceneTree = get_tree()
	if tree != null:
		await tree.process_frame

	# Step 1 & 2: Perform analysis/cache load completely BEFORE starting cassette SFX + fade
	var payload: Dictionary = prepare_session_launch_payload()
	if payload.has("error"):
		if _transition_fade_rect != null:
			_transition_fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
			_transition_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _status_label != null:
			_status_label.text = str(payload["error"])
		_is_launching = false
		if _play_button != null:
			_play_button.disabled = false
		if _modal_close_button != null:
			_modal_close_button.disabled = false
		return

	GameSession.set_pending_session(payload)
	_last_launch_sequence.append("analysis_done")

	# Step 3: Chart is ready (no more CPU stalls) -> trigger cassette SFX + 2.5s fade simultaneously
	if _status_label != null:
		_status_label.text = "INICIANDO..."

	var transition_start_usec: int = Time.get_ticks_usec()
	if ui_sfx_player != null:
		ui_sfx_player.play_cassette_insert()
	_last_launch_sequence.append("cassette_started")

	if _transition_tween != null:
		_transition_tween.kill()
		_transition_tween = null

	if _transition_fade_rect != null:
		_transition_tween = create_tween()
		_transition_tween.tween_property(
			_transition_fade_rect,
			"modulate:a",
			1.0,
			TRANSITION_FADE_DURATION_SEC
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_last_launch_sequence.append("fade_started")

	if _transition_tween != null and _transition_tween.is_running():
		await _transition_tween.finished
	_transition_tween = null

	if tree != null:
		var elapsed_sec: float = float(Time.get_ticks_usec() - transition_start_usec) * USEC_TO_SEC
		var remaining_sec: float = TRANSITION_FADE_DURATION_SEC - elapsed_sec
		if remaining_sec > 0.005:
			await tree.create_timer(remaining_sec).timeout

	if _transition_fade_rect != null:
		_transition_fade_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if tree != null and ResourceLoader.exists(GAME_SESSION_SCENE_PATH):
		tree.change_scene_to_file(GAME_SESSION_SCENE_PATH)


func _on_browse_button_pressed() -> void:
	request_audio_import()


func has_android_audio_permission(p_granted: PackedStringArray) -> bool:
	for i: int in range(p_granted.size()):
		var perm: String = p_granted[i]
		if perm == ANDROID_PERM_READ_MEDIA_AUDIO or perm == ANDROID_PERM_READ_EXTERNAL_STORAGE:
			return true
	return false


func request_audio_import(
	p_platform_name: String = OS.get_name(),
	p_granted_override: PackedStringArray = PackedStringArray(),
	p_use_override: bool = false
) -> bool:
	if _file_dialog == null:
		return false

	if p_platform_name != "Android":
		_pending_import_after_permission = false
		_set_import_status("")
		_open_import_file_dialog(p_platform_name)
		return true

	var granted_perms: PackedStringArray = p_granted_override if p_use_override else OS.get_granted_permissions()
	if has_android_audio_permission(granted_perms):
		_pending_import_after_permission = false
		_set_import_status("")
		_open_import_file_dialog(p_platform_name)
		return true

	_pending_import_after_permission = true
	_set_import_status("Solicitando permiso de acceso a audio...", false)
	if not p_use_override:
		var granted_immediately: bool = OS.request_permissions()
		if granted_immediately or has_android_audio_permission(OS.get_granted_permissions()):
			_pending_import_after_permission = false
			_set_import_status("")
			_open_import_file_dialog(p_platform_name)
			return true
	return false


func get_import_status_text() -> String:
	return _import_status_label.text if _import_status_label != null else ""


func _open_import_file_dialog(p_platform_name: String) -> void:
	if _file_dialog == null:
		return
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	if p_platform_name == "Android":
		var music_dir: String = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)
		if not music_dir.is_empty() and DirAccess.dir_exists_absolute(music_dir):
			_file_dialog.current_dir = music_dir
	_file_dialog.popup_centered_ratio(0.85)


func _on_android_permissions_result(p_permission: String, p_granted: bool) -> void:
	if not _pending_import_after_permission:
		return
	var is_audio_perm: bool = (
		p_permission == ANDROID_PERM_READ_MEDIA_AUDIO
		or p_permission == ANDROID_PERM_READ_EXTERNAL_STORAGE
	)
	if p_granted or has_android_audio_permission(OS.get_granted_permissions()):
		_pending_import_after_permission = false
		_set_import_status("")
		_open_import_file_dialog("Android")
	elif is_audio_perm or p_permission.is_empty():
		_pending_import_after_permission = false
		_set_import_status(ANDROID_PERMISSION_DENIED_MESSAGE, true)


func _set_import_status(p_text: String, p_is_error: bool = false) -> void:
	if _import_status_label == null:
		return
	_import_status_label.text = p_text
	_import_status_label.visible = not p_text.is_empty()
	_import_status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.42, 0.52, 1.0) if p_is_error else COLOR_TEXT_GOLD
	)


func _on_file_selected(p_path: String) -> void:
	_set_import_status("")
	register_external_track(p_path, true)


func _on_bgm_toggle_pressed() -> void:
	if menu_bgm_player != null:
		menu_bgm_player.set_bgm_enabled(not menu_bgm_player.is_bgm_enabled)
	_refresh_bgm_controls()
	_sync_live_audio_monitoring()


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


func _on_bgm_enabled_changed(_p_enabled: bool) -> void:
	_refresh_bgm_controls()
	_sync_live_audio_monitoring()


func _on_bass_kick_pulsed(p_strength: float) -> void:
	_title_bass_boost = maxf(_title_bass_boost, clampf(p_strength, 0.0, 1.0))


func _on_menu_spectrum_updated(
	p_bass_energy: float,
	_p_mid_energy: float,
	_p_high_energy: float,
	_p_total_energy: float
) -> void:
	_live_menu_bass = maxf(_live_menu_bass, clampf(p_bass_energy, 0.0, 1.0))


func _on_modal_backdrop_gui_input(p_event: InputEvent) -> void:
	if _is_launching:
		return
	if p_event is InputEventMouseButton:
		var mb: InputEventMouseButton = p_event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _song_modal_panel != null and not _song_modal_panel.get_rect().has_point(mb.position):
				close_song_setup_modal()
	elif p_event is InputEventScreenTouch:
		var st: InputEventScreenTouch = p_event as InputEventScreenTouch
		if st.pressed:
			if _song_modal_panel != null and not _song_modal_panel.get_rect().has_point(st.position):
				close_song_setup_modal()


func _on_exit_confirm_backdrop_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton:
		var mb: InputEventMouseButton = p_event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _exit_confirm_panel != null and not _exit_confirm_panel.get_rect().has_point(mb.position):
				close_exit_confirm_modal()
	elif p_event is InputEventScreenTouch:
		var st: InputEventScreenTouch = p_event as InputEventScreenTouch
		if st.pressed:
			if _exit_confirm_panel != null and not _exit_confirm_panel.get_rect().has_point(st.position):
				close_exit_confirm_modal()


func _on_exit_confirm_cancel_pressed() -> void:
	close_exit_confirm_modal()


func _on_exit_confirm_quit_pressed() -> void:
	if ui_sfx_player != null:
		ui_sfx_player.play_button_click()
	if menu_bgm_player != null:
		menu_bgm_player.stop_bgm()
	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(false)
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.quit()


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
		reactive_background.set_backdrop_mode(ReactiveBackground.BackdropMode.MENU)
		reactive_background.set_perimeter_wave_enabled(false)
		reactive_background.audio_analyzer = audio_analyzer
		reactive_background.connect_dependencies()
		if not reactive_background.bass_kick_pulsed.is_connected(_on_bass_kick_pulsed):
			reactive_background.bass_kick_pulsed.connect(_on_bass_kick_pulsed)
		if not audio_analyzer.spectrum_updated.is_connected(_on_menu_spectrum_updated):
			audio_analyzer.spectrum_updated.connect(_on_menu_spectrum_updated)

	if menu_bgm_player != null:
		if not menu_bgm_player.track_changed.is_connected(_on_bgm_track_changed):
			menu_bgm_player.track_changed.connect(_on_bgm_track_changed)
		if not menu_bgm_player.bgm_enabled_changed.is_connected(_on_bgm_enabled_changed):
			menu_bgm_player.bgm_enabled_changed.connect(_on_bgm_enabled_changed)

	var tree: SceneTree = get_tree()
	if tree != null and tree.has_signal("on_request_permissions_result"):
		if not tree.is_connected("on_request_permissions_result", _on_android_permissions_result):
			tree.connect("on_request_permissions_result", _on_android_permissions_result)

	if ui_sfx_player != null and _safe_container != null:
		var excluded: Array[BaseButton] = []
		if _play_button != null:
			excluded.append(_play_button)
		if _exit_confirm_button != null:
			excluded.append(_exit_confirm_button)
		ui_sfx_player.bind_buttons_in_tree(_safe_container, excluded)


func _sync_live_audio_monitoring() -> void:
	var should_monitor: bool = (
		not _is_launching
		and menu_bgm_player != null
		and menu_bgm_player.is_bgm_enabled
		and menu_bgm_player.get_track_count() > 0
	)
	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(should_monitor)
	if reactive_background != null:
		reactive_background.set_menu_bgm_active(should_monitor)


func _reload_all_track_lists() -> void:
	_song_entries.clear()
	_imported_entries.clear()

	var seen_songs: Dictionary = {}
	_song_entries.append({
		"is_demo": true,
		"song_key": ChartCacheRepository.BUILTIN_DEMO_SONG_KEY,
		"audio_path": "",
		"title": "Demo Integrada (128 BPM)",
		"source_tag": "DEMO",
	})
	seen_songs[ChartCacheRepository.BUILTIN_DEMO_SONG_KEY] = true

	var bundled_paths: PackedStringArray = _scan_bundled_songs()
	for i: int in range(bundled_paths.size()):
		var song_path: String = bundled_paths[i]
		var song_key: String = ChartCacheRepository.normalize_song_key(song_path)
		if not seen_songs.has(song_key):
			seen_songs[song_key] = true
			_song_entries.append({
				"is_demo": false,
				"song_key": song_key,
				"audio_path": song_path,
				"title": song_path.get_file().get_basename(),
				"source_tag": "LOCAL",
			})

	var seen_imported: Dictionary = {}
	var recent_paths: PackedStringArray = _load_recent_tracks()
	for j: int in range(recent_paths.size()):
		var recent_path: String = recent_paths[j]
		var recent_key: String = ChartCacheRepository.normalize_song_key(recent_path)
		if not seen_imported.has(recent_key) and FileAccess.file_exists(recent_path):
			seen_imported[recent_key] = true
			_imported_entries.append({
				"is_demo": false,
				"song_key": recent_key,
				"audio_path": recent_path,
				"title": recent_path.get_file().get_basename(),
				"source_tag": "IMPORTADA",
			})

	if _selected_entry.is_empty() and not _song_entries.is_empty():
		_selected_entry = _song_entries[0].duplicate()

	_rebuild_songs_list_ui()
	_rebuild_imported_list_ui()


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
	var target_norm: String = ChartCacheRepository.normalize_song_key(p_audio_path)
	var updated: Array[String] = [p_audio_path]
	for i: int in range(existing.size()):
		var item: String = existing[i]
		if ChartCacheRepository.normalize_song_key(item) != target_norm and updated.size() < MAX_RECENT_TRACKS:
			updated.append(item)

	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("recent", "paths", PackedStringArray(updated))
	cfg.save(_recent_tracks_path)


func _rebuild_songs_list_ui() -> void:
	_rebuild_entry_list(
		_songs_list_vbox,
		_song_entries,
		_songs_marquee_items,
		"SongRow",
		"No hay canciones disponibles."
	)


func _rebuild_imported_list_ui() -> void:
	_rebuild_entry_list(
		_import_list_vbox,
		_imported_entries,
		_imported_marquee_items,
		"ImportedRow",
		"Aún no has importado canciones desde tu dispositivo."
	)


func _rebuild_entry_list(
	p_container: VBoxContainer,
	p_entries: Array[Dictionary],
	p_marquee_target: Array[Dictionary],
	p_prefix: String,
	p_empty_message: String
) -> void:
	if p_container == null:
		return

	p_container.add_theme_constant_override("separation", 0)
	p_marquee_target.clear()
	var old_children: Array[Node] = p_container.get_children()
	for i: int in range(old_children.size()):
		p_container.remove_child(old_children[i])
		old_children[i].queue_free()

	if p_entries.is_empty():
		var empty_margin: MarginContainer = MarginContainer.new()
		empty_margin.name = "%sEmptyMargin" % p_prefix
		empty_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_margin.add_theme_constant_override("margin_left", 28)
		empty_margin.add_theme_constant_override("margin_right", 28)
		empty_margin.add_theme_constant_override("margin_top", 56)
		empty_margin.add_theme_constant_override("margin_bottom", 32)
		var empty_label: Label = Label.new()
		empty_label.name = "%sEmptyLabel" % p_prefix
		empty_label.text = p_empty_message
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", SONG_BADGE_FONT_SIZE)
		empty_label.modulate = COLOR_TEXT_INACTIVE
		empty_margin.add_child(empty_label)
		p_container.add_child(empty_margin)
		return

	var count: int = p_entries.size()
	for idx: int in range(count):
		var entry: Dictionary = p_entries[idx]
		var song_key: String = str(entry.get("song_key", ""))
		var title: String = str(entry.get("title", "Pista"))
		var summary: Dictionary = _chart_cache_repo.load_song_summary(song_key)
		var has_record: bool = summary.get("has_record", false) as bool
		var best_rank: String = str(summary.get("best_rank", ""))

		var row_btn: Button = Button.new()
		row_btn.name = "%s_%d" % [p_prefix, idx]
		row_btn.text = ""
		row_btn.custom_minimum_size = Vector2(0.0, SONG_ROW_HEIGHT_PX)
		row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_apply_song_row_style(row_btn, idx < count - 1)
		row_btn.pressed.connect(open_song_setup_modal.bind(entry))
		if ui_sfx_player != null:
			ui_sfx_player.bind_button(row_btn)

		var row_margin: MarginContainer = MarginContainer.new()
		row_margin.name = "RowInnerMargin"
		row_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row_margin.add_theme_constant_override("margin_left", ROW_INNER_MARGIN_X)
		row_margin.add_theme_constant_override("margin_right", ROW_INNER_MARGIN_X)
		row_margin.add_theme_constant_override("margin_top", 0)
		row_margin.add_theme_constant_override("margin_bottom", 0)
		row_btn.add_child(row_margin)

		var row_hbox: HBoxContainer = HBoxContainer.new()
		row_hbox.name = "RowContentHBox"
		row_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_hbox.add_theme_constant_override("separation", ROW_TITLE_RANK_GAP_PX)
		row_margin.add_child(row_hbox)

		# Zone 1: Left clipped conditional marquee container (28 px left margin, 24 px gap before rank)
		var title_clip: Control = Control.new()
		title_clip.name = "RowTitleClip"
		title_clip.clip_contents = true
		title_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row_hbox.add_child(title_clip)

		var title_lbl: Label = _create_marquee_title_label("RowTitleLabel", title)
		title_clip.add_child(title_lbl)

		var measured_width: float = _measure_marquee_title_width(title_lbl, title)
		title_lbl.position = Vector2(0.0, 0.0)
		title_lbl.size = Vector2(measured_width + 16.0, SONG_ROW_HEIGHT_PX)

		p_marquee_target.append({
			"clip": title_clip,
			"label": title_lbl,
			"text_width": measured_width,
			"offset": 0.0,
			"pause_remaining": MARQUEE_INITIAL_PAUSE_SEC,
		})

		# Zone 2: Fixed right zone for Rank (58px neon blur) + Difficulty (30px)
		var rank_zone: HBoxContainer = HBoxContainer.new()
		rank_zone.name = "RowRankZone"
		rank_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rank_zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rank_zone.alignment = BoxContainer.ALIGNMENT_END
		rank_zone.add_theme_constant_override("separation", 12)
		row_hbox.add_child(rank_zone)

		var rank_lbl: Label = Label.new()
		rank_lbl.name = "RowRankBadge"
		var display_rank: String = best_rank if has_record else "--"
		rank_lbl.text = display_rank
		rank_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rank_lbl.custom_minimum_size = Vector2(96.0, 0.0)
		UiFontRegistry.apply_neon_rank_style(rank_lbl, display_rank, SONG_RANK_FONT_SIZE)
		rank_zone.add_child(rank_lbl)

		if has_record:
			var best_diff: int = int(summary.get("best_difficulty", AutoChartGenerator.Difficulty.NORMAL))
			var diff_lbl: Label = Label.new()
			diff_lbl.name = "RowDiffBadge"
			diff_lbl.text = "· %s" % ChartCacheRepository.difficulty_to_label(best_diff)
			diff_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			diff_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			diff_lbl.add_theme_font_size_override("font_size", SONG_DIFF_FONT_SIZE)
			diff_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.96))
			if _font_registry != null:
				_font_registry.apply_global_font_override(diff_lbl, 3)
			rank_zone.add_child(diff_lbl)

		p_container.add_child(row_btn)


func _create_marquee_title_label(p_name: String, p_text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.name = p_name
	lbl.text = p_text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text = false
	lbl.add_theme_font_size_override("font_size", SONG_ROW_FONT_SIZE)
	lbl.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	if _font_registry != null:
		_font_registry.apply_global_font_override(lbl, 3)
	return lbl


func _measure_marquee_title_width(p_label: Label, p_text: String) -> float:
	if p_label == null:
		return 240.0
	var used_font: Font = _font_registry.get_global_font() if _font_registry != null else null
	if used_font == null:
		used_font = p_label.get_theme_font("font")
	if used_font != null:
		var measured: Vector2 = used_font.get_string_size(
			p_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			SONG_ROW_FONT_SIZE
		)
		return maxf(64.0, measured.x)
	return maxf(64.0, float(p_text.length()) * float(SONG_ROW_FONT_SIZE) * 0.62)


func _reset_marquee_items(p_items: Array[Dictionary]) -> void:
	var count: int = p_items.size()
	for i: int in range(count):
		var item: Dictionary = p_items[i]
		item["offset"] = 0.0
		item["pause_remaining"] = MARQUEE_INITIAL_PAUSE_SEC
		p_items[i] = item
		var label: Label = item.get("label", null) as Label
		if is_instance_valid(label):
			label.position = Vector2(0.0, 0.0)


func _step_marquee_items(p_items: Array[Dictionary], p_delta: float) -> void:
	var count: int = p_items.size()
	for i: int in range(count):
		var item: Dictionary = p_items[i]
		var clip: Control = item.get("clip", null) as Control
		var label: Label = item.get("label", null) as Label
		if not is_instance_valid(clip) or not is_instance_valid(label):
			continue

		var clip_w: float = clip.size.x
		var clip_h: float = clip.size.y if clip.size.y > 1.0 else SONG_ROW_HEIGHT_PX
		var text_w: float = float(item.get("text_width", 0.0))
		label.size = Vector2(maxf(clip_w, text_w + 16.0), clip_h)

		# Keep fixed left alignment until layout resolves or whenever the title fits completely
		if clip_w <= 1.0 or text_w <= clip_w:
			item["offset"] = 0.0
			item["pause_remaining"] = MARQUEE_INITIAL_PAUSE_SEC
			p_items[i] = item
			label.position = Vector2(0.0, 0.0)
			continue

		var pause_remaining: float = float(item.get("pause_remaining", MARQUEE_INITIAL_PAUSE_SEC))
		var move_dt: float = p_delta
		if pause_remaining > 0.0:
			if move_dt <= pause_remaining:
				pause_remaining -= move_dt
				move_dt = 0.0
			else:
				move_dt -= pause_remaining
				pause_remaining = 0.0

		var offset: float = float(item.get("offset", 0.0))
		var next_x: float = 0.0
		if move_dt > 0.0:
			var exit_distance: float = text_w + MARQUEE_EDGE_PAD_PX
			var cycle_span: float = exit_distance + clip_w
			offset += MARQUEE_SPEED_PX_PER_SEC * move_dt
			if offset >= cycle_span:
				offset = 0.0
				pause_remaining = MARQUEE_INITIAL_PAUSE_SEC
				next_x = 0.0
			else:
				next_x = -offset if offset <= exit_distance else (cycle_span - offset)

		item["offset"] = offset
		item["pause_remaining"] = pause_remaining
		p_items[i] = item
		label.position = Vector2(next_x, 0.0)


func _refresh_tab_visuals() -> void:
	if _songs_tab_container != null:
		_songs_tab_container.visible = (_active_tab == MenuTab.SONGS)
	if _import_tab_container != null:
		_import_tab_container.visible = (_active_tab == MenuTab.IMPORT)
	if _settings_tab_container != null:
		_settings_tab_container.visible = (_active_tab == MenuTab.SETTINGS)

	_set_option_highlight(_tab_songs_button, _active_tab == MenuTab.SONGS)
	_set_option_highlight(_tab_import_button, _active_tab == MenuTab.IMPORT)
	_set_option_highlight(_tab_settings_button, _active_tab == MenuTab.SETTINGS)


func _refresh_modal_option_styles() -> void:
	_set_option_highlight(_diff_easy_button, _selected_difficulty == AutoChartGenerator.Difficulty.EASY)
	_set_option_highlight(_diff_normal_button, _selected_difficulty == AutoChartGenerator.Difficulty.NORMAL)
	_set_option_highlight(_diff_hard_button, _selected_difficulty == AutoChartGenerator.Difficulty.HARD)

	_set_option_highlight(_mode_tap_hold_button, _selected_note_type_mode == AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD)
	_set_option_highlight(_mode_tap_only_button, _selected_note_type_mode == AutoChartGenerator.NoteTypeMode.TAP_ONLY)

	_set_option_highlight(_speed_1x_button, _selected_speed_multiplier == 1)
	_set_option_highlight(_speed_2x_button, _selected_speed_multiplier == 2)
	_set_option_highlight(_speed_3x_button, _selected_speed_multiplier == 3)
	_set_option_highlight(_speed_4x_button, _selected_speed_multiplier == 4)


func _refresh_modal_record_label() -> void:
	if _modal_record_label == null or _modal_record_rank_label == null or _modal_record_detail_label == null:
		return
	var selected: Dictionary = get_selected_track()
	var song_key: String = str(selected.get("song_key", ""))
	if song_key.is_empty():
		_modal_record_label.text = "SIN RÉCORD TODAVÍA"
		_modal_record_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
		_modal_record_rank_label.text = "--"
		UiFontRegistry.apply_neon_rank_style(_modal_record_rank_label, "--", MODAL_RANK_FONT_SIZE)
		_modal_record_detail_label.text = ""
		return

	var summary: Dictionary = _chart_cache_repo.load_song_summary(song_key)
	var specific: Dictionary = _chart_cache_repo.load_song_record(
		song_key,
		_selected_difficulty,
		_selected_note_type_mode
	)
	if specific.get("has_record", false) as bool:
		var rank: String = str(specific.get("best_rank", ""))
		var score_val: int = int(specific.get("best_score", 0))
		var acc_val: float = float(specific.get("best_accuracy", 0.0))
		_modal_record_label.text = "MEJOR EN ESTE MODO:"
		_modal_record_label.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
		_modal_record_rank_label.text = rank
		UiFontRegistry.apply_neon_rank_style(_modal_record_rank_label, rank, MODAL_RANK_FONT_SIZE)
		_modal_record_detail_label.text = "· %d pts (%.1f%%)" % [score_val, acc_val]
		_modal_record_detail_label.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	elif summary.get("has_record", false) as bool:
		var best_rank: String = str(summary.get("best_rank", ""))
		var best_diff: int = int(summary.get("best_difficulty", AutoChartGenerator.Difficulty.NORMAL))
		_modal_record_label.text = "MEJOR GLOBAL:"
		_modal_record_label.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
		_modal_record_rank_label.text = best_rank
		UiFontRegistry.apply_neon_rank_style(_modal_record_rank_label, best_rank, MODAL_RANK_FONT_SIZE)
		_modal_record_detail_label.text = "· %s" % ChartCacheRepository.difficulty_to_label(best_diff)
		_modal_record_detail_label.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	else:
		_modal_record_label.text = "SIN RÉCORD TODAVÍA"
		_modal_record_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
		_modal_record_rank_label.text = "--"
		UiFontRegistry.apply_neon_rank_style(_modal_record_rank_label, "--", MODAL_RANK_FONT_SIZE)
		_modal_record_detail_label.text = ""


func _refresh_bgm_controls() -> void:
	var bgm_enabled: bool = menu_bgm_player.is_bgm_enabled if menu_bgm_player != null else true
	var track_name: String = menu_bgm_player.get_current_track_name() if menu_bgm_player != null else MenuBgmPlayer.EMPTY_TRACK_LABEL
	var auto_rotate: bool = menu_bgm_player.is_auto_rotate if menu_bgm_player != null else true

	if _bgm_toggle_button != null:
		_bgm_toggle_button.text = "BGM: ACTIVADO" if bgm_enabled else "BGM: APAGADO"
		_set_option_highlight(_bgm_toggle_button, bgm_enabled)

	if _bgm_track_label != null:
		_bgm_track_label.text = "PISTA ACTUAL: %s" % track_name

	if _bgm_mode_button != null:
		_bgm_mode_button.text = "MODO: AUTO" if auto_rotate else "MODO: FIJA"
		_set_option_highlight(_bgm_mode_button, auto_rotate)


func _set_option_highlight(p_button: Button, p_is_active: bool) -> void:
	if p_button == null:
		return
	var target_style: StyleBox = _style_option_active if p_is_active else _style_option_inactive
	_apply_stylebox_to_button(p_button, target_style)
	var text_col: Color = COLOR_TEXT_ACTIVE if p_is_active else COLOR_TEXT_INACTIVE
	p_button.add_theme_color_override("font_color", text_col)
	p_button.add_theme_color_override("font_hover_color", COLOR_TEXT_ACTIVE)
	p_button.add_theme_color_override("font_pressed_color", COLOR_TEXT_ACTIVE)
	p_button.add_theme_color_override("font_focus_color", text_col)


func _apply_stylebox_to_button(p_button: Button, p_style: StyleBox) -> void:
	if p_button == null or p_style == null:
		return
	p_button.add_theme_stylebox_override("normal", p_style)
	p_button.add_theme_stylebox_override("hover", p_style)
	p_button.add_theme_stylebox_override("pressed", p_style)
	p_button.add_theme_stylebox_override("focus", p_style)


func _apply_song_row_style(p_button: Button, p_has_bottom_divider: bool) -> void:
	if p_button == null:
		return
	var normal_style: StyleBoxFlat = _style_song_row_divider_normal if p_has_bottom_divider else _style_song_row_last_normal
	var hover_style: StyleBoxFlat = _style_song_row_divider_hover if p_has_bottom_divider else _style_song_row_last_hover
	if normal_style != null:
		p_button.add_theme_stylebox_override("normal", normal_style)
		p_button.add_theme_stylebox_override("focus", normal_style)
	if hover_style != null:
		p_button.add_theme_stylebox_override("hover", hover_style)
		p_button.add_theme_stylebox_override("pressed", hover_style)


func _create_white_divider(p_name: String, p_margin_x: int = ROW_INNER_MARGIN_X) -> MarginContainer:
	var holder: MarginContainer = MarginContainer.new()
	holder.name = p_name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	holder.custom_minimum_size = Vector2(0.0, DIVIDER_HEIGHT_PX)
	holder.add_theme_constant_override("margin_left", p_margin_x)
	holder.add_theme_constant_override("margin_right", p_margin_x)
	holder.add_theme_constant_override("margin_top", 0)
	holder.add_theme_constant_override("margin_bottom", 0)

	var line: ColorRect = ColorRect.new()
	line.name = "DividerLine"
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = COLOR_WHITE_DIVIDER
	line.custom_minimum_size = Vector2(0.0, DIVIDER_HEIGHT_PX)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_child(line)
	return holder


func _create_song_row_stylebox(p_bg_color: Color, p_bottom_border_px: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = p_bg_color
	sb.set_border_width_all(0)
	sb.border_width_bottom = p_bottom_border_px
	sb.border_color = COLOR_ROW_BOTTOM_BORDER
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(0.0)
	return sb


func _build_theme_styles() -> void:
	_style_option_active = StyleBoxFlat.new()
	_style_option_active.bg_color = Color(0.10, 0.44, 0.58, 0.94)
	_style_option_active.border_color = Color(0.38, 0.96, 1.0, 1.0)
	_style_option_active.set_border_width_all(3)
	_style_option_active.set_corner_radius_all(12)
	_style_option_active.shadow_color = Color(0.20, 0.90, 1.0, 0.35)
	_style_option_active.shadow_size = 6

	_style_option_inactive = StyleBoxFlat.new()
	_style_option_inactive.bg_color = Color(0.06, 0.09, 0.16, 0.84)
	_style_option_inactive.border_color = Color(0.26, 0.36, 0.52, 0.55)
	_style_option_inactive.set_border_width_all(1)
	_style_option_inactive.set_corner_radius_all(12)

	_style_content_sheet = StyleBoxFlat.new()
	_style_content_sheet.bg_color = COLOR_SHEET_BG
	_style_content_sheet.border_color = COLOR_SHEET_BORDER
	_style_content_sheet.set_border_width_all(2)
	_style_content_sheet.set_corner_radius_all(22)
	_style_content_sheet.anti_aliasing = true

	_style_song_row_divider_normal = _create_song_row_stylebox(COLOR_ROW_REST_BG, ROW_BOTTOM_BORDER_PX)
	_style_song_row_divider_hover = _create_song_row_stylebox(COLOR_ROW_HOVER_BG, ROW_BOTTOM_BORDER_PX)
	_style_song_row_last_normal = _create_song_row_stylebox(COLOR_ROW_REST_BG, 0)
	_style_song_row_last_hover = _create_song_row_stylebox(COLOR_ROW_HOVER_BG, 0)

	_style_modal_panel = StyleBoxFlat.new()
	_style_modal_panel.bg_color = Color(0.05, 0.07, 0.14, 0.96)
	_style_modal_panel.border_color = Color(0.35, 0.92, 1.0, 0.92)
	_style_modal_panel.set_border_width_all(3)
	_style_modal_panel.set_corner_radius_all(18)
	_style_modal_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	_style_modal_panel.shadow_size = 18

	_style_play_cta = StyleBoxFlat.new()
	_style_play_cta.bg_color = Color(0.10, 0.68, 0.64, 0.98)
	_style_play_cta.border_color = Color(0.65, 1.0, 0.94, 1.0)
	_style_play_cta.set_border_width_all(3)
	_style_play_cta.set_corner_radius_all(16)
	_style_play_cta.shadow_color = Color(0.22, 1.0, 0.88, 0.40)
	_style_play_cta.shadow_size = 10

	_style_exit_danger = StyleBoxFlat.new()
	_style_exit_danger.bg_color = Color(0.56, 0.12, 0.22, 0.94)
	_style_exit_danger.border_color = Color(1.0, 0.42, 0.56, 0.96)
	_style_exit_danger.set_border_width_all(3)
	_style_exit_danger.set_corner_radius_all(14)
	_style_exit_danger.shadow_color = Color(1.0, 0.25, 0.45, 0.35)
	_style_exit_danger.shadow_size = 8

	_style_floating_play = StyleBoxEmpty.new()


func _apply_external_fonts() -> void:
	if _font_registry == null:
		_font_registry = UiFontRegistry.new()
	_font_registry.apply_global_theme(get_tree())
	_font_registry.apply_title_role(_hero_title_label, 10)
	_font_registry.apply_title_role(_browser_header_label, 7)
	_font_registry.apply_global_font_override(_hero_play_button, 6)
	_font_registry.apply_global_font_override(_exit_confirm_title, 3)
	_font_registry.apply_global_font_override(_exit_cancel_button, 2)
	_font_registry.apply_global_font_override(_exit_confirm_button, 2)
	_font_registry.apply_global_font_override(_import_status_label, 2)


func _ensure_ui_nodes() -> void:
	if _safe_container != null:
		return

	_safe_container = Control.new()
	_safe_container.name = "SafeAreaContainer"
	_safe_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_container)

	_build_title_screen_ui()
	_build_browser_screen_ui()
	_build_song_setup_modal_ui()
	_build_exit_confirm_modal_ui()

	_file_dialog = FileDialog.new()
	_file_dialog.name = "AudioFileDialog"
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	_file_dialog.filters = PackedStringArray(["*.mp3, *.ogg, *.wav ; Pistas de Audio"])
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)

	_transition_fade_rect = ColorRect.new()
	_transition_fade_rect.name = "TransitionFadeRect"
	_transition_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_transition_fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_transition_fade_rect.z_index = TRANSITION_FADE_Z_INDEX
	_transition_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_transition_fade_rect)
	_transition_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_title_screen_ui() -> void:
	_title_screen_container = Control.new()
	_title_screen_container.name = "TitleScreenContainer"
	_title_screen_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_container.add_child(_title_screen_container)

	_hero_title_label = Label.new()
	_hero_title_label.name = "HeroTitleLabel"
	_hero_title_label.text = "FEEL YOUR BEATS"
	_hero_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hero_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hero_title_label.add_theme_font_size_override("font_size", TITLE_HERO_FONT_SIZE)
	_hero_title_label.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	_title_screen_container.add_child(_hero_title_label)

	_hero_subtitle_label = Label.new()
	_hero_subtitle_label.name = "HeroSubtitleLabel"
	_hero_subtitle_label.text = "TU MÚSICA · TU RITMO"
	_hero_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hero_subtitle_label.add_theme_font_size_override("font_size", TITLE_SUBTITLE_FONT_SIZE)
	_hero_subtitle_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
	_title_screen_container.add_child(_hero_subtitle_label)

	_hero_play_button = Button.new()
	_hero_play_button.name = "HeroPlayButton"
	_hero_play_button.text = "JUGAR"
	_hero_play_button.flat = true
	_hero_play_button.add_theme_font_size_override("font_size", TITLE_PLAY_FONT_SIZE)
	_hero_play_button.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	_hero_play_button.add_theme_color_override("font_hover_color", COLOR_TEXT_ACCENT)
	_hero_play_button.add_theme_color_override("font_pressed_color", COLOR_TEXT_GOLD)
	_apply_stylebox_to_button(_hero_play_button, _style_floating_play)
	_hero_play_button.pressed.connect(_on_hero_play_pressed)
	_title_screen_container.add_child(_hero_play_button)


func _build_browser_screen_ui() -> void:
	_browser_screen_container = VBoxContainer.new()
	_browser_screen_container.name = "BrowserScreenContainer"
	_browser_screen_container.visible = false
	_browser_screen_container.add_theme_constant_override("separation", 18)
	_safe_container.add_child(_browser_screen_container)

	_browser_header_label = Label.new()
	_browser_header_label.name = "BrowserHeaderLabel"
	_browser_header_label.text = "FEEL YOUR BEATS"
	_browser_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_browser_header_label.add_theme_font_size_override("font_size", HEADER_TITLE_FONT_SIZE)
	_browser_header_label.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	_browser_screen_container.add_child(_browser_header_label)

	var tabs_row: HBoxContainer = HBoxContainer.new()
	tabs_row.name = "TopTabsRow"
	tabs_row.add_theme_constant_override("separation", 10)
	_browser_screen_container.add_child(tabs_row)

	_tab_songs_button = _create_tab_button("TabSongsButton", "CANCIONES")
	_tab_songs_button.pressed.connect(select_tab.bind(MenuTab.SONGS))
	tabs_row.add_child(_tab_songs_button)

	_tab_import_button = _create_tab_button("TabImportButton", "IMPORTAR")
	_tab_import_button.pressed.connect(select_tab.bind(MenuTab.IMPORT))
	tabs_row.add_child(_tab_import_button)

	_tab_settings_button = _create_tab_button("TabSettingsButton", "AJUSTES")
	_tab_settings_button.pressed.connect(select_tab.bind(MenuTab.SETTINGS))
	tabs_row.add_child(_tab_settings_button)

	# Unified full-height frosted translucent sheet below the top tabs
	_content_sheet_panel = PanelContainer.new()
	_content_sheet_panel.name = "ContentSheetPanel"
	_content_sheet_panel.clip_contents = true
	_content_sheet_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_sheet_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_sheet_panel.add_theme_stylebox_override("panel", _style_content_sheet)
	_browser_screen_container.add_child(_content_sheet_panel)

	var sheet_inner: MarginContainer = MarginContainer.new()
	sheet_inner.name = "ContentSheetInner"
	sheet_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet_inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet_inner.add_theme_constant_override("margin_left", 0)
	sheet_inner.add_theme_constant_override("margin_right", 0)
	sheet_inner.add_theme_constant_override("margin_top", 8)
	sheet_inner.add_theme_constant_override("margin_bottom", 8)
	_content_sheet_panel.add_child(sheet_inner)

	# Tab 1: CANCIONES
	var songs_scroll: ScrollContainer = ScrollContainer.new()
	songs_scroll.name = "SongsTabScroll"
	songs_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	songs_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet_inner.add_child(songs_scroll)
	_songs_tab_container = songs_scroll

	_songs_list_vbox = VBoxContainer.new()
	_songs_list_vbox.name = "SongsListVBox"
	_songs_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_songs_list_vbox.add_theme_constant_override("separation", 0)
	songs_scroll.add_child(_songs_list_vbox)

	# Tab 2: IMPORTAR
	var import_vbox: VBoxContainer = VBoxContainer.new()
	import_vbox.name = "ImportTabContainer"
	import_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	import_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_vbox.add_theme_constant_override("separation", 16)
	import_vbox.visible = false
	sheet_inner.add_child(import_vbox)
	_import_tab_container = import_vbox

	var import_top_margin: MarginContainer = MarginContainer.new()
	import_top_margin.name = "ImportTopMargin"
	import_top_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_top_margin.add_theme_constant_override("margin_left", 24)
	import_top_margin.add_theme_constant_override("margin_right", 24)
	import_top_margin.add_theme_constant_override("margin_top", 18)
	import_top_margin.add_theme_constant_override("margin_bottom", 6)
	import_vbox.add_child(import_top_margin)

	var import_top_vbox: VBoxContainer = VBoxContainer.new()
	import_top_vbox.add_theme_constant_override("separation", 16)
	import_top_margin.add_child(import_top_vbox)

	_browse_button = Button.new()
	_browse_button.name = "ImportSongButton"
	_browse_button.text = "IMPORTAR CANCIÓN DEL DISPOSITIVO"
	_browse_button.custom_minimum_size = Vector2(0.0, 92.0)
	_browse_button.add_theme_font_size_override("font_size", 36)
	_browse_button.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	_apply_stylebox_to_button(_browse_button, _style_option_active)
	_browse_button.pressed.connect(_on_browse_button_pressed)
	import_top_vbox.add_child(_browse_button)

	_import_status_label = Label.new()
	_import_status_label.name = "ImportStatusLabel"
	_import_status_label.text = ""
	_import_status_label.visible = false
	_import_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_import_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_import_status_label.add_theme_font_size_override("font_size", 28)
	_import_status_label.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	import_top_vbox.add_child(_import_status_label)

	var imported_header: Label = Label.new()
	imported_header.name = "ImportedHeaderLabel"
	imported_header.text = "CANCIONES IMPORTADAS / RECIENTES"
	imported_header.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	imported_header.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
	import_top_vbox.add_child(imported_header)

	import_vbox.add_child(_create_white_divider("ImportSectionDivider", 24))

	var import_scroll: ScrollContainer = ScrollContainer.new()
	import_scroll.name = "ImportedListScroll"
	import_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	import_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_vbox.add_child(import_scroll)

	_import_list_vbox = VBoxContainer.new()
	_import_list_vbox.name = "ImportedListVBox"
	_import_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_import_list_vbox.add_theme_constant_override("separation", 0)
	import_scroll.add_child(_import_list_vbox)

	# Tab 3: AJUSTES (within the same unified frosted sheet with white dividers)
	var settings_margin: MarginContainer = MarginContainer.new()
	settings_margin.name = "SettingsTabContainer"
	settings_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_margin.add_theme_constant_override("margin_left", 28)
	settings_margin.add_theme_constant_override("margin_right", 28)
	settings_margin.add_theme_constant_override("margin_top", 28)
	settings_margin.add_theme_constant_override("margin_bottom", 28)
	settings_margin.visible = false
	sheet_inner.add_child(settings_margin)
	_settings_tab_container = settings_margin

	var settings_vbox: VBoxContainer = VBoxContainer.new()
	settings_vbox.name = "SettingsContentVBox"
	settings_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_vbox.add_theme_constant_override("separation", 28)
	settings_margin.add_child(settings_vbox)

	var settings_header: Label = Label.new()
	settings_header.name = "SettingsBgmHeader"
	settings_header.text = "MÚSICA DE FONDO DEL MENÚ (BGM)"
	settings_header.add_theme_font_size_override("font_size", SETTINGS_LABEL_FONT_SIZE)
	settings_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	settings_vbox.add_child(settings_header)

	_bgm_toggle_button = Button.new()
	_bgm_toggle_button.name = "BgmToggleButton"
	_bgm_toggle_button.text = "BGM: ACTIVADO"
	_bgm_toggle_button.custom_minimum_size = Vector2(0.0, 90.0)
	_bgm_toggle_button.add_theme_font_size_override("font_size", 38)
	_bgm_toggle_button.pressed.connect(_on_bgm_toggle_pressed)
	settings_vbox.add_child(_bgm_toggle_button)

	settings_vbox.add_child(_create_white_divider("SettingsDivider_0", 0))

	_bgm_track_label = Label.new()
	_bgm_track_label.name = "BgmTrackLabel"
	_bgm_track_label.text = "PISTA ACTUAL: Sin BGM"
	_bgm_track_label.clip_text = true
	_bgm_track_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_bgm_track_label.add_theme_font_size_override("font_size", SETTINGS_LABEL_FONT_SIZE)
	_bgm_track_label.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	settings_vbox.add_child(_bgm_track_label)

	var bgm_nav_row: HBoxContainer = HBoxContainer.new()
	bgm_nav_row.name = "BgmNavRow"
	bgm_nav_row.add_theme_constant_override("separation", 14)
	settings_vbox.add_child(bgm_nav_row)

	_bgm_prev_button = _create_option_button("BgmPrevButton", "< ANTERIOR")
	_bgm_prev_button.pressed.connect(_on_bgm_prev_pressed)
	_apply_stylebox_to_button(_bgm_prev_button, _style_option_inactive)
	bgm_nav_row.add_child(_bgm_prev_button)

	_bgm_next_button = _create_option_button("BgmNextButton", "SIGUIENTE >")
	_bgm_next_button.pressed.connect(_on_bgm_next_pressed)
	_apply_stylebox_to_button(_bgm_next_button, _style_option_inactive)
	bgm_nav_row.add_child(_bgm_next_button)

	settings_vbox.add_child(_create_white_divider("SettingsDivider_1", 0))

	_bgm_mode_button = Button.new()
	_bgm_mode_button.name = "BgmModeButton"
	_bgm_mode_button.text = "MODO: AUTO"
	_bgm_mode_button.custom_minimum_size = Vector2(0.0, 88.0)
	_bgm_mode_button.add_theme_font_size_override("font_size", 36)
	_bgm_mode_button.pressed.connect(_on_bgm_mode_pressed)
	settings_vbox.add_child(_bgm_mode_button)


func _build_song_setup_modal_ui() -> void:
	_song_modal_backdrop = ColorRect.new()
	_song_modal_backdrop.name = "SongModalBackdrop"
	_song_modal_backdrop.color = Color(0.01, 0.02, 0.05, 0.80)
	_song_modal_backdrop.visible = false
	_song_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_song_modal_backdrop.gui_input.connect(_on_modal_backdrop_gui_input)
	_safe_container.add_child(_song_modal_backdrop)

	_song_modal_panel = Panel.new()
	_song_modal_panel.name = "SongModalPanel"
	_song_modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_song_modal_panel.add_theme_stylebox_override("panel", _style_modal_panel)
	_song_modal_backdrop.add_child(_song_modal_panel)

	_modal_vbox = VBoxContainer.new()
	_modal_vbox.name = "SongModalVBox"
	_modal_vbox.add_theme_constant_override("separation", 18)
	_song_modal_panel.add_child(_modal_vbox)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.name = "ModalHeaderRow"
	header_row.add_theme_constant_override("separation", 12)
	_modal_vbox.add_child(header_row)

	_modal_song_title_label = Label.new()
	_modal_song_title_label.name = "ModalSongTitleLabel"
	_modal_song_title_label.text = "Canción"
	_modal_song_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_song_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_modal_song_title_label.clip_text = true
	_modal_song_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_modal_song_title_label.add_theme_font_size_override("font_size", MODAL_TITLE_FONT_SIZE)
	_modal_song_title_label.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	header_row.add_child(_modal_song_title_label)

	_modal_close_button = Button.new()
	_modal_close_button.name = "ModalCloseButton"
	_modal_close_button.text = "CERRAR"
	_modal_close_button.custom_minimum_size = Vector2(168.0, 72.0)
	_modal_close_button.add_theme_font_size_override("font_size", 30)
	_apply_stylebox_to_button(_modal_close_button, _style_option_inactive)
	_modal_close_button.pressed.connect(close_song_setup_modal)
	header_row.add_child(_modal_close_button)

	_modal_record_row = HBoxContainer.new()
	_modal_record_row.name = "ModalRecordRow"
	_modal_record_row.add_theme_constant_override("separation", 14)
	_modal_vbox.add_child(_modal_record_row)

	_modal_record_label = Label.new()
	_modal_record_label.name = "ModalRecordLabel"
	_modal_record_label.text = "SIN RÉCORD TODAVÍA"
	_modal_record_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_modal_record_label.add_theme_font_size_override("font_size", MODAL_RECORD_FONT_SIZE)
	_modal_record_row.add_child(_modal_record_label)

	_modal_record_rank_label = Label.new()
	_modal_record_rank_label.name = "ModalRecordRankLabel"
	_modal_record_rank_label.text = "--"
	_modal_record_rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiFontRegistry.apply_neon_rank_style(_modal_record_rank_label, "--", MODAL_RANK_FONT_SIZE)
	_modal_record_row.add_child(_modal_record_rank_label)

	_modal_record_detail_label = Label.new()
	_modal_record_detail_label.name = "ModalRecordDetailLabel"
	_modal_record_detail_label.text = ""
	_modal_record_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_modal_record_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_record_detail_label.clip_text = true
	_modal_record_detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_modal_record_detail_label.add_theme_font_size_override("font_size", MODAL_RECORD_FONT_SIZE)
	_modal_record_row.add_child(_modal_record_detail_label)

	var diff_header: Label = Label.new()
	diff_header.text = "DIFICULTAD"
	diff_header.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	diff_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	_modal_vbox.add_child(diff_header)

	var diff_row: HBoxContainer = HBoxContainer.new()
	diff_row.name = "ModalDifficultyRow"
	diff_row.add_theme_constant_override("separation", 12)
	_modal_vbox.add_child(diff_row)

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
	mode_header.text = "MODO DE NOTAS"
	mode_header.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	mode_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	_modal_vbox.add_child(mode_header)

	var mode_row: HBoxContainer = HBoxContainer.new()
	mode_row.name = "ModalNoteModeRow"
	mode_row.add_theme_constant_override("separation", 12)
	_modal_vbox.add_child(mode_row)

	_mode_tap_hold_button = _create_option_button("ModeTapHoldButton", "TAP + HOLD")
	_mode_tap_hold_button.pressed.connect(select_note_type_mode.bind(AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD))
	mode_row.add_child(_mode_tap_hold_button)

	_mode_tap_only_button = _create_option_button("ModeTapOnlyButton", "SOLO TAP")
	_mode_tap_only_button.pressed.connect(select_note_type_mode.bind(AutoChartGenerator.NoteTypeMode.TAP_ONLY))
	mode_row.add_child(_mode_tap_only_button)

	var speed_header: Label = Label.new()
	speed_header.text = "VELOCIDAD"
	speed_header.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	speed_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	_modal_vbox.add_child(speed_header)

	var speed_row: HBoxContainer = HBoxContainer.new()
	speed_row.name = "ModalSpeedRow"
	speed_row.add_theme_constant_override("separation", 12)
	_modal_vbox.add_child(speed_row)

	_speed_1x_button = _create_option_button("Speed1xButton", "1x")
	_speed_1x_button.pressed.connect(select_speed_multiplier.bind(1))
	speed_row.add_child(_speed_1x_button)

	_speed_2x_button = _create_option_button("Speed2xButton", "2x")
	_speed_2x_button.pressed.connect(select_speed_multiplier.bind(2))
	speed_row.add_child(_speed_2x_button)

	_speed_3x_button = _create_option_button("Speed3xButton", "3x")
	_speed_3x_button.pressed.connect(select_speed_multiplier.bind(3))
	speed_row.add_child(_speed_3x_button)

	_speed_4x_button = _create_option_button("Speed4xButton", "4x")
	_speed_4x_button.pressed.connect(select_speed_multiplier.bind(4))
	speed_row.add_child(_speed_4x_button)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_vbox.add_child(spacer)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", STATUS_FONT_SIZE)
	_status_label.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	_modal_vbox.add_child(_status_label)

	_play_button = Button.new()
	_play_button.name = "PlayButton"
	_play_button.text = "JUGAR"
	_play_button.custom_minimum_size = Vector2(0.0, PLAY_BUTTON_HEIGHT_PX)
	_play_button.add_theme_font_size_override("font_size", PRIMARY_BUTTON_FONT_SIZE)
	_play_button.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	_apply_stylebox_to_button(_play_button, _style_play_cta)
	_play_button.pressed.connect(_on_play_button_pressed)
	_modal_vbox.add_child(_play_button)


func _build_exit_confirm_modal_ui() -> void:
	_exit_confirm_backdrop = ColorRect.new()
	_exit_confirm_backdrop.name = "ExitConfirmBackdrop"
	_exit_confirm_backdrop.color = Color(0.01, 0.02, 0.06, 0.84)
	_exit_confirm_backdrop.visible = false
	_exit_confirm_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_exit_confirm_backdrop.gui_input.connect(_on_exit_confirm_backdrop_gui_input)
	_safe_container.add_child(_exit_confirm_backdrop)

	_exit_confirm_panel = PanelContainer.new()
	_exit_confirm_panel.name = "ExitConfirmPanel"
	_exit_confirm_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_exit_confirm_panel.add_theme_stylebox_override("panel", _style_modal_panel)
	_exit_confirm_backdrop.add_child(_exit_confirm_panel)

	var exit_margin: MarginContainer = MarginContainer.new()
	exit_margin.name = "ExitConfirmMargin"
	exit_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exit_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exit_margin.add_theme_constant_override("margin_left", 36)
	exit_margin.add_theme_constant_override("margin_right", 36)
	exit_margin.add_theme_constant_override("margin_top", 40)
	exit_margin.add_theme_constant_override("margin_bottom", 40)
	_exit_confirm_panel.add_child(exit_margin)

	var exit_vbox: VBoxContainer = VBoxContainer.new()
	exit_vbox.name = "ExitConfirmVBox"
	exit_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	exit_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exit_vbox.add_theme_constant_override("separation", 34)
	exit_margin.add_child(exit_vbox)

	_exit_confirm_title = Label.new()
	_exit_confirm_title.name = "ExitConfirmTitleLabel"
	_exit_confirm_title.text = "¿SALIR DE FEEL YOUR BEATS?"
	_exit_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exit_confirm_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_exit_confirm_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_exit_confirm_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exit_confirm_title.add_theme_font_size_override("font_size", 42)
	_exit_confirm_title.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	exit_vbox.add_child(_exit_confirm_title)

	var buttons_row: HBoxContainer = HBoxContainer.new()
	buttons_row.name = "ExitConfirmButtonsRow"
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons_row.add_theme_constant_override("separation", 24)
	exit_vbox.add_child(buttons_row)

	_exit_cancel_button = Button.new()
	_exit_cancel_button.name = "ExitConfirmCancelButton"
	_exit_cancel_button.text = "CANCELAR"
	_exit_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exit_cancel_button.custom_minimum_size = Vector2(0.0, 96.0)
	_exit_cancel_button.add_theme_font_size_override("font_size", 36)
	_exit_cancel_button.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	_apply_stylebox_to_button(_exit_cancel_button, _style_option_active)
	_exit_cancel_button.pressed.connect(_on_exit_confirm_cancel_pressed)
	buttons_row.add_child(_exit_cancel_button)

	_exit_confirm_button = Button.new()
	_exit_confirm_button.name = "ExitConfirmQuitButton"
	_exit_confirm_button.text = "SALIR"
	_exit_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exit_confirm_button.custom_minimum_size = Vector2(0.0, 96.0)
	_exit_confirm_button.add_theme_font_size_override("font_size", 36)
	_exit_confirm_button.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	_apply_stylebox_to_button(_exit_confirm_button, _style_exit_danger)
	_exit_confirm_button.pressed.connect(_on_exit_confirm_quit_pressed)
	buttons_row.add_child(_exit_confirm_button)


func _create_tab_button(p_name: String, p_text: String) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.text = p_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, 84.0)
	btn.add_theme_font_size_override("font_size", TAB_FONT_SIZE)
	return btn


func _create_option_button(p_name: String, p_text: String) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.text = p_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, MODAL_OPTION_HEIGHT_PX)
	btn.add_theme_font_size_override("font_size", MODAL_OPTION_FONT_SIZE)
	return btn
