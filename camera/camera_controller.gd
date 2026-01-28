class_name CameraController
extends Node3D


@export var distance := 6.0
@export var zoom_out_speed := 6.0


@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var ray_cast: RayCast3D = $RayCast3D

var _camera_distance: float


func _ready() -> void:
	top_level = true
	ray_cast.enabled = false


func _physics_process(delta: float) -> void:
	var targets := get_tree().get_nodes_in_group("camera_targets")
	var target_position := _calculate_position(targets, false)
	var look_at_position := _calculate_position(targets, true)
	
	position = target_position
	
	var target_distance:= distance
	ray_cast.target_position = Vector3.BACK * distance
	ray_cast.force_raycast_update()
	
	if ray_cast.is_colliding():
		target_distance = target_position.distance_to(ray_cast.get_collision_point())
	
	if target_distance < _camera_distance:
		_camera_distance = target_distance
	else:
		_camera_distance = lerp(_camera_distance, target_distance, delta * zoom_out_speed)
	
	camera_pivot.position = Vector3.BACK * _camera_distance
	if ray_cast.is_colliding():
		camera_pivot.global_position += ray_cast.get_collision_normal() * camera.near
	camera.look_at(look_at_position)


func _calculate_position(targets: Array, _look_at: bool) -> Vector3:
	var pos := Vector3.ZERO
	var total_influence := 0.0
	for t in targets:
		if t.disabled():
			continue
		var influence = t.get_influence(_look_at)
		pos += t.global_position * influence
		total_influence += influence
	
	return pos / total_influence if total_influence > 0 else position
