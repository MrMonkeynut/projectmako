class_name Entity
extends CharacterBody3D
signal weapon_equipped(weapon: Weapon)
signal health_changed(current: float, max_value: float)
@export var max_health: float = 3.0
@export var hurtbox_shape: Shape3D
@export var hurtbox_offset: Vector3 = Vector3(0, 0.9, 0)
@export_flags_3d_physics var hurtbox_layer: int = 0
@export var show_health_label: bool = true
@export var health_label_offset: Vector3 = Vector3(0, 1.0, 0)
@export var flash_color: Color = Color(1, 0, 0)
@export var flash_duration: float = 0.15
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
var _health_bar: StatBarController
var _flash_material: StandardMaterial3D
var _flash_meshes: Array[MeshInstance3D] = []
var _flash_time_left: float = 0.0
var _persistent_tint_material: Material = null


func _ready() -> void:
	health = max_health
	_handle_hurtbox()
	_handle_hitbox()
	_handle_labels()
	_handle_health_bar()
	_handle_flash()
	health_changed.emit(health, max_health)
	if hitbox and equipped_weapon:
		hitbox.configure_from_weapon(equipped_weapon)


func _process(delta: float) -> void:
	if _flash_time_left <= 0.0:
		return
	_flash_time_left -= delta
	if _flash_time_left <= 0.0:
		_set_flashing(false)


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


## Zeroes horizontal velocity, leaving vertical (gravity/jump) untouched.
func stop_moving() -> void:
	velocity.x = 0
	velocity.z = 0


func take_damage(amount: float) -> void:
	health -= amount
	_update_health_label()
	health_changed.emit(health, max_health)
	_flash_red()
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
	if hitbox.damage_override:
		if not target.has_method("receive_damage"):
			return
		var instance := hitbox.damage_override
		instance.source = self
		target.receive_damage(instance)
	elif equipped_weapon:
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


## Wires an optional "HealthBar" child (a StatBarController) up to
## health_changed. Entity doesn't build or own any bar visuals itself —
## that's StatBarController's job; this just connects it if one is present.
func _handle_health_bar() -> void:
	_health_bar = find_child("HealthBar")
	if _health_bar:
		health_changed.connect(_health_bar.set_value)


func _handle_flash() -> void:
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = flash_color
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_collect_flash_meshes(self)


## Collects MeshInstance3D nodes for the flash, skipping HitboxController
## subtrees so debug hitbox meshes don't get tinted along with the model.
func _collect_flash_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is HitboxController:
			continue
		if child is MeshInstance3D:
			_flash_meshes.append(child)
		_collect_flash_meshes(child)


func _flash_red() -> void:
	_flash_time_left = flash_duration
	_set_flashing(true)


func _set_flashing(enabled: bool) -> void:
	var material := _flash_material if enabled else _persistent_tint_material
	for mesh in _flash_meshes:
		mesh.material_overlay = material


## A standing, low-alpha tint (e.g. an enemy's alert-state color) that
## persists until changed — distinct from the momentary damage flash,
## which temporarily overrides it and restores it when the flash ends.
func set_persistent_tint(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_persistent_tint_material = mat
	if _flash_time_left <= 0.0:
		_set_flashing(false)


func clear_persistent_tint() -> void:
	_persistent_tint_material = null
	if _flash_time_left <= 0.0:
		_set_flashing(false)
