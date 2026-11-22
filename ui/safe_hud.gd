class_name SafeHud
extends Control

signal pause_requested()
signal resume_requested()
signal restart_requested()
signal main_menu_requested()

const TOP_BAR_HEIGHT_PX: float = 132.0
const PAUSE_BUTTON_WIDTH_PX: float = 212.0
const PAUSE_BUTTON_HEIGHT_PX: float = 82.0
const DANGER_BAR_HEIGHT_PX: float = 28.0
const DANGER_BAR_LERP_SPEED: float = 9.0
const DANGER_PULSE_SPEED_RAD: float = 9.5
const DANGER_THRESHOLD_AMBER: float = 0.45
const DANGER_THRESHOLD_CRITICAL: float = 0.75
const COLOR_DANGER_CYAN: Color = Color(0.22, 0.92, 1.0, 1.0)
const COLOR_DANGER_AMBER: Color = Color(1.0, 0.76, 0.18, 1.0)
const COLOR_DANGER_CRITICAL: Color = Color(1.0, 0.18, 0.48, 1.0)
const CENTER_BANNER_HEIGHT_PX: float = 156.0
const MODAL_WIDTH_PX: float = 640.0
const MODAL_HEIGHT_PX: float = 490.0
const RESULTS_WIDTH_RATIO: float = 0.90
const RESULTS_MAX_WIDTH_PX: float = 920.0
const RESULTS_HEIGHT_RATIO: float = 0.84
const RESULTS_BUTTON_MIN_HEIGHT_PX: float = 96.0
const COUNTDOWN_BOX_WIDTH_PX: float = 280.0
const COUNTDOWN_BOX_HEIGHT_PX: float = 180.0

const SCORE_FONT_SIZE: int = 50
const ACCURACY_FONT_SIZE: int = 40
const PAUSE_BUTTON_FONT_SIZE: int = 38
const MODAL_BUTTON_FONT_SIZE: int = 36
const COMBO_FONT_SIZE: int = 52
const JUDGMENT_FONT_SIZE: int = 48
const COUNTDOWN_FONT_SIZE: int = 120
const RESULTS_TITLE_FONT_SIZE: int = 54
const RESULTS_RECORD_FONT_SIZE: int = 40
const RESULTS_RANK_FONT_SIZE: int = 250
const RESULTS_STATS_FONT_SIZE: int = 56
const RESULTS_BREAKDOWN_FONT_SIZE: int = 46
const RESULTS_BUTTON_FONT_SIZE: int = 50

const COLOR_RESULTS_GOOD_AMBER: Color = Color(1.0, 0.78, 0.28, 1.0)

const COUNTDOWN_STEP_DURATION_SEC: float = 1.0
const COUNTDOWN_START_SCALE: float = 1.35
const COUNTDOWN_END_ALPHA: float = 0.25

const COMBO_MAX_WIDTH_RATIO: float = 0.44
const COMBO_MIN_SCALE: float = 1.0
const COMBO_MAX_SCALE: float = 1.30
const COMBO_GROWTH_PER_HIT: float = 0.006
const COMBO_POP_IMPULSE: float = 0.14
const COMBO_BASS_BOUNCE_MAX: float = 0.10
const COMBO_DECAY_SPEED: float = 7.5
const HUD_AUTO_FADE_DELAY_SEC: float = 1.0
const HUD_AUTO_FADE_SPEED: float = 3.2

const COLOR_JUDGMENT_READY: Color = Color(0.85, 0.94, 1.0, 1.0)
const COLOR_JUDGMENT_PERFECT: Color = Color(0.32, 1.0, 0.94, 1.0)
const COLOR_JUDGMENT_GREAT: Color = Color(0.35, 1.0, 0.52, 1.0)
const COLOR_JUDGMENT_GOOD: Color = Color(0.42, 0.78, 1.0, 1.0)
const COLOR_JUDGMENT_MISS: Color = Color(1.0, 0.34, 0.44, 1.0)

const SONG_PROGRESS_CONTROL_HEIGHT_PX: float = 44.0
const SONG_PROGRESS_SIDE_INSET_PX: float = 24.0
const SONG_PROGRESS_BOTTOM_MARGIN_PX: float = 36.0
const SONG_PROGRESS_RAIL_INSET_PX: float = 14.0
const SONG_PROGRESS_RAIL_THICKNESS_PX: float = 3.0
const SONG_PROGRESS_SQUARE_HALF_SIZE_PX: float = 7.0
const SONG_PROGRESS_GLOW_HALF_SIZE_PX: float = 10.5
const SONG_PROGRESS_ROTATION_SPEED_RAD: float = 2.4
const COLOR_PROGRESS_TRACK: Color = Color(0.55, 0.78, 0.96, 0.22)
const COLOR_PROGRESS_FILL_GLOW: Color = Color(0.22, 0.88, 1.0, 0.26)
const COLOR_PROGRESS_FILL_CORE: Color = Color(0.45, 0.96, 1.0, 0.88)
const COLOR_PROGRESS_SQUARE_GLOW: Color = Color(0.28, 0.94, 1.0, 0.34)
const COLOR_PROGRESS_SQUARE_CORE: Color = Color(0.84, 0.99, 1.0, 0.98)
const COLOR_PROGRESS_SQUARE_BORDER: Color = Color(0.32, 0.96, 1.0, 1.0)

@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var hit_judge: HitJudge = null
@export var dsp_clock: DSPClock = null
@export var input_adapter: RhythmInputAdapter = null
@export var reactive_background: ReactiveBackground = null
@export var ui_sfx_player: UiSfxPlayer = null

var _safe_container: Control = null
var _top_bar_margin: MarginContainer = null
var _top_bar_hbox: HBoxContainer = null
var _left_stats_vbox: VBoxContainer = null
var _right_controls_vbox: VBoxContainer = null
var _score_label: Label = null
var _accuracy_label: Label = null
var _combo_label: Label = null
var _judgment_label: Label = null
var _countdown_label: Label = null
var _pause_button: Button = null
var _danger_bar_track: Panel = null
var _danger_bar_fill: Panel = null
var _style_danger_track: StyleBoxFlat = null
var _style_danger_fill: StyleBoxFlat = null

var _pause_overlay: ColorRect = null
var _pause_panel: Panel = null
var _pause_vbox: VBoxContainer = null
var _pause_title_label: Label = null
var _resume_button: Button = null
var _restart_button: Button = null
var _pause_menu_button: Button = null

var _results_overlay: ColorRect = null
var _results_panel: Panel = null
var _results_vbox: VBoxContainer = null
var _results_title_label: Label = null
var _results_record_label: Label = null
var _results_rank_label: Label = null
var _results_stats_label: Label = null
var _results_breakdown_grid: GridContainer = null
var _results_perfect_label: Label = null
var _results_great_label: Label = null
var _results_good_label: Label = null
var _results_miss_label: Label = null
var _results_retry_button: Button = null
var _results_menu_button: Button = null

var _style_results_panel: StyleBoxFlat = null
var _style_results_retry: StyleBoxFlat = null
var _style_results_menu: StyleBoxFlat = null

var _countdown_tween: Tween = null
var _is_counting_down: bool = false
var _displayed_score: int = 0
var _displayed_combo: int = 0
var _displayed_accuracy: float = 0.0
var _last_judgment_text: String = "READY"
var _last_displayed_rank: String = ""
var _judgment_color: Color = COLOR_JUDGMENT_READY

