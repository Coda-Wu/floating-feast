extends Control
## The ship hub: entry points to the Kitchen (now), the Garden (Day 12), and Sleep. Minimal hub
## for M1 — a walkable deck reusing TopDownActor is deferred (§F assumption). (§5, §B)

@onready var _kitchen_button: Button = $Center/VBox/KitchenButton
@onready var _end_day_button: Button = $Center/VBox/EndDayButton

func _ready() -> void:
	_kitchen_button.pressed.connect(GameManager.request_enter_kitchen)
	_end_day_button.pressed.connect(GameManager.request_end_day)