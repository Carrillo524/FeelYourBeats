class_name HitJudge
extends Node

enum JudgmentGrade {
	PERFECT = 0,
	GREAT = 1,
	GOOD = 2,
	MISS = 3,
}

signal note_judged(lane: int, grade: int, error_ms: float, combo: int)
signal score_changed(score: int, combo: int, max_combo: int, accuracy: float)
signal hold_state_changed(lane: int, is_holding: bool)
signal hold_combo_ticked(p_lane: int, p_new_combo: int)
signal danger_changed(p_ratio: float)
signal danger_overflowed()

const LANE_COUNT: int = 4
const SEC_TO_MS: float = 1000.0
const HOLD_COMBO_TICK_INTERVAL_SEC: float = 0.25
const SCORE_HOLD_TICK: int = 150
const SCORE_PERFECT: int = 1000
const SCORE_GREAT: int = 700
const SCORE_GOOD: int = 400
const SCORE_MISS: int = 0
const WEIGHT_PERFECT: float = 1.0
const WEIGHT_GREAT: float = 0.75
const WEIGHT_GOOD: float = 0.40
const WEIGHT_MISS: float = 0.0

const DANGER_MISS_EASY: float = 0.08
const DANGER_RECOVERY_EASY: float = 0.045
const DANGER_MISS_NORMAL: float = 0.11
const DANGER_RECOVERY_NORMAL: float = 0.035
const DANGER_MISS_HARD: float = 0.15
const DANGER_RECOVERY_HARD: float = 0.025

@export var perfect_window_sec: float = 0.045
@export var great_window_sec: float = 0.090
@export var good_window_sec: float = 0.140
@export var miss_window_sec: float = 0.180
@export var hold_release_grace_sec: float = 0.120

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var accuracy: float = 0.0
var perfect_count: int = 0
var great_count: int = 0
var good_count: int = 0
var miss_count: int = 0
var danger_ratio: float = 0.0
var active_difficulty: int = AutoChartGenerator.Difficulty.NORMAL

var _chart: ChartData = null
var _lane_queues: Array[Array] = [[], [], [], []]
var _lane_cursors: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var _active_holds: Array[NoteData] = [null, null, null, null]
var _hold_last_tick_times: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _resolved_notes: Dictionary = {}
var _judged_count: int = 0
var _accuracy_weight_sum: float = 0.0
var _danger_overflow_emitted: bool = false


func load_chart(p_chart: ChartData) -> bool:
	if p_chart == null:
		return false

	var validation: Dictionary = p_chart.validate()
	var is_valid: bool = validation.get("valid", false) as bool
	if not is_valid:
		return false

	reset_state()
	_chart = p_chart

	var note_count: int = _chart.notes.size()
	for i: int in range(note_count):
		var note: NoteData = _chart.notes[i]
		if note != null and note.lane >= NoteData.MIN_LANE and note.lane <= NoteData.MAX_LANE:
			_lane_queues[note.lane].append(note)

	return true


func reset_state() -> void:
	for lane_idx: int in range(LANE_COUNT):
		if _active_holds[lane_idx] != null:
			_active_holds[lane_idx] = null
			hold_state_changed.emit(lane_idx, false)
		_hold_last_tick_times[lane_idx] = 0.0
		_lane_queues[lane_idx].clear()
		_lane_cursors[lane_idx] = 0

	_resolved_notes.clear()
	score = 0
	combo = 0
	max_combo = 0
	accuracy = 0.0
	perfect_count = 0
	great_count = 0
	good_count = 0
	miss_count = 0
	danger_ratio = 0.0
	_danger_overflow_emitted = false
	_judged_count = 0
	_accuracy_weight_sum = 0.0
	danger_changed.emit(danger_ratio)


func set_difficulty(p_difficulty: int) -> void:
	active_difficulty = clampi(
		p_difficulty,
		AutoChartGenerator.Difficulty.EASY,
		AutoChartGenerator.Difficulty.HARD
	)


func get_difficulty() -> int:
	return active_difficulty


func get_danger_ratio() -> float:
	return danger_ratio


func has_danger_overflowed() -> bool:
	return _danger_overflow_emitted


