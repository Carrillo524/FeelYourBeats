class_name MainMenu
extends Control

enum MenuTab {
	SONGS = 0,
	IMPORT = 1,
	SETTINGS = 2,
}

const GAME_SESSION_SCENE_PATH: String = "res://ui/game_session.tscn"
const SONGS_DIR_PATH: String = "res://assets/songs"
const IMPORTED_SONGS_DIR_PATH: String = "user://imported_songs"
const ANDROID_SHARED_STORAGE_DIR: String = "/storage/emulated/0"
const RECENT_TRACKS_CONFIG_PATH: String = "user://recent_tracks.cfg"
const MAX_RECENT_TRACKS: int = 32
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
const STARTUP_INTRO_Z_INDEX: int = 95
const STARTUP_INTRO_VEIL_SEC: float = 0.80
const STARTUP_INTRO_TITLE_DELAY_SEC: float = 0.36
const STARTUP_INTRO_TITLE_DURATION_SEC: float = 1.20
const STARTUP_INTRO_WAVE_DELAY_SEC: float = 0.56
const STARTUP_INTRO_WAVE_SEC: float = 1.44
const STARTUP_INTRO_PRIMARY_DELAY_SEC: float = 1.08
const STARTUP_INTRO_PRIMARY_DURATION_SEC: float = 1.08
const STARTUP_INTRO_SECONDARY_DELAY_SEC: float = 1.64
const STARTUP_INTRO_TOTAL_SEC: float = 3.00
const STARTUP_INTRO_TITLE_OFFSET_Y_PX: float = 22.0
const PHOTOSENSITIVITY_Z_INDEX: int = 110
const PHOTOSENSITIVITY_FADE_IN_SEC: float = 0.45
const PHOTOSENSITIVITY_HOLD_SEC: float = 3.95
const PHOTOSENSITIVITY_FADE_OUT_SEC: float = 0.60
const PHOTOSENSITIVITY_TOTAL_SEC: float = 5.00
const PHOTOSENSITIVITY_TAP_ENABLE_SEC: float = 1.50
const PHOTOSENSITIVITY_SKIP_FADE_SEC: float = 0.25
const PHOTOSENSITIVITY_HINT_FADE_SEC: float = 0.35
const PHOTOSENSITIVITY_SIDE_MARGIN_PX: float = 48.0
const PHOTOSENSITIVITY_TITLE_FONT_SIZE: int = 50
const PHOTOSENSITIVITY_BODY_FONT_SIZE: int = 34
const PHOTOSENSITIVITY_HINT_FONT_SIZE: int = 28
const PHOTOSENSITIVITY_ICON_HEIGHT_PX: float = 176.0
const PHOTOSENSITIVITY_TITLE_TEXT: String = "AVISO DE FOTOSENSIBILIDAD"
const PHOTOSENSITIVITY_BODY_TEXT: String = "Este juego contiene destellos luminosos, patrones de alto contraste y efectos visuales rítmicos que pueden provocar molestias o crisis en personas con epilepsia fotosensible. Si experimentas mareos, alteraciones visuales o malestar, detén el juego de inmediato."
const PHOTOSENSITIVITY_HINT_TEXT: String = "Toca para continuar"
const COLOR_PHOTOSENSITIVITY_AMBER: Color = Color(1.0, 0.78, 0.32, 1.0)
const COLOR_PHOTOSENSITIVITY_CYAN_GLOW: Color = Color(0.38, 0.92, 1.0, 0.22)
const COLOR_PHOTOSENSITIVITY_BODY: Color = Color(0.88, 0.92, 0.98, 1.0)
const COLOR_PHOTOSENSITIVITY_HINT: Color = Color(0.58, 0.62, 0.68, 1.0)
const LOADING_OVERLAY_Z_INDEX: int = 90
const TOUCH_PREVIEW_Z_INDEX: int = 85
const MAX_MENU_TOUCH_PREVIEWS: int = 12
const BGM_FADEOUT_DURATION_SEC: float = 0.35
const USEC_TO_SEC: float = 0.000001
const BACK_DEBOUNCE_MSEC: int = 300
const TOUCH_SCROLL_DEADZONE_PX: int = 20
const TOUCH_SCROLL_DRAG_THRESHOLD_PX: float = 18.0
const TAB_SLIDE_MAIN_DURATION_SEC: float = 0.17
const TAB_SLIDE_SETTLE_DURATION_SEC: float = 0.05
const TAB_SLIDE_OVERSHOOT_PX: float = 10.0
const TAB_INDICATOR_HEIGHT_PX: float = 5.0

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
static var _has_played_startup_intro: bool = false
static var _has_shown_photosensitivity_warning: bool = false


static func reset_startup_intro_for_tests() -> void:
	_has_played_startup_intro = false
	_has_shown_photosensitivity_warning = false


static func has_shown_photosensitivity_warning() -> bool:
	return _has_shown_photosensitivity_warning


static func has_played_startup_intro() -> bool:
	return _has_played_startup_intro

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
@export var reactive_particles_layer: ReactiveParticlesLayer = null
@export var menu_bgm_player: MenuBgmPlayer = null
@export var ui_sfx_player: UiSfxPlayer = null
@export var audio_analyzer: AudioAnalyzer = null
@export var particles_settings_path: String = ReactiveParticlesConfig.DEFAULT_SETTINGS_PATH
@export var background_settings_path: String = ReactiveBackgroundConfig.DEFAULT_SETTINGS_PATH
@export var effects_settings_path: String = GameplayEffectsConfig.DEFAULT_SETTINGS_PATH
@export var allow_scene_change: bool = true

var _chart_cache_repo: ChartCacheRepository = ChartCacheRepository.new()
var _particles_config: ReactiveParticlesConfig = ReactiveParticlesConfig.new()
var _bg_config: ReactiveBackgroundConfig = ReactiveBackgroundConfig.new()
var _effects_config: GameplayEffectsConfig = GameplayEffectsConfig.new()
var _font_registry: UiFontRegistry = null
var _recent_tracks_path: String = RECENT_TRACKS_CONFIG_PATH
var _imported_songs_dir: String = IMPORTED_SONGS_DIR_PATH

var _safe_container: Control = null

# Screen 1: Title Screen
var _title_screen_container: Control = null
var _hero_title_label: Label = null
var _hero_subtitle_label: Label = null
var _hero_play_button: Button = null

# Screen 2: Tabbed Browser
var _browser_screen_container: VBoxContainer = null
var _browser_header_label: Label = null
var _tabs_bar_wrapper: Control = null
var _tabs_row: HBoxContainer = null
var _tab_indicator_bar: Panel = null
var _tab_songs_button: Button = null
var _tab_import_button: Button = null
var _tab_settings_button: Button = null
var _content_sheet_panel: PanelContainer = null
var _tab_content_viewport: Control = null

var _songs_tab_container: Control = null
var _songs_scroll: ScrollContainer = null
var _songs_list_vbox: VBoxContainer = null

var _import_tab_container: Control = null
var _import_scroll: ScrollContainer = null
var _browse_button: Button = null
var _import_status_label: Label = null
var _import_list_vbox: VBoxContainer = null

var _settings_tab_container: Control = null
var _settings_scroll: ScrollContainer = null
var _bgm_toggle_button: Button = null
var _bgm_track_label: Label = null
var _bgm_prev_button: Button = null
var _bgm_next_button: Button = null
var _bgm_mode_button: Button = null
var _particles_type_buttons: Dictionary = {}
var _particles_density_label: Label = null
var _particles_density_row: HBoxContainer = null
var _particles_density_buttons: Dictionary = {}
var _particles_reactivity_label: Label = null
var _particles_reactivity_row: HBoxContainer = null
var _particles_reactivity_buttons: Dictionary = {}
var _bg_style_buttons: Dictionary = {}
var _bg_reactivity_buttons: Dictionary = {}
var _hit_effect_buttons: Dictionary = {}
var _touch_effect_buttons: Dictionary = {}
var _vanish_effect_buttons: Dictionary = {}

# Immediate touch effect preview overlay (fixed pool, 0 allocs/frame)
var _touch_preview_layer: Control = null
var _touch_preview_renderer: TouchEffectRenderer = TouchEffectRenderer.new()
var _tp_active: PackedByteArray = PackedByteArray()
var _tp_age: PackedFloat32Array = PackedFloat32Array()
var _tp_duration: PackedFloat32Array = PackedFloat32Array()
var _tp_pos: PackedVector2Array = PackedVector2Array()
var _tp_variant: PackedInt32Array = PackedInt32Array()
var _tp_cursor: int = 0
var _tp_seed: int = 1
var _last_touch_preview_msec: int = -100
var _is_app_backgrounded: bool = false
var _master_was_muted_before_bg: bool = false
var _background_paused_players: Array[AudioStreamPlayer] = []

# Floating Song Setup Modal
var _song_modal_backdrop: ColorRect = null
var _song_modal_panel: Panel = null
var _modal_scroll: ScrollContainer = null
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
var _mode_double_tap_button: Button = null
var _mode_hold_double_tap_button: Button = null
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

# Non-blocking Song Processing Loading Overlay
var _loading_overlay: ColorRect = null
var _loading_panel: PanelContainer = null
var _loading_spinner: Control = null
var _loading_title_label: Label = null
var _loading_stage_label: Label = null
var _loading_progress_track: Panel = null
var _loading_progress_fill: Panel = null
var _loading_percent_label: Label = null

var _file_dialog: FileDialog = null
var _transition_fade_rect: ColorRect = null
var _transition_tween: Tween = null
var _intro_overlay: Control = null
var _intro_veil_rect: ColorRect = null
var _intro_wave_fx: Control = null
var _intro_tween: Tween = null

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
var _style_loading_track: StyleBoxFlat = null
var _style_loading_fill: StyleBoxFlat = null
var _style_tab_indicator: StyleBoxFlat = null

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
var _is_processing_song: bool = false
var _is_playing_startup_intro: bool = false
var _is_tab_transitioning: bool = false
var _tab_transition_tween: Tween = null
var _tab_transition_outgoing: Control = null
var _tab_transition_incoming: Control = null
var _intro_wave_progress: float = 0.0
var _intro_wave_center: Vector2 = Vector2.ZERO
var _is_showing_photosensitivity_warning: bool = false
var _is_skipping_photosensitivity_warning: bool = false
var _photosensitivity_elapsed_sec: float = 0.0
var _photosensitivity_hint_revealed: bool = false
var _photosensitivity_overlay: Control = null
var _photosensitivity_content: VBoxContainer = null
var _photosensitivity_icon: Control = null
var _photosensitivity_hint_label: Label = null
var _photosensitivity_tween: Tween = null
var _photosensitivity_hint_tween: Tween = null
var _pending_import_after_permission: bool = false
var _last_back_msec: int = -BACK_DEBOUNCE_MSEC
var _active_worker_task_id: int = -1
var _active_processing_job_id: int = 0
var _loading_anim_phase: float = 0.0
var _loading_target_progress: float = -1.0
var _loading_display_progress: float = 0.0
var _loading_indeterminate_phase: float = 0.0

var _touch_scroll_containers: Array[ScrollContainer] = []
var _active_scroll_touch_index: int = -1
var _active_scroll_container: ScrollContainer = null
var _touch_scroll_start_pos: Vector2 = Vector2.ZERO
var _touch_scroll_last_pos: Vector2 = Vector2.ZERO
var _touch_scroll_start_v: int = 0
var _touch_scroll_accum_y: float = 0.0
var _touch_scroll_drag_active: bool = false
var _suppress_scroll_button_press: bool = false

var _pulse_phase: float = 0.0
var _title_bass_boost: float = 0.0
var _live_menu_bass: float = 0.0
var _last_launch_sequence: Array[String] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_touch_preview_pool()


func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.set_quit_on_go_back(false)
		tree.set_auto_accept_quit(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_theme_styles()
	_resolve_scene_nodes()
	_ensure_ui_nodes()
	_apply_external_fonts()
	_connect_dependencies()
	reload_gameplay_effects_settings()
	_reload_all_track_lists()
	_refresh_tab_visuals()
	_refresh_modal_option_styles()
	_refresh_bgm_controls()
	_refresh_particle_controls()
	_refresh_background_controls()
	_refresh_gameplay_effects_controls()
	_sync_live_audio_monitoring()
	var returning_to_selector: bool = open_directly_to_selector
	if open_directly_to_selector:
		open_directly_to_selector = false
		show_browser_screen(MenuTab.SONGS)
	else:
		show_title_screen()

	if screen_safe_adapter != null:
		apply_hud_safe_rect(screen_safe_adapter.get_hud_safe_rect())
	else:
		apply_hud_safe_rect(Rect2(64.8, 0.0, 950.4, 1920.0))

	if returning_to_selector:
		_has_played_startup_intro = true
		_has_shown_photosensitivity_warning = true
	elif not _has_played_startup_intro:
		if not _has_shown_photosensitivity_warning:
			# Initial app launch only: black photosensitivity warning holds the 3.0s intro
			_start_photosensitivity_warning()
		else:
			_start_startup_intro()


func _process(p_delta: float) -> void:
	var dt: float = maxf(0.0, p_delta)
	if _is_showing_photosensitivity_warning:
		_step_photosensitivity_warning(dt)
	_pulse_phase += dt * 2.8
	_title_bass_boost = maxf(0.0, _title_bass_boost - (4.8 * dt))
	_live_menu_bass = maxf(0.0, _live_menu_bass - (3.8 * dt))

	var bgm_active: bool = menu_bgm_player != null and menu_bgm_player.is_bgm_enabled and menu_bgm_player.get_track_count() > 0
	var combined_energy: float = clampf(maxf(_title_bass_boost, _live_menu_bass), 0.0, 1.0) if bgm_active else 0.0

	if _title_screen_container != null and _title_screen_container.visible and not _is_playing_startup_intro:
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

	if _loading_overlay != null and _loading_overlay.visible:
		_step_loading_overlay_animation(dt)

	_step_touch_preview_pool(dt)


func _exit_tree() -> void:
	if _active_worker_task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_active_worker_task_id)
		_active_worker_task_id = -1
	_kill_photosensitivity_tweens()
	if _intro_tween != null:
		_intro_tween.kill()
		_intro_tween = null
	if _tab_transition_tween != null:
		_tab_transition_tween.kill()
		_tab_transition_tween = null
	if _transition_tween != null:
		_transition_tween.kill()
		_transition_tween = null
	if _is_app_backgrounded:
		AudioServer.set_bus_mute(0, _master_was_muted_before_bg)
		_is_app_backgrounded = false
	_background_paused_players.clear()


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_WM_CLOSE_REQUEST:
			handle_back_request()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_handle_app_backgrounded()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_handle_app_foregrounded()


func _collect_menu_audio_players() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = []
	_append_audio_players_recursive(self, players)
	return players


func _append_audio_players_recursive(p_node: Node, p_out: Array[AudioStreamPlayer]) -> void:
	if p_node == null:
		return
	if p_node is AudioStreamPlayer:
		var ap: AudioStreamPlayer = p_node as AudioStreamPlayer
		if not p_out.has(ap):
			p_out.append(ap)
	var children: Array[Node] = p_node.get_children()
	for i: int in range(children.size()):
		_append_audio_players_recursive(children[i], p_out)


func _handle_app_backgrounded() -> void:
	if _is_app_backgrounded:
		AudioServer.set_bus_mute(0, true)
		return
	_is_app_backgrounded = true
	_master_was_muted_before_bg = AudioServer.is_bus_mute(0)
	_background_paused_players.clear()

	var players: Array[AudioStreamPlayer] = _collect_menu_audio_players()
	for i: int in range(players.size()):
		var ap: AudioStreamPlayer = players[i]
		if ap != null and ap.playing and not ap.stream_paused:
			ap.stream_paused = true
			_background_paused_players.append(ap)

	AudioServer.set_bus_mute(0, true)


