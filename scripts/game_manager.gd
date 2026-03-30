extends Node

signal game_started
signal game_over
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal speed_changed(new_speed: float)
signal hearts_changed(count: int)
signal skin_changed(index: int)
signal wallet_changed(amount: int)
signal boss_spawned(hp: int)
signal boss_hit(hp_remaining: int)
signal boss_defeated

enum GameState { MENU, PLAYING, GAME_OVER }

var state: GameState = GameState.MENU
var score: int = 0
var coins: int = 0
var distance: float = 0.0
var hearts: int = 0

# Speed settings
var base_speed: float = 15.0
var current_speed: float = 15.0
var max_speed: float = 80.0
var speed_increase_rate: float = 0.1 # per second

# Lane settings
const LANE_WIDTH: float = 2.5
const LANE_COUNT: int = 3
const LANES: Array[float] = [-2.5, 0.0, 2.5]

# Shop / skins
const SKINS: Array[Dictionary] = [
	{"name": "Blue", "color": Color(0.1, 0.35, 0.9), "price": 0},
	{"name": "Pink", "color": Color(1.0, 0.4, 0.7), "price": 25},
	{"name": "Purple", "color": Color(0.6, 0.2, 0.9), "price": 75},
	{"name": "Green", "color": Color(0.2, 0.8, 0.3), "price": 150},
	{"name": "Teal", "color": Color(0.0, 0.6, 0.6), "price": 300},
	{"name": "Orange", "color": Color(1.0, 0.5, 0.1), "price": 500},
	{"name": "Gold", "color": Color(0.85, 0.65, 0.13), "price": 1000},
	{"name": "Black", "color": Color(0.1, 0.1, 0.1), "price": 2000},
	{"name": "Red", "color": Color(0.9, 0.2, 0.2), "price": 3000},
]

# Boss
const BOSS_INTERVAL: float = 200.0  # TODO: change back to 10000
const BOSS_BASE_HP: int = 5
const BOSS_HP_INCREMENT: int = 2
var boss_active: bool = false
var boss_hp: int = 0
var boss_max_hp: int = 0
var bosses_defeated: int = 0
var next_boss_at: float = BOSS_INTERVAL

var wallet: int = 0
var owned_skins: Array[int] = [0]
var selected_skin: int = 0

# Leaderboard
const MAX_RUNS: int = 20
var run_history: Array[Dictionary] = []

const SAVE_PATH := "user://save.cfg"


func _ready() -> void:
	_load_save()


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
	boss_active = false
	boss_hp = 0
	bosses_defeated = 0
	next_boss_at = BOSS_INTERVAL
	current_speed = base_speed
	score_changed.emit(score)
	coins_changed.emit(coins)
	speed_changed.emit(current_speed)
	hearts_changed.emit(0)
	game_started.emit()


func end_game() -> void:
	state = GameState.GAME_OVER
	wallet += coins
	wallet_changed.emit(wallet)
	run_history.append({"score": score, "coins": coins})
	run_history.sort_custom(func(a, b): return a["score"] > b["score"])
	if run_history.size() > MAX_RUNS:
		run_history.resize(MAX_RUNS)
	_save_data()
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


func start_boss() -> void:
	boss_active = true
	boss_max_hp = BOSS_BASE_HP + bosses_defeated * BOSS_HP_INCREMENT
	boss_hp = boss_max_hp
	boss_spawned.emit(boss_hp)


func hit_boss() -> void:
	if not boss_active:
		return
	boss_hp -= 1
	boss_hit.emit(boss_hp)
	if boss_hp <= 0:
		boss_active = false
		bosses_defeated += 1
		next_boss_at = distance + BOSS_INTERVAL
		boss_defeated.emit()


func get_player_color() -> Color:
	return SKINS[selected_skin]["color"]


func buy_skin(index: int) -> bool:
	if index < 0 or index >= SKINS.size():
		return false
	if index in owned_skins:
		return false
	var price: int = SKINS[index]["price"]
	if wallet < price:
		return false
	wallet -= price
	owned_skins.append(index)
	wallet_changed.emit(wallet)
	_save_data()
	return true


func select_skin(index: int) -> void:
	if index in owned_skins:
		selected_skin = index
		skin_changed.emit(index)
		_save_data()


const SAVE_VERSION := 5

func _save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("save", "wallet", wallet)
	config.set_value("save", "owned_skins", owned_skins)
	config.set_value("save", "selected_skin", selected_skin)
	config.set_value("save", "run_history", run_history)
	config.save(SAVE_PATH)


func _load_save() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var version: int = config.get_value("save", "version", 1)
	if version < SAVE_VERSION:
		# Skin order changed — keep wallet but reset skin selections
		wallet = config.get_value("save", "wallet", 0)
		owned_skins = [0]
		selected_skin = 0
		_save_data()
		return
	wallet = config.get_value("save", "wallet", 0)
	var loaded_owned = config.get_value("save", "owned_skins", [0])
	owned_skins.clear()
	for s in loaded_owned:
		owned_skins.append(s)
	selected_skin = config.get_value("save", "selected_skin", 0)
	if selected_skin not in owned_skins:
		selected_skin = 0
	var loaded_history = config.get_value("save", "run_history", [])
	run_history.clear()
	for r in loaded_history:
		run_history.append(r)
