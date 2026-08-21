class_name BehaviourSequence
extends RefCounted

## A named group of AttackSequenceStep with a relative weight, for enemies
## that want to randomly choose between multiple attack patterns rather
## than always running the same one.

var steps: Array[AttackSequenceStep]
var weight: float

func _init(p_steps: Array[AttackSequenceStep], p_weight: float = 1.0) -> void:
	steps = p_steps
	weight = p_weight


## Picks one sequence at random, proportional to weight — weights don't
## need to sum to anything in particular, they're only relative to each
## other. Returns null if behaviours is empty or all weights are <= 0.
static func pick_weighted(behaviours: Array[BehaviourSequence]) -> BehaviourSequence:
	var total_weight := 0.0
	for behaviour in behaviours:
		total_weight += behaviour.weight

	if total_weight <= 0.0:
		return null

	var roll := randf() * total_weight
	for behaviour in behaviours:
		roll -= behaviour.weight
		if roll < 0.0:
			return behaviour

	return behaviours[-1]
