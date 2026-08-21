class_name DamageInstance
extends Resource

@export var amount := 0.0
@export var type: DamageType.Type = DamageType.Type.NONE
@export var crit := false
var source: Node

func _init(p_amount = 0.0, p_type: DamageType.Type = DamageType.Type.NONE, p_crit := false) -> void:
	amount = p_amount
	type = p_type
	crit = p_crit
