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
	DOUBLE_TAP = 2,
	HOLD_AND_DOUBLE_TAP = 3,
}

const LANE_COUNT: int = 4
const THUMB_LEFT: int = 0
const THUMB_RIGHT: int = 1
const MIN_HOLD_DURATION_SEC: float = 0.45
const HOLD_CASCADE_COOLDOWN_SEC: float = 0.30
const TRACK_END_MARGIN_SEC: float = 0.12
const LOCAL_WINDOW_RADIUS_FRAMES: int = 12
const DEFAULT_BLOCK_BEATS: int = 8
const TIME_DEDUP_EPSILON_SEC: float = 0.005
const ELASTIC_SNAP_MAX_SEC: float = 0.045
const ELASTIC_SNAP_GRID_RATIO: float = 0.42
const DOMINANT_PEAK_REPLACE_RATIO: float = 1.08
const ONSET_LEAD_COMPENSATION_SEC: float = AudioAnalyzer.ONSET_LEAD_COMPENSATION_SEC
const ERGONOMIC_EPSILON_SEC: float = 0.0005
const COMBINED_TARGET_HOLD_RATIO: float = 0.30
const COMBINED_TARGET_DOUBLE_RATIO: float = 0.29
const COMBINED_MAX_HOLD_RATIO: float = 0.35
const COMBINED_MAX_DOUBLE_RATIO: float = 0.34
const COMBINED_MIN_SINGLE_RATIO: float = 0.35
const COMBINED_MIN_HOLD_OPPOSITE_LEAD_SEC: float = 0.14
const COMBINED_HOLD_DIP_TOLERANCE_FRAMES: int = 2


static func lane_to_thumb(p_lane: int) -> int:
	return THUMB_LEFT if p_lane <= 1 else THUMB_RIGHT


static func get_sibling_lane(p_lane: int) -> int:
	if p_lane <= 1:
		return 1 - p_lane
	return 5 - p_lane


static func get_release_margin_for_difficulty(p_difficulty: int) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return 0.16
		Difficulty.HARD:
			return 0.12
		_:
			return 0.14


static func get_same_thumb_min_gap_for_difficulty(p_difficulty: int) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return 0.32
		Difficulty.HARD:
			return 0.15
		_:
			return 0.21


static func get_sibling_cross_penalty_for_difficulty(p_difficulty: int) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return 0.04
		Difficulty.HARD:
			return 0.025
		_:
			return 0.03


static func get_max_hold_duration_for_difficulty(p_difficulty: int) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return 1.45
		Difficulty.HARD:
			return 1.50
		_:
			return 1.75


