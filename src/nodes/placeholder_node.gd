extends ExplorationNode
## Gray-box stand-in: hosts every node type in 5a, then serves as the fallback for any
## not-yet-implemented type. Shows the node's type and a Continue button; yields nothing.

@onready var _type_label: Label = $Center/VBox/TypeLabel
@onready var _continue_button: Button = $Center/VBox/ContinueButton

func _run() -> void:
	_type_label.text = "[ %s node ]" % String(node_def.type)
	_continue_button.pressed.connect(func() -> void: complete({}))
