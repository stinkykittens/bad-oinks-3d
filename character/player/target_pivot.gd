extends Node3D

@export var velocity_influence_xz := 0.1
@export var velocity_influence_y := 0.1
@export var speed_ground := 2.0
@export var speed_air := 1.0

@onready var target: CameraTarget = %CameraTargetPosition

var player: Player

func _ready() -> void:
	player = owner
	top_level = true
	player.state_changed.connect(_on_state_changed)


func _process(_delta: float) -> void:
	if not player.state == Player.State.Dash:
		position.x = player.global_position.x + player.velocity.x * velocity_influence_xz
		position.z = player.global_position.z + player.velocity.z * velocity_influence_xz
	#if not player.state == Player.State.Jump:
	position.y = player.global_position.y + player.velocity.y * velocity_influence_y


func _on_state_changed(state: Player.State) -> void:
	match state:
		Player.State.Idle, Player.State.Run:
			target.interpolation_speed = speed_ground
		Player.State.Jump, Player.State.Fall, Player.State.Dash:
			target.interpolation_speed = speed_air