static func validate_two_thumb_ergonomics(
	p_chart: ChartData,
	p_release_margin_sec: float = 0.12,
	p_same_thumb_min_gap_sec: float = 0.0,
	p_sibling_cross_penalty_sec: float = 0.0
) -> Dictionary:
	var violations: Array[String] = []
	var hold_thumb_collisions: int = 0
	var same_thumb_chords: int = 0
	var same_thumb_gap_violations: int = 0
	var three_finger_violations: int = 0

	if p_chart == null:
		violations.append("ChartData is null.")
		return {
			"valid": false,
			"violations": violations,
			"hold_thumb_collisions": 0,
			"same_thumb_chords": 0,
			"same_thumb_gap_violations": 0,
			"three_finger_violations": 0,
		}

	var safe_margin: float = maxf(0.0, p_release_margin_sec)
	var last_note_time: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var last_note_lane: PackedInt32Array = PackedInt32Array([-1, -1])
	var active_hold_end: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var active_hold_lane: PackedInt32Array = PackedInt32Array([-1, -1])

	var note_count: int = p_chart.notes.size()
	for i: int in range(note_count):
		var note: NoteData = p_chart.notes[i]
		if note == null:
			violations.append("notes[%d] is null." % i)
			continue

		var thumb: int = lane_to_thumb(note.lane)
		if last_note_time[thumb] >= 0.0:
			var dt: float = note.time_sec - last_note_time[thumb]
			if dt <= TIME_DEDUP_EPSILON_SEC:
				same_thumb_chords += 1
				violations.append(
					"Same-thumb chord at %.4fs on thumb %d (lanes %d and %d)."
					% [note.time_sec, thumb, last_note_lane[thumb], note.lane]
				)
			elif p_same_thumb_min_gap_sec > 0.0:
				var req_gap: float = p_same_thumb_min_gap_sec
				if last_note_lane[thumb] >= 0 and last_note_lane[thumb] != note.lane:
					req_gap += p_sibling_cross_penalty_sec
				if dt < req_gap - 0.001:
					same_thumb_gap_violations += 1
					violations.append(
						"Same-thumb gap violation at %.4fs on thumb %d (dt=%.4fs < %.4fs, lanes %d->%d)."
						% [note.time_sec, thumb, dt, req_gap, last_note_lane[thumb], note.lane]
					)

		if active_hold_end[thumb] >= 0.0:
			var lock_until: float = active_hold_end[thumb] + safe_margin
			if note.time_sec < lock_until - ERGONOMIC_EPSILON_SEC:
				hold_thumb_collisions += 1
				violations.append(
					"Intra-thumb Hold collision at %.4fs (lane %d) during active Hold on lane %d (lock until %.4fs)."
					% [note.time_sec, note.lane, active_hold_lane[thumb], lock_until]
				)

		last_note_time[thumb] = note.time_sec
		last_note_lane[thumb] = note.lane

		if note.duration_sec > 0.0:
			var hold_end_sec: float = note.time_sec + note.duration_sec
			if hold_end_sec > active_hold_end[thumb]:
				active_hold_end[thumb] = hold_end_sec
				active_hold_lane[thumb] = note.lane

	# Check maximum simultaneous finger load across all timestamps (active holds incl. release margin + new presses <= 2)
	var group_start: int = 0
	while group_start < note_count:
		var anchor_note: NoteData = p_chart.notes[group_start]
		if anchor_note == null:
			group_start += 1
			continue
		var t_group: float = anchor_note.time_sec
		var group_end: int = group_start + 1
		while group_end < note_count:
			var next_note: NoteData = p_chart.notes[group_end]
			if next_note != null and absf(next_note.time_sec - t_group) <= TIME_DEDUP_EPSILON_SEC:
				group_end += 1
			else:
				break
		var presses_at_t: int = group_end - group_start
		var prior_active_holds: int = 0
		for h_idx: int in range(group_start):
			var prev_note: NoteData = p_chart.notes[h_idx]
			if prev_note != null and prev_note.duration_sec > 0.0:
				var prev_lock_until: float = prev_note.time_sec + prev_note.duration_sec + safe_margin
				if t_group < prev_lock_until - ERGONOMIC_EPSILON_SEC:
					prior_active_holds += 1
		if prior_active_holds + presses_at_t > 2:
			three_finger_violations += 1
			violations.append(
				"Three-finger simultaneous load at %.4fs (%d active holds + %d presses)."
				% [t_group, prior_active_holds, presses_at_t]
			)
		group_start = group_end

	return {
		"valid": violations.is_empty(),
		"violations": violations,
		"hold_thumb_collisions": hold_thumb_collisions,
		"same_thumb_chords": same_thumb_chords,
		"same_thumb_gap_violations": same_thumb_gap_violations,
		"three_finger_violations": three_finger_violations,
	}


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
	var beat_phase_sec: float = 0.0
	if p_analysis.has("beat_phase_sec"):
		beat_phase_sec = fposmod(p_analysis.get("beat_phase_sec", 0.0) as float, beat_sec)
	else:
		beat_phase_sec = AudioAnalyzer.estimate_beat_phase_sec(onset_frames, hop_sec, bpm_estimate)

	var intensity_blocks: Array[IntensityBlock] = _build_intensity_blocks(
		rms_frames,
		hop_sec,
		duration_sec,
		beat_sec
	)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = p_seed

	var raw_candidates: Array[Dictionary] = _pick_quantized_peaks(
		onset_frames,
		bass_frames,
		mid_frames,
		high_frames,
		hop_sec,
		duration_sec,
		beat_sec,
		beat_phase_sec,
		p_difficulty,
		intensity_blocks
	)

	var allow_chords: bool = (
		p_note_type_mode == NoteTypeMode.DOUBLE_TAP
		or p_note_type_mode == NoteTypeMode.HOLD_AND_DOUBLE_TAP
	)
	var allow_holds: bool = (
		p_note_type_mode == NoteTypeMode.TAP_AND_HOLD
		or p_note_type_mode == NoteTypeMode.HOLD_AND_DOUBLE_TAP
	)
	var is_combined_mode: bool = p_note_type_mode == NoteTypeMode.HOLD_AND_DOUBLE_TAP

	var release_margin_sec: float = get_release_margin_for_difficulty(p_difficulty)
	var same_thumb_min_gap_sec: float = get_same_thumb_min_gap_for_difficulty(p_difficulty)
	var sibling_cross_penalty_sec: float = get_sibling_cross_penalty_for_difficulty(p_difficulty)

	var notes: Array[NoteData] = []
	if is_combined_mode:
		notes = _generate_balanced_hold_and_double_notes(
			raw_candidates,
			rms_frames,
			hop_sec,
			duration_sec,
			beat_sec,
			p_difficulty,
			intensity_blocks,
			release_margin_sec,
			same_thumb_min_gap_sec,
			sibling_cross_penalty_sec,
			rng
		)
	else:
		notes = _assign_lanes_ergonomically(
			raw_candidates,
			p_difficulty,
			allow_chords,
			rng
		)

		if allow_holds:
			_apply_hold_durations(
				notes,
				rms_frames,
				hop_sec,
				duration_sec,
				beat_sec,
				p_difficulty,
				intensity_blocks,
				release_margin_sec
			)
		else:
			var note_count: int = notes.size()
			for i: int in range(note_count):
				notes[i].duration_sec = 0.0

	notes = _sanitize_two_thumb_ergonomics(
		notes,
		release_margin_sec,
		same_thumb_min_gap_sec,
		sibling_cross_penalty_sec,
		allow_chords,
		is_combined_mode
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
	p_beat_sec: float,
	p_beat_phase_sec: float,
	p_difficulty: int,
	p_intensity_blocks: Array[IntensityBlock]
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var frame_count: int = p_onset_frames.size()
	if frame_count < 3:
		return candidates

	var max_allowed_time_sec: float = maxf(0.0, p_duration_sec - TRACK_END_MARGIN_SEC)

	for i: int in range(1, frame_count - 1):
		var curr: float = p_onset_frames[i]
		var prev_o: float = p_onset_frames[i - 1]
		var next_o: float = p_onset_frames[i + 1]
		if curr < prev_o or curr < next_o:
			continue

		var delta: float = 0.0
		var denom: float = prev_o - (2.0 * curr) + next_o
		if denom < -0.00001:
			delta = clampf((0.5 * (prev_o - next_o)) / denom, -0.5, 0.5)

		var raw_time_sec: float = maxf(
			0.0,
			((float(i) + delta) * p_hop_sec) - ONSET_LEAD_COMPENSATION_SEC
		)
		var tier: int = _get_tier_at_time(raw_time_sec, p_intensity_blocks)
		var threshold_bias: float = _get_threshold_bias_for_difficulty_and_tier(p_difficulty, tier)

		var w_start: int = maxi(0, i - LOCAL_WINDOW_RADIUS_FRAMES)
		var w_end: int = mini(frame_count - 1, i + LOCAL_WINDOW_RADIUS_FRAMES)
		var local_sum: float = 0.0
		var local_count: int = (w_end - w_start) + 1
		for k: int in range(w_start, w_end + 1):
			local_sum += p_onset_frames[k]
		var local_mean: float = local_sum / float(maxi(1, local_count))
		var local_mean_weight: float = _get_local_mean_weight_for_tier(tier)

		if curr < (local_mean * local_mean_weight) + threshold_bias:
			continue

		var grid_step_sec: float = _get_grid_step_for_difficulty_and_tier(p_beat_sec, p_difficulty, tier)
		var min_note_gap_sec: float = _get_min_gap_for_difficulty_and_tier(p_beat_sec, p_difficulty, tier)

		var grid_idx: float = round((raw_time_sec - p_beat_phase_sec) / grid_step_sec)
		var grid_time_sec: float = p_beat_phase_sec + (grid_idx * grid_step_sec)
		var snap_tolerance_sec: float = minf(ELASTIC_SNAP_GRID_RATIO * grid_step_sec, ELASTIC_SNAP_MAX_SEC)

		var final_time_sec: float = raw_time_sec
		if absf(raw_time_sec - grid_time_sec) <= snap_tolerance_sec:
			final_time_sec = grid_time_sec
		final_time_sec = clampf(final_time_sec, 0.0, max_allowed_time_sec)

		var bass_val: float = p_bass_frames[i] if i < p_bass_frames.size() else 0.0
		var mid_val: float = p_mid_frames[i] if i < p_mid_frames.size() else 0.0
		var high_val: float = p_high_frames[i] if i < p_high_frames.size() else 0.0
		var strength: float = clampf(maxf(0.25, curr), 0.0, 1.0)

		var cand: Dictionary = {
			"time_sec": final_time_sec,
			"frame_index": i,
			"strength": strength,
			"bass": bass_val,
			"mid": mid_val,
			"high": high_val,
			"tier": tier,
		}

		if not candidates.is_empty():
			var last_idx: int = candidates.size() - 1
			var prev_cand: Dictionary = candidates[last_idx]
			var prev_time_sec: float = prev_cand["time_sec"] as float
			var prev_strength: float = prev_cand["strength"] as float

			if final_time_sec - prev_time_sec < min_note_gap_sec - TIME_DEDUP_EPSILON_SEC:
				if strength > prev_strength * DOMINANT_PEAK_REPLACE_RATIO:
					var safe_replace: bool = true
					if last_idx >= 1:
						var earlier_time_sec: float = candidates[last_idx - 1]["time_sec"] as float
						if final_time_sec - earlier_time_sec < min_note_gap_sec - TIME_DEDUP_EPSILON_SEC:
							safe_replace = false
					if safe_replace:
						candidates[last_idx] = cand
				continue

		candidates.append(cand)

	candidates.sort_custom(_compare_candidates_chronologically)
	return candidates


func _assign_lanes_ergonomically(
	p_candidates: Array[Dictionary],
	p_difficulty: int,
	p_allow_chords: bool,
	p_rng: RandomNumberGenerator
) -> Array[NoteData]:
	var generated_notes: Array[NoteData] = []
	var same_thumb_min_gap: float = get_same_thumb_min_gap_for_difficulty(p_difficulty)
	var sibling_cross_penalty: float = get_sibling_cross_penalty_for_difficulty(p_difficulty)

	var chord_strength_threshold: float = _compute_adaptive_chord_threshold(
		p_candidates,
		p_difficulty,
		p_allow_chords
	)
	var base_chord_cooldown_sec: float = _get_chord_cooldown_for_difficulty(p_difficulty, false)
	var drop_chord_cooldown_sec: float = _get_chord_cooldown_for_difficulty(p_difficulty, true)

	var thumb_last_time: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var thumb_last_lane: PackedInt32Array = PackedInt32Array([-1, -1])
	var last_thumb: int = -1
	var last_chord_time: float = -999.0

	var candidate_count: int = p_candidates.size()
	for i: int in range(candidate_count):
		var item: Dictionary = p_candidates[i]
		var t_sec: float = item["time_sec"] as float
		var strength: float = item["strength"] as float
		var bass_val: float = item["bass"] as float
		var mid_val: float = item["mid"] as float
		var high_val: float = item["high"] as float
		var tier: int = item["tier"] as int

		var active_chord_cooldown: float = drop_chord_cooldown_sec if tier >= 2 else base_chord_cooldown_sec
		var active_chord_threshold: float = chord_strength_threshold * (0.90 if tier >= 2 else 1.0)
		var chord_tier_ok: bool = tier >= 1 or chord_strength_threshold <= 0.76

		if (
			p_allow_chords
			and chord_tier_ok
			and strength >= active_chord_threshold
			and (t_sec - last_chord_time) >= active_chord_cooldown
		):
			var left_lane: int = _choose_lane_within_thumb(
				THUMB_LEFT,
				bass_val,
				mid_val,
				high_val,
				thumb_last_lane[THUMB_LEFT],
				p_rng
			)
			var right_lane: int = _choose_lane_within_thumb(
				THUMB_RIGHT,
				bass_val,
				mid_val,
				high_val,
				thumb_last_lane[THUMB_RIGHT],
				p_rng
			)
			var left_ok: bool = _can_thumb_hit_lane(
				THUMB_LEFT,
				left_lane,
				t_sec,
				thumb_last_time,
				thumb_last_lane,
				same_thumb_min_gap,
				sibling_cross_penalty
			)
			if not left_ok:
				var left_alt: int = get_sibling_lane(left_lane)
				if _can_thumb_hit_lane(
					THUMB_LEFT,
					left_alt,
					t_sec,
					thumb_last_time,
					thumb_last_lane,
					same_thumb_min_gap,
					sibling_cross_penalty
				):
					left_lane = left_alt
					left_ok = true

			var right_ok: bool = _can_thumb_hit_lane(
				THUMB_RIGHT,
				right_lane,
				t_sec,
				thumb_last_time,
				thumb_last_lane,
				same_thumb_min_gap,
				sibling_cross_penalty
			)
			if not right_ok:
				var right_alt: int = get_sibling_lane(right_lane)
				if _can_thumb_hit_lane(
					THUMB_RIGHT,
					right_alt,
					t_sec,
					thumb_last_time,
					thumb_last_lane,
					same_thumb_min_gap,
					sibling_cross_penalty
				):
					right_lane = right_alt
					right_ok = true

			if left_ok and right_ok:
				generated_notes.append(NoteData.new(t_sec, left_lane, 0.0, strength))
				generated_notes.append(NoteData.new(t_sec, right_lane, 0.0, strength))
				thumb_last_time[THUMB_LEFT] = t_sec
				thumb_last_lane[THUMB_LEFT] = left_lane
				thumb_last_time[THUMB_RIGHT] = t_sec
				thumb_last_lane[THUMB_RIGHT] = right_lane
				last_chord_time = t_sec
				last_thumb = -1
				continue

		var preferred_thumb: int = _choose_preferred_thumb(
			bass_val,
			mid_val,
			high_val,
			last_thumb,
			p_rng
		)
		if last_thumb >= 0:
			var dt_from_last: float = t_sec - thumb_last_time[last_thumb]
			var fast_alternation_limit: float = same_thumb_min_gap + sibling_cross_penalty + 0.04
			if preferred_thumb == last_thumb and dt_from_last < fast_alternation_limit:
				preferred_thumb = 1 - last_thumb

		var chosen_lane: int = -1
		var thumb_order: PackedInt32Array = PackedInt32Array([preferred_thumb, 1 - preferred_thumb])
		for order_idx: int in range(2):
			var try_thumb: int = thumb_order[order_idx]
			var primary_lane: int = _choose_lane_within_thumb(
				try_thumb,
				bass_val,
				mid_val,
				high_val,
				thumb_last_lane[try_thumb],
				p_rng
			)
			var secondary_lane: int = get_sibling_lane(primary_lane)
			if _can_thumb_hit_lane(
				try_thumb,
				primary_lane,
				t_sec,
				thumb_last_time,
				thumb_last_lane,
				same_thumb_min_gap,
				sibling_cross_penalty
			):
				chosen_lane = primary_lane
				break
			if _can_thumb_hit_lane(
				try_thumb,
				secondary_lane,
				t_sec,
				thumb_last_time,
				thumb_last_lane,
				same_thumb_min_gap,
				sibling_cross_penalty
			):
				chosen_lane = secondary_lane
				break

		if chosen_lane < 0:
			continue

		var chosen_thumb: int = lane_to_thumb(chosen_lane)
		thumb_last_time[chosen_thumb] = t_sec
		thumb_last_lane[chosen_thumb] = chosen_lane
		last_thumb = chosen_thumb
		generated_notes.append(NoteData.new(t_sec, chosen_lane, 0.0, strength))

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


func _generate_balanced_hold_and_double_notes(
	p_candidates: Array[Dictionary],
	p_rms_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_duration_sec: float,
	p_beat_sec: float,
	p_difficulty: int,
	p_intensity_blocks: Array[IntensityBlock],
	p_release_margin_sec: float,
	p_same_thumb_min_gap_sec: float,
	p_sibling_cross_penalty_sec: float,
	p_rng: RandomNumberGenerator
) -> Array[NoteData]:
	var generated_notes: Array[NoteData] = []
	var candidate_count: int = p_candidates.size()
	if candidate_count == 0:
		return generated_notes

	var rms_count: int = p_rms_frames.size()
	var mean_rms: float = 0.5
	if rms_count > 0:
		var sum_rms: float = 0.0
		for r_idx: int in range(rms_count):
			sum_rms += p_rms_frames[r_idx]
		mean_rms = sum_rms / float(rms_count)
	var sustain_threshold: float = maxf(0.18, mean_rms * 0.72)

	var max_hold_cap_sec: float = get_max_hold_duration_for_difficulty(p_difficulty)
	var musical_max_hold_sec: float = minf(
		max_hold_cap_sec,
		maxf(MIN_HOLD_DURATION_SEC + 0.20, p_beat_sec * 2.25)
	)
	var hold_cooldown_sec: float = maxf(
		p_release_margin_sec,
		minf(HOLD_CASCADE_COOLDOWN_SEC, p_beat_sec * 0.55)
	)

	var chord_strength_threshold: float = _compute_adaptive_chord_threshold(
		p_candidates,
		p_difficulty,
		true
	)
	var min_ergonomic_double_gap: float = p_same_thumb_min_gap_sec + p_sibling_cross_penalty_sec + 0.04
	var base_chord_cooldown_sec: float = maxf(
		min_ergonomic_double_gap,
		minf(_get_chord_cooldown_for_difficulty(p_difficulty, false), p_beat_sec * 1.25)
	)
	var drop_chord_cooldown_sec: float = maxf(
		min_ergonomic_double_gap,
		minf(_get_chord_cooldown_for_difficulty(p_difficulty, true), p_beat_sec * 0.95)
	)
	var opp_hold_lead_sec: float = maxf(
		COMBINED_MIN_HOLD_OPPOSITE_LEAD_SEC,
		p_same_thumb_min_gap_sec * 0.80
	)
	var opp_hold_min_tap_gap: float = maxf(
		p_same_thumb_min_gap_sec + p_sibling_cross_penalty_sec,
		p_beat_sec * (0.45 if p_difficulty != Difficulty.HARD else 0.35)
	)

	var thumb_last_time: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var thumb_last_lane: PackedInt32Array = PackedInt32Array([-1, -1])
	var active_hold_start: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var active_hold_end: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var active_hold_lock_until: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var opp_hold_tail_guard_sec: float = maxf(0.04, p_same_thumb_min_gap_sec * 0.35)

	var last_thumb: int = -1
	var last_hold_thumb: int = -1
	var global_last_hold_end: float = -999.0
	var last_chord_time: float = -999.0

	var event_count: int = 0
	var hold_events: int = 0
	var double_events: int = 0
	var single_events: int = 0
	var events_since_last_hold: int = 2
	var events_since_last_double: int = 1
	var opp_taps_during_hold: int = 0

	for i: int in range(candidate_count):
		var item: Dictionary = p_candidates[i]
		var t_sec: float = item["time_sec"] as float
		var strength: float = item["strength"] as float
		var bass_val: float = item["bass"] as float
		var mid_val: float = item["mid"] as float
		var high_val: float = item["high"] as float
		var tier: int = item["tier"] as int

		var left_hold_busy: bool = t_sec < active_hold_lock_until[THUMB_LEFT] - ERGONOMIC_EPSILON_SEC
		var right_hold_busy: bool = t_sec < active_hold_lock_until[THUMB_RIGHT] - ERGONOMIC_EPSILON_SEC

		# Rule 1 & 2: While a Hold is active (including release margin), NEVER emit a Double Tap
		# and NEVER cancel the Hold; instead allow ergonomic Single Taps on the opposite thumb.
		if left_hold_busy or right_hold_busy:
			if left_hold_busy and right_hold_busy:
				continue
			var busy_thumb: int = THUMB_LEFT if left_hold_busy else THUMB_RIGHT
			var free_thumb: int = 1 - busy_thumb
			if (t_sec - active_hold_start[busy_thumb]) < opp_hold_lead_sec - ERGONOMIC_EPSILON_SEC:
				continue
			if t_sec > active_hold_end[busy_thumb] - opp_hold_tail_guard_sec + ERGONOMIC_EPSILON_SEC:
				continue
			if (
				thumb_last_time[free_thumb] >= 0.0
				and (t_sec - thumb_last_time[free_thumb]) < opp_hold_min_tap_gap - ERGONOMIC_EPSILON_SEC
			):
				continue
			var max_opp_taps: int = 1 if (event_count >= 4 and (float(single_events) / float(event_count)) >= 0.42) else 2
			if opp_taps_during_hold >= max_opp_taps:
				continue

			var free_lane: int = _find_playable_lane_on_thumb(
				free_thumb,
				t_sec,
				bass_val,
				mid_val,
				high_val,
				thumb_last_time,
				thumb_last_lane,
				p_same_thumb_min_gap_sec,
				p_sibling_cross_penalty_sec,
				p_rng
			)
			if free_lane >= 0:
				generated_notes.append(NoteData.new(t_sec, free_lane, 0.0, strength))
				thumb_last_time[free_thumb] = t_sec
				thumb_last_lane[free_thumb] = free_lane
				last_thumb = free_thumb
				event_count += 1
				single_events += 1
				events_since_last_hold += 1
				events_since_last_double += 1
				opp_taps_during_hold += 1
			continue

		# Both thumbs are free and rested past any previous Hold release margin.
		var hold_ratio: float = float(hold_events) / float(maxi(1, event_count))
		var double_ratio: float = float(double_events) / float(maxi(1, event_count))
		var single_ratio: float = float(single_events) / float(maxi(1, event_count))
		var hold_deficit: float = COMBINED_TARGET_HOLD_RATIO - (float(hold_events) / float(event_count + 2))
		var double_deficit: float = COMBINED_TARGET_DOUBLE_RATIO - (float(double_events) / float(event_count + 2))

		var force_single_for_balance: bool = (
			event_count >= 3
			and single_ratio < COMBINED_MIN_SINGLE_RATIO
			and hold_deficit < 0.09
			and double_deficit < 0.09
		)

		var left_lane: int = _find_playable_lane_on_thumb(
			THUMB_LEFT,
			t_sec,
			bass_val,
			mid_val,
			high_val,
			thumb_last_time,
			thumb_last_lane,
			p_same_thumb_min_gap_sec,
			p_sibling_cross_penalty_sec,
			p_rng
		)
		var right_lane: int = _find_playable_lane_on_thumb(
			THUMB_RIGHT,
			t_sec,
			bass_val,
			mid_val,
			high_val,
			thumb_last_time,
			thumb_last_lane,
			p_same_thumb_min_gap_sec,
			p_sibling_cross_penalty_sec,
			p_rng
		)

		var active_chord_cooldown: float = drop_chord_cooldown_sec if tier >= 2 else base_chord_cooldown_sec
		var active_chord_threshold: float = chord_strength_threshold * (0.90 if tier >= 2 else 1.0)
		var double_cooldown_ok: bool = (t_sec - last_chord_time) >= active_chord_cooldown - ERGONOMIC_EPSILON_SEC
		var double_cap_ok: bool = event_count < 2 or double_ratio < COMBINED_MAX_DOUBLE_RATIO
		var double_wanted: bool = (
			(strength >= active_chord_threshold and double_deficit >= -0.025)
			or double_deficit >= 0.035
			or (events_since_last_double >= 4 and double_deficit >= -0.01)
		)
		var can_double: bool = (
			not force_single_for_balance
			and left_lane >= 0
			and right_lane >= 0
			and double_cooldown_ok
			and double_cap_ok
			and double_wanted
		)

		var remaining_song_sec: float = (p_duration_sec - TRACK_END_MARGIN_SEC) - t_sec
		var max_hold_here: float = minf(musical_max_hold_sec, remaining_song_sec)
		var hold_cooldown_ok: bool = t_sec >= global_last_hold_end + hold_cooldown_sec - ERGONOMIC_EPSILON_SEC
		var hold_cap_ok: bool = event_count < 2 or hold_ratio < COMBINED_MAX_HOLD_RATIO

		var preferred_hold_thumb: int = (
			(1 - last_hold_thumb)
			if last_hold_thumb >= 0
			else _choose_preferred_thumb(bass_val, mid_val, high_val, last_thumb, p_rng)
		)
		var hold_lane: int = left_lane if preferred_hold_thumb == THUMB_LEFT else right_lane
		if hold_lane < 0:
			hold_lane = right_lane if preferred_hold_thumb == THUMB_LEFT else left_lane

		var sustain_sec: float = 0.0
		var hold_duration_sec: float = 0.0
		if (
			not force_single_for_balance
			and hold_lane >= 0
			and max_hold_here >= MIN_HOLD_DURATION_SEC
			and hold_cooldown_ok
			and hold_cap_ok
		):
			sustain_sec = _measure_sustain_with_dip_tolerance(
				t_sec,
				max_hold_here,
				p_rms_frames,
				p_hop_sec,
				sustain_threshold
			)
			var force_musical_hold: bool = (
				hold_deficit >= 0.03
				or (events_since_last_hold >= 4 and hold_deficit >= -0.01)
			)
			var hold_wanted: bool = (
				(sustain_sec >= MIN_HOLD_DURATION_SEC and hold_deficit >= -0.025)
				or force_musical_hold
			)
			if hold_wanted:
				hold_duration_sec = _compute_combined_hold_duration(
					sustain_sec,
					max_hold_here,
					p_beat_sec,
					p_difficulty,
					tier,
					force_musical_hold
				)
		var can_hold: bool = hold_duration_sec >= MIN_HOLD_DURATION_SEC

		var choose_hold: bool = false
		var choose_double: bool = false
		if can_hold and can_double:
			if hold_deficit > double_deficit + 0.015:
				choose_hold = true
			elif double_deficit > hold_deficit + 0.015:
				choose_double = true
			elif events_since_last_hold > events_since_last_double:
				choose_hold = true
			elif events_since_last_double > events_since_last_hold:
				choose_double = true
			elif sustain_sec >= MIN_HOLD_DURATION_SEC:
				choose_hold = true
			else:
				choose_double = true
		elif can_hold:
			choose_hold = true
		elif can_double:
			choose_double = true

		if choose_hold:
			var hold_thumb: int = lane_to_thumb(hold_lane)
			var hold_end_sec: float = t_sec + hold_duration_sec
			generated_notes.append(NoteData.new(t_sec, hold_lane, hold_duration_sec, strength))
			thumb_last_time[hold_thumb] = t_sec
			thumb_last_lane[hold_thumb] = hold_lane
			active_hold_start[hold_thumb] = t_sec
			active_hold_end[hold_thumb] = hold_end_sec
			active_hold_lock_until[hold_thumb] = hold_end_sec + p_release_margin_sec
			global_last_hold_end = maxf(global_last_hold_end, hold_end_sec)
			last_hold_thumb = hold_thumb
			last_thumb = hold_thumb
			opp_taps_during_hold = 0
			event_count += 1
			hold_events += 1
			events_since_last_hold = 0
			events_since_last_double += 1
			continue

		if choose_double:
			generated_notes.append(NoteData.new(t_sec, left_lane, 0.0, strength))
			generated_notes.append(NoteData.new(t_sec, right_lane, 0.0, strength))
			thumb_last_time[THUMB_LEFT] = t_sec
			thumb_last_lane[THUMB_LEFT] = left_lane
			thumb_last_time[THUMB_RIGHT] = t_sec
			thumb_last_lane[THUMB_RIGHT] = right_lane
			last_chord_time = t_sec
			last_thumb = -1
			event_count += 1
			double_events += 1
			events_since_last_double = 0
			events_since_last_hold += 1
			continue

		# If Double Tap has a strong deficit and one thumb only needs a brief rest before the next close beat,
		# skip an off-beat single that would re-lock the alternate thumb and starve Double Taps on fast tracks.
		if (
			double_deficit >= 0.07
			and double_cooldown_ok
			and double_cap_ok
			and (left_lane < 0 or right_lane < 0)
			and i + 1 < candidate_count
		):
			var next_t: float = p_candidates[i + 1]["time_sec"] as float
			var dt_to_next: float = next_t - t_sec
			if dt_to_next > 0.0 and dt_to_next <= p_beat_sec * 0.85:
				var both_ready_next: bool = (
					(thumb_last_time[THUMB_LEFT] < 0.0 or (next_t - thumb_last_time[THUMB_LEFT]) >= p_same_thumb_min_gap_sec + p_sibling_cross_penalty_sec - ERGONOMIC_EPSILON_SEC)
					and (thumb_last_time[THUMB_RIGHT] < 0.0 or (next_t - thumb_last_time[THUMB_RIGHT]) >= p_same_thumb_min_gap_sec + p_sibling_cross_penalty_sec - ERGONOMIC_EPSILON_SEC)
				)
				if both_ready_next:
					continue

		# Single Tap emission with natural alternating thumb ergonomics
		var preferred_thumb: int = _choose_preferred_thumb(
			bass_val,
			mid_val,
			high_val,
			last_thumb,
			p_rng
		)
		if last_thumb >= 0:
			var dt_from_last: float = t_sec - thumb_last_time[last_thumb]
			var fast_alternation_limit: float = p_same_thumb_min_gap_sec + p_sibling_cross_penalty_sec + 0.04
			if preferred_thumb == last_thumb and dt_from_last < fast_alternation_limit:
				preferred_thumb = 1 - last_thumb

		var chosen_lane: int = left_lane if preferred_thumb == THUMB_LEFT else right_lane
		if chosen_lane < 0:
			chosen_lane = right_lane if preferred_thumb == THUMB_LEFT else left_lane
		if chosen_lane < 0:
			continue

		var chosen_thumb: int = lane_to_thumb(chosen_lane)
		thumb_last_time[chosen_thumb] = t_sec
		thumb_last_lane[chosen_thumb] = chosen_lane
		last_thumb = chosen_thumb
		generated_notes.append(NoteData.new(t_sec, chosen_lane, 0.0, strength))
		event_count += 1
		single_events += 1
		events_since_last_hold += 1
		events_since_last_double += 1

	generated_notes.sort_custom(_compare_notes_chronologically)
	return generated_notes


func _find_playable_lane_on_thumb(
	p_thumb: int,
	p_time_sec: float,
	p_bass: float,
	p_mid: float,
	p_high: float,
	p_thumb_last_time: PackedFloat32Array,
	p_thumb_last_lane: PackedInt32Array,
	p_same_thumb_min_gap_sec: float,
	p_sibling_cross_penalty_sec: float,
	p_rng: RandomNumberGenerator
) -> int:
	var primary_lane: int = _choose_lane_within_thumb(
		p_thumb,
		p_bass,
		p_mid,
		p_high,
		p_thumb_last_lane[p_thumb],
		p_rng
	)
	if _can_thumb_hit_lane(
		p_thumb,
		primary_lane,
		p_time_sec,
		p_thumb_last_time,
		p_thumb_last_lane,
		p_same_thumb_min_gap_sec,
		p_sibling_cross_penalty_sec
	):
		return primary_lane
	var secondary_lane: int = get_sibling_lane(primary_lane)
	if _can_thumb_hit_lane(
		p_thumb,
		secondary_lane,
		p_time_sec,
		p_thumb_last_time,
		p_thumb_last_lane,
		p_same_thumb_min_gap_sec,
		p_sibling_cross_penalty_sec
	):
		return secondary_lane
	return -1


func _measure_sustain_with_dip_tolerance(
	p_time_sec: float,
	p_max_hold_sec: float,
	p_rms_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_sustain_threshold: float
) -> float:
	var rms_count: int = p_rms_frames.size()
	if rms_count == 0 or p_max_hold_sec < MIN_HOLD_DURATION_SEC:
		return 0.0
	var start_frame: int = clampi(int(round(p_time_sec / p_hop_sec)), 0, rms_count - 1)
	var max_frames: int = maxi(1, int(ceil(p_max_hold_sec / p_hop_sec)) + 1)
	var cursor: int = start_frame
	var scanned: int = 0
	var dip_streak: int = 0
	var last_strong_span: int = 0
	while cursor < rms_count and scanned < max_frames:
		scanned += 1
		if p_rms_frames[cursor] >= p_sustain_threshold:
			dip_streak = 0
			last_strong_span = scanned
		else:
			dip_streak += 1
			if dip_streak > COMBINED_HOLD_DIP_TOLERANCE_FRAMES:
				break
		cursor += 1
	return float(last_strong_span) * p_hop_sec


func _compute_combined_hold_duration(
	p_sustain_sec: float,
	p_max_allowed_sec: float,
	p_beat_sec: float,
	p_difficulty: int,
	p_tier: int,
	p_force_musical: bool
) -> float:
	if p_max_allowed_sec < MIN_HOLD_DURATION_SEC:
		return 0.0
	var hold_grid_sec: float = maxf(
		0.125,
		_get_grid_step_for_difficulty_and_tier(p_beat_sec, p_difficulty, p_tier)
	)
	if p_sustain_sec >= MIN_HOLD_DURATION_SEC:
		var quantized: float = floor(p_sustain_sec / hold_grid_sec) * hold_grid_sec
		if quantized < MIN_HOLD_DURATION_SEC:
			quantized = MIN_HOLD_DURATION_SEC
		return minf(quantized, p_max_allowed_sec)

	if not p_force_musical:
		return 0.0

	var beat_mult: float = 1.25 if p_tier <= 1 else 1.0
	var target_sec: float = clampf(
		p_beat_sec * beat_mult,
		MIN_HOLD_DURATION_SEC,
		minf(p_max_allowed_sec, maxf(MIN_HOLD_DURATION_SEC, p_beat_sec * 1.5))
	)
	var snapped_sec: float = round(target_sec / hold_grid_sec) * hold_grid_sec
	return clampf(snapped_sec, MIN_HOLD_DURATION_SEC, p_max_allowed_sec)


func _apply_hold_durations(
	p_notes: Array[NoteData],
	p_rms_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_duration_sec: float,
	p_beat_sec: float,
	p_difficulty: int,
	p_intensity_blocks: Array[IntensityBlock],
	p_release_margin_sec: float
) -> void:
	var rms_count: int = p_rms_frames.size()
	if rms_count == 0:
		return

	var sum_rms: float = 0.0
	for i: int in range(rms_count):
		sum_rms += p_rms_frames[i]
	var mean_rms: float = sum_rms / float(rms_count)
	var sustain_threshold: float = maxf(0.26, mean_rms * 0.88)
	var max_hold_cap_sec: float = get_max_hold_duration_for_difficulty(p_difficulty)
	var allow_parallel_holds: bool = p_difficulty == Difficulty.HARD

	var thumb_last_hold_end: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var global_last_hold_end: float = -999.0

	var note_count: int = p_notes.size()
	for i: int in range(note_count):
		var note: NoteData = p_notes[i]
		var is_chord_member: bool = (
			(i > 0 and absf(note.time_sec - p_notes[i - 1].time_sec) <= TIME_DEDUP_EPSILON_SEC)
			or (i + 1 < note_count and absf(p_notes[i + 1].time_sec - note.time_sec) <= TIME_DEDUP_EPSILON_SEC)
		)
		if is_chord_member:
			note.duration_sec = 0.0
			continue

		var thumb: int = lane_to_thumb(note.lane)
		if note.time_sec < thumb_last_hold_end[thumb] + HOLD_CASCADE_COOLDOWN_SEC:
			note.duration_sec = 0.0
			continue

		if not allow_parallel_holds and note.time_sec < global_last_hold_end + HOLD_CASCADE_COOLDOWN_SEC:
			note.duration_sec = 0.0
			continue

		var next_same_thumb_limit: float = p_duration_sec - TRACK_END_MARGIN_SEC
		for j: int in range(i + 1, note_count):
			if lane_to_thumb(p_notes[j].lane) == thumb:
				next_same_thumb_limit = minf(
					next_same_thumb_limit,
					p_notes[j].time_sec - p_release_margin_sec
				)
				break

		var max_possible_hold_sec: float = minf(
			max_hold_cap_sec,
			next_same_thumb_limit - note.time_sec
		)
		if max_possible_hold_sec < MIN_HOLD_DURATION_SEC:
			note.duration_sec = 0.0
			continue

		var start_frame: int = clampi(int(round(note.time_sec / p_hop_sec)), 0, rms_count - 1)
		var max_frames: int = maxi(1, int(ceil(max_possible_hold_sec / p_hop_sec)) + 1)
		var sustained_frames: int = 0
		var cursor: int = start_frame
		while cursor < rms_count and sustained_frames < max_frames and p_rms_frames[cursor] >= sustain_threshold:
			sustained_frames += 1
			cursor += 1

		var raw_sustain_sec: float = float(sustained_frames) * p_hop_sec
		var tier: int = _get_tier_at_time(note.time_sec, p_intensity_blocks)
		var hold_grid_sec: float = maxf(
			0.125,
			_get_grid_step_for_difficulty_and_tier(p_beat_sec, p_difficulty, tier)
		)
		var quantized_hold_sec: float = floor(raw_sustain_sec / hold_grid_sec) * hold_grid_sec
		var clamped_hold_sec: float = minf(quantized_hold_sec, max_possible_hold_sec)

		if clamped_hold_sec >= MIN_HOLD_DURATION_SEC:
			note.duration_sec = clamped_hold_sec
			var hold_end_sec: float = note.time_sec + clamped_hold_sec
			thumb_last_hold_end[thumb] = hold_end_sec
			global_last_hold_end = maxf(global_last_hold_end, hold_end_sec)
		else:
			note.duration_sec = 0.0


func _sanitize_two_thumb_ergonomics(
	p_notes: Array[NoteData],
	p_release_margin_sec: float,
	p_same_thumb_min_gap_sec: float,
	p_sibling_cross_penalty_sec: float,
	p_allow_chords: bool = true,
	p_protect_holds: bool = false
) -> Array[NoteData]:
	if p_notes.is_empty():
		return p_notes

	p_notes.sort_custom(_compare_notes_chronologically)

	var sanitized: Array[NoteData] = []
	var last_any_note_time: float = -999.0
	var thumb_last_time: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])
	var thumb_last_lane: PackedInt32Array = PackedInt32Array([-1, -1])
	var active_hold_idx: PackedInt32Array = PackedInt32Array([-1, -1])
	var active_hold_lock_until: PackedFloat32Array = PackedFloat32Array([-999.0, -999.0])

	var note_count: int = p_notes.size()
	for i: int in range(note_count):
		var note: NoteData = p_notes[i]
		if note == null:
			continue

		var t_sec: float = note.time_sec
		if not p_allow_chords and last_any_note_time >= 0.0 and absf(t_sec - last_any_note_time) <= TIME_DEDUP_EPSILON_SEC:
			continue

		var thumb: int = lane_to_thumb(note.lane)
		var opp_thumb: int = 1 - thumb

		var same_thumb_chord: bool = (
			thumb_last_time[thumb] >= 0.0
			and (t_sec - thumb_last_time[thumb]) <= TIME_DEDUP_EPSILON_SEC
		)
		if same_thumb_chord:
			if not p_allow_chords:
				continue
			var moved_lane: int = _try_find_free_lane_on_thumb(
				opp_thumb,
				t_sec,
				p_notes,
				i,
				thumb_last_time,
				thumb_last_lane,
				active_hold_lock_until,
				p_same_thumb_min_gap_sec,
				p_sibling_cross_penalty_sec
			)
			if moved_lane >= 0 and note.duration_sec <= 0.0:
				note.lane = moved_lane
				thumb = opp_thumb
				opp_thumb = 1 - thumb
			else:
				continue

		if active_hold_idx[thumb] >= 0 and t_sec < active_hold_lock_until[thumb] - ERGONOMIC_EPSILON_SEC:
			var moved_for_hold: int = -1
			if note.duration_sec <= 0.0:
				moved_for_hold = _try_find_free_lane_on_thumb(
					opp_thumb,
					t_sec,
					p_notes,
					i,
					thumb_last_time,
					thumb_last_lane,
					active_hold_lock_until,
					p_same_thumb_min_gap_sec,
					p_sibling_cross_penalty_sec
				)
			if moved_for_hold >= 0:
				note.lane = moved_for_hold
				thumb = opp_thumb
				opp_thumb = 1 - thumb
			elif p_protect_holds:
				# Preserve active Hold rather than cancelling/trimming it when a chord or tap collides.
				continue
			else:
				var prev_hold: NoteData = sanitized[active_hold_idx[thumb]]
				var trimmed_dur: float = (t_sec - p_release_margin_sec) - prev_hold.time_sec
				if trimmed_dur >= MIN_HOLD_DURATION_SEC:
					prev_hold.duration_sec = trimmed_dur
					active_hold_lock_until[thumb] = prev_hold.time_sec + trimmed_dur + p_release_margin_sec
				else:
					prev_hold.duration_sec = 0.0
					active_hold_idx[thumb] = -1
					active_hold_lock_until[thumb] = -999.0

		# Guarantee <= 2 simultaneous fingers (active holds incl. release margin + notes at t_sec <= 2)
		if p_protect_holds:
			var active_holds_now: int = 0
			if active_hold_idx[THUMB_LEFT] >= 0 and t_sec < active_hold_lock_until[THUMB_LEFT] - ERGONOMIC_EPSILON_SEC:
				active_holds_now += 1
			if active_hold_idx[THUMB_RIGHT] >= 0 and t_sec < active_hold_lock_until[THUMB_RIGHT] - ERGONOMIC_EPSILON_SEC:
				active_holds_now += 1
			var simultaneous_already_added: int = 0
			for rev_idx: int in range(sanitized.size() - 1, -1, -1):
				if absf(t_sec - sanitized[rev_idx].time_sec) <= TIME_DEDUP_EPSILON_SEC:
					simultaneous_already_added += 1
				else:
					break
			if active_holds_now + simultaneous_already_added + 1 > 2:
				continue

		if not _can_thumb_hit_lane(
			thumb,
			note.lane,
			t_sec,
			thumb_last_time,
			thumb_last_lane,
			p_same_thumb_min_gap_sec,
			p_sibling_cross_penalty_sec
		):
			var alt_lane_same: int = get_sibling_lane(note.lane)
			if _can_thumb_hit_lane(
				thumb,
				alt_lane_same,
				t_sec,
				thumb_last_time,
				thumb_last_lane,
				p_same_thumb_min_gap_sec,
				p_sibling_cross_penalty_sec
			):
				note.lane = alt_lane_same
			else:
				var moved_for_gap: int = -1
				if note.duration_sec <= 0.0:
					moved_for_gap = _try_find_free_lane_on_thumb(
						opp_thumb,
						t_sec,
						p_notes,
						i,
						thumb_last_time,
						thumb_last_lane,
						active_hold_lock_until,
						p_same_thumb_min_gap_sec,
						p_sibling_cross_penalty_sec
					)
				if moved_for_gap >= 0:
					note.lane = moved_for_gap
					thumb = opp_thumb
				else:
					continue

		sanitized.append(note)
		last_any_note_time = t_sec
		thumb_last_time[thumb] = t_sec
		thumb_last_lane[thumb] = note.lane

		if note.duration_sec > 0.0:
			var lock_until: float = t_sec + note.duration_sec + p_release_margin_sec
			if lock_until > active_hold_lock_until[thumb]:
				active_hold_idx[thumb] = sanitized.size() - 1
				active_hold_lock_until[thumb] = lock_until

	sanitized.sort_custom(_compare_notes_chronologically)
	return sanitized