func on_lane_pressed(p_lane: int, p_dsp_time_sec: float) -> void:
	if p_lane < NoteData.MIN_LANE or p_lane > NoteData.MAX_LANE:
		return

	_expire_missed_notes_in_lane(p_lane, p_dsp_time_sec)

	var queue: Array = _lane_queues[p_lane]
	var cursor: int = _lane_cursors[p_lane]
	if cursor >= queue.size():
		return

	var candidate: NoteData = queue[cursor] as NoteData
	var delta_sec: float = p_dsp_time_sec - candidate.time_sec
	var abs_error_sec: float = absf(delta_sec)

	if abs_error_sec > miss_window_sec:
		return

	var grade: int = _classify_error(abs_error_sec)
	var error_ms: float = delta_sec * SEC_TO_MS
	_lane_cursors[p_lane] = cursor + 1

	if not candidate.is_hold():
		_resolved_notes[candidate] = true
		_apply_judgment(p_lane, grade, error_ms)
	else:
		_apply_judgment(p_lane, grade, error_ms)
		if grade != JudgmentGrade.MISS:
			_active_holds[p_lane] = candidate
			_hold_last_tick_times[p_lane] = maxf(p_dsp_time_sec, candidate.time_sec)
			hold_state_changed.emit(p_lane, true)
		else:
			_resolved_notes[candidate] = true


func on_lane_released(p_lane: int, p_dsp_time_sec: float) -> void:
	if p_lane < NoteData.MIN_LANE or p_lane > NoteData.MAX_LANE:
		return

	var hold_note: NoteData = _active_holds[p_lane]
	if hold_note == null:
		return

	_active_holds[p_lane] = null
	_hold_last_tick_times[p_lane] = 0.0
	_resolved_notes[hold_note] = true
	hold_state_changed.emit(p_lane, false)

	var end_time_sec: float = _get_note_end_time_sec(hold_note)
	var delta_end_sec: float = p_dsp_time_sec - end_time_sec
	var error_ms: float = delta_end_sec * SEC_TO_MS
	var grace_threshold_sec: float = end_time_sec - hold_release_grace_sec

	var release_grade: int = JudgmentGrade.MISS
	if p_dsp_time_sec >= grace_threshold_sec:
		release_grade = JudgmentGrade.PERFECT
	else:
		var early_shortfall_sec: float = grace_threshold_sec - p_dsp_time_sec
		if early_shortfall_sec <= great_window_sec:
			release_grade = JudgmentGrade.GREAT
		elif early_shortfall_sec <= good_window_sec:
			release_grade = JudgmentGrade.GOOD
		else:
			release_grade = JudgmentGrade.MISS

	_apply_judgment(p_lane, release_grade, error_ms)


func update_dsp_time(p_dsp_time_sec: float) -> void:
	for lane_idx: int in range(LANE_COUNT):
		var hold_note: NoteData = _active_holds[lane_idx]
		if hold_note != null:
			var end_time_sec: float = _get_note_end_time_sec(hold_note)
			if p_dsp_time_sec < end_time_sec:
				while (p_dsp_time_sec - _hold_last_tick_times[lane_idx]) >= HOLD_COMBO_TICK_INTERVAL_SEC:
					_hold_last_tick_times[lane_idx] += HOLD_COMBO_TICK_INTERVAL_SEC
					_apply_hold_combo_tick(lane_idx)
			else:
				while (_hold_last_tick_times[lane_idx] + HOLD_COMBO_TICK_INTERVAL_SEC) < (end_time_sec - 0.001):
					_hold_last_tick_times[lane_idx] += HOLD_COMBO_TICK_INTERVAL_SEC
					_apply_hold_combo_tick(lane_idx)
				_active_holds[lane_idx] = null
				_hold_last_tick_times[lane_idx] = 0.0
				_resolved_notes[hold_note] = true
				hold_state_changed.emit(lane_idx, false)
				_apply_judgment(lane_idx, JudgmentGrade.PERFECT, 0.0)

		_expire_missed_notes_in_lane(lane_idx, p_dsp_time_sec)


func is_note_resolved(p_note: NoteData) -> bool:
	if p_note == null:
		return true
	return _resolved_notes.has(p_note)


func is_note_actively_held(p_note: NoteData) -> bool:
	if p_note == null or p_note.lane < NoteData.MIN_LANE or p_note.lane > NoteData.MAX_LANE:
		return false
	return _active_holds[p_note.lane] == p_note


func is_lane_holding(p_lane: int) -> bool:
	if p_lane < NoteData.MIN_LANE or p_lane > NoteData.MAX_LANE:
		return false
	return _active_holds[p_lane] != null


