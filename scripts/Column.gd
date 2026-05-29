extends Node2D

const MAX_PILE: int = 5

const LETTER_WEIGHTS: Dictionary = {
	"E": 12, "A": 9, "I": 9, "O": 8, "N": 6, "R": 6, "T": 6,
	"L": 4,  "S": 4, "U": 4, "D": 4, "G": 3, "B": 2, "C": 2,
	"M": 2,  "P": 2, "F": 2, "H": 2, "V": 2, "W": 2, "Y": 2,
	"K": 1,  "J": 1, "X": 1, "Q": 1, "Z": 1,
}

const LETTER_VALUES: Dictionary = {
	"A": 1, "E": 1, "I": 1, "O": 1, "U": 1, "L": 1, "N": 1, "S": 1, "T": 1, "R": 1,
	"D": 2, "G": 2,
	"B": 3, "C": 3, "M": 3, "P": 3,
	"F": 4, "H": 4, "V": 4, "W": 4, "Y": 4,
	"K": 5,
	"J": 8, "X": 8,
	"Q": 10, "Z": 10,
}

signal pile_overflow(column_id: int)
signal tile_spawned(tile: LetterTile)

@export var column_id: int = 0

var _pile: Array = []
var _pool: Array[String] = []
var _rng: RandomNumberGenerator
var _spawn_timer: Timer
var _last_spawned_letter: String = ""
var _tile_scene: PackedScene


func _ready() -> void:
	_tile_scene = preload("res://scenes/game/LetterTile.tscn")

	for ltr in LETTER_WEIGHTS:
		for _i in LETTER_WEIGHTS[ltr]:
			_pool.append(ltr)

	_rng = RandomNumberGenerator.new()

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.wait_time = 2.5
	_spawn_timer.timeout.connect(_spawn_tile)
	add_child(_spawn_timer)

	add_to_group("columns")
	GameManager.state_changed.connect(_on_game_state_changed)
	GameManager.speed_increased.connect(set_fall_speed)
	# Bootstrap: scene may load after state_changed(PLAYING) was already emitted
	if GameManager.state == GameManager.State.PLAYING:
		_on_game_state_changed(GameManager.State.PLAYING)
		if GameManager.continuation_pile_fraction > 0.0:
			var fill_count := ceili(MAX_PILE * GameManager.continuation_pile_fraction)
			_prefill_pile.call_deferred(fill_count)


func _on_game_state_changed(new_state: GameManager.State) -> void:
	if new_state == GameManager.State.PLAYING:
		_rng.seed = GameManager.session_seed ^ column_id
		_spawn_timer.wait_time = _rng.randf_range(1.5, 3.5)
		_spawn_timer.start()
	else:
		_spawn_timer.stop()


func _pick_letter() -> String:
	if _last_spawned_letter == "Q":
		_last_spawned_letter = "U"
		return "U"

	const VOWELS: Array = ["A", "E", "I", "O", "U"]
	var vowel_count := 0
	for tile in GameManager.active_tiles:
		if tile.letter in VOWELS:
			vowel_count += 1
	if vowel_count == 0:
		var v: String = VOWELS[_rng.randi() % VOWELS.size()]
		for _attempt in 5:
			var count := 0
			for t in GameManager.active_tiles:
				if t.letter == v:
					count += 1
			if count < 2:
				break
			v = VOWELS[_rng.randi() % VOWELS.size()]
		_last_spawned_letter = v
		return v

	var chosen := _pool[_rng.randi() % _pool.size()]
	for _attempt in 10:
		var count := 0
		for tile in GameManager.active_tiles:
			if tile.letter == chosen:
				count += 1
		if count < 2:
			break
		chosen = _pool[_rng.randi() % _pool.size()]

	_last_spawned_letter = chosen
	return chosen


func _spawn_tile() -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return

	var letter := _pick_letter()
	var tile: LetterTile = _tile_scene.instantiate()
	tile.setup(letter, LETTER_VALUES.get(letter, 1), column_id, GameManager.current_speed)
	tile.tile_landed.connect(_on_tile_landed.bind(tile))
	tile.tree_exiting.connect(_on_tile_exiting.bind(tile))
	tile.position = $SpawnPoint.position
	add_child(tile)
	GameManager.register_tile(tile)
	tile_spawned.emit(tile)

	_spawn_timer.wait_time = _rng.randf_range(1.5, 3.5)


func _on_tile_exiting(tile: LetterTile) -> void:
	GameManager.unregister_tile(tile)
	if _pile.has(tile):
		_pile.erase(tile)
		_update_pile_indicator()


func _on_tile_landed(col_id: int, landed_tile: LetterTile) -> void:
	if _pile.size() >= MAX_PILE:
		landed_tile.destroy()
		return
	_pile.append(landed_tile)
	_update_pile_indicator()
	if _pile.size() == MAX_PILE:
		pile_overflow.emit(col_id)


func _update_pile_indicator() -> void:
	var height := _pile.size() / float(MAX_PILE) * 580.0
	$PileIndicator.size = Vector2(8.0, height)
	$PileIndicator.position = Vector2(24.0, 580.0 - height)


func set_fall_speed(speed: float) -> void:
	for child in get_children():
		if child is LetterTile and child.state == LetterTile.TileState.FALLING:
			child.fall_speed = speed


func reset() -> void:
	_spawn_timer.stop()
	for child in get_children():
		if child is LetterTile:
			child.queue_free()
	_pile.clear()
	_last_spawned_letter = ""
	_update_pile_indicator()


func clear_pile(fraction: float) -> void:
	var count := ceili(_pile.size() * fraction)
	for _i in count:
		if _pile.is_empty():
			break
		var tile: LetterTile = _pile.pop_front()
		tile.destroy()
	_update_pile_indicator()


func _prefill_pile(count: int) -> void:
	var fill := mini(count, MAX_PILE - 1)
	for _i in fill:
		var letter := _pick_letter()
		var tile: LetterTile = _tile_scene.instantiate()
		tile.setup(letter, LETTER_VALUES.get(letter, 1), column_id, GameManager.current_speed)
		tile.state = LetterTile.TileState.PILED
		tile.position = Vector2(0.0, LetterTile.PILE_Y)
		tile.input_pickable = false
		tile.tree_exiting.connect(_on_tile_exiting.bind(tile))
		add_child(tile)
		GameManager.register_tile(tile)
		_pile.append(tile)
	_update_pile_indicator()
