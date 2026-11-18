class_name AudioAnalyzer
extends Node

signal spectrum_updated(
	bass_energy: float,
	mid_energy: float,
	high_energy: float,
	total_energy: float
)

const DEFAULT_HOP_SEC: float = 0.02
const MIN_HOP_SEC: float = 0.005
const DEFAULT_BPM: float = 120.0
const MIN_BPM: float = 72.0
const MAX_BPM: float = 185.0
const MIN_DB_THRESHOLD: float = 60.0
const EPSILON: float = 0.00001

@export var analysis_bus_name: StringName = &"Master"
@export var bass_min_hz: float = 20.0
@export var bass_max_hz: float = 200.0
@export var mid_max_hz: float = 2200.0
@export var high_max_hz: float = 12000.0
@export var live_monitoring_enabled: bool = false

var _spectrum_instance: AudioEffectSpectrumAnalyzerInstance = null


func _ready() -> void:
	if live_monitoring_enabled:
		_ensure_spectrum_analyzer_instance()


func set_live_monitoring(p_enabled: bool) -> void:
	live_monitoring_enabled = p_enabled
	if live_monitoring_enabled:
		_ensure_spectrum_analyzer_instance()


func _process(_delta: float) -> void:
	if not live_monitoring_enabled:
		return

	if _spectrum_instance == null:
		_ensure_spectrum_analyzer_instance()
		if _spectrum_instance == null:
			return

	var bass_vec: Vector2 = _spectrum_instance.get_magnitude_for_frequency_range(
		bass_min_hz,
		bass_max_hz,
		AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
	)
	var mid_vec: Vector2 = _spectrum_instance.get_magnitude_for_frequency_range(
		bass_max_hz,
		mid_max_hz,
		AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
	)
	var high_vec: Vector2 = _spectrum_instance.get_magnitude_for_frequency_range(
		mid_max_hz,
		high_max_hz,
		AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
	)

	var bass_energy: float = _normalize_spectrum_magnitude(bass_vec.length())
	var mid_energy: float = _normalize_spectrum_magnitude(mid_vec.length())
	var high_energy: float = _normalize_spectrum_magnitude(high_vec.length())
	var total_energy: float = clampf(
		(bass_energy * 0.45) + (mid_energy * 0.35) + (high_energy * 0.20),
		0.0,
		1.0
	)

	spectrum_updated.emit(bass_energy, mid_energy, high_energy, total_energy)


func load_audio_stream(p_path: String) -> AudioStream:
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
		"wav":
			return AudioStreamWAV.load_from_file(p_path)
		"ogg":
			return AudioStreamOggVorbis.load_from_file(p_path)
		"mp3":
			return AudioStreamMP3.load_from_file(p_path)
		_:
			return null


