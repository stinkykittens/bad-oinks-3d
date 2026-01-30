@tool
class_name CSGMapTool
extends CSGCombiner3D

@export var divisions := 8
@export var minimum_vertex_distance := 2.6
@export var divide_walls_only := true
@export_range(0, 1) var walls_treshold := 0.5
@export var deep_vertex_color_copy := true
@export var _generate: bool:
	set(v):
		_generate = true
		await get_tree().process_frame
		await get_tree().process_frame
		generate()
		_generate = false

@export var _generated_mesh_instance: MeshInstance3D


func _ready() -> void:
	if is_instance_valid(_generated_mesh_instance) and not Engine.is_editor_hint():
		queue_free()


func generate() -> void:
	
	# Previous mesh to restore vertex data
	var previous_mesh: ArrayMesh
	if _generated_mesh_instance:
		previous_mesh = _generated_mesh_instance.mesh
	
	# Generate new static mesh
	var mesh = bake_static_mesh()
	mesh = deindex_mesh(mesh)
	
	for i in divisions:
		mesh = _divide_mesh(mesh)
	
	if previous_mesh:
		mesh = _retarget_vertex_colors(mesh, previous_mesh)
	mesh = index_mesh(mesh)
	
	# Add Nodes to scene
	var holder_name = name + "Static"
	if get_parent().has_node(holder_name):
		get_parent().get_node(holder_name).queue_free()
		get_parent().remove_child(get_parent().get_node(holder_name))
	
	var holder = Node3D.new()
	add_sibling(holder)
	holder.owner = owner
	holder.name = holder_name
	
	_generated_mesh_instance = MeshInstance3D.new()
	_generated_mesh_instance.mesh = mesh
	holder.add_child(_generated_mesh_instance, true)
	_generated_mesh_instance.owner = owner
	_generated_mesh_instance.material_override = material_override
	
	if use_collision:
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = bake_collision_shape()
		var collision_body = StaticBody3D.new()
		collision_body.collision_layer = collision_layer
		collision_body.collision_mask = collision_mask
		collision_body.collision_priority = collision_priority
		holder.add_child(collision_body, true)
		collision_body.owner = owner
		collision_body.add_child(collision_shape, true)
		collision_shape.owner = owner
		collision_shape.hide()
	
	hide()

func _divide_mesh(mesh: Mesh) -> Mesh:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	for sur_idx in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(sur_idx)
		var indices_count = 0
		print(arrays[Mesh.ARRAY_VERTEX].size())
		for i in range(0, arrays[Mesh.ARRAY_VERTEX].size(), 3):
			var skip_dividing = false
			
			if divide_walls_only:
				var avg_normal = (arrays[Mesh.ARRAY_NORMAL][i] + arrays[Mesh.ARRAY_NORMAL][i + 1] + arrays[Mesh.ARRAY_NORMAL][i + 2]) / 3
				if abs(avg_normal.dot(Vector3.UP)) > walls_treshold:
					skip_dividing = true
			
			var dist_ab = arrays[Mesh.ARRAY_VERTEX][i].distance_squared_to(arrays[Mesh.ARRAY_VERTEX][i + 1])
			var dist_ac = arrays[Mesh.ARRAY_VERTEX][i].distance_squared_to(arrays[Mesh.ARRAY_VERTEX][i + 2])
			var dist_cb = arrays[Mesh.ARRAY_VERTEX][i + 1].distance_squared_to(arrays[Mesh.ARRAY_VERTEX][i + 2])
			
			var longest_distance = max(max(dist_ab, dist_ac), dist_cb)
			
			if sqrt(longest_distance) < minimum_vertex_distance:
				skip_dividing = true
			
			if skip_dividing:
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 1])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 1])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 2])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 2])
				indices.append_array([indices_count, indices_count + 1, indices_count + 2])
				indices_count += 3
			elif longest_distance == dist_ab:
				var d = (arrays[Mesh.ARRAY_VERTEX][i] + arrays[Mesh.ARRAY_VERTEX][i + 1]) / 2
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
				vertices.push_back(d)
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 2])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 2])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 2])
	
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 2])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 2])
				vertices.push_back(d)
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 2])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 1])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 1])
			elif longest_distance == dist_ac:
				var d = (arrays[Mesh.ARRAY_VERTEX][i] + arrays[Mesh.ARRAY_VERTEX][i + 2]) / 2
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 1])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 1])
				vertices.push_back(d)
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 1])
				
				vertices.push_back(d)
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 1])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 1])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 1])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 2])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 2])
			elif longest_distance == dist_cb:
				var d = (arrays[Mesh.ARRAY_VERTEX][i + 2] + arrays[Mesh.ARRAY_VERTEX][i + 1]) / 2
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 1])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 1])
				vertices.push_back(d)
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
				
				vertices.push_back(d)
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 2])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 2])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
	
	var new_mesh = ArrayMesh.new()
	var surface_arrays = []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = vertices
	surface_arrays[Mesh.ARRAY_NORMAL] = normals
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	return new_mesh


func _retarget_vertex_colors(mesh: ArrayMesh, old_mesh: ArrayMesh) -> Mesh:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	
	for sur_idx in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(sur_idx)
		var old_arrays = index_mesh(old_mesh).surface_get_arrays(sur_idx)
		
		for i in arrays[Mesh.ARRAY_VERTEX].size():
			
			var color := Color.WHITE
			var vertex_index = old_arrays[Mesh.ARRAY_VERTEX].find(arrays[Mesh.ARRAY_VERTEX][i])
			
			if vertex_index != -1:
				color = old_arrays[Mesh.ARRAY_COLOR][vertex_index]
			elif deep_vertex_color_copy:
				var distances = PackedFloat32Array()
				for vi in old_mesh.surface_get_array_len(sur_idx):
					distances.push_back(arrays[Mesh.ARRAY_VERTEX][i].distance_squared_to(old_arrays[Mesh.ARRAY_VERTEX][vi]))
				var unsorted_distances = distances.duplicate()
				distances.sort()
				vertex_index = unsorted_distances.find(distances[0])
				if vertex_index != -1:
					color = old_arrays[Mesh.ARRAY_COLOR][vertex_index]
			
			vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i])
			normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
			colors.push_back(color)
	
	var new_mesh = ArrayMesh.new()
	var surface_arrays = []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = vertices
	surface_arrays[Mesh.ARRAY_NORMAL] = normals
	surface_arrays[Mesh.ARRAY_COLOR] = colors
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	return new_mesh


func index_mesh(mesh: Mesh) -> Mesh:
	var surface = SurfaceTool.new()
	for sur_idx in mesh.get_surface_count():
		surface.append_from(mesh, sur_idx, Transform3D.IDENTITY)
	surface.index()
	return surface.commit()


func deindex_mesh(mesh: Mesh) -> Mesh:
	var surface = SurfaceTool.new()
	for sur_idx in mesh.get_surface_count():
		surface.append_from(mesh, sur_idx, Transform3D.IDENTITY)
	surface.deindex()
	return surface.commit()
