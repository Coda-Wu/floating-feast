class_name NodeDefinition extends RefCounted
## A single generated exploration node: a type + a small params payload. Produced by
## NodeChainGenerator, consumed by IslandScreen (Step 5). Runtime, not authored. (§9)

var type: StringName
var params: Dictionary
@export var fuel_cost: int = 1 # fuel spent to step onto this node; renders as 1-3 fuel icons. The "2× cost" heavy node is simply a higher value here. (§4.1)

func _init(p_type: StringName = &"", p_params: Dictionary = {}) -> void:
	type = p_type
	params = p_params