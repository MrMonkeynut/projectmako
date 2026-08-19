class_name StopMovingStep
extends AttackSequenceStep

@export var duration: float = 0.4
@export var aim_at_player: bool = true

func execute(enemy: Enemy) -> void:
	enemy.set_movement_locked(true)
	var t := 0.0
	while t < duration:
		if aim_at_player:
			enemy.face_target()
		t += enemy.get_physics_process_delta_time()
		await enemy.get_tree().physics_frame
	enemy.set_movement_locked(false)
