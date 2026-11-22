class_name ScreenSafeAdapter
extends Node

signal safe_play_rect_changed(play_rect: Rect2, hud_safe_rect: Rect2)

const DEFAULT_VIEWPORT_WIDTH: float = 1080.0
const DEFAULT_VIEWPORT_HEIGHT: float = 1920.0
const MIN_LATERAL_MARGIN_RATIO: float = 0.0
const MAX_LATERAL_MARGIN_RATIO: float = 0.25
const MAX_COMBINED_SIDE_MARGIN_RATIO: float = 0.35
const MAX_VERTICAL_SAFE_INSET_RATIO: float = 0.25
const PLAY_MAX_WIDTH_RATIO: float = 0.94
const PLAY_LANDSCAPE_HEIGHT_WIDTH_RATIO: float = 0.62

@export_range(0.0, 0.25, 0.005) var lateral_margin_ratio: float = 0.06
@export var lane_count: int = 4

var _play_rect: Rect2 = Rect2(0.0, 0.0, DEFAULT_VIEWPORT_WIDTH, DEFAULT_VIEWPORT_HEIGHT)
var _hud_safe_rect: Rect2 = Rect2(0.0, 0.0, DEFAULT_VIEWPORT_WIDTH, DEFAULT_VIEWPORT_HEIGHT)


func _ready() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	var tree: SceneTree = get_tree()
	if tree != null and tree.root != null and tree.root != viewport:
		if not tree.root.size_changed.is_connected(_on_viewport_size_changed):
			tree.root.size_changed.connect(_on_viewport_size_changed)
	recalculate_layout()


func _exit_tree() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.disconnect(_on_viewport_size_changed)
	var tree: SceneTree = get_tree()
	if tree != null and tree.root != null and tree.root.size_changed.is_connected(_on_viewport_size_changed):
		tree.root.size_changed.disconnect(_on_viewport_size_changed)


func recalculate_layout() -> void:
	recalculate_for_viewport_size(_get_active_viewport_size())


func recalculate_for_viewport_size(p_viewport_size: Vector2) -> void:
	var viewport_size: Vector2 = Vector2(
		maxf(1.0, p_viewport_size.x),
		maxf(1.0, p_viewport_size.y)
	)
	var window_size: Vector2i = DisplayServer.window_get_size()
	var display_safe: Rect2i = DisplayServer.get_display_safe_area()

	var safe_left: float = 0.0
	var safe_top: float = 0.0
	var safe_right: float = 0.0
	var safe_bottom: float = 0.0

	var valid_window: bool = window_size.x > 0 and window_size.y > 0
	var valid_safe_rect: bool = (
		display_safe.size.x > 0
		and display_safe.size.y > 0
		and display_safe.position.x >= 0
		and display_safe.position.y >= 0
		and display_safe.end.x <= window_size.x
		and display_safe.end.y <= window_size.y
	)

	if valid_window and valid_safe_rect:
		var scale_x: float = viewport_size.x / float(window_size.x)
		var scale_y: float = viewport_size.y / float(window_size.y)

		safe_left = clampf(
			float(display_safe.position.x) * scale_x,
			0.0,
			viewport_size.x * MAX_LATERAL_MARGIN_RATIO
		)
		safe_right = clampf(
			float(window_size.x - display_safe.end.x) * scale_x,
			0.0,
			viewport_size.x * MAX_LATERAL_MARGIN_RATIO
		)
		safe_top = clampf(
			float(display_safe.position.y) * scale_y,
			0.0,
			viewport_size.y * MAX_VERTICAL_SAFE_INSET_RATIO
		)
		safe_bottom = clampf(
			float(window_size.y - display_safe.end.y) * scale_y,
			0.0,
			viewport_size.y * MAX_VERTICAL_SAFE_INSET_RATIO
		)

	var clamped_margin_ratio: float = clampf(
		lateral_margin_ratio,
		MIN_LATERAL_MARGIN_RATIO,
		MAX_LATERAL_MARGIN_RATIO
	)
	var min_axis_px: float = minf(viewport_size.x, viewport_size.y)
	var base_lateral_margin_px: float = min_axis_px * clamped_margin_ratio
	var symmetric_horizontal_safe_px: float = maxf(safe_left, safe_right)
	var combined_side_margin_px: float = clampf(
		base_lateral_margin_px + symmetric_horizontal_safe_px,
		0.0,
		viewport_size.x * MAX_COMBINED_SIDE_MARGIN_RATIO
	)

	var safe_available_w: float = maxf(1.0, viewport_size.x - (combined_side_margin_px * 2.0))
	var proportional_max_w: float = minf(
		viewport_size.x * PLAY_MAX_WIDTH_RATIO,
		viewport_size.y * PLAY_LANDSCAPE_HEIGHT_WIDTH_RATIO
	)
	var play_width: float = maxf(1.0, minf(safe_available_w, proportional_max_w))
	var play_x: float = (viewport_size.x - play_width) * 0.5
	_play_rect = Rect2(play_x, 0.0, play_width, viewport_size.y)

	var hud_left: float = maxf(safe_left, base_lateral_margin_px)
	var hud_right: float = maxf(safe_right, base_lateral_margin_px)
	var hud_width: float = maxf(1.0, viewport_size.x - hud_left - hud_right)
	var hud_height: float = maxf(1.0, viewport_size.y - safe_top - safe_bottom)
	_hud_safe_rect = Rect2(hud_left, safe_top, hud_width, hud_height)

	safe_play_rect_changed.emit(_play_rect, _hud_safe_rect)


func get_play_rect() -> Rect2:
	return _play_rect


func get_hud_safe_rect() -> Rect2:
	return _hud_safe_rect


func get_lane_width() -> float:
	var valid_lanes: int = maxi(1, lane_count)
	return _play_rect.size.x / float(valid_lanes)


func get_lane_at_x(p_viewport_x: float) -> int:
	if p_viewport_x < _play_rect.position.x or p_viewport_x >= _play_rect.end.x:
		return -1

	var lane_width: float = get_lane_width()
	if lane_width <= 0.0:
		return -1

	var valid_lanes: int = maxi(1, lane_count)
	var relative_x: float = p_viewport_x - _play_rect.position.x
	var lane_index: int = int(floor(relative_x / lane_width))
	return clampi(lane_index, 0, valid_lanes - 1)


func _get_active_viewport_size() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		var visible_size: Vector2 = viewport.get_visible_rect().size
		if visible_size.x > 0.0 and visible_size.y > 0.0:
			return visible_size
	return Vector2(DEFAULT_VIEWPORT_WIDTH, DEFAULT_VIEWPORT_HEIGHT)


func _on_viewport_size_changed() -> void:
	recalculate_layout()
