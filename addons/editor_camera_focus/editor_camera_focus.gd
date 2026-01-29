@tool
extends EditorPlugin


# cached triangular meshes in case multiple instances share the same mesh resource
var trimesh_cache := {}


func _enable_plugin():
	# forward 3d viewport events even if no node is selected
	set_input_event_forwarding_always_enabled()


func _forward_3d_gui_input(viewport_camera, event) -> int:
	# do our thing on ALT + MMB
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.is_pressed() and event.alt_pressed:
			focus_cam_to_surface_point(event.position, viewport_camera)
	return AFTER_GUI_INPUT_PASS
	 
	
func focus_cam_to_surface_point(screen_position: Vector2, cam: Camera3D) -> void:
	# calculate pick ray in world space
	var ray_origin: Vector3 = cam.project_ray_origin(screen_position)
	var ray_direction: Vector3 = cam.project_ray_normal(screen_position)
	
	# get all mesh instances in the scene
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	var mesh_instances: Array = scene_root.find_children("*", "MeshInstance3D", true, false)
	
	# exclude invisible mesh instances
	mesh_instances = mesh_instances.filter(
			func(mi: MeshInstance3D): 
				return mi.is_visible_in_tree()
	)
	
	# get mouse ray hitpoints on all hit meshes
	trimesh_cache = {}
	var hitpoints: Array[Vector3] = []
	for instance: MeshInstance3D in mesh_instances:
		var hit_position = _mesh_instance_intersect_ray(instance, ray_origin, ray_direction)
		if hit_position:
			hitpoints.append(hit_position)

	# sort hitpoints by distance to camera
	hitpoints.sort_custom(
			func(a: Vector3, b: Vector3):
				return cam.global_position.distance_squared_to(a) < cam.global_position.distance_squared_to(b)
	)
	# decide the target position: nearest hitpoint or ground if there are no hitpoints
	var target_position: Vector3
	if hitpoints.is_empty():
		var plane_hit: Variant = Plane(Vector3.UP).intersects_ray(ray_origin, ray_direction) 
		if plane_hit:
			target_position = plane_hit
		else:
			return # ray cannot hit ground, we're out of target options
	else:
		target_position = hitpoints[0]
	
	# create a dummy target node
	var dummy_target: Node3D = Node3D.new()
	scene_root.add_child(dummy_target)
	dummy_target.owner = scene_root # make dummy node visible in the editor (for debugging)
	dummy_target.global_position = target_position
	
	# store the current selection and select the dummy target node
	var editor_selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes_before: Array = editor_selection.get_selected_nodes()
	editor_selection.clear()
	editor_selection.add_node(dummy_target)
	
	# trigger editor's built in focus by faking the hotkey F press
	# (is there a better way to do this?)
	var persp_popup: PopupMenu = _get_perspective_popup_menu(cam.get_viewport())
	if persp_popup:
		var e: InputEventKey = InputEventKey.new()
		e.keycode = KEY_F
		e.pressed = true
		persp_popup.activate_item_by_event(e)

	# delete the dummy target node and restore selection
	dummy_target.queue_free()
	for node in selected_nodes_before:
		editor_selection.add_node(node)

	# purge trimesh cache
	trimesh_cache = {}

	
func _find_viewport(node: Node) -> SubViewport:
	while true:
		node = node.get_parent()
		var vports = node.find_children("*", "SubViewport", true, false)
		if not vports.is_empty():
			return vports[0] as SubViewport
	return null


func _get_perspective_popup_menu(vport: SubViewport) -> PopupMenu:
	for b in EditorInterface.get_editor_main_screen().find_children("*", "Button", true, false):
		if b.text.contains("Perspective"):
			var p: PopupMenu = b.find_children("*", "PopupMenu", false, false)[0]
			if _find_viewport(p) == vport:
				return p
	return null


func _mesh_instance_intersect_ray(instance: MeshInstance3D, ray_origin: Vector3, ray_direction: Vector3) -> Variant:
	# make trimesh (and cache it) ot get it from our cache
	var trimesh: TriangleMesh = trimesh_cache.get_or_add(instance.mesh, instance.mesh.generate_triangle_mesh())
	
	# get ray in instance local space
	var to_instance_space = instance.global_transform.affine_inverse()
	var ray_origin_local: Vector3 = to_instance_space * ray_origin
	var ray_direction_local: Vector3 = to_instance_space.basis * ray_direction
	
	# intersect and append hitpoint if mesh was hit
	var result: Dictionary = trimesh.intersect_ray(ray_origin_local, ray_direction_local)
	if result:
		return instance.global_transform * result["position"]
	else:
		return null
	
	
