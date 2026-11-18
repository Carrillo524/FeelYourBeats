class_name LaneField
extends Control

const DEFAULT_LANE_COUNT: int = 4
const TOP_SPAWN_MARGIN_PX: float = 64.0
const DEFAULT_PLAY_WIDTH: float = 950.4
const DEFAULT_PLAY_HEIGHT: float = 1920.0

@export var dsp_clock: DSPClock = null
@export var screen_safe_adapter: ScreenSafeAdapter = null
@export var input_adapter: RhythmInputAdapter = null
@export var hit_judge: HitJudge = null
@export var hit_line_height_ratio: float = 0.84
@export var scroll_speed_px_per_sec: float = 1100.0
@export var pool_size: int = 64
@export var bottom_padding_px: float = 48.0
@export var despawn_past_hit_line_px: float = 220.0

var _chart: ChartData = null
var _hit_line_y: float = DEFAULT_PLAY_HEIGHT * 0.84
var _lane_width: float = DEFAULT_PLAY_WIDTH / float(DEFAULT_LANE_COUNT)
var _current_dsp_time_sec: float = 0.0
var _next_spawn_index: int = 0
var _free_pool: Array[NoteView] = []
var _active_views: Array[NoteView] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_pool()
	_connect_dependencies()

	if screen_safe_adapter != null:
		apply_safe_layout(
			screen_safe_adapter.get_play_rect(),
			screen_safe_adapter.get_hud_safe_rect()
		)


func load_chart(p_chart: ChartData) -> bool:
	if p_chart == null:
		return false

	var validation: Dictionary = p_chart.validate()
	var is_valid: bool = validation.get("valid", false) as bool
	if not is_valid:
		return false

	if hit_judge != null:
		if not hit_judge.load_chart(p_chart):
			return false

	_ensure_pool()
	_recycle_all_active_views()
	_chart = p_chart
	_next_spawn_index = 0
	return true


func apply_safe_layout(p_play_rect: Rect2, p_hud_safe_rect: Rect2) -> void:
	position = p_play_rect.position
	size = p_play_rect.size

	var lane_count: int = DEFAULT_LANE_COUNT
	if screen_safe_adapter != null:
		lane_count = maxi(1, screen_safe_adapter.lane_count)
	_lane_width = maxf(1.0, p_play_rect.size.x / float(lane_count))

	var max_hit_line_y: float = maxf(0.0, p_hud_safe_rect.end.y - bottom_padding_px)
	var target_hit_line_y: float = p_play_rect.size.y * hit_line_height_ratio
	_hit_line_y = clampf(target_hit_line_y, 0.0, max_hit_line_y)

	var active_count: int = _active_views.size()
	for i: int in range(active_count):
		var view: NoteView = _active_views[i]
		var note: NoteData = view.note_data
		if note != null:
			view.lane_width = _lane_width
			view.scroll_speed_px_per_sec = scroll_speed_px_per_sec
			var is_holding: bool = hit_judge != null and hit_judge.is_note_actively_held(note)
			view.update_position(_current_dsp_time_sec, _hit_line_y, is_holding)


func update_field_at_time(p_dsp_time_sec: float) -> void:
	_current_dsp_time_sec = p_dsp_time_sec

	if hit_judge != null:
		hit_judge.update_dsp_time(p_dsp_time_sec)

	if _chart == null:
		return

	_ensure_pool()
	_spawn_visible_notes(p_dsp_time_sec)
	_update_and_cull_active_views(p_dsp_time_sec)


func get_hit_line_y() -> float:
	return _hit_line_y


func get_lane_width() -> float:
	return _lane_width


func get_active_note_views() -> Array[NoteView]:
	return _active_views


func get_free_pool_count() -> int:
	return _free_pool.size()


func _ensure_pool() -> void:
	var target_count: int = maxi(1, pool_size)
	var current_total: int = _free_pool.size() + _active_views.size()
	while current_total < target_count:
		var view: NoteView = NoteView.new()
		view.reset_for_pool()
		add_child(view)
		_free_pool.append(view)
		current_total += 1


