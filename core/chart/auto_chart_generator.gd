class_name AutoChartGenerator
extends RefCounted

enum Difficulty {
	EASY = 0,
	NORMAL = 1,
	HARD = 2,
}

enum NoteTypeMode {
	TAP_AND_HOLD = 0,
	TAP_ONLY = 1,
}

const LANE_COUNT: int = 4
const MIN_HOLD_DURATION_SEC: float = 0.45
const HOLD_TAIL_SAFETY_GAP_SEC: float = 0.08
const HOLD_CASCADE_COOLDOWN_SEC: float = 0.30
const TRACK_END_MARGIN_SEC: float = 0.10
const LOCAL_WINDOW_RADIUS_FRAMES: int = 12
const DEFAULT_BLOCK_BEATS: int = 8
const TIME_DEDUP_EPSILON_SEC: float = 0.002


func generate_from_analysis(
	p_song_id: String,
	p_title: String,
	p_audio_path: String,
	p_analysis: Dictionary,
	p_difficulty: int = Difficulty.NORMAL,
	p_note_type_mode: int = NoteTypeMode.TAP_AND_HOLD,
	p_seed: int = 1337
) -> ChartData:
	var duration_sec: float = maxf(0.5, p_analysis.get("duration_sec", 4.0) as float)
	var bpm_estimate: float = clampf(p_analysis.get("bpm_estimate", 120.0) as float, 60.0, 220.0)
	var hop_sec: float = maxf(0.005, p_analysis.get("frame_hop_sec", 0.02) as float)

	var rms_frames: PackedFloat32Array = p_analysis.get("rms_frames", PackedFloat32Array()) as PackedFloat32Array
	var bass_frames: PackedFloat32Array = p_analysis.get("bass_frames", PackedFloat32Array()) as PackedFloat32Array
	var mid_frames: PackedFloat32Array = p_analysis.get("mid_frames", PackedFloat32Array()) as PackedFloat32Array
	var high_frames: PackedFloat32Array = p_analysis.get("high_frames", PackedFloat32Array()) as PackedFloat32Array
	var onset_frames: PackedFloat32Array = p_analysis.get("onset_frames", PackedFloat32Array()) as PackedFloat32Array

	var beat_sec: float = 60.0 / bpm_estimate
	var grid_step_sec: float = _get_grid_step_for_difficulty(beat_sec, p_difficulty)
	var min_note_gap_sec: float = _get_min_gap_for_difficulty(beat_sec, p_difficulty)
	var threshold_bias: float = _get_threshold_bias_for_difficulty(p_difficulty)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = p_seed

	var raw_candidates: Array[Dictionary] = _pick_quantized_peaks(
		onset_frames,
		bass_frames,
		mid_frames,
		high_frames,
		hop_sec,
		duration_sec,
		grid_step_sec,
		min_note_gap_sec,
		threshold_bias
	)

	var notes: Array[NoteData] = _assign_lanes_and_deduplicate(
		raw_candidates,
		min_note_gap_sec,
		rng
	)

	if p_note_type_mode == NoteTypeMode.TAP_AND_HOLD:
		_apply_hold_durations(
			notes,
			rms_frames,
			hop_sec,
			duration_sec,
			grid_step_sec
		)
	else:
		var note_count: int = notes.size()
		for i: int in range(note_count):
			notes[i].duration_sec = 0.0

	var intensity_blocks: Array[IntensityBlock] = _build_intensity_blocks(
		rms_frames,
		hop_sec,
		duration_sec,
		beat_sec
	)

	var safe_id: String = p_song_id if not p_song_id.is_empty() else "auto_song"
	var safe_title: String = p_title if not p_title.is_empty() else "Auto Generated Track"
	var chart: ChartData = ChartData.new(
		safe_id,
		safe_title,
		p_audio_path,
		duration_sec,
		bpm_estimate,
		0.0,
		notes,
		intensity_blocks
	)

	var validation: Dictionary = chart.validate()
	if not (validation.get("valid", false) as bool):
		var empty_notes: Array[NoteData] = []
		chart.notes = empty_notes

	return chart


