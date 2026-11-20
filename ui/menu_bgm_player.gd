class_name MenuBgmPlayer
extends Node

signal track_changed(p_track_index: int, p_track_name: String)
signal bgm_enabled_changed(p_enabled: bool)

const DEFAULT_BGM_DIR: String = "res://assets/bgm"
const DEFAULT_SETTINGS_PATH: String = "user://user_settings.cfg"
const SETTINGS_SECTION: String = "menu_bgm"
const EMPTY_TRACK_LABEL: String = "Sin BGM"
const SUPPORTED_EXTENSIONS: PackedStringArray = ["ogg", "mp3", "wav"]

@export var bgm_dir_path: String = DEFAULT_BGM_DIR
@export var settings_file_path: String = DEFAULT_SETTINGS_PATH
@export var is_bgm_enabled: bool = true
@export var is_auto_rotate: bool = true
@export var auto_start_on_ready: bool = true

var _player: AudioStreamPlayer = null
var _track_paths: PackedStringArray = PackedStringArray()
var _current_index: int = -1
var _preferred_track_name: String = ""
var _is_stopped_manually: bool = false


func _ready() -> void:
	_ensure_player()
	scan_tracks()
	load_settings()
	_resolve_initial_track_index()

	if auto_start_on_ready and is_bgm_enabled and not _track_paths.is_empty():
		select_track(maxi(0, _current_index), false)
	elif not _track_paths.is_empty():
		track_changed.emit(_current_index, get_current_track_name())


func _exit_tree() -> void:
	stop_bgm()
	if _player != null:
		_player.stream = null


func load_settings() -> void:
	if settings_file_path.is_empty() or not FileAccess.file_exists(settings_file_path):
		return

	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(settings_file_path) != OK:
		return

	is_bgm_enabled = bool(cfg.get_value(SETTINGS_SECTION, "bgm_enabled", is_bgm_enabled))
	is_auto_rotate = bool(cfg.get_value(SETTINGS_SECTION, "auto_rotate", is_auto_rotate))
	_preferred_track_name = str(cfg.get_value(SETTINGS_SECTION, "selected_track_name", ""))


func save_settings() -> bool:
	if settings_file_path.is_empty():
		return false

	var cfg: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(settings_file_path):
		var load_err: Error = cfg.load(settings_file_path)
		if load_err != OK:
			cfg = ConfigFile.new()

	var selected_name: String = _preferred_track_name
	if _current_index >= 0 and _current_index < _track_paths.size():
		selected_name = get_current_track_name()

	cfg.set_value(SETTINGS_SECTION, "bgm_enabled", is_bgm_enabled)
	cfg.set_value(SETTINGS_SECTION, "auto_rotate", is_auto_rotate)
	cfg.set_value(SETTINGS_SECTION, "selected_track_name", selected_name)

	var parent_dir: String = settings_file_path.get_base_dir()
	if not parent_dir.is_empty() and parent_dir != "user://":
		DirAccess.make_dir_recursive_absolute(parent_dir)

	return cfg.save(settings_file_path) == OK


func scan_tracks() -> PackedStringArray:
	var discovered: Array[String] = []
	var seen: Dictionary = {}
	var dir: DirAccess = DirAccess.open(bgm_dir_path)
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

				var ext: String = cleaned.get_extension().to_lower()
				if SUPPORTED_EXTENSIONS.has(ext):
					var full_path: String = "%s/%s" % [bgm_dir_path.trim_suffix("/"), cleaned]
					if not seen.has(full_path):
						seen[full_path] = true
						discovered.append(full_path)
			entry = dir.get_next()
		dir.list_dir_end()

	discovered.sort()
	_track_paths = PackedStringArray(discovered)
	if _track_paths.is_empty():
		_current_index = -1
	elif _current_index >= _track_paths.size():
		_current_index = 0
	return _track_paths