func _try_find_free_lane_on_thumb(
	p_target_thumb: int,
	p_time_sec: float,
	p_all_notes: Array[NoteData],
	p_current_index: int,
	p_thumb_last_time: PackedFloat32Array,
	p_thumb_last_lane: PackedInt32Array,
	p_active_hold_lock_until: PackedFloat32Array,
	p_same_thumb_min_gap_sec: float,
	p_sibling_cross_penalty_sec: float
) -> int:
	if p_time_sec < p_active_hold_lock_until[p_target_thumb] - ERGONOMIC_EPSILON_SEC:
		return -1
	if (
		p_thumb_last_time[p_target_thumb] >= 0.0
		and (p_time_sec - p_thumb_last_time[p_target_thumb]) <= TIME_DEDUP_EPSILON_SEC
	):
		return -1

	var total_notes: int = p_all_notes.size()
	for k: int in range(p_current_index + 1, total_notes):
		var future_note: NoteData = p_all_notes[k]
		if future_note == null:
			continue
		if future_note.time_sec - p_time_sec > TIME_DEDUP_EPSILON_SEC:
			break
		if lane_to_thumb(future_note.lane) == p_target_thumb:
			return -1

	var first_lane: int = 0 if p_target_thumb == THUMB_LEFT else 2
	var second_lane: int = first_lane + 1
	if p_thumb_last_lane[p_target_thumb] == first_lane:
		var tmp_lane: int = first_lane
		first_lane = second_lane
		second_lane = tmp_lane

	if _can_thumb_hit_lane(
		p_target_thumb,
		first_lane,
		p_time_sec,
		p_thumb_last_time,
		p_thumb_last_lane,
		p_same_thumb_min_gap_sec,
		p_sibling_cross_penalty_sec
	):
		return first_lane
	if _can_thumb_hit_lane(
		p_target_thumb,
		second_lane,
		p_time_sec,
		p_thumb_last_time,
		p_thumb_last_lane,
		p_same_thumb_min_gap_sec,
		p_sibling_cross_penalty_sec
	):
		return second_lane
	return -1


