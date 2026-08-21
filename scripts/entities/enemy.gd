class_name Enemy
extends Entity

enum State { UNAWARE, SUSPICIOUS, HOSTILE, SEARCH, DEAD }

var current_state: State = State.UNAWARE
var player: Node3D
var player_head: Node3D
var facing_direction: Vector3 = Vector3.FORWARD
var movement_locked: bool = false
var is_attacking: bool = false
@export var speed: float = 3.0
@export var stopping_distance: float = 0.0
@export var detection_range: float = 20.0
@export var attack_range: float = 5.0
@export var unaware_tint: Color = Color(0.4, 1.0, 0.4, 0.18)
@export var hostile_tint: Color = Color(1.0, 0.3, 0.3, 0.18)

@onready var vision_ray: RayCast3D = $VisionRay

var unaware_behaviours: Array[BehaviourSequence] = []
var suspicious_behaviours: Array[BehaviourSequence] = []
var hostile_behaviours: Array[BehaviourSequence] = []
var search_behaviours: Array[BehaviourSequence] = []
var dead_behaviours: Array[BehaviourSequence] = []


func _ready() -> void:
	super._ready()
	call_deferred("_find_player")
	_dispatch_enter_hook(current_state)


func run_sequence(steps: Array[AttackSequenceStep]) -> void:
	if is_attacking:
		return
	is_attacking = true
	for step in steps:
		await step.execute(self)
	is_attacking = false


## Weighted-picks one of behaviours and runs its steps. No-op if empty,
## or if a sequence is already running (run_sequence's own guard).
func run_behaviour(behaviours: Array[BehaviourSequence]) -> void:
	if behaviours.is_empty():
		return
	var behaviour := BehaviourSequence.pick_weighted(behaviours)
	if behaviour:
		await run_sequence(behaviour.steps)

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	player_head = player.get_node_or_null("Head") if player else null


## Aim point for targeting the player (e.g. raycast LOS checks) — the
## player's "Head" marker if it has one, otherwise its own position.
func get_player_head_position() -> Vector3:
	if player_head:
		return player_head.global_position
	return player.global_position if player else Vector3.ZERO


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
		stop_moving()

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


## Generic distance gate any detection scheme can use before doing its own
## (possibly more expensive) check — e.g. proximity-only detectors can use
## this alone, raycast/sound-based ones can gate their check behind it.
func is_player_in_range(detection_range: float) -> bool:
	return player != null and global_position.distance_to(player.global_position) <= detection_range


## Raycast-based line of sight: aims `ray` at `aim_position` and reports
## whether the path is clear, or the ray's collider is `expected_collider`.
## Fields are passed in rather than read from self so any enemy with its
## own RayCast3D can reuse this instead of only the one that declared it.
func has_raycast_line_of_sight(ray: RayCast3D, aim_position: Vector3, expected_collider: Node) -> bool:
	ray.target_position = ray.to_local(aim_position)
	ray.force_raycast_update()

	if not ray.is_colliding():
		return true
	return ray.get_collider() == expected_collider


## Range-gates, then raycasts toward the player's head via vision_ray;
## transitions to HOSTILE if both pass. Caller (a specific Enemy subclass)
## owns detection_range as its own tuning value and calls this from its
## UNAWARE state processor.
func try_detect_player(range: float) -> void:
	if not is_player_in_range(range):
		return
	if has_raycast_line_of_sight(vision_ray, get_player_head_position(), player):
		change_state(State.HOSTILE)


func chase_player() -> void:
	if not player:
		stop_moving()
		return
	face_target()
	if global_position.distance_to(player.global_position) <= stopping_distance:
		stop_moving()
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


## Changes current_state and fires the matching _on_enter_* hook exactly
## once, only on an actual transition (no-op if already in new_state).
func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	current_state = new_state
	_dispatch_enter_hook(new_state)


func _dispatch_enter_hook(state: State) -> void:
	match state:
		State.UNAWARE:
			_on_enter_unaware()
		State.SUSPICIOUS:
			_on_enter_suspicious()
		State.HOSTILE:
			_on_enter_hostile()
		State.SEARCH:
			_on_enter_search()
		State.DEAD:
			_on_enter_dead()


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


func _on_enter_unaware() -> void:
	set_persistent_tint(unaware_tint)


func _on_enter_suspicious() -> void:
	pass


func _on_enter_hostile() -> void:
	set_persistent_tint(hostile_tint)


func _on_enter_search() -> void:
	pass


func _on_enter_dead() -> void:
	pass
