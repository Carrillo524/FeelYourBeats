class_name LaneField
extends Control

const DEFAULT_LANE_COUNT: int = 4
const TOP_SPAWN_MARGIN_PX: float = 64.0
const DEFAULT_PLAY_WIDTH: float = 950.4
const DEFAULT_PLAY_HEIGHT: float = 1920.0
const LANE_DIVIDER_COLOR: Color = Color(0.45, 0.75, 1.0, 0.16)
const OUTER_BORDER_COLOR: Color = Color(0.35, 0.85, 1.0, 0.32)
const RAIL_IDLE_CORE_COLOR: Color = Color(0.45, 0.90, 1.0, 0.78)
const RAIL_IDLE_GLOW_COLOR: Color = Color(0.20, 0.75, 1.0, 0.42)
const RAIL_PRESSED_CORE_COLOR: Color = Color(0.90, 0.99, 1.0, 1.0)
const RAIL_PRESSED_GLOW_COLOR: Color = Color(0.35, 0.95, 1.0, 0.85)
const RAIL_HOLD_CORE_COLOR: Color = Color(0.75, 1.0, 0.92, 1.0)
const RAIL_HOLD_GLOW_COLOR: Color = Color(0.25, 1.0, 0.82, 0.92)
const RAIL_LATERAL_INSET_PX: float = 10.0

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
var _lane_pressed_states: Array[bool] = [false, false, false, false]
var _lane_hold_states: Array[bool] = [false, false, false, false]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_pool()
	_connect_dependencies()

	if screen_safe_adapter != null:
		apply_safe_layout(
			screen_safe_adapter.get_play_rect(),
			screen_safe_adapter.get_hud_safe_rect()
		)
	else:
		queue_redraw()


func _draw() -> void:
	var lane_count: int = _get_active_lane_count()
	var field_height: float = maxf(1.0, size.y)

	for divider_idx: int in range(lane_count + 1):
		var x_pos: float = float(divider_idx) * _lane_width
		var is_outer: bool = divider_idx == 0 or divider_idx == lane_count
		var divider_color: Color = OUTER_BORDER_COLOR if is_outer else LANE_DIVIDER_COLOR
		var divider_width: float = 2.0 if is_outer else 1.5
		draw_line(Vector2(x_pos, 0.0), Vector2(x_pos, field_height), divider_color, divider_width)

	var receptor_half_h: float = NoteView.DEFAULT_HEAD_HEIGHT_PX * 0.5
	var top_rail_y: float = _hit_line_y - receptor_half_h
	var bottom_rail_y: float = _hit_line_y + receptor_half_h
	var rail_inset: float = maxf(NoteView.HORIZONTAL_PADDING_PX, RAIL_LATERAL_INSET_PX)
	var rail_width: float = maxf(4.0, _lane_width - (rail_inset * 2.0))

	for lane_idx: int in range(lane_count):
		var is_pressed: bool = lane_idx < _lane_pressed_states.size() and _lane_pressed_states[lane_idx]
		var is_holding: bool = lane_idx < _lane_hold_states.size() and _lane_hold_states[lane_idx]

		var rail_start_x: float = (float(lane_idx) * _lane_width) + rail_inset
		var rail_end_x: float = rail_start_x + rail_width

		var core_color: Color = RAIL_IDLE_CORE_COLOR
		var glow_color: Color = RAIL_IDLE_GLOW_COLOR
		var core_thickness: float = 2.0
		var glow_scale: float = 1.0

		if is_holding:
			core_color = RAIL_HOLD_CORE_COLOR
			glow_color = RAIL_HOLD_GLOW_COLOR
			core_thickness = 3.4
			glow_scale = 1.55
		elif is_pressed:
			core_color = RAIL_PRESSED_CORE_COLOR
			glow_color = RAIL_PRESSED_GLOW_COLOR
			core_thickness = 3.0
			glow_scale = 1.40

		_draw_glowing_horizontal_line(
			rail_start_x,
			rail_end_x,
			top_rail_y,
			core_color,
			glow_color,
			core_thickness,
			glow_scale
		)
		_draw_glowing_horizontal_line(
			rail_start_x,
			rail_end_x,
			bottom_rail_y,
			core_color,
			glow_color,
			core_thickness,
			glow_scale
		)


