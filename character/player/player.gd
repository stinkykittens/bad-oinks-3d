class_name Player
extends CharacterBody3D

enum States {
	Idle,
	Run,
	Jump,
	Fall,
	Dash
}


@export var move_speed := 8.0
@export var move_deadzone := 0.25
@export var gravity_scale := 1.0
@export var jump_gravity_scale := 0.8
@export var jump_strenght := 8.0
@export var jump_cancel_strenght := 3.0

@export var rotaion_smooth_speed_grounded := 6
@export var rotaion_smooth_speed_air := 3


var state: States

var _target_rotation: float


func _ready() -> void:
	state = States.Idle


func _physics_process(delta: float) -> void:
	var input: Vector2
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	var input_scale = min(1, input.length())
	input = input.normalized() * input_scale
	var camera := get_tree().root.get_camera_3d()
	var input_direction := Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera.global_rotation.y)
	
	if is_on_floor() and (state == States.Fall or state == States.Jump):
		# Ground entered
		state = States.Idle
	
	if not is_on_floor() and (state == States.Idle or state == States.Run):
		# Ground exited
		state = States.Fall
	
	if state == States.Idle:
		velocity.x = 0
		velocity.z = 0
		velocity.y = -1
		if input_scale > move_deadzone:
			state = States.Run
	
	if state == States.Run:
		velocity.y = -1
		velocity.x = input_direction.x
		velocity.z = input_direction.z
		if input_scale < move_deadzone:
			state = States.Idle
		else:
			_target_rotation = camera.global_rotation.y + input.angle_to(Vector2.UP)
	
	if state == States.Fall:
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale * delta
	
	if state == States.Jump:
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * jump_gravity_scale * delta
		if not Input.is_action_pressed("jump"):
			velocity.y = move_toward(velocity.y, 0, jump_cancel_strenght * delta)
		if velocity.y <= 0:
			state = States.Fall
	
	rotation.y = lerp_angle(rotation.y, _target_rotation, delta * (rotaion_smooth_speed_grounded if is_on_floor() else rotaion_smooth_speed_air))
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strenght
		state = States.Jump
	
	move_and_slide()
	print(state)
