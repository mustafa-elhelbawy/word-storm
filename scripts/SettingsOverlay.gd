extends CanvasLayer


func _ready() -> void:
	$DimBackground.gui_input.connect(_on_dim_input)
	$CloseButton.pressed.connect(queue_free)

	$Panel/VBox/SoundRow/SoundToggle.button_pressed = SaveGame.get_sound_enabled()
	$Panel/VBox/SoundRow/SoundToggle.toggled.connect(func(on: bool) -> void:
		AudioManager.set_enabled(on)
		SaveGame.set_sound_enabled(on))

	_setup_theme_buttons()


func _setup_theme_buttons() -> void:
	var current := SaveGame.get_theme()
	var theme_map := {
		"ThemeDefault": "default",
		"ThemeOcean":   "ocean",
		"ThemeEmber":   "ember",
		"ThemeVoid":    "void",
	}
	for btn_name in theme_map:
		var btn: Button = $Panel/VBox/ThemeGrid.get_node(btn_name)
		var key: String = theme_map[btn_name]
		btn.disabled = not SaveGame.is_theme_unlocked(key)
		btn.flat = (key != current)
		btn.pressed.connect(func() -> void: ThemeManager.apply_theme(key))


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		queue_free()