var _lane_hold_flags: Array[bool] = [false, false, false, false]
var _combo_base_scale: float = COMBO_MIN_SCALE
var _combo_pop_boost: float = 0.0
var _combo_bass_boost: float = 0.0
var _judgment_pop_boost: float = 0.0
var _banner_idle_sec: float = 0.0
var _banner_alpha: float = 1.0
var _target_danger_ratio: float = 0.0
var _displayed_danger_ratio: float = 0.0
var _danger_pulse_phase: float = 0.0
var _song_progress_bar: Control = null
var _song_total_duration_sec: float = 0.0
var _song_progress: float = 0.0
var _song_progress_completed: bool = false
var _progress_square_angle_rad: float = 0.0
var _font_registry: UiFontRegistry = null


static func compute_song_progress(p_current_sec: float, p_total_sec: float) -> float:
	if p_total_sec <= 0.0:
		return 0.0
	return clampf(p_current_sec / maxf(p_total_sec, 0.001), 0.0, 1.0)


static func compute_letter_rank(p_accuracy_percent: float) -> String:
	if p_accuracy_percent >= 100.0:
		return "SSS+"
	if p_accuracy_percent >= 95.0:
		return "SSS"
	if p_accuracy_percent >= 90.0:
		return "SS"
	if p_accuracy_percent >= 85.0:
		return "S"
	if p_accuracy_percent >= 80.0:
		return "A+"
	if p_accuracy_percent >= 75.0:
		return "A"
	if p_accuracy_percent >= 65.0:
		return "B"
	if p_accuracy_percent >= 50.0:
		return "C"
	return "D"


static func get_rank_color(p_rank: String) -> Color:
	match p_rank:
		"SSS+":
			return Color(0.45, 1.0, 0.98, 1.0)
		"SSS":
			return Color(1.0, 0.92, 0.32, 1.0)
		"SS":
			return Color(1.0, 0.78, 0.24, 1.0)
		"S":
			return Color(1.0, 0.62, 0.26, 1.0)
		"A+":
			return Color(0.35, 1.0, 0.60, 1.0)
		"A":
			return Color(0.45, 0.95, 0.50, 1.0)
		"B":
			return Color(0.40, 0.78, 1.0, 1.0)
		"C":
			return Color(0.95, 0.68, 0.36, 1.0)
		_:
			return Color(1.0, 0.36, 0.44, 1.0)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_ui_nodes()
	_apply_external_fonts()
	connect_dependencies()

	if screen_safe_adapter != null:
		apply_hud_safe_rect(screen_safe_adapter.get_hud_safe_rect())
	else:
		apply_hud_safe_rect(Rect2(64.8, 0.0, 950.4, 1920.0))


func _process(p_delta: float) -> void:
	var dt: float = maxf(0.0, p_delta)

	_combo_pop_boost = maxf(0.0, _combo_pop_boost - (COMBO_DECAY_SPEED * dt))
	_combo_bass_boost = maxf(0.0, _combo_bass_boost - (COMBO_DECAY_SPEED * dt))
	_judgment_pop_boost = maxf(0.0, _judgment_pop_boost - (COMBO_DECAY_SPEED * dt))

	if _is_any_lane_holding():
		_banner_idle_sec = 0.0
		_banner_alpha = 1.0
	else:
		_banner_idle_sec += dt
		if _banner_idle_sec > HUD_AUTO_FADE_DELAY_SEC:
			_banner_alpha = maxf(0.0, _banner_alpha - (HUD_AUTO_FADE_SPEED * dt))

	_apply_banner_visual_transform()
	_update_danger_bar_visual(dt)
	_update_song_progress_visual(dt)


func _exit_tree() -> void:
	_cancel_resume_countdown()


func connect_dependencies() -> void:
	if screen_safe_adapter != null:
		if not screen_safe_adapter.safe_play_rect_changed.is_connected(_on_safe_play_rect_changed):
			screen_safe_adapter.safe_play_rect_changed.connect(_on_safe_play_rect_changed)

	if hit_judge != null:
		if not hit_judge.score_changed.is_connected(_on_score_changed):
			hit_judge.score_changed.connect(_on_score_changed)
		if not hit_judge.note_judged.is_connected(_on_note_judged):
			hit_judge.note_judged.connect(_on_note_judged)
		if not hit_judge.hold_combo_ticked.is_connected(_on_hold_combo_ticked):
			hit_judge.hold_combo_ticked.connect(_on_hold_combo_ticked)
		if not hit_judge.hold_state_changed.is_connected(_on_hold_state_changed):
			hit_judge.hold_state_changed.connect(_on_hold_state_changed)
		if not hit_judge.danger_changed.is_connected(_on_danger_changed):
			hit_judge.danger_changed.connect(_on_danger_changed)

	if reactive_background != null:
		if not reactive_background.bass_kick_pulsed.is_connected(_on_bass_kick_pulsed):
			reactive_background.bass_kick_pulsed.connect(_on_bass_kick_pulsed)

	if dsp_clock != null:
		if not dsp_clock.dsp_time_updated.is_connected(_on_dsp_time_updated):
			dsp_clock.dsp_time_updated.connect(_on_dsp_time_updated)
		if not dsp_clock.playback_finished.is_connected(_on_dsp_playback_finished):
			dsp_clock.playback_finished.connect(_on_dsp_playback_finished)


