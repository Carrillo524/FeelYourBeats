class_name UiFontRegistry
extends RefCounted

const DEFAULT_FONTS_DIR: String = "res://assets/fonts"
const GLOBAL_FONT_STEM: String = "global_font"
const TITLE_FONT_STEM: String = "title_font"
const COMBO_FONT_STEM: String = "combo_font"
const RANK_FONT_STEM: String = "rank_font"
const SUPPORTED_EXTENSIONS: PackedStringArray = ["ttf", "otf"]

const COLOR_OUTLINE_DARK: Color = Color(0.03, 0.06, 0.14, 0.96)
const COLOR_TITLE_OUTLINE: Color = Color(0.04, 0.14, 0.24, 0.96)
const COLOR_TITLE_SHADOW: Color = Color(0.14, 0.90, 1.0, 0.45)
const COLOR_COMBO_SHADOW: Color = Color(0.02, 0.04, 0.10, 0.72)
const COLOR_RANK_SHADOW: Color = Color(0.02, 0.04, 0.10, 0.78)

static var _shared_rank_font_searched: bool = false
static var _shared_rank_font_path: String = ""

var fonts_dir_path: String = DEFAULT_FONTS_DIR
var global_font: Font = null
var title_font: Font = null
var combo_font: Font = null
var rank_font: Font = null


func _init(p_fonts_dir_path: String = DEFAULT_FONTS_DIR) -> void:
	fonts_dir_path = p_fonts_dir_path if not p_fonts_dir_path.is_empty() else DEFAULT_FONTS_DIR
	reload_fonts()


func reload_fonts() -> void:
	global_font = _find_and_load_font(GLOBAL_FONT_STEM)
	title_font = _find_and_load_font(TITLE_FONT_STEM)
	combo_font = _find_and_load_font(COMBO_FONT_STEM)
	var rank_path: String = _find_font_path(RANK_FONT_STEM)
	rank_font = _load_font_resource(rank_path)
	if fonts_dir_path == DEFAULT_FONTS_DIR:
		_shared_rank_font_path = rank_path
		_shared_rank_font_searched = true


static func apply_neon_rank_style(p_label: Label, p_rank: String, p_font_size: int) -> void:
	if p_label == null:
		return

	var resolved_rank_font: Font = _load_shared_rank_font()
	if resolved_rank_font != null:
		p_label.add_theme_font_override("font", resolved_rank_font)

	var safe_size: int = maxi(16, p_font_size)
	p_label.add_theme_font_size_override("font_size", safe_size)
	p_label.modulate = Color.WHITE

	var normalized_rank: String = p_rank.strip_edges().to_upper()
	var core_color: Color = Color(0.62, 0.84, 0.96, 0.78)
	var outline_color: Color = Color(0.08, 0.26, 0.40, 0.72)
	var halo_color: Color = Color(0.15, 0.72, 0.92, 0.34)
	var is_unplayed: bool = false

	match normalized_rank:
		"SSS+":
			core_color = Color(1.0, 0.98, 1.0, 1.0)
			outline_color = Color(1.0, 0.26, 0.92, 0.98)
			halo_color = Color(0.22, 0.96, 1.0, 0.80)
		"SSS":
			core_color = Color(1.0, 0.97, 0.96, 1.0)
			outline_color = Color(1.0, 0.32, 0.84, 0.98)
			halo_color = Color(1.0, 0.28, 0.88, 0.78)
		"SS", "S":
			core_color = Color(1.0, 0.98, 0.86, 1.0)
			outline_color = Color(1.0, 0.78, 0.14, 0.96)
			halo_color = Color(1.0, 0.84, 0.18, 0.72)
		"A+", "A":
			core_color = Color(0.88, 1.0, 0.94, 1.0)
			outline_color = Color(0.14, 0.96, 0.56, 0.96)
			halo_color = Color(0.18, 1.0, 0.62, 0.70)
		"B":
			core_color = Color(0.86, 0.97, 1.0, 1.0)
			outline_color = Color(0.12, 0.84, 1.0, 0.96)
			halo_color = Color(0.15, 0.88, 1.0, 0.70)
		"C":
			core_color = Color(0.95, 0.90, 1.0, 1.0)
			outline_color = Color(0.68, 0.40, 1.0, 0.96)
			halo_color = Color(0.62, 0.32, 1.0, 0.70)
		"D":
			core_color = Color(1.0, 0.90, 0.92, 1.0)
			outline_color = Color(1.0, 0.36, 0.52, 0.96)
			halo_color = Color(1.0, 0.28, 0.46, 0.70)
		_:
			is_unplayed = true

	var size_t: float = clampf((float(safe_size) - 48.0) / 202.0, 0.0, 1.0)
	var outline_px: int = clampi(int(round(lerpf(4.0, 12.0, size_t))), 3, 14)
	var blur_halo_px: int = clampi(int(round(lerpf(18.0, 46.0, size_t))), 16, 48)
	if is_unplayed:
		outline_px = maxi(2, outline_px / 2)
		blur_halo_px = maxi(8, blur_halo_px / 2)

	p_label.add_theme_color_override("font_color", core_color)
	p_label.add_theme_constant_override("outline_size", outline_px)
	p_label.add_theme_color_override("font_outline_color", outline_color)
	p_label.add_theme_color_override("font_shadow_color", halo_color)
	p_label.add_theme_constant_override("shadow_offset_x", 0)
	p_label.add_theme_constant_override("shadow_offset_y", 0)
	p_label.add_theme_constant_override("shadow_outline_size", blur_halo_px)


