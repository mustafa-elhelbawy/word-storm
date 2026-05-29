extends Node

const SFX_PATHS: Dictionary = {
	"tile_land":    "res://assets/audio/sfx/tile_land.ogg",
	"tile_select":  "res://assets/audio/sfx/tile_select.ogg",
	"word_valid":   "res://assets/audio/sfx/word_valid.ogg",
	"word_invalid": "res://assets/audio/sfx/word_invalid.ogg",
	"life_lost":    "res://assets/audio/sfx/life_lost.ogg",
	"game_over":    "res://assets/audio/sfx/game_over.ogg",
}

const POOL_SIZE: int = 8

var _pool: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}
var _enabled: bool = true


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)

	var loaded := 0
	for name in SFX_PATHS:
		var path: String = SFX_PATHS[name]
		if FileAccess.file_exists(path):
			_sounds[name] = load(path)
			loaded += 1

	print("AudioManager: loaded %d sounds" % loaded)
	_enabled = SaveGame.get_sound_enabled()


func play(name: String) -> void:
	if not _enabled or not _sounds.has(name):
		return
	var player := _get_free_player()
	if player == null:
		return
	player.stream = _sounds[name]
	player.play()


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		for p in _pool:
			p.stop()


func _get_free_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	return null
