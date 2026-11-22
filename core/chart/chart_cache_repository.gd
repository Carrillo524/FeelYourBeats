class_name ChartCacheRepository
extends RefCounted

const DEFAULT_CACHE_DIR: String = "user://charts_cache"
const DEFAULT_RECORDS_PATH: String = "user://song_records.cfg"
const CACHE_SCHEMA_VERSION: String = "v6"
const BUILTIN_DEMO_SONG_KEY: String = "builtin://demo_128bpm"
const LEGACY_DEMO_SONG_KEY: String = "fyb_demo_128bpm"

var cache_dir_path: String = DEFAULT_CACHE_DIR
var records_file_path: String = DEFAULT_RECORDS_PATH


static func normalize_song_key(p_audio_path: String) -> String:
	var cleaned: String = p_audio_path.strip_edges().replace("\\", "/")
	var lower_cleaned: String = cleaned.to_lower()
	if (
		lower_cleaned.is_empty()
		or lower_cleaned == BUILTIN_DEMO_SONG_KEY
		or lower_cleaned == LEGACY_DEMO_SONG_KEY
	):
		return BUILTIN_DEMO_SONG_KEY

	if lower_cleaned.begins_with("res://"):
		var res_tail: String = lower_cleaned.substr(6).strip_edges()
		while res_tail.begins_with("/"):
			res_tail = res_tail.substr(1)
		return "res://%s" % res_tail

	if lower_cleaned.begins_with("user://"):
		var user_tail: String = lower_cleaned.substr(7).strip_edges()
		while user_tail.begins_with("/"):
			user_tail = user_tail.substr(1)
		return "user://%s" % user_tail

	while lower_cleaned.contains("//"):
		lower_cleaned = lower_cleaned.replace("//", "/")
	return lower_cleaned


static func difficulty_to_label(p_difficulty: int) -> String:
	match p_difficulty:
		AutoChartGenerator.Difficulty.EASY:
			return "FÁCIL"
		AutoChartGenerator.Difficulty.HARD:
			return "DIFÍCIL"
		_:
			return "NORMAL"


static func note_mode_to_label(p_note_type_mode: int) -> String:
	match p_note_type_mode:
		AutoChartGenerator.NoteTypeMode.TAP_ONLY:
			return "SOLO TAP"
		AutoChartGenerator.NoteTypeMode.DOUBLE_TAP:
			return "DOBLE TAP"
		AutoChartGenerator.NoteTypeMode.HOLD_AND_DOUBLE_TAP:
			return "HOLD + DOBLE TAP"
		_:
			return "TAP + HOLD"


static func format_summary_badge(p_summary: Dictionary) -> String:
	var has_record: bool = p_summary.get("has_record", false) as bool
	if not has_record:
		return "[--]"
	var best_rank: String = str(p_summary.get("best_rank", ""))
	if best_rank.is_empty():
		return "[--]"
	var best_diff: int = int(p_summary.get("best_difficulty", AutoChartGenerator.Difficulty.NORMAL))
	return "[%s · %s]" % [best_rank, difficulty_to_label(best_diff)]


func _init(
	p_cache_dir_path: String = DEFAULT_CACHE_DIR,
	p_records_file_path: String = DEFAULT_RECORDS_PATH
) -> void:
	cache_dir_path = p_cache_dir_path if not p_cache_dir_path.is_empty() else DEFAULT_CACHE_DIR
	records_file_path = p_records_file_path if not p_records_file_path.is_empty() else DEFAULT_RECORDS_PATH


func build_cache_key(p_audio_path: String, p_difficulty: int, p_note_type_mode: int) -> String:
	var normalized_path: String = normalize_song_key(p_audio_path)
	var file_size: int = 0
	var modified_time: int = 0

	if not p_audio_path.is_empty() and FileAccess.file_exists(p_audio_path):
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
	var normalized: String = normalize_song_key(p_song_key)
	var short_hash: String = normalized.sha256_text().substr(0, 16)
	return "song_%s_d%d_m%d" % [short_hash, p_difficulty, p_note_type_mode]


func build_summary_key(p_song_key: String) -> String:
	var normalized: String = normalize_song_key(p_song_key)
	var short_hash: String = normalized.sha256_text().substr(0, 16)
	return "summary_%s" % short_hash


func load_song_record(p_song_key: String, p_difficulty: int, p_note_type_mode: int) -> Dictionary:
	var empty_result: Dictionary = {
		"has_record": false,
		"best_rank": "",
		"best_score": 0,
		"best_accuracy": 0.0,
	}
	if not FileAccess.file_exists(records_file_path):
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