func _can_thumb_hit_lane(
	p_thumb: int,
	p_lane: int,
	p_time_sec: float,
	p_thumb_last_time: PackedFloat32Array,
	p_thumb_last_lane: PackedInt32Array,
	p_same_thumb_min_gap_sec: float,
	p_sibling_cross_penalty_sec: float
) -> bool:
	var prev_time: float = p_thumb_last_time[p_thumb]
	if prev_time < 0.0:
		return true
	var dt: float = p_time_sec - prev_time
	if dt <= TIME_DEDUP_EPSILON_SEC:
		return false
	var required_gap: float = p_same_thumb_min_gap_sec
	if p_thumb_last_lane[p_thumb] >= 0 and p_thumb_last_lane[p_thumb] != p_lane:
		required_gap += p_sibling_cross_penalty_sec
	return dt >= required_gap - ERGONOMIC_EPSILON_SEC


func _choose_preferred_thumb(
	p_bass: float,
	p_mid: float,
	p_high: float,
	p_last_thumb: int,
	p_rng: RandomNumberGenerator
) -> int:
	if p_bass >= p_mid * 1.12 and p_bass >= p_high * 1.12:
		return THUMB_LEFT
	if p_high >= p_mid * 1.12 and p_high >= p_bass * 1.12:
		return THUMB_RIGHT
	if p_last_thumb >= 0:
		return 1 - p_last_thumb
	return THUMB_LEFT if (p_rng.randi() % 2) == 0 else THUMB_RIGHT


