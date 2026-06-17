class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step5b() # TEMP — delete after confirming


# ==== TEMP — delete after Step 5b verify ====
func _verify_step5b() -> void:
	var t := Database.get_island_template(&"island_mission_whale")
	if t == null:
		push_warning("[verify 5b] mission template missing")
		return
	# Mission template's fixed chain (npc -> event), with a shop + butchery prepended so all
	# four new node types are reachable in one island. Tests the is_mission generation path too.
	var chain: Array[NodeDefinition] = NodeChainGenerator.generate(t, 0)
	chain.insert(0, NodeDefinition.new(&"butchery", {"stock_id": &"stock_butchery"}))
	chain.insert(0, NodeDefinition.new(&"shop", {"stock_id": &"stock_island_shop"}))
	var pos := _farthest_spot([Vector2(330, 70), Vector2(560, 80), Vector2(110, 70), Vector2(560, 300)])
	var dbg := Island.new(&"island_debug_5b", pos)
	dbg.node_chain = chain
	GameManager.day_islands.append(dbg)
	print("[verify 5b] debug island at %s — chain: Shop -> Butcher -> NPC -> Event (hover to find it)." % pos.round())

func _farthest_spot(candidates: Array) -> Vector2:
	var best: Vector2 = candidates[0]
	var best_d := -1.0
	for cand in candidates:
		var nearest := INF
		for isl in GameManager.day_islands:
			nearest = minf(nearest, cand.distance_to(isl.position))
		if nearest > best_d:
			best_d = nearest
			best = cand
	return best
