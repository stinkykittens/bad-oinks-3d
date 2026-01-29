class_name Player
extends CharacterBody3D

const EGG_SCENE = preload("uid://d3woe0uy4fv75")

enum States {
	Idle,
	Run,
	Jump,
	Fall,
	Dash,
	LayEgg,
	EggAction
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
@export_category("Bomb Eggs")
@export var egg_reload_time := 1.0
@export var egg_lay_time := 0.15
@export var egg_jump_strenght := 9.0
@export var egg_air_jump_strenght := 4.0
@export var egg_throw_velocity := Vector2(8, 3)
@export var layed_egg_velocity := -6.0
@export var lay_egg_friction := 5.0
@export var egg_action_friction := 5.0
@export var egg_action_duration := 0.2
@export_category("Rotation Smoothing")
@export var ground_rotaion_speed := 6.0
@export var air_rotaion_speed := 1.6
@export var dash_rotaion_speed := 32.0
@export var lay_egg_rotaion_speed := 16.0
@export var egg_action_rotaion_speed := 32.0

var state: States

var _target_rotation: float
var _dash_time: float
var _used_dash: bool
var _egg_time: float
var _layed_egg: bool
var _egg_action_time: float
var _is_holding_egg: bool
var _egg: CharacterBody3D


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
	
	if state == States.LayEgg:
		velocity.y = -1
		velocity.x = lerpf(velocity.x, 0, lay_egg_friction * delta)
		velocity.z = lerpf(velocity.z, 0, lay_egg_friction * delta)
		_egg_time += delta
		if input_scale > move_deadzone:
			_target_rotation = camera.global_rotation.y + input.angle_to(Vector2.UP)
		if _egg_time > egg_lay_time:
			_egg_time = 0
			_egg = EGG_SCENE.instantiate()
			get_parent().add_child(_egg)
			_egg.position = position
			if is_on_floor():
				_egg.process_mode = Node.PROCESS_MODE_DISABLED
				_is_holding_egg = true
				state = States.Idle
			else:
				_egg_jump()
	else:
		if _egg_time <= egg_reload_time:
			_egg_time += delta
		if _layed_egg and is_on_floor():
			_layed_egg = false
	
	if state == States.EggAction:
		_egg_action_time += delta
		velocity.x = lerpf(velocity.x, 0, egg_action_friction * delta)
		velocity.z = lerpf(velocity.z, 0, egg_action_friction * delta)
		velocity.y = max(velocity.y, 0)
		if input_scale > move_deadzone:
			_target_rotation = camera.global_rotation.y + input.angle_to(Vector2.UP)
		if _egg_action_time > egg_action_duration:
			if is_on_floor():
				state = States.Idle
			else:
				state = States.Fall
	
	_smooth_rotation(delta)
	
	if _can_jump() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strenght
		state = States.Jump
	
	if _can_dash() and Input.is_action_just_pressed("dash"):
		state = States.Dash
		_dash_time = 0
		if input_scale > move_deadzone:
			_target_rotation = camera.global_rotation.y + input.angle_to(Vector2.UP)
		if not is_on_floor():
			_used_dash = true
	
	if _can_lay_egg() and Input.is_action_just_pressed("lay_egg"):
		state = States.LayEgg
		_egg_time = 0
		_layed_egg = true
	
	if _is_holding_egg:
		_egg.position = position
		if Input.is_action_just_pressed("dash"):
			_egg.process_mode = Node.PROCESS_MODE_INHERIT
			_egg.velocity = egg_throw_velocity.x * Vector3.FORWARD.rotated(Vector3.UP, _target_rotation) * dash_speed
			_egg.velocity.y = egg_throw_velocity.y
			_is_holding_egg = false
			state = States.EggAction
			_egg_action_time = 0
		elif Input.is_action_just_pressed("lay_egg"):
			_egg.process_mode = Node.PROCESS_MODE_INHERIT
			_egg_jump()
			_is_holding_egg = false
	
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
		States.LayEgg:
			speed = lay_egg_rotaion_speed
		States.EggAction:
			speed = egg_action_rotaion_speed
		
	rotation.y = lerp_angle(rotation.y, _target_rotation, delta * speed)


func _can_jump() -> bool:
	return state != States.LayEgg and is_on_floor()


func _can_dash() -> bool:
	return not _is_holding_egg and not _used_dash and _dash_time > dash_reload_time and state != States.LayEgg


func _can_lay_egg() -> bool:
	return not _layed_egg and state != States.EggAction and not _is_holding_egg and _egg_time > egg_reload_time and state != States.Dash


func _egg_jump() -> void:
	_egg.velocity.y = layed_egg_velocity
	velocity.y = egg_jump_strenght
	state = States.EggAction
	_used_dash = false
	_egg_action_time = 0
