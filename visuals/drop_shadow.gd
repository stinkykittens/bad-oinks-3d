class_name DropShadow
extends RayCast3D

@export var distance: float = 10
@export var always_visible: bool
@export var visible_distance := 50.0
@export var decal_texture: Texture2D = preload("res://visuals/shadow_decal.tres")
@export var decal_size: float = 1
@export var extra_size: float = 4

var decal: Decal

func _ready() -> void:
	target_position = Vector3.DOWN * distance
	if always_visible:
		visible = true
	
	decal = Decal.new()
	decal.normal_fade = 0.4
	decal.lower_fade = 0.2
	decal.upper_fade = 0
	decal.texture_albedo = decal_texture
	decal.size = Vector3(decal_size, 0, decal_size)
	decal.cull_mask = 1
	add_child(decal)
	

func _physics_process(_delta: float) -> void:
	
	if not always_visible:
		var cam := get_viewport().get_camera_3d()
		if cam and cam.global_position.distance_to(global_position) > visible_distance:
			visible = false
			return
	
	visible = true
	
	var collision_point: = get_collision_point()
	var y_offset: float = abs(collision_point.y - global_position.y) + extra_size
	decal.size.y = y_offset + 0.3
	decal.position.y = -y_offset / 2
