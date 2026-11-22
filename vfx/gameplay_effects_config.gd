class_name GameplayEffectsConfig
extends RefCounted

const DEFAULT_SETTINGS_PATH: String = "user://user_settings.cfg"
const SETTINGS_SECTION: String = "gameplay_effects"

const HIT_CLASSIC: String = "classic"
const HIT_STAR: String = "star"
const HIT_CROWN: String = "crown"

const TOUCH_WAVE: String = "wave"
const TOUCH_DOUBLE_DIAMOND: String = "double_diamond"
const TOUCH_MUSICAL_NOTE: String = "musical_note"

const VANISH_FIREWORK: String = "firework"
const VANISH_ZOOM_FADE: String = "zoom_fade"
const VANISH_FRACTURE: String = "fracture"

const SUPPORTED_HIT_EFFECTS: PackedStringArray = [
	HIT_CLASSIC,
	HIT_STAR,
	HIT_CROWN,
]

const SUPPORTED_TOUCH_EFFECTS: PackedStringArray = [
	TOUCH_WAVE,
	TOUCH_DOUBLE_DIAMOND,
	TOUCH_MUSICAL_NOTE,
]

const SUPPORTED_VANISH_EFFECTS: PackedStringArray = [
	VANISH_FIREWORK,
	VANISH_ZOOM_FADE,
	VANISH_FRACTURE,
]

var hit_effect: String = HIT_CLASSIC
var touch_effect: String = TOUCH_WAVE
var vanish_effect: String = VANISH_FIREWORK


func reset_to_defaults() -> void:
	hit_effect = HIT_CLASSIC
	touch_effect = TOUCH_WAVE
	vanish_effect = VANISH_FIREWORK


func duplicate_config() -> GameplayEffectsConfig:
	var copy: GameplayEffectsConfig = GameplayEffectsConfig.new()
	copy.hit_effect = hit_effect
	copy.touch_effect = touch_effect
	copy.vanish_effect = vanish_effect
	return copy


func copy_from(p_other: GameplayEffectsConfig) -> void:
	if p_other == null:
		reset_to_defaults()
		return
	hit_effect = sanitize_hit_effect(p_other.hit_effect)
	touch_effect = sanitize_touch_effect(p_other.touch_effect)
	vanish_effect = sanitize_vanish_effect(p_other.vanish_effect)


func load_from_file(p_settings_path: String = DEFAULT_SETTINGS_PATH) -> bool:
	reset_to_defaults()
	if p_settings_path.is_empty() or not FileAccess.file_exists(p_settings_path):
		return false

	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(p_settings_path) != OK:
		return false

	if not cfg.has_section(SETTINGS_SECTION):
		return true

	hit_effect = sanitize_hit_effect(str(cfg.get_value(SETTINGS_SECTION, "hit_effect", HIT_CLASSIC)))
	touch_effect = sanitize_touch_effect(str(cfg.get_value(SETTINGS_SECTION, "touch_effect", TOUCH_WAVE)))
	vanish_effect = sanitize_vanish_effect(str(cfg.get_value(SETTINGS_SECTION, "vanish_effect", VANISH_FIREWORK)))
	return true


func save_to_file(p_settings_path: String = DEFAULT_SETTINGS_PATH) -> bool:
	if p_settings_path.is_empty():
		return false

	var cfg: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(p_settings_path):
		var load_err: Error = cfg.load(p_settings_path)
		if load_err != OK:
			cfg = ConfigFile.new()

	hit_effect = sanitize_hit_effect(hit_effect)
	touch_effect = sanitize_touch_effect(touch_effect)
	vanish_effect = sanitize_vanish_effect(vanish_effect)

	cfg.set_value(SETTINGS_SECTION, "hit_effect", hit_effect)
	cfg.set_value(SETTINGS_SECTION, "touch_effect", touch_effect)
	cfg.set_value(SETTINGS_SECTION, "vanish_effect", vanish_effect)

	var parent_dir: String = p_settings_path.get_base_dir()
	if not parent_dir.is_empty() and parent_dir != "user://":
		DirAccess.make_dir_recursive_absolute(parent_dir)

	return cfg.save(p_settings_path) == OK


func to_dict() -> Dictionary:
	return {
		"hit_effect": hit_effect,
		"touch_effect": touch_effect,
		"vanish_effect": vanish_effect,
	}


func apply_dict(p_data: Dictionary) -> void:
	hit_effect = sanitize_hit_effect(str(p_data.get("hit_effect", HIT_CLASSIC)))
	touch_effect = sanitize_touch_effect(str(p_data.get("touch_effect", TOUCH_WAVE)))
	vanish_effect = sanitize_vanish_effect(str(p_data.get("vanish_effect", VANISH_FIREWORK)))


static func sanitize_hit_effect(p_raw: String) -> String:
	var lowered: String = p_raw.strip_edges().to_lower()
	match lowered:
		HIT_STAR, "estrella":
			return HIT_STAR
		HIT_CROWN, "corona":
			return HIT_CROWN
		_:
			return HIT_CLASSIC


static func sanitize_touch_effect(p_raw: String) -> String:
	var lowered: String = p_raw.strip_edges().to_lower()
	match lowered:
		TOUCH_DOUBLE_DIAMOND, "doble rombo", "doble_rombo":
			return TOUCH_DOUBLE_DIAMOND
		TOUCH_MUSICAL_NOTE, "figura musical", "figura_musical":
			return TOUCH_MUSICAL_NOTE
		_:
			return TOUCH_WAVE


static func sanitize_vanish_effect(p_raw: String) -> String:
	var lowered: String = p_raw.strip_edges().to_lower()
	match lowered:
		VANISH_ZOOM_FADE, "zoom + fade", "zoom+fade":
			return VANISH_ZOOM_FADE
		VANISH_FRACTURE, "fractura":
			return VANISH_FRACTURE
		_:
			return VANISH_FIREWORK


static func hit_effect_to_label(p_style: String) -> String:
	match sanitize_hit_effect(p_style):
		HIT_STAR:
			return "Estrella"
		HIT_CROWN:
			return "Corona"
		_:
			return "Clásico"


static func touch_effect_to_label(p_style: String) -> String:
	match sanitize_touch_effect(p_style):
		TOUCH_DOUBLE_DIAMOND:
			return "Doble Rombo"
		TOUCH_MUSICAL_NOTE:
			return "Figura Musical"
		_:
			return "Onda"


static func vanish_effect_to_label(p_style: String) -> String:
	match sanitize_vanish_effect(p_style):
		VANISH_ZOOM_FADE:
			return "Zoom + Fade"
		VANISH_FRACTURE:
			return "Fractura"
		_:
			return "FireWork"
