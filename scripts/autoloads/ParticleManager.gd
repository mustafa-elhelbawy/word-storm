extends Node

const BURST_SCENE := preload("res://scenes/effects/TileBurst.tscn")

var _effects_layer: Node2D = null


func set_effects_layer(layer: Node2D) -> void:
	_effects_layer = layer


func emit_burst(world_pos: Vector2, column_id: int) -> void:
	if _effects_layer == null:
		return
	var colour := Palette.COL_COLOURS[clampi(column_id, 0, 4)]
	var burst: Node2D = BURST_SCENE.instantiate()
	burst.position = world_pos
	_effects_layer.add_child(burst)
	burst.fire(colour)


func flash(overlay: ColorRect, colour: Color, duration: float) -> void:
	overlay.color = colour
	overlay.modulate.a = 0.4
	var tween := overlay.create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, duration)
