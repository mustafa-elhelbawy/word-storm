extends Node2D

var _word_tray: WordTray
var _displayed_score: int = 0
var _combo_popup_tween: Tween = null
var _score_tween: Tween = null


func _ready() -> void:
	_word_tray = $HUD/TrayBG/WordTray

	ParticleManager.set_effects_layer($EffectsLayer)

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
	GameManager.speed_increased.connect(_on_speed_increased)
	WordValidator.word_accepted.connect(_on_word_accepted)
	WordValidator.word_rejected.connect(_on_word_rejected)
	ScoreManager.score_updated.connect(_on_score_updated)
	ScoreManager.combo_changed.connect(_on_combo_changed)

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


func _on_word_accepted(_word: String, _raw_score: int) -> void:
	var tiles := _word_tray.get_tiles()
	_word_tray.accept_and_destroy()
	ScoreManager.award(tiles)
	for tile in tiles:
		ParticleManager.emit_burst(tile.global_position, tile.column_id)
		tile.destroy()
	AudioManager.play("word_valid")
	ParticleManager.flash($HUD/FlashOverlay, Color(0.0, 0.8, 0.3), 0.2)


func _on_word_rejected(_word: String) -> void:
	ScoreManager.break_combo()
	_word_tray.clear()
	_flash_tray()
	AudioManager.play("word_invalid")


func _on_life_lost(lives: int) -> void:
	_refresh_lives(lives)
	AudioManager.play("life_lost")
	ParticleManager.flash($HUD/FlashOverlay, Color(0.9, 0.1, 0.1), 0.3)


func _on_game_over() -> void:
	AudioManager.play("game_over")
	$HUD/GameOverlay.visible = true
	$HUD/GameOverlay/FinalScoreLabel.text = "Score: %d" % ScoreManager.score


func _on_speed_increased(_new_speed: float) -> void:
	# Columns handle their own speed via GameManager.speed_increased — just show banner
	_show_speed_banner()


func _on_score_updated(new_score: int, _delta: int) -> void:
	if _score_tween != null and _score_tween.is_valid():
		_score_tween.kill()
	var from := _displayed_score
	_displayed_score = new_score
	_score_tween = create_tween()
	_score_tween.tween_method(
		func(v: int) -> void: $HUD/Header/ScoreLabel.text = str(v),
		from,
		new_score,
		0.4
	)


func _on_combo_changed(multiplier: float) -> void:
	var indicator := $HUD/Header/ComboIndicator
	if multiplier <= 1.0:
		indicator.hide()
	else:
		indicator.text = "×%.1f" % multiplier
		indicator.show()
		var tween := create_tween()
		tween.tween_property(indicator, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(indicator, "scale", Vector2(1.0, 1.0), 0.1)
	_show_combo_popup(multiplier)


func _on_play_again_pressed() -> void:
	$HUD/GameOverlay.visible = false
	if _score_tween != null and _score_tween.is_valid():
		_score_tween.kill()
	_word_tray.accept_and_destroy()
	for child in get_children():
		if child.has_method("reset"):
			child.reset()
	_displayed_score = 0
	ScoreManager.reset()
	GameManager.start_game(GameManager.SessionType.CLASSIC)
	_refresh_lives(GameManager.MAX_LIVES)
	_on_tray_changed(null)


func _on_tray_changed(_tile) -> void:
	var w := _word_tray.word
	$HUD/ButtonsBG/SubmitButton.disabled = w.length() < 3
	$HUD/ButtonsBG/ClearButton.disabled = w.is_empty()


func _refresh_lives(lives: int) -> void:
	var container := $HUD/Header/LivesContainer
	var hearts := container.get_children()
	for i in hearts.size():
		# Dim hearts that are "lost" — e.g. with 2 lives remaining, heart at index 2 is dimmed
		hearts[i].modulate.a = 1.0 if i < lives else 0.2


func _show_combo_popup(multiplier: float) -> void:
	if multiplier <= 1.0:
		return
	if _combo_popup_tween != null and _combo_popup_tween.is_valid():
		_combo_popup_tween.kill()
	var label := $HUD/ComboPopup
	label.text = "+%.0f× COMBO!" % multiplier
	label.position.y = 510.0
	label.modulate.a = 1.0
	label.show()
	_combo_popup_tween = create_tween()
	_combo_popup_tween.set_parallel(true)
	_combo_popup_tween.tween_property(label, "position:y", 450.0, 0.6)
	_combo_popup_tween.tween_property(label, "modulate:a", 0.0, 0.6)
	_combo_popup_tween.chain().tween_callback(label.hide)


func _show_speed_banner() -> void:
	var banner := $HUD/SpeedBanner
	banner.modulate.a = 1.0
	banner.show()
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(banner.hide)


func _flash_tray() -> void:
	var panel := $HUD/TrayBG
	var tween := create_tween()
	tween.tween_property(panel, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)
	tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
