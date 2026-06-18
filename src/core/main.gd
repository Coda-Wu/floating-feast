class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step7() # TEMP — delete after confirming


# ==== TEMP — delete after Step 7 verify ====
func _verify_step7() -> void:
	GameState.add_item(&"tomato", 4) # so the debug Spirit node is tameable (Tomato prefers veg)
	var chain: Array[NodeDefinition] = []
	chain.append(NodeDefinition.new(&"gathering", {"biome": &"orchard"}))
	chain.append(NodeDefinition.new(&"spirit_encounter", {"spirit_id": &"spirit_tomato"}))
	chain.append(NodeDefinition.new(&"shop", {"stock_id": &"stock_island_shop"}))
	var dbg := Island.new(&"island_debug_7", Vector2(330, 90))
	dbg.node_chain = chain
	GameManager.day_islands.append(dbg)
	print("[verify 7] debug island at (330,90): Forage → Spirit → Shop.")
	SignalBus.inventory_changed.connect(func(id, n): print("[verify 7] inventory: %s = %d" % [id, n]))
	SignalBus.day_ended.connect(func(): print("[verify 7] DAY ENDED — full inventory: ", GameState.inventory))