func apply_hud_safe_rect(p_hud_safe_rect: Rect2) -> void:
	_ensure_ui_nodes()
	var vp_size: Vector2 = size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		var vp_rect: Rect2 = get_viewport_rect()
		if vp_rect.size.x > 1.0 and vp_rect.size.y > 1.0:
			vp_size = vp_rect.size
		else:
			vp_size = Vector2(
				maxf(320.0, p_hud_safe_rect.end.x),
				maxf(480.0, p_hud_safe_rect.end.y)
			)

	_safe_container.position = p_hud_safe_rect.position
	_safe_container.size = p_hud_safe_rect.size

	var safe_w: float = maxf(320.0, p_hud_safe_rect.size.x)
	var safe_h: float = maxf(480.0, p_hud_safe_rect.size.y)

	if _top_bar_margin != null:
		_top_bar_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_top_bar_margin.offset_bottom = _top_bar_margin.get_combined_minimum_size().y

	_sync_danger_bar_fill_rect()

	var banner_w: float = minf(560.0, safe_w * COMBO_MAX_WIDTH_RATIO)
	var banner_x: float = (safe_w - banner_w) * 0.5
	var center_y: float = safe_h * 0.28

	_combo_label.size = Vector2(banner_w, CENTER_BANNER_HEIGHT_PX * 0.52)
	_combo_label.position = Vector2(banner_x, center_y)
	_combo_label.pivot_offset = _combo_label.size * 0.5

	_judgment_label.size = Vector2(banner_w, CENTER_BANNER_HEIGHT_PX * 0.48)
	_judgment_label.position = Vector2(banner_x, center_y + 72.0)
	_judgment_label.pivot_offset = _judgment_label.size * 0.5

	var countdown_size: Vector2 = Vector2(COUNTDOWN_BOX_WIDTH_PX, COUNTDOWN_BOX_HEIGHT_PX)
	_countdown_label.size = countdown_size
	_countdown_label.position = Vector2(
		(safe_w - countdown_size.x) * 0.5,
		(safe_h - countdown_size.y) * 0.42
	)
	_countdown_label.pivot_offset = countdown_size * 0.5

	if _song_progress_bar != null:
		var bar_w: float = maxf(160.0, safe_w - (SONG_PROGRESS_SIDE_INSET_PX * 2.0))
		var bottom_margin: float = SONG_PROGRESS_BOTTOM_MARGIN_PX * clampf(safe_h / 1920.0, 0.55, 1.0)
		var bar_y: float = clampf(
			safe_h - bottom_margin - SONG_PROGRESS_CONTROL_HEIGHT_PX,
			0.0,
			maxf(0.0, safe_h - SONG_PROGRESS_CONTROL_HEIGHT_PX)
		)
		_song_progress_bar.position = Vector2(SONG_PROGRESS_SIDE_INSET_PX, bar_y)
		_song_progress_bar.size = Vector2(bar_w, SONG_PROGRESS_CONTROL_HEIGHT_PX)
		_song_progress_bar.queue_redraw()

	# Full-bleed modal backdrops covering 100% of viewport with centered dialogs
	var full_offset: Vector2 = -p_hud_safe_rect.position
	_pause_overlay.position = full_offset
	_pause_overlay.size = vp_size

	var panel_w: float = minf(MODAL_WIDTH_PX, safe_w - 32.0)
	var panel_h: float = minf(MODAL_HEIGHT_PX, safe_h - 64.0)
	_pause_panel.position = Vector2((vp_size.x - panel_w) * 0.5, (vp_size.y - panel_h) * 0.5)
	_pause_panel.size = Vector2(panel_w, panel_h)
	_pause_vbox.position = Vector2(28.0, 24.0)
	_pause_vbox.size = Vector2(maxf(200.0, panel_w - 56.0), maxf(300.0, panel_h - 48.0))

	_results_overlay.position = full_offset
	_results_overlay.size = vp_size

	var res_w: float = minf(RESULTS_MAX_WIDTH_PX, maxf(300.0, safe_w * RESULTS_WIDTH_RATIO))
	var res_h: float = minf(safe_h - 48.0, maxf(460.0, safe_h * RESULTS_HEIGHT_RATIO))
	_results_panel.position = Vector2((vp_size.x - res_w) * 0.5, (vp_size.y - res_h) * 0.5)
	_results_panel.size = Vector2(res_w, res_h)
	_results_vbox.position = Vector2(30.0, 28.0)
	_results_vbox.size = Vector2(maxf(240.0, res_w - 60.0), maxf(380.0, res_h - 56.0))

	_apply_banner_visual_transform()


func reset_hud_display() -> void:
	_cancel_resume_countdown()
	_displayed_score = 0
	_displayed_combo = 0
	_displayed_accuracy = 0.0
	_last_judgment_text = "READY"
	_last_displayed_rank = ""
	_judgment_color = COLOR_JUDGMENT_READY
	for i: int in range(_lane_hold_flags.size()):
		_lane_hold_flags[i] = false
	_combo_base_scale = COMBO_MIN_SCALE
	_combo_pop_boost = 0.0
	_combo_bass_boost = 0.0
	_judgment_pop_boost = 0.0
	_banner_idle_sec = 0.0
	_banner_alpha = 1.0
	_target_danger_ratio = 0.0
	_displayed_danger_ratio = 0.0
	_danger_pulse_phase = 0.0
	_song_progress = 0.0
	_song_progress_completed = false
	_progress_square_angle_rad = 0.0
	if _song_progress_bar != null:
		_song_progress_bar.queue_redraw()
	if _pause_overlay != null:
		_pause_overlay.visible = false
	if _results_overlay != null:
		_results_overlay.visible = false
	if _pause_button != null:
		_pause_button.disabled = false
	_refresh_labels()
	_apply_banner_visual_transform()
	_sync_danger_bar_fill_rect()


func open_pause_menu() -> void:
	_ensure_ui_nodes()
	if is_results_overlay_open():
		return
	_cancel_resume_countdown()
	if input_adapter != null:
		input_adapter.reset_input_state()
	if dsp_clock != null:
		dsp_clock.pause()
	_pause_overlay.visible = true
	pause_requested.emit()