func analyze_audio_stream(p_stream: AudioStream, p_hop_sec: float = DEFAULT_HOP_SEC) -> Dictionary:
	var safe_hop_sec: float = maxf(MIN_HOP_SEC, p_hop_sec)
	if p_stream == null:
		return _build_empty_analysis(safe_hop_sec)

	if p_stream is AudioStreamWAV:
		return analyze_wav_stream(p_stream as AudioStreamWAV, safe_hop_sec)

	var duration_sec: float = maxf(0.0, p_stream.get_length())
	if duration_sec <= 0.0:
		return _build_empty_analysis(safe_hop_sec)

	var playback: AudioStreamPlayback = p_stream.instantiate_playback()
	if playback == null:
		return _build_empty_analysis(safe_hop_sec)

	var mix_rate: float = maxf(8000.0, AudioServer.get_mix_rate())
	var samples_per_hop: int = maxi(1, int(round(mix_rate * safe_hop_sec)))
	var frame_count: int = maxi(1, int(ceil(duration_sec / safe_hop_sec)))

	var rms_frames: PackedFloat32Array = PackedFloat32Array()
	var bass_frames: PackedFloat32Array = PackedFloat32Array()
	var mid_frames: PackedFloat32Array = PackedFloat32Array()
	var high_frames: PackedFloat32Array = PackedFloat32Array()

	rms_frames.resize(frame_count)
	bass_frames.resize(frame_count)
	mid_frames.resize(frame_count)
	high_frames.resize(frame_count)

	var alpha_bass: float = _compute_lpf_alpha(bass_max_hz, mix_rate)
	var alpha_mid: float = _compute_lpf_alpha(mid_max_hz, mix_rate)
	var lp_bass: float = 0.0
	var lp_mid: float = 0.0

	playback.start(0.0)
	for frame_idx: int in range(frame_count):
		var mixed_chunk: PackedVector2Array = playback.mix_audio(1.0, samples_per_hop)
		var count: int = mixed_chunk.size()
		if count <= 0:
			rms_frames[frame_idx] = 0.0
			bass_frames[frame_idx] = 0.0
			mid_frames[frame_idx] = 0.0
			high_frames[frame_idx] = 0.0
			continue

		var sum_sq_total: float = 0.0
		var sum_sq_bass: float = 0.0
		var sum_sq_mid: float = 0.0
		var sum_sq_high: float = 0.0

		for s_idx: int in range(count):
			var stereo_frame: Vector2 = mixed_chunk[s_idx]
			var sample: float = (stereo_frame.x + stereo_frame.y) * 0.5
			lp_bass += alpha_bass * (sample - lp_bass)
			lp_mid += alpha_mid * (sample - lp_mid)

			var s_bass: float = lp_bass
			var s_mid: float = lp_mid - lp_bass
			var s_high: float = sample - lp_mid

			sum_sq_total += sample * sample
			sum_sq_bass += s_bass * s_bass
			sum_sq_mid += s_mid * s_mid
			sum_sq_high += s_high * s_high

		var inv_count: float = 1.0 / float(count)
		rms_frames[frame_idx] = sqrt(sum_sq_total * inv_count)
		bass_frames[frame_idx] = sqrt(sum_sq_bass * inv_count)
		mid_frames[frame_idx] = sqrt(sum_sq_mid * inv_count)
		high_frames[frame_idx] = sqrt(sum_sq_high * inv_count)

	playback.stop()
	return _finalize_analysis_buffers(
		duration_sec,
		safe_hop_sec,
		rms_frames,
		bass_frames,
		mid_frames,
		high_frames
	)


func analyze_wav_stream(p_wav: AudioStreamWAV, p_hop_sec: float = DEFAULT_HOP_SEC) -> Dictionary:
	var safe_hop_sec: float = maxf(MIN_HOP_SEC, p_hop_sec)
	if p_wav == null:
		return _build_empty_analysis(safe_hop_sec)

	var format: int = p_wav.format
	if format != AudioStreamWAV.FORMAT_8_BITS and format != AudioStreamWAV.FORMAT_16_BITS:
		return _build_empty_analysis(safe_hop_sec)

	var raw_bytes: PackedByteArray = p_wav.data
	var total_bytes: int = raw_bytes.size()
	var mix_rate: int = maxi(1, p_wav.mix_rate)
	var bytes_per_sample: int = 2 if format == AudioStreamWAV.FORMAT_16_BITS else 1
	var channels: int = 2 if p_wav.stereo else 1
	var bytes_per_frame: int = bytes_per_sample * channels

	var total_sample_frames: int = total_bytes / bytes_per_frame
	if total_sample_frames <= 0:
		return _build_empty_analysis(safe_hop_sec)

	var duration_sec: float = float(total_sample_frames) / float(mix_rate)
	var samples_per_hop: int = maxi(1, int(round(float(mix_rate) * safe_hop_sec)))
	var hop_count: int = maxi(1, int(ceil(float(total_sample_frames) / float(samples_per_hop))))

	var rms_frames: PackedFloat32Array = PackedFloat32Array()
	var bass_frames: PackedFloat32Array = PackedFloat32Array()
	var mid_frames: PackedFloat32Array = PackedFloat32Array()
	var high_frames: PackedFloat32Array = PackedFloat32Array()

	rms_frames.resize(hop_count)
	bass_frames.resize(hop_count)
	mid_frames.resize(hop_count)
	high_frames.resize(hop_count)

	var alpha_bass: float = _compute_lpf_alpha(bass_max_hz, float(mix_rate))
	var alpha_mid: float = _compute_lpf_alpha(mid_max_hz, float(mix_rate))
	var lp_bass: float = 0.0
	var lp_mid: float = 0.0

	var is_16_bit: bool = format == AudioStreamWAV.FORMAT_16_BITS
	var is_stereo: bool = p_wav.stereo

	for hop_idx: int in range(hop_count):
		var start_sample: int = hop_idx * samples_per_hop
		var end_sample: int = mini(total_sample_frames, start_sample + samples_per_hop)
		var count: int = end_sample - start_sample
		if count <= 0:
			rms_frames[hop_idx] = 0.0
			bass_frames[hop_idx] = 0.0
			mid_frames[hop_idx] = 0.0
			high_frames[hop_idx] = 0.0
			continue

		var sum_sq_total: float = 0.0
		var sum_sq_bass: float = 0.0
		var sum_sq_mid: float = 0.0
		var sum_sq_high: float = 0.0

		var byte_cursor: int = start_sample * bytes_per_frame
		for _s: int in range(count):
			var sample: float = 0.0
			if is_16_bit:
				var left_16: float = float(raw_bytes.decode_s16(byte_cursor)) / 32768.0
				if is_stereo:
					var right_16: float = float(raw_bytes.decode_s16(byte_cursor + 2)) / 32768.0
					sample = (left_16 + right_16) * 0.5
				else:
					sample = left_16
			else:
				var left_8: float = float(raw_bytes.decode_s8(byte_cursor)) / 128.0
				if is_stereo:
					var right_8: float = float(raw_bytes.decode_s8(byte_cursor + 1)) / 128.0
					sample = (left_8 + right_8) * 0.5
				else:
					sample = left_8

			byte_cursor += bytes_per_frame

			lp_bass += alpha_bass * (sample - lp_bass)
			lp_mid += alpha_mid * (sample - lp_mid)

			var s_bass: float = lp_bass
			var s_mid: float = lp_mid - lp_bass
			var s_high: float = sample - lp_mid

			sum_sq_total += sample * sample
			sum_sq_bass += s_bass * s_bass
			sum_sq_mid += s_mid * s_mid
			sum_sq_high += s_high * s_high

		var inv_count: float = 1.0 / float(count)
		rms_frames[hop_idx] = sqrt(sum_sq_total * inv_count)
		bass_frames[hop_idx] = sqrt(sum_sq_bass * inv_count)
		mid_frames[hop_idx] = sqrt(sum_sq_mid * inv_count)
		high_frames[hop_idx] = sqrt(sum_sq_high * inv_count)

	return _finalize_analysis_buffers(
		duration_sec,
		safe_hop_sec,
		rms_frames,
		bass_frames,
		mid_frames,
		high_frames
	)


