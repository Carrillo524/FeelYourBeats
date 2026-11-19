class_name ChartCacheRepository
extends RefCounted

const DEFAULT_CACHE_DIR: String = "user://charts_cache"
const DEFAULT_RECORDS_PATH: String = "user://song_records.cfg"
const CACHE_SCHEMA_VERSION: String = "v1"

var cache_dir_path: String = DEFAULT_CACHE_DIR
var records_file_path: String = DEFAULT_RECORDS_PATH


func _init(
	p_cache_dir_path: String = DEFAULT_CACHE_DIR,
	p_records_file_path: String = DEFAULT_RECORDS_PATH
) -> void:
	cache_dir_path = p_cache_dir_path if not p_cache_dir_path.is_empty() else DEFAULT_CACHE_DIR
	records_file_path = p_records_file_path if not p_records_file_path.is_empty() else DEFAULT_RECORDS_PATH


func build_cache_key(p_audio_path: String, p_difficulty: int, p_note_type_mode: int) -> String:
	var normalized_path: String = p_audio_path.strip_edges().replace("\\", "/")
	var file_size: int = 0
	var modified_time: int = 0

	if not normalized_path.is_empty() and FileAccess.file_exists(p_audio_path):
		modified_time = FileAccess.get_modified_time(p_audio_path)
		var file: FileAccess = FileAccess.open(p_audio_path, FileAccess.READ)
		if file != null:
			file_size = file.get_length()
			file.close()

	var signature: String = "%s|%s|%d|%d|%d|%d" % [
		CACHE_SCHEMA_VERSION,
		normalized_path,
		file_size,
		modified_time,
		p_difficulty,
		p_note_type_mode,
	]
	return signature.sha256_text()


func get_cache_file_path(p_key: String) -> String:
	var base_dir: String = cache_dir_path.trim_suffix("/")
	return "%s/%s.tres" % [base_dir, p_key]


func has_cached_file(p_key: String) -> bool:
	if p_key.is_empty():
		return false
	return FileAccess.file_exists(get_cache_file_path(p_key))


func load_cached_chart(p_key: String) -> ChartData:
	if p_key.is_empty():
		return null

	var file_path: String = get_cache_file_path(p_key)
	if not FileAccess.file_exists(file_path):
		return null

	if not _looks_like_valid_tres_header(file_path):
		_remove_file_silently(file_path)
		return null

	var loaded_res: Resource = ResourceLoader.load(
		file_path,
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)
	if loaded_res == null or not (loaded_res is ChartData):
		_remove_file_silently(file_path)
		return null

	var chart: ChartData = loaded_res as ChartData
	var validation: Dictionary = chart.validate()
	var is_valid: bool = validation.get("valid", false) as bool
	if not is_valid or chart.duration_sec <= 0.0:
		_remove_file_silently(file_path)
		return null

	return chart


func save_cached_chart(p_key: String, p_chart: ChartData) -> bool:
	if p_key.is_empty() or p_chart == null:
		return false

	var validation: Dictionary = p_chart.validate()
	if not (validation.get("valid", false) as bool):
		return false

	var dir_err: Error = DirAccess.make_dir_recursive_absolute(cache_dir_path)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		return false

	var file_path: String = get_cache_file_path(p_key)
	var save_err: Error = ResourceSaver.save(p_chart, file_path)
	return save_err == OK


func build_record_key(p_song_key: String, p_difficulty: int, p_note_type_mode: int) -> String:
	var normalized: String = p_song_key.strip_edges().replace("\\", "/").to_lower()
	var short_hash: String = normalized.sha256_text().substr(0, 16)
	return "song_%s_d%d_m%d" % [short_hash, p_difficulty, p_note_type_mode]


func load_song_record(p_song_key: String, p_difficulty: int, p_note_type_mode: int) -> Dictionary:
	var empty_result: Dictionary = {
		"has_record": false,
		"best_rank": "",
		"best_score": 0,
		"best_accuracy": 0.0,
	}
	if p_song_key.is_empty() or not FileAccess.file_exists(records_file_path):
		return empty_result

	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(records_file_path) != OK:
		return empty_result

	var section: String = build_record_key(p_song_key, p_difficulty, p_note_type_mode)
	if not cfg.has_section(section):
		return empty_result

	return {
		"has_record": true,
		"best_rank": str(cfg.get_value(section, "best_rank", "")),
		"best_score": int(cfg.get_value(section, "best_score", 0)),
		"best_accuracy": float(cfg.get_value(section, "best_accuracy", 0.0)),
	}


func load_best_rank_for_song(p_song_key: String, p_difficulty: int, p_note_type_mode: int) -> String:
	var record: Dictionary = load_song_record(p_song_key, p_difficulty, p_note_type_mode)
	return record.get("best_rank", "") as String


func save_song_record_if_better(
	p_song_key: String,
	p_difficulty: int,
	p_note_type_mode: int,
	p_rank: String,
	p_score: int,
	p_accuracy: float
) -> bool:
	if p_song_key.is_empty():
		return false

	var cfg: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(records_file_path):
		var load_err: Error = cfg.load(records_file_path)
		if load_err != OK:
			cfg = ConfigFile.new()

	var section: String = build_record_key(p_song_key, p_difficulty, p_note_type_mode)
	var has_prev: bool = cfg.has_section(section)
	var prev_score: int = int(cfg.get_value(section, "best_score", -1))
	var prev_acc: float = float(cfg.get_value(section, "best_accuracy", -1.0))

	var is_better: bool = (
		(not has_prev)
		or (p_score > prev_score)
		or (p_score == prev_score and p_accuracy > prev_acc)
	)
	if not is_better:
		return false

	cfg.set_value(section, "song_key", p_song_key)
	cfg.set_value(section, "difficulty", p_difficulty)
	cfg.set_value(section, "note_type_mode", p_note_type_mode)
	cfg.set_value(section, "best_rank", p_rank)
	cfg.set_value(section, "best_score", p_score)
	cfg.set_value(section, "best_accuracy", p_accuracy)

	var parent_dir: String = records_file_path.get_base_dir()
	if not parent_dir.is_empty() and parent_dir != "user://":
		DirAccess.make_dir_recursive_absolute(parent_dir)

	return cfg.save(records_file_path) == OK


func _looks_like_valid_tres_header(p_file_path: String) -> bool:
	var file: FileAccess = FileAccess.open(p_file_path, FileAccess.READ)
	if file == null:
		return false
	var first_line: String = file.get_line().strip_edges()
	file.close()
	return first_line.begins_with("[gd_resource")


func _remove_file_silently(p_file_path: String) -> void:
	if FileAccess.file_exists(p_file_path):
		DirAccess.remove_absolute(p_file_path)
