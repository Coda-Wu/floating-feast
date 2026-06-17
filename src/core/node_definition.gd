class_name NodeDefinition extends RefCounted
## A single generated exploration node: a type + a small params payload. Produced by
## NodeChainGenerator, consumed by IslandScreen (Step 5). Runtime, not authored. (§9)

var type: StringName
var params: Dictionary

func _init(p_type: StringName = &"", p_params: Dictionary = {}) -> void:
	type = p_type
	params = p_params