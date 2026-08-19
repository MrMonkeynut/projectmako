class_name FollowStep
extends AttackSequenceStep

var engage_range: float
var move_speed: float

func _init(p_engage_range: float, p_move_speed: float) -> void:
	engage_range = p_engage_range
	move_speed = p_move_speed


func execute(enemy: Enemy) -> void:
	while enemy.is_alive() and enemy.distance_to_target() > engage_range:
		enemy.move_toward_target(move_speed)
		await enemy.get_tree().physics_frame