func _choose_lane_within_thumb(
	p_thumb: int,
	p_bass: float,
	p_mid: float,
	p_high: float,
	p_last_lane_on_thumb: int,
	p_rng: RandomNumberGenerator
) -> int:
	if p_thumb == THUMB_LEFT:
		if p_bass >= p_mid * 1.15:
			return 0
		if p_mid >= p_bass * 1.15:
			return 1
		if p_last_lane_on_thumb == 0 or p_last_lane_on_thumb == 1:
			return 1 - p_last_lane_on_thumb
		return 1 if (p_rng.randi() % 2) == 0 else 0

	if p_high >= p_mid * 1.15:
		return 3
	if p_mid >= p_high * 1.15:
		return 2
	if p_last_lane_on_thumb == 2 or p_last_lane_on_thumb == 3:
		return 5 - p_last_lane_on_thumb
	return 3 if (p_rng.randi() % 2) == 0 else 2


func _build_intensity_blocks(
	p_rms_frames: PackedFloat32Array,
	p_hop_sec: float,
	p_duration_sec: float,
	p_beat_sec: float
) -> Array[IntensityBlock]:
	var blocks: Array[IntensityBlock] = []
	var block_span_sec: float = maxf(1.5, p_beat_sec * float(DEFAULT_BLOCK_BEATS))
	var rms_count: int = p_rms_frames.size()

	var block_starts: PackedFloat32Array = PackedFloat32Array()
	var block_ends: PackedFloat32Array = PackedFloat32Array()
	var block_energies: PackedFloat32Array = PackedFloat32Array()

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

		block_starts.append(cursor_sec)
		block_ends.append(end_sec)
		block_energies.append(energy)
		cursor_sec = end_sec

	var block_count: int = block_energies.size()
	if block_count == 0:
		blocks.append(IntensityBlock.new(0.0, p_duration_sec, 0.35, 1))
		return blocks

	var min_e: float = 1.0
	var max_e: float = 0.0
	for b_idx: int in range(block_count):
		var e_val: float = block_energies[b_idx]
		min_e = minf(min_e, e_val)
		max_e = maxf(max_e, e_val)

	var use_relative_scale: bool = max_e >= 0.12 and (max_e - min_e) >= 0.06
	var inv_range: float = 1.0 / maxf(0.001, max_e - min_e)

	for b_idx: int in range(block_count):
		var raw_e: float = block_energies[b_idx]
		var effective_e: float = raw_e
		if use_relative_scale:
			var rel_e: float = clampf((raw_e - min_e) * inv_range, 0.0, 1.0)
			effective_e = lerpf(raw_e, rel_e, 0.72)
		var tier: int = _classify_energy_tier(effective_e)
		blocks.append(IntensityBlock.new(block_starts[b_idx], block_ends[b_idx], raw_e, tier))

	return blocks


