class_name Entity
extends CharacterBody3D
signal weapon_equipped(weapon: Weapon)
@export var max_health: float = 4.0
@export var hurtbox_shape: Shape3D
@export var hurtbox_offset: Vector3 = Vector3(0, 0.9, 0)
@export_flags_3d_physics var hurtbox_layer: int = 0
@export var show_health_label: bool = true
@export var health_label_offset: Vector3 = Vector3(0, 1.0, 0)
@export var equipped_weapon: Weapon:
	set(value):
		equipped_weapon = value
		if hitbox and equipped_weapon:
			hitbox.configure_from_weapon(equipped_weapon)
		weapon_equipped.emit(equipped_weapon)

enum AttackPhase { NONE, WINDUP, ACTIVE, COOLDOWN }
var _attack_phase: AttackPhase = AttackPhase.NONE

var health: float
var hurtbox: HurtboxController
var hitbox: HitboxController
var _health_label: Label3D


func _ready() -> void:
	health = max_health
	_handle_hurtbox()
	_handle_hitbox()
	_handle_labels()
	if hitbox and equipped_weapon:
		hitbox.configure_from_weapon(equipped_weapon)


func _handle_hurtbox() -> void:
	hurtbox = HurtboxController.get_or_create(self, hurtbox_shape, hurtbox_offset, hurtbox_layer)
	hurtbox.damaged.connect(receive_damage)


func _handle_hitbox() -> void:
	hitbox = find_child("Hitbox")
	if hitbox:
		hitbox.set_exclusions([self, hurtbox])
		hitbox.attack_landed.connect(_on_attack_landed)


func _handle_labels() -> void:
	if show_health_label:
		_setup_health_label()


func take_damage(amount: float) -> void:
	health -= amount
	_update_health_label()
	if health <= 0:
		die()


func receive_damage(instance: DamageInstance) -> void:
	take_damage(instance.amount)


func die() -> void:
	queue_free()


func _is_attacking() -> bool:
	return _attack_phase != AttackPhase.NONE


## Runs the windup -> active -> cooldown sequence for equipped_weapon.
## Caller (Player input, an AttackSequence, ...) decides WHEN to call
## this; Entity owns the state machine so Player and Enemy share it.
func _perform_attack() -> void:
	if not equipped_weapon or not hitbox:
		return

	_attack_phase = AttackPhase.WINDUP
	hitbox.set_debug_state(HitboxController.DebugState.WINDUP)
	if equipped_weapon.windup_time > 0.0:
		await get_tree().create_timer(equipped_weapon.windup_time).timeout

	_attack_phase = AttackPhase.ACTIVE
	hitbox.open()
	await get_tree().create_timer(equipped_weapon.active_window).timeout
	hitbox.close()

	_attack_phase = AttackPhase.COOLDOWN
	hitbox.set_debug_state(HitboxController.DebugState.COOLDOWN)
	if equipped_weapon.attack_cooldown > 0.0:
		await get_tree().create_timer(equipped_weapon.attack_cooldown).timeout

	_attack_phase = AttackPhase.NONE
	hitbox.set_debug_state(HitboxController.DebugState.IDLE)


func _on_attack_landed(target: Node) -> void:
	if equipped_weapon:
		deal_damage(target, equipped_weapon.damage_amount, equipped_weapon.damage_type)


func deal_damage(target: Node, amount: float, type: DamageType.Type) -> void:
	if not target.has_method("receive_damage"):
		return
	var instance := DamageInstance.new(amount, type)
	instance.source = self
	target.receive_damage(instance)


func _setup_health_label() -> void:
	_health_label = Label3D.new()
	_health_label.position = health_label_offset
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_label.no_depth_test = true
	_health_label.font_size = 80
	_health_label.outline_size = 8
	add_child(_health_label)
	_update_health_label()


func _update_health_label() -> void:
	if _health_label:
		_health_label.text = str(int(health))
