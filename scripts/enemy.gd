class_name Enemy
extends Entity

enum State { UNAWARE, SUSPICIOUS, HOSTILE, SEARCH, DEAD }

var current_state: State = State.UNAWARE
var player: Node3D
var attack_steps: Array[AttackSequenceStep]
var is_attacking: bool = false


func _ready() -> void:
	super._ready()
	call_deferred("_find_player")


func run_sequence(steps: Array[AttackSequenceStep]) -> void:
	if is_attacking:
		return
	is_attacking = true

	for step in steps:
		if not is_alive():
			break
		await step.execute(self)

	is_attacking = false


func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
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
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func change_state(new_state: State) -> void:
	current_state = new_state


func die() -> void:
	change_state(State.DEAD)
	super.die()


func distance_to_target() -> float:
	if not player:
		return INF
	return global_position.distance_to(player.global_position)


func get_direction_to_target() -> Vector3:
	if not player:
		return facing_direction()
	var to_player := player.global_position - global_position
	to_player.y = 0
	return to_player.normalized()


func facing_direction() -> Vector3:
	return -global_transform.basis.z


func face_target() -> void:
	if not player:
		return
	var target_pos := player.global_position
	target_pos.y = global_position.y
	look_at(target_pos, Vector3.UP)


func move_toward_target(speed: float) -> void:
	var dir := get_direction_to_target()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed


func launch(velocity_vec: Vector3) -> void:
	velocity = velocity_vec


func is_grounded() -> bool:
	return is_on_floor()


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
