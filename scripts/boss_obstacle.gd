extends Area3D

# Boss-thrown obstacle — must dodge to another lane (can't jump or slide)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if GameManager.use_heart():
			body.flash_heart()
			_destroy()
			return
		body.die()


func _destroy() -> void:
	set_deferred("monitoring", false)
	for child in get_children():
		if child is MeshInstance3D:
			var tween := create_tween()
			tween.set_parallel(true)
			var fling_dir := Vector3(randf_range(-3.0, 3.0), randf_range(4.0, 8.0), randf_range(1.0, 4.0))
			tween.tween_property(child, "position", child.position + fling_dir, 0.4).set_ease(Tween.EASE_OUT)
			tween.tween_property(child, "rotation_degrees", Vector3(randf_range(-360, 360), randf_range(-360, 360), 0), 0.4)
			tween.tween_property(child, "scale", Vector3.ZERO, 0.4).set_delay(0.1)
	get_tree().create_timer(0.5).timeout.connect(queue_free)
