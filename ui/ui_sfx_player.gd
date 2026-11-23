class_name UiSfxPlayer
extends Node

signal fullscreen_mode_changed(p_is_fullscreen: bool)

const DEFAULT_SFX_DIR: String = "res://assets/sfx"
const BUTTON_CLICK_STEM: String = "button_click"
const CASSETTE_INSERT_STEM: String = "cassette_insert"
const CASSETTE_FALLBACK_PREFIX: String = "cassette"
const SUPPORTED_EXTENSIONS: PackedStringArray = ["ogg", "wav", "mp3"]
const DEFAULT_AUDIO_BUS: StringName = &"Master"
const DEFAULT_VOLUME_DB: float = 0.0
const DEFAULT_TRANSITION_DURATION_SEC: float = 2.5
const ROOT_CLICK_PLAYER_NAME: StringName = &"PersistentUiClickPlayer"
const META_CLICK_WIRED: StringName = &"ui_click_wired"
const META_CLICK_EXCLUDED: StringName = &"ui_click_excluded"

static var _touch_scroll_suppressed: bool = false
static var _desktop_platform_override: int = -1
static var _desktop_fullscreen_state: bool = false

@export var sfx_dir_path: String = DEFAULT_SFX_DIR
@export var auto_wire_scene_tree: bool = false

var _click_player: AudioStreamPlayer = null
var _cassette_player: AudioStreamPlayer = null
var _button_click_stream: AudioStream = null
var _cassette_insert_stream: AudioStream = null
var _global_wiring_active: bool = false
var _click_play_count: int = 0


static func set_touch_scroll_suppressed(p_suppressed: bool) -> void:
	_touch_scroll_suppressed = p_suppressed


static func is_touch_scroll_suppressed() -> bool:
	return _touch_scroll_suppressed


static func mark_button_excluded(p_button: BaseButton) -> void:
	if p_button == null:
		return
	p_button.set_meta(META_CLICK_EXCLUDED, true)


static func set_desktop_platform_override_for_tests(p_override: int) -> void:
	_desktop_platform_override = clampi(p_override, -1, 1)


static func is_desktop_platform() -> bool:
	if _desktop_platform_override == 0:
		return false
	if _desktop_platform_override == 1:
		return true
	var os_name: String = OS.get_name()
	if os_name == "Android" or os_name == "iOS":
		return false
	return os_name == "Windows" or OS.has_feature("pc")


func is_desktop_fullscreen() -> bool:
	if not is_desktop_platform():
		return false
	if DisplayServer.get_name() != "headless":
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		_desktop_fullscreen_state = (
			mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)
	return _desktop_fullscreen_state


