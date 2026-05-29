class_name LetterTile
extends Area2D

enum TileState { FALLING, PILED, SELECTED, DESTROYING }

signal tile_tapped(tile: Area2D)
signal tile_landed(column_id: int)

const PILE_Y: float = 580.0

var letter: String = "A"
var point_value: int = 1
var column_id: int = 0
var fall_speed: float = 80.0
var state: TileState = TileState.FALLING


func setup(p_letter: String, p_value: int, p_col_id: int, p_speed: float) -> void:
	letter = p_letter
	point_value = p_value
	column_id = p_col_id
	fall_speed = p_speed


func _ready() -> void:
	input_event.connect(_on_input_event)
	$LetterLabel.text = letter
	$PointsLabel.text = str(point_value)
	$TileBackground.color = Palette.COL_COLOURS[column_id]


func _process(delta: float) -> void:
	if state == TileState.FALLING:
		position.y += fall_speed * delta
		if position.y >= PILE_Y:
			_land()


func _land() -> void:
	state = TileState.PILED
	tile_landed.emit(column_id)
	AudioManager.play("tile_land")


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if state == TileState.FALLING or state == TileState.PILED or state == TileState.SELECTED:
			tile_tapped.emit(self)
			AudioManager.play("tile_select")


func select() -> void:
	state = TileState.SELECTED
	$TileBackground.color = Palette.COL_COLOURS[column_id].lightened(0.35)


func deselect() -> void:
	state = TileState.PILED if position.y >= PILE_Y else TileState.FALLING
	$TileBackground.color = Palette.COL_COLOURS[column_id]


func destroy() -> void:
	state = TileState.DESTROYING
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
