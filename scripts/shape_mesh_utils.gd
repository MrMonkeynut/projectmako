class_name ShapeMeshUtils

static func create_mesh(parent: Node3D, color: Color) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.material_override = mat
	parent.add_child(mesh_instance)
	return mesh_instance


static func rebuild_mesh(mesh_instance: MeshInstance3D, tris: PackedVector3Array) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in tris:
		im.surface_add_vertex(v)
	im.surface_end()
	mesh_instance.mesh = im
