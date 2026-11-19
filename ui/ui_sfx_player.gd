class_name UiSfxPlayer
extends Node

const DEFAULT_SFX_DIR: String = "res://assets/sfx"
const BUTTON_CLICK_STEM: String = "button_click"
const CASSETTE_INSERT_STEM: String = "cassette_insert"
const SUPPORTED_EXTENSIONS: PackedStringArray = ["ogg", "wav", "mp3"]
const MAX_TRANSITION_DELAY_SEC: float = 0.45

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
	_button_click_stream = _find_and_load_sfx(BUTTON_CLICK_STEM)
	_cassette_insert_stream = _find_and_load_sfx(CASSETTE_INSERT_STEM)
	if _click_player != null:
		_click_player.stream = _button_click_stream
	if _cassette_player != null:
		_cassette_player.stream = _cassette_insert_stream


func play_button_click() -> void:
	_ensure_players()
	if _button_click_stream == null or _click_player == null:
		return
	_click_player.stream = _button_click_stream
	_click_player.play()


func play_cassette_insert() -> void:
	_ensure_players()
	if _cassette_insert_stream == null or _cassette_player == null:
		return
	_cassette_player.stream = _cassette_insert_stream
	_cassette_player.play()


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


func get_cassette_transition_delay_sec() -> float:
	if _cassette_insert_stream == null:
		return 0.0
	var length_sec: float = maxf(0.0, _cassette_insert_stream.get_length())
	if length_sec <= 0.0:
		return 0.12
	return minf(length_sec, MAX_TRANSITION_DELAY_SEC)


func _ensure_players() -> void:
	if _click_player == null:
		_click_player = AudioStreamPlayer.new()
		_click_player.name = "UiClickPlayer"
		add_child(_click_player)

	if _cassette_player == null:
		_cassette_player = AudioStreamPlayer.new()
		_cassette_player.name = "UiCassettePlayer"
		add_child(_cassette_player)


func _find_and_load_sfx(p_stem: String) -> AudioStream:
	var base_dir: String = sfx_dir_path.trim_suffix("/")
	var ext_count: int = SUPPORTED_EXTENSIONS.size()
	for i: int in range(ext_count):
		var ext: String = SUPPORTED_EXTENSIONS[i]
		var candidate_path: String = "%s/%s.%s" % [base_dir, p_stem, ext]
		var stream: AudioStream = _load_external_audio(candidate_path)
		if stream != null:
			return stream
	return null


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
