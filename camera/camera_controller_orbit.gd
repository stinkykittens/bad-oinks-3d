extends CameraController

@export var rotation_speed := 50.0
@export var mouse_sensitivity := 0.3
@export var rotation_range := Vector2(-45, 45)


func _process(delta: float) -> void:
	var input: Vector2
	input.x = Input.get_axis("rotate_camera_left", "rotate_camera_right")
	input.y = Input.get_axis("rotate_camera_up", "rotate_camera_down")
	
	rotation_degrees.x -= input.y * rotation_speed * delta;
	rotation_degrees.x = clamp(rotation_degrees.x, rotation_range.x, rotation_range.y)
	rotation_degrees.y -= input.x * rotation_speed * delta;
	rotation_degrees.y = wrapf(rotation_degrees.y, 0, 360)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.x -= event.relative.y * mouse_sensitivity;
		rotation_degrees.x = clamp(rotation_degrees.x, rotation_range.x, rotation_range.y)
		rotation_degrees.y -= event.relative.x * mouse_sensitivity;
		rotation_degrees.y = wrapf(rotation_degrees.y, 0, 360)
