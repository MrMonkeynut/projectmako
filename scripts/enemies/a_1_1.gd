class_name a_1_1
extends Enemy

var speed_unaware = 2.5
var speed_hostile = 4.5

func _init() -> void:
	speed = 2.0
	stopping_distance = 3.5
	detection_range = 5.0
	attack_range = 5.0
	_declare_behaviour_sequences()


func _declare_behaviour_sequences() -> void:
	var jump_attack = BehaviourSequence.new([
		StopMovingStep.new(1),
		JumpAttackStep.new(30.0, 7.0, true, DamageInstance.new(1.0, DamageType.Type.BLUNT)),
		StopMovingStep.new(0.5),
		FollowPlayerStep.new(1),
	], 1.0)
	hostile_behaviours = [jump_attack]
	
	var wander = BehaviourSequence.new([
		WanderAimlesslyStep.new(randi_range(1, 3)),
		StopMovingStep.new(randi_range(1, 3))
	], 1.0)
	unaware_behaviours = [wander]


func _on_enter_unaware() -> void:
	super._on_enter_unaware()
	speed = speed_unaware


func _process_unaware(_delta: float) -> void:
	try_detect_player(detection_range)
	await run_behaviour(unaware_behaviours)


func _on_enter_hostile() -> void:
	super._on_enter_hostile()
	speed = speed_hostile


func _process_hostile(_delta: float) -> void:
	if is_attacking:
		return

	if is_player_in_range(attack_range):
		stop_moving()
		face_target()
		await run_behaviour(hostile_behaviours)
		return

	chase_player()
