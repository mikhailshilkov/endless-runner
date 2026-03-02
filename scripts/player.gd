extends CharacterBody3D

const JUMP_VELOCITY: float = 12.0
const GRAVITY: float = 30.0
const LANE_SWITCH_SPEED: float = 12.0
const SLIDE_DURATION: float = 0.6

var current_lane: int = 1  # 0=left, 1=center, 2=right
var target_x: float = 0.0
var is_sliding: bool = false
var slide_timer: float = 0.0
var is_dead: bool = false

# Swipe detection
var swipe_start: Vector2 = Vector2.ZERO
var is_swiping: bool = false
const SWIPE_THRESHOLD: float = 50.0

@onready var collision_shape: CollisionShape3D = $CollisionShape
@onready var mesh: MeshInstance3D = $Mesh
@onready var slide_collision: CollisionShape3D = $SlideCollision


func _ready() -> void:
	target_x = GameManager.LANES[current_lane]
	position.x = target_x
	slide_collision.disabled = true


func _physics_process(delta: float) -> void:
	if is_dead or not GameManager.is_playing():
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Lane movement — snap quickly to target lane
	var x_diff := target_x - position.x
	if absf(x_diff) > 0.02:
		position.x = move_toward(position.x, target_x, LANE_SWITCH_SPEED * delta)
	else:
		position.x = target_x
	velocity.x = 0.0

	# Slide timer
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			_end_slide()

	velocity.z = 0.0  # Player doesn't move forward; world moves toward them
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or not GameManager.is_playing():
		return
	if event.is_action_pressed("move_left"):
		switch_lane(-1)
	elif event.is_action_pressed("move_right"):
		switch_lane(1)
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_pressed("slide"):
		start_slide()
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.is_pressed():
			swipe_start = event.position
			is_swiping = true
		elif is_swiping:
			is_swiping = false
			var swipe: Vector2 = event.position - swipe_start
			if swipe.length() > SWIPE_THRESHOLD:
				if absf(swipe.x) > absf(swipe.y):
					if swipe.x < 0:
						switch_lane(-1)
					else:
						switch_lane(1)
				else:
					if swipe.y < 0:
						jump()
					else:
						start_slide()


func switch_lane(direction: int) -> void:
	var new_lane := clampi(current_lane + direction, 0, GameManager.LANE_COUNT - 1)
	if new_lane != current_lane:
		current_lane = new_lane
		target_x = GameManager.LANES[current_lane]


func jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		if is_sliding:
			_end_slide()


func start_slide() -> void:
	if is_on_floor() and not is_sliding:
		is_sliding = true
		slide_timer = SLIDE_DURATION
		# Shrink collision for sliding
		collision_shape.disabled = true
		slide_collision.disabled = false
		# Visual: squash the mesh
		mesh.scale.y = 0.4
		mesh.position.y = -0.3


func _end_slide() -> void:
	is_sliding = false
	collision_shape.disabled = false
	slide_collision.disabled = true
	mesh.scale.y = 1.0
	mesh.position.y = 0.0


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector3.ZERO
	# Tumble animation
	var tween := create_tween()
	tween.tween_property(mesh, "rotation_degrees:x", -90.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_callback(GameManager.end_game)


func reset_player() -> void:
	is_dead = false
	current_lane = 1
	target_x = GameManager.LANES[current_lane]
	position = Vector3(0.0, 0.81, 0.0)
	velocity = Vector3.ZERO
	mesh.rotation_degrees = Vector3.ZERO
	mesh.scale = Vector3.ONE
	mesh.position.y = 0.0
	_end_slide()
