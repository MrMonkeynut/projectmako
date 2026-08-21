class_name JumpAttackStep
extends AttackSequenceStep

@export var angle_deg: float = 25.0
@export var magnitude: float = 10.0
@export var aim_at_player_on_launch: bool = true
@export var damage_instance: DamageInstance

func _init(p_angle_deg: float = 25.0, p_magnitude: float = 10.0, p_aim_at_player_on_launch: bool = true, p_damage_instance: DamageInstance = null) -> void:
	angle_deg = p_angle_deg
	magnitude = p_magnitude
	aim_at_player_on_launch = p_aim_at_player_on_launch
	damage_instance = p_damage_instance

func execute(enemy: Enemy) -> void:
	var direction: Vector3 = enemy.get_direction_to_target() if aim_at_player_on_launch else enemy.facing_direction
	var velocity := _compute_launch_velocity(direction, angle_deg, magnitude)
	enemy.launch(velocity)
	enemy.hitbox.hit_trigger = HitTriggers.continuous()
	enemy.hitbox.open(damage_instance)

	await enemy.wait_until_grounded()
	enemy.hitbox.close()

func _compute_launch_velocity(dir: Vector3, angle: float, mag: float) -> Vector3:
	var rad := deg_to_rad(angle)
	var horizontal := dir * cos(rad)
	var vertical := Vector3.UP * sin(rad)
	return (horizontal + vertical) * mag
