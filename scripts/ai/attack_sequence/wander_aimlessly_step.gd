class_name WanderAimlesslyStep
extends AttackSequenceStep

@export var duration: float = 1.0

func _init(p_duration: float = 1.0) -> void:
	duration = p_duration

func execute(enemy: Enemy) -> void:
	var direction := _random_direction()
	enemy.look_at(enemy.global_position + direction, Vector3.UP)

	var t := 0.0
	while t < duration:
		enemy.velocity.x = direction.x * enemy.speed
		enemy.velocity.z = direction.z * enemy.speed
		t += enemy.get_physics_process_delta_time()
		await enemy.get_tree().physics_frame

func _random_direction() -> Vector3:
	var angle := randf() * TAU
	return Vector3(cos(angle), 0, sin(angle))
