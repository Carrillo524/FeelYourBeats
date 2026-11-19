class_name DSPClock
extends Node

signal dsp_time_updated(current_time_sec: float)
signal visual_time_updated(visual_time_sec: float)
signal beat_pulsed(beat_index: int, beat_time_sec: float)
signal intensity_changed(block: IntensityBlock)
signal playback_finished()

const USEC_TO_SEC: float = 0.000001
const SECONDS_PER_MINUTE: float = 60.0
const VISUAL_PHASE_LOCK_TOLERANCE_SEC: float = 0.006
const VISUAL_SOFT_CORRECTION_RATE: float = 8.0
const VISUAL_HARD_CORRECTION_RATE: float = 20.0
const VISUAL_SNAP_THRESHOLD_SEC: float = 0.045
const MAX_VISUAL_FRAME_DELTA_SEC: float = 0.05

@export var audio_player: AudioStreamPlayer = null
@export var user_offset_sec: float = 0.0
@export var default_lead_in_sec: float = 2.0

var current_dsp_time_sec: float = 0.0
var _visual_time_sec: float = 0.0
var _visual_time_initialized: bool = false

var _chart: ChartData = null
var _is_running: bool = false
var _is_paused: bool = false
var _in_lead_in: bool = false
var _last_tick_usec: int = 0
var _last_emitted_beat_index: int = -1
var _current_block_index: int = 0
var _active_intensity_block: IntensityBlock = null


func _ready() -> void:
	_ensure_audio_player()


func load_chart(p_chart: ChartData) -> bool:
	if p_chart == null:
		return false

	var validation: Dictionary = p_chart.validate()
	var is_valid: bool = validation.get("valid", false) as bool
	if not is_valid:
		return false

	stop()
	_ensure_audio_player()
	_chart = p_chart

	if _chart.audio_path != "" and ResourceLoader.exists(_chart.audio_path):
		var loaded_resource: Resource = ResourceLoader.load(_chart.audio_path)
		if loaded_resource is AudioStream:
			audio_player.stream = loaded_resource as AudioStream

	return true


func start(p_lead_in_sec: float = -1.0) -> void:
	if _chart == null:
		return

	_ensure_audio_player()

	var effective_lead_in: float = default_lead_in_sec if p_lead_in_sec < 0.0 else p_lead_in_sec
	_last_emitted_beat_index = -1
	_current_block_index = 0
	_active_intensity_block = null
	_is_running = true
	_is_paused = false
	_last_tick_usec = Time.get_ticks_usec()
	current_dsp_time_sec = -effective_lead_in
	_visual_time_sec = current_dsp_time_sec
	_visual_time_initialized = true

	var trigger_time_sec: float = _get_pre_trigger_time_sec()
	if current_dsp_time_sec >= trigger_time_sec:
		_in_lead_in = false
		_trigger_audio_playback(current_dsp_time_sec)
	else:
		_in_lead_in = true
		if audio_player != null and audio_player.playing:
			audio_player.stop()


func pause() -> void:
	if not _is_running or _is_paused:
		return

	_is_paused = true
	if audio_player != null and audio_player.playing:
		audio_player.stream_paused = true


func resume() -> void:
	if not _is_running or not _is_paused:
		return

	_is_paused = false
	_last_tick_usec = Time.get_ticks_usec()
	_visual_time_sec = current_dsp_time_sec
	_visual_time_initialized = true
	if not _in_lead_in and audio_player != null and audio_player.stream != null:
		audio_player.stream_paused = false


func stop() -> void:
	_is_running = false
	_is_paused = false
	_in_lead_in = false
	current_dsp_time_sec = 0.0
	_visual_time_sec = 0.0
	_visual_time_initialized = false
	_last_emitted_beat_index = -1
	_current_block_index = 0
	_active_intensity_block = null

	if audio_player != null:
		audio_player.stream_paused = false
		if audio_player.playing:
			audio_player.stop()


