extends CharacterBody3D

@export var gravity := 1.0

func _physics_process(delta: float) -> void:
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity * delta
	var collision := move_and_collide(velocity * delta)
	if collision:
		queue_free()
