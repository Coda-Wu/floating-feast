extends ExplorationNode
## One-line NPC node (stub). Shows params.text (mission islands) or a random default
## (ambient random-island NPCs) + Continue. Completes empty. M2: Dialogic + the [Signal]
## pattern replace this. (§9)

@onready var _name_label: Label = $Center/Panel/Margin/VBox/NameLabel
@onready var _text_label: Label = $Center/Panel/Margin/VBox/TextLabel
@onready var _continue_button: Button = $Center/Panel/Margin/VBox/ContinueButton

const _DEFAULT_LINES := [
	"Fair winds today! Caught anything tasty out there?",
	"Welcome, traveler. The spirits hereabouts are a shy bunch.",
	"A cook, are you? You'll find good pickings on these isles.",
]

func _run() -> void:
	var text := String(node_def.params.get("text", ""))
	if text.is_empty():
		text = _DEFAULT_LINES[randi() % _DEFAULT_LINES.size()]
	_name_label.text = "Islander"
	_text_label.text = text
	_continue_button.pressed.connect(func() -> void: complete({}))