func _pick_quantized_peaks(
	p_onset_frames: PackedFloat32Array,
	p_bass_frames: PackedFloat32Array,
	p_mid_frames: PackedFloat32Array,
	p_high_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_duration_sec: float,
	p_grid_step_sec: float,
	p_min_note_gap_sec: float,
	p_threshold_bias: float
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var frame_count: int = p_onset_frames.size()
	if frame_count < 3:
		return candidates

	var last_accepted_time_sec: float = -999.0
	var max_allowed_time_sec: float = maxf(0.0, p_duration_sec - TRACK_END_MARGIN_SEC)

	for i: int in range(1, frame_count - 1):
		var curr: float = p_onset_frames[i]
		if curr < p_onset_frames[i - 1] or curr < p_onset_frames[i + 1]:
			continue

		var w_start: int = maxi(0, i - LOCAL_WINDOW_RADIUS_FRAMES)
		var w_end: int = mini(frame_count - 1, i + LOCAL_WINDOW_RADIUS_FRAMES)
		var local_sum: float = 0.0
		var local_count: int = (w_end - w_start) + 1
		for k: int in range(w_start, w_end + 1):
			local_sum += p_onset_frames[k]
		var local_mean: float = local_sum / float(maxi(1, local_count))

		if curr < local_mean + p_threshold_bias:
			continue

		var raw_time_sec: float = float(i) * p_hop_sec
		var quantized_time_sec: float = round(raw_time_sec / p_grid_step_sec) * p_grid_step_sec
		quantized_time_sec = clampf(quantized_time_sec, 0.0, max_allowed_time_sec)

		if quantized_time_sec - last_accepted_time_sec < p_min_note_gap_sec - TIME_DEDUP_EPSILON_SEC:
			continue

		var bass_val: float = p_bass_frames[i] if i < p_bass_frames.size() else 0.0
		var mid_val: float = p_mid_frames[i] if i < p_mid_frames.size() else 0.0
		var high_val: float = p_high_frames[i] if i < p_high_frames.size() else 0.0
		var strength: float = clampf(maxf(0.25, curr), 0.0, 1.0)

		candidates.append({
			"time_sec": quantized_time_sec,
			"frame_index": i,
			"strength": strength,
			"bass": bass_val,
			"mid": mid_val,
			"high": high_val,
		})
		last_accepted_time_sec = quantized_time_sec

	return candidates


func _assign_lanes_and_deduplicate(
	p_candidates: Array[Dictionary],
	p_min_note_gap_sec: float,
	p_rng: RandomNumberGenerator
) -> Array[NoteData]:
	var generated_notes: Array[NoteData] = []
	var last_lane: int = -1
	var lane_last_time: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0, -999.0, -999.0])

	var candidate_count: int = p_candidates.size()
	for i: int in range(candidate_count):
		var item: Dictionary = p_candidates[i]
		var t_sec: float = item["time_sec"] as float
		var strength: float = item["strength"] as float
		var bass_val: float = item["bass"] as float
		var mid_val: float = item["mid"] as float
		var high_val: float = item["high"] as float

		var preferred_lane: int = 0
		if bass_val >= mid_val and bass_val >= high_val:
			preferred_lane = 1 if (p_rng.randi() % 2) == 0 else 0
		elif mid_val >= high_val:
			preferred_lane = 2 if (p_rng.randi() % 2) == 0 else 1
		else:
			preferred_lane = 3 if (p_rng.randi() % 2) == 0 else 2

		var chosen_lane: int = preferred_lane
		if chosen_lane == last_lane or (t_sec - lane_last_time[chosen_lane]) < p_min_note_gap_sec:
			for offset: int in range(1, LANE_COUNT + 1):
				var alt_lane: int = (preferred_lane + offset) % LANE_COUNT
				if alt_lane != last_lane and (t_sec - lane_last_time[alt_lane]) >= p_min_note_gap_sec:
					chosen_lane = alt_lane
					break

		lane_last_time[chosen_lane] = t_sec
		last_lane = chosen_lane
		generated_notes.append(NoteData.new(t_sec, chosen_lane, 0.0, strength))

	# Sort chronologically by time_sec (and lane as tie-breaker) and filter exact/same-lane duplicates
	generated_notes.sort_custom(_compare_notes_chronologically)

	var deduplicated_notes: Array[NoteData] = []
	var per_lane_last_time: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0, -999.0, -999.0])
	var gen_count: int = generated_notes.size()
	for idx: int in range(gen_count):
		var note: NoteData = generated_notes[idx]
		var prev_t: float = per_lane_last_time[note.lane]
		if prev_t >= 0.0 and absf(note.time_sec - prev_t) <= TIME_DEDUP_EPSILON_SEC:
			continue
		if prev_t >= 0.0 and note.time_sec <= prev_t:
			continue
		per_lane_last_time[note.lane] = note.time_sec
		deduplicated_notes.append(note)

	return deduplicated_notes


