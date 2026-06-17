class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step6b() # TEMP — delete after confirming


# ==== TEMP — delete after Step 6b verify ====
func _verify_step6b() -> void:
	GameState.add_item(&"tomato", 6) # veg → preferred by the Tomato Spirit
	GameState.add_item(&"rice", 6) # grain → preferred by Sprout & Chicken
	GameState.add_item(&"flour", 4)
	var chain: Array[NodeDefinition] = []
	chain.append(NodeDefinition.new(&"spirit_encounter", {"spirit_id": &"spirit_sprout"}))
	chain.append(NodeDefinition.new(&"spirit_encounter", {"spirit_id": &"spirit_tomato"}))
	chain.append(NodeDefinition.new(&"spirit_encounter", {"spirit_id": &"spirit_chicken"}))
	var dbg := Island.new(&"island_debug_6b", Vector2(330, 90))
	dbg.node_chain = chain
	GameManager.day_islands.append(dbg)
	print("[verify 6b] debug island at (330, 90): Sprout → Tomato → Chicken (hover shows 3× Spirit).")
	SignalBus.spirit_tamed.connect(func(s): print("[verify 6b] TAMED %s | captured: %s" % [s.id, GameState.captured_spirits]))
	SignalBus.spirit_fled.connect(func(s, d): print("[verify 6b] FLED/GIFT %s | drops: %s" % [s.id, d]))
