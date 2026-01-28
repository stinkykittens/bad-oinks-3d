class_name Player
extends CharacterBody3D

@export var move_speed := 8.0
@export var move_deadzone := 0.25
@export var gravity_scale := 1.0
@export var jump_strenght := 8.0


func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	var input: Vector2
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	var input_scale = smoothstep(move_deadzone, 1, input.length())
	input = input.normalized() * input_scale
	
	velocity.x = input.x
	velocity.z = input.y
	
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale * delta
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strenght
	
	move_and_slide()
