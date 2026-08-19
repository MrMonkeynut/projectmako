class_name StopMovingStep
extends AttackSequenceStep

var duration: float
var aim_at_player: bool

func _init(p_duration: float = 0.4, p_aim_at_player: bool = true) -> void:
	duration = p_duration
	aim_at_player = p_aim_at_player


func execute(enemy: Enemy) -> void:
	enemy.velocity.x = 0
	enemy.velocity.z = 0
	var t := 0.0
	while enemy.is_alive() and t < duration:
		if aim_at_player:
			enemy.face_target()
		t += enemy.get_physics_process_delta_time()
		await enemy.get_tree().physics_frame
