extends Node3D

const CHUNK_LENGTH: float = 40.0
const BUFFER_AHEAD: float = 160.0  # Keep this much track ahead of scroll position

var chunk_scene: PackedScene
var obstacle_low_scene: PackedScene
var obstacle_high_scene: PackedScene
var obstacle_full_scene: PackedScene
var coin_scene: PackedScene
var heart_scene: PackedScene

var distance_scrolled: float = 0.0
var next_chunk_at: float = 0.0  # World-space z where the next chunk should go
var chunks_spawned: int = 0
var next_heart_at: float = 1000.0  # Distance for next heart spawn
const HEART_INTERVAL: float = 1000.0


func _ready() -> void:
	chunk_scene = preload("res://scenes/track_chunk.tscn")
	obstacle_low_scene = preload("res://scenes/obstacle_low.tscn")
	obstacle_high_scene = preload("res://scenes/obstacle_high.tscn")
	obstacle_full_scene = preload("res://scenes/obstacle_full.tscn")
	coin_scene = preload("res://scenes/coin.tscn")
	heart_scene = preload("res://scenes/shield_pickup.tscn")
	GameManager.game_started.connect(_on_game_started)


func _on_game_started() -> void:
	for child in get_children():
		child.queue_free()
	distance_scrolled = 0.0
	next_chunk_at = 0.0
	chunks_spawned = 0
	next_heart_at = HEART_INTERVAL
	# Spawn initial batch
	_ensure_chunks()


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	distance_scrolled += GameManager.current_speed * delta
	_ensure_chunks()
	# Move all chunks toward the player
	for child in get_children():
		child.position.z = child.get_meta("world_z") + distance_scrolled
		# Despawn chunks well behind the player
		if child.position.z > CHUNK_LENGTH:
			child.queue_free()


func _ensure_chunks() -> void:
	# Keep spawning until we have enough track ahead
	while next_chunk_at < distance_scrolled + BUFFER_AHEAD:
		_spawn_chunk()


func _spawn_chunk() -> void:
	var chunk: Node3D = chunk_scene.instantiate()
	# Store the fixed world-space z so we can reposition each frame
	var world_z: float = -next_chunk_at
	chunk.set_meta("world_z", world_z)
	chunk.position.z = world_z + distance_scrolled
	add_child(chunk)

	if chunks_spawned > 1:
		_populate_chunk(chunk)

	next_chunk_at += CHUNK_LENGTH
	chunks_spawned += 1


func _populate_chunk(chunk: Node3D) -> void:
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

	# Heart pickup — spawns every ~1000 distance
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
