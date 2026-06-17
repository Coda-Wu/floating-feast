class_name Island extends RefCounted
## A runtime island for one day: which template it came from, where it sits on the
## Ocean Map, and its generated node chain. Not persisted; regenerated each day. (§1)

var template_id: StringName
var position: Vector2
var node_chain: Array[NodeDefinition] = []

func _init(p_template_id: StringName = &"", p_position: Vector2 = Vector2.ZERO) -> void:
	template_id = p_template_id
	position = p_position