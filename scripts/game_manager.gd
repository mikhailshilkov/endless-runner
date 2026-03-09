extends Node

signal game_started
signal game_over
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal speed_changed(new_speed: float)
signal hearts_changed(count: int)

enum GameState { MENU, PLAYING, GAME_OVER }

var state: GameState = GameState.MENU
var score: int = 0
var coins: int = 0
var distance: float = 0.0
var hearts: int = 0

# Speed settings
var base_speed: float = 15.0
var current_speed: float = 15.0
var max_speed: float = 50.0
var speed_increase_rate: float = 0.15 # per second

# Lane settings
const LANE_WIDTH: float = 2.5
const LANE_COUNT: int = 3
const LANES: Array[float] = [-2.5, 0.0, 2.5]


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	distance += current_speed * delta
	score = int(distance)
	score_changed.emit(score)

	if current_speed < max_speed:
		current_speed += speed_increase_rate * delta
		speed_changed.emit(current_speed)


func start_game() -> void:
	state = GameState.PLAYING
	score = 0
	coins = 0
	distance = 0.0
	hearts = 0
	current_speed = base_speed
	score_changed.emit(score)
	coins_changed.emit(coins)
	speed_changed.emit(current_speed)
	hearts_changed.emit(0)
	game_started.emit()


func end_game() -> void:
	state = GameState.GAME_OVER
	game_over.emit()


func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)


func add_heart() -> void:
	hearts += 1
	hearts_changed.emit(hearts)


func use_heart() -> bool:
	if hearts > 0:
		hearts -= 1
		hearts_changed.emit(hearts)
		return true
	return false


func is_playing() -> bool:
	return state == GameState.PLAYING
