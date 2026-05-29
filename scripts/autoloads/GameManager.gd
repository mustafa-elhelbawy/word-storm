extends Node

enum State { TITLE, WAITING, PLAYING, GAME_OVER }
enum SessionType { CLASSIC, DAILY }

signal state_changed(new_state: State)
signal life_lost(lives_remaining: int)
signal game_over
signal speed_increased(new_speed: float)

const BASE_SPEED:     float = 80.0
const SPEED_STEP:     float = 10.0
const SPEED_INTERVAL: float = 30.0
const MAX_SPEED:      float = 220.0
const MAX_LIVES:      int   = 3

var state:           State       = State.TITLE
var session_type:    SessionType = SessionType.CLASSIC
var session_seed:    int         = 0
var lives:           int         = MAX_LIVES
var speed_level:     int         = 0
var current_speed:   float       = BASE_SPEED
var elapsed_seconds: float       = 0.0
var active_tiles:    Array       = []


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	elapsed_seconds += delta
	var new_level := int(elapsed_seconds / SPEED_INTERVAL)
	if new_level != speed_level:
		speed_level = new_level
		current_speed = minf(BASE_SPEED + speed_level * SPEED_STEP, MAX_SPEED)
		speed_increased.emit(current_speed)


func start_game(type: SessionType) -> void:
	session_type = type
	session_seed = _generate_seed(type)
	lives = MAX_LIVES
	speed_level = 0
	current_speed = BASE_SPEED
	elapsed_seconds = 0.0
	active_tiles.clear()
	ScoreManager.reset()
	_set_state(State.PLAYING)


func continue_game() -> void:
	if state != State.GAME_OVER:
		return
	active_tiles.clear()
	_set_state(State.PLAYING)


func lose_life(col_id: int = -1) -> void:
	if state != State.PLAYING:
		return
	lives -= 1
	life_lost.emit(lives)
	if lives <= 0:
		game_over.emit()
		_set_state(State.GAME_OVER)


func register_tile(tile: Area2D) -> void:
	active_tiles.append(tile)


func unregister_tile(tile: Area2D) -> void:
	active_tiles.erase(tile)


func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)


func _generate_seed(type: SessionType) -> int:
	if type == SessionType.DAILY:
		var date := Time.get_date_string_from_system()
		return int(date.replace("-", ""))
	return randi()