func _draw_glowing_horizontal_line(
	p_x_start: float,
	p_x_end: float,
	p_y: float,
	p_core_color: Color,
	p_glow_color: Color,
	p_core_thickness: float,
	p_glow_scale: float
) -> void:
	var p_from: Vector2 = Vector2(p_x_start, p_y)
	var p_to: Vector2 = Vector2(p_x_end, p_y)

	var outer_halo: Color = Color(p_glow_color.r, p_glow_color.g, p_glow_color.b, p_glow_color.a * 0.16)
	var mid_halo: Color = Color(p_glow_color.r, p_glow_color.g, p_glow_color.b, p_glow_color.a * 0.32)
	var inner_halo: Color = Color(p_glow_color.r, p_glow_color.g, p_glow_color.b, p_glow_color.a * 0.54)

	draw_line(p_from, p_to, outer_halo, p_core_thickness * 5.2 * p_glow_scale)
	draw_line(p_from, p_to, mid_halo, p_core_thickness * 3.2 * p_glow_scale)
	draw_line(p_from, p_to, inner_halo, p_core_thickness * 1.8 * p_glow_scale)
	draw_line(p_from, p_to, p_core_color, p_core_thickness)


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
	_reset_lane_visual_states()
	_chart = p_chart
	_next_spawn_index = 0
	queue_redraw()
	return true


func apply_safe_layout(p_play_rect: Rect2, p_hud_safe_rect: Rect2) -> void:
	position = p_play_rect.position
	size = p_play_rect.size

	var lane_count: int = _get_active_lane_count()
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

	queue_redraw()


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

	if input_adapter != null:
		if not input_adapter.lane_input_pressed.is_connected(_on_lane_input_pressed):
			input_adapter.lane_input_pressed.connect(_on_lane_input_pressed)
		if not input_adapter.lane_input_released.is_connected(_on_lane_input_released):
			input_adapter.lane_input_released.connect(_on_lane_input_released)

	if hit_judge != null:
		if not hit_judge.hold_state_changed.is_connected(_on_hold_state_changed):
			hit_judge.hold_state_changed.connect(_on_hold_state_changed)

	if input_adapter != null and hit_judge != null:
		if not input_adapter.lane_input_pressed.is_connected(hit_judge.on_lane_pressed):
			input_adapter.lane_input_pressed.connect(hit_judge.on_lane_pressed)
		if not input_adapter.lane_input_released.is_connected(hit_judge.on_lane_released):
			input_adapter.lane_input_released.connect(hit_judge.on_lane_released)


func _on_lane_input_pressed(p_lane: int, _p_dsp_time_sec: float) -> void:
	if p_lane < 0 or p_lane >= _lane_pressed_states.size():
		return
	if not _lane_pressed_states[p_lane]:
		_lane_pressed_states[p_lane] = true
		queue_redraw()


func _on_lane_input_released(p_lane: int, _p_dsp_time_sec: float) -> void:
	if p_lane < 0 or p_lane >= _lane_pressed_states.size():
		return
	if _lane_pressed_states[p_lane]:
		_lane_pressed_states[p_lane] = false
		queue_redraw()


func _on_hold_state_changed(p_lane: int, p_is_holding: bool) -> void:
	if p_lane < 0 or p_lane >= _lane_hold_states.size():
		return
	if _lane_hold_states[p_lane] != p_is_holding:
		_lane_hold_states[p_lane] = p_is_holding
		queue_redraw()


func _get_active_lane_count() -> int:
	if screen_safe_adapter != null:
		return maxi(1, screen_safe_adapter.lane_count)
	return DEFAULT_LANE_COUNT


func _reset_lane_visual_states() -> void:
	for i: int in range(_lane_pressed_states.size()):
		_lane_pressed_states[i] = false
	for j: int in range(_lane_hold_states.size()):
		_lane_hold_states[j] = false


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
