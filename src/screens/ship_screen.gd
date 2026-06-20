extends Control
## The ship hub: Kitchen, Garden, Trade Fair (once unlocked), and Sleep. (§5, §B)

@onready var _kitchen_button: Button = $Center/VBox/KitchenButton
@onready var _garden_button: Button = $Center/VBox/GardenButton
@onready var _fair_button: Button = $Center/VBox/FairButton
@onready var _end_day_button: Button = $Center/VBox/EndDayButton

func _ready() -> void:
	_kitchen_button.pressed.connect(GameManager.request_enter_kitchen)
	_garden_button.pressed.connect(UIManager.show_garden_panel)
	_fair_button.pressed.connect(GameManager.request_enter_fair)
	_fair_button.visible = QuestManager.is_fair_unlocked() # appears once the quest reaches the Fair phase
	_end_day_button.pressed.connect(GameManager.request_end_day)