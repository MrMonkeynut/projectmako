extends HitboxShapeDefinition
class_name WedgeHitboxShape

## Offset-apex wedge, clipped to the region in front of the player.
## The apex sits behind the player only to widen the outline at z = 0 —
## everything behind that plane is cut away, so it never contributes
## hittable area. Collision shape and debug mesh are both built from the
## SAME clipped footprint, so they can never disagree.

@export var angle_deg: float = 90.0
@export var radius: float = 2.0       ## reach measured FROM THE PLAYER
@export var apex_offset: float = 0.4  ## how far behind the player the apex sits
@export var height: float = 1.5
@export var segments: int = 8


func build_collision_shape() -> Shape3D:
	var shape := ConvexPolygonShape3D.new()
	shape.points = _extrude(_forward_footprint())
	return shape


func build_debug_triangles() -> PackedVector3Array:
	return _triangulate(_forward_footprint())


## The flat (Y=0) outline of the ACTIVE hitbox — the raw fan, clipped to
## z <= 0. This is the single source of truth both other methods build from.
func _forward_footprint() -> Array[Vector3]:
	return _clip_to_forward_half(_raw_fan_outline())


## Un-clipped fan outline: apex + arc points, in order around the boundary.
## Convex, but may extend slightly behind the player (z > 0) near the apex.
func _raw_fan_outline() -> Array[Vector3]:
	var half_angle := deg_to_rad(angle_deg) * 0.5
	var apex := _apex()
	var effective_radius := radius + apex_offset

	var outline: Array[Vector3] = [apex]
	for i in range(segments + 1):
		var t := float(i) / segments
		var a: float = lerp(-half_angle, half_angle, t)
		var dir := Vector3(sin(a), 0, -cos(a))
		outline.append(apex + dir * effective_radius)
	return outline


func _apex() -> Vector3:
	return Vector3(0, 0, apex_offset)


## Sutherland-Hodgman clip of a convex polygon against the half-plane z <= 0.
func _clip_to_forward_half(poly: Array[Vector3]) -> Array[Vector3]:
	var output: Array[Vector3] = []
	var count := poly.size()

	for i in range(count):
		var current: Vector3 = poly[i]
		var prev: Vector3 = poly[(i - 1 + count) % count]
		var current_inside := current.z <= 0.0
		var prev_inside := prev.z <= 0.0

		if current_inside:
			if not prev_inside:
				output.append(_intersect_z_zero(prev, current))
			output.append(current)
		elif prev_inside:
			output.append(_intersect_z_zero(prev, current))

	return output


func _intersect_z_zero(a: Vector3, b: Vector3) -> Vector3:
	var t: float = -a.z / (b.z - a.z)
	return a + (b - a) * t


## Extrudes a flat footprint into a bottom+top point cloud for
## ConvexPolygonShape3D.points.
func _extrude(footprint: Array[Vector3]) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for p in footprint:
		pts.append(p)
	for p in footprint:
		pts.append(p + Vector3(0, height, 0))
	return pts


## Fan-triangulates a convex flat footprint into a solid prism
## (bottom cap, top cap, side walls) for debug rendering.
func _triangulate(footprint: Array[Vector3]) -> PackedVector3Array:
	var tris := PackedVector3Array()
	var count := footprint.size()
	if count < 3:
		return tris

	var top: Array[Vector3] = []
	for p in footprint:
		top.append(p + Vector3(0, height, 0))

	for i in range(1, count - 1):
		tris.append_array([footprint[0], footprint[i], footprint[i + 1]])
		tris.append_array([top[0], top[i + 1], top[i]])

	for i in range(count):
		var b0: Vector3 = footprint[i]
		var b1: Vector3 = footprint[(i + 1) % count]
		var t0: Vector3 = top[i]
		var t1: Vector3 = top[(i + 1) % count]
		tris.append_array([b0, b1, t1])
		tris.append_array([b0, t1, t0])

	return tris
