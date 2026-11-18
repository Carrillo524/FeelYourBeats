class_name SafeHud
extends Control

signal pause_requested()
signal resume_requested()
signal restart_requested()

const TOP_BAR_HEIGHT_PX: float = 88.0
const PAUSE_BUTTON_WIDTH_PX: float = 148.0
const PAUSE_BUTTON_HEIGHT_PX: float = 64.0
const CENTER_BANNER_HEIGHT_PX: float = 140.0
const MODAL_WIDTH_PX: float = 440.0
const MODAL_HEIGHT_PX: float = 300.0

@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var hit_judge: HitJudge = null
@export var dsp_clock: DSPClock = null
@export var input_adapter: RhythmInputAdapter = null

var _safe_container: Control = null
var _score_label: Label = null
var _accuracy_label: Label = null
var _combo_label: Label = null
var _judgment_label: Label = null
var _pause_button: Button = null
var _pause_overlay: ColorRect = null
var _pause_panel: Panel = null
var _resume_button: Button = null
var _restart_button: Button = null

var _displayed_score: int = 0
var _displayed_combo: int = 0
var _displayed_accuracy: float = 1.0
var _last_judgment_text: String = "READY"


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


func connect_dependencies() -> void:
	if screen_safe_adapter != null:
		if not screen_safe_adapter.safe_play_rect_changed.is_connected(_on_safe_play_rect_changed):
			screen_safe_adapter.safe_play_rect_changed.connect(_on_safe_play_rect_changed)

	if hit_judge != null:
		if not hit_judge.score_changed.is_connected(_on_score_changed):
			hit_judge.score_changed.connect(_on_score_changed)
		if not hit_judge.note_judged.is_connected(_on_note_judged):
			hit_judge.note_judged.connect(_on_note_judged)


func apply_hud_safe_rect(p_hud_safe_rect: Rect2) -> void:
	_ensure_ui_nodes()
	_safe_container.position = p_hud_safe_rect.position
	_safe_container.size = p_hud_safe_rect.size

	var safe_w: float = maxf(320.0, p_hud_safe_rect.size.x)
	var safe_h: float = maxf(480.0, p_hud_safe_rect.size.y)

	_score_label.position = Vector2(16.0, 12.0)
	_score_label.size = Vector2(safe_w * 0.45, TOP_BAR_HEIGHT_PX)

	_accuracy_label.position = Vector2(16.0, 52.0)
	_accuracy_label.size = Vector2(safe_w * 0.45, TOP_BAR_HEIGHT_PX * 0.5)

	_pause_button.position = Vector2(safe_w - PAUSE_BUTTON_WIDTH_PX - 16.0, 12.0)
	_pause_button.size = Vector2(PAUSE_BUTTON_WIDTH_PX, PAUSE_BUTTON_HEIGHT_PX)

	var center_y: float = safe_h * 0.30
	_combo_label.position = Vector2(0.0, center_y)
	_combo_label.size = Vector2(safe_w, CENTER_BANNER_HEIGHT_PX * 0.5)

	_judgment_label.position = Vector2(0.0, center_y + 52.0)
	_judgment_label.size = Vector2(safe_w, CENTER_BANNER_HEIGHT_PX * 0.5)

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


func reset_hud_display() -> void:
	_displayed_score = 0
	_displayed_combo = 0
	_displayed_accuracy = 1.0
	_last_judgment_text = "READY"
	if _pause_overlay != null:
		_pause_overlay.visible = false
	_refresh_labels()


func open_pause_menu() -> void:
	_ensure_ui_nodes()
	if input_adapter != null:
		input_adapter.reset_input_state()
	if dsp_clock != null:
		dsp_clock.pause()
	_pause_overlay.visible = true
	pause_requested.emit()


func close_pause_menu_and_resume() -> void:
	_ensure_ui_nodes()
	_pause_overlay.visible = false
	if dsp_clock != null:
		dsp_clock.resume()
	resume_requested.emit()


func request_restart() -> void:
	_ensure_ui_nodes()
	_pause_overlay.visible = false
	if input_adapter != null:
		input_adapter.reset_input_state()
	restart_requested.emit()


func is_pause_menu_open() -> bool:
	return _pause_overlay != null and _pause_overlay.visible


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


func _on_safe_play_rect_changed(_p_play_rect: Rect2, p_hud_safe_rect: Rect2) -> void:
	apply_hud_safe_rect(p_hud_safe_rect)


func _on_score_changed(p_score: int, p_combo: int, _p_max_combo: int, p_accuracy: float) -> void:
	_displayed_score = p_score
	_displayed_combo = p_combo
	_displayed_accuracy = p_accuracy
	_refresh_labels()


func _on_note_judged(_p_lane: int, p_grade: int, _p_error_ms: float, p_combo: int) -> void:
	_displayed_combo = p_combo
	match p_grade:
		HitJudge.JudgmentGrade.PERFECT:
			_last_judgment_text = "PERFECT"
		HitJudge.JudgmentGrade.GREAT:
			_last_judgment_text = "GREAT"
		HitJudge.JudgmentGrade.GOOD:
			_last_judgment_text = "GOOD"
		_:
			_last_judgment_text = "MISS"
	_refresh_labels()


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
	_safe_container.add_child(_score_label)

	_accuracy_label = Label.new()
	_accuracy_label.name = "AccuracyLabel"
	_accuracy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_container.add_child(_accuracy_label)

	_combo_label = Label.new()
	_combo_label.name = "ComboLabel"
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_container.add_child(_combo_label)

	_judgment_label = Label.new()
	_judgment_label.name = "JudgmentLabel"
	_judgment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judgment_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_container.add_child(_judgment_label)

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "PAUSA"
	_pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
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
	_resume_button.pressed.connect(close_pause_menu_and_resume)
	_pause_panel.add_child(_resume_button)

	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "REINICIAR"
	_restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_restart_button.pressed.connect(request_restart)
	_pause_panel.add_child(_restart_button)

	_refresh_labels()


func _refresh_labels() -> void:
	if _score_label != null:
		_score_label.text = "SCORE: %07d" % _displayed_score
	if _accuracy_label != null:
		_accuracy_label.text = "ACC: %.1f%%" % (_displayed_accuracy * 100.0)
	if _combo_label != null:
		_combo_label.text = "COMBO x%d" % _displayed_combo if _displayed_combo > 0 else ""
	if _judgment_label != null:
		_judgment_label.text = _last_judgment_text
