class_name ReactiveParticlesConfig
extends RefCounted

const DEFAULT_SETTINGS_PATH: String = "user://user_settings.cfg"
const SETTINGS_SECTION: String = "reactive_particles"

const TYPE_NONE: String = "none"
const TYPE_CIRCLES: String = "circles"
const TYPE_SQUARES: String = "squares"
const TYPE_MIST: String = "mist"
const TYPE_SPARKLES: String = "sparkles"

const LEVEL_LOW: String = "low"
const LEVEL_MEDIUM: String = "medium"
const LEVEL_HIGH: String = "high"

const MAX_PARTICLES_LOW: int = 28
const MAX_PARTICLES_MEDIUM: int = 48
const MAX_PARTICLES_HIGH: int = 72

const MAX_MIST_LOW: int = 8
const MAX_MIST_MEDIUM: int = 14
const MAX_MIST_HIGH: int = 20

const REACTIVITY_MULT_LOW: float = 0.45
const REACTIVITY_MULT_MEDIUM: float = 1.00
const REACTIVITY_MULT_HIGH: float = 1.55

const SUPPORTED_TYPES: PackedStringArray = [
	TYPE_NONE,
	TYPE_CIRCLES,
	TYPE_SQUARES,
	TYPE_MIST,
	TYPE_SPARKLES,
]

const SUPPORTED_LEVELS: PackedStringArray = [
	LEVEL_LOW,
	LEVEL_MEDIUM,
	LEVEL_HIGH,
]

var enabled: bool = true
var particle_type: String = TYPE_NONE
var density: String = LEVEL_MEDIUM
var music_reactivity: String = LEVEL_MEDIUM


func reset_to_defaults() -> void:
	enabled = true
	particle_type = TYPE_NONE
	density = LEVEL_MEDIUM
	music_reactivity = LEVEL_MEDIUM


func duplicate_config() -> ReactiveParticlesConfig:
	var copy: ReactiveParticlesConfig = ReactiveParticlesConfig.new()
	copy.enabled = enabled
	copy.particle_type = particle_type
	copy.density = density
	copy.music_reactivity = music_reactivity
	return copy


func copy_from(p_other: ReactiveParticlesConfig) -> void:
	if p_other == null:
		reset_to_defaults()
		return
	enabled = p_other.enabled
	particle_type = sanitize_type(p_other.particle_type)
	density = sanitize_level(p_other.density)
	music_reactivity = sanitize_level(p_other.music_reactivity)


func load_from_file(p_settings_path: String = DEFAULT_SETTINGS_PATH) -> bool:
	reset_to_defaults()
	if p_settings_path.is_empty() or not FileAccess.file_exists(p_settings_path):
		return false

	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(p_settings_path) != OK:
		return false

	if not cfg.has_section(SETTINGS_SECTION):
		return true

	enabled = bool(cfg.get_value(SETTINGS_SECTION, "enabled", true))
	particle_type = sanitize_type(str(cfg.get_value(SETTINGS_SECTION, "type", TYPE_NONE)))
	density = sanitize_level(str(cfg.get_value(SETTINGS_SECTION, "density", LEVEL_MEDIUM)))
	music_reactivity = sanitize_level(str(cfg.get_value(SETTINGS_SECTION, "music_reactivity", LEVEL_MEDIUM)))
	return true


func save_to_file(p_settings_path: String = DEFAULT_SETTINGS_PATH) -> bool:
	if p_settings_path.is_empty():
		return false

	var cfg: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(p_settings_path):
		var load_err: Error = cfg.load(p_settings_path)
		if load_err != OK:
			cfg = ConfigFile.new()

	particle_type = sanitize_type(particle_type)
	density = sanitize_level(density)
	music_reactivity = sanitize_level(music_reactivity)

	cfg.set_value(SETTINGS_SECTION, "enabled", enabled)
	cfg.set_value(SETTINGS_SECTION, "type", particle_type)
	cfg.set_value(SETTINGS_SECTION, "density", density)
	cfg.set_value(SETTINGS_SECTION, "music_reactivity", music_reactivity)

	var parent_dir: String = p_settings_path.get_base_dir()
	if not parent_dir.is_empty() and parent_dir != "user://":
		DirAccess.make_dir_recursive_absolute(parent_dir)

	return cfg.save(p_settings_path) == OK


func get_max_particle_count() -> int:
	return density_to_max_count(density)


func get_effective_particle_count() -> int:
	if not is_rendered_type():
		return 0
	if particle_type == TYPE_MIST:
		return density_to_mist_count(density)
	return density_to_max_count(density)


func get_reactivity_multiplier() -> float:
	return reactivity_to_multiplier(music_reactivity)


func is_rendered_type() -> bool:
	return enabled and particle_type != TYPE_NONE and SUPPORTED_TYPES.has(particle_type)


func is_rendered_in_phase7a() -> bool:
	return is_rendered_type()


func is_reserved_for_phase7b() -> bool:
	return false


func to_dict() -> Dictionary:
	return {
		"enabled": enabled,
		"type": particle_type,
		"density": density,
		"music_reactivity": music_reactivity,
	}


func apply_dict(p_data: Dictionary) -> void:
	enabled = bool(p_data.get("enabled", true))
	particle_type = sanitize_type(str(p_data.get("type", TYPE_NONE)))
	density = sanitize_level(str(p_data.get("density", LEVEL_MEDIUM)))
	music_reactivity = sanitize_level(str(p_data.get("music_reactivity", LEVEL_MEDIUM)))


static func sanitize_type(p_raw_type: String) -> String:
	var lowered: String = p_raw_type.strip_edges().to_lower()
	match lowered:
		TYPE_NONE, "ninguna":
			return TYPE_NONE
		TYPE_CIRCLES, "circulos", "círculos":
			return TYPE_CIRCLES
		TYPE_SQUARES, "cuadrados":
			return TYPE_SQUARES
		TYPE_MIST, "neblina":
			return TYPE_MIST
		TYPE_SPARKLES, "destellos":
			return TYPE_SPARKLES
		_:
			return TYPE_NONE


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


static func density_to_max_count(p_density: String) -> int:
	match sanitize_level(p_density):
		LEVEL_LOW:
			return MAX_PARTICLES_LOW
		LEVEL_HIGH:
			return MAX_PARTICLES_HIGH
		_:
			return MAX_PARTICLES_MEDIUM


static func density_to_mist_count(p_density: String) -> int:
	match sanitize_level(p_density):
		LEVEL_LOW:
			return MAX_MIST_LOW
		LEVEL_HIGH:
			return MAX_MIST_HIGH
		_:
			return MAX_MIST_MEDIUM


static func reactivity_to_multiplier(p_level: String) -> float:
	match sanitize_level(p_level):
		LEVEL_LOW:
			return REACTIVITY_MULT_LOW
		LEVEL_HIGH:
			return REACTIVITY_MULT_HIGH
		_:
			return REACTIVITY_MULT_MEDIUM


static func type_to_label(p_type: String) -> String:
	match sanitize_type(p_type):
		TYPE_CIRCLES:
			return "Círculos"
		TYPE_SQUARES:
			return "Cuadrados"
		TYPE_MIST:
			return "Neblina"
		TYPE_SPARKLES:
			return "Destellos"
		_:
			return "Ninguna"


static func level_to_label(p_level: String) -> String:
	match sanitize_level(p_level):
		LEVEL_LOW:
			return "Baja"
		LEVEL_HIGH:
			return "Alta"
		_:
			return "Media"