func seek(p_time_sec: float) -> void:
	if _chart == null:
		return

	_ensure_audio_player()
	var max_seek_sec: float = maxf(0.0, _chart.duration_sec)
	var clamped_time_sec: float = clampf(p_time_sec, -default_lead_in_sec, max_seek_sec)
	current_dsp_time_sec = clamped_time_sec
	_visual_time_sec = clamped_time_sec
	_visual_time_initialized = true
	_last_tick_usec = Time.get_ticks_usec()

	if _chart.bpm_estimate > 0.0 and clamped_time_sec >= 0.0:
		var beat_period_sec: float = SECONDS_PER_MINUTE / _chart.bpm_estimate
		_last_emitted_beat_index = int(floor(clamped_time_sec / beat_period_sec)) - 1
	else:
		_last_emitted_beat_index = -1

	_current_block_index = 0
	_active_intensity_block = null
	var blocks: Array[IntensityBlock] = _chart.intensity_blocks
	var block_count: int = blocks.size()
	if clamped_time_sec >= 0.0:
		while _current_block_index < block_count and clamped_time_sec >= blocks[_current_block_index].end_sec:
			_current_block_index += 1

	var trigger_time_sec: float = _get_pre_trigger_time_sec()
	if current_dsp_time_sec < trigger_time_sec:
		_in_lead_in = true
		if audio_player != null and audio_player.playing:
			audio_player.stop()
	else:
		_in_lead_in = false
		if _is_running:
			_trigger_audio_playback(current_dsp_time_sec)
			if _is_paused and audio_player != null:
				audio_player.stream_paused = true

	_evaluate_intensity_blocks()


func get_current_dsp_time() -> float:
	return current_dsp_time_sec


func get_visual_time_sec() -> float:
	return _visual_time_sec


func step_visual_clock_for_test(p_delta: float, p_target_dsp_time_sec: float) -> float:
	_advance_visual_clock(p_delta, p_target_dsp_time_sec)
	return _visual_time_sec


func is_playing() -> bool:
	return _is_running and not _is_paused


func _process(p_delta: float) -> void:
	if not _is_running or _is_paused or _chart == null:
		return

	var now_usec: int = Time.get_ticks_usec()
	var elapsed_sec: float = maxf(0.0, float(now_usec - _last_tick_usec) * USEC_TO_SEC)
	_last_tick_usec = now_usec

	if _in_lead_in:
		current_dsp_time_sec += elapsed_sec
		var trigger_time_sec: float = _get_pre_trigger_time_sec()
		if current_dsp_time_sec >= trigger_time_sec:
			_in_lead_in = false
			_trigger_audio_playback(current_dsp_time_sec)
	else:
		if audio_player != null and audio_player.stream != null and audio_player.playing:
			var since_last_mix_sec: float = maxf(0.0, AudioServer.get_time_since_last_mix())
			var raw_time: float = (
				audio_player.get_playback_position()
				+ since_last_mix_sec
				- AudioServer.get_output_latency()
				- _chart.offset_sec
				- user_offset_sec
			)
			current_dsp_time_sec = maxf(current_dsp_time_sec, raw_time)
		else:
			current_dsp_time_sec += elapsed_sec

		if _chart.duration_sec > 0.0 and current_dsp_time_sec >= _chart.duration_sec:
			_finalize_playback()
			return

	var visual_dt: float = p_delta if p_delta > 0.0 else elapsed_sec
	_advance_visual_clock(visual_dt, current_dsp_time_sec)

	dsp_time_updated.emit(current_dsp_time_sec)
	visual_time_updated.emit(_visual_time_sec)
	_evaluate_beats()
	_evaluate_intensity_blocks()