func close_pause_menu_and_resume() -> void:
	_ensure_ui_nodes()
	_cancel_resume_countdown()
	_pause_overlay.visible = false
	_results_overlay.visible = false
	_pause_button.disabled = true
	_is_counting_down = true
	_countdown_label.visible = true

	_prepare_countdown_step(3)
	_countdown_tween = create_tween()

	_countdown_tween.tween_property(
		_countdown_label,
		"scale",
		Vector2.ONE,
		COUNTDOWN_STEP_DURATION_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_countdown_tween.parallel().tween_property(
		_countdown_label,
		"modulate:a",
		COUNTDOWN_END_ALPHA,
		COUNTDOWN_STEP_DURATION_SEC
	)

	_countdown_tween.tween_callback(_prepare_countdown_step.bind(2))
	_countdown_tween.tween_property(
		_countdown_label,
		"scale",
		Vector2.ONE,
		COUNTDOWN_STEP_DURATION_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_countdown_tween.parallel().tween_property(
		_countdown_label,
		"modulate:a",
		COUNTDOWN_END_ALPHA,
		COUNTDOWN_STEP_DURATION_SEC
	)

	_countdown_tween.tween_callback(_prepare_countdown_step.bind(1))
	_countdown_tween.tween_property(
		_countdown_label,
		"scale",
		Vector2.ONE,
		COUNTDOWN_STEP_DURATION_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_countdown_tween.parallel().tween_property(
		_countdown_label,
		"modulate:a",
		COUNTDOWN_END_ALPHA,
		COUNTDOWN_STEP_DURATION_SEC
	)

	_countdown_tween.tween_callback(_on_resume_countdown_finished)


func show_results_overlay(
	p_title: String,
	p_score: int,
	p_accuracy_percent: float,
	p_max_combo: int,
	p_breakdown: Dictionary,
	p_is_new_record: bool = false,
	p_is_failed: bool = false
) -> void:
	_ensure_ui_nodes()
	_cancel_resume_countdown()
	if input_adapter != null:
		input_adapter.reset_input_state()
	if dsp_clock != null:
		dsp_clock.pause()

	_pause_overlay.visible = false
	_pause_button.disabled = true

	var clamped_acc: float = clampf(p_accuracy_percent, 0.0, 100.0)
	var rank: String = "F" if p_is_failed else compute_letter_rank(clamped_acc)
	_last_displayed_rank = rank

	var safe_title: String = p_title if not p_title.is_empty() else "RESULTADOS"
	_results_title_label.text = safe_title
	if p_is_failed:
		_results_record_label.text = "PISTA FALLIDA"
		_results_record_label.modulate = Color(1.0, 0.34, 0.46, 1.0)
	else:
		_results_record_label.text = "¡NUEVO RÉCORD!" if p_is_new_record else "RESULTADOS DE PARTIDA"
		_results_record_label.modulate = Color(1.0, 0.90, 0.30, 1.0) if p_is_new_record else Color(0.76, 0.88, 1.0, 0.90)

	_results_rank_label.text = rank
	UiFontRegistry.apply_neon_rank_style(_results_rank_label, rank, RESULTS_RANK_FONT_SIZE)

	_results_stats_label.text = (
		"SCORE: %07d\nACCURACY: %.2f%%\nCOMBO MÁX: x%d"
		% [p_score, clamped_acc, p_max_combo]
	)

	var perfect_n: int = int(p_breakdown.get("perfect", 0))
	var great_n: int = int(p_breakdown.get("great", 0))
	var good_n: int = int(p_breakdown.get("good", 0))
	var miss_n: int = int(p_breakdown.get("miss", 0))
	_results_perfect_label.text = "PERFECT: %d" % perfect_n
	_results_great_label.text = "GREAT: %d" % great_n
	_results_good_label.text = "GOOD: %d" % good_n
	_results_miss_label.text = "MISS: %d" % miss_n

	_results_overlay.visible = true


func hide_results_overlay() -> void:
	if _results_overlay != null:
		_results_overlay.visible = false
	if _pause_button != null:
		_pause_button.disabled = false


func request_restart() -> void:
	_ensure_ui_nodes()
	_cancel_resume_countdown()
	_pause_overlay.visible = false
	_results_overlay.visible = false
	if input_adapter != null:
		input_adapter.reset_input_state()
	restart_requested.emit()


func request_main_menu() -> void:
	_ensure_ui_nodes()
	_cancel_resume_countdown()
	_pause_overlay.visible = false
	_results_overlay.visible = false
	if input_adapter != null:
		input_adapter.reset_input_state()
	main_menu_requested.emit()


func is_pause_menu_open() -> bool:
	return _pause_overlay != null and _pause_overlay.visible


func is_results_overlay_open() -> bool:
	return _results_overlay != null and _results_overlay.visible


func is_resume_countdown_active() -> bool:
	return _is_counting_down


func get_safe_container_rect() -> Rect2:
	if _safe_container == null:
		return Rect2()
	return Rect2(_safe_container.position, _safe_container.size)


func get_displayed_score() -> int:
	return _displayed_score


func get_displayed_combo() -> int:
	return _displayed_combo


func get_displayed_accuracy() -> float:
	return _displayed_accuracy


func get_last_judgment_text() -> String:
	return _last_judgment_text


func get_displayed_rank() -> String:
	return _last_displayed_rank


func get_combo_current_scale() -> float:
	if _combo_label == null:
		return COMBO_MIN_SCALE
	return _combo_label.scale.x


func get_combo_width_ratio() -> float:
	if _combo_label == null or _safe_container == null or _safe_container.size.x <= 0.0:
		return COMBO_MAX_WIDTH_RATIO
	return _combo_label.size.x / _safe_container.size.x


func get_banner_alpha() -> float:
	return _banner_alpha


func set_danger_ratio(p_ratio: float) -> void:
	_target_danger_ratio = clampf(p_ratio, 0.0, 1.0)


func get_displayed_danger_ratio() -> float:
	return _displayed_danger_ratio


func set_song_duration_sec(p_duration_sec: float) -> void:
	_song_total_duration_sec = maxf(0.0, p_duration_sec)
	if dsp_clock != null:
		_song_progress = compute_song_progress(dsp_clock.get_current_dsp_time(), _get_effective_song_duration_sec())
	else:
		_song_progress = 0.0
	if _song_progress_bar != null:
		_song_progress_bar.queue_redraw()


func get_song_progress() -> float:
	return _song_progress


func get_song_progress_angle_rad() -> float:
	return _progress_square_angle_rad


func get_song_progress_bar_rect() -> Rect2:
	if _song_progress_bar == null:
		return Rect2()
	return _song_progress_bar.get_global_rect()


func get_song_progress_bar_control() -> Control:
	return _song_progress_bar


func get_top_bar_rects() -> Dictionary:
	return {
		"score": _score_label.get_global_rect() if _score_label != null else Rect2(),
		"accuracy": _accuracy_label.get_global_rect() if _accuracy_label != null else Rect2(),
		"danger_bar": _danger_bar_track.get_global_rect() if _danger_bar_track != null else Rect2(),
		"pause": _pause_button.get_global_rect() if _pause_button != null else Rect2(),
	}


func get_font_registry() -> UiFontRegistry:
	return _font_registry


func get_role_control_fonts() -> Dictionary:
	return {
		"score": _score_label.get_theme_font("font") if _score_label != null else null,
		"accuracy": _accuracy_label.get_theme_font("font") if _accuracy_label != null else null,
		"pause": _pause_button.get_theme_font("font") if _pause_button != null else null,
		"combo": _combo_label.get_theme_font("font") if _combo_label != null else null,
		"judgment": _judgment_label.get_theme_font("font") if _judgment_label != null else null,
		"rank": _results_rank_label.get_theme_font("font") if _results_rank_label != null else null,
	}


func get_results_layout_info() -> Dictionary:
	return {
		"grid_columns": _results_breakdown_grid.columns if _results_breakdown_grid != null else 0,
		"title_font_size": _results_title_label.get_theme_font_size("font_size") if _results_title_label != null else 0,
		"record_font_size": _results_record_label.get_theme_font_size("font_size") if _results_record_label != null else 0,
		"rank_font_size": _results_rank_label.get_theme_font_size("font_size") if _results_rank_label != null else 0,
		"stats_font_size": _results_stats_label.get_theme_font_size("font_size") if _results_stats_label != null else 0,
		"breakdown_font_size": _results_perfect_label.get_theme_font_size("font_size") if _results_perfect_label != null else 0,
		"button_font_size": _results_retry_button.get_theme_font_size("font_size") if _results_retry_button != null else 0,
		"retry_min_height": _results_retry_button.custom_minimum_size.y if _results_retry_button != null else 0.0,
		"menu_min_height": _results_menu_button.custom_minimum_size.y if _results_menu_button != null else 0.0,
		"panel_size": _results_panel.size if _results_panel != null else Vector2.ZERO,
	}


func _prepare_countdown_step(p_number: int) -> void:
	if _countdown_label == null:
		return
	_countdown_label.text = str(p_number)
	_countdown_label.pivot_offset = _countdown_label.size * 0.5
	_countdown_label.scale = Vector2(COUNTDOWN_START_SCALE, COUNTDOWN_START_SCALE)
	_countdown_label.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_resume_countdown_finished() -> void:
	_countdown_tween = null
	_is_counting_down = false
	if _countdown_label != null:
		_countdown_label.visible = false
		_countdown_label.scale = Vector2.ONE
		_countdown_label.modulate = Color.WHITE
	if _pause_button != null:
		_pause_button.disabled = false
	if dsp_clock != null:
		dsp_clock.resume()
	resume_requested.emit()


func _cancel_resume_countdown() -> void:
	if _countdown_tween != null:
		_countdown_tween.kill()
		_countdown_tween = null
	_is_counting_down = false
	if _countdown_label != null:
		_countdown_label.visible = false
		_countdown_label.scale = Vector2.ONE
		_countdown_label.modulate = Color.WHITE
	if _pause_button != null and not is_results_overlay_open():
		_pause_button.disabled = false


func _on_safe_play_rect_changed(_p_play_rect: Rect2, p_hud_safe_rect: Rect2) -> void:
	apply_hud_safe_rect(p_hud_safe_rect)


func _on_score_changed(p_score: int, p_combo: int, _p_max_combo: int, p_accuracy: float) -> void:
	_displayed_score = p_score
	_displayed_combo = p_combo
	_displayed_accuracy = p_accuracy
	_combo_base_scale = _compute_combo_base_scale(_displayed_combo)
	_refresh_labels()
	_apply_banner_visual_transform()


func _on_note_judged(_p_lane: int, p_grade: int, _p_error_ms: float, p_combo: int) -> void:
	_displayed_combo = p_combo
	match p_grade:
		HitJudge.JudgmentGrade.PERFECT:
			_last_judgment_text = "PERFECT"
			_judgment_color = COLOR_JUDGMENT_PERFECT
		HitJudge.JudgmentGrade.GREAT:
			_last_judgment_text = "GREAT"
			_judgment_color = COLOR_JUDGMENT_GREAT
		HitJudge.JudgmentGrade.GOOD:
			_last_judgment_text = "GOOD"
			_judgment_color = COLOR_JUDGMENT_GOOD
		_:
			_last_judgment_text = "MISS"
			_judgment_color = COLOR_JUDGMENT_MISS

	_combo_base_scale = _compute_combo_base_scale(_displayed_combo)
	_combo_pop_boost = COMBO_POP_IMPULSE if _displayed_combo > 0 else 0.0
	_judgment_pop_boost = 0.16
	_banner_idle_sec = 0.0
	_banner_alpha = 1.0
	_refresh_labels()
	_apply_banner_visual_transform()


func _on_hold_combo_ticked(_p_lane: int, p_new_combo: int) -> void:
	_displayed_combo = p_new_combo
	_combo_base_scale = _compute_combo_base_scale(_displayed_combo)
	_combo_pop_boost = COMBO_POP_IMPULSE * 0.85
	_banner_idle_sec = 0.0
	_banner_alpha = 1.0
	_refresh_labels()
	_apply_banner_visual_transform()


func _on_hold_state_changed(p_lane: int, p_is_holding: bool) -> void:
	if p_lane >= 0 and p_lane < _lane_hold_flags.size():
		_lane_hold_flags[p_lane] = p_is_holding
	if p_is_holding:
		_banner_idle_sec = 0.0
		_banner_alpha = 1.0
		_apply_banner_visual_transform()


func _on_danger_changed(p_ratio: float) -> void:
	set_danger_ratio(p_ratio)


func _update_danger_bar_visual(p_delta: float) -> void:
	_displayed_danger_ratio = lerpf(
		_displayed_danger_ratio,
		_target_danger_ratio,
		clampf(DANGER_BAR_LERP_SPEED * p_delta, 0.0, 1.0)
	)
	if absf(_displayed_danger_ratio - _target_danger_ratio) < 0.001:
		_displayed_danger_ratio = _target_danger_ratio

	if _displayed_danger_ratio >= DANGER_THRESHOLD_CRITICAL:
		_danger_pulse_phase += p_delta * DANGER_PULSE_SPEED_RAD
	else:
		_danger_pulse_phase = 0.0

	_sync_danger_bar_fill_rect()


func _sync_danger_bar_fill_rect() -> void:
	if _danger_bar_track == null or _danger_bar_fill == null or _style_danger_fill == null or _style_danger_track == null:
		return

	var ratio: float = clampf(_displayed_danger_ratio, 0.0, 1.0)
	var track_size: Vector2 = _danger_bar_track.size
	if track_size.x <= 1.0 or track_size.y <= 1.0:
		track_size = _danger_bar_track.custom_minimum_size
	_danger_bar_track.pivot_offset = track_size * 0.5
	var inner_pad: float = 4.0
	var inner_w: float = maxf(0.0, track_size.x - (inner_pad * 2.0))
	var inner_h: float = maxf(4.0, track_size.y - (inner_pad * 2.0))
	var fill_w: float = inner_w * ratio

	_danger_bar_fill.position = Vector2(inner_pad, inner_pad)
	_danger_bar_fill.size = Vector2(fill_w, inner_h)
	_danger_bar_fill.visible = fill_w > 1.0

	var active_color: Color = COLOR_DANGER_CYAN
	var pulse_boost: float = 0.0
	if ratio >= DANGER_THRESHOLD_CRITICAL:
		var pulse_wave: float = sin(_danger_pulse_phase) * 0.5 + 0.5
		pulse_boost = pulse_wave
		active_color = COLOR_DANGER_CRITICAL.lerp(Color(1.0, 0.45, 0.78, 1.0), pulse_wave * 0.55)
		var pulse_scale: float = 1.0 + (pulse_wave * 0.06)
		_danger_bar_track.scale = Vector2(pulse_scale, pulse_scale)
	elif ratio >= DANGER_THRESHOLD_AMBER:
		active_color = COLOR_DANGER_AMBER
		_danger_bar_track.scale = Vector2.ONE
	else:
		active_color = COLOR_DANGER_CYAN
		_danger_bar_track.scale = Vector2.ONE

	_style_danger_fill.bg_color = active_color
	_style_danger_fill.shadow_color = Color(active_color.r, active_color.g, active_color.b, 0.55 + (pulse_boost * 0.35))
	_style_danger_fill.shadow_size = 10 + int(round(pulse_boost * 8.0))
	_style_danger_track.border_color = Color(active_color.r, active_color.g, active_color.b, 0.58 + (pulse_boost * 0.36))
	_style_danger_track.shadow_color = Color(active_color.r, active_color.g, active_color.b, 0.25 + (pulse_boost * 0.32))
	_style_danger_track.shadow_size = 10 + int(round(pulse_boost * 6.0))


func _on_bass_kick_pulsed(p_strength: float) -> void:
	if _displayed_combo <= 0:
		return
	var kick_boost: float = clampf(p_strength, 0.0, 1.0) * COMBO_BASS_BOUNCE_MAX
	_combo_bass_boost = maxf(_combo_bass_boost, kick_boost)
	_apply_banner_visual_transform()


func _get_effective_song_duration_sec() -> float:
	if dsp_clock != null:
		var clock_duration: float = dsp_clock.get_total_duration_sec()
		if clock_duration > 0.0:
			return clock_duration
	return _song_total_duration_sec


func _is_song_progress_actively_playing() -> bool:
	return (
		dsp_clock != null
		and dsp_clock.is_playing()
		and not is_pause_menu_open()
		and not is_resume_countdown_active()
		and not is_results_overlay_open()
		and not _song_progress_completed
	)


func _on_dsp_time_updated(p_current_time_sec: float) -> void:
	if not _is_song_progress_actively_playing():
		return
	var next_progress: float = compute_song_progress(p_current_time_sec, _get_effective_song_duration_sec())
	if absf(next_progress - _song_progress) > 0.0001:
		_song_progress = next_progress
		if _song_progress_bar != null:
			_song_progress_bar.queue_redraw()


func _on_dsp_playback_finished() -> void:
	_song_progress_completed = true
	_song_progress = 1.0
	if _song_progress_bar != null:
		_song_progress_bar.queue_redraw()


func _update_song_progress_visual(p_delta: float) -> void:
	if not _is_song_progress_actively_playing():
		return
	var current_sec: float = dsp_clock.get_current_dsp_time()
	_song_progress = compute_song_progress(current_sec, _get_effective_song_duration_sec())
	_progress_square_angle_rad = fmod(
		_progress_square_angle_rad + (SONG_PROGRESS_ROTATION_SPEED_RAD * p_delta),
		TAU
	)
	if _song_progress_bar != null:
		_song_progress_bar.queue_redraw()


func _draw_song_progress_bar() -> void:
	if _song_progress_bar == null:
		return
	var bar_size: Vector2 = _song_progress_bar.size
	if bar_size.x <= 4.0 or bar_size.y <= 4.0:
		return

	var rail_left: float = SONG_PROGRESS_RAIL_INSET_PX
	var rail_right: float = maxf(rail_left + 1.0, bar_size.x - SONG_PROGRESS_RAIL_INSET_PX)
	var center_y: float = bar_size.y * 0.5
	var progress: float = clampf(_song_progress, 0.0, 1.0)
	var marker_x: float = lerpf(rail_left, rail_right, progress)

	# Subtle base track rail
	_song_progress_bar.draw_line(
		Vector2(rail_left, center_y),
		Vector2(rail_right, center_y),
		COLOR_PROGRESS_TRACK,
		SONG_PROGRESS_RAIL_THICKNESS_PX,
		true
	)

	# Elapsed neon cyan progress fill
	if marker_x > rail_left + 0.5:
		_song_progress_bar.draw_line(
			Vector2(rail_left, center_y),
			Vector2(marker_x, center_y),
			COLOR_PROGRESS_FILL_GLOW,
			SONG_PROGRESS_RAIL_THICKNESS_PX * 2.6,
			true
		)
		_song_progress_bar.draw_line(
			Vector2(rail_left, center_y),
			Vector2(marker_x, center_y),
			COLOR_PROGRESS_FILL_CORE,
			SONG_PROGRESS_RAIL_THICKNESS_PX,
			true
		)

	# Rotating neon square position indicator
	var marker_center: Vector2 = Vector2(marker_x, center_y)
	var glow_pts: PackedVector2Array = _build_rotated_square_points(
		marker_center,
		SONG_PROGRESS_GLOW_HALF_SIZE_PX,
		_progress_square_angle_rad
	)
	_song_progress_bar.draw_colored_polygon(glow_pts, COLOR_PROGRESS_SQUARE_GLOW)

	var core_pts: PackedVector2Array = _build_rotated_square_points(
		marker_center,
		SONG_PROGRESS_SQUARE_HALF_SIZE_PX,
		_progress_square_angle_rad
	)
	_song_progress_bar.draw_colored_polygon(core_pts, COLOR_PROGRESS_SQUARE_CORE)

	var border_pts: PackedVector2Array = PackedVector2Array([
		core_pts[0],
		core_pts[1],
		core_pts[2],
		core_pts[3],
		core_pts[0],
	])
	_song_progress_bar.draw_polyline(border_pts, COLOR_PROGRESS_SQUARE_BORDER, 1.8, true)


static func _build_rotated_square_points(
	p_center: Vector2,
	p_half_size: float,
	p_angle_rad: float
) -> PackedVector2Array:
	var c: float = cos(p_angle_rad)
	var s: float = sin(p_angle_rad)
	var h: float = p_half_size
	var corners: Array[Vector2] = [
		Vector2(-h, -h),
		Vector2(h, -h),
		Vector2(h, h),
		Vector2(-h, h),
	]
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(4)
	for i: int in range(4):
		var v: Vector2 = corners[i]
		out[i] = p_center + Vector2((v.x * c) - (v.y * s), (v.x * s) + (v.y * c))
	return out


func _compute_combo_base_scale(p_combo: int) -> float:
	if p_combo <= 0:
		return COMBO_MIN_SCALE
	var steps: int = maxi(0, p_combo - 1)
	return clampf(
		COMBO_MIN_SCALE + (float(steps) * COMBO_GROWTH_PER_HIT),
		COMBO_MIN_SCALE,
		COMBO_MAX_SCALE
	)


func _is_any_lane_holding() -> bool:
	for i: int in range(_lane_hold_flags.size()):
		if _lane_hold_flags[i]:
			return true
	return false


func _apply_banner_visual_transform() -> void:
	if _combo_label != null:
		var effective_combo_scale: float = clampf(
			_combo_base_scale + _combo_pop_boost + _combo_bass_boost,
			COMBO_MIN_SCALE,
			COMBO_MAX_SCALE
		)
		_combo_label.pivot_offset = _combo_label.size * 0.5
		_combo_label.scale = Vector2(effective_combo_scale, effective_combo_scale)
		_combo_label.modulate = Color(1.0, 0.96, 0.82, _banner_alpha)

	if _judgment_label != null:
		var effective_judgment_scale: float = clampf(1.0 + _judgment_pop_boost, 1.0, 1.24)
		_judgment_label.pivot_offset = _judgment_label.size * 0.5
		_judgment_label.scale = Vector2(effective_judgment_scale, effective_judgment_scale)
		_judgment_label.modulate = Color(
			_judgment_color.r,
			_judgment_color.g,
			_judgment_color.b,
			_banner_alpha
		)


func _ensure_ui_nodes() -> void:
	if _safe_container != null:
		return

	if ui_sfx_player == null:
		var global_sfx: Node = get_node_or_null("/root/GlobalUiSfx")
		if global_sfx is UiSfxPlayer:
			ui_sfx_player = global_sfx as UiSfxPlayer
		else:
			ui_sfx_player = UiSfxPlayer.new()
			ui_sfx_player.name = "HudUiSfxPlayer"
			add_child(ui_sfx_player)

	_safe_container = Control.new()
	_safe_container.name = "SafeAreaContainer"
	_safe_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_container)

	_top_bar_margin = MarginContainer.new()
	_top_bar_margin.name = "TopBarMargin"
	_top_bar_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_bar_margin.add_theme_constant_override("margin_left", 16)
	_top_bar_margin.add_theme_constant_override("margin_right", 16)
	_top_bar_margin.add_theme_constant_override("margin_top", 12)
	_top_bar_margin.add_theme_constant_override("margin_bottom", 0)
	_safe_container.add_child(_top_bar_margin)

	_top_bar_hbox = HBoxContainer.new()
	_top_bar_hbox.name = "TopBarHBox"
	_top_bar_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_bar_hbox.add_theme_constant_override("separation", 20)
	_top_bar_margin.add_child(_top_bar_hbox)

	_left_stats_vbox = VBoxContainer.new()
	_left_stats_vbox.name = "LeftStatsVBox"
	_left_stats_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_stats_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_left_stats_vbox.add_theme_constant_override("separation", 4)
	_top_bar_hbox.add_child(_left_stats_vbox)

	_score_label = Label.new()
	_score_label.name = "ScoreLabel"
	_score_label.clip_text = false
	_score_label.clip_contents = false
	_score_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_label.add_theme_font_size_override("font_size", SCORE_FONT_SIZE)
	_left_stats_vbox.add_child(_score_label)

	_accuracy_label = Label.new()
	_accuracy_label.name = "AccuracyLabel"
	_accuracy_label.clip_text = false
	_accuracy_label.clip_contents = false
	_accuracy_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_accuracy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_accuracy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accuracy_label.add_theme_font_size_override("font_size", ACCURACY_FONT_SIZE)
	_left_stats_vbox.add_child(_accuracy_label)

	_right_controls_vbox = VBoxContainer.new()
	_right_controls_vbox.name = "RightControlsVBox"
	_right_controls_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_controls_vbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	_right_controls_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_right_controls_vbox.add_theme_constant_override("separation", 12)
	_top_bar_hbox.add_child(_right_controls_vbox)

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "PAUSA"
	_pause_button.custom_minimum_size = Vector2(PAUSE_BUTTON_WIDTH_PX, PAUSE_BUTTON_HEIGHT_PX)
	_pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_button.add_theme_font_size_override("font_size", PAUSE_BUTTON_FONT_SIZE)
	_pause_button.pressed.connect(open_pause_menu)
	_right_controls_vbox.add_child(_pause_button)

	_style_danger_track = StyleBoxFlat.new()
	_style_danger_track.bg_color = Color(0.03, 0.06, 0.14, 0.78)
	_style_danger_track.border_color = Color(COLOR_DANGER_CYAN.r, COLOR_DANGER_CYAN.g, COLOR_DANGER_CYAN.b, 0.58)
	_style_danger_track.set_border_width_all(2)
	_style_danger_track.set_corner_radius_all(14)
	_style_danger_track.shadow_color = Color(COLOR_DANGER_CYAN.r, COLOR_DANGER_CYAN.g, COLOR_DANGER_CYAN.b, 0.25)
	_style_danger_track.shadow_size = 10

	_style_danger_fill = StyleBoxFlat.new()
	_style_danger_fill.bg_color = COLOR_DANGER_CYAN
	_style_danger_fill.set_border_width_all(0)
	_style_danger_fill.set_corner_radius_all(10)
	_style_danger_fill.shadow_color = Color(COLOR_DANGER_CYAN.r, COLOR_DANGER_CYAN.g, COLOR_DANGER_CYAN.b, 0.55)
	_style_danger_fill.shadow_size = 10

	_danger_bar_track = Panel.new()
	_danger_bar_track.name = "DangerBarTrack"
	_danger_bar_track.custom_minimum_size = Vector2(PAUSE_BUTTON_WIDTH_PX, DANGER_BAR_HEIGHT_PX)
	_danger_bar_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_danger_bar_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_danger_bar_track.add_theme_stylebox_override("panel", _style_danger_track)
	_right_controls_vbox.add_child(_danger_bar_track)

	_danger_bar_fill = Panel.new()
	_danger_bar_fill.name = "DangerBarFill"
	_danger_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_danger_bar_fill.visible = false
	_danger_bar_fill.add_theme_stylebox_override("panel", _style_danger_fill)
	_danger_bar_track.add_child(_danger_bar_fill)

	_combo_label = Label.new()
	_combo_label.name = "ComboLabel"
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_label.clip_text = true
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_label.add_theme_font_size_override("font_size", COMBO_FONT_SIZE)
	_safe_container.add_child(_combo_label)

	_judgment_label = Label.new()
	_judgment_label.name = "JudgmentLabel"
	_judgment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judgment_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_judgment_label.clip_text = true
	_judgment_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_judgment_label.add_theme_font_size_override("font_size", JUDGMENT_FONT_SIZE)
	_safe_container.add_child(_judgment_label)

	_countdown_label = Label.new()
	_countdown_label.name = "CountdownLabel"
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_label.add_theme_font_size_override("font_size", COUNTDOWN_FONT_SIZE)
	_countdown_label.visible = false
	_safe_container.add_child(_countdown_label)

	_song_progress_bar = Control.new()
	_song_progress_bar.name = "SongProgressBar"
	_song_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_song_progress_bar.draw.connect(_draw_song_progress_bar)
	_safe_container.add_child(_song_progress_bar)

	_pause_overlay = ColorRect.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.color = Color(0.02, 0.02, 0.06, 0.82)
	_pause_overlay.visible = false
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_safe_container.add_child(_pause_overlay)

	_pause_panel = Panel.new()
	_pause_panel.name = "PausePanel"
	_pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.add_child(_pause_panel)

	_pause_vbox = VBoxContainer.new()
	_pause_vbox.name = "PauseVBox"
	_pause_vbox.add_theme_constant_override("separation", 18)
	_pause_panel.add_child(_pause_vbox)

	_pause_title_label = Label.new()
	_pause_title_label.name = "PauseTitleLabel"
	_pause_title_label.text = "PAUSA"
	_pause_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pause_title_label.add_theme_font_size_override("font_size", RESULTS_TITLE_FONT_SIZE)
	_pause_vbox.add_child(_pause_title_label)

	_resume_button = Button.new()
	_resume_button.name = "ResumeButton"
	_resume_button.text = "REANUDAR"
	_resume_button.custom_minimum_size = Vector2(0.0, 84.0)
	_resume_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_resume_button.add_theme_font_size_override("font_size", MODAL_BUTTON_FONT_SIZE)
	_resume_button.pressed.connect(close_pause_menu_and_resume)
	_pause_vbox.add_child(_resume_button)

	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "REINICIAR"
	_restart_button.custom_minimum_size = Vector2(0.0, 84.0)
	_restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_restart_button.add_theme_font_size_override("font_size", MODAL_BUTTON_FONT_SIZE)
	_restart_button.pressed.connect(request_restart)
	_pause_vbox.add_child(_restart_button)

	_pause_menu_button = Button.new()
	_pause_menu_button.name = "PauseMenuButton"
	_pause_menu_button.text = "MENÚ PRINCIPAL"
	_pause_menu_button.custom_minimum_size = Vector2(0.0, 84.0)
	_pause_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_menu_button.add_theme_font_size_override("font_size", MODAL_BUTTON_FONT_SIZE)
	_pause_vbox.add_child(_pause_menu_button)
	ui_sfx_player.bind_button(_pause_menu_button)
	_pause_menu_button.pressed.connect(request_main_menu)

	_build_results_styles()

	_results_overlay = ColorRect.new()
	_results_overlay.name = "ResultsOverlay"
	_results_overlay.color = Color(0.01, 0.02, 0.06, 0.84)
	_results_overlay.visible = false
	_results_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_safe_container.add_child(_results_overlay)

	_results_panel = Panel.new()
	_results_panel.name = "ResultsPanel"
	_results_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_results_panel.add_theme_stylebox_override("panel", _style_results_panel)
	_results_overlay.add_child(_results_panel)

	_results_vbox = VBoxContainer.new()
	_results_vbox.name = "ResultsVBox"
	_results_vbox.add_theme_constant_override("separation", 18)
	_results_panel.add_child(_results_vbox)

	_results_title_label = Label.new()
	_results_title_label.name = "ResultsTitleLabel"
	_results_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_results_title_label.clip_text = true
	_results_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_results_title_label.add_theme_font_size_override("font_size", RESULTS_TITLE_FONT_SIZE)
	_results_title_label.add_theme_color_override("font_color", Color(0.98, 1.0, 1.0, 1.0))
	_results_vbox.add_child(_results_title_label)

	_results_record_label = Label.new()
	_results_record_label.name = "ResultsRecordLabel"
	_results_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_record_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_results_record_label.add_theme_font_size_override("font_size", RESULTS_RECORD_FONT_SIZE)
	_results_vbox.add_child(_results_record_label)

	_results_rank_label = Label.new()
	_results_rank_label.name = "ResultsRankLabel"
	_results_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_results_rank_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results_rank_label.custom_minimum_size = Vector2(0.0, 270.0)
	_results_rank_label.add_theme_font_size_override("font_size", RESULTS_RANK_FONT_SIZE)
	_results_vbox.add_child(_results_rank_label)

	_results_stats_label = Label.new()
	_results_stats_label.name = "ResultsStatsLabel"
	_results_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_results_stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results_stats_label.add_theme_constant_override("line_spacing", 14)
	_results_stats_label.add_theme_font_size_override("font_size", RESULTS_STATS_FONT_SIZE)
	_results_stats_label.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 1.0))
	_results_vbox.add_child(_results_stats_label)

	_results_breakdown_grid = GridContainer.new()
	_results_breakdown_grid.name = "ResultsBreakdownGrid"
	_results_breakdown_grid.columns = 2
	_results_breakdown_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_results_breakdown_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results_breakdown_grid.add_theme_constant_override("h_separation", 20)
	_results_breakdown_grid.add_theme_constant_override("v_separation", 18)
	_results_vbox.add_child(_results_breakdown_grid)

	_results_perfect_label = _create_results_breakdown_cell("ResultsPerfectLabel", COLOR_JUDGMENT_PERFECT)
	_results_breakdown_grid.add_child(_results_perfect_label)

	_results_great_label = _create_results_breakdown_cell("ResultsGreatLabel", COLOR_JUDGMENT_GREAT)
	_results_breakdown_grid.add_child(_results_great_label)

	_results_good_label = _create_results_breakdown_cell("ResultsGoodLabel", COLOR_RESULTS_GOOD_AMBER)
	_results_breakdown_grid.add_child(_results_good_label)

	_results_miss_label = _create_results_breakdown_cell("ResultsMissLabel", COLOR_JUDGMENT_MISS)
	_results_breakdown_grid.add_child(_results_miss_label)

	_results_retry_button = Button.new()
	_results_retry_button.name = "ResultsRetryButton"
	_results_retry_button.text = "REINTENTAR"
	_results_retry_button.custom_minimum_size = Vector2(0.0, RESULTS_BUTTON_MIN_HEIGHT_PX)
	_results_retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_results_retry_button.add_theme_font_size_override("font_size", RESULTS_BUTTON_FONT_SIZE)
	_results_retry_button.add_theme_color_override("font_color", Color(0.98, 1.0, 1.0, 1.0))
	_apply_results_button_style(_results_retry_button, _style_results_retry)
	_results_vbox.add_child(_results_retry_button)
	ui_sfx_player.bind_button(_results_retry_button)
	_results_retry_button.pressed.connect(request_restart)

	_results_menu_button = Button.new()
	_results_menu_button.name = "ResultsMenuButton"
	_results_menu_button.text = "MENÚ PRINCIPAL"
	_results_menu_button.custom_minimum_size = Vector2(0.0, RESULTS_BUTTON_MIN_HEIGHT_PX)
	_results_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_results_menu_button.add_theme_font_size_override("font_size", RESULTS_BUTTON_FONT_SIZE)
	_results_menu_button.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 1.0))
	_apply_results_button_style(_results_menu_button, _style_results_menu)
	_results_vbox.add_child(_results_menu_button)
	ui_sfx_player.bind_button(_results_menu_button)
	_results_menu_button.pressed.connect(request_main_menu)

	ui_sfx_player.enable_global_button_wiring()
	ui_sfx_player.bind_buttons_in_tree(self)
	_refresh_labels()
	_apply_banner_visual_transform()