func _compute_adaptive_chord_threshold(
	p_candidates: Array[Dictionary],
	p_difficulty: int,
	p_allow_chords: bool
) -> float:
	if not p_allow_chords:
		return 2.0

	var eligible_strengths: Array[float] = []
	var count: int = p_candidates.size()
	for i: int in range(count):
		var cand: Dictionary = p_candidates[i]
		if (cand["tier"] as int) >= 1:
			eligible_strengths.append(cand["strength"] as float)

	if eligible_strengths.is_empty():
		for i: int in range(count):
			eligible_strengths.append(p_candidates[i]["strength"] as float)

	if eligible_strengths.is_empty():
		match p_difficulty:
			Difficulty.EASY:
				return 0.72
			Difficulty.HARD:
				return 0.48
			_:
				return 0.60

	eligible_strengths.sort()
	var percentile: float = 0.60
	var min_clamp: float = 0.34
	var max_clamp: float = 0.66
	match p_difficulty:
		Difficulty.EASY:
			percentile = 0.78
			min_clamp = 0.42
			max_clamp = 0.76
		Difficulty.HARD:
			percentile = 0.42
			min_clamp = 0.26
			max_clamp = 0.56
		_:
			percentile = 0.60
			min_clamp = 0.34
			max_clamp = 0.66

	var idx: int = clampi(
		int(floor(float(eligible_strengths.size() - 1) * percentile)),
		0,
		eligible_strengths.size() - 1
	)
	return clampf(eligible_strengths[idx], min_clamp, max_clamp)


