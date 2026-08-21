extends Resource
class_name HitboxShapeDefinition

func build_collision_shape() -> Shape3D:
		push_error("build_collision_shape() not implemented on " + str(self))
		return null
		
func build_debug_triangles() -> PackedVector3Array:
	push_error("build_debug_triangles() not implemented on " + str(self))
	return PackedVector3Array()
