extends Node

const SCENES: Dictionary = {
	GameManager.State.TITLE:     "res://scenes/screens/StartScreen.tscn",
	GameManager.State.PLAYING:   "res://scenes/game/GameScreen.tscn",
	GameManager.State.GAME_OVER: "res://scenes/screens/GameOver.tscn",
}

var _current_scene: Node = null


func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	_switch_to(GameManager.State.TITLE)


func _on_state_changed(new_state: GameManager.State) -> void:
	if SCENES.has(new_state):
		_switch_to(new_state)


func _switch_to(state: GameManager.State) -> void:
	if _current_scene != null:
		_current_scene.queue_free()
	var packed: PackedScene = load(SCENES[state])
	_current_scene = packed.instantiate()
	$SceneContainer.add_child(_current_scene)