func _get_chord_cooldown_for_difficulty(p_difficulty: int, p_is_drop: bool) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return 1.55 if p_is_drop else 1.85
		Difficulty.HARD:
			return 0.42 if p_is_drop else 0.55
		_:
			return 0.80 if p_is_drop else 1.00


func _get_local_mean_weight_for_tier(p_tier: int) -> float:
	if p_tier >= 3:
		return 0.72
	if p_tier == 2:
		return 0.85
	if p_tier == 1:
		return 1.00
	return 1.08


func _get_tier_at_time(p_time_sec: float, p_blocks: Array[IntensityBlock]) -> int:
	var count: int = p_blocks.size()
	for i: int in range(count):
		var block: IntensityBlock = p_blocks[i]
		if p_time_sec >= block.start_sec and p_time_sec <= block.end_sec:
			return block.tier
	if count > 0:
		return p_blocks[count - 1].tier
	return 1


func _classify_energy_tier(p_energy: float) -> int:
	if p_energy >= 0.76:
		return 3
	if p_energy >= 0.52:
		return 2
	if p_energy >= 0.26:
		return 1
	return 0


func _get_grid_step_for_difficulty_and_tier(
	p_beat_sec: float,
	p_difficulty: int,
	p_tier: int
) -> float:
	match p_difficulty:
		Difficulty.EASY:
			return p_beat_sec
		Difficulty.HARD:
			return p_beat_sec * 0.25 if p_tier >= 2 else p_beat_sec * 0.5
		_:
			return p_beat_sec * 0.5


