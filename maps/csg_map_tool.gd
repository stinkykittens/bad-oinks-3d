@tool
class_name CSGMapTool
extends CSGCombiner3D

@export var divisions := 8
@export var minimum_vertex_distance := 0.4
@export var _generate: bool:
	set(v):
		_generate = false
		generate()

@export var _generated_mesh_instance: MeshInstance3D

func _ready() -> void:
	if is_instance_valid(_generated_mesh_instance) and not Engine.is_editor_hint():
		queue_free()


func generate() -> void:
	if _generated_mesh_instance:
		get_parent().remove_child(_generated_mesh_instance)
		_generated_mesh_instance.queue_free()
	
	var mesh = bake_static_mesh()
	
	for i in divisions:
		mesh = _divide_mesh(mesh)
	
	_generated_mesh_instance = MeshInstance3D.new()
	_generated_mesh_instance.mesh = mesh
	add_sibling(_generated_mesh_instance)
	_generated_mesh_instance.name = "GeneratedMapMeshInstance"
	_generated_mesh_instance.owner = owner
	_generated_mesh_instance.material_override = material_override


func _divide_mesh(mesh: Mesh) -> Mesh:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	
	for sur_idx in mesh.get_surface_count():
		@warning_ignore("confusable_local_declaration")
		var arrays = mesh.surface_get_arrays(sur_idx)
		print(arrays[Mesh.ARRAY_VERTEX].size())
		print(arrays[Mesh.ARRAY_TANGENT].size())
		for i in range(0, arrays[Mesh.ARRAY_VERTEX].size(), 3):
			var dist_ab = arrays[Mesh.ARRAY_VERTEX][i].distance_squared_to(arrays[Mesh.ARRAY_VERTEX][i + 1])
			var dist_ac = arrays[Mesh.ARRAY_VERTEX][i].distance_squared_to(arrays[Mesh.ARRAY_VERTEX][i + 2])
			var dist_cb = arrays[Mesh.ARRAY_VERTEX][i + 1].distance_squared_to(arrays[Mesh.ARRAY_VERTEX][i + 2])
			
			var longest_distance = max(max(dist_ab, dist_ac), dist_cb)
			var d: Vector3
			
			if sqrt(longest_distance) < minimum_vertex_distance:
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 1])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 1])
				vertices.push_back(arrays[Mesh.ARRAY_VERTEX][i + 2])
				normals.push_back(arrays[Mesh.ARRAY_NORMAL][i + 2])
				continue
			
			if longest_distance == dist_ab:
				d = (arrays[Mesh.ARRAY_VERTEX][i] + arrays[Mesh.ARRAY_VERTEX][i + 1]) / 2
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
				d = (arrays[Mesh.ARRAY_VERTEX][i] + arrays[Mesh.ARRAY_VERTEX][i + 2]) / 2
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
				d = (arrays[Mesh.ARRAY_VERTEX][i + 2] + arrays[Mesh.ARRAY_VERTEX][i + 1]) / 2
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
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return new_mesh
