class_name CameraTarget
extends Node3D

@export var _start_active: bool
@export_range(0, 10) var influence := 1.0
@export var interpolate := false
@export var physics_frame := false
@export var interpolation_speed := 1.0
@export var smooth_activation := true
@export var smooth_activation_time := 1.0
@export var validate_target := true
@export var look_at_target := true
@export var position_target := false

var _offset: Vector3
var _active: bool

func _ready() -> void:
	add_to_group("camera_targets")
	var glob_pos = global_position
	_offset = position
	top_level = true
	position = glob_pos
	
	if _start_active:
		activate()


func _process(delta: float) -> void:
	if not disabled() and not physics_frame:
		_update_position(delta)


func _physics_process(delta: float) -> void:
	if not disabled() and physics_frame:
		_update_position(delta)


func _update_position(delta: float) -> void:
	var target_position = get_parent().global_position + _offset
	if not interpolate:
		position = target_position
		return
	position = position.lerp(target_position, delta * interpolation_speed)


func disabled() -> bool:
	return not _active


func activate() -> void:
	_active = true


func deactivate() -> void:
	_active = true


func get_influence() -> float:
	return influence
