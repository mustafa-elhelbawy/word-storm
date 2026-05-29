extends Node

const SAVE_PATH := "user://save.cfg"

var _cfg: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_cfg.load(SAVE_PATH)


func get_best_score() -> int:
	return int(_cfg.get_value("scores", "best", 0))


func set_best_score(value: int) -> void:
	_cfg.set_value("scores", "best", value)
	_cfg.save(SAVE_PATH)


func get_sound_enabled() -> bool:
	return bool(_cfg.get_value("settings", "sound_enabled", true))


func set_sound_enabled(value: bool) -> void:
	_cfg.set_value("settings", "sound_enabled", value)
	_cfg.save(SAVE_PATH)
