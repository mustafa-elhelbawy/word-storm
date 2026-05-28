extends Node2D

var _word_tray: WordTray


func _ready() -> void:
	_word_tray = $HUD/TrayBG/WordTray

	for child in get_children():
		if child.has_signal("pile_overflow"):
			child.pile_overflow.connect(GameManager.lose_life)
			child.tile_spawned.connect(_on_tile_spawned)

	_word_tray.tile_added.connect(_on_tray_changed)
	_word_tray.tile_removed.connect(_on_tray_changed)

	$HUD/ButtonsBG/SubmitButton.pressed.connect(_on_submit_pressed)
	$HUD/ButtonsBG/ClearButton.pressed.connect(_on_clear_pressed)
	$HUD/GameOverlay/PlayAgainButton.pressed.connect(_on_play_again_pressed)

	GameManager.life_lost.connect(_on_life_lost)
	GameManager.game_over.connect(_on_game_over)
	WordValidator.word_accepted.connect(_on_word_accepted)
	WordValidator.word_rejected.connect(_on_word_rejected)
	ScoreManager.score_changed.connect(_on_score_changed)

	ScoreManager.reset()
	GameManager.start_game(GameManager.SessionType.CLASSIC)
	_refresh_lives(GameManager.MAX_LIVES)
	_on_tray_changed(null)


func _on_tile_spawned(tile: LetterTile) -> void:
	tile.tile_tapped.connect(_on_tile_tapped)


func _on_tile_tapped(tile: LetterTile) -> void:
	if _word_tray.has_tile(tile):
		if tile == _word_tray.last_tile():
			_word_tray.remove_last()
	else:
		_word_tray.add_tile(tile)


func _on_submit_pressed() -> void:
	var w := _word_tray.word
	if w.length() < 3:
		return
	WordValidator.submit(w, _word_tray.get_tiles())


func _on_clear_pressed() -> void:
	_word_tray.clear()


func _on_word_accepted(word: String, score: int) -> void:
	var tiles := _word_tray.get_tiles()
	_word_tray.accept_and_destroy()
	for tile in tiles:
		tile.destroy()
	ScoreManager.add(score)


func _on_word_rejected(_word: String) -> void:
	_word_tray.clear()
	_flash_tray()


func _on_life_lost(lives: int) -> void:
	_refresh_lives(lives)


func _on_score_changed(new_score: int) -> void:
	$HUD/Header/ScoreLabel.text = str(new_score)


func _on_game_over() -> void:
	$HUD/GameOverlay.visible = true
	$HUD/GameOverlay/FinalScoreLabel.text = "Score: %d" % ScoreManager.current_score


func _on_play_again_pressed() -> void:
	$HUD/GameOverlay.visible = false
	_word_tray.accept_and_destroy()
	for child in get_children():
		if child.has_method("reset"):
			child.reset()
	ScoreManager.reset()
	GameManager.start_game(GameManager.SessionType.CLASSIC)
	_refresh_lives(GameManager.MAX_LIVES)


func _on_tray_changed(_tile) -> void:
	var w := _word_tray.word
	$HUD/ButtonsBG/SubmitButton.disabled = w.length() < 3
	$HUD/ButtonsBG/ClearButton.disabled = w.is_empty()


func _refresh_lives(lives: int) -> void:
	$HUD/Header/LivesLabel.text = "♥ × %d" % lives


func _flash_tray() -> void:
	var panel := $HUD/TrayBG
	var tween := create_tween()
	tween.tween_property(panel, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)
	tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
