class_name UiSfxPlayer
extends Node

const DEFAULT_SFX_DIR: String = "res://assets/sfx"
const BUTTON_CLICK_STEM: String = "button_click"
const CASSETTE_INSERT_STEM: String = "cassette_insert"
const CASSETTE_FALLBACK_PREFIX: String = "cassette"
const SUPPORTED_EXTENSIONS: PackedStringArray = ["ogg", "wav", "mp3"]
const DEFAULT_AUDIO_BUS: StringName = &"Master"
const DEFAULT_VOLUME_DB: float = 0.0
const DEFAULT_TRANSITION_DURATION_SEC: float = 2.5

@export var sfx_dir_path: String = DEFAULT_SFX_DIR

var _click_player: AudioStreamPlayer = null
var _cassette_player: AudioStreamPlayer = null
var _button_click_stream: AudioStream = null
var _cassette_insert_stream: AudioStream = null


func _ready() -> void:
	_ensure_players()
	reload_sfx()


func reload_sfx() -> void:
	_ensure_players()
	_button_click_stream = _find_and_load_sfx(BUTTON_CLICK_STEM, "")
	_cassette_insert_stream = _find_and_load_sfx(CASSETTE_INSERT_STEM, CASSETTE_FALLBACK_PREFIX)
	if _click_player != null:
		_click_player.stream = _button_click_stream
	if _cassette_player != null:
		_cassette_player.stream = _cassette_insert_stream


func play_button_click() -> void:
	_ensure_players()
	if _button_click_stream == null or _click_player == null:
		return
	_click_player.bus = DEFAULT_AUDIO_BUS
	_click_player.volume_db = DEFAULT_VOLUME_DB
	_click_player.stream = _button_click_stream
	_click_player.play()


func play_cassette_insert() -> void:
	_ensure_players()
	if _cassette_insert_stream == null or _cassette_player == null:
		return
	_cassette_player.bus = DEFAULT_AUDIO_BUS
	_cassette_player.volume_db = DEFAULT_VOLUME_DB
	_cassette_player.stream = _cassette_insert_stream
	_cassette_player.play(0.0)


func bind_button(p_button: BaseButton) -> void:
	if p_button == null:
		return
	if not p_button.pressed.is_connected(play_button_click):
		p_button.pressed.connect(play_button_click)


func bind_buttons_in_tree(p_root: Node, p_excluded_buttons: Array[BaseButton] = []) -> void:
	if p_root == null:
		return

	if p_root is BaseButton:
		var btn: BaseButton = p_root as BaseButton
		if not p_excluded_buttons.has(btn):
			bind_button(btn)

	var children: Array[Node] = p_root.get_children()
	var child_count: int = children.size()
	for i: int in range(child_count):
		bind_buttons_in_tree(children[i], p_excluded_buttons)


func has_button_click() -> bool:
	return _button_click_stream != null


func has_cassette_insert() -> bool:
	return _cassette_insert_stream != null


func is_cassette_playing() -> bool:
	return _cassette_player != null and _cassette_player.playing


func get_cassette_bus() -> StringName:
	_ensure_players()
	return _cassette_player.bus


func get_cassette_volume_db() -> float:
	_ensure_players()
	return _cassette_player.volume_db


func get_cassette_transition_delay_sec() -> float:
	if _cassette_insert_stream == null:
		return DEFAULT_TRANSITION_DURATION_SEC
	var length_sec: float = maxf(0.0, _cassette_insert_stream.get_length())
	return maxf(DEFAULT_TRANSITION_DURATION_SEC, length_sec)


func _ensure_players() -> void:
	if _click_player == null:
		_click_player = AudioStreamPlayer.new()
		_click_player.name = "UiClickPlayer"
		_click_player.bus = DEFAULT_AUDIO_BUS
		_click_player.volume_db = DEFAULT_VOLUME_DB
		add_child(_click_player)

	if _cassette_player == null:
		_cassette_player = AudioStreamPlayer.new()
		_cassette_player.name = "UiCassettePlayer"
		_cassette_player.bus = DEFAULT_AUDIO_BUS
		_cassette_player.volume_db = DEFAULT_VOLUME_DB
		add_child(_cassette_player)


func _find_and_load_sfx(p_exact_stem: String, p_prefix_fallback: String) -> AudioStream:
	var base_dir: String = sfx_dir_path.trim_suffix("/")
	var exact_lower: String = p_exact_stem.to_lower()
	var prefix_lower: String = p_prefix_fallback.to_lower()

	var exact_candidates: Array[String] = []
	var prefix_candidates: Array[String] = []
	var seen_paths: Dictionary = {}

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
					var full_path: String = "%s/%s" % [base_dir, cleaned]
					if not seen_paths.has(full_path):
						seen_paths[full_path] = true
						var stem_lower: String = cleaned.get_basename().to_lower()
						if stem_lower == exact_lower:
							exact_candidates.append(full_path)
						elif not prefix_lower.is_empty() and stem_lower.begins_with(prefix_lower):
							prefix_candidates.append(full_path)
			entry = dir.get_next()
		dir.list_dir_end()

	exact_candidates.sort_custom(_compare_by_extension_priority)
	for i: int in range(exact_candidates.size()):
		var exact_stream: AudioStream = _load_external_audio(exact_candidates[i])
		if exact_stream != null:
			return exact_stream

	var ext_count: int = SUPPORTED_EXTENSIONS.size()
	for j: int in range(ext_count):
		var ext: String = SUPPORTED_EXTENSIONS[j]
		var direct_path: String = "%s/%s.%s" % [base_dir, p_exact_stem, ext]
		var direct_stream: AudioStream = _load_external_audio(direct_path)
		if direct_stream != null:
			return direct_stream

	if not prefix_lower.is_empty():
		prefix_candidates.sort_custom(_compare_by_extension_priority)
		for k: int in range(prefix_candidates.size()):
			var fallback_stream: AudioStream = _load_external_audio(prefix_candidates[k])
			if fallback_stream != null:
				return fallback_stream

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
		"wav":
			return AudioStreamWAV.load_from_file(p_path)
		"mp3":
			return AudioStreamMP3.load_from_file(p_path)
		_:
			return null
