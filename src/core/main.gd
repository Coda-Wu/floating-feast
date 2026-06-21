class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	# TEMP P-2b — dishes across tiers + methods for the Dishes tab
	GameState.known_recipes.assign([&"roasted_tomato", &"med_roasted_vegetables", &"classic_rustic_salad", &"hummus"])
	GameState.add_dish(&"roasted_tomato", 2, 1)
	GameState.add_dish(&"roasted_tomato", 3, 2)
	GameState.add_dish(&"med_roasted_vegetables", 5, 1)
	GameState.add_dish(&"med_roasted_vegetables", 3, 1)
	GameState.add_dish(&"classic_rustic_salad", 4, 1)
	GameState.add_dish(&"hummus", 2, 1)
	GameState.known_recipes.assign([&"roasted_tomato", &"med_roasted_vegetables", &"classic_rustic_salad", &"hummus"])