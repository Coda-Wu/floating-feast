class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step11a() # TEMP — delete after confirming


# ==== TEMP — delete after Step 11a verify ====
func _verify_step11a() -> void:
	for n in [0, 1, 2, 3, 4]:
		print("[verify 11a] enhancers=%d -> tier %d" % [n, Cooking.compute_tier(n)["tier"]])
	print("[verify 11a] starter: tomato known? %s | potato known? %s" % [GameState.is_recipe_known(&"roasted_tomato"), GameState.is_recipe_known(&"roasted_potato")])
	print("[verify 11a] mark potato -> %s (again) %s" % [GameState.mark_recipe_known(&"roasted_potato"), GameState.mark_recipe_known(&"roasted_potato")])
	GameState.add_dish(&"med_roasted_vegetables", 5, 2)
	GameState.add_dish(&"med_roasted_vegetables", 3, 1)
	GameState.add_dish(&"roasted_tomato", 2, 4)
	print("[verify 11a] med veg total: %d | >=4: %d" % [GameState.count_dishes(&"med_roasted_vegetables"), GameState.count_dishes(&"med_roasted_vegetables", 4)])
	print("[verify 11a] remove 2 med veg(>=1) -> %s | left: %d" % [GameState.remove_dishes(&"med_roasted_vegetables", 1, 2), GameState.count_dishes(&"med_roasted_vegetables")])
	print("[verify 11a] entries: ", GameState.get_dish_entries())
	var snap := GameState.serialize()
	GameState.dish_inventory.clear()
	GameState.known_recipes.clear()
	GameState.deserialize(snap)
	print("[verify 11a] post round-trip: potato known? %s | dishes: %s" % [GameState.is_recipe_known(&"roasted_potato"), GameState.get_dish_entries()])