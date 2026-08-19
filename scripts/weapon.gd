extends Resource
class_name Weapon

@export var weapon_name: String = "Weapon"
@export var icon: Texture2D

@export_group("Damage")
@export var damage_amount: float = 1.0
@export var damage_type: DamageType.Type = DamageType.Type.SLASH

@export_group("Hitbox")
@export var shape_def: HitboxShapeDefinition
@export var active_window: float = 0.15  ## seconds hitbox stays live per swing

@export_group("Timing")
@export var windup_time: float = 0.0  ## seconds before the attack becomes active
@export var attack_cooldown: float = 0.4  ## time before this weapon can attack again

@export_group("Movement")
@export_range(0.0, 1.0, 0.01) var windup_move_speed_mod: float = 0.0  ## % of normal move speed during windup only. Active window is always 0 (locked). Cooldown is unaffected.