func _apply_hold_durations(
	p_notes: Array[NoteData],
	p_rms_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_duration_sec: float,
	p_grid_step_sec: float
) -> void:
	var rms_count: int = p_rms_frames.size()
	if rms_count == 0:
		return

	var sum_rms: float = 0.0
	for i: int in range(rms_count):
		sum_rms += p_rms_frames[i]
	var mean_rms: float = sum_rms / float(rms_count)
	var sustain_threshold: float = maxf(0.26, mean_rms * 0.88)
	var last_hold_end_sec: float = -999.0

	var note_count: int = p_notes.size()
	for i: int in range(note_count):
		var note: NoteData = p_notes[i]
		if note.time_sec < last_hold_end_sec + HOLD_CASCADE_COOLDOWN_SEC:
			note.duration_sec = 0.0
			continue

		var start_frame: int = clampi(int(round(note.time_sec / p_hop_sec)), 0, rms_count - 1)

		var next_same_lane_time: float = p_duration_sec - TRACK_END_MARGIN_SEC
		for j: int in range(i + 1, note_count):
			if p_notes[j].lane == note.lane:
				next_same_lane_time = minf(
					next_same_lane_time,
					p_notes[j].time_sec - HOLD_TAIL_SAFETY_GAP_SEC
				)
				break

		var max_possible_hold_sec: float = next_same_lane_time - note.time_sec
		if max_possible_hold_sec < MIN_HOLD_DURATION_SEC:
			note.duration_sec = 0.0
			continue

		var sustained_frames: int = 0
		var cursor: int = start_frame
		while cursor < rms_count and p_rms_frames[cursor] >= sustain_threshold:
			sustained_frames += 1
			cursor += 1

		var raw_sustain_sec: float = float(sustained_frames) * p_hop_sec
		var quantized_hold_sec: float = floor(raw_sustain_sec / p_grid_step_sec) * p_grid_step_sec
		var clamped_hold_sec: float = minf(quantized_hold_sec, max_possible_hold_sec)

		if clamped_hold_sec >= MIN_HOLD_DURATION_SEC:
			note.duration_sec = clamped_hold_sec
			last_hold_end_sec = note.time_sec + clamped_hold_sec
		else:
			note.duration_sec = 0.0


func _build_intensity_blocks(
	p_rms_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_duration_sec: float,
	p_beat_sec: float
) -> Array[IntensityBlock]:
	var blocks: Array[IntensityBlock] = []
	var block_span_sec: float = maxf(1.5, p_beat_sec * float(DEFAULT_BLOCK_BEATS))
	var rms_count: int = p_rms_frames.size()

	var cursor_sec: float = 0.0
	while cursor_sec < p_duration_sec - TIME_DEDUP_EPSILON_SEC:
		var end_sec: float = minf(p_duration_sec, cursor_sec + block_span_sec)
		if p_duration_sec - end_sec < 0.35:
			end_sec = p_duration_sec

		var energy: float = 0.35
		if rms_count > 0:
			var start_idx: int = clampi(int(floor(cursor_sec / p_hop_sec)), 0, rms_count - 1)
			var end_idx: int = clampi(int(ceil(end_sec / p_hop_sec)), start_idx + 1, rms_count)
			var sum_e: float = 0.0
			var span_count: int = maxi(1, end_idx - start_idx)
			for k: int in range(start_idx, end_idx):
				sum_e += p_rms_frames[k]
			energy = clampf(sum_e / float(span_count), 0.0, 1.0)

		var tier: int = _classify_energy_tier(energy)
		blocks.append(IntensityBlock.new(cursor_sec, end_sec, energy, tier))
		cursor_sec = end_sec

	if blocks.is_empty():
		blocks.append(IntensityBlock.new(0.0, p_duration_sec, 0.35, 1))

	return blocks


func _classify_energy_tier(p_energy: float) -> int:
	if p_energy >= 0.76:
		return 3
	if p_energy >= 0.52:
		return 2
	if p_energy >= 0.26:
		return 1
	return 0


func _get_grid_step_for_difficulty(p_beat_sec: float, p_difficulty: int) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return p_beat_sec
		Difficulty.HARD:
			return p_beat_sec * 0.25
		_:
			return p_beat_sec * 0.5


func _get_min_gap_for_difficulty(p_beat_sec: float, p_difficulty: int) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return maxf(0.24, p_beat_sec * 0.85)
		Difficulty.HARD:
			return maxf(0.11, p_beat_sec * 0.24)
		_:
			return maxf(0.16, p_beat_sec * 0.45)


func _get_threshold_bias_for_difficulty(p_difficulty: int) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return 0.22
		Difficulty.HARD:
			return 0.06
		_:
			return 0.12


func _compare_notes_chronologically(p_a: NoteData, p_b: NoteData) -> bool:
	if is_equal_approx(p_a.time_sec, p_b.time_sec):
		return p_a.lane < p_b.lane
	return p_a.time_sec < p_b.time_sec
