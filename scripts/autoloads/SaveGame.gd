extends Node

const SAVE_PATH := "user://save.json"

const DEFAULTS: Dictionary = {
	"best_score":      0,
	"selected_theme":  "default",
	"sound_enabled":   true,
	"unlocked_themes": [],
	"daily":           {}
}

var _data: Dictionary = {}


func _ready() -> void:
	_load()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = DEFAULTS.duplicate(true)
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveGame: could not open save file — resetting to defaults")
		_data = DEFAULTS.duplicate(true)
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_warning("SaveGame: corrupt save — resetting to defaults")
		_data = DEFAULTS.duplicate(true)
		return
	_data = DEFAULTS.duplicate(true)
	for key in parsed:
		_data[key] = parsed[key]
	if not _data["daily"] is Dictionary:
		_data["daily"] = {}
	if not _data["unlocked_themes"] is Array:
		_data["unlocked_themes"] = []


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: could not write save file")
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


func get_best_score() -> int:
	return int(_data.get("best_score", 0))


func set_best_score(n: int) -> void:
	if n > int(_data.get("best_score", 0)):
		_data["best_score"] = n
		_save()


func get_theme() -> String:
	return str(_data.get("selected_theme", "default"))


func set_theme(name: String) -> void:
	_data["selected_theme"] = name
	_save()


func get_sound_enabled() -> bool:
	return bool(_data.get("sound_enabled", true))


func set_sound_enabled(value: bool) -> void:
	_data["sound_enabled"] = value
	_save()


func is_theme_unlocked(name: String) -> bool:
	if name == "default":
		return true
	var unlocked: Array = _data.get("unlocked_themes", [])
	return name in unlocked


func unlock_theme(name: String) -> void:
	var unlocked: Array = _data.get("unlocked_themes", [])
	if not name in unlocked:
		unlocked.append(name)
		_data["unlocked_themes"] = unlocked
		_save()


func get_daily_result(date_str: String) -> int:
	return int(_data.get("daily", {}).get(date_str, -1))


func set_daily_result(date_str: String, score: int) -> void:
	if not _data.has("daily"):
		_data["daily"] = {}
	_data["daily"][date_str] = score
	_save()
