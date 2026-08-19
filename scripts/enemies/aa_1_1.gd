class_name aa_1_1
extends Enemy

@export var speed: float = 3
@export var detection_range: float = 20.0
@export var engage_range: float = 2.5
@export var jump_angle_deg: float = 45.0
@export var jump_magnitude: float = 12.0
@export var jump_damage: float = 1.0

@onready var vision_ray: RayCast3D = $VisionRay

func _ready() -> void:
	super._ready()
	attack_steps = [
		FollowStep.new(engage_range, speed),
		StopMovingStep.new(0.4, true),
		JumpAttackStep.new(jump_angle_deg, jump_magnitude, DamageInstance.new(jump_damage, DamageType.Type.BLUNT)),
		StopMovingStep.new(0.4, true),
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
		print("LOS: clear")
		return true

	print("LOS: hit ", vision_ray.get_collider().name)
	return vision_ray.get_collider() == player

func _process_hostile(_delta: float) -> void:
	await run_sequence(attack_steps)
	# transition back to HOSTILE/SEARCH/whatever comes after
	#if player:
		#var direction = (player.global_position - global_position).normalized()
		#velocity = direction * speed
		#move_and_slide()
	
