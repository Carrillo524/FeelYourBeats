class_name ChartData
extends Resource

@export var song_id: String = ""
@export var title: String = ""
@export var audio_path: String = ""
@export var duration_sec: float = 0.0
@export var bpm_estimate: float = 120.0
@export var offset_sec: float = 0.0
@export var notes: Array[NoteData] = []
@export var intensity_blocks: Array[IntensityBlock] = []


func _init(
	p_song_id: String = "",
	p_title: String = "",
	p_audio_path: String = "",
	p_duration_sec: float = 0.0,
	p_bpm_estimate: float = 120.0,
	p_offset_sec: float = 0.0,
	p_notes: Array[NoteData] = [],
	p_intensity_blocks: Array[IntensityBlock] = []
) -> void:
	song_id = p_song_id
	title = p_title
	audio_path = p_audio_path
	duration_sec = p_duration_sec
	bpm_estimate = p_bpm_estimate
	offset_sec = p_offset_sec
	notes = p_notes
	intensity_blocks = p_intensity_blocks


func validate() -> Dictionary:
	var errors: Array[String] = []
	var lane_last_start: Dictionary = {}
	var lane_last_end: Dictionary = {}
	var prev_note_time: float = -1.0

	var note_count: int = notes.size()
	for i: int in range(note_count):
		var note: NoteData = notes[i]
		if note == null:
			errors.append("notes[%d] is null." % i)
			continue

		if note.time_sec < 0.0:
			errors.append("notes[%d].time_sec (%f) must be >= 0.0." % [i, note.time_sec])

		if note.duration_sec < 0.0:
			errors.append("notes[%d].duration_sec (%f) must be >= 0.0." % [i, note.duration_sec])

		if note.strength < 0.0 or note.strength > 1.0:
			errors.append("notes[%d].strength (%f) must be in range 0.0..1.0." % [i, note.strength])

		var lane_valid: bool = note.lane >= NoteData.MIN_LANE and note.lane <= NoteData.MAX_LANE
		if not lane_valid:
			errors.append(
				"notes[%d].lane (%d) is out of valid range %d..%d."
				% [i, note.lane, NoteData.MIN_LANE, NoteData.MAX_LANE]
			)

		if prev_note_time >= 0.0 and note.time_sec < prev_note_time:
			errors.append(
				"notes[%d].time_sec (%f) violates ascending chronological order (previous: %f)."
				% [i, note.time_sec, prev_note_time]
			)
		prev_note_time = note.time_sec

		if lane_valid:
			var note_end_sec: float = note.time_sec + maxf(note.duration_sec, 0.0)
			if lane_last_end.has(note.lane):
				var prev_lane_start: float = lane_last_start[note.lane] as float
				var prev_lane_end: float = lane_last_end[note.lane] as float
				var overlaps_hold: bool = note.time_sec < prev_lane_end
				var overlaps_same_time: bool = is_equal_approx(note.time_sec, prev_lane_start)
				if overlaps_hold or overlaps_same_time:
					errors.append(
						"notes[%d] on lane %d at %f overlaps previous note in same lane (start: %f, end: %f)."
						% [i, note.lane, note.time_sec, prev_lane_start, prev_lane_end]
					)
			lane_last_start[note.lane] = note.time_sec
			lane_last_end[note.lane] = note_end_sec

	var prev_block_start: float = -1.0
	var prev_block_end: float = -1.0
	var block_count: int = intensity_blocks.size()
	for j: int in range(block_count):
		var block: IntensityBlock = intensity_blocks[j]
		if block == null:
			errors.append("intensity_blocks[%d] is null." % j)
			continue

		if block.start_sec < 0.0:
			errors.append(
				"intensity_blocks[%d].start_sec (%f) must be >= 0.0." % [j, block.start_sec]
			)

		if block.end_sec <= block.start_sec:
			errors.append(
				"intensity_blocks[%d].end_sec (%f) must be > start_sec (%f)."
				% [j, block.end_sec, block.start_sec]
			)

		if block.energy < 0.0 or block.energy > 1.0:
			errors.append(
				"intensity_blocks[%d].energy (%f) must be in range 0.0..1.0." % [j, block.energy]
			)

		if block.tier < IntensityBlock.MIN_TIER or block.tier > IntensityBlock.MAX_TIER:
			errors.append(
				"intensity_blocks[%d].tier (%d) is out of valid range %d..%d."
				% [j, block.tier, IntensityBlock.MIN_TIER, IntensityBlock.MAX_TIER]
			)

		if prev_block_start >= 0.0 and block.start_sec < prev_block_start:
			errors.append(
				"intensity_blocks[%d].start_sec (%f) violates ascending chronological order (previous start: %f)."
				% [j, block.start_sec, prev_block_start]
			)
		elif prev_block_end >= 0.0 and block.start_sec < prev_block_end:
			errors.append(
				"intensity_blocks[%d].start_sec (%f) overlaps previous block end_sec (%f)."
				% [j, block.start_sec, prev_block_end]
			)

		prev_block_start = block.start_sec
		prev_block_end = block.end_sec

	var result: Dictionary = {
		"valid": errors.is_empty(),
		"errors": errors,
	}
	return result