func load_song_summary(p_song_key: String) -> Dictionary:
	var empty_summary: Dictionary = {
		"has_record": false,
		"best_rank": "",
		"best_difficulty": AutoChartGenerator.Difficulty.NORMAL,
		"best_score": 0,
		"best_accuracy": 0.0,
		"last_rank": "",
		"last_difficulty": AutoChartGenerator.Difficulty.NORMAL,
		"badge_text": "[--]",
	}
	if not FileAccess.file_exists(records_file_path):
		return empty_summary

	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(records_file_path) != OK:
		return empty_summary

	var summary_section: String = build_summary_key(p_song_key)
	if cfg.has_section(summary_section):
		var best_rank: String = str(cfg.get_value(summary_section, "best_rank", ""))
		var best_diff: int = int(cfg.get_value(summary_section, "best_difficulty", AutoChartGenerator.Difficulty.NORMAL))
		var result: Dictionary = {
			"has_record": not best_rank.is_empty(),
			"best_rank": best_rank,
			"best_difficulty": best_diff,
			"best_score": int(cfg.get_value(summary_section, "best_score", 0)),
			"best_accuracy": float(cfg.get_value(summary_section, "best_accuracy", 0.0)),
			"last_rank": str(cfg.get_value(summary_section, "last_rank", best_rank)),
			"last_difficulty": int(cfg.get_value(summary_section, "last_difficulty", best_diff)),
		}
		result["badge_text"] = format_summary_badge(result)
		return result

	# Fallback scan across per-(difficulty, mode) sections for legacy records
	var best_found_score: int = -1
	var best_found_acc: float = -1.0
	var best_found_rank: String = ""
	var best_found_diff: int = AutoChartGenerator.Difficulty.NORMAL
	for diff: int in range(3):
		for mode: int in range(4):
			var rec_sec: String = build_record_key(p_song_key, diff, mode)
			if cfg.has_section(rec_sec):
				var rec_score: int = int(cfg.get_value(rec_sec, "best_score", 0))
				var rec_acc: float = float(cfg.get_value(rec_sec, "best_accuracy", 0.0))
				if rec_score > best_found_score or (rec_score == best_found_score and rec_acc > best_found_acc):
					best_found_score = rec_score
					best_found_acc = rec_acc
					best_found_rank = str(cfg.get_value(rec_sec, "best_rank", ""))
					best_found_diff = diff

	if best_found_score >= 0 and not best_found_rank.is_empty():
		var legacy_summary: Dictionary = {
			"has_record": true,
			"best_rank": best_found_rank,
			"best_difficulty": best_found_diff,
			"best_score": best_found_score,
			"best_accuracy": best_found_acc,
			"last_rank": best_found_rank,
			"last_difficulty": best_found_diff,
		}
		legacy_summary["badge_text"] = format_summary_badge(legacy_summary)
		return legacy_summary

	return empty_summary


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
	var normalized_key: String = normalize_song_key(p_song_key)
	var cfg: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(records_file_path):
		var load_err: Error = cfg.load(records_file_path)
		if load_err != OK:
			cfg = ConfigFile.new()

	var section: String = build_record_key(normalized_key, p_difficulty, p_note_type_mode)
	var has_prev: bool = cfg.has_section(section)
	var prev_score: int = int(cfg.get_value(section, "best_score", -1))
	var prev_acc: float = float(cfg.get_value(section, "best_accuracy", -1.0))

	var is_better: bool = (
		(not has_prev)
		or (p_score > prev_score)
		or (p_score == prev_score and p_accuracy > prev_acc)
	)
	if is_better:
		cfg.set_value(section, "song_key", normalized_key)
		cfg.set_value(section, "difficulty", p_difficulty)
		cfg.set_value(section, "note_type_mode", p_note_type_mode)
		cfg.set_value(section, "best_rank", p_rank)
		cfg.set_value(section, "best_score", p_score)
		cfg.set_value(section, "best_accuracy", p_accuracy)

	var summary_section: String = build_summary_key(normalized_key)
	var has_summary: bool = cfg.has_section(summary_section)
	var prev_sum_score: int = int(cfg.get_value(summary_section, "best_score", -1))
	var prev_sum_acc: float = float(cfg.get_value(summary_section, "best_accuracy", -1.0))
	var is_summary_better: bool = (
		(not has_summary)
		or (p_score > prev_sum_score)
		or (p_score == prev_sum_score and p_accuracy > prev_sum_acc)
	)

	cfg.set_value(summary_section, "song_key", normalized_key)
	cfg.set_value(summary_section, "last_rank", p_rank)
	cfg.set_value(summary_section, "last_difficulty", p_difficulty)
	cfg.set_value(summary_section, "last_score", p_score)
	cfg.set_value(summary_section, "last_accuracy", p_accuracy)
	if is_summary_better:
		cfg.set_value(summary_section, "best_rank", p_rank)
		cfg.set_value(summary_section, "best_difficulty", p_difficulty)
		cfg.set_value(summary_section, "best_score", p_score)
		cfg.set_value(summary_section, "best_accuracy", p_accuracy)

	var parent_dir: String = records_file_path.get_base_dir()
	if not parent_dir.is_empty() and parent_dir != "user://":
		DirAccess.make_dir_recursive_absolute(parent_dir)

	var save_ok: bool = cfg.save(records_file_path) == OK
	return save_ok and is_better


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
