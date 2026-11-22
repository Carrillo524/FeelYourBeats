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
const ONSET_LEAD_COMPENSATION_SEC: float = 0.002
const PHASE_COARSE_STEP_SEC: float = 0.005
const PHASE_FINE_STEP_SEC: float = 0.001
const PHASE_KERNEL_SIGMA_SEC: float = 0.022
const BPM_PERCEPTUAL_CENTER: float = 126.0
const BPM_PERCEPTUAL_SIGMA: float = 42.0
const RAYLEIGH_CHUNK_SEC: float = 20.0

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


static func detect_audio_extension_from_bytes(
	p_bytes: PackedByteArray,
	p_fallback_path: String = ""
) -> String:
	var byte_count: int = p_bytes.size()
	if byte_count >= 4:
		# OGG Vorbis: "OggS"
		if (
			p_bytes[0] == 0x4F
			and p_bytes[1] == 0x67
			and p_bytes[2] == 0x67
			and p_bytes[3] == 0x53
		):
			return "ogg"
		# MP3 with ID3v2 header: "ID3"
		if p_bytes[0] == 0x49 and p_bytes[1] == 0x44 and p_bytes[2] == 0x33:
			return "mp3"

	if byte_count >= 12:
		# WAV: "RIFF" ... "WAVE"
		if (
			p_bytes[0] == 0x52
			and p_bytes[1] == 0x49
			and p_bytes[2] == 0x46
			and p_bytes[3] == 0x46
			and p_bytes[8] == 0x57
			and p_bytes[9] == 0x41
			and p_bytes[10] == 0x56
			and p_bytes[11] == 0x45
		):
			return "wav"

	# Raw MP3 frame sync header (11-bit sync 0xFFE0, valid MPEG version != 01, valid layer != 00)
	if byte_count >= 2:
		var scan_limit: int = mini(byte_count - 1, 16)
		for offset: int in range(scan_limit):
			var b0: int = p_bytes[offset]
			var b1: int = p_bytes[offset + 1]
			if b0 == 0xFF and (b1 & 0xE0) == 0xE0 and (b1 & 0x18) != 0x08 and (b1 & 0x06) != 0x00:
				return "mp3"
			if b0 != 0x00:
				break

	var fallback_ext: String = p_fallback_path.get_extension().to_lower()
	if fallback_ext == "mp3" or fallback_ext == "ogg" or fallback_ext == "wav":
		return fallback_ext
	return ""


