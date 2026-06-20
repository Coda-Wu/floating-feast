class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step13a() # TEMP — delete after confirming


# ==== TEMP — delete after Step 13a verify ====
func _verify_step13a() -> void:
	GameState.add_dish(&"roasted_tomato", 2, 1) # right family, UNDER tier (gourmand wants 3+) → refused
	GameState.add_dish(&"roasted_tomato", 3, 2) # right family + tier → accepted (+60 each)
	GameState.add_dish(&"hummus", 3, 1) # right tier, WRONG family (dip) → refused
	var chain: Array[NodeDefinition] = []
	chain.append(NodeDefinition.new(&"spirit_encounter", {"spirit_id": &"spirit_gourmand"}))
	var dbg := Island.new(&"island_debug_13a", Vector2(330, 90))
	dbg.node_chain = chain
	GameManager.day_islands.append(dbg)
	print("[verify 13a] debug island (330,90): Gourmand. Dishes seeded: RoastedTomato ★★, ★★★ ×2; Hummus ★★★.")
	SignalBus.spirit_tamed.connect(func(s): print("[verify 13a] TAMED %s | captured: %s" % [s.id, GameState.captured_spirits]))
