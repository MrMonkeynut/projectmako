class_name FollowPlayerStep
extends AttackSequenceStep

@export var duration: float = 1.0

func _init(p_duration: float = 1.0) -> void:
	duration = p_duration

func execute(enemy: Enemy) -> void:
	var t := 0.0
	while t < duration:
		enemy.chase_player()
		t += enemy.get_physics_process_delta_time()
		await enemy.get_tree().physics_frame
