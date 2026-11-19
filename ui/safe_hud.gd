class_name SafeHud
extends Control

signal pause_requested()
signal resume_requested()
signal restart_requested()

const TOP_BAR_HEIGHT_PX: float = 96.0
const PAUSE_BUTTON_WIDTH_PX: float = 156.0
const PAUSE_BUTTON_HEIGHT_PX: float = 66.0
const CENTER_BANNER_HEIGHT_PX: float = 148.0
const MODAL_WIDTH_PX: float = 460.0
const MODAL_HEIGHT_PX: float = 310.0
const COUNTDOWN_BOX_WIDTH_PX: float = 260.0
const COUNTDOWN_BOX_HEIGHT_PX: float = 160.0

const SCORE_FONT_SIZE: int = 34
const ACCURACY_FONT_SIZE: int = 26
const PAUSE_BUTTON_FONT_SIZE: int = 28
const MODAL_BUTTON_FONT_SIZE: int = 28
const COMBO_FONT_SIZE: int = 50
const JUDGMENT_FONT_SIZE: int = 46
const COUNTDOWN_FONT_SIZE: int = 110

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

@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var hit_judge: HitJudge = null
@export var dsp_clock: DSPClock = null
@export var input_adapter: RhythmInputAdapter = null
@export var reactive_background: ReactiveBackground = null

var _safe_container: Control = null
var _score_label: Label = null
var _accuracy_label: Label = null
var _combo_label: Label = null
var _judgment_label: Label = null
var _countdown_label: Label = null
var _pause_button: Button = null
var _pause_overlay: ColorRect = null
var _pause_panel: Panel = null
var _resume_button: Button = null
var _restart_button: Button = null

var _countdown_tween: Tween = null
var _is_counting_down: bool = false
var _displayed_score: int = 0
var _displayed_combo: int = 0
var _displayed_accuracy: float = 1.0
var _last_judgment_text: String = "READY"
var _judgment_color: Color = COLOR_JUDGMENT_READY

var _lane_hold_flags: Array[bool] = [false, false, false, false]
var _combo_base_scale: float = COMBO_MIN_SCALE
var _combo_pop_boost: float = 0.0
var _combo_bass_boost: float = 0.0
var _judgment_pop_boost: float = 0.0
var _banner_idle_sec: float = 0.0
var _banner_alpha: float = 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_ui_nodes()
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

	if reactive_background != null:
		if not reactive_background.bass_kick_pulsed.is_connected(_on_bass_kick_pulsed):
			reactive_background.bass_kick_pulsed.connect(_on_bass_kick_pulsed)


func apply_hud_safe_rect(p_hud_safe_rect: Rect2) -> void:
	_ensure_ui_nodes()
	_safe_container.position = p_hud_safe_rect.position
	_safe_container.size = p_hud_safe_rect.size

	var safe_w: float = maxf(320.0, p_hud_safe_rect.size.x)
	var safe_h: float = maxf(480.0, p_hud_safe_rect.size.y)

	_score_label.position = Vector2(16.0, 12.0)
	_score_label.size = Vector2(safe_w * 0.55, TOP_BAR_HEIGHT_PX * 0.52)

	_accuracy_label.position = Vector2(16.0, 58.0)
	_accuracy_label.size = Vector2(safe_w * 0.55, TOP_BAR_HEIGHT_PX * 0.45)

	_pause_button.position = Vector2(safe_w - PAUSE_BUTTON_WIDTH_PX - 16.0, 12.0)
	_pause_button.size = Vector2(PAUSE_BUTTON_WIDTH_PX, PAUSE_BUTTON_HEIGHT_PX)

	var banner_w: float = safe_w * COMBO_MAX_WIDTH_RATIO
	var banner_x: float = (safe_w - banner_w) * 0.5
	var center_y: float = safe_h * 0.28

	_combo_label.size = Vector2(banner_w, CENTER_BANNER_HEIGHT_PX * 0.52)
	_combo_label.position = Vector2(banner_x, center_y)
	_combo_label.pivot_offset = _combo_label.size * 0.5

	_judgment_label.size = Vector2(banner_w, CENTER_BANNER_HEIGHT_PX * 0.48)
	_judgment_label.position = Vector2(banner_x, center_y + 68.0)
	_judgment_label.pivot_offset = _judgment_label.size * 0.5

	var countdown_size: Vector2 = Vector2(COUNTDOWN_BOX_WIDTH_PX, COUNTDOWN_BOX_HEIGHT_PX)
	_countdown_label.size = countdown_size
	_countdown_label.position = Vector2(
		(safe_w - countdown_size.x) * 0.5,
		(safe_h - countdown_size.y) * 0.42
	)
	_countdown_label.pivot_offset = countdown_size * 0.5

	_pause_overlay.position = Vector2.ZERO
	_pause_overlay.size = p_hud_safe_rect.size

	var panel_w: float = minf(MODAL_WIDTH_PX, safe_w - 32.0)
	var panel_h: float = MODAL_HEIGHT_PX
	_pause_panel.position = Vector2((safe_w - panel_w) * 0.5, (safe_h - panel_h) * 0.5)
	_pause_panel.size = Vector2(panel_w, panel_h)

	var btn_w: float = panel_w - 64.0
	_resume_button.position = Vector2(32.0, 72.0)
	_resume_button.size = Vector2(btn_w, 68.0)

	_restart_button.position = Vector2(32.0, 164.0)
	_restart_button.size = Vector2(btn_w, 68.0)

	_apply_banner_visual_transform()


