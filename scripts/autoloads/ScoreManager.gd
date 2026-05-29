extends Node

signal score_updated(new_score: int, delta: int)
signal combo_changed(multiplier: float)

const BASE_SCORES: Dictionary = { 3: 10, 4: 25, 5: 50 }
const BASE_SCORE_LONG: int = 100
const COMBO_RESET_SECONDS: float = 6.0

# [min_consecutive, multiplier] — checked highest-first
const COMBO_TIERS: Array[Array] = [
	[6, 3.0],
	[4, 2.0],
	[2, 1.5],
	[0, 1.0],
]

var score: int = 0
var best_score: int = 0
var combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_active: bool = false


func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if _combo_active:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_expire_combo()


func reset() -> void:
	score = 0
	combo_count = 0
	_combo_timer = 0.0
	_combo_active = false
	best_score = SaveGame.get_best_score()
	score_updated.emit(0, 0)
	combo_changed.emit(1.0)


func award(tiles: Array) -> int:
	if tiles.is_empty():
		return 0
	var length := tiles.size()
	var base: int = BASE_SCORES.get(length, BASE_SCORE_LONG)

	var letter_sum: int = 0
	for tile in tiles:
		letter_sum += tile.point_value
	var letter_bonus: float = 1.0 + letter_sum * 0.1

	combo_count += 1
	_combo_timer = COMBO_RESET_SECONDS
	_combo_active = true
	var multiplier := _get_combo_multiplier()

	var points := int(base * multiplier * letter_bonus)
	score += points

	if score > best_score:
		best_score = score
		SaveGame.set_best_score(best_score)

	score_updated.emit(score, points)
	combo_changed.emit(multiplier)
	return points


func break_combo() -> void:
	combo_count = 0
	_combo_timer = 0.0
	_combo_active = false
	combo_changed.emit(1.0)


func _get_combo_multiplier() -> float:
	for tier in COMBO_TIERS:
		if combo_count >= tier[0]:
			return tier[1]
	return 1.0


func _expire_combo() -> void:
	combo_count = 0
	_combo_timer = 0.0
	_combo_active = false
	combo_changed.emit(1.0)