func _finalize_analysis_buffers(
	p_duration_sec: float,
	p_hop_sec: float,
	p_rms_frames: PackedFloat32Array,
	p_bass_frames: PackedFloat32Array,
	p_mid_frames: PackedFloat32Array,
	p_high_frames: PackedFloat32Array
) -> Dictionary:
	_normalize_array_in_place(p_rms_frames)
	_normalize_array_in_place(p_bass_frames)
	_normalize_array_in_place(p_mid_frames)
	_normalize_array_in_place(p_high_frames)

	var frame_count: int = p_rms_frames.size()
	var onset_frames: PackedFloat32Array = PackedFloat32Array()
	onset_frames.resize(frame_count)

	var prev_bass: float = 0.0
	var prev_mid: float = 0.0
	var prev_high: float = 0.0

	for i: int in range(frame_count):
		var b_curr: float = p_bass_frames[i]
		var m_curr: float = p_mid_frames[i]
		var h_curr: float = p_high_frames[i]

		var db: float = maxf(0.0, b_curr - prev_bass)
		var dm: float = maxf(0.0, m_curr - prev_mid)
		var dh: float = maxf(0.0, h_curr - prev_high)

		onset_frames[i] = (db * 1.35) + (dm * 1.00) + (dh * 1.15)
		prev_bass = b_curr
		prev_mid = m_curr
		prev_high = h_curr

	_normalize_array_in_place(onset_frames)
	var bpm_estimate: float = _estimate_bpm_from_onsets(onset_frames, p_hop_sec)

	return {
		"duration_sec": p_duration_sec,
		"bpm_estimate": bpm_estimate,
		"frame_hop_sec": p_hop_sec,
		"rms_frames": p_rms_frames,
		"bass_frames": p_bass_frames,
		"mid_frames": p_mid_frames,
		"high_frames": p_high_frames,
		"onset_frames": onset_frames,
	}


