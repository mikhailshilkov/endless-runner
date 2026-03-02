extends Area3D

var rotation_speed: float = 3.0
var bob_speed: float = 2.0
var bob_amount: float = 0.2
var base_y: float = 0.0


func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotation.y += rotation_speed * delta
	position.y = base_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_amount


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.add_coin()
		# Quick scale-down effect
		# Disable collision immediately, then remove
		set_deferred("monitoring", false)
		visible = false
		queue_free()
