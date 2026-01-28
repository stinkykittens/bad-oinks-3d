class_name Player
extends CharacterBody3D

enum States {
	Idle,
	Run,
	Jump,
	Fall,
	Dash
}

@export_category("Movement")
@export var move_deadzone := 0.25
@export var run_acceleration := 2.0
@export var air_acceleration := 1.0
@export var run_friction := 8.0
@export var idle_friction := 12.0
@export var air_friction := 4.0
@export_category("Jump")
@export var gravity_scale := 1.0
@export var jump_gravity_scale := 0.8
@export var jump_strenght := 8.0
@export var jump_cancel_strenght := 3.0
@export_category("Dash")
@export var dash_duration := 0.2
@export var dash_speed := 22.0
@export var dash_curve: Curve
@export var dash_reload_time := 0.5
@export_category("Rotation Smoothing")
@export var ground_rotaion_speed := 6.0
@export var air_rotaion_speed := 1.6
@export var dash_rotaion_speed := 16.0

var state: States

var _target_rotation: float
var _dash_time: float
var _used_dash: bool


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
		velocity.x = lerpf(velocity.x, 0, idle_friction * delta)
		velocity.z = lerpf(velocity.z, 0, idle_friction * delta)
		velocity.y = -1
		if input_scale > move_deadzone:
			state = States.Run
	
	if state == States.Run:
		velocity += input_direction * run_acceleration * delta
		velocity.x = lerpf(velocity.x, 0, run_friction * delta)
		velocity.z = lerpf(velocity.z, 0, run_friction * delta)
		velocity.y = -1
		if input_scale < move_deadzone:
			state = States.Idle
		else:
			_target_rotation = camera.global_rotation.y + input.angle_to(Vector2.UP)
	
	if state == States.Fall:
		velocity += input_direction * air_acceleration * delta
		velocity.x = lerpf(velocity.x, 0, air_friction * delta)
		velocity.z = lerpf(velocity.z, 0, air_friction * delta)
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale * delta
	
	if state == States.Jump:
		velocity += input_direction * air_acceleration * delta
		velocity.x = lerpf(velocity.x, 0, air_friction * delta)
		velocity.z = lerpf(velocity.z, 0, air_friction * delta)
		if input_scale > move_deadzone:
			_target_rotation = camera.global_rotation.y + input.angle_to(Vector2.UP)
		
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * jump_gravity_scale * delta
		if not Input.is_action_pressed("jump"):
			velocity.y = move_toward(velocity.y, 0, jump_cancel_strenght * delta)
		if velocity.y <= 0:
			state = States.Fall
	
	if state == States.Dash:
		_dash_time += delta
		var magnitute = dash_curve.sample(_dash_time / dash_duration)
		velocity = magnitute * Vector3.FORWARD.rotated(Vector3.UP, _target_rotation) * dash_speed
		if _dash_time > dash_duration:
			state = States.Fall
			_dash_time = 0
	else:
		if _dash_time <= dash_reload_time:
			_dash_time += delta
		if _used_dash and is_on_floor():
			_used_dash = false

	_smooth_rotation(delta)
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strenght
		state = States.Jump
	
	if not _used_dash and _dash_time > dash_reload_time and Input.is_action_just_pressed("dash"):
		state = States.Dash
		_dash_time = 0
		if input_scale > move_deadzone:
			_target_rotation = camera.global_rotation.y + input.angle_to(Vector2.UP)
		if not is_on_floor():
			_used_dash = true
	
	move_and_slide()


func _smooth_rotation(delta: float) -> void:
	var speed: float
	match state:
		States.Idle, States.Run:
			speed = ground_rotaion_speed
		States.Jump, States.Fall:
			speed = air_rotaion_speed
		States.Dash:
			speed = dash_rotaion_speed
		
	rotation.y = lerp_angle(rotation.y, _target_rotation, delta * speed)
