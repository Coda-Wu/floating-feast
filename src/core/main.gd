class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	
	# TEMP UX-1 — seed ingredients to exercise the hotbar (12 types → 2 pages) + cooking from it
	for pair in [[&"tomato", 3], [&"potato", 2], [&"eggplant", 2], [&"onion", 1], [&"rosemary", 1], [&"salt", 2], [&"lemon", 1], [&"chickpeas", 2]]:
		GameState.add_item(pair[0], pair[1])
	GameState.add_dish(&"roasted_tomato", 2, 1)
	GameState.add_item(&"tomato", 5)
	GameState.add_dish(&"roasted_eggplant", 3, 1) # both are family "roasted", tier ≥2