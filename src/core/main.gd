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
	# TEMP 2a — print unlock states at current quest_phase
	_verify_step3() # TEMP — delete after confirming


# ==== TEMP — delete after Step 3 verify ====
func _verify_step3() -> void:
	var island := Database.get_world_island(&"cat_island")
	for s in [GameState.day_seed, GameState.day_seed + 1]: # two seeds → reshuffle
		print("=== RunGraph: %s (seed %d) ===" % [island.display_name, s])
		var g := RunGraphGenerator.generate(island, s)
		_print_graph(g)
		print("  start=%d terminal=%d layers=%d nodes=%d" % [g.start_index, g.terminal_index, g.layer_count(), g.nodes.size()])
		var bad := 0
		for i in g.nodes.size():
			if i != g.terminal_index and g.next_of(i).is_empty(): bad += 1
			if i != g.start_index and g.incoming_count(i) == 0: bad += 1
		print("  dangling/unreachable: %d (expect 0)" % bad)
	# consultations: learn the salad recipe + deplete cat_geode → neither appears on any terminal
	GameState.known_recipes.append(&"classic_rustic_salad")
	GameState.island_depletion = {&"cat_island": {&"cat_geode": 1}}
	var salad := 0; var geode := 0; var fig := 0
	for s in 300:
		var gg := RunGraphGenerator.generate(island, s)
		var tp: Dictionary = gg.nodes[gg.terminal_index].params
		if tp.get("recipe_id") == &"classic_rustic_salad": salad += 1
		elif tp.get("tier_s_id") == &"cat_geode": geode += 1
		elif tp.get("tier_s_id") == &"fig_spirit": fig += 1
	print("=== after learning salad + depleting cat_geode (300 terminals) ===")
	print("  salad=%d geode=%d fig=%d  (expect 0 / 0 / 300)" % [salad, geode, fig])

func _print_graph(g) -> void:
	for layer in g.layer_count():
		var parts: Array = []
		for i in g.nodes_in_layer(layer):
			var nd = g.nodes[i]
			parts.append("#%d %s(f%d)->%s" % [i, nd.type, nd.fuel_cost, g.next_of(i)])
		print("  L%d: %s" % [layer, parts])