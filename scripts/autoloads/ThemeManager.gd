extends Node

signal theme_changed(palette: Dictionary)

const PALETTES: Dictionary = {
	"default": {
		"bg":        Color(0.055, 0.039, 0.118),
		"text":      Color.WHITE,
		"pile_warn": Color(1.0, 0.2, 0.2),
		"cols": [
			Color(0.0,   0.784, 0.722),
			Color(0.0,   0.878, 1.000),
			Color(1.0,   0.757, 0.027),
			Color(0.694, 0.404, 1.000),
			Color(0.0,   0.941, 0.502),
		]
	},
	"ocean": {
		"bg": Color(0.02, 0.05, 0.15), "text": Color.WHITE,
		"pile_warn": Color(1.0, 0.2, 0.2),
		"cols": [Color(0.0, 0.5, 1.0), Color(0.0, 0.8, 0.9),
				 Color(0.2, 0.9, 0.6), Color(0.3, 0.6, 1.0), Color(0.0, 0.7, 0.8)]
	},
	"ember": {
		"bg": Color(0.10, 0.03, 0.01), "text": Color(1.0, 0.95, 0.8),
		"pile_warn": Color(1.0, 0.1, 0.0),
		"cols": [Color(1.0, 0.3, 0.0), Color(1.0, 0.6, 0.0),
				 Color(1.0, 0.8, 0.1), Color(0.9, 0.2, 0.1), Color(1.0, 0.5, 0.1)]
	},
	"void": {
		"bg": Color(0.0, 0.0, 0.0), "text": Color(0.8, 0.8, 1.0),
		"pile_warn": Color(0.8, 0.0, 1.0),
		"cols": [Color(0.5, 0.0, 1.0), Color(0.8, 0.0, 0.8),
				 Color(0.3, 0.0, 0.8), Color(0.6, 0.2, 1.0), Color(0.4, 0.0, 0.6)]
	},
}

var _current: String = "default"


func _ready() -> void:
	_current = SaveGame.get_theme()


func current_palette() -> Dictionary:
	return PALETTES.get(_current, PALETTES["default"])


func column_colour(col_id: int) -> Color:
	return current_palette()["cols"][clampi(col_id, 0, 4)]


func apply_theme(name: String) -> void:
	if not PALETTES.has(name):
		return
	_current = name
	SaveGame.set_theme(name)
	theme_changed.emit(current_palette())
