extends Control
## The ship hub: Kitchen, Garden, and Sleep. Minimal hub for M1 (walkable deck deferred). (§5, §B)

@onready var _kitchen_button: Button = $Center/VBox/KitchenButton
@onready var _garden_button: Button = $Center/VBox/GardenButton
@onready var _end_day_button: Button = $Center/VBox/EndDayButton

func _ready() -> void:
	_kitchen_button.pressed.connect(GameManager.request_enter_kitchen)
	_garden_button.pressed.connect(UIManager.show_garden_panel)
	_end_day_button.pressed.connect(GameManager.request_end_day)