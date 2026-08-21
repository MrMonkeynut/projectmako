class_name Enemy
extends Entity

enum State { UNAWARE, SUSPICIOUS, HOSTILE, SEARCH, DEAD }

var current_state: State = State.UNAWARE
var player: Node3D
var facing_direction: Vector3 = Vector3.FORWARD
var movement_locked: bool = false
var attack_steps: Array[AttackSequenceStep] = []
@export var speed: float = 3.0
@export var stopping_distance: float = 0.0


func _ready() -> void:
	super._ready()
	call_deferred("_find_player")


func run_sequence(steps: Array[AttackSequenceStep]) -> void:
	for step in steps:
		await step.execute(self)

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		State.UNAWARE:
			_process_unaware(delta)
		State.SUSPICIOUS:
			_process_suspicious(delta)
		State.HOSTILE:
			_process_hostile(delta)
		State.SEARCH:
			_process_search(delta)
		State.DEAD:
			_process_dead(delta)

	if movement_locked:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()


func get_direction_to_target() -> Vector3:
	if not player:
		return facing_direction
	var direction := player.global_position - global_position
	direction.y = 0
	return direction.normalized() if direction.length() > 0.001 else facing_direction


func face_target() -> void:
	if not player:
		return
	var target := player.global_position
	target.y = global_position.y
	if target.distance_to(global_position) > 0.001:
		look_at(target, Vector3.UP)
		facing_direction = -global_transform.basis.z


func set_movement_locked(locked: bool) -> void:
	movement_locked = locked


func chase_player() -> void:
	if not player:
		velocity.x = 0
		velocity.z = 0
		return
	face_target()
	if global_position.distance_to(player.global_position) <= stopping_distance:
		velocity.x = 0
		velocity.z = 0
		return
	var direction := get_direction_to_target()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func launch(launch_velocity: Vector3) -> void:
	velocity = launch_velocity


func wait_until_grounded() -> void:
	await get_tree().physics_frame
	while not is_on_floor():
		await get_tree().physics_frame


func change_state(new_state: State) -> void:
	current_state = new_state


func die() -> void:
	change_state(State.DEAD)
	super.die()


func _process_unaware(_delta: float) -> void:
	pass


func _process_suspicious(_delta: float) -> void:
	pass


func _process_hostile(_delta: float) -> void:
	pass


func _process_search(_delta: float) -> void:
	pass


func _process_dead(_delta: float) -> void:
	pass
