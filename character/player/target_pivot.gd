extends Node3D

@export var velocity_influence_xz := 0.1
@export var velocity_influence_y := 0.1
@export var speed_ground := 2.0
@export var speed_air := 1.0
@export var instant_position_blend_speed := 3.0
@export var instant_position_blend_amount := 9.0

@onready var target: CameraTarget = $CameraTargetPosition
@onready var target_instant: CameraTarget = $"../CameraTargetInstant"
@onready var camera_controller: CameraController = $"../CameraController"

var player: Player

var _instant_blend: float

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
	
	_instant_blend = lerpf(_instant_blend, camera_controller.look_at_cancel_amount * instant_position_blend_amount, instant_position_blend_speed * delta)
	target_instant.influence = _instant_blend


func _on_state_changed(state: Player.State) -> void:
	match state:
		Player.State.Idle, Player.State.Run:
			target.interpolation_speed = speed_ground
		Player.State.Jump, Player.State.Fall, Player.State.Dash:
			target.interpolation_speed = speed_air
