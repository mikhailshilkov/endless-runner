extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	player.add_to_group("player")


func _on_game_started() -> void:
	player.reset_player()


func _physics_process(delta: float) -> void:
	# Camera follows player's X (lane changes) smoothly, fixed Y/Z
	camera.position.x = lerpf(camera.position.x, player.position.x * 0.6, 8.0 * delta)
