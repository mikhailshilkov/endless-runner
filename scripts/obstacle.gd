extends Area3D

# Obstacle types:
# - low: player must jump over
# - high: player must slide under
# - full: player must dodge to another lane

@export var obstacle_type: String = "low"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Check if player can pass through
		match obstacle_type:
			"high":
				# High obstacles can be passed by sliding
				if body.is_sliding:
					return
			"low":
				# Low obstacles can be passed by jumping
				if not body.is_on_floor():
					return
		body.die()