func set_bgm_enabled(p_enabled: bool) -> void:
	is_bgm_enabled = p_enabled
	save_settings()
	if is_bgm_enabled:
		_is_stopped_manually = false
		if not _track_paths.is_empty():
			var target_idx: int = _current_index if _current_index >= 0 else 0
			select_track(target_idx, false)
	else:
		stop_bgm()
	bgm_enabled_changed.emit(is_bgm_enabled)


func select_track(p_index: int, p_persist: bool = true) -> bool:
	_ensure_player()
	if _track_paths.is_empty():
		_current_index = -1
		track_changed.emit(-1, EMPTY_TRACK_LABEL)
		return false

	var wrapped_index: int = posmod(p_index, _track_paths.size())
	_current_index = wrapped_index
	_preferred_track_name = get_current_track_name()
	if p_persist:
		save_settings()

	if not is_bgm_enabled:
		if _player.playing:
			_player.stop()
		track_changed.emit(_current_index, get_current_track_name())
		return true

	var track_path: String = _track_paths[wrapped_index]
	var stream: AudioStream = _load_external_audio(track_path)
	if stream == null:
		return false

	_is_stopped_manually = false
	_player.stream = stream
	_player.play()
	track_changed.emit(_current_index, get_current_track_name())
	return true


func next_track() -> bool:
	if _track_paths.is_empty():
		return false
	var target: int = 0 if _current_index < 0 else (_current_index + 1) % _track_paths.size()
	return select_track(target, true)


func prev_track() -> bool:
	if _track_paths.is_empty():
		return false
	var target: int = _track_paths.size() - 1 if _current_index < 0 else posmod(_current_index - 1, _track_paths.size())
	return select_track(target, true)


func set_auto_rotate(p_enabled: bool) -> void:
	is_auto_rotate = p_enabled
	save_settings()


func stop_bgm() -> void:
	_is_stopped_manually = true
	if _player != null and _player.playing:
		_player.stop()


func get_track_count() -> int:
	return _track_paths.size()


func get_current_track_index() -> int:
	return _current_index


func get_current_track_name() -> String:
	if _current_index < 0 or _current_index >= _track_paths.size():
		return EMPTY_TRACK_LABEL
	return _track_paths[_current_index].get_file().get_basename()


func get_track_paths() -> PackedStringArray:
	return _track_paths


func is_playing() -> bool:
	return _player != null and _player.playing


func _resolve_initial_track_index() -> void:
	if _track_paths.is_empty():
		_current_index = -1
		return

	if not _preferred_track_name.is_empty():
		var count: int = _track_paths.size()
		for i: int in range(count):
			var base_name: String = _track_paths[i].get_file().get_basename()
			if base_name == _preferred_track_name:
				_current_index = i
				return

	_current_index = 0


func _ensure_player() -> void:
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "MenuBgmAudioPlayer"
		_player.bus = &"Master"
		add_child(_player)

	if not _player.finished.is_connected(_on_player_finished):
		_player.finished.connect(_on_player_finished)


func _on_player_finished() -> void:
	if _is_stopped_manually or not is_bgm_enabled or _track_paths.is_empty():
		return

	if is_auto_rotate:
		next_track()
	elif _current_index >= 0 and _current_index < _track_paths.size():
		select_track(_current_index, false)


func _load_external_audio(p_path: String) -> AudioStream:
	if p_path.is_empty():
		return null

	if p_path.begins_with("res://") and ResourceLoader.exists(p_path):
		var res: Resource = ResourceLoader.load(p_path)
		if res is AudioStream:
			return res as AudioStream

	if not FileAccess.file_exists(p_path):
		return null

	var ext: String = p_path.get_extension().to_lower()
	match ext:
		"ogg":
			return AudioStreamOggVorbis.load_from_file(p_path)
		"mp3":
			return AudioStreamMP3.load_from_file(p_path)
		"wav":
			return AudioStreamWAV.load_from_file(p_path)
		_:
			return null
