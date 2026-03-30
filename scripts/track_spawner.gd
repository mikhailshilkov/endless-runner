extends Node3D

const CHUNK_LENGTH: float = 40.0
const BUFFER_AHEAD: float = 300.0

var chunk_scene: PackedScene
var obstacle_low_scene: PackedScene
var obstacle_high_scene: PackedScene
var obstacle_full_scene: PackedScene
var coin_scene: PackedScene
var heart_scene: PackedScene
var boss_scene: PackedScene
var bomb_scene: PackedScene

var distance_scrolled: float = 0.0
var next_chunk_at: float = 0.0
var chunks_spawned: int = 0
var next_heart_at: float = 1000.0
const HEART_INTERVAL: float = 1000.0

var current_boss: Node3D = null


func _ready() -> void:
	chunk_scene = preload("res://scenes/track_chunk.tscn")
	obstacle_low_scene = preload("res://scenes/obstacle_low.tscn")
	obstacle_high_scene = preload("res://scenes/obstacle_high.tscn")
	obstacle_full_scene = preload("res://scenes/obstacle_full.tscn")
	coin_scene = preload("res://scenes/coin.tscn")
	heart_scene = preload("res://scenes/shield_pickup.tscn")
	boss_scene = preload("res://scenes/boss.tscn")
	bomb_scene = preload("res://scenes/bomb_pickup.tscn")
	GameManager.game_started.connect(_on_game_started)
	GameManager.boss_defeated.connect(_on_boss_defeated)


func _on_game_started() -> void:
	for child in get_children():
		child.queue_free()
	distance_scrolled = 0.0
	next_chunk_at = 0.0
	chunks_spawned = 0
	next_heart_at = HEART_INTERVAL
	current_boss = null
	_ensure_chunks()


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	distance_scrolled += GameManager.current_speed * delta
	_ensure_chunks()

	# Check if boss should spawn
	if not GameManager.boss_active and GameManager.distance >= GameManager.next_boss_at:
		_spawn_boss()

	# Move all chunks/objects toward the player
	for child in get_children():
		if child.has_meta("world_z"):
			child.position.z = child.get_meta("world_z") + distance_scrolled
			if child.position.z > CHUNK_LENGTH:
				child.queue_free()

	# Keep boss at fixed screen position (ahead of player)
	if current_boss and is_instance_valid(current_boss):
		current_boss.position.z = -20.0


func _ensure_chunks() -> void:
	while next_chunk_at < distance_scrolled + BUFFER_AHEAD:
		_spawn_chunk()


func _spawn_chunk() -> void:
	var chunk: Node3D = chunk_scene.instantiate()
	var world_z: float = -next_chunk_at
	chunk.set_meta("world_z", world_z)
	chunk.position.z = world_z + distance_scrolled
	add_child(chunk)

	if chunks_spawned > 1:
		_populate_chunk(chunk)

	next_chunk_at += CHUNK_LENGTH
	chunks_spawned += 1


func _populate_chunk(chunk: Node3D) -> void:
	if GameManager.boss_active:
		_populate_boss_chunk(chunk)
		return

	var num_obstacles := randi_range(1, 3)
	var used_positions: Array[Vector2] = []

	for i in range(num_obstacles):
		var lane := randi_range(0, 2)
		var z_offset: float = snapped(randf_range(-CHUNK_LENGTH * 0.4, CHUNK_LENGTH * 0.4), 5.0)

		var overlap := false
		for used in used_positions:
			if int(used.x) == lane and absf(used.y - z_offset) < 4.0:
				overlap = true
				break
		if overlap:
			continue

		used_positions.append(Vector2(lane, z_offset))

		var obstacle_type := randi_range(0, 2)
		var obstacle: Node3D
		match obstacle_type:
			0:
				obstacle = obstacle_low_scene.instantiate()
			1:
				obstacle = obstacle_high_scene.instantiate()
			2:
				obstacle = obstacle_full_scene.instantiate()

		obstacle.position = Vector3(GameManager.LANES[lane], 0.0, z_offset)
		chunk.add_child(obstacle)

	# Heart pickup
	var chunk_start_dist: float = next_chunk_at - CHUNK_LENGTH
	if chunk_start_dist >= next_heart_at:
		var heart_lane := randi_range(0, 2)
		var heart: Node3D = heart_scene.instantiate()
		heart.position = Vector3(GameManager.LANES[heart_lane], 1.5, 0.0)
		chunk.add_child(heart)
		next_heart_at = chunk_start_dist + HEART_INTERVAL

	# Coin lines
	if randf() < 0.7:
		var coin_lane := randi_range(0, 2)
		var coin_z_start := randf_range(-CHUNK_LENGTH * 0.3, CHUNK_LENGTH * 0.1)
		var coin_count := randi_range(3, 7)
		var coin_height := 1.0
		if randf() < 0.3:
			coin_height = 3.0
		for c in range(coin_count):
			var cz := coin_z_start - c * 2.0
			var blocked := false
			for used in used_positions:
				if int(used.x) == coin_lane and absf(used.y - cz) < 2.0:
					blocked = true
					break
			if blocked:
				continue
			var coin: Node3D = coin_scene.instantiate()
			coin.position = Vector3(GameManager.LANES[coin_lane], coin_height, cz)
			chunk.add_child(coin)


var boss_chunk_count: int = 0

func _populate_boss_chunk(chunk: Node3D) -> void:
	boss_chunk_count += 1
	# Bomb every other chunk
	if boss_chunk_count % 2 == 1:
		var bomb_lane := randi_range(0, 2)
		var bomb_z := randf_range(-CHUNK_LENGTH * 0.3, CHUNK_LENGTH * 0.3)
		var bomb: Node3D = bomb_scene.instantiate()
		bomb.position = Vector3(GameManager.LANES[bomb_lane], 1.5, bomb_z)
		chunk.add_child(bomb)

	# Still spawn coins
	if randf() < 0.7:
		var coin_lane := randi_range(0, 2)
		var coin_z_start := randf_range(-CHUNK_LENGTH * 0.3, CHUNK_LENGTH * 0.1)
		var coin_count := randi_range(3, 5)
		for c in range(coin_count):
			var cz := coin_z_start - c * 2.0
			var coin: Node3D = coin_scene.instantiate()
			coin.position = Vector3(GameManager.LANES[coin_lane], 1.0, cz)
			chunk.add_child(coin)


func _spawn_boss() -> void:
	GameManager.start_boss()
	boss_chunk_count = 0
	current_boss = boss_scene.instantiate()
	current_boss.position.z = -20.0
	add_child(current_boss)
	_repopulate_ahead_chunks()


func _on_boss_defeated() -> void:
	current_boss = null
	# Remove boss-thrown obstacles (direct children of spawner with world_z)
	for child in get_children():
		if child is Area3D and child.has_meta("world_z"):
			child.queue_free()
	_repopulate_ahead_chunks()


func _repopulate_ahead_chunks() -> void:
	# Strip spawned content from all chunks ahead of the player and refill
	for child in get_children():
		if not child.has_meta("world_z"):
			continue
		# Only repopulate chunks that are still ahead
		var screen_z: float = child.get_meta("world_z") + distance_scrolled
		if screen_z > -5.0:
			continue  # Already behind the player
		# Remove all obstacles, coins, hearts, bombs (keep scenery and ground)
		for sub in child.get_children():
			if sub is Area3D:
				sub.queue_free()
		# Repopulate with correct content for current state
		_populate_chunk(child)
