extends Control
## Week-1 Ship stub: an End Day affordance + labelled slots for the Week-2
## cooking and garden systems. Becomes the ship hub in Week 2. (§5)

@onready var _end_day_button: Button = $Center/VBox/EndDayButton

func _ready() -> void:
	_end_day_button.pressed.connect(GameManager.request_end_day)
