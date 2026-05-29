extends CanvasLayer


func _ready() -> void:
	$BestScore.text = "Best: %d" % SaveGame.get_best_score()

	var today := Time.get_date_string_from_system().replace("-", "")
	var daily_score := SaveGame.get_daily_result(today)
	if daily_score >= 0:
		$DailyBadge.text = "Done Today ✓ (%d)" % daily_score
		$DailyButton.disabled = true
	else:
		$DailyBadge.text = "Today's challenge ready!"

	$PlayButton.pressed.connect(func():
		GameManager.start_game(GameManager.SessionType.CLASSIC))
	$DailyButton.pressed.connect(func():
		GameManager.start_game(GameManager.SessionType.DAILY))
	$SettingsButton.pressed.connect(_show_settings)


func _show_settings() -> void:
	var overlay := preload("res://scenes/overlays/SettingsOverlay.tscn").instantiate()
	add_child(overlay)
