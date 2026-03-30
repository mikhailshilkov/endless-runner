extends Node3D

# Boss floats ahead of player, throws blue obstacles at random lanes

var boss_obstacle_scene: PackedScene
var throw_timer: float = 0.0
var throw_interval: float = 2.0
var throw_interval_min: float = 0.5
var throw_accel: float = 0.05
var bob_time: float = 0.0
var base_y: float = 4.0
var mesh: MeshInstance3D
var is_active: bool = true
var throw_count: int = 0


func _ready() -> void:
	boss_obstacle_scene = preload("res://scenes/boss_obstacle.tscn")
	mesh = $Mesh
	GameManager.boss_hit.connect(_on_boss_hit)
	GameManager.boss_defeated.connect(_on_boss_defeated)


func _process(delta: float) -> void:
	if not is_active:
		return
	bob_time += delta
	mesh.position.y = base_y + sin(bob_time * 1.5) * 0.5
	mesh.position.x = sin(bob_time * 0.7) * 2.0
	mesh.rotation.y += delta * 2.0

	throw_timer -= delta
	if throw_timer <= 0.0:
		_do_attack()
		throw_interval = maxf(throw_interval - throw_accel, throw_interval_min)
		throw_timer = throw_interval


func _do_attack() -> void:
	throw_count += 1
	# Every 5th throw is a wave (3 rapid obstacles in sequence)
	if throw_count % 5 == 0:
		_throw_wave()
	# Every 3rd throw is a double (2 lanes blocked)
	elif throw_count % 3 == 0:
		_throw_double()
	else:
		_throw_single()


func _throw_single() -> void:
	var lane := randi_range(0, 2)
	_spawn_obstacle(lane, 0.0)


func _throw_double() -> void:
	# Block 2 of 3 lanes — player must go to the open one
	var open_lane := randi_range(0, 2)
	for lane in range(3):
		if lane != open_lane:
			_spawn_obstacle(lane, 0.0)


func _throw_wave() -> void:
	# 3 obstacles in rapid sequence, each in a random lane
	for i in range(3):
		var lane := randi_range(0, 2)
		_spawn_obstacle(lane, -i * 4.0)  # Stagger Z so they arrive sequentially


func _spawn_obstacle(lane: int, z_offset: float) -> void:
	var obs: Node3D = boss_obstacle_scene.instantiate()
	var spawn_z: float = position.z - 10.0 + z_offset
	obs.position = Vector3(GameManager.LANES[lane], 0.0, spawn_z)
	obs.set_meta("world_z", -get_parent().distance_scrolled + spawn_z)
	get_parent().add_child(obs)


func _on_boss_hit(hp_remaining: int) -> void:
	# Flash effect
	var mat: StandardMaterial3D = mesh.get_surface_override_material(0)
	if mat:
		var original_emission: float = mat.emission_energy_multiplier
		mat.emission_energy_multiplier = 8.0
		var tween := create_tween()
		tween.tween_property(mat, "emission_energy_multiplier", original_emission, 0.3)
	# Shrink slightly with each hit
	var scale_factor: float = 0.5 + 0.5 * (float(hp_remaining) / float(GameManager.boss_max_hp))
	var tween2 := create_tween()
	tween2.tween_property(mesh, "scale", Vector3.ONE * scale_factor, 0.2)


func _on_boss_defeated() -> void:
	is_active = false
	# Explode effect
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh, "scale", Vector3.ONE * 3.0, 0.3).set_ease(Tween.EASE_OUT)
	var mat: StandardMaterial3D = mesh.get_surface_override_material(0)
	if mat:
		tween.tween_property(mat, "emission_energy_multiplier", 10.0, 0.3)
	tween.chain().tween_property(mesh, "scale", Vector3.ZERO, 0.2)
	tween.chain().tween_callback(queue_free)
