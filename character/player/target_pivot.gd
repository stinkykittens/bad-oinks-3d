extends Node3D

@export var velocity_influence_xz := 0.1
@export var velocity_influence_y := 0.1
@export var speed_ground := 2.0
@export var speed_air := 1.0
@export var speed_tween_duration := 0.2
@export var instant_position_blend_speed := 3.0
@export var instant_position_blend_curve: Curve
@export var instant_position_amount_curve: Curve

@onready var target: CameraTarget = $CameraTargetPosition
#@onready var target_instant: CameraTarget = $"../CameraTargetInstant"
@onready var target_instant: CameraTarget = $CameraTargetInstant
@onready var camera_controller: CameraController = $"../CameraController"

var player: Player

var _instant_blend: float
var _speed_tween: Tween

func _ready() -> void:
	player = owner
	top_level = true
	player.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if not player.state == Player.State.Dash:
		position.x = player.global_position.x + player.velocity.x * velocity_influence_xz
		position.z = player.global_position.z + player.velocity.z * velocity_influence_xz
	#if not player.state == Player.State.Jump:
	position.y = player.global_position.y + player.velocity.y * velocity_influence_y
	
	var target_blend = instant_position_amount_curve.sample((1 + camera_controller.camera.global_basis.z.dot((camera_controller.camera.global_position.direction_to(global_position)))))
	_instant_blend = lerpf(_instant_blend, target_blend, instant_position_blend_speed * delta)
	#_instant_blend = move_toward(_instant_blend, target_blend, delta * instant_position_blend_speed)
	var blend = instant_position_blend_curve.sample(_instant_blend)
	target_instant.influence = blend
	target.influence = 1.0 - blend
	printt(blend, _instant_blend)


func _on_state_changed(state: Player.State) -> void:
	var target_speed := -1.0
	var easing: int
	
	match state:
		Player.State.Idle, Player.State.Run:
			target_speed = speed_ground
			easing = Tween.EASE_OUT
		Player.State.Jump, Player.State.Fall, Player.State.Dash:
			target_speed = speed_air
			easing = Tween.EASE_IN
	
	if target_speed != -1.0:
		if _speed_tween:
			if _speed_tween.is_running():
				await _speed_tween.finished
			else:
				_speed_tween.kill()
		_speed_tween = create_tween()
		_speed_tween.tween_property(target, ^"interpolation_speed", target_speed, speed_tween_duration)\
			.set_ease(easing).set_trans(Tween.TRANS_QUAD)