func _get_min_gap_for_difficulty_and_tier(
	p_beat_sec: float,
	p_difficulty: int,
	p_tier: int
) -> float:
	var is_drop: bool = p_tier >= 2
	match p_difficulty:
		Difficulty.EASY:
			return maxf(0.30, p_beat_sec * 0.72) if is_drop else maxf(0.38, p_beat_sec * 0.90)
		Difficulty.HARD:
			return maxf(0.11, p_beat_sec * 0.23) if is_drop else maxf(0.16, p_beat_sec * 0.36)
		_:
			return maxf(0.16, p_beat_sec * 0.38) if is_drop else maxf(0.22, p_beat_sec * 0.52)


func _get_threshold_bias_for_difficulty_and_tier(p_difficulty: int, p_tier: int) -> float:
	match p_difficulty:
		Difficulty.EASY:
			if p_tier >= 3:
				return 0.18
			if p_tier == 2:
				return 0.20
			if p_tier == 1:
				return 0.23
			return 0.26
		Difficulty.HARD:
			if p_tier >= 3:
				return 0.04
			if p_tier == 2:
				return 0.055
			if p_tier == 1:
				return 0.08
			return 0.10
		_:
			if p_tier >= 3:
				return 0.09
			if p_tier == 2:
				return 0.11
			if p_tier == 1:
				return 0.14
			return 0.16


func _compare_candidates_chronologically(p_a: Dictionary, p_b: Dictionary) -> bool:
	return (p_a["time_sec"] as float) < (p_b["time_sec"] as float)


func _compare_notes_chronologically(p_a: NoteData, p_b: NoteData) -> bool:
	if is_equal_approx(p_a.time_sec, p_b.time_sec):
		return p_a.lane < p_b.lane
	return p_a.time_sec < p_b.time_sec