func connect_dependencies() -> void:
	_connect_dependencies()


func _connect_dependencies() -> void:
	if screen_safe_adapter != null:
		if not screen_safe_adapter.safe_play_rect_changed.is_connected(apply_safe_layout):
			screen_safe_adapter.safe_play_rect_changed.connect(apply_safe_layout)

	if dsp_clock != null:
		if not dsp_clock.dsp_time_updated.is_connected(update_field_at_time):
			dsp_clock.dsp_time_updated.connect(update_field_at_time)

	if input_adapter != null and hit_judge != null:
		if not input_adapter.lane_input_pressed.is_connected(hit_judge.on_lane_pressed):
			input_adapter.lane_input_pressed.connect(hit_judge.on_lane_pressed)
		if not input_adapter.lane_input_released.is_connected(hit_judge.on_lane_released):
			input_adapter.lane_input_released.connect(hit_judge.on_lane_released)


func _spawn_visible_notes(p_dsp_time_sec: float) -> void:
	var safe_speed: float = maxf(1.0, scroll_speed_px_per_sec)
	var lookahead_sec: float = (_hit_line_y + TOP_SPAWN_MARGIN_PX) / safe_speed
	var max_spawn_time_sec: float = p_dsp_time_sec + lookahead_sec

	var notes: Array[NoteData] = _chart.notes
	var note_count: int = notes.size()
	while _next_spawn_index < note_count:
		var candidate: NoteData = notes[_next_spawn_index]
		if candidate == null:
			_next_spawn_index += 1
			continue

		if candidate.time_sec > max_spawn_time_sec:
			break

		_next_spawn_index += 1

		if hit_judge != null and hit_judge.is_note_resolved(candidate):
			continue

		var tail_end_sec: float = candidate.time_sec + maxf(0.0, candidate.duration_sec)
		var tail_y: float = _hit_line_y - (tail_end_sec - p_dsp_time_sec) * safe_speed
		if tail_y > _hit_line_y + despawn_past_hit_line_px:
			continue

		var view: NoteView = _acquire_note_view()
		view.setup(candidate, _lane_width, safe_speed)
		var is_holding: bool = hit_judge != null and hit_judge.is_note_actively_held(candidate)
		view.update_position(p_dsp_time_sec, _hit_line_y, is_holding)
		_active_views.append(view)


func _update_and_cull_active_views(p_dsp_time_sec: float) -> void:
	var safe_speed: float = maxf(1.0, scroll_speed_px_per_sec)
	var i: int = _active_views.size() - 1
	while i >= 0:
		var view: NoteView = _active_views[i]
		var note: NoteData = view.note_data
		if note == null:
			_recycle_view_at_index(i)
			i -= 1
			continue

		var is_holding: bool = hit_judge != null and hit_judge.is_note_actively_held(note)
		var is_resolved: bool = hit_judge != null and hit_judge.is_note_resolved(note)
		var tail_end_sec: float = note.time_sec + maxf(0.0, note.duration_sec)
		var tail_y: float = _hit_line_y - (tail_end_sec - p_dsp_time_sec) * safe_speed

		if (is_resolved and not is_holding) or tail_y > _hit_line_y + despawn_past_hit_line_px:
			_recycle_view_at_index(i)
		else:
			view.update_position(p_dsp_time_sec, _hit_line_y, is_holding)

		i -= 1


func _acquire_note_view() -> NoteView:
	if _free_pool.is_empty():
		var extra_view: NoteView = NoteView.new()
		extra_view.reset_for_pool()
		add_child(extra_view)
		return extra_view

	var view: NoteView = _free_pool.pop_back()
	return view


func _recycle_view_at_index(p_active_index: int) -> void:
	var view: NoteView = _active_views[p_active_index]
	_active_views.remove_at(p_active_index)
	view.reset_for_pool()
	_free_pool.append(view)


func _recycle_all_active_views() -> void:
	var i: int = _active_views.size() - 1
	while i >= 0:
		_recycle_view_at_index(i)
		i -= 1
