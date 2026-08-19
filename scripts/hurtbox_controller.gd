extends Area3D
class_name HurtboxController


signal damaged(instance: DamageInstance)


func receive_damage(instance: DamageInstance) -> void:
	damaged.emit(instance)

## Finds an existing "Hurtbox" child under parent, or builds a default one
## from the given shape/offset/layer. This is where the shape-building
## default lives now — not hardcoded on Entity.
static func get_or_create(parent: Node, shape: Shape3D, offset: Vector3, layer: int) -> HurtboxController:
	var existing := parent.get_node_or_null("Hurtbox")
	if existing:
		if not (existing is HurtboxController):
			existing.set_script(HurtboxController)
		return existing

	var hurtbox := HurtboxController.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = layer
	hurtbox.collision_mask = 0
	parent.add_child(hurtbox)

	var shape_node := CollisionShape3D.new()
	shape_node.shape = shape if shape else _default_shape()
	shape_node.position = offset
	hurtbox.add_child(shape_node)

	return hurtbox

static func _default_shape() -> Shape3D:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	return capsule