func _handle_app_foregrounded() -> void:
	if not _is_app_backgrounded:
		return
	_is_app_backgrounded = false
	AudioServer.set_bus_mute(0, _master_was_muted_before_bg)

	var bgm_audio_player: AudioStreamPlayer = null
	if menu_bgm_player != null:
		bgm_audio_player = menu_bgm_player.get_node_or_null("MenuBgmAudioPlayer") as AudioStreamPlayer

	for i: int in range(_background_paused_players.size()):
		var ap: AudioStreamPlayer = _background_paused_players[i]
		if not is_instance_valid(ap):
			continue
		if ap == bgm_audio_player and menu_bgm_player != null and not menu_bgm_player.is_bgm_enabled:
			continue
		ap.stream_paused = false

	_background_paused_players.clear()


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
		return

	if _is_showing_photosensitivity_warning:
		_handle_photosensitivity_input(p_event)
		return

	if not _is_playing_startup_intro:
		if p_event is InputEventScreenTouch:
			var st: InputEventScreenTouch = p_event as InputEventScreenTouch
			if st.pressed:
				_last_touch_preview_msec = Time.get_ticks_msec()
				spawn_touch_effect_preview(st.position)
		elif p_event is InputEventMouseButton:
			var mb: InputEventMouseButton = p_event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				var now_msec: int = Time.get_ticks_msec()
				if now_msec - _last_touch_preview_msec > 30:
					spawn_touch_effect_preview(mb.position)

	_handle_touch_scroll_input(p_event)


func _configure_touch_scroll_container(p_scroll: ScrollContainer) -> void:
	if p_scroll == null:
		return
	p_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	p_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p_scroll.scroll_deadzone = TOUCH_SCROLL_DEADZONE_PX
	p_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	if not _touch_scroll_containers.has(p_scroll):
		_touch_scroll_containers.append(p_scroll)
	_apply_scroll_children_mouse_filter(p_scroll)


func _apply_scroll_children_mouse_filter(p_root: Node) -> void:
	if p_root == null:
		return
	var children: Array[Node] = p_root.get_children()
	for i: int in range(children.size()):
		var child: Node = children[i]
		if child is BaseButton:
			var btn: BaseButton = child as BaseButton
			btn.mouse_filter = Control.MOUSE_FILTER_PASS
		elif child is Control:
			var ctrl: Control = child as Control
			if ctrl.mouse_filter == Control.MOUSE_FILTER_STOP:
				ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
		_apply_scroll_children_mouse_filter(child)


func get_touch_scroll_containers() -> Array[ScrollContainer]:
	return _touch_scroll_containers


func _reset_touch_scroll_state() -> void:
	_active_scroll_touch_index = -1
	_active_scroll_container = null
	_touch_scroll_start_pos = Vector2.ZERO
	_touch_scroll_last_pos = Vector2.ZERO
	_touch_scroll_start_v = 0
	_touch_scroll_accum_y = 0.0
	_touch_scroll_drag_active = false
	_suppress_scroll_button_press = false


func _find_touch_scroll_container_at(p_pos: Vector2) -> ScrollContainer:
	if _is_launching or _is_processing_song or _is_playing_startup_intro or _is_tab_transitioning:
		return null
	if is_loading_overlay_visible():
		return null
	if is_exit_confirm_modal_open():
		return null
	if _file_dialog != null and _file_dialog.visible:
		return null

	if is_song_modal_open():
		if _modal_scroll != null and _modal_scroll.is_visible_in_tree() and _modal_scroll.get_global_rect().has_point(p_pos):
			return _modal_scroll
		return null

	for i: int in range(_touch_scroll_containers.size()):
		var candidate: ScrollContainer = _touch_scroll_containers[i]
		if candidate == null or candidate == _modal_scroll:
			continue
		if candidate.is_visible_in_tree() and candidate.get_global_rect().has_point(p_pos):
			return candidate
	return null


func _get_scroll_max_vertical(p_scroll: ScrollContainer) -> int:
	if p_scroll == null or p_scroll.get_child_count() == 0:
		return 0
	var content_node: Control = p_scroll.get_child(0) as Control
	if content_node == null:
		return 0
	var content_h: float = maxf(content_node.size.y, content_node.get_combined_minimum_size().y)
	var viewport_h: float = p_scroll.size.y
	if viewport_h <= 0.0:
		return 0
	return maxi(0, int(ceil(content_h - viewport_h)))


func _handle_touch_scroll_input(p_event: InputEvent) -> void:
	if p_event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = p_event as InputEventScreenTouch
		if touch.pressed:
			_suppress_scroll_button_press = false
			_touch_scroll_drag_active = false
			_touch_scroll_accum_y = 0.0
			var target_scroll: ScrollContainer = _find_touch_scroll_container_at(touch.position)
			if target_scroll != null:
				_active_scroll_touch_index = touch.index
				_active_scroll_container = target_scroll
				_touch_scroll_start_pos = touch.position
				_touch_scroll_last_pos = touch.position
				_touch_scroll_start_v = target_scroll.scroll_vertical
			else:
				_active_scroll_touch_index = -1
				_active_scroll_container = null
		elif touch.index == _active_scroll_touch_index:
			_suppress_scroll_button_press = _touch_scroll_drag_active
			_active_scroll_touch_index = -1
			_active_scroll_container = null
			_touch_scroll_drag_active = false
		UiSfxPlayer.set_touch_scroll_suppressed(_touch_scroll_drag_active or _suppress_scroll_button_press)
		return

	if p_event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = p_event as InputEventScreenDrag
		if drag.index != _active_scroll_touch_index or _active_scroll_container == null:
			return
		var step_y: float = drag.position.y - _touch_scroll_last_pos.y
		if absf(step_y) < 0.001 and absf(drag.relative.y) > 0.001:
			step_y = drag.relative.y
		_touch_scroll_last_pos = drag.position
		_touch_scroll_accum_y += absf(step_y)
		var net_y: float = drag.position.y - _touch_scroll_start_pos.y
		var effective_travel: float = maxf(_touch_scroll_accum_y, absf(net_y))

		if effective_travel > TOUCH_SCROLL_DRAG_THRESHOLD_PX:
			_touch_scroll_drag_active = true
			_suppress_scroll_button_press = true
			var max_v: int = _get_scroll_max_vertical(_active_scroll_container)
			if max_v > 0:
				var target_v: int = clampi(_touch_scroll_start_v - int(round(net_y)), 0, max_v)
				_active_scroll_container.scroll_vertical = target_v
			else:
				_active_scroll_container.scroll_vertical = 0
			var vp: Viewport = get_viewport()
			if vp != null:
				vp.set_input_as_handled()
		UiSfxPlayer.set_touch_scroll_suppressed(_touch_scroll_drag_active or _suppress_scroll_button_press)
		return

	if p_event is InputEventMouseButton:
		var mb: InputEventMouseButton = p_event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _active_scroll_touch_index == -1:
			_suppress_scroll_button_press = false
	UiSfxPlayer.set_touch_scroll_suppressed(_touch_scroll_drag_active or _suppress_scroll_button_press)


func _consume_suppressed_scroll_press() -> bool:
	if _touch_scroll_drag_active or _suppress_scroll_button_press:
		_suppress_scroll_button_press = false
		UiSfxPlayer.set_touch_scroll_suppressed(_touch_scroll_drag_active)
		return true
	UiSfxPlayer.set_touch_scroll_suppressed(false)
	return false


func _on_song_row_pressed(p_entry: Dictionary) -> void:
	if _is_playing_startup_intro:
		return
	if _consume_suppressed_scroll_press():
		return
	open_song_setup_modal(p_entry)


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
	if _is_launching or _is_processing_song or _is_playing_startup_intro or _is_showing_photosensitivity_warning:
		return
	if not _consume_back_debounce(p_now_msec):
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

	var modal_inner_w: float = maxf(240.0, modal_w - 52.0)
	var modal_inner_h: float = maxf(400.0, modal_h - 48.0)
	if _modal_scroll != null:
		_modal_scroll.position = Vector2(26.0, 24.0)
		_modal_scroll.size = Vector2(modal_inner_w, modal_inner_h)
		_modal_vbox.custom_minimum_size = Vector2(0.0, modal_inner_h)
	else:
		_modal_vbox.position = Vector2(26.0, 24.0)
		_modal_vbox.size = Vector2(modal_inner_w, modal_inner_h)

	if _exit_confirm_backdrop != null:
		_exit_confirm_backdrop.position = Vector2.ZERO
		_exit_confirm_backdrop.size = Vector2(safe_w, safe_h)

	_layout_exit_confirm_panel(safe_w, safe_h)
	_layout_loading_overlay(safe_w, safe_h)
	if not _is_tab_transitioning:
		_sync_all_tab_panel_geometries()
		call_deferred(&"_snap_tab_indicator_to_active")


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
	_reset_touch_scroll_state()
	_title_screen_container.visible = true
	_browser_screen_container.visible = false
	_song_modal_backdrop.visible = false
	if _exit_confirm_backdrop != null:
		_exit_confirm_backdrop.visible = false


func show_browser_screen(p_tab: int = MenuTab.SONGS) -> void:
	_ensure_ui_nodes()
	_reset_touch_scroll_state()
	_cancel_tab_transition_immediately()
	_title_screen_container.visible = false
	_browser_screen_container.visible = true
	_song_modal_backdrop.visible = false
	if _exit_confirm_backdrop != null:
		_exit_confirm_backdrop.visible = false
	select_tab(p_tab, false)


func select_tab(p_tab: int, p_animate: bool = true) -> void:
	if _is_playing_startup_intro or _is_processing_song or _is_launching:
		return
	if _is_tab_transitioning:
		return

	var target_tab: int = clampi(p_tab, MenuTab.SONGS, MenuTab.SETTINGS)
	var old_tab: int = _active_tab
	_reset_touch_scroll_state()

	var can_animate: bool = (
		p_animate
		and old_tab != target_tab
		and _browser_screen_container != null
		and _browser_screen_container.visible
		and _tab_content_viewport != null
		and is_inside_tree()
	)

	_active_tab = target_tab
	if _active_tab == MenuTab.SONGS:
		_reset_marquee_items(_songs_marquee_items)
	elif _active_tab == MenuTab.IMPORT:
		_reset_marquee_items(_imported_marquee_items)

	if not can_animate:
		_refresh_tab_visuals()
		_sync_all_tab_panel_geometries()
		call_deferred(&"_snap_tab_indicator_to_active")
		return

	_start_tab_transition(old_tab, target_tab)


func is_tab_transitioning() -> bool:
	return _is_tab_transitioning


func get_tab_indicator_bar() -> Panel:
	return _tab_indicator_bar


func get_tab_content_viewport() -> Control:
	return _tab_content_viewport


func _get_tab_container(p_tab: int) -> Control:
	match p_tab:
		MenuTab.SONGS:
			return _songs_tab_container
		MenuTab.IMPORT:
			return _import_tab_container
		MenuTab.SETTINGS:
			return _settings_tab_container
		_:
			return _songs_tab_container


func _get_tab_button(p_tab: int) -> Button:
	match p_tab:
		MenuTab.SONGS:
			return _tab_songs_button
		MenuTab.IMPORT:
			return _tab_import_button
		MenuTab.SETTINGS:
			return _tab_settings_button
		_:
			return _tab_songs_button


func _restore_tab_panel_geometry(p_panel: Control) -> void:
	if p_panel == null:
		return
	p_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p_panel.position = Vector2.ZERO
	if _tab_content_viewport != null and _tab_content_viewport.size.x > 1.0 and _tab_content_viewport.size.y > 1.0:
		p_panel.size = _tab_content_viewport.size


func _sync_all_tab_panel_geometries() -> void:
	_restore_tab_panel_geometry(_songs_tab_container)
	_restore_tab_panel_geometry(_import_tab_container)
	_restore_tab_panel_geometry(_settings_tab_container)


func _snap_tab_indicator_to_active() -> void:
	if _tab_indicator_bar == null or _tabs_row == null:
		return
	var active_btn: Button = _get_tab_button(_active_tab)
	if active_btn == null:
		return
	var btn_w: float = active_btn.size.x
	var btn_x: float = active_btn.position.x
	if btn_w <= 1.0 and _tabs_bar_wrapper != null and _tabs_bar_wrapper.size.x > 1.0:
		var slot_w: float = (_tabs_bar_wrapper.size.x - 20.0) / 3.0
		btn_w = maxf(40.0, slot_w)
		btn_x = float(_active_tab) * (slot_w + 10.0)
	_tab_indicator_bar.position = Vector2(btn_x, 85.0)
	_tab_indicator_bar.size = Vector2(maxf(24.0, btn_w), TAB_INDICATOR_HEIGHT_PX)


func _cancel_tab_transition_immediately() -> void:
	if _tab_transition_tween != null:
		_tab_transition_tween.kill()
		_tab_transition_tween = null
	_is_tab_transitioning = false
	_tab_transition_outgoing = null
	_tab_transition_incoming = null
	_sync_all_tab_panel_geometries()


