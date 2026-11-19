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
	rank_font = _find_and_load_font(RANK_FONT_STEM)


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


func _find_and_load_font(p_stem: String) -> Font:
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
		var loaded: Font = _load_font_resource(matches[i])
		if loaded != null:
			return loaded

	var ext_count: int = SUPPORTED_EXTENSIONS.size()
	for j: int in range(ext_count):
		var ext: String = SUPPORTED_EXTENSIONS[j]
		var direct_path: String = "%s/%s.%s" % [base_dir, p_stem, ext]
		var direct_loaded: Font = _load_font_resource(direct_path)
		if direct_loaded != null:
			return direct_loaded

	return null


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
