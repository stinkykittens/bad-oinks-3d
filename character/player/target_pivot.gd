extends Node3D

@export var velocity_influence_xz := 0.1
@export var velocity_influence_y := 0.1

var player: Player

func _ready() -> void:
	player = owner
	top_level = true


func _process(delta: float) -> void:
	if not player.state == Player.States.Dash:
		position.x = player.global_position.x + player.velocity.x * velocity_influence_xz
		position.z = player.global_position.z + player.velocity.z * velocity_influence_xz
	position.y = player.global_position.y + player.velocity.y * velocity_influence_y
