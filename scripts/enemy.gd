class_name Enemy
extends Entity

enum State { UNAWARE, SUSPICIOUS, HOSTILE, SEARCH, DEAD }

var current_state: State = State.UNAWARE
var player: Node3D
@export var attack_steps: Array[AttackSequenceStep]


func _ready() -> void:
	super._ready()
	call_deferred("_find_player")
	
	
func run_sequence(steps: Array[AttackSequenceStep]) -> void:
	for step in steps:
		await step.execute(self)

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
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