func get_judgment_breakdown() -> Dictionary:
	return {
		"perfect": perfect_count,
		"great": great_count,
		"good": good_count,
		"miss": miss_count,
	}


func get_total_judged() -> int:
	return _judged_count


func get_accuracy_percent() -> float:
	if _judged_count <= 0:
		return 0.0
	return (_accuracy_weight_sum / float(_judged_count)) * 100.0


func _expire_missed_notes_in_lane(p_lane: int, p_dsp_time_sec: float) -> void:
	var queue: Array = _lane_queues[p_lane]
	var queue_size: int = queue.size()
	var cursor: int = _lane_cursors[p_lane]

	while cursor < queue_size:
		var note: NoteData = queue[cursor] as NoteData
		if p_dsp_time_sec > note.time_sec + miss_window_sec:
			cursor += 1
			_lane_cursors[p_lane] = cursor
			_resolved_notes[note] = true
			var error_ms: float = (p_dsp_time_sec - note.time_sec) * SEC_TO_MS
			_apply_judgment(p_lane, JudgmentGrade.MISS, error_ms)
		else:
			break


func _classify_error(p_abs_error_sec: float) -> int:
	if p_abs_error_sec <= perfect_window_sec:
		return JudgmentGrade.PERFECT
	if p_abs_error_sec <= great_window_sec:
		return JudgmentGrade.GREAT
	if p_abs_error_sec <= good_window_sec:
		return JudgmentGrade.GOOD
	return JudgmentGrade.MISS


func _apply_judgment(p_lane: int, p_grade: int, p_error_ms: float) -> void:
	_judged_count += 1
	match p_grade:
		JudgmentGrade.PERFECT:
			perfect_count += 1
			combo += 1
			score += SCORE_PERFECT
			_accuracy_weight_sum += WEIGHT_PERFECT
		JudgmentGrade.GREAT:
			great_count += 1
			combo += 1
			score += SCORE_GREAT
			_accuracy_weight_sum += WEIGHT_GREAT
		JudgmentGrade.GOOD:
			good_count += 1
			combo += 1
			score += SCORE_GOOD
			_accuracy_weight_sum += WEIGHT_GOOD
		_:
			miss_count += 1
			combo = 0
			score += SCORE_MISS
			_accuracy_weight_sum += WEIGHT_MISS

	if combo > max_combo:
		max_combo = combo

	accuracy = (_accuracy_weight_sum / float(_judged_count)) if _judged_count > 0 else 0.0
	_update_danger_for_grade(p_grade)
	note_judged.emit(p_lane, p_grade, p_error_ms, combo)
	score_changed.emit(score, combo, max_combo, accuracy)


func _update_danger_for_grade(p_grade: int) -> void:
	if _danger_overflow_emitted:
		return

	if p_grade == JudgmentGrade.MISS:
		danger_ratio = clampf(danger_ratio + _get_danger_miss_step(), 0.0, 1.0)
	else:
		danger_ratio = clampf(danger_ratio - _get_danger_recovery_step(), 0.0, 1.0)

	danger_changed.emit(danger_ratio)

	if danger_ratio >= 1.0 and not _danger_overflow_emitted:
		_danger_overflow_emitted = true
		danger_overflowed.emit()


func _get_danger_miss_step() -> float:
	match active_difficulty:
		AutoChartGenerator.Difficulty.EASY:
			return DANGER_MISS_EASY
		AutoChartGenerator.Difficulty.HARD:
			return DANGER_MISS_HARD
		_:
			return DANGER_MISS_NORMAL


func _get_danger_recovery_step() -> float:
	match active_difficulty:
		AutoChartGenerator.Difficulty.EASY:
			return DANGER_RECOVERY_EASY
		AutoChartGenerator.Difficulty.HARD:
			return DANGER_RECOVERY_HARD
		_:
			return DANGER_RECOVERY_NORMAL


func _apply_hold_combo_tick(p_lane: int) -> void:
	combo += 1
	if combo > max_combo:
		max_combo = combo
	score += SCORE_HOLD_TICK
	hold_combo_ticked.emit(p_lane, combo)
	score_changed.emit(score, combo, max_combo, accuracy)


func _get_note_end_time_sec(p_note: NoteData) -> float:
	return p_note.time_sec + maxf(0.0, p_note.duration_sec)