func _start_tab_transition(p_old_tab: int, p_new_tab: int) -> void:
	var outgoing: Control = _get_tab_container(p_old_tab)
	var incoming: Control = _get_tab_container(p_new_tab)
	if outgoing == null or incoming == null or outgoing == incoming:
		_refresh_tab_visuals()
		_sync_all_tab_panel_geometries()
		_snap_tab_indicator_to_active()
		return

	_is_tab_transitioning = true
	_tab_transition_outgoing = outgoing
	_tab_transition_incoming = incoming

	# Update tab button highlights immediately while indicator bar slides smoothly
	_set_option_highlight(_tab_songs_button, p_new_tab == MenuTab.SONGS)
	_set_option_highlight(_tab_import_button, p_new_tab == MenuTab.IMPORT)
	_set_option_highlight(_tab_settings_button, p_new_tab == MenuTab.SETTINGS)

	# Hide any non-participating tab (e.g. IMPORT when jumping SONGS <-> SETTINGS)
	var all_tabs: Array[Control] = [_songs_tab_container, _import_tab_container, _settings_tab_container]
	for i: int in range(all_tabs.size()):
		var tab_ctrl: Control = all_tabs[i]
		if tab_ctrl != null and tab_ctrl != outgoing and tab_ctrl != incoming:
			tab_ctrl.visible = false
			_restore_tab_panel_geometry(tab_ctrl)

	var vp_size: Vector2 = _tab_content_viewport.size
	var slide_w: float = maxf(240.0, vp_size.x)
	var direction: float = 1.0 if p_new_tab > p_old_tab else -1.0
	var overshoot_x: float = -direction * TAB_SLIDE_OVERSHOOT_PX

	_restore_tab_panel_geometry(outgoing)
	_restore_tab_panel_geometry(incoming)
	outgoing.visible = true
	incoming.visible = true
	outgoing.position.x = 0.0
	incoming.position.x = direction * slide_w

	# Ensure indicator bar starts from old tab button position
	var old_btn: Button = _get_tab_button(p_old_tab)
	var new_btn: Button = _get_tab_button(p_new_tab)
	if _tab_indicator_bar != null and old_btn != null and old_btn.size.x > 1.0:
		_tab_indicator_bar.position = Vector2(old_btn.position.x, 85.0)
		_tab_indicator_bar.size = Vector2(old_btn.size.x, TAB_INDICATOR_HEIGHT_PX)

	if _tab_transition_tween != null:
		_tab_transition_tween.kill()
		_tab_transition_tween = null

	_tab_transition_tween = create_tween()
	_tab_transition_tween.set_parallel(true)

	# Phase A (170ms): Horizontal directional slide + subtle overshoot (10px)
	_tab_transition_tween.tween_property(
		outgoing,
		"position:x",
		-direction * slide_w,
		TAB_SLIDE_MAIN_DURATION_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_tab_transition_tween.tween_property(
		incoming,
		"position:x",
		overshoot_x,
		TAB_SLIDE_MAIN_DURATION_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Sliding neon indicator bar across total 220ms
	if _tab_indicator_bar != null and new_btn != null:
		var target_x: float = new_btn.position.x
		var target_w: float = new_btn.size.x
		if target_w <= 1.0 and _tabs_bar_wrapper != null and _tabs_bar_wrapper.size.x > 1.0:
			var slot_w: float = (_tabs_bar_wrapper.size.x - 20.0) / 3.0
			target_w = maxf(40.0, slot_w)
			target_x = float(p_new_tab) * (slot_w + 10.0)
		var total_dur: float = TAB_SLIDE_MAIN_DURATION_SEC + TAB_SLIDE_SETTLE_DURATION_SEC
		_tab_transition_tween.tween_property(
			_tab_indicator_bar,
			"position:x",
			target_x,
			total_dur
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tab_transition_tween.tween_property(
			_tab_indicator_bar,
			"size:x",
			maxf(24.0, target_w),
			total_dur
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Phase B (50ms): Quick settle from overshoot back to exact x == 0.0
	_tab_transition_tween.tween_property(
		incoming,
		"position:x",
		0.0,
		TAB_SLIDE_SETTLE_DURATION_SEC
	).set_delay(TAB_SLIDE_MAIN_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_tab_transition_tween.chain().tween_callback(_finish_tab_transition)


func _finish_tab_transition() -> void:
	var outgoing: Control = _tab_transition_outgoing
	var incoming: Control = _tab_transition_incoming
	_tab_transition_tween = null
	_tab_transition_outgoing = null
	_tab_transition_incoming = null
	_is_tab_transitioning = false

	if outgoing != null and outgoing != incoming:
		outgoing.visible = false
		_restore_tab_panel_geometry(outgoing)

	_refresh_tab_visuals()
	_sync_all_tab_panel_geometries()
	_snap_tab_indicator_to_active()


func _on_tab_viewport_resized() -> void:
	if not _is_tab_transitioning:
		_sync_all_tab_panel_geometries()
		_snap_tab_indicator_to_active()


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
	if _is_launching or _is_processing_song:
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
	_reset_touch_scroll_state()
	if p_entry.is_empty():
		return
	_selected_entry = p_entry.duplicate()
	var is_demo: bool = _selected_entry.get("is_demo", false) as bool
	var title_resolved: bool = _selected_entry.get("title_resolved", false) as bool
	var audio_path: String = str(_selected_entry.get("audio_path", ""))
	var raw_title: String = str(_selected_entry.get("title", "")).strip_edges()
	var display_title: String = raw_title
	if is_demo or (title_resolved and not raw_title.is_empty()):
		display_title = raw_title if not raw_title.is_empty() else "Pista"
	elif not raw_title.is_empty():
		display_title = _format_song_display_title(raw_title)
	elif not audio_path.is_empty():
		display_title = _format_song_display_title(audio_path)
	else:
		display_title = "Pista"
	_selected_entry["title"] = display_title
	_modal_song_title_label.text = display_title
	_refresh_modal_record_label()
	_refresh_modal_option_styles()
	if _status_label != null:
		_status_label.text = ""
	if _play_button != null and not _is_launching:
		_play_button.disabled = false
	_song_modal_backdrop.visible = true


func close_song_setup_modal() -> void:
	if _is_launching or _is_processing_song:
		return
	_reset_touch_scroll_state()
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
		AutoChartGenerator.NoteTypeMode.HOLD_AND_DOUBLE_TAP
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


func import_external_track_to_storage(p_source_path: String) -> Dictionary:
	var cleaned: String = p_source_path.strip_edges()
	if cleaned.is_empty():
		return {"ok": false, "error": "Ruta de archivo vacía."}

	var normalized_dir: String = _imported_songs_dir.trim_suffix("/")

	# If already stored inside the persistent imported directory, keep it in place
	if cleaned.begins_with(normalized_dir + "/") and FileAccess.file_exists(cleaned):
		var existing_key: String = ChartCacheRepository.normalize_song_key(cleaned)
		var existing_title: String = _resolve_imported_song_title(cleaned, PackedByteArray(), cleaned)
		return {
			"ok": true,
			"audio_path": cleaned,
			"title": existing_title,
			"song_key": existing_key,
			"error": "",
		}

	var raw_bytes: PackedByteArray = FileAccess.get_file_as_bytes(cleaned)
	if raw_bytes.is_empty():
		return {"ok": false, "error": "No se pudo leer el archivo de audio seleccionado."}

	var detected_ext: String = AudioAnalyzer.detect_audio_extension_from_bytes(raw_bytes, cleaned)
	if detected_ext.is_empty() or not SUPPORTED_AUDIO_EXTENSIONS.has(detected_ext):
		return {"ok": false, "error": "Formato de audio no soportado (usa MP3, OGG o WAV)."}

	var display_title: String = _resolve_imported_song_title(cleaned, raw_bytes, "")

	var dir_err: Error = DirAccess.make_dir_recursive_absolute(normalized_dir)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		return {"ok": false, "error": "No se pudo crear la carpeta de canciones importadas."}

	var content_hash: String = _compute_bytes_short_hash(raw_bytes)
	var safe_stem: String = _sanitize_filename_stem(display_title)
	var dest_path: String = "%s/%s_%s.%s" % [normalized_dir, safe_stem, content_hash, detected_ext]

	var needs_write: bool = true
	if FileAccess.file_exists(dest_path):
		var existing_file: FileAccess = FileAccess.open(dest_path, FileAccess.READ)
		if existing_file != null:
			var existing_len: int = existing_file.get_length()
			existing_file.close()
			if existing_len == raw_bytes.size():
				needs_write = false

	if needs_write:
		var out_file: FileAccess = FileAccess.open(dest_path, FileAccess.WRITE)
		if out_file == null:
			return {"ok": false, "error": "No se pudo guardar una copia local de la canción."}
		out_file.store_buffer(raw_bytes)
		out_file.flush()
		out_file.close()

	var song_key: String = ChartCacheRepository.normalize_song_key(dest_path)
	return {
		"ok": true,
		"audio_path": dest_path,
		"title": display_title,
		"song_key": song_key,
		"error": "",
	}


func register_external_track(p_audio_path: String, p_open_modal: bool = true) -> void:
	var cleaned: String = p_audio_path.strip_edges()
	if cleaned.is_empty():
		return

	var import_result: Dictionary = import_external_track_to_storage(cleaned)
	var import_ok: bool = import_result.get("ok", false) as bool
	if not import_ok:
		var err_msg: String = str(import_result.get("error", "No se pudo importar la canción."))
		_set_import_status(err_msg, true)
		return

	var persisted_path: String = str(import_result.get("audio_path", ""))
	var display_title: String = str(import_result.get("title", "Pista"))
	var song_key: String = str(import_result.get("song_key", ChartCacheRepository.normalize_song_key(persisted_path)))

	_set_import_status("")
	_save_recent_track(persisted_path, display_title, song_key)
	_reload_all_track_lists()

	var count: int = _imported_entries.size()
	for i: int in range(count):
		var entry: Dictionary = _imported_entries[i]
		if str(entry.get("song_key", "")) == song_key:
			_selected_entry = entry.duplicate()
			if p_open_modal:
				show_browser_screen(MenuTab.IMPORT)
				open_song_setup_modal(entry)
			return


func _sanitize_filename_stem(p_title: String) -> String:
	var lowered: String = p_title.strip_edges().to_lower()
	var chars: PackedStringArray = PackedStringArray()
	var prev_underscore: bool = false
	for i: int in range(lowered.length()):
		var code: int = lowered.unicode_at(i)
		var is_alnum: bool = (
			(code >= 48 and code <= 57)
			or (code >= 97 and code <= 122)
		)
		if is_alnum:
			chars.append(lowered.substr(i, 1))
			prev_underscore = false
		elif not prev_underscore and not chars.is_empty():
			chars.append("_")
			prev_underscore = true
		if chars.size() >= 48:
			break
	var result: String = "".join(chars).trim_suffix("_")
	return result if not result.is_empty() else "track"


func _compute_bytes_short_hash(p_bytes: PackedByteArray) -> String:
	var ctx: HashingContext = HashingContext.new()
	if ctx.start(HashingContext.HASH_SHA256) == OK:
		ctx.update(p_bytes)
		var digest: PackedByteArray = ctx.finish()
		return digest.hex_encode().substr(0, 12)
	return str(p_bytes.size()).sha256_text().substr(0, 12)


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


func is_processing_song() -> bool:
	return _is_processing_song


func is_playing_startup_intro() -> bool:
	return _is_playing_startup_intro


func get_intro_wave_progress() -> float:
	return _intro_wave_progress


func is_loading_overlay_visible() -> bool:
	return _loading_overlay != null and _loading_overlay.visible


func get_loading_title_text() -> String:
	return _loading_title_label.text if _loading_title_label != null else ""


func get_loading_progress() -> float:
	return _loading_target_progress


func get_loading_anim_phase() -> float:
	return _loading_anim_phase


func get_active_processing_job_id() -> int:
	return _active_processing_job_id


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
		"mode_double_tap": _mode_double_tap_button,
		"mode_hold_double_tap": _mode_hold_double_tap_button,
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
		if not title.is_empty():
			cached_chart.title = title
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
	if _is_playing_startup_intro:
		return
	show_browser_screen(MenuTab.SONGS)


func is_showing_photosensitivity_warning() -> bool:
	return _is_showing_photosensitivity_warning


func get_photosensitivity_elapsed_sec() -> float:
	return _photosensitivity_elapsed_sec


func get_photosensitivity_overlay() -> Control:
	return _photosensitivity_overlay


func can_skip_photosensitivity_warning() -> bool:
	return (
		_is_showing_photosensitivity_warning
		and not _is_skipping_photosensitivity_warning
		and _photosensitivity_elapsed_sec >= PHOTOSENSITIVITY_TAP_ENABLE_SEC
	)


func _start_photosensitivity_warning() -> void:
	_has_shown_photosensitivity_warning = true
	_is_showing_photosensitivity_warning = true
	_is_skipping_photosensitivity_warning = false
	_photosensitivity_elapsed_sec = 0.0
	_photosensitivity_hint_revealed = false
	_kill_photosensitivity_tweens()
	if _photosensitivity_overlay != null:
		_photosensitivity_overlay.queue_free()
		_photosensitivity_overlay = null

	# Full-rect pure black blocker (stops all clicks toward the menu underneath)
	_photosensitivity_overlay = Control.new()
	_photosensitivity_overlay.name = "PhotosensitivityWarningOverlay"
	_photosensitivity_overlay.z_index = PHOTOSENSITIVITY_Z_INDEX
	_photosensitivity_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_photosensitivity_overlay)
	_photosensitivity_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var black_rect: ColorRect = ColorRect.new()
	black_rect.name = "PhotosensitivityBlackBackground"
	black_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photosensitivity_overlay.add_child(black_rect)
	black_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Vertically centered content column with wide lateral margins
	_photosensitivity_content = VBoxContainer.new()
	_photosensitivity_content.name = "PhotosensitivityContent"
	_photosensitivity_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photosensitivity_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_photosensitivity_content.add_theme_constant_override("separation", 40)
	_photosensitivity_content.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_photosensitivity_overlay.add_child(_photosensitivity_content)
	_photosensitivity_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_photosensitivity_content.offset_left = PHOTOSENSITIVITY_SIDE_MARGIN_PX
	_photosensitivity_content.offset_right = -PHOTOSENSITIVITY_SIDE_MARGIN_PX

	_photosensitivity_icon = Control.new()
	_photosensitivity_icon.name = "PhotosensitivityWarningIcon"
	_photosensitivity_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photosensitivity_icon.custom_minimum_size = Vector2(0.0, PHOTOSENSITIVITY_ICON_HEIGHT_PX)
	_photosensitivity_icon.draw.connect(_draw_photosensitivity_icon)
	_photosensitivity_content.add_child(_photosensitivity_icon)

	var title_label: Label = Label.new()
	title_label.name = "PhotosensitivityTitle"
	title_label.text = PHOTOSENSITIVITY_TITLE_TEXT
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photosensitivity_content.add_child(title_label)

	var body_label: Label = Label.new()
	body_label.name = "PhotosensitivityBody"
	body_label.text = PHOTOSENSITIVITY_BODY_TEXT
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photosensitivity_content.add_child(body_label)

	_photosensitivity_hint_label = Label.new()
	_photosensitivity_hint_label.name = "PhotosensitivityHint"
	_photosensitivity_hint_label.text = PHOTOSENSITIVITY_HINT_TEXT
	_photosensitivity_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_photosensitivity_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photosensitivity_hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_photosensitivity_content.add_child(_photosensitivity_hint_label)

	if _font_registry != null:
		_font_registry.apply_global_font_override(title_label, 0)
		_font_registry.apply_global_font_override(body_label, 0)
		_font_registry.apply_global_font_override(_photosensitivity_hint_label, 0)
	# Faux-bold title via same-color outline (clean, no glow flicker)
	title_label.add_theme_font_size_override("font_size", PHOTOSENSITIVITY_TITLE_FONT_SIZE)
	title_label.add_theme_color_override("font_color", COLOR_PHOTOSENSITIVITY_AMBER)
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.add_theme_color_override("font_outline_color", COLOR_PHOTOSENSITIVITY_AMBER)
	body_label.add_theme_font_size_override("font_size", PHOTOSENSITIVITY_BODY_FONT_SIZE)
	body_label.add_theme_color_override("font_color", COLOR_PHOTOSENSITIVITY_BODY)
	body_label.add_theme_constant_override("line_spacing", 10)
	_photosensitivity_hint_label.add_theme_font_size_override("font_size", PHOTOSENSITIVITY_HINT_FONT_SIZE)
	_photosensitivity_hint_label.add_theme_color_override("font_color", COLOR_PHOTOSENSITIVITY_HINT)

	_photosensitivity_overlay.move_to_front()

	# Timeline: 0.45s fade-in -> 3.95s static hold -> 0.60s fade-out (5.00s total) -> 3.0s menu intro
	_photosensitivity_tween = create_tween()
	_photosensitivity_tween.tween_property(
		_photosensitivity_content,
		"modulate:a",
		1.0,
		PHOTOSENSITIVITY_FADE_IN_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_photosensitivity_tween.tween_interval(PHOTOSENSITIVITY_HOLD_SEC)
	_photosensitivity_tween.tween_property(
		_photosensitivity_content,
		"modulate:a",
		0.0,
		PHOTOSENSITIVITY_FADE_OUT_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_photosensitivity_tween.tween_callback(_finish_photosensitivity_warning)


func _step_photosensitivity_warning(p_delta: float) -> void:
	_photosensitivity_elapsed_sec += p_delta
	if (
		not _photosensitivity_hint_revealed
		and not _is_skipping_photosensitivity_warning
		and _photosensitivity_elapsed_sec >= PHOTOSENSITIVITY_TAP_ENABLE_SEC
		and _photosensitivity_hint_label != null
	):
		_photosensitivity_hint_revealed = true
		_photosensitivity_hint_tween = create_tween()
		_photosensitivity_hint_tween.tween_property(
			_photosensitivity_hint_label,
			"modulate:a",
			1.0,
			PHOTOSENSITIVITY_HINT_FADE_SEC
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _handle_photosensitivity_input(p_event: InputEvent) -> void:
	var is_tap: bool = false
	if p_event is InputEventScreenTouch:
		is_tap = (p_event as InputEventScreenTouch).pressed
	elif p_event is InputEventMouseButton:
		var mb: InputEventMouseButton = p_event as InputEventMouseButton
		is_tap = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	# Swallow every pointer event so nothing reaches the menu underneath
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.set_input_as_handled()
	if is_tap:
		request_skip_photosensitivity_warning()


func request_skip_photosensitivity_warning() -> bool:
	if not can_skip_photosensitivity_warning():
		return false
	_is_skipping_photosensitivity_warning = true
	_kill_photosensitivity_tweens()
	_photosensitivity_tween = create_tween()
	if _photosensitivity_content != null:
		_photosensitivity_tween.tween_property(
			_photosensitivity_content,
			"modulate:a",
			0.0,
			PHOTOSENSITIVITY_SKIP_FADE_SEC
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_photosensitivity_tween.tween_interval(PHOTOSENSITIVITY_SKIP_FADE_SEC)
	_photosensitivity_tween.tween_callback(_finish_photosensitivity_warning)
	return true


func _finish_photosensitivity_warning() -> void:
	if not _is_showing_photosensitivity_warning:
		return
	_is_showing_photosensitivity_warning = false
	_is_skipping_photosensitivity_warning = false
	_photosensitivity_tween = null
	if _photosensitivity_hint_tween != null:
		_photosensitivity_hint_tween.kill()
		_photosensitivity_hint_tween = null

	# Start the 3.0s intro first: its opaque dark veil takes over seamlessly from pure black
	if not _has_played_startup_intro:
		_start_startup_intro()

	if _photosensitivity_overlay != null:
		var overlay_to_free: Control = _photosensitivity_overlay
		_photosensitivity_overlay = null
		_photosensitivity_content = null
		_photosensitivity_icon = null
		_photosensitivity_hint_label = null
		overlay_to_free.queue_free()


func _kill_photosensitivity_tweens() -> void:
	if _photosensitivity_tween != null:
		_photosensitivity_tween.kill()
		_photosensitivity_tween = null
	if _photosensitivity_hint_tween != null:
		_photosensitivity_hint_tween.kill()
		_photosensitivity_hint_tween = null


func _draw_photosensitivity_icon() -> void:
	if _photosensitivity_icon == null:
		return
	var icon_size: Vector2 = _photosensitivity_icon.size
	var tri_h: float = minf(icon_size.y, PHOTOSENSITIVITY_ICON_HEIGHT_PX) * 0.92
	var tri_w: float = tri_h * 1.12
	var center_x: float = icon_size.x * 0.5
	var top_y: float = (icon_size.y - tri_h) * 0.5
	var p_top: Vector2 = Vector2(center_x, top_y)
	var p_right: Vector2 = Vector2(center_x + (tri_w * 0.5), top_y + tri_h)
	var p_left: Vector2 = Vector2(center_x - (tri_w * 0.5), top_y + tri_h)

	# Static soft amber fill
	var fill_pts: PackedVector2Array = PackedVector2Array([p_top, p_right, p_left])
	_photosensitivity_icon.draw_colored_polygon(
		fill_pts,
		Color(COLOR_PHOTOSENSITIVITY_AMBER.r, COLOR_PHOTOSENSITIVITY_AMBER.g, COLOR_PHOTOSENSITIVITY_AMBER.b, 0.10)
	)

	# Soft cyan neon halo stroke + crisp amber outline (no animation, no flashing)
	var outline_pts: PackedVector2Array = PackedVector2Array([p_top, p_right, p_left, p_top])
	_photosensitivity_icon.draw_polyline(outline_pts, COLOR_PHOTOSENSITIVITY_CYAN_GLOW, 14.0, true)
	_photosensitivity_icon.draw_polyline(outline_pts, COLOR_PHOTOSENSITIVITY_AMBER, 6.0, true)

	# Exclamation mark
	var bar_top: Vector2 = Vector2(center_x, top_y + (tri_h * 0.36))
	var bar_bottom: Vector2 = Vector2(center_x, top_y + (tri_h * 0.68))
	_photosensitivity_icon.draw_line(bar_top, bar_bottom, COLOR_PHOTOSENSITIVITY_AMBER, tri_h * 0.085, true)
	_photosensitivity_icon.draw_circle(bar_top, tri_h * 0.0425, COLOR_PHOTOSENSITIVITY_AMBER)
	_photosensitivity_icon.draw_circle(bar_bottom, tri_h * 0.0425, COLOR_PHOTOSENSITIVITY_AMBER)
	_photosensitivity_icon.draw_circle(
		Vector2(center_x, top_y + (tri_h * 0.82)),
		tri_h * 0.055,
		COLOR_PHOTOSENSITIVITY_AMBER
	)


func _start_startup_intro() -> void:
	_has_played_startup_intro = true
	_is_playing_startup_intro = true
	_intro_wave_progress = 0.0

	if _intro_tween != null:
		_intro_tween.kill()
		_intro_tween = null
	if _intro_overlay != null:
		_intro_overlay.queue_free()
		_intro_overlay = null
		_intro_veil_rect = null
		_intro_wave_fx = null

	_intro_overlay = Control.new()
	_intro_overlay.name = "StartupIntroOverlay"
	_intro_overlay.z_index = STARTUP_INTRO_Z_INDEX
	_intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_intro_overlay)
	_intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_intro_veil_rect = ColorRect.new()
	_intro_veil_rect.name = "StartupIntroVeil"
	_intro_veil_rect.color = Color(0.01, 0.02, 0.06, 1.0)
	_intro_veil_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_intro_veil_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_overlay.add_child(_intro_veil_rect)
	_intro_veil_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_intro_wave_fx = Control.new()
	_intro_wave_fx.name = "StartupIntroWaveFx"
	_intro_wave_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_wave_fx.draw.connect(_draw_intro_wave)
	_intro_overlay.add_child(_intro_wave_fx)
	_intro_wave_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var on_title_screen: bool = _title_screen_container != null and _title_screen_container.visible
	var title_node: Control = _hero_title_label if on_title_screen else _browser_header_label
	var primary_node: Control = _hero_play_button if on_title_screen else _tabs_row
	var secondary_node: Control = _hero_subtitle_label if on_title_screen else _content_sheet_panel

	var title_base_y: float = 0.0
	if title_node != null:
		title_base_y = title_node.position.y
		title_node.pivot_offset = title_node.size * 0.5
		title_node.modulate = Color(1.0, 1.0, 1.0, 0.0)
		title_node.scale = Vector2(0.94, 0.94)
		title_node.position.y = title_base_y + STARTUP_INTRO_TITLE_OFFSET_Y_PX
		var title_rect: Rect2 = title_node.get_global_rect()
		_intro_wave_center = (title_rect.position + (title_rect.size * 0.5)) - global_position
	else:
		_intro_wave_center = Vector2(size.x * 0.5, size.y * 0.30)

	if primary_node != null:
		primary_node.pivot_offset = primary_node.size * 0.5
		primary_node.modulate = Color(1.0, 1.0, 1.0, 0.0)
		primary_node.scale = Vector2(0.94, 0.94)

	if secondary_node != null:
		secondary_node.modulate = Color(1.0, 1.0, 1.0, 0.0)

	call_deferred(&"_launch_startup_intro_tween", title_node, title_base_y, primary_node, secondary_node)


func _launch_startup_intro_tween(
	p_title_node: Control,
	p_title_base_y: float,
	p_primary_node: Control,
	p_secondary_node: Control
) -> void:
	if not _is_playing_startup_intro or not is_inside_tree():
		return

	var tree: SceneTree = get_tree()
	if tree != null:
		await tree.process_frame
	if not _is_playing_startup_intro or not is_inside_tree():
		return

	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)

	# 1. Dark veil fade-out (0.00s -> 0.80s)
	if _intro_veil_rect != null:
		_intro_tween.tween_property(
			_intro_veil_rect,
			"modulate:a",
			0.0,
			STARTUP_INTRO_VEIL_SEC
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. Title / logo progressive reveal with subtle scale & lift (0.36s -> 1.56s)
	if p_title_node != null:
		_intro_tween.tween_property(
			p_title_node,
			"modulate:a",
			1.0,
			STARTUP_INTRO_TITLE_DURATION_SEC
		).set_delay(STARTUP_INTRO_TITLE_DELAY_SEC).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(
			p_title_node,
			"scale",
			Vector2.ONE,
			STARTUP_INTRO_TITLE_DURATION_SEC
		).set_delay(STARTUP_INTRO_TITLE_DELAY_SEC).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(
			p_title_node,
			"position:y",
			p_title_base_y,
			STARTUP_INTRO_TITLE_DURATION_SEC
		).set_delay(STARTUP_INTRO_TITLE_DELAY_SEC).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# 3. Subtle expanding circular neon "boom" wave centered on title (0.56s -> 2.00s)
	_intro_tween.tween_method(
		_set_intro_wave_progress,
		0.0,
		1.0,
		STARTUP_INTRO_WAVE_SEC
	).set_delay(STARTUP_INTRO_WAVE_DELAY_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 4. Primary action / tabs row reveal (1.08s -> 2.16s)
	if p_primary_node != null:
		_intro_tween.tween_property(
			p_primary_node,
			"modulate:a",
			1.0,
			STARTUP_INTRO_PRIMARY_DURATION_SEC
		).set_delay(STARTUP_INTRO_PRIMARY_DELAY_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(
			p_primary_node,
			"scale",
			Vector2.ONE,
			STARTUP_INTRO_PRIMARY_DURATION_SEC
		).set_delay(STARTUP_INTRO_PRIMARY_DELAY_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 5. Secondary elements / subtitle / content sheet reveal (1.64s -> 3.00s)
	if p_secondary_node != null:
		_intro_tween.tween_property(
			p_secondary_node,
			"modulate:a",
			1.0,
			STARTUP_INTRO_TOTAL_SEC - STARTUP_INTRO_SECONDARY_DELAY_SEC
		).set_delay(STARTUP_INTRO_SECONDARY_DELAY_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Guarantee exact 3.00s total duration even if secondary node is absent
	_intro_tween.tween_interval(STARTUP_INTRO_TOTAL_SEC)
	_intro_tween.chain().tween_callback(_finish_startup_intro)


func _set_intro_wave_progress(p_progress: float) -> void:
	_intro_wave_progress = clampf(p_progress, 0.0, 1.0)
	if _intro_wave_fx != null:
		_intro_wave_fx.queue_redraw()


func _draw_intro_wave() -> void:
	if _intro_wave_fx == null:
		return
	if _intro_wave_progress <= 0.001 or _intro_wave_progress >= 0.999:
		return

	var t: float = _intro_wave_progress
	var fade: float = pow(1.0 - t, 1.65)
	var base_radius: float = lerpf(24.0, 340.0, t)
	var inner_radius: float = lerpf(12.0, 235.0, t)

	# Soft radial bloom behind title at wave peak
	var core_alpha: float = fade * 0.14
	if core_alpha > 0.005:
		_intro_wave_fx.draw_circle(
			_intro_wave_center,
			lerpf(42.0, 165.0, t),
			Color(0.32, 0.92, 1.0, core_alpha)
		)

	# Outer glowing neon cyan ring + crisp core arc
	_intro_wave_fx.draw_arc(
		_intro_wave_center,
		base_radius,
		0.0,
		TAU,
		56,
		Color(0.24, 0.88, 1.0, fade * 0.24),
		lerpf(22.0, 6.0, t),
		true
	)
	_intro_wave_fx.draw_arc(
		_intro_wave_center,
		base_radius,
		0.0,
		TAU,
		56,
		Color(0.68, 0.99, 1.0, fade * 0.62),
		lerpf(4.2, 1.4, t),
		true
	)

	# Subtle secondary magenta/violet harmonic ring
	_intro_wave_fx.draw_arc(
		_intro_wave_center,
		inner_radius,
		0.0,
		TAU,
		48,
		Color(0.78, 0.42, 1.0, fade * 0.30),
		lerpf(6.0, 1.8, t),
		true
	)


func _finish_startup_intro() -> void:
	_is_playing_startup_intro = false
	_intro_wave_progress = 1.0
	_intro_tween = null

	var revealed_nodes: Array[Control] = [
		_hero_title_label,
		_hero_subtitle_label,
		_hero_play_button,
		_browser_header_label,
		_tabs_row,
		_content_sheet_panel,
	]
	for i: int in range(revealed_nodes.size()):
		var node_ctrl: Control = revealed_nodes[i]
		if node_ctrl != null:
			node_ctrl.modulate = Color(1.0, 1.0, 1.0, 1.0)
			node_ctrl.scale = Vector2.ONE

	if _safe_container != null:
		apply_hud_safe_rect(Rect2(_safe_container.position, _safe_container.size))

	if _intro_overlay != null:
		var overlay_to_free: Control = _intro_overlay
		_intro_overlay = null
		_intro_veil_rect = null
		_intro_wave_fx = null
		overlay_to_free.queue_free()


func get_last_launch_sequence() -> Array[String]:
	return _last_launch_sequence


func _on_play_button_pressed() -> void:
	if _is_launching or _is_processing_song or _is_playing_startup_intro:
		return
	_is_launching = true
	_is_processing_song = true
	_active_processing_job_id += 1
	var job_id: int = _active_processing_job_id
	_last_launch_sequence.clear()
	_last_launch_sequence.append("processing_started")

	if _play_button != null:
		_play_button.disabled = true
	if _modal_close_button != null:
		_modal_close_button.disabled = true
	if _transition_fade_rect != null:
		_transition_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_transition_fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)

	# Keep menu BGM and live spectrum monitoring active while processing the song
	_sync_live_audio_monitoring()

	var selected: Dictionary = get_selected_track()
	var is_demo: bool = selected.get("is_demo", true) as bool
	var audio_path: String = str(selected.get("audio_path", ""))
	var title: String = str(selected.get("title", "FeelYourBeats Demo 128 BPM"))
	var cache_key: String = ""
	var has_cache: bool = false
	if not is_demo and not audio_path.is_empty():
		cache_key = _chart_cache_repo.build_cache_key(
			audio_path,
			_selected_difficulty,
			_selected_note_type_mode
		)
		has_cache = _chart_cache_repo.has_cached_file(cache_key)

	var loading_title: String = "CARGANDO..." if (is_demo or has_cache) else "PROCESANDO CANCIÓN..."
	var initial_stage: String = "Cargando pista en caché..." if has_cache else ("Preparando demo..." if is_demo else "Leyendo archivo de audio...")
	_show_loading_overlay(loading_title, initial_stage, -1.0 if (is_demo or has_cache) else 0.05)

	if _status_label != null:
		_status_label.text = ""

	var tree: SceneTree = get_tree()
	if tree != null:
		await tree.process_frame
	if job_id != _active_processing_job_id or not is_inside_tree():
		return

	if is_demo or audio_path.is_empty() or audio_analyzer == null:
		var demo_payload: Dictionary = {
			"is_demo": true,
			"audio_path": "",
			"title": title,
			"difficulty": _selected_difficulty,
			"note_type_mode": _selected_note_type_mode,
			"speed_multiplier": _selected_speed_multiplier,
			"preloaded_chart": null,
			"preloaded_stream": null,
			"from_cache": false,
		}
		_on_song_processing_completed(job_id, demo_payload)
		return

	if has_cache:
		var cached_stream: AudioStream = audio_analyzer.load_audio_stream(audio_path)
		var cached_chart: ChartData = _chart_cache_repo.load_cached_chart(cache_key)
		if cached_stream != null and cached_chart != null:
			if not title.is_empty():
				cached_chart.title = title
			var cached_payload: Dictionary = {
				"is_demo": false,
				"audio_path": audio_path,
				"title": title,
				"difficulty": _selected_difficulty,
				"note_type_mode": _selected_note_type_mode,
				"speed_multiplier": _selected_speed_multiplier,
				"preloaded_chart": cached_chart,
				"preloaded_stream": cached_stream,
				"from_cache": true,
				"cache_key": cache_key,
			}
			_on_song_processing_progress(job_id, 1.0, "Pista lista")
			_on_song_processing_completed(job_id, cached_payload)
			return

	# Resolve res:// bundled AudioStream on main thread (fast ResourceLoader); external files decode on worker thread
	var res_stream: AudioStream = null
	if audio_path.begins_with("res://") and ResourceLoader.exists(audio_path):
		res_stream = audio_analyzer.load_audio_stream(audio_path)

	var mix_rate: float = maxf(8000.0, AudioServer.get_mix_rate())
	var job_cfg: Dictionary = {
		"job_id": job_id,
		"audio_path": audio_path,
		"title": title,
		"difficulty": _selected_difficulty,
		"note_type_mode": _selected_note_type_mode,
		"speed_multiplier": _selected_speed_multiplier,
		"cache_key": cache_key,
		"mix_rate": mix_rate,
		"bass_max_hz": audio_analyzer.bass_max_hz,
		"mid_max_hz": audio_analyzer.mid_max_hz,
		"preloaded_stream": res_stream,
	}
	_active_worker_task_id = WorkerThreadPool.add_task(
		_run_song_processing_worker.bind(job_cfg),
		true,
		"FyB_SongProcessing"
	)


func _run_song_processing_worker(p_job: Dictionary) -> void:
	# Pure data & resource processing only: NEVER touch SceneTree or Control nodes directly here
	var job_id: int = int(p_job.get("job_id", 0))
	var audio_path: String = str(p_job.get("audio_path", ""))
	var title: String = str(p_job.get("title", "Pista"))
	var difficulty: int = int(p_job.get("difficulty", AutoChartGenerator.Difficulty.NORMAL))
	var note_type_mode: int = int(p_job.get("note_type_mode", AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD))
	var speed_multiplier: int = int(p_job.get("speed_multiplier", LaneField.MIN_SPEED_MULTIPLIER))
	var cache_key: String = str(p_job.get("cache_key", ""))
	var mix_rate: float = float(p_job.get("mix_rate", 44100.0))
	var bass_max_hz: float = float(p_job.get("bass_max_hz", 200.0))
	var mid_max_hz: float = float(p_job.get("mid_max_hz", 2200.0))

	call_deferred(&"_on_song_processing_progress", job_id, 0.10, "Leyendo archivo de audio...")

	var stream: AudioStream = p_job.get("preloaded_stream", null) as AudioStream
	if stream == null:
		stream = AudioAnalyzer.load_external_audio_stream_data(audio_path)
	if stream == null:
		call_deferred(
			&"_on_song_processing_completed",
			job_id,
			{"error": "No se pudo leer o decodificar el archivo de audio."}
		)
		return

	call_deferred(&"_on_song_processing_progress", job_id, 0.15, "Analizando espectro y ritmo...")

	var progress_cb: Callable = func(p_pct: float) -> void:
		var mapped: float = lerpf(0.15, 0.82, clampf(p_pct, 0.0, 1.0))
		call_deferred(&"_on_song_processing_progress", job_id, mapped, "Analizando espectro y ritmo...")

	var analysis: Dictionary = AudioAnalyzer.analyze_audio_stream_data(
		stream,
		mix_rate,
		bass_max_hz,
		mid_max_hz,
		AudioAnalyzer.DEFAULT_HOP_SEC,
		progress_cb
	)
	var duration_sec: float = analysis.get("duration_sec", 0.0) as float
	if duration_sec <= 0.0:
		call_deferred(
			&"_on_song_processing_completed",
			job_id,
			{"error": "El audio no contiene muestras válidas."}
		)
		return

	call_deferred(&"_on_song_processing_progress", job_id, 0.86, "Generando mapa de notas...")

	var generator: AutoChartGenerator = AutoChartGenerator.new()
	var chart: ChartData = generator.generate_from_analysis(
		audio_path.get_file().get_basename(),
		title,
		audio_path,
		analysis,
		difficulty,
		note_type_mode
	)
	AudioAnalyzer.release_analysis_buffers(analysis)
	var validation: Dictionary = chart.validate()
	if not (validation.get("valid", false) as bool):
		call_deferred(
			&"_on_song_processing_completed",
			job_id,
			{"error": "No se pudo generar un chart válido para esta pista."}
		)
		return

	call_deferred(&"_on_song_processing_progress", job_id, 0.98, "Preparando partida...")

	var payload: Dictionary = {
		"is_demo": false,
		"audio_path": audio_path,
		"title": title,
		"difficulty": difficulty,
		"note_type_mode": note_type_mode,
		"speed_multiplier": speed_multiplier,
		"preloaded_chart": chart,
		"preloaded_stream": stream,
		"from_cache": false,
		"cache_key": cache_key,
	}
	call_deferred(&"_on_song_processing_completed", job_id, payload)


func _on_song_processing_progress(p_job_id: int, p_progress: float, p_stage_text: String) -> void:
	if p_job_id != _active_processing_job_id or not _is_processing_song:
		return
	_loading_target_progress = clampf(p_progress, 0.0, 1.0)
	if _loading_stage_label != null and not p_stage_text.is_empty():
		_loading_stage_label.text = p_stage_text


func _on_song_processing_completed(p_job_id: int, p_payload: Dictionary) -> void:
	if _active_worker_task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_active_worker_task_id)
		_active_worker_task_id = -1

	if p_job_id != _active_processing_job_id:
		return

	if p_payload.has("error"):
		_abort_song_launch_with_error(str(p_payload["error"]))
		return

	var from_cache: bool = p_payload.get("from_cache", false) as bool
	var cache_key: String = str(p_payload.get("cache_key", ""))
	var chart: ChartData = p_payload.get("preloaded_chart", null) as ChartData
	if not from_cache and chart != null and not cache_key.is_empty():
		_chart_cache_repo.save_cached_chart(cache_key, chart)

	GameSession.set_pending_session(p_payload)
	_finish_song_launch_transition()


func _abort_song_launch_with_error(p_error_message: String) -> void:
	_is_processing_song = false
	_is_launching = false
	_hide_loading_overlay()

	if _transition_fade_rect != null:
		_transition_fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_transition_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _status_label != null:
		_status_label.text = p_error_message
	if _play_button != null:
		_play_button.disabled = false
	if _modal_close_button != null:
		_modal_close_button.disabled = false

	if menu_bgm_player != null and menu_bgm_player.is_bgm_enabled and not menu_bgm_player.is_playing():
		menu_bgm_player.resume_bgm()
	_sync_live_audio_monitoring()


func _finish_song_launch_transition() -> void:
	_is_processing_song = false
	_hide_loading_overlay()
	_last_launch_sequence.append("analysis_done")

	if _status_label != null:
		_status_label.text = "INICIANDO..."
	if _transition_fade_rect != null:
		_transition_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		_transition_fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)

	# Step 1: Smooth brief BGM fade-out & stop just before cassette SFX
	_last_launch_sequence.append("bgm_fade_started")
	if menu_bgm_player != null:
		await menu_bgm_player.fade_out_and_stop(BGM_FADEOUT_DURATION_SEC)
	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(false)
	if reactive_background != null:
		reactive_background.set_menu_bgm_active(false)
	_last_launch_sequence.append("bgm_stopped")

	if not is_inside_tree():
		return

	# Step 2: Cassette SFX + 2.5s visual fade-to-black simultaneously
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

	var tree: SceneTree = get_tree()
	if tree != null:
		var elapsed_sec: float = float(Time.get_ticks_usec() - transition_start_usec) * USEC_TO_SEC
		var remaining_sec: float = TRANSITION_FADE_DURATION_SEC - elapsed_sec
		if remaining_sec > 0.005:
			await tree.create_timer(remaining_sec).timeout

	if _transition_fade_rect != null:
		_transition_fade_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if allow_scene_change and tree != null and ResourceLoader.exists(GAME_SESSION_SCENE_PATH):
		tree.change_scene_to_file(GAME_SESSION_SCENE_PATH)


func _show_loading_overlay(
	p_title: String,
	p_stage: String,
	p_initial_progress: float = -1.0
) -> void:
	_ensure_ui_nodes()
	_reset_touch_scroll_state()
	_loading_anim_phase = 0.0
	_loading_indeterminate_phase = 0.0
	_loading_target_progress = p_initial_progress
	_loading_display_progress = maxf(0.0, p_initial_progress)
	if _loading_title_label != null:
		_loading_title_label.text = p_title
	if _loading_stage_label != null:
		_loading_stage_label.text = p_stage
	if _loading_percent_label != null:
		_loading_percent_label.text = "%d%%" % int(round(_loading_display_progress * 100.0)) if p_initial_progress >= 0.0 else "..."
	if _loading_overlay != null:
		_loading_overlay.visible = true
		if _safe_container != null:
			_layout_loading_overlay(_safe_container.size.x, _safe_container.size.y)
		_update_loading_progress_bar_visual()


func _hide_loading_overlay() -> void:
	if _loading_overlay != null:
		_loading_overlay.visible = false


func _step_loading_overlay_animation(p_dt: float) -> void:
	_loading_anim_phase += p_dt * 4.8
	_loading_indeterminate_phase += p_dt * 1.45
	if _loading_target_progress >= 0.0:
		_loading_display_progress = lerpf(
			_loading_display_progress,
			_loading_target_progress,
			clampf(p_dt * 10.0, 0.0, 1.0)
		)
	if _loading_spinner != null:
		_loading_spinner.queue_redraw()
	_update_loading_progress_bar_visual()


func _update_loading_progress_bar_visual() -> void:
	if _loading_progress_track == null or _loading_progress_fill == null:
		return
	var track_w: float = maxf(1.0, _loading_progress_track.size.x)
	var track_h: float = maxf(8.0, _loading_progress_track.size.y)
	if _loading_target_progress >= 0.0:
		var pct: float = clampf(_loading_display_progress, 0.02, 1.0)
		_loading_progress_fill.position = Vector2.ZERO
		_loading_progress_fill.size = Vector2(track_w * pct, track_h)
		if _loading_percent_label != null:
			_loading_percent_label.text = "%d%%" % int(round(clampf(_loading_target_progress, 0.0, 1.0) * 100.0))
	else:
		var bar_w: float = track_w * 0.34
		var travel: float = maxf(0.0, track_w - bar_w)
		var wave: float = (sin(_loading_indeterminate_phase * PI) * 0.5) + 0.5
		_loading_progress_fill.position = Vector2(travel * wave, 0.0)
		_loading_progress_fill.size = Vector2(bar_w, track_h)
		if _loading_percent_label != null:
			_loading_percent_label.text = "..."


func _draw_loading_spinner() -> void:
	if _loading_spinner == null:
		return
	var center: Vector2 = _loading_spinner.size * 0.5
	var radius: float = maxf(18.0, minf(center.x, center.y) - 8.0)

	# Subtle background ring
	_loading_spinner.draw_arc(
		center,
		radius,
		0.0,
		TAU,
		40,
		Color(0.22, 0.38, 0.54, 0.35),
		6.0,
		true
	)
	# Outer glowing cyan arc
	var start_a: float = _loading_anim_phase
	_loading_spinner.draw_arc(
		center,
		radius,
		start_a,
		start_a + (TAU * 0.34),
		32,
		Color(0.32, 0.96, 1.0, 0.35),
		13.0,
		true
	)
	_loading_spinner.draw_arc(
		center,
		radius,
		start_a,
		start_a + (TAU * 0.34),
		32,
		Color(0.55, 0.99, 1.0, 0.98),
		5.5,
		true
	)
	# Counter-rotating inner magenta/violet arc
	var start_b: float = -_loading_anim_phase * 1.35
	_loading_spinner.draw_arc(
		center,
		radius * 0.66,
		start_b,
		start_b + (TAU * 0.28),
		28,
		Color(0.86, 0.38, 1.0, 0.85),
		4.0,
		true
	)
	# Pulsing core dot
	var pulse: float = 0.72 + (0.28 * (sin(_loading_anim_phase * 1.6) * 0.5 + 0.5))
	_loading_spinner.draw_circle(center, 7.0 * pulse, Color(0.75, 1.0, 1.0, 0.92))


func _layout_loading_overlay(p_safe_w: float, p_safe_h: float) -> void:
	if _loading_overlay == null or _loading_panel == null:
		return
	var safe_w: float = maxf(320.0, p_safe_w)
	var safe_h: float = maxf(480.0, p_safe_h)
	_loading_overlay.position = Vector2.ZERO
	_loading_overlay.size = Vector2(safe_w, safe_h)

	var panel_w: float = minf(760.0, safe_w - 64.0)
	var panel_h: float = 410.0
	_loading_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	_loading_panel.size = Vector2(panel_w, panel_h)
	_loading_panel.position = Vector2((safe_w - panel_w) * 0.5, (safe_h - panel_h) * 0.5)


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
		if DirAccess.dir_exists_absolute(ANDROID_SHARED_STORAGE_DIR):
			_file_dialog.current_dir = ANDROID_SHARED_STORAGE_DIR
		else:
			var downloads_dir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
			var shared_root: String = downloads_dir.get_base_dir() if not downloads_dir.is_empty() else ""
			if not shared_root.is_empty() and DirAccess.dir_exists_absolute(shared_root):
				_file_dialog.current_dir = shared_root
			elif not downloads_dir.is_empty() and DirAccess.dir_exists_absolute(downloads_dir):
				_file_dialog.current_dir = downloads_dir
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
	if _consume_suppressed_scroll_press():
		return
	if menu_bgm_player != null:
		menu_bgm_player.set_bgm_enabled(not menu_bgm_player.is_bgm_enabled)
	_refresh_bgm_controls()
	_sync_live_audio_monitoring()


func _on_bgm_prev_pressed() -> void:
	if _consume_suppressed_scroll_press():
		return
	if menu_bgm_player != null:
		menu_bgm_player.prev_track()
	_refresh_bgm_controls()


func _on_bgm_next_pressed() -> void:
	if _consume_suppressed_scroll_press():
		return
	if menu_bgm_player != null:
		menu_bgm_player.next_track()
	_refresh_bgm_controls()


func _on_bgm_mode_pressed() -> void:
	if _consume_suppressed_scroll_press():
		return
	if menu_bgm_player != null:
		menu_bgm_player.set_auto_rotate(not menu_bgm_player.is_auto_rotate)
	_refresh_bgm_controls()


func _on_bgm_track_changed(_p_index: int, _p_name: String) -> void:
	_refresh_bgm_controls()


func _on_bgm_enabled_changed(_p_enabled: bool) -> void:
	_refresh_bgm_controls()
	_sync_live_audio_monitoring()


func get_reactive_particles_layer() -> ReactiveParticlesLayer:
	return reactive_particles_layer


func get_particles_config_snapshot() -> ReactiveParticlesConfig:
	return _particles_config.duplicate_config()


func set_particles_settings_path(p_path: String) -> void:
	particles_settings_path = p_path
	reload_particle_settings()


func reload_particle_settings() -> void:
	_particles_config.load_from_file(particles_settings_path)
	if not _particles_config.enabled:
		_particles_config.particle_type = ReactiveParticlesConfig.TYPE_NONE
		_particles_config.enabled = true
	if reactive_particles_layer != null:
		reactive_particles_layer.apply_config(_particles_config)
	_refresh_particle_controls()


func _apply_and_persist_particle_settings() -> void:
	_particles_config.save_to_file(particles_settings_path)
	if reactive_particles_layer != null:
		reactive_particles_layer.apply_config(_particles_config)
	_refresh_particle_controls()


func _on_particles_type_selected(p_type: String) -> void:
	if _consume_suppressed_scroll_press():
		return
	_particles_config.particle_type = ReactiveParticlesConfig.sanitize_type(p_type)
	_particles_config.enabled = true
	_apply_and_persist_particle_settings()


func _on_particles_density_selected(p_density: String) -> void:
	if _consume_suppressed_scroll_press():
		return
	if _particles_config.particle_type == ReactiveParticlesConfig.TYPE_NONE:
		return
	_particles_config.density = ReactiveParticlesConfig.sanitize_level(p_density)
	_apply_and_persist_particle_settings()


func _on_particles_reactivity_selected(p_reactivity: String) -> void:
	if _consume_suppressed_scroll_press():
		return
	if _particles_config.particle_type == ReactiveParticlesConfig.TYPE_NONE:
		return
	_particles_config.music_reactivity = ReactiveParticlesConfig.sanitize_level(p_reactivity)
	_apply_and_persist_particle_settings()


func get_background_config_snapshot() -> ReactiveBackgroundConfig:
	return _bg_config.duplicate_config()


func set_background_settings_path(p_path: String) -> void:
	background_settings_path = p_path
	reload_background_settings()


func reload_background_settings() -> void:
	_bg_config.load_from_file(background_settings_path)
	if reactive_background != null:
		reactive_background.apply_background_config(_bg_config)
	_refresh_background_controls()


func _apply_and_persist_background_settings() -> void:
	_bg_config.save_to_file(background_settings_path)
	if reactive_background != null:
		reactive_background.apply_background_config(_bg_config)
	_refresh_background_controls()


func _on_bg_style_selected(p_style: String) -> void:
	if _consume_suppressed_scroll_press():
		return
	_bg_config.style = ReactiveBackgroundConfig.sanitize_style(p_style)
	_apply_and_persist_background_settings()


func _on_bg_reactivity_selected(p_reactivity: String) -> void:
	if _consume_suppressed_scroll_press():
		return
	_bg_config.reactivity = ReactiveBackgroundConfig.sanitize_level(p_reactivity)
	_apply_and_persist_background_settings()


func get_gameplay_effects_config_snapshot() -> GameplayEffectsConfig:
	return _effects_config.duplicate_config()


func set_effects_settings_path(p_path: String) -> void:
	effects_settings_path = p_path
	reload_gameplay_effects_settings()


func reload_gameplay_effects_settings() -> void:
	_effects_config.load_from_file(effects_settings_path)
	if reactive_background != null:
		reactive_background.apply_gameplay_effects_config(_effects_config)
	_refresh_gameplay_effects_controls()


func _apply_and_persist_gameplay_effects_settings() -> void:
	_effects_config.save_to_file(effects_settings_path)
	if reactive_background != null:
		reactive_background.apply_gameplay_effects_config(_effects_config)
	_refresh_gameplay_effects_controls()


func _on_hit_effect_selected(p_style: String) -> void:
	if _consume_suppressed_scroll_press():
		return
	_effects_config.hit_effect = GameplayEffectsConfig.sanitize_hit_effect(p_style)
	_apply_and_persist_gameplay_effects_settings()


func _on_touch_effect_selected(p_style: String) -> void:
	if _consume_suppressed_scroll_press():
		return
	_effects_config.touch_effect = GameplayEffectsConfig.sanitize_touch_effect(p_style)
	_apply_and_persist_gameplay_effects_settings()
	var btn: Button = _touch_effect_buttons.get(_effects_config.touch_effect, null) as Button
	if btn != null:
		var btn_rect: Rect2 = btn.get_global_rect()
		spawn_touch_effect_preview(btn_rect.position + (btn_rect.size * 0.5))


func _on_vanish_effect_selected(p_style: String) -> void:
	if _consume_suppressed_scroll_press():
		return
	_effects_config.vanish_effect = GameplayEffectsConfig.sanitize_vanish_effect(p_style)
	_apply_and_persist_gameplay_effects_settings()


func _init_touch_preview_pool() -> void:
	_tp_active.resize(MAX_MENU_TOUCH_PREVIEWS)
	_tp_age.resize(MAX_MENU_TOUCH_PREVIEWS)
	_tp_duration.resize(MAX_MENU_TOUCH_PREVIEWS)
	_tp_pos.resize(MAX_MENU_TOUCH_PREVIEWS)
	_tp_variant.resize(MAX_MENU_TOUCH_PREVIEWS)
	for i: int in range(MAX_MENU_TOUCH_PREVIEWS):
		_tp_active[i] = 0
		_tp_age[i] = 0.0
		_tp_duration[i] = TouchEffectRenderer.WAVE_DURATION_SEC
		_tp_pos[i] = Vector2.ZERO
		_tp_variant[i] = 0
	_tp_cursor = 0


func spawn_touch_effect_preview(p_global_pos: Vector2) -> void:
	if _tp_active.size() != MAX_MENU_TOUCH_PREVIEWS:
		_init_touch_preview_pool()
	_tp_seed += 1
	var slot: int = _tp_cursor
	_tp_cursor = (_tp_cursor + 1) % MAX_MENU_TOUCH_PREVIEWS
	var local_pos: Vector2 = p_global_pos - global_position
	_tp_active[slot] = 1
	_tp_age[slot] = 0.0
	_tp_duration[slot] = TouchEffectRenderer.get_duration_for_style(_effects_config.touch_effect)
	_tp_pos[slot] = local_pos
	_tp_variant[slot] = posmod((_tp_seed * 5) + int(local_pos.x), TouchEffectRenderer.NOTE_VARIANT_COUNT)
	if _touch_preview_layer != null:
		_touch_preview_layer.queue_redraw()


func get_active_touch_preview_count() -> int:
	var count: int = 0
	for i: int in range(_tp_active.size()):
		if _tp_active[i] != 0:
			count += 1
	return count


func _step_touch_preview_pool(p_dt: float) -> void:
	var any_active: bool = false
	for i: int in range(_tp_active.size()):
		if _tp_active[i] == 0:
			continue
		var next_age: float = _tp_age[i] + p_dt
		if next_age >= _tp_duration[i]:
			_tp_active[i] = 0
		else:
			_tp_age[i] = next_age
		any_active = true
	if any_active and _touch_preview_layer != null:
		_touch_preview_layer.queue_redraw()


func _draw_touch_preview_layer() -> void:
	if _touch_preview_layer == null:
		return
	var style: String = _effects_config.touch_effect
	var base_col: Color = Color(0.38, 0.94, 1.0, 0.92)
	for i: int in range(_tp_active.size()):
		if _tp_active[i] == 0:
			continue
		var dur: float = maxf(0.01, _tp_duration[i])
		var t: float = clampf(_tp_age[i] / dur, 0.0, 1.0)
		_touch_preview_renderer.draw_touch_effect(
			_touch_preview_layer,
			_tp_pos[i],
			t,
			style,
			base_col,
			_tp_variant[i]
		)


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
	if _is_launching or _is_processing_song:
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
	if reactive_particles_layer == null:
		reactive_particles_layer = get_node_or_null("ReactiveParticlesLayer") as ReactiveParticlesLayer
	if menu_bgm_player == null:
		menu_bgm_player = get_node_or_null("MenuBgmPlayer") as MenuBgmPlayer
	if ui_sfx_player == null:
		var global_sfx: Node = get_node_or_null("/root/GlobalUiSfx")
		if global_sfx is UiSfxPlayer:
			ui_sfx_player = global_sfx as UiSfxPlayer
		else:
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

	if reactive_particles_layer == null:
		reactive_particles_layer = ReactiveParticlesLayer.new()
		reactive_particles_layer.name = "ReactiveParticlesLayer"
		add_child(reactive_particles_layer)

	if reactive_background != null and reactive_particles_layer.get_parent() == self:
		var bg_idx: int = reactive_background.get_index()
		if reactive_particles_layer.get_index() != bg_idx + 1:
			move_child(reactive_particles_layer, bg_idx + 1)

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
		reload_background_settings()
		if not reactive_background.bass_kick_pulsed.is_connected(_on_bass_kick_pulsed):
			reactive_background.bass_kick_pulsed.connect(_on_bass_kick_pulsed)
		if not audio_analyzer.spectrum_updated.is_connected(_on_menu_spectrum_updated):
			audio_analyzer.spectrum_updated.connect(_on_menu_spectrum_updated)

	if reactive_particles_layer != null:
		reactive_particles_layer.reactive_background = reactive_background
		reactive_particles_layer.audio_analyzer = audio_analyzer
		reactive_particles_layer.connect_dependencies()
		reload_particle_settings()

	if menu_bgm_player != null:
		if not menu_bgm_player.track_changed.is_connected(_on_bgm_track_changed):
			menu_bgm_player.track_changed.connect(_on_bgm_track_changed)
		if not menu_bgm_player.bgm_enabled_changed.is_connected(_on_bgm_enabled_changed):
			menu_bgm_player.bgm_enabled_changed.connect(_on_bgm_enabled_changed)

	var tree: SceneTree = get_tree()
	if tree != null and tree.has_signal("on_request_permissions_result"):
		if not tree.is_connected("on_request_permissions_result", _on_android_permissions_result):
			tree.connect("on_request_permissions_result", _on_android_permissions_result)

	if ui_sfx_player != null:
		var excluded: Array[BaseButton] = []
		if _play_button != null:
			UiSfxPlayer.mark_button_excluded(_play_button)
			excluded.append(_play_button)
		ui_sfx_player.enable_global_button_wiring()
		ui_sfx_player.bind_buttons_in_tree(self, excluded)


func _sync_live_audio_monitoring() -> void:
	var bgm_suppressed_for_transition: bool = _is_launching and not _is_processing_song
	var should_monitor: bool = (
		not bgm_suppressed_for_transition
		and menu_bgm_player != null
		and menu_bgm_player.is_bgm_enabled
		and menu_bgm_player.get_track_count() > 0
	)
	if audio_analyzer != null:
		audio_analyzer.set_live_monitoring(should_monitor)
	if reactive_background != null:
		reactive_background.set_menu_bgm_active(should_monitor)
	if reactive_particles_layer != null:
		reactive_particles_layer.set_audio_active(should_monitor)


func _format_song_display_title(p_raw_path: String) -> String:
	var normalized: String = p_raw_path.strip_edges().replace("\\", "/")
	var decoded_full: String = normalized.uri_decode().uri_decode()
	var lower_full: String = decoded_full.to_lower()
	var doc_marker_idx: int = lower_full.rfind("/document/")
	var segment: String = decoded_full.substr(doc_marker_idx + 10) if doc_marker_idx >= 0 else decoded_full

	var saf_prefixes: PackedStringArray = PackedStringArray([
		"document:",
		"primary:music/",
		"primary:download/",
		"primary:downloads/",
		"primary:",
		"audio:",
	])
	var stripped_prefix: bool = true
	while stripped_prefix:
		stripped_prefix = false
		var trimmed: String = segment.strip_edges()
		var low: String = trimmed.to_lower()
		for i: int in range(saf_prefixes.size()):
			var prefix: String = saf_prefixes[i]
			if low.begins_with(prefix):
				segment = trimmed.substr(prefix.length())
				stripped_prefix = true
				break

	var file_part: String = segment.get_file()
	if file_part.is_empty():
		file_part = segment
	var colon_idx: int = file_part.rfind(":")
	if colon_idx >= 0 and colon_idx < file_part.length() - 1:
		file_part = file_part.substr(colon_idx + 1)

	var ext_lower: String = file_part.get_extension().to_lower()
	var base_name: String = file_part.get_basename() if SUPPORTED_AUDIO_EXTENSIONS.has(ext_lower) else file_part
	var cleaned: String = " ".join(base_name.replace("\t", " ").split(" ", false)).strip_edges()
	return cleaned if not cleaned.is_empty() else "Pista"


func _strip_trailing_content_hash(p_stem: String) -> String:
	var trimmed: String = p_stem.strip_edges()
	var underscore_idx: int = trimmed.rfind("_")
	if underscore_idx <= 0:
		return trimmed
	var suffix: String = trimmed.substr(underscore_idx + 1)
	if suffix.length() != 12:
		return trimmed
	for i: int in range(12):
		var code: int = suffix.unicode_at(i)
		var is_hex: bool = (
			(code >= 48 and code <= 57)
			or (code >= 97 and code <= 102)
			or (code >= 65 and code <= 70)
		)
		if not is_hex:
			return trimmed
	return trimmed.substr(0, underscore_idx)


func _resolve_imported_song_title(
	p_raw_source_path: String,
	p_audio_bytes: PackedByteArray = PackedByteArray(),
	p_persisted_file_path: String = ""
) -> String:
	# Priority 1: Binary metadata tags (ID3v2 / ID3v1 / Vorbis Comments)
	var meta_title: String = ""
	if not p_audio_bytes.is_empty():
		meta_title = AudioAnalyzer.extract_audio_metadata_title(p_audio_bytes)
	elif not p_persisted_file_path.is_empty():
		meta_title = AudioAnalyzer.extract_audio_metadata_title_from_file(p_persisted_file_path)
	if not meta_title.is_empty():
		return meta_title

	# Priority 2: Clean URI/filename title as long as it is NOT purely numeric
	var uri_title: String = _format_song_display_title(p_raw_source_path)
	var stem_candidate: String = _strip_trailing_content_hash(uri_title)
	if not stem_candidate.is_empty() and stem_candidate != "Pista" and not stem_candidate.is_valid_int():
		return uri_title

	# Priority 3: Purely numeric MediaStore ID (e.g. "1000009633") -> "Pista Importada #<ID>"
	if stem_candidate.is_valid_int():
		return "Pista Importada #%s" % stem_candidate

	return "Pista Importada"


func _reload_all_track_lists() -> void:
	_song_entries.clear()
	_imported_entries.clear()

	var seen_songs: Dictionary = {}
	_song_entries.append({
		"is_demo": true,
		"song_key": ChartCacheRepository.BUILTIN_DEMO_SONG_KEY,
		"audio_path": "",
		"title": "Demo Integrada (128 BPM)",
		"title_resolved": true,
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
				"title": _format_song_display_title(song_path),
				"title_resolved": true,
				"source_tag": "LOCAL",
			})

	var seen_imported: Dictionary = {}
	var persisted_entries: Array[Dictionary] = _load_imported_catalog_entries()
	var titles_upgraded: Dictionary = {}
	for j: int in range(persisted_entries.size()):
		var item: Dictionary = persisted_entries[j]
		var item_path: String = str(item.get("audio_path", "")).strip_edges()
		if item_path.is_empty() or not FileAccess.file_exists(item_path):
			continue
		var item_key: String = str(item.get("song_key", "")).strip_edges()
		if item_key.is_empty():
			item_key = ChartCacheRepository.normalize_song_key(item_path)
		if not seen_imported.has(item_key):
			seen_imported[item_key] = true
			var stored_title: String = str(item.get("title", "")).strip_edges()
			var title_source: String = stored_title if not stored_title.is_empty() else item_path
			var final_title: String = _resolve_imported_song_title(title_source, PackedByteArray(), item_path)
			if final_title != stored_title:
				titles_upgraded[item_key] = final_title
			_imported_entries.append({
				"is_demo": false,
				"song_key": item_key,
				"audio_path": item_path,
				"title": final_title,
				"title_resolved": true,
				"source_tag": "IMPORTADA",
			})

	if not titles_upgraded.is_empty():
		_update_persisted_imported_titles(titles_upgraded)

	# Also include any audio files present inside user://imported_songs/ not yet listed in config
	var disk_imported_paths: PackedStringArray = _scan_imported_songs_dir()
	for k: int in range(disk_imported_paths.size()):
		var disk_path: String = disk_imported_paths[k]
		var disk_key: String = ChartCacheRepository.normalize_song_key(disk_path)
		if not seen_imported.has(disk_key) and FileAccess.file_exists(disk_path):
			seen_imported[disk_key] = true
			_imported_entries.append({
				"is_demo": false,
				"song_key": disk_key,
				"audio_path": disk_path,
				"title": _resolve_imported_song_title(disk_path, PackedByteArray(), disk_path),
				"title_resolved": true,
				"source_tag": "IMPORTADA",
			})

	if _selected_entry.is_empty() and not _song_entries.is_empty():
		_selected_entry = _song_entries[0].duplicate()

	_rebuild_songs_list_ui()
	_rebuild_imported_list_ui()


func _update_persisted_imported_titles(p_upgraded_titles: Dictionary) -> void:
	if p_upgraded_titles.is_empty() or not FileAccess.file_exists(_recent_tracks_path):
		return
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(_recent_tracks_path) != OK:
		return
	var titles_map: Dictionary = {}
	var raw_titles: Variant = cfg.get_value("recent_meta", "titles", {})
	if raw_titles is Dictionary:
		titles_map = (raw_titles as Dictionary).duplicate()
	var keys: Array = p_upgraded_titles.keys()
	for i: int in range(keys.size()):
		var k: String = str(keys[i])
		titles_map[k] = str(p_upgraded_titles[k])
	cfg.set_value("recent_meta", "titles", titles_map)
	cfg.save(_recent_tracks_path)


func _scan_imported_songs_dir() -> PackedStringArray:
	var found: Array[String] = []
	var normalized_dir: String = _imported_songs_dir.trim_suffix("/")
	var dir: DirAccess = DirAccess.open(normalized_dir)
	if dir == null:
		return PackedStringArray()

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if not dir.current_is_dir() and not entry.begins_with("."):
			var ext: String = entry.get_extension().to_lower()
			if SUPPORTED_AUDIO_EXTENSIONS.has(ext):
				found.append("%s/%s" % [normalized_dir, entry])
		entry = dir.get_next()
	dir.list_dir_end()

	found.sort()
	return PackedStringArray(found)


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


func _load_imported_catalog_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not FileAccess.file_exists(_recent_tracks_path):
		return entries

	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(_recent_tracks_path) != OK:
		return entries

	var raw_paths: Variant = cfg.get_value("recent", "paths", PackedStringArray())
	var titles_map: Dictionary = {}
	var raw_titles: Variant = cfg.get_value("recent_meta", "titles", {})
	if raw_titles is Dictionary:
		titles_map = raw_titles as Dictionary

	var keys_map: Dictionary = {}
	var raw_keys: Variant = cfg.get_value("recent_meta", "song_keys", {})
	if raw_keys is Dictionary:
		keys_map = raw_keys as Dictionary

	var path_list: Array[String] = []
	if raw_paths is PackedStringArray:
		var packed: PackedStringArray = raw_paths as PackedStringArray
		for i: int in range(packed.size()):
			var p: String = packed[i].strip_edges()
			if not p.is_empty():
				path_list.append(p)
	elif raw_paths is Array:
		var arr: Array = raw_paths as Array
		for i: int in range(arr.size()):
			var p: String = str(arr[i]).strip_edges()
			if not p.is_empty():
				path_list.append(p)

	for idx: int in range(path_list.size()):
		var audio_path: String = path_list[idx]
		var norm_path: String = ChartCacheRepository.normalize_song_key(audio_path)
		var song_key: String = str(keys_map.get(norm_path, norm_path)).strip_edges()
		if song_key.is_empty():
			song_key = norm_path
		var title: String = str(titles_map.get(song_key, titles_map.get(norm_path, ""))).strip_edges()
		entries.append({
			"audio_path": audio_path,
			"song_key": song_key,
			"title": title,
		})

	return entries


func _load_recent_tracks() -> PackedStringArray:
	var catalog: Array[Dictionary] = _load_imported_catalog_entries()
	var result: Array[String] = []
	for i: int in range(catalog.size()):
		var p: String = str(catalog[i].get("audio_path", "")).strip_edges()
		if not p.is_empty():
			result.append(p)
	return PackedStringArray(result)


func _save_recent_track(
	p_audio_path: String,
	p_display_title: String = "",
	p_song_key: String = ""
) -> void:
	var existing_entries: Array[Dictionary] = _load_imported_catalog_entries()
	var target_norm: String = ChartCacheRepository.normalize_song_key(p_audio_path)
	var target_key: String = p_song_key.strip_edges() if not p_song_key.strip_edges().is_empty() else target_norm
	var target_title: String = p_display_title.strip_edges() if not p_display_title.strip_edges().is_empty() else _format_song_display_title(p_audio_path)

	var updated_paths: Array[String] = [p_audio_path]
	var updated_titles: Dictionary = {}
	var updated_keys: Dictionary = {}
	updated_titles[target_key] = target_title
	updated_keys[target_norm] = target_key

	for i: int in range(existing_entries.size()):
		var entry: Dictionary = existing_entries[i]
		var item_path: String = str(entry.get("audio_path", "")).strip_edges()
		if item_path.is_empty():
			continue
		var item_norm: String = ChartCacheRepository.normalize_song_key(item_path)
		var item_key: String = str(entry.get("song_key", item_norm)).strip_edges()
		if item_key.is_empty():
			item_key = item_norm
		if item_norm != target_norm and item_key != target_key and updated_paths.size() < MAX_RECENT_TRACKS:
			updated_paths.append(item_path)
			updated_keys[item_norm] = item_key
			var existing_title: String = str(entry.get("title", "")).strip_edges()
			if not existing_title.is_empty():
				updated_titles[item_key] = existing_title

	var parent_dir: String = _recent_tracks_path.get_base_dir()
	if not parent_dir.is_empty() and parent_dir != "user://":
		DirAccess.make_dir_recursive_absolute(parent_dir)

	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("recent", "paths", PackedStringArray(updated_paths))
	cfg.set_value("recent_meta", "titles", updated_titles)
	cfg.set_value("recent_meta", "song_keys", updated_keys)
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
		var entry_is_demo: bool = entry.get("is_demo", false) as bool
		var entry_title_resolved: bool = entry.get("title_resolved", false) as bool
		var entry_audio_path: String = str(entry.get("audio_path", ""))
		var entry_raw_title: String = str(entry.get("title", "")).strip_edges()
		var title: String = entry_raw_title
		if entry_is_demo or (entry_title_resolved and not entry_raw_title.is_empty()):
			title = entry_raw_title if not entry_raw_title.is_empty() else "Pista"
		elif not entry_raw_title.is_empty():
			title = _format_song_display_title(entry_raw_title)
		elif not entry_audio_path.is_empty():
			title = _format_song_display_title(entry_audio_path)
		else:
			title = "Pista"
		var summary: Dictionary = _chart_cache_repo.load_song_summary(song_key)
		var has_record: bool = summary.get("has_record", false) as bool
		var best_rank: String = str(summary.get("best_rank", ""))

		var row_btn: Button = Button.new()
		row_btn.name = "%s_%d" % [p_prefix, idx]
		row_btn.text = ""
		row_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		row_btn.custom_minimum_size = Vector2(0.0, SONG_ROW_HEIGHT_PX)
		row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_apply_song_row_style(row_btn, idx < count - 1)
		row_btn.pressed.connect(_on_song_row_pressed.bind(entry))

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
	_set_option_highlight(_mode_double_tap_button, _selected_note_type_mode == AutoChartGenerator.NoteTypeMode.DOUBLE_TAP)
	_set_option_highlight(_mode_hold_double_tap_button, _selected_note_type_mode == AutoChartGenerator.NoteTypeMode.HOLD_AND_DOUBLE_TAP)

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


func _refresh_particle_controls() -> void:
	for i: int in range(ReactiveParticlesConfig.SUPPORTED_TYPES.size()):
		var type_id: String = ReactiveParticlesConfig.SUPPORTED_TYPES[i]
		var btn: Button = _particles_type_buttons.get(type_id, null) as Button
		if btn != null:
			_set_option_highlight(btn, _particles_config.particle_type == type_id)

	var is_none_selected: bool = _particles_config.particle_type == ReactiveParticlesConfig.TYPE_NONE
	var sub_alpha: float = 0.45 if is_none_selected else 1.0
	if _particles_density_label != null:
		_particles_density_label.modulate.a = sub_alpha
	if _particles_density_row != null:
		_particles_density_row.modulate.a = sub_alpha
	if _particles_reactivity_label != null:
		_particles_reactivity_label.modulate.a = sub_alpha
	if _particles_reactivity_row != null:
		_particles_reactivity_row.modulate.a = sub_alpha

	for j: int in range(ReactiveParticlesConfig.SUPPORTED_LEVELS.size()):
		var level_id: String = ReactiveParticlesConfig.SUPPORTED_LEVELS[j]
		var density_btn: Button = _particles_density_buttons.get(level_id, null) as Button
		if density_btn != null:
			density_btn.disabled = is_none_selected
			_set_option_highlight(density_btn, _particles_config.density == level_id)
		var react_btn: Button = _particles_reactivity_buttons.get(level_id, null) as Button
		if react_btn != null:
			react_btn.disabled = is_none_selected
			_set_option_highlight(react_btn, _particles_config.music_reactivity == level_id)


func _refresh_background_controls() -> void:
	for i: int in range(ReactiveBackgroundConfig.SUPPORTED_STYLES.size()):
		var style_id: String = ReactiveBackgroundConfig.SUPPORTED_STYLES[i]
		var style_btn: Button = _bg_style_buttons.get(style_id, null) as Button
		if style_btn != null:
			_set_option_highlight(style_btn, _bg_config.style == style_id)

	for j: int in range(ReactiveBackgroundConfig.SUPPORTED_LEVELS.size()):
		var level_id: String = ReactiveBackgroundConfig.SUPPORTED_LEVELS[j]
		var level_btn: Button = _bg_reactivity_buttons.get(level_id, null) as Button
		if level_btn != null:
			_set_option_highlight(level_btn, _bg_config.reactivity == level_id)


func _refresh_gameplay_effects_controls() -> void:
	for i: int in range(GameplayEffectsConfig.SUPPORTED_HIT_EFFECTS.size()):
		var hit_id: String = GameplayEffectsConfig.SUPPORTED_HIT_EFFECTS[i]
		var hit_btn: Button = _hit_effect_buttons.get(hit_id, null) as Button
		if hit_btn != null:
			_set_option_highlight(hit_btn, _effects_config.hit_effect == hit_id)

	for j: int in range(GameplayEffectsConfig.SUPPORTED_TOUCH_EFFECTS.size()):
		var touch_id: String = GameplayEffectsConfig.SUPPORTED_TOUCH_EFFECTS[j]
		var touch_btn: Button = _touch_effect_buttons.get(touch_id, null) as Button
		if touch_btn != null:
			_set_option_highlight(touch_btn, _effects_config.touch_effect == touch_id)

	for k: int in range(GameplayEffectsConfig.SUPPORTED_VANISH_EFFECTS.size()):
		var vanish_id: String = GameplayEffectsConfig.SUPPORTED_VANISH_EFFECTS[k]
		var vanish_btn: Button = _vanish_effect_buttons.get(vanish_id, null) as Button
		if vanish_btn != null:
			_set_option_highlight(vanish_btn, _effects_config.vanish_effect == vanish_id)


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
	p_button.add_theme_color_override("font_disabled_color", text_col)


func _apply_stylebox_to_button(p_button: Button, p_style: StyleBox) -> void:
	if p_button == null or p_style == null:
		return
	p_button.add_theme_stylebox_override("normal", p_style)
	p_button.add_theme_stylebox_override("hover", p_style)
	p_button.add_theme_stylebox_override("pressed", p_style)
	p_button.add_theme_stylebox_override("focus", p_style)
	p_button.add_theme_stylebox_override("disabled", p_style)


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

	_style_loading_track = StyleBoxFlat.new()
	_style_loading_track.bg_color = Color(0.08, 0.12, 0.22, 0.92)
	_style_loading_track.border_color = Color(0.30, 0.72, 0.92, 0.55)
	_style_loading_track.set_border_width_all(2)
	_style_loading_track.set_corner_radius_all(10)

	_style_loading_fill = StyleBoxFlat.new()
	_style_loading_fill.bg_color = Color(0.28, 0.94, 1.0, 0.95)
	_style_loading_fill.set_corner_radius_all(8)
	_style_loading_fill.shadow_color = Color(0.24, 0.92, 1.0, 0.45)
	_style_loading_fill.shadow_size = 8

	_style_tab_indicator = StyleBoxFlat.new()
	_style_tab_indicator.bg_color = Color(0.42, 0.98, 1.0, 1.0)
	_style_tab_indicator.set_corner_radius_all(3)
	_style_tab_indicator.shadow_color = Color(0.22, 0.92, 1.0, 0.65)
	_style_tab_indicator.shadow_size = 8


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
	_font_registry.apply_global_font_override(_loading_title_label, 3)
	_font_registry.apply_global_font_override(_loading_stage_label, 2)
	_font_registry.apply_global_font_override(_loading_percent_label, 2)


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
	_build_loading_overlay_ui()

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

	_touch_preview_layer = Control.new()
	_touch_preview_layer.name = "TouchPreviewLayer"
	_touch_preview_layer.z_index = TOUCH_PREVIEW_Z_INDEX
	_touch_preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_preview_layer.draw.connect(_draw_touch_preview_layer)
	add_child(_touch_preview_layer)
	_touch_preview_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


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

	_tabs_bar_wrapper = Control.new()
	_tabs_bar_wrapper.name = "TopTabsBarWrapper"
	_tabs_bar_wrapper.custom_minimum_size = Vector2(0.0, 92.0)
	_tabs_bar_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs_bar_wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	_browser_screen_container.add_child(_tabs_bar_wrapper)

	_tabs_row = HBoxContainer.new()
	_tabs_row.name = "TopTabsRow"
	_tabs_row.add_theme_constant_override("separation", 10)
	_tabs_bar_wrapper.add_child(_tabs_row)
	_tabs_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_tabs_row.offset_bottom = 84.0

	_tab_songs_button = _create_tab_button("TabSongsButton", "CANCIONES")
	_tab_songs_button.pressed.connect(select_tab.bind(MenuTab.SONGS))
	_tabs_row.add_child(_tab_songs_button)

	_tab_import_button = _create_tab_button("TabImportButton", "IMPORTAR")
	_tab_import_button.pressed.connect(select_tab.bind(MenuTab.IMPORT))
	_tabs_row.add_child(_tab_import_button)

	_tab_settings_button = _create_tab_button("TabSettingsButton", "AJUSTES")
	_tab_settings_button.pressed.connect(select_tab.bind(MenuTab.SETTINGS))
	_tabs_row.add_child(_tab_settings_button)

	_tab_indicator_bar = Panel.new()
	_tab_indicator_bar.name = "TabActiveIndicatorBar"
	_tab_indicator_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab_indicator_bar.position = Vector2(0.0, 85.0)
	_tab_indicator_bar.size = Vector2(120.0, TAB_INDICATOR_HEIGHT_PX)
	_tab_indicator_bar.add_theme_stylebox_override("panel", _style_tab_indicator)
	_tabs_bar_wrapper.add_child(_tab_indicator_bar)

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

	_tab_content_viewport = Control.new()
	_tab_content_viewport.name = "TabContentViewport"
	_tab_content_viewport.clip_contents = true
	_tab_content_viewport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_content_viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_content_viewport.mouse_filter = Control.MOUSE_FILTER_PASS
	_tab_content_viewport.resized.connect(_on_tab_viewport_resized)
	sheet_inner.add_child(_tab_content_viewport)

	# Tab 1: CANCIONES
	_songs_scroll = ScrollContainer.new()
	_songs_scroll.name = "SongsTabScroll"
	_tab_content_viewport.add_child(_songs_scroll)
	_songs_scroll.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_songs_tab_container = _songs_scroll

	_songs_list_vbox = VBoxContainer.new()
	_songs_list_vbox.name = "SongsListVBox"
	_songs_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_songs_list_vbox.add_theme_constant_override("separation", 0)
	_songs_scroll.add_child(_songs_list_vbox)
	_configure_touch_scroll_container(_songs_scroll)

	# Tab 2: IMPORTAR
	var import_vbox: VBoxContainer = VBoxContainer.new()
	import_vbox.name = "ImportTabContainer"
	import_vbox.add_theme_constant_override("separation", 16)
	import_vbox.visible = false
	_tab_content_viewport.add_child(import_vbox)
	import_vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
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

	_import_scroll = ScrollContainer.new()
	_import_scroll.name = "ImportedListScroll"
	_import_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_import_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_vbox.add_child(_import_scroll)

	_import_list_vbox = VBoxContainer.new()
	_import_list_vbox.name = "ImportedListVBox"
	_import_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_import_list_vbox.add_theme_constant_override("separation", 0)
	_import_scroll.add_child(_import_list_vbox)
	_configure_touch_scroll_container(_import_scroll)

	# Tab 3: AJUSTES (wrapped in ScrollContainer for touch scrolling and future growth)
	_settings_scroll = ScrollContainer.new()
	_settings_scroll.name = "SettingsTabScroll"
	_settings_scroll.visible = false
	_tab_content_viewport.add_child(_settings_scroll)
	_settings_scroll.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_settings_tab_container = _settings_scroll

	var settings_margin: MarginContainer = MarginContainer.new()
	settings_margin.name = "SettingsTabContainer"
	settings_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_margin.add_theme_constant_override("margin_left", 28)
	settings_margin.add_theme_constant_override("margin_right", 28)
	settings_margin.add_theme_constant_override("margin_top", 28)
	settings_margin.add_theme_constant_override("margin_bottom", 28)
	_settings_scroll.add_child(settings_margin)

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

	settings_vbox.add_child(_create_white_divider("SettingsDivider_2", 0))

	var particles_header: Label = Label.new()
	particles_header.name = "SettingsParticlesHeader"
	particles_header.text = "PARTÍCULAS REACTIVAS"
	particles_header.add_theme_font_size_override("font_size", SETTINGS_LABEL_FONT_SIZE)
	particles_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	settings_vbox.add_child(particles_header)

	var particles_type_label: Label = Label.new()
	particles_type_label.name = "ParticlesTypeLabel"
	particles_type_label.text = "TIPO DE PARTÍCULAS"
	particles_type_label.add_theme_font_size_override("font_size", 30)
	particles_type_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
	settings_vbox.add_child(particles_type_label)

	_particles_type_buttons.clear()
	var particle_type_rows: Array[PackedStringArray] = [
		PackedStringArray([ReactiveParticlesConfig.TYPE_NONE, ReactiveParticlesConfig.TYPE_CIRCLES]),
		PackedStringArray([ReactiveParticlesConfig.TYPE_SQUARES, ReactiveParticlesConfig.TYPE_MIST]),
		PackedStringArray([ReactiveParticlesConfig.TYPE_SPARKLES, ReactiveParticlesConfig.TYPE_SHOOTING_STARS]),
	]
	for row_idx: int in range(particle_type_rows.size()):
		var type_row: HBoxContainer = HBoxContainer.new()
		type_row.name = "ParticlesTypeRow%d" % (row_idx + 1)
		type_row.add_theme_constant_override("separation", 12)
		settings_vbox.add_child(type_row)

		var row_ids: PackedStringArray = particle_type_rows[row_idx]
		for col_idx: int in range(row_ids.size()):
			var type_id: String = row_ids[col_idx]
			var type_btn: Button = _create_compact_settings_button(
				"ParticlesType_%s" % type_id,
				ReactiveParticlesConfig.type_to_label(type_id)
			)
			type_btn.pressed.connect(_on_particles_type_selected.bind(type_id))
			type_row.add_child(type_btn)
			_particles_type_buttons[type_id] = type_btn

	_particles_density_label = Label.new()
	_particles_density_label.name = "ParticlesDensityLabel"
	_particles_density_label.text = "DENSIDAD"
	_particles_density_label.add_theme_font_size_override("font_size", 30)
	_particles_density_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
	settings_vbox.add_child(_particles_density_label)

	_particles_density_buttons.clear()
	_particles_density_row = HBoxContainer.new()
	_particles_density_row.name = "ParticlesDensityRow"
	_particles_density_row.add_theme_constant_override("separation", 12)
	settings_vbox.add_child(_particles_density_row)

	for d_idx: int in range(ReactiveParticlesConfig.SUPPORTED_LEVELS.size()):
		var d_id: String = ReactiveParticlesConfig.SUPPORTED_LEVELS[d_idx]
		var d_btn: Button = _create_compact_settings_button(
			"ParticlesDensity_%s" % d_id,
			ReactiveParticlesConfig.level_to_label(d_id)
		)
		d_btn.pressed.connect(_on_particles_density_selected.bind(d_id))
		_particles_density_row.add_child(d_btn)
		_particles_density_buttons[d_id] = d_btn

	_particles_reactivity_label = Label.new()
	_particles_reactivity_label.name = "ParticlesReactivityLabel"
	_particles_reactivity_label.text = "REACCIÓN MUSICAL"
	_particles_reactivity_label.add_theme_font_size_override("font_size", 30)
	_particles_reactivity_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
	settings_vbox.add_child(_particles_reactivity_label)

	_particles_reactivity_buttons.clear()
	_particles_reactivity_row = HBoxContainer.new()
	_particles_reactivity_row.name = "ParticlesReactivityRow"
	_particles_reactivity_row.add_theme_constant_override("separation", 12)
	settings_vbox.add_child(_particles_reactivity_row)

	for r_idx: int in range(ReactiveParticlesConfig.SUPPORTED_LEVELS.size()):
		var r_id: String = ReactiveParticlesConfig.SUPPORTED_LEVELS[r_idx]
		var r_btn: Button = _create_compact_settings_button(
			"ParticlesReactivity_%s" % r_id,
			ReactiveParticlesConfig.level_to_label(r_id)
		)
		r_btn.pressed.connect(_on_particles_reactivity_selected.bind(r_id))
		_particles_reactivity_row.add_child(r_btn)
		_particles_reactivity_buttons[r_id] = r_btn

	settings_vbox.add_child(_create_white_divider("SettingsDivider_3", 0))

	var bg_header: Label = Label.new()
	bg_header.name = "SettingsBackgroundHeader"
	bg_header.text = "FONDO REACTIVO"
	bg_header.add_theme_font_size_override("font_size", SETTINGS_LABEL_FONT_SIZE)
	bg_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	settings_vbox.add_child(bg_header)

	var bg_style_label: Label = Label.new()
	bg_style_label.name = "BackgroundStyleLabel"
	bg_style_label.text = "ESTILO DE FONDO"
	bg_style_label.add_theme_font_size_override("font_size", 30)
	bg_style_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
	settings_vbox.add_child(bg_style_label)

	_bg_style_buttons.clear()
	var bg_style_rows: Array[PackedStringArray] = [
		PackedStringArray([ReactiveBackgroundConfig.STYLE_CLASSIC, ReactiveBackgroundConfig.STYLE_NEBULA]),
		PackedStringArray([ReactiveBackgroundConfig.STYLE_AURORA, ReactiveBackgroundConfig.STYLE_ECLIPSE]),
	]
	for bg_row_idx: int in range(bg_style_rows.size()):
		var bg_row: HBoxContainer = HBoxContainer.new()
		bg_row.name = "BackgroundStyleRow%d" % (bg_row_idx + 1)
		bg_row.add_theme_constant_override("separation", 12)
		settings_vbox.add_child(bg_row)

		var row_styles: PackedStringArray = bg_style_rows[bg_row_idx]
		for col_idx: int in range(row_styles.size()):
			var b_id: String = row_styles[col_idx]
			var b_btn: Button = _create_compact_settings_button(
				"BackgroundStyle_%s" % b_id,
				ReactiveBackgroundConfig.style_to_label(b_id)
			)
			b_btn.pressed.connect(_on_bg_style_selected.bind(b_id))
			bg_row.add_child(b_btn)
			_bg_style_buttons[b_id] = b_btn

	var bg_react_label: Label = Label.new()
	bg_react_label.name = "BackgroundReactivityLabel"
	bg_react_label.text = "INTENSIDAD MUSICAL DEL FONDO"
	bg_react_label.add_theme_font_size_override("font_size", 30)
	bg_react_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
	settings_vbox.add_child(bg_react_label)

	_bg_reactivity_buttons.clear()
	var bg_react_row: HBoxContainer = HBoxContainer.new()
	bg_react_row.name = "BackgroundReactivityRow"
	bg_react_row.add_theme_constant_override("separation", 12)
	settings_vbox.add_child(bg_react_row)

	for br_idx: int in range(ReactiveBackgroundConfig.SUPPORTED_LEVELS.size()):
		var br_id: String = ReactiveBackgroundConfig.SUPPORTED_LEVELS[br_idx]
		var br_btn: Button = _create_compact_settings_button(
			"BackgroundReactivity_%s" % br_id,
			ReactiveBackgroundConfig.level_to_label(br_id)
		)
		br_btn.pressed.connect(_on_bg_reactivity_selected.bind(br_id))
		bg_react_row.add_child(br_btn)
		_bg_reactivity_buttons[br_id] = br_btn

	settings_vbox.add_child(_create_white_divider("SettingsDivider_4", 0))

	var hit_fx_header: Label = Label.new()
	hit_fx_header.name = "SettingsHitEffectHeader"
	hit_fx_header.text = "EFECTO DE ACIERTO"
	hit_fx_header.add_theme_font_size_override("font_size", SETTINGS_LABEL_FONT_SIZE)
	hit_fx_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	settings_vbox.add_child(hit_fx_header)

	_hit_effect_buttons.clear()
	var hit_fx_row: HBoxContainer = HBoxContainer.new()
	hit_fx_row.name = "HitEffectRow"
	hit_fx_row.add_theme_constant_override("separation", 10)
	settings_vbox.add_child(hit_fx_row)

	for hf_idx: int in range(GameplayEffectsConfig.SUPPORTED_HIT_EFFECTS.size()):
		var hf_id: String = GameplayEffectsConfig.SUPPORTED_HIT_EFFECTS[hf_idx]
		var hf_btn: Button = _create_compact_settings_button(
			"HitEffect_%s" % hf_id,
			GameplayEffectsConfig.hit_effect_to_label(hf_id)
		)
		hf_btn.add_theme_font_size_override("font_size", 28)
		hf_btn.pressed.connect(_on_hit_effect_selected.bind(hf_id))
		hit_fx_row.add_child(hf_btn)
		_hit_effect_buttons[hf_id] = hf_btn

	settings_vbox.add_child(_create_white_divider("SettingsDivider_5", 0))

	var touch_fx_header: Label = Label.new()
	touch_fx_header.name = "SettingsTouchEffectHeader"
	touch_fx_header.text = "EFECTO TÁCTIL"
	touch_fx_header.add_theme_font_size_override("font_size", SETTINGS_LABEL_FONT_SIZE)
	touch_fx_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	settings_vbox.add_child(touch_fx_header)

	_touch_effect_buttons.clear()
	var touch_fx_row: HBoxContainer = HBoxContainer.new()
	touch_fx_row.name = "TouchEffectRow"
	touch_fx_row.add_theme_constant_override("separation", 10)
	settings_vbox.add_child(touch_fx_row)

	for tf_idx: int in range(GameplayEffectsConfig.SUPPORTED_TOUCH_EFFECTS.size()):
		var tf_id: String = GameplayEffectsConfig.SUPPORTED_TOUCH_EFFECTS[tf_idx]
		var tf_btn: Button = _create_compact_settings_button(
			"TouchEffect_%s" % tf_id,
			GameplayEffectsConfig.touch_effect_to_label(tf_id)
		)
		tf_btn.add_theme_font_size_override("font_size", 26)
		tf_btn.pressed.connect(_on_touch_effect_selected.bind(tf_id))
		touch_fx_row.add_child(tf_btn)
		_touch_effect_buttons[tf_id] = tf_btn

	settings_vbox.add_child(_create_white_divider("SettingsDivider_6", 0))

	var vanish_fx_header: Label = Label.new()
	vanish_fx_header.name = "SettingsVanishEffectHeader"
	vanish_fx_header.text = "EFECTO DE DESVANECIMIENTO"
	vanish_fx_header.add_theme_font_size_override("font_size", SETTINGS_LABEL_FONT_SIZE)
	vanish_fx_header.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	settings_vbox.add_child(vanish_fx_header)

	_vanish_effect_buttons.clear()
	var vanish_fx_row: HBoxContainer = HBoxContainer.new()
	vanish_fx_row.name = "VanishEffectRow"
	vanish_fx_row.add_theme_constant_override("separation", 10)
	settings_vbox.add_child(vanish_fx_row)

	for vf_idx: int in range(GameplayEffectsConfig.SUPPORTED_VANISH_EFFECTS.size()):
		var vf_id: String = GameplayEffectsConfig.SUPPORTED_VANISH_EFFECTS[vf_idx]
		var vf_btn: Button = _create_compact_settings_button(
			"VanishEffect_%s" % vf_id,
			GameplayEffectsConfig.vanish_effect_to_label(vf_id)
		)
		vf_btn.add_theme_font_size_override("font_size", 28)
		vf_btn.pressed.connect(_on_vanish_effect_selected.bind(vf_id))
		vanish_fx_row.add_child(vf_btn)
		_vanish_effect_buttons[vf_id] = vf_btn

	_configure_touch_scroll_container(_settings_scroll)


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

	_modal_scroll = ScrollContainer.new()
	_modal_scroll.name = "SongModalScroll"
	_song_modal_panel.add_child(_modal_scroll)

	_modal_vbox = VBoxContainer.new()
	_modal_vbox.name = "SongModalVBox"
	_modal_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal_vbox.add_theme_constant_override("separation", 18)
	_modal_scroll.add_child(_modal_vbox)

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

	var mode_row_1: HBoxContainer = HBoxContainer.new()
	mode_row_1.name = "ModalNoteModeRow1"
	mode_row_1.add_theme_constant_override("separation", 12)
	_modal_vbox.add_child(mode_row_1)

	_mode_tap_hold_button = _create_option_button("ModeTapHoldButton", "TAP + HOLD")
	_mode_tap_hold_button.add_theme_font_size_override("font_size", 30)
	_mode_tap_hold_button.pressed.connect(select_note_type_mode.bind(AutoChartGenerator.NoteTypeMode.TAP_AND_HOLD))
	mode_row_1.add_child(_mode_tap_hold_button)

	_mode_tap_only_button = _create_option_button("ModeTapOnlyButton", "SOLO TAP")
	_mode_tap_only_button.add_theme_font_size_override("font_size", 30)
	_mode_tap_only_button.pressed.connect(select_note_type_mode.bind(AutoChartGenerator.NoteTypeMode.TAP_ONLY))
	mode_row_1.add_child(_mode_tap_only_button)

	var mode_row_2: HBoxContainer = HBoxContainer.new()
	mode_row_2.name = "ModalNoteModeRow2"
	mode_row_2.add_theme_constant_override("separation", 12)
	_modal_vbox.add_child(mode_row_2)

	_mode_double_tap_button = _create_option_button("ModeDoubleTapButton", "DOBLE TAP")
	_mode_double_tap_button.add_theme_font_size_override("font_size", 30)
	_mode_double_tap_button.pressed.connect(select_note_type_mode.bind(AutoChartGenerator.NoteTypeMode.DOUBLE_TAP))
	mode_row_2.add_child(_mode_double_tap_button)

	_mode_hold_double_tap_button = _create_option_button("ModeHoldDoubleTapButton", "HOLD + DOBLE TAP")
	_mode_hold_double_tap_button.add_theme_font_size_override("font_size", 28)
	_mode_hold_double_tap_button.pressed.connect(select_note_type_mode.bind(AutoChartGenerator.NoteTypeMode.HOLD_AND_DOUBLE_TAP))
	mode_row_2.add_child(_mode_hold_double_tap_button)

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

	_configure_touch_scroll_container(_modal_scroll)


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


func _build_loading_overlay_ui() -> void:
	_loading_overlay = ColorRect.new()
	_loading_overlay.name = "SongLoadingOverlay"
	_loading_overlay.color = Color(0.02, 0.03, 0.08, 0.84)
	_loading_overlay.visible = false
	_loading_overlay.z_index = LOADING_OVERLAY_Z_INDEX
	_loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_safe_container.add_child(_loading_overlay)

	_loading_panel = PanelContainer.new()
	_loading_panel.name = "SongLoadingPanel"
	_loading_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_panel.add_theme_stylebox_override("panel", _style_modal_panel)
	_loading_overlay.add_child(_loading_panel)

	var panel_margin: MarginContainer = MarginContainer.new()
	panel_margin.name = "SongLoadingMargin"
	panel_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_margin.add_theme_constant_override("margin_left", 36)
	panel_margin.add_theme_constant_override("margin_right", 36)
	panel_margin.add_theme_constant_override("margin_top", 36)
	panel_margin.add_theme_constant_override("margin_bottom", 34)
	_loading_panel.add_child(panel_margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "SongLoadingVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	panel_margin.add_child(vbox)

	var spinner_center: CenterContainer = CenterContainer.new()
	spinner_center.name = "LoadingSpinnerCenter"
	spinner_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(spinner_center)

	_loading_spinner = Control.new()
	_loading_spinner.name = "LoadingSpinner"
	_loading_spinner.custom_minimum_size = Vector2(96.0, 96.0)
	_loading_spinner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_spinner.draw.connect(_draw_loading_spinner)
	spinner_center.add_child(_loading_spinner)

	_loading_title_label = Label.new()
	_loading_title_label.name = "LoadingTitleLabel"
	_loading_title_label.text = "PROCESANDO CANCIÓN..."
	_loading_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_title_label.add_theme_font_size_override("font_size", 40)
	_loading_title_label.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	vbox.add_child(_loading_title_label)

	_loading_stage_label = Label.new()
	_loading_stage_label.name = "LoadingStageLabel"
	_loading_stage_label.text = "Analizando espectro y ritmo..."
	_loading_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loading_stage_label.add_theme_font_size_override("font_size", 28)
	_loading_stage_label.add_theme_color_override("font_color", COLOR_TEXT_INACTIVE)
	vbox.add_child(_loading_stage_label)

	_loading_progress_track = Panel.new()
	_loading_progress_track.name = "LoadingProgressTrack"
	_loading_progress_track.custom_minimum_size = Vector2(0.0, 22.0)
	_loading_progress_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_loading_progress_track.clip_contents = true
	_loading_progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_progress_track.add_theme_stylebox_override("panel", _style_loading_track)
	vbox.add_child(_loading_progress_track)

	_loading_progress_fill = Panel.new()
	_loading_progress_fill.name = "LoadingProgressFill"
	_loading_progress_fill.position = Vector2.ZERO
	_loading_progress_fill.size = Vector2(0.0, 22.0)
	_loading_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_progress_fill.add_theme_stylebox_override("panel", _style_loading_fill)
	_loading_progress_track.add_child(_loading_progress_fill)

	_loading_percent_label = Label.new()
	_loading_percent_label.name = "LoadingPercentLabel"
	_loading_percent_label.text = "0%"
	_loading_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_percent_label.add_theme_font_size_override("font_size", 28)
	_loading_percent_label.add_theme_color_override("font_color", COLOR_TEXT_ACTIVE)
	vbox.add_child(_loading_percent_label)


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


func _create_compact_settings_button(p_name: String, p_text: String) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.text = p_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, 72.0)
	btn.add_theme_font_size_override("font_size", 32)
	return btn
