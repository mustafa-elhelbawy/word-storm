extends CanvasLayer


func _ready() -> void:
	var final_score := ScoreManager.score
	var best := ScoreManager.best_score

	$FinalScoreLabel.text = "Score: %d" % final_score
	$BestScoreLabel.text = "Best: %d" % best

	var tween := create_tween()
	tween.tween_method(
		func(v: int) -> void: $FinalScoreLabel.text = "Score: %d" % v,
		0, final_score, 1.0
	)

	if final_score > 0 and final_score > best:
		$NewBestBadge.show()
		$NewBestBadge.scale = Vector2(0.5, 0.5)
		var badge_tween := create_tween()
		badge_tween.tween_property($NewBestBadge, "scale",
			Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT)

	# Save daily result if this was a daily session
	if GameManager.session_type == GameManager.SessionType.DAILY:
		var today := Time.get_date_string_from_system().replace("-", "")
		if SaveGame.get_daily_result(today) < 0:
			SaveGame.set_daily_result(today, final_score)

	if GameManager.session_type == GameManager.SessionType.DAILY:
		$AdSlot/ContinueAdButton.hide()
	else:
		$AdSlot/ContinueAdButton.show()
		$AdSlot/NoAdLabel.hide()
		AdManager.ad_unavailable.connect(_on_ad_unavailable, CONNECT_ONE_SHOT)
		AdManager.ad_reward_granted.connect(_on_ad_reward_granted, CONNECT_ONE_SHOT)
		AdManager.load_rewarded()

	$AdSlot/ContinueAdButton.pressed.connect(func(): AdManager.show_rewarded())
	$PlayAgainButton.pressed.connect(func():
		GameManager.start_game(GameManager.SessionType.CLASSIC))


func _on_ad_unavailable() -> void:
	$AdSlot/ContinueAdButton.hide()
	$AdSlot/NoAdLabel.show()
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(self):
		$AdSlot/NoAdLabel.hide()


func _on_ad_reward_granted() -> void:
	GameManager.lives = mini(GameManager.lives + 1, GameManager.MAX_LIVES)
	GameManager.continue_game()
