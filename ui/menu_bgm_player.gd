class_name MenuBgmPlayer
extends Node

signal track_changed(p_track_index: int, p_track_name: String)

const DEFAULT_BGM_DIR: String = "res://assets/bgm"
const EMPTY_TRACK_LABEL: String = "Sin BGM"
const SUPPORTED_EXTENSIONS: PackedStringArray = ["ogg", "mp3", "wav"]

@export var bgm_dir_path: String = DEFAULT_BGM_DIR
@export var is_auto_rotate: bool = true
@export var auto_start_on_ready: bool = true

var _player: AudioStreamPlayer = null
var _track_paths: PackedStringArray = PackedStringArray()
var _current_index: int = -1
var _is_stopped_manually: bool = false


func _ready() -> void:
	_ensure_player()
	scan_tracks()
	if auto_start_on_ready and not _track_paths.is_empty():
		select_track(0)


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


func select_track(p_index: int) -> bool:
	_ensure_player()
	if _track_paths.is_empty():
		_current_index = -1
		track_changed.emit(-1, EMPTY_TRACK_LABEL)
		return false

	var wrapped_index: int = posmod(p_index, _track_paths.size())
	var track_path: String = _track_paths[wrapped_index]
	var stream: AudioStream = _load_external_audio(track_path)
	if stream == null:
		return false

	_is_stopped_manually = false
	_current_index = wrapped_index
	_player.stream = stream
	_player.play()
	track_changed.emit(_current_index, get_current_track_name())
	return true


func next_track() -> bool:
	if _track_paths.is_empty():
		return false
	var target: int = 0 if _current_index < 0 else (_current_index + 1) % _track_paths.size()
	return select_track(target)


func prev_track() -> bool:
	if _track_paths.is_empty():
		return false
	var target: int = _track_paths.size() - 1 if _current_index < 0 else posmod(_current_index - 1, _track_paths.size())
	return select_track(target)


func set_auto_rotate(p_enabled: bool) -> void:
	is_auto_rotate = p_enabled


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


func _ensure_player() -> void:
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "MenuBgmAudioPlayer"
		add_child(_player)

	if not _player.finished.is_connected(_on_player_finished):
		_player.finished.connect(_on_player_finished)


func _on_player_finished() -> void:
	if _is_stopped_manually or _track_paths.is_empty():
		return

	if is_auto_rotate:
		next_track()
	elif _current_index >= 0 and _current_index < _track_paths.size():
		select_track(_current_index)


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