static func _read_file_header_bytes(p_path: String, p_max_bytes: int = 32) -> PackedByteArray:
	var file: FileAccess = FileAccess.open(p_path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var to_read: int = mini(p_max_bytes, file.get_length())
	var header: PackedByteArray = file.get_buffer(to_read) if to_read > 0 else PackedByteArray()
	file.close()
	return header


static func extract_audio_metadata_title_from_file(p_path: String) -> String:
	if p_path.is_empty():
		return ""
	var file: FileAccess = FileAccess.open(p_path, FileAccess.READ)
	if file == null:
		return ""
	var file_len: int = file.get_length()
	if file_len <= 0:
		file.close()
		return ""

	var probe_len: int = mini(file_len, 65536)
	var head_bytes: PackedByteArray = file.get_buffer(probe_len)
	if head_bytes.size() >= 10 and head_bytes[0] == 0x49 and head_bytes[1] == 0x44 and head_bytes[2] == 0x33:
		var id3_size: int = _decode_synchsafe_u32(head_bytes, 6)
		var desired_id3_len: int = mini(file_len, mini(10 + id3_size, 524288))
		if desired_id3_len > head_bytes.size():
			file.seek(0)
			head_bytes = file.get_buffer(desired_id3_len)

	var title_from_head: String = extract_audio_metadata_title(head_bytes)
	if not title_from_head.is_empty():
		file.close()
		return title_from_head

	# Fallback to ID3v1 tag in the last 128 bytes when file is larger than head probe
	if file_len > head_bytes.size() and file_len >= 128:
		file.seek(file_len - 128)
		var tail_bytes: PackedByteArray = file.get_buffer(128)
		file.close()
		return _extract_id3v1_title(tail_bytes)

	file.close()
	return ""


static func extract_audio_metadata_title(p_bytes: PackedByteArray) -> String:
	var byte_count: int = p_bytes.size()
	if byte_count < 4:
		return ""

	# 1. MP3 ID3v2 ("ID3")
	if p_bytes[0] == 0x49 and p_bytes[1] == 0x44 and p_bytes[2] == 0x33:
		var id3v2_title: String = _extract_id3v2_title(p_bytes)
		if not id3v2_title.is_empty():
			return id3v2_title

	# 2. OGG Vorbis Comments ("\x03vorbis" within first 64 KB)
	if (
		p_bytes[0] == 0x4F
		and p_bytes[1] == 0x67
		and p_bytes[2] == 0x67
		and p_bytes[3] == 0x53
	):
		var vorbis_title: String = _extract_ogg_vorbis_title(p_bytes)
		if not vorbis_title.is_empty():
			return vorbis_title

	# 3. MP3 ID3v1 (last 128 bytes starting with "TAG")
	if byte_count >= 128:
		var id3v1_title: String = _extract_id3v1_title(p_bytes)
		if not id3v1_title.is_empty():
			return id3v1_title

	return ""


static func _combine_metadata_artist_title(p_artist: String, p_title: String) -> String:
	var clean_title: String = _clean_metadata_text(p_title)
	if clean_title.is_empty():
		return ""
	var clean_artist: String = _clean_metadata_text(p_artist)
	if not clean_artist.is_empty():
		return "%s - %s" % [clean_artist, clean_title]
	return clean_title


static func _clean_metadata_text(p_text: String) -> String:
	var sanitized: String = p_text.replace("\r", " ").replace("\n", " ").replace("\t", " ")
	return " ".join(sanitized.split(" ", false)).strip_edges()


static func _decode_synchsafe_u32(p_bytes: PackedByteArray, p_offset: int) -> int:
	if p_offset + 4 > p_bytes.size():
		return 0
	return (
		((p_bytes[p_offset] & 0x7F) << 21)
		| ((p_bytes[p_offset + 1] & 0x7F) << 14)
		| ((p_bytes[p_offset + 2] & 0x7F) << 7)
		| (p_bytes[p_offset + 3] & 0x7F)
	)


static func _decode_big_endian_u32(p_bytes: PackedByteArray, p_offset: int) -> int:
	if p_offset + 4 > p_bytes.size():
		return 0
	return (
		(p_bytes[p_offset] << 24)
		| (p_bytes[p_offset + 1] << 16)
		| (p_bytes[p_offset + 2] << 8)
		| p_bytes[p_offset + 3]
	)


static func _extract_id3v2_title(p_bytes: PackedByteArray) -> String:
	var total_len: int = p_bytes.size()
	if total_len < 10:
		return ""

	var major_version: int = p_bytes[3]
	var header_flags: int = p_bytes[5]
	var tag_size: int = _decode_synchsafe_u32(p_bytes, 6)
	var tag_end: int = mini(total_len, 10 + tag_size)
	var cursor: int = 10

	# Skip optional extended header for ID3v2.3 / ID3v2.4
	if (header_flags & 0x40) != 0 and major_version >= 3 and cursor + 4 <= tag_end:
		if major_version == 4:
			var ext_size_v4: int = _decode_synchsafe_u32(p_bytes, cursor)
			if ext_size_v4 >= 6:
				cursor += ext_size_v4
		else:
			var ext_size_v3: int = _decode_big_endian_u32(p_bytes, cursor)
			cursor += 4 + ext_size_v3

	var found_title: String = ""
	var found_artist: String = ""

	if major_version == 2:
		while cursor + 6 <= tag_end:
			if p_bytes[cursor] == 0x00:
				break
			var frame_id_v2: String = p_bytes.slice(cursor, cursor + 3).get_string_from_ascii()
			var frame_size_v2: int = (
				(p_bytes[cursor + 3] << 16)
				| (p_bytes[cursor + 4] << 8)
				| p_bytes[cursor + 5]
			)
			var data_start_v2: int = cursor + 6
			if frame_size_v2 <= 0 or data_start_v2 + frame_size_v2 > tag_end:
				break
			if frame_id_v2 == "TT2" and found_title.is_empty():
				found_title = _decode_id3_text_payload(p_bytes.slice(data_start_v2, data_start_v2 + frame_size_v2))
			elif frame_id_v2 == "TP1" and found_artist.is_empty():
				found_artist = _decode_id3_text_payload(p_bytes.slice(data_start_v2, data_start_v2 + frame_size_v2))
			cursor = data_start_v2 + frame_size_v2
			if not found_title.is_empty() and not found_artist.is_empty():
				break
	else:
		while cursor + 10 <= tag_end:
			if p_bytes[cursor] == 0x00:
				break
			var frame_id: String = p_bytes.slice(cursor, cursor + 4).get_string_from_ascii()
			var frame_size: int = 0
			if major_version == 4:
				var has_high_bit: bool = (
					((p_bytes[cursor + 4] | p_bytes[cursor + 5] | p_bytes[cursor + 6] | p_bytes[cursor + 7]) & 0x80) != 0
				)
				frame_size = _decode_big_endian_u32(p_bytes, cursor + 4) if has_high_bit else _decode_synchsafe_u32(p_bytes, cursor + 4)
			else:
				frame_size = _decode_big_endian_u32(p_bytes, cursor + 4)

			var data_start: int = cursor + 10
			if frame_size <= 0 or data_start + frame_size > tag_end:
				break

			if frame_id == "TIT2" and found_title.is_empty():
				found_title = _decode_id3_text_payload(p_bytes.slice(data_start, data_start + frame_size))
			elif frame_id == "TPE1" and found_artist.is_empty():
				found_artist = _decode_id3_text_payload(p_bytes.slice(data_start, data_start + frame_size))

			cursor = data_start + frame_size
			if not found_title.is_empty() and not found_artist.is_empty():
				break

	return _combine_metadata_artist_title(found_artist, found_title)


static func _decode_id3_text_payload(p_payload: PackedByteArray) -> String:
	if p_payload.size() < 2:
		return ""
	var encoding: int = p_payload[0]
	var raw: PackedByteArray = p_payload.slice(1, p_payload.size())
	match encoding:
		0x00:
			return _decode_iso_8859_1(raw)
		0x01:
			return _decode_utf16_with_bom(raw)
		0x02:
			return _decode_utf16_raw(raw, true)
		0x03:
			var end_idx: int = raw.size()
			for i: int in range(raw.size()):
				if raw[i] == 0x00:
					end_idx = i
					break
			return raw.slice(0, end_idx).get_string_from_utf8()
		_:
			return _decode_iso_8859_1(raw)


static func _decode_iso_8859_1(p_bytes: PackedByteArray) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for i: int in range(p_bytes.size()):
		var b: int = p_bytes[i]
		if b == 0x00:
			break
		parts.append(String.chr(b))
	return "".join(parts)


static func _decode_utf16_with_bom(p_bytes: PackedByteArray) -> String:
	if p_bytes.size() < 2:
		return ""
	var is_big_endian: bool = false
	var start_offset: int = 0
	if p_bytes[0] == 0xFE and p_bytes[1] == 0xFF:
		is_big_endian = true
		start_offset = 2
	elif p_bytes[0] == 0xFF and p_bytes[1] == 0xFE:
		is_big_endian = false
		start_offset = 2
	return _decode_utf16_raw(p_bytes.slice(start_offset, p_bytes.size()), is_big_endian)


static func _decode_utf16_raw(p_bytes: PackedByteArray, p_big_endian: bool) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var byte_len: int = p_bytes.size()
	var i: int = 0
	while i + 1 < byte_len:
		var unit: int = (
			((p_bytes[i] << 8) | p_bytes[i + 1])
			if p_big_endian
			else (p_bytes[i] | (p_bytes[i + 1] << 8))
		)
		i += 2
		if unit == 0x0000:
			break
		if unit >= 0xD800 and unit <= 0xDBFF and i + 1 < byte_len:
			var low: int = (
				((p_bytes[i] << 8) | p_bytes[i + 1])
				if p_big_endian
				else (p_bytes[i] | (p_bytes[i + 1] << 8))
			)
			if low >= 0xDC00 and low <= 0xDFFF:
				i += 2
				var codepoint: int = 0x10000 + (((unit - 0xD800) << 10) | (low - 0xDC00))
				parts.append(String.chr(codepoint))
				continue
		parts.append(String.chr(unit))
	return "".join(parts)


static func _extract_id3v1_title(p_bytes: PackedByteArray) -> String:
	var byte_len: int = p_bytes.size()
	if byte_len < 128:
		return ""
	var base: int = byte_len - 128
	if p_bytes[base] != 0x54 or p_bytes[base + 1] != 0x41 or p_bytes[base + 2] != 0x47:
		return ""
	var raw_title: String = _decode_iso_8859_1(p_bytes.slice(base + 3, base + 33))
	var raw_artist: String = _decode_iso_8859_1(p_bytes.slice(base + 33, base + 63))
	return _combine_metadata_artist_title(raw_artist, raw_title)


static func _extract_ogg_vorbis_title(p_bytes: PackedByteArray) -> String:
	var limit: int = mini(p_bytes.size(), 65536)
	var marker_pos: int = -1
	for i: int in range(limit - 7):
		if (
			p_bytes[i] == 0x03
			and p_bytes[i + 1] == 0x76
			and p_bytes[i + 2] == 0x6F
			and p_bytes[i + 3] == 0x72
			and p_bytes[i + 4] == 0x62
			and p_bytes[i + 5] == 0x69
			and p_bytes[i + 6] == 0x73
		):
			marker_pos = i
			break

	if marker_pos < 0:
		return ""

	var cursor: int = marker_pos + 7
	if cursor + 4 > limit:
		return ""
	var vendor_len: int = p_bytes.decode_u32(cursor)
	cursor += 4 + vendor_len
	if vendor_len < 0 or cursor + 4 > limit:
		return ""

	var comment_count: int = mini(p_bytes.decode_u32(cursor), 256)
	cursor += 4

	var found_title: String = ""
	var found_artist: String = ""
	for _idx: int in range(comment_count):
		if cursor + 4 > limit:
			break
		var comment_len: int = p_bytes.decode_u32(cursor)
		cursor += 4
		if comment_len < 0 or cursor + comment_len > limit:
			break
		var comment: String = p_bytes.slice(cursor, cursor + comment_len).get_string_from_utf8()
		cursor += comment_len
		var eq_idx: int = comment.find("=")
		if eq_idx > 0:
			var key: String = comment.substr(0, eq_idx).strip_edges().to_upper()
			var val: String = comment.substr(eq_idx + 1).strip_edges()
			if key == "TITLE" and found_title.is_empty():
				found_title = val
			elif key == "ARTIST" and found_artist.is_empty():
				found_artist = val
		if not found_title.is_empty() and not found_artist.is_empty():
			break

	return _combine_metadata_artist_title(found_artist, found_title)


func load_audio_stream(p_path: String) -> AudioStream:
	if p_path.is_empty():
		return null

	if p_path.begins_with("res://") and ResourceLoader.exists(p_path):
		var res: Resource = ResourceLoader.load(p_path)
		if res is AudioStream:
			return res as AudioStream

	var header_bytes: PackedByteArray = _read_file_header_bytes(p_path, 32)
	if header_bytes.is_empty() and not FileAccess.file_exists(p_path):
		return null

	var ext: String = p_path.get_extension().to_lower()
	if ext != "wav" and ext != "ogg" and ext != "mp3":
		ext = detect_audio_extension_from_bytes(header_bytes, p_path)
	if ext.is_empty():
		return null

	var stream: AudioStream = null
	match ext:
		"wav":
			stream = AudioStreamWAV.load_from_file(p_path)
			if stream == null:
				var wav_bytes: PackedByteArray = FileAccess.get_file_as_bytes(p_path)
				if not wav_bytes.is_empty():
					stream = AudioStreamWAV.load_from_buffer(wav_bytes)
		"ogg":
			stream = AudioStreamOggVorbis.load_from_file(p_path)
			if stream == null:
				var ogg_bytes: PackedByteArray = FileAccess.get_file_as_bytes(p_path)
				if not ogg_bytes.is_empty():
					stream = AudioStreamOggVorbis.load_from_buffer(ogg_bytes)
		"mp3":
			stream = AudioStreamMP3.load_from_file(p_path)
			if stream == null:
				var mp3_bytes: PackedByteArray = FileAccess.get_file_as_bytes(p_path)
				if not mp3_bytes.is_empty():
					var mp3_stream: AudioStreamMP3 = AudioStreamMP3.new()
					mp3_stream.data = mp3_bytes
					stream = mp3_stream
		_:
			return null

	return stream


static func load_external_audio_stream_data(p_path: String) -> AudioStream:
	if p_path.is_empty():
		return null
	var raw_bytes: PackedByteArray = FileAccess.get_file_as_bytes(p_path)
	if raw_bytes.is_empty():
		return null

	var ext: String = p_path.get_extension().to_lower()
	if ext != "wav" and ext != "ogg" and ext != "mp3":
		ext = detect_audio_extension_from_bytes(raw_bytes, p_path)
	if ext.is_empty():
		return null

	match ext:
		"wav":
			var wav_stream: AudioStream = AudioStreamWAV.load_from_buffer(raw_bytes)
			raw_bytes = PackedByteArray()
			return wav_stream
		"ogg":
			var ogg_stream: AudioStream = AudioStreamOggVorbis.load_from_buffer(raw_bytes)
			raw_bytes = PackedByteArray()
			return ogg_stream
		"mp3":
			var mp3_stream: AudioStreamMP3 = AudioStreamMP3.new()
			mp3_stream.data = raw_bytes
			raw_bytes = PackedByteArray()
			return mp3_stream
		_:
			raw_bytes = PackedByteArray()
			return null


static func release_analysis_buffers(p_analysis: Dictionary) -> void:
	if p_analysis.is_empty():
		return
	var keys: Array = p_analysis.keys()
	for i: int in range(keys.size()):
		var k: Variant = keys[i]
		var val: Variant = p_analysis[k]
		if val is PackedFloat32Array:
			p_analysis[k] = PackedFloat32Array()
		elif val is PackedByteArray:
			p_analysis[k] = PackedByteArray()
		elif val is Array:
			(val as Array).clear()
	p_analysis.clear()


func analyze_audio_stream(p_stream: AudioStream, p_hop_sec: float = DEFAULT_HOP_SEC) -> Dictionary:
	var mix_rate: float = maxf(8000.0, AudioServer.get_mix_rate())
	return analyze_audio_stream_data(
		p_stream,
		mix_rate,
		bass_max_hz,
		mid_max_hz,
		p_hop_sec
	)


func analyze_wav_stream(p_wav: AudioStreamWAV, p_hop_sec: float = DEFAULT_HOP_SEC) -> Dictionary:
	return analyze_wav_stream_data(
		p_wav,
		bass_max_hz,
		mid_max_hz,
		p_hop_sec
	)


static func analyze_audio_stream_data(
	p_stream: AudioStream,
	p_mix_rate: float = 44100.0,
	p_bass_max_hz: float = 200.0,
	p_mid_max_hz: float = 2200.0,
	p_hop_sec: float = DEFAULT_HOP_SEC,
	p_progress_cb: Callable = Callable()
) -> Dictionary:
	var safe_hop_sec: float = maxf(MIN_HOP_SEC, p_hop_sec)
	if p_stream == null:
		return _build_empty_analysis(safe_hop_sec)

	if p_stream is AudioStreamWAV:
		return analyze_wav_stream_data(
			p_stream as AudioStreamWAV,
			p_bass_max_hz,
			p_mid_max_hz,
			safe_hop_sec,
			p_progress_cb
		)

	var duration_sec: float = maxf(0.0, p_stream.get_length())
	if duration_sec <= 0.0:
		return _build_empty_analysis(safe_hop_sec)

	var playback: AudioStreamPlayback = p_stream.instantiate_playback()
	if playback == null:
		return _build_empty_analysis(safe_hop_sec)

	var mix_rate: float = maxf(8000.0, p_mix_rate)
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

	var alpha_bass: float = _compute_lpf_alpha(p_bass_max_hz, mix_rate)
	var alpha_mid: float = _compute_lpf_alpha(p_mid_max_hz, mix_rate)
	var lp_bass: float = 0.0
	var lp_mid: float = 0.0
	var has_progress_cb: bool = p_progress_cb.is_valid()
	var last_reported_pct: float = -1.0

	playback.start(0.0)
	var stream_exhausted: bool = false
	for frame_idx: int in range(frame_count):
		if stream_exhausted:
			rms_frames[frame_idx] = 0.0
			bass_frames[frame_idx] = 0.0
			mid_frames[frame_idx] = 0.0
			high_frames[frame_idx] = 0.0
			continue

		var acc_samples_in_hop: int = 0
		var sum_sq_total: float = 0.0
		var sum_sq_bass: float = 0.0
		var sum_sq_mid: float = 0.0
		var sum_sq_high: float = 0.0

		while acc_samples_in_hop < samples_per_hop:
			var remaining_in_hop: int = samples_per_hop - acc_samples_in_hop
			var mixed_chunk: PackedVector2Array = playback.mix_audio(1.0, remaining_in_hop)
			var chunk_count: int = mixed_chunk.size()
			if chunk_count <= 0:
				stream_exhausted = true
				break

			for s_idx: int in range(chunk_count):
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

			acc_samples_in_hop += chunk_count

		if acc_samples_in_hop > 0:
			var inv_count: float = 1.0 / float(acc_samples_in_hop)
			rms_frames[frame_idx] = sqrt(sum_sq_total * inv_count)
			bass_frames[frame_idx] = sqrt(sum_sq_bass * inv_count)
			mid_frames[frame_idx] = sqrt(sum_sq_mid * inv_count)
			high_frames[frame_idx] = sqrt(sum_sq_high * inv_count)
		else:
			rms_frames[frame_idx] = 0.0
			bass_frames[frame_idx] = 0.0
			mid_frames[frame_idx] = 0.0
			high_frames[frame_idx] = 0.0

		if has_progress_cb:
			var pct: float = float(frame_idx + 1) / float(frame_count)
			if pct - last_reported_pct >= 0.03 or frame_idx == frame_count - 1:
				last_reported_pct = pct
				p_progress_cb.call(pct)

	playback.stop()
	return _finalize_analysis_buffers(
		duration_sec,
		safe_hop_sec,
		rms_frames,
		bass_frames,
		mid_frames,
		high_frames
	)


static func analyze_wav_stream_data(
	p_wav: AudioStreamWAV,
	p_bass_max_hz: float = 200.0,
	p_mid_max_hz: float = 2200.0,
	p_hop_sec: float = DEFAULT_HOP_SEC,
	p_progress_cb: Callable = Callable()
) -> Dictionary:
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

	var alpha_bass: float = _compute_lpf_alpha(p_bass_max_hz, float(mix_rate))
	var alpha_mid: float = _compute_lpf_alpha(p_mid_max_hz, float(mix_rate))
	var lp_bass: float = 0.0
	var lp_mid: float = 0.0

	var is_16_bit: bool = format == AudioStreamWAV.FORMAT_16_BITS
	var is_stereo: bool = p_wav.stereo
	var has_progress_cb: bool = p_progress_cb.is_valid()
	var last_reported_pct: float = -1.0

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

		if has_progress_cb:
			var pct: float = float(hop_idx + 1) / float(hop_count)
			if pct - last_reported_pct >= 0.03 or hop_idx == hop_count - 1:
				last_reported_pct = pct
				p_progress_cb.call(pct)

	raw_bytes = PackedByteArray()
	return _finalize_analysis_buffers(
		duration_sec,
		safe_hop_sec,
		rms_frames,
		bass_frames,
		mid_frames,
		high_frames
	)


static func _finalize_analysis_buffers(
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
	var beat_phase_sec: float = estimate_beat_phase_sec(onset_frames, p_hop_sec, bpm_estimate)

	return {
		"duration_sec": p_duration_sec,
		"bpm_estimate": bpm_estimate,
		"beat_phase_sec": beat_phase_sec,
		"frame_hop_sec": p_hop_sec,
		"rms_frames": p_rms_frames,
		"bass_frames": p_bass_frames,
		"mid_frames": p_mid_frames,
		"high_frames": p_high_frames,
		"onset_frames": onset_frames,
	}


static func _estimate_bpm_from_onsets(p_onset_frames: PackedFloat32Array, p_hop_sec: float) -> float:
	var count: int = p_onset_frames.size()
	var min_lag: int = maxi(1, int(floor((60.0 / MAX_BPM) / p_hop_sec)) - 1)
	var max_lag: int = maxi(min_lag + 2, int(ceil((60.0 / MIN_BPM) / p_hop_sec)) + 1)
	if count <= max_lag + 2:
		return DEFAULT_BPM

	# 3-tap smoothing prevents sharp onsets from falling between integer hop bins
	var smooth_onsets: PackedFloat32Array = PackedFloat32Array()
	smooth_onsets.resize(count)
	smooth_onsets[0] = (p_onset_frames[0] * 0.75) + (p_onset_frames[1] * 0.25)
	for s_idx: int in range(1, count - 1):
		smooth_onsets[s_idx] = (
			(p_onset_frames[s_idx - 1] * 0.25)
			+ (p_onset_frames[s_idx] * 0.50)
			+ (p_onset_frames[s_idx + 1] * 0.25)
		)
	smooth_onsets[count - 1] = (p_onset_frames[count - 2] * 0.25) + (p_onset_frames[count - 1] * 0.75)

	var max_ac_lag: int = mini(count - 2, (max_lag * 3) + 2)
	var ac_values: PackedFloat32Array = PackedFloat32Array()
	ac_values.resize(max_ac_lag + 1)
	for init_idx: int in range(max_ac_lag + 1):
		ac_values[init_idx] = 0.0

	for lag: int in range(min_lag, max_ac_lag + 1):
		var limit: int = count - lag
		if limit <= 0:
			continue
		var sum_corr: float = 0.0
		for i: int in range(limit):
			sum_corr += smooth_onsets[i] * smooth_onsets[i + lag]
		ac_values[lag] = sum_corr / float(limit)

	var best_bpm: float = DEFAULT_BPM
	var best_weighted_score: float = -1.0
	var cand_bpm: float = MIN_BPM
	while cand_bpm <= MAX_BPM + 0.001:
		var lag_1: float = (60.0 / cand_bpm) / p_hop_sec
		var lag_2: float = lag_1 * 2.0
		var lag_3: float = lag_1 * 3.0

		var corr_score: float = _sample_array_linear(ac_values, lag_1)
		if lag_2 <= float(max_ac_lag):
			corr_score += 0.40 * _sample_array_linear(ac_values, lag_2)
		if lag_3 <= float(max_ac_lag):
			corr_score += 0.20 * _sample_array_linear(ac_values, lag_3)

		var bpm_diff: float = (cand_bpm - BPM_PERCEPTUAL_CENTER) / BPM_PERCEPTUAL_SIGMA
		var prior_weight: float = 0.86 + (0.14 * exp(-0.5 * bpm_diff * bpm_diff))
		var weighted_score: float = corr_score * prior_weight

		if weighted_score > best_weighted_score:
			best_weighted_score = weighted_score
			best_bpm = cand_bpm

		cand_bpm += 0.5

	if best_weighted_score <= EPSILON:
		return DEFAULT_BPM

	var fine_bpm: float = _refine_bpm_with_peaks(p_onset_frames, p_hop_sec, best_bpm)
	return clampf(round(fine_bpm * 10.0) * 0.1, MIN_BPM, MAX_BPM)


static func _sample_array_linear(p_arr: PackedFloat32Array, p_index: float) -> float:
	var count: int = p_arr.size()
	if count == 0 or p_index < 0.0:
		return 0.0
	var idx_lo: int = int(floor(p_index))
	if idx_lo >= count - 1:
		return p_arr[count - 1]
	var frac: float = p_index - float(idx_lo)
	return lerpf(p_arr[idx_lo], p_arr[idx_lo + 1], frac)


static func _refine_bpm_with_peaks(
	p_onset_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_anchor_bpm: float
) -> float:
	var peak_data: Dictionary = _extract_onset_peaks(p_onset_frames, p_hop_sec, 0.08)
	var peak_times: PackedFloat32Array = peak_data["times"] as PackedFloat32Array
	var peak_weights: PackedFloat32Array = peak_data["weights"] as PackedFloat32Array
	var peak_count: int = peak_times.size()
	if peak_count < 4:
		return p_anchor_bpm

	var best_bpm: float = p_anchor_bpm
	var best_score: float = -1.0
	var search_min: float = maxf(MIN_BPM, p_anchor_bpm - 3.0)
	var search_max: float = minf(MAX_BPM, p_anchor_bpm + 3.0)

	var coarse_bpm: float = search_min
	while coarse_bpm <= search_max + 0.001:
		var score: float = _evaluate_windowed_rayleigh(
			peak_times,
			peak_weights,
			coarse_bpm,
			p_anchor_bpm
		)
		if score > best_score:
			best_score = score
			best_bpm = coarse_bpm
		coarse_bpm += 0.2

	var fine_center: float = best_bpm
	var fine_min: float = maxf(MIN_BPM, fine_center - 0.25)
	var fine_max: float = minf(MAX_BPM, fine_center + 0.25)
	var fine_bpm: float = fine_min
	while fine_bpm <= fine_max + 0.001:
		var fine_score: float = _evaluate_windowed_rayleigh(
			peak_times,
			peak_weights,
			fine_bpm,
			p_anchor_bpm
		)
		if fine_score > best_score:
			best_score = fine_score
			best_bpm = fine_bpm
		fine_bpm += 0.05

	return best_bpm


static func _evaluate_windowed_rayleigh(
	p_peak_times: PackedFloat32Array,
	p_peak_weights: PackedFloat32Array,
	p_candidate_bpm: float,
	p_anchor_bpm: float
) -> float:
	var count: int = p_peak_times.size()
	if count == 0 or p_candidate_bpm <= EPSILON:
		return 0.0

	var period_sec: float = 60.0 / p_candidate_bpm
	var omega: float = TAU / period_sec
	var total_magnitude: float = 0.0
	var chunk_start_sec: float = p_peak_times[0]
	var sum_c1: float = 0.0
	var sum_s1: float = 0.0
	var sum_c2: float = 0.0
	var sum_s2: float = 0.0
	var sum_c4: float = 0.0
	var sum_s4: float = 0.0

	for i: int in range(count):
		var t_sec: float = p_peak_times[i]
		if t_sec - chunk_start_sec >= RAYLEIGH_CHUNK_SEC:
			total_magnitude += (
				sqrt((sum_c1 * sum_c1) + (sum_s1 * sum_s1))
				+ (0.85 * sqrt((sum_c2 * sum_c2) + (sum_s2 * sum_s2)))
				+ (0.35 * sqrt((sum_c4 * sum_c4) + (sum_s4 * sum_s4)))
			)
			sum_c1 = 0.0
			sum_s1 = 0.0
			sum_c2 = 0.0
			sum_s2 = 0.0
			sum_c4 = 0.0
			sum_s4 = 0.0
			chunk_start_sec = t_sec

		var w: float = p_peak_weights[i]
		var a1: float = t_sec * omega
		var a2: float = a1 * 2.0
		var a4: float = a1 * 4.0
		sum_c1 += w * cos(a1)
		sum_s1 += w * sin(a1)
		sum_c2 += w * cos(a2)
		sum_s2 += w * sin(a2)
		sum_c4 += w * cos(a4)
		sum_s4 += w * sin(a4)

	total_magnitude += (
		sqrt((sum_c1 * sum_c1) + (sum_s1 * sum_s1))
		+ (0.85 * sqrt((sum_c2 * sum_c2) + (sum_s2 * sum_s2)))
		+ (0.35 * sqrt((sum_c4 * sum_c4) + (sum_s4 * sum_s4)))
	)

	var anchor_diff: float = (p_candidate_bpm - p_anchor_bpm) / 2.4
	var anchor_bias: float = 1.0 + (0.03 * exp(-0.5 * anchor_diff * anchor_diff))
	return total_magnitude * anchor_bias


static func estimate_beat_phase_sec(
	p_onset_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_bpm: float
) -> float:
	if p_onset_frames.size() < 3 or p_hop_sec <= EPSILON or p_bpm <= EPSILON:
		return 0.0

	var safe_bpm: float = clampf(p_bpm, MIN_BPM, MAX_BPM)
	var beat_sec: float = 60.0 / safe_bpm
	var peak_data: Dictionary = _extract_onset_peaks(p_onset_frames, p_hop_sec, 0.08)
	var peak_times: PackedFloat32Array = peak_data["times"] as PackedFloat32Array
	var peak_weights: PackedFloat32Array = peak_data["weights"] as PackedFloat32Array
	if peak_times.is_empty():
		return 0.0

	var best_phase: float = 0.0
	var best_score: float = -1.0
	var step_count: int = maxi(1, int(ceil(beat_sec / PHASE_COARSE_STEP_SEC)))

	for s: int in range(step_count):
		var cand_phase: float = float(s) * PHASE_COARSE_STEP_SEC
		if cand_phase >= beat_sec:
			break
		var score: float = _evaluate_phase_alignment(peak_times, peak_weights, beat_sec, cand_phase)
		if score > best_score:
			best_score = score
			best_phase = cand_phase

	var fine_center: float = best_phase
	for offset_idx: int in range(-5, 6):
		var fine_phase: float = fposmod(
			fine_center + (float(offset_idx) * PHASE_FINE_STEP_SEC),
			beat_sec
		)
		var fine_score: float = _evaluate_phase_alignment(
			peak_times,
			peak_weights,
			beat_sec,
			fine_phase
		)
		if fine_score > best_score:
			best_score = fine_score
			best_phase = fine_phase

	return fposmod(best_phase, beat_sec)


static func _extract_onset_peaks(
	p_onset_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_min_height: float
) -> Dictionary:
	var times: PackedFloat32Array = PackedFloat32Array()
	var weights: PackedFloat32Array = PackedFloat32Array()
	var count: int = p_onset_frames.size()
	if count < 3:
		return {"times": times, "weights": weights}

	for i: int in range(1, count - 1):
		var curr: float = p_onset_frames[i]
		if curr < p_min_height:
			continue
		var prev_v: float = p_onset_frames[i - 1]
		var next_v: float = p_onset_frames[i + 1]
		if curr < prev_v or curr < next_v:
			continue

		var delta: float = 0.0
		var denom: float = prev_v - (2.0 * curr) + next_v
		if denom < -EPSILON:
			delta = clampf((0.5 * (prev_v - next_v)) / denom, -0.5, 0.5)

		var peak_time_sec: float = maxf(
			0.0,
			((float(i) + delta) * p_hop_sec) - ONSET_LEAD_COMPENSATION_SEC
		)
		times.append(peak_time_sec)
		weights.append(curr)

	return {"times": times, "weights": weights}


static func _evaluate_phase_alignment(
	p_peak_times: PackedFloat32Array,
	p_peak_weights: PackedFloat32Array,
	p_beat_sec: float,
	p_phase_sec: float
) -> float:
	var count: int = p_peak_times.size()
	var inv_two_sigma_sq: float = 0.5 / (PHASE_KERNEL_SIGMA_SEC * PHASE_KERNEL_SIGMA_SEC)
	var half_beat_sec: float = p_beat_sec * 0.5
	var score: float = 0.0

	for i: int in range(count):
		var rel: float = fposmod(p_peak_times[i] - p_phase_sec, p_beat_sec)
		var d_beat: float = minf(rel, p_beat_sec - rel)
		var w: float = p_peak_weights[i]
		if d_beat <= 0.075:
			score += w * exp(-(d_beat * d_beat) * inv_two_sigma_sq)
		else:
			var d_half: float = absf(rel - half_beat_sec)
			if d_half <= 0.055:
				score += 0.30 * w * exp(-(d_half * d_half) * inv_two_sigma_sq)

	return score


static func _compute_lpf_alpha(p_cutoff_hz: float, p_mix_rate: float) -> float:
	var omega: float = TAU * maxf(1.0, p_cutoff_hz)
	return clampf(omega / (omega + maxf(1.0, p_mix_rate)), 0.0001, 0.9999)


static func _normalize_array_in_place(p_array: PackedFloat32Array) -> void:
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


static func _build_empty_analysis(p_hop_sec: float) -> Dictionary:
	return {
		"duration_sec": 0.0,
		"bpm_estimate": DEFAULT_BPM,
		"beat_phase_sec": 0.0,
		"frame_hop_sec": p_hop_sec,
		"rms_frames": PackedFloat32Array(),
		"bass_frames": PackedFloat32Array(),
		"mid_frames": PackedFloat32Array(),
		"high_frames": PackedFloat32Array(),
		"onset_frames": PackedFloat32Array(),
	}
