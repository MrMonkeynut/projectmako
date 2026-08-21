class_name aa_1_1
extends Enemy

@export var detection_range: float = 20.0
@export var attack_range: float = 5.0

@onready var vision_ray: RayCast3D = $VisionRay

var _running_attack_sequence: bool = false

func _init() -> void:
	speed = 5.0
	stopping_distance = 3.5
	attack_steps = [
		StopMovingStep.new(1),
		JumpAttackStep.new(25.0, 10.0, true, DamageInstance.new(1.0, DamageType.Type.BLUNT)),
		StopMovingStep.new(0.5),
		FollowPlayerStep.new(1),
	]

func _process_unaware(_delta: float) -> void:
	if not player:
		return
	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range:
		return

	if _has_line_of_sight():
		change_state(State.HOSTILE)

func _has_line_of_sight() -> bool:
	var head = player.get_node("Head")
	vision_ray.target_position = vision_ray.to_local(head.global_position)
	vision_ray.force_raycast_update()

	if not vision_ray.is_colliding():
		return true
	return vision_ray.get_collider() == player

func _process_hostile(_delta: float) -> void:
	if _running_attack_sequence or not player:
		return

	var distance := global_position.distance_to(player.global_position)

	if distance <= attack_range and not attack_steps.is_empty():
		velocity.x = 0
		velocity.z = 0
		face_target()
		_running_attack_sequence = true
		await run_sequence(attack_steps)
		_running_attack_sequence = false
		return

	if movement_locked:
		return

	chase_player()