func _build_results_styles() -> void:
	_style_results_panel = StyleBoxFlat.new()
	_style_results_panel.bg_color = Color(0.03, 0.08, 0.16, 0.84)
	_style_results_panel.border_color = Color(0.18, 0.90, 1.0, 0.85)
	_style_results_panel.set_border_width_all(3)
	_style_results_panel.set_corner_radius_all(22)
	_style_results_panel.shadow_color = Color(0.12, 0.85, 1.0, 0.30)
	_style_results_panel.shadow_size = 18

	_style_results_retry = StyleBoxFlat.new()
	_style_results_retry.bg_color = Color(0.08, 0.56, 0.58, 0.94)
	_style_results_retry.border_color = Color(0.45, 1.0, 0.96, 1.0)
	_style_results_retry.set_border_width_all(3)
	_style_results_retry.set_corner_radius_all(16)
	_style_results_retry.shadow_color = Color(0.20, 0.95, 0.90, 0.35)
	_style_results_retry.shadow_size = 10

	_style_results_menu = StyleBoxFlat.new()
	_style_results_menu.bg_color = Color(0.05, 0.14, 0.26, 0.88)
	_style_results_menu.border_color = Color(0.22, 0.86, 1.0, 0.85)
	_style_results_menu.set_border_width_all(3)
	_style_results_menu.set_corner_radius_all(16)
	_style_results_menu.shadow_color = Color(0.15, 0.80, 1.0, 0.24)
	_style_results_menu.shadow_size = 8


