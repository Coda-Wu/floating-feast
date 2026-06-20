class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	# TEMP 14a — unlock the Fair + seed dishes for isolated testing
	GameState.quest_phase = 2
	SignalBus.quest_phase_changed.emit(2)
	GameState.add_dish(&"roasted_tomato", 3, 2)
	GameState.add_dish(&"med_roasted_vegetables", 5, 1)
	GameState.add_dish(&"hummus", 2, 1)
	print("[verify 14a] Fair unlocked (phase 2), dishes seeded. Rank: ", GameState.rank)
