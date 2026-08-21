extends Entity

const SPEED = 7.0
const JUMP_VELOCITY = 4.5
@export var weapon_name_label: Label
@export var available_weapons: Array[Weapon] = []
var _weapon_index: int = 0

func _ready() -> void:
	max_health = 10
	super._ready()
	weapon_equipped.connect(_on_weapon_equipped)
	if available_weapons.size() > 0:
		_weapon_index = available_weapons.find(equipped_weapon)
		if _weapon_index == -1:
			_weapon_index = 0
			equipped_weapon = available_weapons[0]
	_on_weapon_equipped(equipped_weapon)


func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	player_jump()
	player_movement()
	player_direction_to_mouse()
	attack()
	camera_follow()


func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func player_jump():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func player_movement():
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_up", "move_down")
	input_dir = input_dir.normalized()

	var speed := SPEED
	match _attack_phase:
		AttackPhase.WINDUP, AttackPhase.ACTIVE:
			if equipped_weapon:
				speed *= equipped_weapon.windup_move_speed_mod

	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed
	move_and_slide()


func player_direction_to_mouse():
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	var plane = Plane(Vector3.UP, global_position.y)
	var target = plane.intersects_ray(ray_origin, ray_dir)

	if target:
		if !hitbox.active:
			look_at(target, Vector3.UP)


func camera_follow():
	$CameraController.position = lerp($CameraController.position, position, 0.10)


func _on_weapon_equipped(weapon: Weapon) -> void:
	if weapon_name_label:
		weapon_name_label.text = weapon.weapon_name if weapon else ""


func attack():
	if Input.is_action_just_pressed("attack") and equipped_weapon and _attack_phase == AttackPhase.NONE:
		_perform_attack()
		
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_weapon(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_weapon(1)

func _cycle_weapon(direction: int) -> void:
	if available_weapons.is_empty() or _is_attacking():
		return
	_weapon_index = wrapi(_weapon_index + direction, 0, available_weapons.size())
	equipped_weapon = available_weapons[_weapon_index]
