extends Node2D

# Temporary test harness for Phase 2 gate — replaced by GameScreen in T015.

func _ready() -> void:
	for child in get_children():
		if child.has_signal("pile_overflow"):
			child.pile_overflow.connect(GameManager.lose_life)

	GameManager.life_lost.connect(func(lives: int) -> void:
		print("[TestScreen] Lives remaining: ", lives)
	)
	GameManager.speed_increased.connect(func(spd: float) -> void:
		print("[TestScreen] Speed up: ", spd, " px/s")
	)
	GameManager.game_over.connect(func() -> void:
		print("[TestScreen] GAME OVER")
	)

	GameManager.start_game(GameManager.SessionType.CLASSIC)