func reset_hud_display() -> void:
	_cancel_resume_countdown()
	_displayed_score = 0
	_displayed_combo = 0
	_displayed_accuracy = 1.0
	_last_judgment_text = "READY"
	_judgment_color = COLOR_JUDGMENT_READY
	for i: int in range(_lane_hold_flags.size()):
		_lane_hold_flags[i] = false
	_combo_base_scale = COMBO_MIN_SCALE
	_combo_pop_boost = 0.0
	_combo_bass_boost = 0.0
	_judgment_pop_boost = 0.0
	_banner_idle_sec = 0.0
	_banner_alpha = 1.0
	if _pause_overlay != null:
		_pause_overlay.visible = false
	_refresh_labels()
	_apply_banner_visual_transform()


func open_pause_menu() -> void:
	_ensure_ui_nodes()
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


func request_restart() -> void:
	_ensure_ui_nodes()
	_cancel_resume_countdown()
	_pause_overlay.visible = false
	if input_adapter != null:
		input_adapter.reset_input_state()
	restart_requested.emit()


func is_pause_menu_open() -> bool:
	return _pause_overlay != null and _pause_overlay.visible


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
	if _pause_button != null:
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


func _on_bass_kick_pulsed(p_strength: float) -> void:
	if _displayed_combo <= 0:
		return
	var kick_boost: float = clampf(p_strength, 0.0, 1.0) * COMBO_BASS_BOUNCE_MAX
	_combo_bass_boost = maxf(_combo_bass_boost, kick_boost)
	_apply_banner_visual_transform()


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

	_safe_container = Control.new()
	_safe_container.name = "SafeAreaContainer"
	_safe_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_container)

	_score_label = Label.new()
	_score_label.name = "ScoreLabel"
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_label.add_theme_font_size_override("font_size", SCORE_FONT_SIZE)
	_safe_container.add_child(_score_label)

	_accuracy_label = Label.new()
	_accuracy_label.name = "AccuracyLabel"
	_accuracy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accuracy_label.add_theme_font_size_override("font_size", ACCURACY_FONT_SIZE)
	_safe_container.add_child(_accuracy_label)

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

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "PAUSA"
	_pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_button.add_theme_font_size_override("font_size", PAUSE_BUTTON_FONT_SIZE)
	_pause_button.pressed.connect(open_pause_menu)
	_safe_container.add_child(_pause_button)

	_pause_overlay = ColorRect.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.color = Color(0.02, 0.02, 0.06, 0.78)
	_pause_overlay.visible = false
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_safe_container.add_child(_pause_overlay)

	_pause_panel = Panel.new()
	_pause_panel.name = "PausePanel"
	_pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.add_child(_pause_panel)

	_resume_button = Button.new()
	_resume_button.name = "ResumeButton"
	_resume_button.text = "REANUDAR"
	_resume_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_resume_button.add_theme_font_size_override("font_size", MODAL_BUTTON_FONT_SIZE)
	_resume_button.pressed.connect(close_pause_menu_and_resume)
	_pause_panel.add_child(_resume_button)

	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "REINICIAR"
	_restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_restart_button.add_theme_font_size_override("font_size", MODAL_BUTTON_FONT_SIZE)
	_restart_button.pressed.connect(request_restart)
	_pause_panel.add_child(_restart_button)

	_refresh_labels()
	_apply_banner_visual_transform()


func _refresh_labels() -> void:
	if _score_label != null:
		_score_label.text = "SCORE: %07d" % _displayed_score
	if _accuracy_label != null:
		_accuracy_label.text = "ACC: %.1f%%" % (_displayed_accuracy * 100.0)
	if _combo_label != null:
		_combo_label.text = "COMBO x%d" % _displayed_combo if _displayed_combo > 0 else ""
	if _judgment_label != null:
		_judgment_label.text = _last_judgment_text
