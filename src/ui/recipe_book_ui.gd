extends Control
## Recipe Book — knowledge codex of known recipes. Day-9 stub; Day 11 lists GameState.known_recipes
## with each recipe's ingredient + station path. Dumb view; emits close_requested. (§C.5)

signal close_requested

@onready var _close_button: Button = $Center/Panel/Margin/VBox/CloseButton

func setup() -> void:
	_close_button.pressed.connect(func() -> void: close_requested.emit())
