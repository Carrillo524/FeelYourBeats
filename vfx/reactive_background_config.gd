class_name ReactiveBackgroundConfig
extends RefCounted

const DEFAULT_SETTINGS_PATH: String = "user://user_settings.cfg"
const SETTINGS_SECTION: String = "reactive_background"

const STYLE_CLASSIC: String = "classic"
const STYLE_WAVES: String = "waves"
const STYLE_AURORA: String = "aurora"

const LEVEL_LOW: String = "low"
const LEVEL_MEDIUM: String = "medium"
const LEVEL_HIGH: String = "high"

const REACTIVITY_MULT_LOW: float = 0.55
const REACTIVITY_MULT_MEDIUM: float = 1.00
const REACTIVITY_MULT_HIGH: float = 1.45

const SUPPORTED_STYLES: PackedStringArray = [
	STYLE_CLASSIC,
	STYLE_WAVES,
	STYLE_AURORA,
]

const SUPPORTED_LEVELS: PackedStringArray = [
	LEVEL_LOW,
	LEVEL_MEDIUM,
	LEVEL_HIGH,
]

var style: String = STYLE_CLASSIC
var reactivity: String = LEVEL_MEDIUM


func reset_to_defaults() -> void:
	style = STYLE_CLASSIC
	reactivity = LEVEL_MEDIUM


func duplicate_config() -> ReactiveBackgroundConfig:
	var copy: ReactiveBackgroundConfig = ReactiveBackgroundConfig.new()
	copy.style = style
	copy.reactivity = reactivity
	return copy


func copy_from(p_other: ReactiveBackgroundConfig) -> void:
	if p_other == null:
		reset_to_defaults()
		return
	style = sanitize_style(p_other.style)
	reactivity = sanitize_level(p_other.reactivity)


func load_from_file(p_settings_path: String = DEFAULT_SETTINGS_PATH) -> bool:
	reset_to_defaults()
	if p_settings_path.is_empty() or not FileAccess.file_exists(p_settings_path):
		return false

	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(p_settings_path) != OK:
		return false

	if not cfg.has_section(SETTINGS_SECTION):
		return true

	style = sanitize_style(str(cfg.get_value(SETTINGS_SECTION, "style", STYLE_CLASSIC)))
	reactivity = sanitize_level(str(cfg.get_value(SETTINGS_SECTION, "reactivity", LEVEL_MEDIUM)))
	return true


func save_to_file(p_settings_path: String = DEFAULT_SETTINGS_PATH) -> bool:
	if p_settings_path.is_empty():
		return false

	var cfg: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(p_settings_path):
		var load_err: Error = cfg.load(p_settings_path)
		if load_err != OK:
			cfg = ConfigFile.new()

	style = sanitize_style(style)
	reactivity = sanitize_level(reactivity)

	cfg.set_value(SETTINGS_SECTION, "style", style)
	cfg.set_value(SETTINGS_SECTION, "reactivity", reactivity)

	var parent_dir: String = p_settings_path.get_base_dir()
	if not parent_dir.is_empty() and parent_dir != "user://":
		DirAccess.make_dir_recursive_absolute(parent_dir)

	return cfg.save(p_settings_path) == OK


func get_reactivity_multiplier() -> float:
	return reactivity_to_multiplier(reactivity)


func is_rendered_style() -> bool:
	return SUPPORTED_STYLES.has(style)


func is_rendered_in_phase8a() -> bool:
	return is_rendered_style()


func is_reserved_for_phase8b() -> bool:
	return false


func to_dict() -> Dictionary:
	return {
		"style": style,
		"reactivity": reactivity,
	}


func apply_dict(p_data: Dictionary) -> void:
	style = sanitize_style(str(p_data.get("style", STYLE_CLASSIC)))
	reactivity = sanitize_level(str(p_data.get("reactivity", LEVEL_MEDIUM)))


static func sanitize_style(p_raw_style: String) -> String:
	var lowered: String = p_raw_style.strip_edges().to_lower()
	match lowered:
		STYLE_CLASSIC, "clasico", "clásico":
			return STYLE_CLASSIC
		STYLE_WAVES, "ondas":
			return STYLE_WAVES
		STYLE_AURORA:
			return STYLE_AURORA
		_:
			# Legacy "shooting_stars" (migrated to particles) and unknown values safely fall back to Classic
			return STYLE_CLASSIC


static func sanitize_level(p_raw_level: String) -> String:
	var lowered: String = p_raw_level.strip_edges().to_lower()
	match lowered:
		LEVEL_LOW, "baja":
			return LEVEL_LOW
		LEVEL_MEDIUM, "media":
			return LEVEL_MEDIUM
		LEVEL_HIGH, "alta":
			return LEVEL_HIGH
		_:
			return LEVEL_MEDIUM


static func reactivity_to_multiplier(p_level: String) -> float:
	match sanitize_level(p_level):
		LEVEL_LOW:
			return REACTIVITY_MULT_LOW
		LEVEL_HIGH:
			return REACTIVITY_MULT_HIGH
		_:
			return REACTIVITY_MULT_MEDIUM


static func style_to_label(p_style: String) -> String:
	match sanitize_style(p_style):
		STYLE_WAVES:
			return "Ondas"
		STYLE_AURORA:
			return "Aurora"
		_:
			return "Clásico"


static func level_to_label(p_level: String) -> String:
	match sanitize_level(p_level):
		LEVEL_LOW:
			return "Baja"
		LEVEL_HIGH:
			return "Alta"
		_:
			return "Media"