func get_global_font() -> Font:
	return global_font


func get_title_font() -> Font:
	return title_font


func get_combo_font() -> Font:
	return combo_font


func get_rank_font() -> Font:
	return rank_font


func apply_global_theme(p_tree: SceneTree) -> void:
	if p_tree == null or p_tree.root == null or global_font == null:
		return
	var root_theme: Theme = p_tree.root.theme
	if root_theme == null:
		root_theme = Theme.new()
		p_tree.root.theme = root_theme
	root_theme.default_font = global_font


func apply_global_font_override(p_control: Control, p_outline_size: int = 0) -> void:
	if p_control == null:
		return
	if global_font != null:
		p_control.add_theme_font_override("font", global_font)
	else:
		p_control.remove_theme_font_override("font")

	if p_outline_size > 0:
		p_control.add_theme_constant_override("outline_size", p_outline_size)
		p_control.add_theme_color_override("font_outline_color", COLOR_OUTLINE_DARK)


func apply_title_role(p_control: Control, p_outline_size: int = 10) -> void:
	if p_control == null:
		return
	if title_font != null:
		p_control.add_theme_font_override("font", title_font)
	p_control.add_theme_constant_override("outline_size", p_outline_size)
	p_control.add_theme_color_override("font_outline_color", COLOR_TITLE_OUTLINE)
	if p_control is Label:
		p_control.add_theme_color_override("font_shadow_color", COLOR_TITLE_SHADOW)
		p_control.add_theme_constant_override("shadow_offset_x", 0)
		p_control.add_theme_constant_override("shadow_offset_y", 4)
		p_control.add_theme_constant_override("shadow_outline_size", maxi(3, p_outline_size / 2))


func apply_combo_role(p_control: Control, p_outline_size: int = 8) -> void:
	if p_control == null:
		return
	if combo_font != null:
		p_control.add_theme_font_override("font", combo_font)
	p_control.add_theme_constant_override("outline_size", p_outline_size)
	p_control.add_theme_color_override("font_outline_color", COLOR_OUTLINE_DARK)
	if p_control is Label:
		p_control.add_theme_color_override("font_shadow_color", COLOR_COMBO_SHADOW)
		p_control.add_theme_constant_override("shadow_offset_x", 0)
		p_control.add_theme_constant_override("shadow_offset_y", 3)
		p_control.add_theme_constant_override("shadow_outline_size", maxi(2, p_outline_size / 2))