func set_desktop_fullscreen(p_enabled: bool) -> void:
	if not is_desktop_platform():
		return
	var target_mode: DisplayServer.WindowMode = (
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if p_enabled
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(target_mode)
	_desktop_fullscreen_state = p_enabled
	fullscreen_mode_changed.emit(_desktop_fullscreen_state)


func toggle_desktop_fullscreen() -> void:
	if not is_desktop_platform():
		return
	set_desktop_fullscreen(not is_desktop_fullscreen())


func _is_desktop_shortcut_owner() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return true
	var global_node: Node = tree.root.get_node_or_null(^"GlobalUiSfx")
	if global_node != null:
		return global_node == self
	return true


func _input(p_event: InputEvent) -> void:
	if not is_desktop_platform() or not _is_desktop_shortcut_owner():
		return
	if not (p_event is InputEventKey):
		return
	var key_event: InputEventKey = p_event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var code: Key = key_event.keycode if key_event.keycode != KEY_NONE else key_event.physical_keycode
	var is_f11: bool = (
		code == KEY_F11
		and not key_event.ctrl_pressed
		and not key_event.alt_pressed
		and not key_event.meta_pressed
	)
	var is_alt_enter: bool = (
		(code == KEY_ENTER or code == KEY_KP_ENTER)
		and key_event.alt_pressed
		and not key_event.ctrl_pressed
		and not key_event.meta_pressed
	)
	if is_f11 or is_alt_enter:
		toggle_desktop_fullscreen()
		var vp: Viewport = get_viewport()
		if vp != null:
			vp.set_input_as_handled()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_desktop_platform() and DisplayServer.get_name() != "headless":
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		_desktop_fullscreen_state = (
			mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)
	_ensure_players()
	reload_sfx()
	var tree: SceneTree = get_tree()
	var is_autoload_root_child: bool = tree != null and get_parent() == tree.root and name == &"GlobalUiSfx"
	if auto_wire_scene_tree or is_autoload_root_child:
		enable_global_button_wiring()


func _exit_tree() -> void:
	if _global_wiring_active:
		var tree: SceneTree = get_tree()
		if tree != null and tree.node_added.is_connected(_on_tree_node_added):
			tree.node_added.disconnect(_on_tree_node_added)
		_global_wiring_active = false


func enable_global_button_wiring() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if not _global_wiring_active:
		_global_wiring_active = true
		if not tree.node_added.is_connected(_on_tree_node_added):
			tree.node_added.connect(_on_tree_node_added)
	if tree.root != null:
		bind_buttons_in_tree(tree.root)


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
	_click_play_count += 1
	if _button_click_stream == null or _click_player == null:
		return
	var bus_idx: int = AudioServer.get_bus_index(DEFAULT_AUDIO_BUS)
	if bus_idx >= 0 and AudioServer.is_bus_mute(bus_idx):
		return
	_click_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_click_player.bus = DEFAULT_AUDIO_BUS
	_click_player.volume_db = DEFAULT_VOLUME_DB
	_click_player.stream = _button_click_stream
	_click_player.play(0.0)


func get_persistent_click_player() -> AudioStreamPlayer:
	_ensure_players()
	return _click_player


func is_click_playing() -> bool:
	return _click_player != null and is_instance_valid(_click_player) and _click_player.playing


func get_click_play_count() -> int:
	return _click_play_count


func reset_click_play_count() -> void:
	_click_play_count = 0


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
	if p_button.has_meta(META_CLICK_EXCLUDED) and bool(p_button.get_meta(META_CLICK_EXCLUDED)):
		return
	if p_button.has_meta(META_CLICK_WIRED) and bool(p_button.get_meta(META_CLICK_WIRED)):
		return
	p_button.set_meta(META_CLICK_WIRED, true)
	var cb: Callable = _on_wired_button_pressed.bind(p_button)
	if not p_button.pressed.is_connected(cb):
		p_button.pressed.connect(cb)


func bind_buttons_in_tree(p_root: Node, p_excluded_buttons: Array[BaseButton] = []) -> void:
	if p_root == null:
		return

	if p_root is BaseButton:
		var btn: BaseButton = p_root as BaseButton
		if p_excluded_buttons.has(btn):
			mark_button_excluded(btn)
		else:
			bind_button(btn)

	var children: Array[Node] = p_root.get_children()
	var child_count: int = children.size()
	for i: int in range(child_count):
		bind_buttons_in_tree(children[i], p_excluded_buttons)


func _on_tree_node_added(p_node: Node) -> void:
	if p_node is BaseButton:
		bind_button(p_node as BaseButton)


func _on_wired_button_pressed(p_button: BaseButton) -> void:
	if not is_instance_valid(p_button):
		return
	if p_button.has_meta(META_CLICK_EXCLUDED) and bool(p_button.get_meta(META_CLICK_EXCLUDED)):
		return
	if _touch_scroll_suppressed and _is_inside_scroll_container(p_button):
		return
	play_button_click()


func _is_inside_scroll_container(p_node: Node) -> bool:
	var cur: Node = p_node.get_parent()
	while cur != null:
		if cur is ScrollContainer:
			return true
		cur = cur.get_parent()
	return false


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
	var tree: SceneTree = get_tree()
	var root_window: Window = tree.root if tree != null else null

	if _click_player == null or not is_instance_valid(_click_player):
		_click_player = null
		if root_window != null:
			_click_player = root_window.get_node_or_null(NodePath(String(ROOT_CLICK_PLAYER_NAME))) as AudioStreamPlayer

		if _click_player == null:
			_click_player = AudioStreamPlayer.new()
			_click_player.name = ROOT_CLICK_PLAYER_NAME
			_click_player.process_mode = Node.PROCESS_MODE_ALWAYS
			_click_player.bus = DEFAULT_AUDIO_BUS
			_click_player.volume_db = DEFAULT_VOLUME_DB
			if root_window != null:
				if root_window.is_node_ready():
					root_window.add_child(_click_player)
				else:
					add_child(_click_player)
					call_deferred(&"_reparent_click_player_to_root")
			else:
				add_child(_click_player)
	else:
		_click_player.process_mode = Node.PROCESS_MODE_ALWAYS
		if root_window != null and _click_player.get_parent() != root_window:
			if root_window.is_node_ready():
				_reparent_click_player_to_root()
			else:
				call_deferred(&"_reparent_click_player_to_root")

	if _cassette_player == null or not is_instance_valid(_cassette_player):
		_cassette_player = AudioStreamPlayer.new()
		_cassette_player.name = "UiCassettePlayer"
		_cassette_player.process_mode = Node.PROCESS_MODE_ALWAYS
		_cassette_player.bus = DEFAULT_AUDIO_BUS
		_cassette_player.volume_db = DEFAULT_VOLUME_DB
		add_child(_cassette_player)


func _reparent_click_player_to_root() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return
	var existing_root_player: AudioStreamPlayer = tree.root.get_node_or_null(NodePath(String(ROOT_CLICK_PLAYER_NAME))) as AudioStreamPlayer
	if existing_root_player != null:
		if _click_player != null and is_instance_valid(_click_player) and _click_player != existing_root_player:
			var old_player: AudioStreamPlayer = _click_player
			if old_player.get_parent() != null:
				old_player.get_parent().remove_child(old_player)
			old_player.queue_free()
		_click_player = existing_root_player
		_click_player.process_mode = Node.PROCESS_MODE_ALWAYS
		if _button_click_stream != null and _click_player.stream == null:
			_click_player.stream = _button_click_stream
		return

	if _click_player == null or not is_instance_valid(_click_player):
		return
	_click_player.process_mode = Node.PROCESS_MODE_ALWAYS
	var cur_parent: Node = _click_player.get_parent()
	if cur_parent == tree.root:
		return
	if cur_parent != null:
		cur_parent.remove_child(_click_player)
	tree.root.add_child(_click_player)


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
