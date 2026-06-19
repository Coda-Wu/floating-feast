class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step11c() # TEMP — delete after confirming


# ==== TEMP — delete after Step 11c verify ====
func _verify_step11c() -> void:
	print("[verify 11c] hummus known before: ", GameState.is_recipe_known(&"hummus"), " | coins: ", GameState.coins)
	QuestManager.grant_recipe(&"hummus") # not known → New Recipe notice + codex entry
	QuestManager.grant_recipe(&"hummus") # now known → conflict guard → +25 coins notice
	print("[verify 11c] hummus known after: ", GameState.is_recipe_known(&"hummus"), " | known: ", GameState.known_recipes, " | coins: ", GameState.coins)