func apply_rank_role(p_control: Control, p_outline_size: int = 10) -> void:
	if p_control == null:
		return
	if rank_font != null:
		p_control.add_theme_font_override("font", rank_font)
	p_control.add_theme_constant_override("outline_size", p_outline_size)
	p_control.add_theme_color_override("font_outline_color", COLOR_OUTLINE_DARK)
	if p_control is Label:
		p_control.add_theme_color_override("font_shadow_color", COLOR_RANK_SHADOW)
		p_control.add_theme_constant_override("shadow_offset_x", 0)
		p_control.add_theme_constant_override("shadow_offset_y", 4)
		p_control.add_theme_constant_override("shadow_outline_size", maxi(2, p_outline_size / 2))


func get_loaded_roles_status() -> Dictionary:
	return {
		"global": global_font != null,
		"title": title_font != null,
		"combo": combo_font != null,
		"rank": rank_font != null,
	}


static func _load_shared_rank_font() -> Font:
	if not _shared_rank_font_searched:
		var temp_reg: UiFontRegistry = UiFontRegistry.new(DEFAULT_FONTS_DIR)
		_shared_rank_font_path = temp_reg._find_font_path(RANK_FONT_STEM)
		_shared_rank_font_searched = true
	if _shared_rank_font_path.is_empty():
		return null
	if _shared_rank_font_path.begins_with("res://") and ResourceLoader.exists(_shared_rank_font_path):
		var res: Resource = ResourceLoader.load(_shared_rank_font_path)
		if res is Font:
			return res as Font
	if FileAccess.file_exists(_shared_rank_font_path):
		var dynamic_font: FontFile = FontFile.new()
		if dynamic_font.load_dynamic_font(_shared_rank_font_path) == OK:
			return dynamic_font
	return null


func _find_font_path(p_stem: String) -> String:
	var base_dir: String = fonts_dir_path.trim_suffix("/")
	var stem_lower: String = p_stem.to_lower()
	var matches: Array[String] = []
	var seen: Dictionary = {}

	var dir: DirAccess = DirAccess.open(base_dir)
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

				var ext_lower: String = cleaned.get_extension().to_lower()
				if SUPPORTED_EXTENSIONS.has(ext_lower):
					if cleaned.get_basename().to_lower() == stem_lower:
						var full_path: String = "%s/%s" % [base_dir, cleaned]
						if not seen.has(full_path):
							seen[full_path] = true
							matches.append(full_path)
			entry = dir.get_next()
		dir.list_dir_end()

	matches.sort_custom(_compare_by_extension_priority)
	for i: int in range(matches.size()):
		if _load_font_resource(matches[i]) != null:
			return matches[i]

	var ext_count: int = SUPPORTED_EXTENSIONS.size()
	for j: int in range(ext_count):
		var ext: String = SUPPORTED_EXTENSIONS[j]
		var direct_path: String = "%s/%s.%s" % [base_dir, p_stem, ext]
		if _load_font_resource(direct_path) != null:
			return direct_path

	return ""


func _find_and_load_font(p_stem: String) -> Font:
	var font_path: String = _find_font_path(p_stem)
	return _load_font_resource(font_path)


func _compare_by_extension_priority(p_a: String, p_b: String) -> bool:
	var prio_a: int = _get_extension_priority(p_a.get_extension().to_lower())
	var prio_b: int = _get_extension_priority(p_b.get_extension().to_lower())
	if prio_a != prio_b:
		return prio_a < prio_b
	return p_a.to_lower() < p_b.to_lower()


func _get_extension_priority(p_ext: String) -> int:
	var count: int = SUPPORTED_EXTENSIONS.size()
	for i: int in range(count):
		if SUPPORTED_EXTENSIONS[i] == p_ext:
			return i
	return count


func _load_font_resource(p_path: String) -> Font:
	if p_path.is_empty():
		return null
	if p_path.begins_with("res://") and ResourceLoader.exists(p_path):
		var res: Resource = ResourceLoader.load(p_path)
		if res is Font:
			return res as Font
	if FileAccess.file_exists(p_path):
		var dynamic_font: FontFile = FontFile.new()
		if dynamic_font.load_dynamic_font(p_path) == OK:
			return dynamic_font
	return null
