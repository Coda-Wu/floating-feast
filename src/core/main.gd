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
	_verify_step7() # TEMP — delete after confirming


# ==== TEMP — delete after Step 7 verify ====
func _verify_step7() -> void:
	var island := Database.get_world_island(&"cat_island")
	print("baseline terminals: ", _terminal_hist(island, 300))
	GameState.known_recipes.append(&"classic_rustic_salad") # learn the recipe
	GameState.captured_spirits.append("spirit_gourmand") # tame the unique spirit
	GameState.record_tier_s_collected(&"cat_island", &"cat_geode") # collect the capped geode
	print("island_depletion: ", GameState.island_depletion)
	print("depleted terminals: ", _terminal_hist(island, 300))
	var saved := GameState.serialize() # round-trip
	GameState.island_depletion = {}
	GameState.deserialize(saved)
	print("after round-trip: ", GameState.island_depletion)

func _terminal_hist(island, n: int) -> Dictionary:
	var h := {}
	for s in n:
		var p: Dictionary = RunGraphGenerator.generate(island, s).nodes[RunGraphGenerator.generate(island, s).terminal_index].params
		var key := "?"
		if p.has("recipe_id"): key = "recipe:" + String(p["recipe_id"])
		elif p.has("spirit_id"): key = "spirit:" + String(p["spirit_id"])
		elif p.has("tier_s_id"): key = "tierS:" + String(p["tier_s_id"])
		elif p.has("item_id"): key = "consumable:%sx%d" % [p["item_id"], int(p.get("count", 1))]
		h[key] = int(h.get(key, 0)) + 1
	return h