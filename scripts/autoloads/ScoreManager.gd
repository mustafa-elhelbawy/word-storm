extends Node

signal score_changed(new_score: int)

var current_score: int = 0


func reset() -> void:
	current_score = 0
	score_changed.emit(0)


func add(points: int) -> void:
	current_score += points
	if current_score > GameManager.best_score:
		GameManager.best_score = current_score
	score_changed.emit(current_score)