func _advance_visual_clock(p_delta: float, p_target_dsp_time_sec: float) -> void:
	var dt: float = clampf(p_delta, 0.0, MAX_VISUAL_FRAME_DELTA_SEC)
	if not _visual_time_initialized:
		_visual_time_sec = p_target_dsp_time_sec
		_visual_time_initialized = true
		return

	var predicted_sec: float = _visual_time_sec + dt
	var phase_error_sec: float = p_target_dsp_time_sec - predicted_sec
	var abs_error_sec: float = absf(phase_error_sec)

	if abs_error_sec >= VISUAL_SNAP_THRESHOLD_SEC:
		_visual_time_sec = p_target_dsp_time_sec
	elif abs_error_sec <= VISUAL_PHASE_LOCK_TOLERANCE_SEC:
		var soft_alpha: float = clampf(VISUAL_SOFT_CORRECTION_RATE * dt, 0.0, 1.0)
		_visual_time_sec = lerpf(predicted_sec, p_target_dsp_time_sec, soft_alpha)
	else:
		var pull_alpha: float = clampf(VISUAL_HARD_CORRECTION_RATE * dt, 0.0, 1.0)
		_visual_time_sec = lerpf(predicted_sec, p_target_dsp_time_sec, pull_alpha)


func _ensure_audio_player() -> void:
	if audio_player == null:
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "InternalAudioStreamPlayer"
		add_child(audio_player)

	if not audio_player.finished.is_connected(_on_audio_player_finished):
		audio_player.finished.connect(_on_audio_player_finished)


func _get_total_offset_sec() -> float:
	var chart_offset: float = _chart.offset_sec if _chart != null else 0.0
	return AudioServer.get_output_latency() + chart_offset + user_offset_sec


func _get_pre_trigger_time_sec() -> float:
	return -maxf(0.0, _get_total_offset_sec())


func _trigger_audio_playback(p_target_dsp_time_sec: float) -> void:
	if audio_player == null or audio_player.stream == null:
		return

	var stream_pos: float = maxf(0.0, p_target_dsp_time_sec + _get_total_offset_sec())
	audio_player.stream_paused = false
	audio_player.play(stream_pos)


func _evaluate_beats() -> void:
	if _chart == null or _chart.bpm_estimate <= 0.0:
		return
	if current_dsp_time_sec < 0.0:
		return

	var beat_period_sec: float = SECONDS_PER_MINUTE / _chart.bpm_estimate
	var target_beat_index: int = int(floor(current_dsp_time_sec / beat_period_sec))
	while _last_emitted_beat_index < target_beat_index:
		_last_emitted_beat_index += 1
		var beat_time_sec: float = float(_last_emitted_beat_index) * beat_period_sec
		beat_pulsed.emit(_last_emitted_beat_index, beat_time_sec)


func _evaluate_intensity_blocks() -> void:
	if _chart == null or current_dsp_time_sec < 0.0:
		return

	var blocks: Array[IntensityBlock] = _chart.intensity_blocks
	var block_count: int = blocks.size()
	if block_count == 0:
		return

	while _current_block_index < block_count and current_dsp_time_sec >= blocks[_current_block_index].end_sec:
		_current_block_index += 1

	if _current_block_index < block_count:
		var candidate: IntensityBlock = blocks[_current_block_index]
		if current_dsp_time_sec >= candidate.start_sec and current_dsp_time_sec < candidate.end_sec:
			if candidate != _active_intensity_block:
				_active_intensity_block = candidate
				intensity_changed.emit(candidate)


func _on_audio_player_finished() -> void:
	if not _is_running:
		return
	_finalize_playback()


func _finalize_playback() -> void:
	if _chart != null and _chart.duration_sec > 0.0:
		current_dsp_time_sec = maxf(current_dsp_time_sec, _chart.duration_sec)
	_visual_time_sec = current_dsp_time_sec
	_evaluate_beats()
	_evaluate_intensity_blocks()
	dsp_time_updated.emit(current_dsp_time_sec)
	visual_time_updated.emit(_visual_time_sec)
	_is_running = false
	_is_paused = false
	_in_lead_in = false
	playback_finished.emit()