func _estimate_bpm_from_onsets(p_onset_frames: PackedFloat32Array, p_hop_sec: float) -> float:
	var count: int = p_onset_frames.size()
	var min_lag: int = maxi(1, int(round((60.0 / MAX_BPM) / p_hop_sec)))
	var max_lag: int = maxi(min_lag + 1, int(round((60.0 / MIN_BPM) / p_hop_sec)))
	if count <= max_lag + 2:
		return DEFAULT_BPM

	var best_lag: int = int(round((60.0 / DEFAULT_BPM) / p_hop_sec))
	var best_score: float = -1.0

	for lag: int in range(min_lag, max_lag + 1):
		var limit: int = count - lag
		if limit <= 0:
			continue

		var sum_corr: float = 0.0
		for i: int in range(limit):
			sum_corr += p_onset_frames[i] * p_onset_frames[i + lag]
		var avg_corr: float = sum_corr / float(limit)

		var double_lag: int = lag * 2
		if double_lag < count:
			var limit_2: int = count - double_lag
			var sum_corr_2: float = 0.0
			for j: int in range(limit_2):
				sum_corr_2 += p_onset_frames[j] * p_onset_frames[j + double_lag]
			avg_corr += 0.35 * (sum_corr_2 / float(limit_2))

		if avg_corr > best_score:
			best_score = avg_corr
			best_lag = lag

	if best_score <= EPSILON:
		return DEFAULT_BPM

	var raw_bpm: float = 60.0 / (float(best_lag) * p_hop_sec)
	return clampf(round(raw_bpm), MIN_BPM, MAX_BPM)


func _compute_lpf_alpha(p_cutoff_hz: float, p_mix_rate: float) -> float:
	var omega: float = TAU * maxf(1.0, p_cutoff_hz)
	return clampf(omega / (omega + maxf(1.0, p_mix_rate)), 0.0001, 0.9999)


func _normalize_array_in_place(p_array: PackedFloat32Array) -> void:
	var count: int = p_array.size()
	var peak: float = 0.0
	for i: int in range(count):
		if p_array[i] > peak:
			peak = p_array[i]

	if peak <= EPSILON:
		return

	var inv_peak: float = 1.0 / peak
	for i: int in range(count):
		p_array[i] = clampf(p_array[i] * inv_peak, 0.0, 1.0)


func _ensure_spectrum_analyzer_instance() -> void:
	var bus_idx: int = AudioServer.get_bus_index(analysis_bus_name)
	if bus_idx < 0:
		bus_idx = 0

	var effect_count: int = AudioServer.get_bus_effect_count(bus_idx)
	for i: int in range(effect_count):
		var existing_effect: AudioEffect = AudioServer.get_bus_effect(bus_idx, i)
		if existing_effect is AudioEffectSpectrumAnalyzer:
			var existing_inst: AudioEffectInstance = AudioServer.get_bus_effect_instance(bus_idx, i)
			if existing_inst is AudioEffectSpectrumAnalyzerInstance:
				_spectrum_instance = existing_inst as AudioEffectSpectrumAnalyzerInstance
				return

	var new_analyzer: AudioEffectSpectrumAnalyzer = AudioEffectSpectrumAnalyzer.new()
	new_analyzer.buffer_length = 0.1
	new_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	AudioServer.add_bus_effect(bus_idx, new_analyzer)
	var new_idx: int = AudioServer.get_bus_effect_count(bus_idx) - 1
	var created_inst: AudioEffectInstance = AudioServer.get_bus_effect_instance(bus_idx, new_idx)
	if created_inst is AudioEffectSpectrumAnalyzerInstance:
		_spectrum_instance = created_inst as AudioEffectSpectrumAnalyzerInstance


func _normalize_spectrum_magnitude(p_linear_mag: float) -> float:
	if p_linear_mag <= EPSILON:
		return 0.0
	var db: float = linear_to_db(p_linear_mag)
	return clampf((db + MIN_DB_THRESHOLD) / MIN_DB_THRESHOLD, 0.0, 1.0)


func _build_empty_analysis(p_hop_sec: float) -> Dictionary:
	return {
		"duration_sec": 0.0,
		"bpm_estimate": DEFAULT_BPM,
		"frame_hop_sec": p_hop_sec,
		"rms_frames": PackedFloat32Array(),
		"bass_frames": PackedFloat32Array(),
		"mid_frames": PackedFloat32Array(),
		"high_frames": PackedFloat32Array(),
		"onset_frames": PackedFloat32Array(),
	}