func _apply_results_button_style(p_button: Button, p_style: StyleBoxFlat) -> void:
	if p_button == null or p_style == null:
		return
	p_button.add_theme_stylebox_override("normal", p_style)
	p_button.add_theme_stylebox_override("hover", p_style)
	p_button.add_theme_stylebox_override("pressed", p_style)
	p_button.add_theme_stylebox_override("focus", p_style)


func _create_results_breakdown_cell(p_name: String, p_color: Color) -> Label:
	var cell: Label = Label.new()
	cell.name = p_name
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.add_theme_font_size_override("font_size", RESULTS_BREAKDOWN_FONT_SIZE)
	cell.add_theme_color_override("font_color", p_color)
	return cell


func _apply_external_fonts() -> void:
	if _font_registry == null:
		_font_registry = UiFontRegistry.new()
	_font_registry.apply_global_theme(get_tree())

	var global_font: Font = _font_registry.get_global_font()
	if global_font != null:
		_font_registry.apply_global_font_override(_score_label, 5)
		_font_registry.apply_global_font_override(_accuracy_label, 4)
		_font_registry.apply_global_font_override(_pause_button, 4)
		_font_registry.apply_global_font_override(_pause_title_label, 4)
		_font_registry.apply_global_font_override(_resume_button)
		_font_registry.apply_global_font_override(_restart_button)
		_font_registry.apply_global_font_override(_pause_menu_button)
		_font_registry.apply_global_font_override(_results_title_label, 5)
		_font_registry.apply_global_font_override(_results_record_label, 4)
		_font_registry.apply_global_font_override(_results_stats_label, 5)
		_font_registry.apply_global_font_override(_results_perfect_label, 4)
		_font_registry.apply_global_font_override(_results_great_label, 4)
		_font_registry.apply_global_font_override(_results_good_label, 4)
		_font_registry.apply_global_font_override(_results_miss_label, 4)
		_font_registry.apply_global_font_override(_results_retry_button, 4)
		_font_registry.apply_global_font_override(_results_menu_button, 4)

	_font_registry.apply_combo_role(_combo_label, 8)
	_font_registry.apply_combo_role(_judgment_label, 7)
	UiFontRegistry.apply_neon_rank_style(_results_rank_label, _last_displayed_rank if not _last_displayed_rank.is_empty() else "SSS+", RESULTS_RANK_FONT_SIZE)
	_font_registry.apply_global_font_override(_countdown_label, 8)


func _refresh_labels() -> void:
	if _score_label != null:
		_score_label.text = "SCORE: %07d" % _displayed_score
	if _accuracy_label != null:
		_accuracy_label.text = "ACC: %.1f%%" % (_displayed_accuracy * 100.0)
	if _combo_label != null:
		_combo_label.text = "COMBO x%d" % _displayed_combo if _displayed_combo > 0 else ""
	if _judgment_label != null:
		_judgment_label.text = _last_judgment_text
