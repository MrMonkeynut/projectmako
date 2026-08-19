class_name JumpAttackStep
extends AttackSequenceStep

var angle_deg: float
var magnitude: float
var aim_at_player_on_launch: bool
var damage_instance: DamageInstance
var max_airtime: float

func _init(p_angle_deg: float, p_magnitude: float, p_damage_instance: DamageInstance, p_aim_at_player_on_launch: bool = true, p_max_airtime: float = 3.0) -> void:
	angle_deg = p_angle_deg
	magnitude = p_magnitude
	damage_instance = p_damage_instance
	aim_at_player_on_launch = p_aim_at_player_on_launch
	max_airtime = p_max_airtime


func execute(enemy: Enemy) -> void:
	var direction: Vector3 = enemy.get_direction_to_target() if aim_at_player_on_launch else enemy.facing_direction()
	var launch_velocity := _compute_launch_velocity(direction, angle_deg, magnitude)
	enemy.launch(launch_velocity)

	enemy.set_damage_override(damage_instance)
	enemy.hitbox.open()

	await enemy.get_tree().physics_frame  # let the launch take effect before checking grounded state

	var t := 0.0
	while enemy.is_alive() and not enemy.is_grounded() and t < max_airtime:
		t += enemy.get_physics_process_delta_time()
		await enemy.get_tree().physics_frame

	if enemy.is_alive():
		enemy.hitbox.close()
	enemy.clear_damage_override()


func _compute_launch_velocity(dir: Vector3, angle: float, mag: float) -> Vector3:
	var rad := deg_to_rad(angle)
	var horizontal := dir * cos(rad)
	var vertical := Vector3.UP * sin(rad)
	return (horizontal + vertical) * mag
