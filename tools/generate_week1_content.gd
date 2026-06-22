@tool
extends EditorScript
## Dev-only Week-1 content generator. Run via File > Run in the Script Editor.
## Writes every .tres into res://resources/. Safe to re-run (overwrites) or delete
## once the data exists. NOT autoloaded, NOT shipped. (Step 2b)

const BASE := "res://resources/"

func _run() -> void:
	_ensure_dirs(["world_islands", "ingredients", "spirits", "islands", "shops", "weather", "tutorials", "recipes", "station_recipes", "commissions", "fair"])
	var n := 0
	n += _gen_ingredients()
	n += _gen_spirits()
	n += _gen_islands()
	n += _gen_shops()
	n += _gen_weather()
	n += _gen_tutorials()
	n += _gen_cooking_items()
	n += _gen_recipes()
	n += _gen_station_recipes()
	n += _gen_commissions()
	n += _gen_fair()
	n += _gen_world_islands()
	print("[Week-1 content] wrote %d resources into %s" % [n, BASE])
	EditorInterface.get_resource_filesystem().scan() # refresh the FileSystem dock


func _gen_world_islands() -> int:
	var rows := [
		{"id": &"cat_island", "name": "Cat Island", "cuisine": "Mediterranean", "phase": 0, "pos": Vector2(196, 196)},
		{"id": &"spice_isle", "name": "Spice Isle", "cuisine": "", "phase": 99, "pos": Vector2(452, 150)}, # fogged in M1 ("to be continued")
	]
	for r in rows:
		var wi := WorldIslandData.new()
		wi.id = r["id"]
		wi.display_name = r["name"]
		wi.cuisine = r["cuisine"]
		wi.unlock_phase = r["phase"]
		wi.map_position = r["pos"]
		_save(wi, "world_islands", wi.id)
	return rows.size()


func _ensure_dirs(subs: Array) -> void:
	for s in subs:
		DirAccess.make_dir_recursive_absolute(BASE + s)

func _save(res: Resource, sub: String, id: StringName) -> void:
	var path := "%s%s/%s.tres" % [BASE, sub, id]
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("Failed to save %s (error %d)" % [path, err])

# ---------- Ingredients ----------
func _gen_ingredients() -> int:
	var rows := [
		{"id": &"tomato", "name": "Tomato", "tags": [&"vegetable"], "full": 8, "qual": 2, "src": &"spirit_drop"},
		{"id": &"potato", "name": "Potato", "tags": [&"vegetable"], "full": 10, "qual": 2, "src": &"spirit_drop"},
		{"id": &"eggplant", "name": "Eggplant", "tags": [&"vegetable"], "full": 9, "qual": 2, "src": &"spirit_drop"},
		{"id": &"zucchini", "name": "Zucchini", "tags": [&"vegetable"], "full": 8, "qual": 2, "src": &"spirit_drop"},
		{"id": &"bell_pepper", "name": "Bell Pepper", "tags": [&"vegetable"], "full": 8, "qual": 2, "src": &"spirit_drop"},
		{"id": &"chickpeas", "name": "Chickpeas", "tags": [&"vegetable"], "full": 9, "qual": 2, "src": &"spirit_drop"},
		{"id": &"onion", "name": "Onion", "tags": [&"vegetable", &"spice"], "full": 6, "qual": 2, "src": &"spirit_drop", "flavor": [&"savory"]},
		{"id": &"rosemary", "name": "Rosemary", "tags": [&"spice"], "full": 2, "qual": 3, "src": &"spirit_drop", "flavor": [&"herbal"]},
		{"id": &"sugar", "name": "Sugar", "tags": [&"spice"], "full": 4, "qual": 1, "src": &"spirit_drop", "flavor": [&"sweet"]},
		{"id": &"salt", "name": "Salt", "tags": [&"spice"], "full": 1, "qual": 1, "src": &"shop", "flavor": [&"savory"]},
		{"id": &"lemon", "name": "Lemon", "tags": [&"fruit", &"spice"], "full": 5, "qual": 3, "src": &"orchard", "flavor": [&"citrus"]},
		{"id": &"flour", "name": "Flour", "tags": [&"staple", &"grain"], "full": 5, "qual": 1, "src": &"shop"},
		{"id": &"rice", "name": "Rice", "tags": [&"grain", &"staple"], "full": 6, "qual": 1, "src": &"shop"},
		{"id": &"olive_oil", "name": "Olive Oil", "tags": [&"staple"], "full": 3, "qual": 2, "src": &"shop"},
		{"id": &"egg", "name": "Egg", "tags": [&"protein"], "full": 6, "qual": 2, "src": &"spirit_drop"},
		{"id": &"fish", "name": "Fish", "tags": [&"protein"], "full": 7, "qual": 2, "src": &"butchery"},
		{"id": &"fig", "name": "Fig", "tags": [&"fruit"], "full": 6, "qual": 2, "src": &"orchard"},
		{"id": &"grape", "name": "Grape", "tags": [&"fruit"], "full": 5, "qual": 2, "src": &"orchard"},
	]
	for r in rows:
		var ing := IngredientData.new()
		ing.id = r["id"]
		ing.display_name = r["name"]
		ing.tags.assign(r["tags"])
		ing.base_fullness = r["full"]
		ing.base_quality = r["qual"]
		ing.source_category = r["src"]
		ing.flavor_tags.assign(r.get("flavor", []))
		_save(ing, "ingredients", ing.id)
	return rows.size()

# ---------- Spirits ----------
func _gen_spirits() -> int:
	var sprout := SpiritData.new()
	sprout.id = &"spirit_sprout"
	sprout.display_name = "Sprout Spirit"
	sprout.temperament = &"calm"
	sprout.preferred_food = &"grain" # CHANGED: starting staples (flour/rice) work — Appendix A
	sprout.required_tier = 0
	sprout.well_fed_max = 40 # CHANGED: forgiving tutorial
	sprout.turns_before_flee = 6
	sprout.tameable = false
	sprout.drop_table = {&"flour": 2, &"sugar": 1}
	_save(sprout, "spirits", sprout.id)

	var tomato := SpiritData.new()
	tomato.id = &"spirit_tomato"
	tomato.display_name = "Tomato Spirit"
	tomato.temperament = &"shy"
	tomato.preferred_food = &"vegetable"
	tomato.required_tier = 0
	tomato.well_fed_max = 60 # CHANGED (was 100)
	tomato.turns_before_flee = 5
	tomato.tameable = true
	tomato.produces = &"tomato"
	tomato.yield_per_night = 2
	tomato.drop_table = {&"tomato": 2}
	_save(tomato, "spirits", tomato.id)

	var chicken := SpiritData.new()
	chicken.id = &"spirit_chicken"
	chicken.display_name = "Chicken Spirit"
	chicken.temperament = &"greedy"
	chicken.preferred_food = &"grain"
	chicken.required_tier = 0
	chicken.well_fed_max = 60 # CHANGED (was 120)
	chicken.turns_before_flee = 5
	chicken.tameable = true
	chicken.produces = &"egg"
	chicken.yield_per_night = 1
	chicken.drop_table = {&"egg": 1}
	_save(chicken, "spirits", chicken.id)

	var gourmand := SpiritData.new()
	gourmand.id = &"spirit_gourmand"
	gourmand.display_name = "Gourmand Spirit"
	gourmand.temperament = &"refined"
	gourmand.preferred_food = &"roasted" # a DISH FAMILY (not a raw tag) — gates dish-feeding
	gourmand.required_tier = 3 # only a Roasted dish at Tier 3+ will do
	gourmand.well_fed_max = 80
	gourmand.turns_before_flee = 5
	gourmand.tameable = true
	gourmand.produces = &"rosemary" # garden: yields a premium enhancer (loop feeds itself)
	gourmand.yield_per_night = 1
	gourmand.drop_table = {&"rosemary": 1}
	_save(gourmand, "spirits", gourmand.id)

	return 4

# ---------- Island templates ----------
func _gen_islands() -> int:
	var cove := IslandTemplate.new()
	cove.id = &"island_cove"
	cove.biome = &"mediterranean"
	cove.min_nodes = 2
	cove.max_nodes = 3
	cove.spawn_rules.assign([
		{"type": &"gathering", "weight": 3.0, "params": {"biome": &"orchard"}},
		{"type": &"spirit_encounter", "weight": 2.0, "params": {"spirit_pool": [&"spirit_sprout", &"spirit_tomato", &"spirit_chicken"]}},
		{"type": &"shop", "weight": 1.0, "params": {"stock_id": &"stock_island_shop"}},
		{"type": &"spirit_encounter", "weight": 3.0, "params": {"spirit_pool": [&"spirit_tomato", &"spirit_chicken", &"spirit_sprout", &"spirit_gourmand"]}},
	])
	_save(cove, "islands", cove.id)

	var grove := IslandTemplate.new()
	grove.id = &"island_grove"
	grove.biome = &"mediterranean"
	grove.min_nodes = 2
	grove.max_nodes = 4
	grove.spawn_rules.assign([
		{"type": &"spirit_encounter", "weight": 3.0, "params": {"spirit_pool": [&"spirit_tomato", &"spirit_chicken", &"spirit_sprout"]}},
		{"type": &"gathering", "weight": 2.0, "params": {"biome": &"orchard"}},
		{"type": &"npc", "weight": 1.0, "params": {}},
	])
	_save(grove, "islands", grove.id)

	var harbor := IslandTemplate.new()
	harbor.id = &"island_harbor"
	harbor.biome = &"mediterranean"
	harbor.min_nodes = 2
	harbor.max_nodes = 3
	harbor.spawn_rules.assign([
		{"type": &"shop", "weight": 2.0, "params": {"stock_id": &"stock_island_shop"}},
		{"type": &"butchery", "weight": 2.0, "params": {"stock_id": &"stock_butchery"}},
		{"type": &"spirit_encounter", "weight": 1.0, "params": {"spirit_pool": [&"spirit_tomato", &"spirit_chicken"]}},
		{"type": &"gathering", "weight": 1.0, "params": {"biome": &"orchard"}},
	])
	_save(harbor, "islands", harbor.id)

	var mission := IslandTemplate.new()
	mission.id = &"island_mission_whale"
	mission.biome = &"mediterranean"
	mission.is_mission = true
	mission.fixed_nodes.assign([
		{"type": &"npc", "params": {"giver_id": &"npc_harbor_cook", "text": "The whole bay's gone quiet... everyone's hiding from something out past the reef. Oh — and if you can cook, I've got an order for you."}},
		{"type": &"event", "params": {"flag": &"whale_quest_started", "activate_commission": &"commission_1"}},
	])
	_save(mission, "islands", mission.id)
	return 4

# ---------- Shops ----------
func _gen_shops() -> int:
	var shop := ShopStock.new()
	shop.id = &"stock_island_shop"
	shop.entries.assign([
		{"ingredient_id": &"flour", "price": 12},
		{"ingredient_id": &"rice", "price": 10},
		{"ingredient_id": &"olive_oil", "price": 18},
		{"ingredient_id": &"salt", "price": 5},
	])
	_save(shop, "shops", shop.id)

	var butch := ShopStock.new()
	butch.id = &"stock_butchery"
	butch.entries.assign([
		{"ingredient_id": &"fish", "price": 25},
	])
	_save(butch, "shops", butch.id)
	return 2

# ---------- Weather (cosmetic for M1) ----------
func _gen_weather() -> int:
	var defs := [
		{"id": &"weather_sunny", "name": "Sunny"},
		{"id": &"weather_rainy", "name": "Rainy"},
		{"id": &"weather_foggy", "name": "Foggy"},
	]
	for d in defs:
		var w := WeatherData.new()
		w.id = d["id"]
		w.display_name = d["name"]
		_save(w, "weather", w.id) # icon + map_shader stay null in gray-box
	return defs.size()

# ---------- Tutorials (one per Week-1 mechanic) ----------
func _gen_tutorials() -> int:
	var defs := [
		{"id": &"ocean_map", "text": "Hover an island to preview its nodes. Click to sail there. Each node you explore spends 1 Time from today's budget."},
		{"id": &"island_exit", "text": "Heading back early? Any nodes you haven't visited on this island are lost — but your remaining Time can still be spent elsewhere."},
		{"id": &"spirit_encounter", "text": "Feed the spirit to fill its Well-Fed meter before its turns run out. Fill it to befriend it — or it'll slip away, leaving a little gift behind."},
		{"id": &"orchard", "text": "Catch the falling fruit! Dodge durians, bombs, and beehives — getting hit costs you time."},
		{"id": &"cooking_station", "text": "Click ingredients to fill the slots, then Confirm. The Prep table chops, the Mixing Bowl combines, and the Oven bakes — chain them to build a dish. Add spices to a finished dish for extra stars!"},
		{"id": &"recipe_book", "text": "Your recipe codex. Every dish you cook for the first time is recorded here, along with the ingredients and stations it takes to make it."},
		{"id": &"garden", "text": "Assign a tamed spirit to a pot and it'll grow crops while you sleep, collected each morning. Careful: removing a spirit from a pot sends it away for good."},
		{"id": &"dish_feeding", "text": "This spirit has refined taste — it only accepts a cooked dish of the right kind and quality (its craving is shown above). Cook one and feed it here to win it over."},
		{"id": &"commission", "text": "Commissions ask for dishes of a certain kind and quality. There's no deadline — deliver whenever you're ready (a little sooner earns a bonus). Bring the dishes to the NPC who asked."},
		{"id": &"fair", "text": "At the Trade Fair, submit your dishes to the judges — better dishes earn more coins, and you'll climb the Explorer League ranks. No pressure: bring what you've got."},
	]
	for d in defs:
		var t := TutorialData.new()
		t.id = d["id"]
		t.text = d["text"]
		_save(t, "tutorials", t.id)
	return defs.size()

# ---------- Cooking items (intermediates + dubious food; IngredientData) ----------
func _gen_cooking_items() -> int:
	var rows := [
		{"id": &"chopped_vegetable", "name": "Chopped Vegetable", "tags": [&"intermediate"], "full": 0, "qual": 1, "src": &"cooking"},
		{"id": &"oiled_vegetable", "name": "Oiled Vegetable", "tags": [&"intermediate"], "full": 0, "qual": 2, "src": &"cooking"},
		{"id": &"dubious_food", "name": "Dubious Food", "tags": [&"dubious"], "full": 3, "qual": 1, "src": &"cooking"},
	]
	for r in rows:
		var ing := IngredientData.new()
		ing.id = r["id"]
		ing.display_name = r["name"]
		ing.tags.assign(r["tags"])
		ing.base_fullness = r["full"]
		ing.base_quality = r["qual"]
		ing.source_category = r["src"]
		_save(ing, "ingredients", ing.id)
	return rows.size()

# ---------- Dishes (RecipeData — codex/display/family; tiered instances live in dish_inventory) ----------
func _gen_recipes() -> int:
	var rows := [
		{"id": &"roasted_tomato", "name": "Roasted Tomato", "fam": [&"roasted", &"vegetable"], "st": &"oven", "codex": "Tomato → [Oven]", "sr": &"sr_roasted_tomato", "cap": 3, "flav": [&"savory", &"herbal"]},
		{"id": &"roasted_potato", "name": "Roasted Potato", "fam": [&"roasted", &"vegetable"], "st": &"oven", "codex": "Potato → [Oven]", "sr": &"sr_roasted_potato", "cap": 3, "flav": [&"savory", &"herbal"]},
		{"id": &"roasted_eggplant", "name": "Roasted Eggplant", "fam": [&"roasted", &"vegetable"], "st": &"oven", "codex": "Eggplant → [Oven]", "sr": &"sr_roasted_eggplant", "cap": 3, "flav": [&"savory", &"herbal"]},
		{"id": &"med_roasted_vegetables", "name": "Mediterranean Roasted Vegetables", "fam": [&"roasted", &"vegetable"], "st": &"oven", "codex": "Veg → [Prep] ·2 → [Mixing Bowl] +Olive Oil → [Oven]", "sr": &"sr_med_roasted_vegetables", "cap": 5, "flav": [&"savory", &"herbal"]},
		{"id": &"classic_rustic_salad", "name": "Classic Rustic Salad", "fam": [&"salad", &"vegetable"], "st": &"mix_bowl", "codex": "Veg → [Prep] → [Mixing Bowl] +Olive Oil", "sr": &"sr_classic_rustic_salad", "cap": 4, "flav": [&"savory", &"herbal", &"citrus"]},
		{"id": &"hummus", "name": "Hummus", "fam": [&"dip"], "st": &"mix_bowl", "codex": "Chickpeas + Lemon + Olive Oil → [Mixing Bowl]", "sr": &"sr_hummus", "cap": 3, "flav": [&"savory", &"citrus"]},
	]
	for r in rows:
		var rec := RecipeData.new()
		rec.id = r["id"]
		rec.display_name = r["name"]
		rec.family_tags.assign(r["fam"])
		rec.station_id = r["st"]
		rec.codex_path = r["codex"]
		rec.terminal_recipe_id = r["sr"]
		rec.tier_cap = r["cap"]
		rec.accepted_flavors.assign(r["flav"])
		_save(rec, "recipes", rec.id)
	return rows.size()

# ---------- StationRecipes (drive the simulation) ----------
func _gen_station_recipes() -> int:
	var defs := [
		# intermediates (non-terminal)
		_sr(&"sr_chop_vegetable", &"prep", [ {"match": &"vegetable", "count": 1}], &"chopped_vegetable", false),
		_sr(&"sr_oil_vegetables", &"mix_bowl", [ {"match": &"chopped_vegetable", "count": 2}, {"match": &"olive_oil", "count": 1}], &"oiled_vegetable", false),
		# terminals (produce dishes)
		_sr(&"sr_roasted_tomato", &"oven", [ {"match": &"tomato", "count": 1}], &"roasted_tomato", true),
		_sr(&"sr_roasted_potato", &"oven", [ {"match": &"potato", "count": 1}], &"roasted_potato", true),
		_sr(&"sr_roasted_eggplant", &"oven", [ {"match": &"eggplant", "count": 1}], &"roasted_eggplant", true),
		_sr(&"sr_med_roasted_vegetables", &"oven", [ {"match": &"oiled_vegetable", "count": 1}], &"med_roasted_vegetables", true),
		_sr(&"sr_classic_rustic_salad", &"mix_bowl", [ {"match": &"chopped_vegetable", "count": 1}, {"match": &"olive_oil", "count": 1}], &"classic_rustic_salad", true),
		_sr(&"sr_hummus", &"mix_bowl", [ {"match": &"chickpeas", "count": 1}, {"match": &"lemon", "count": 1}, {"match": &"olive_oil", "count": 1}], &"hummus", true),
	]
	for sr in defs:
		_save(sr, "station_recipes", sr.id)
	return defs.size()

func _sr(id: StringName, station: StringName, inputs: Array, output: StringName, terminal: bool) -> StationRecipe:
	var sr := StationRecipe.new()
	sr.id = id
	sr.station_id = station
	sr.inputs.assign(inputs)
	sr.output_item_id = output
	sr.is_terminal = terminal
	return sr


# ---------- Commissions ----------

func _gen_commissions() -> int:
	var c := CommissionData.new()
	c.id = &"commission_1"
	c.title = "Harbor Cook's Request"
	c.detail = "Bring me 2 roasted dishes, Tier 2 or better — the festival crowd is hungry!"
	c.giver_npc_id = &"npc_harbor_cook"
	c.req_family = &"roasted"
	c.req_min_tier = 2
	c.req_quantity = 2
	c.reward_coins = 60
	c.reward_story_flag = &"commission_1_done"
	c.on_time_day = 5
	c.on_time_bonus = 25
	_save(c, "commissions", c.id)
	return 1


# ---------- Fairs ----------
func _gen_fair() -> int:
	var fc := FairConfig.new()
	fc.id = &"fair_default"
	fc.intro_line = "Welcome to the Trade Fair! Present your finest dishes for the judges."
	fc.coins_per_tier = {1: 5, 2: 15, 3: 30, 4: 50, 5: 80}
	fc.rank_granted = 1
	fc.result_line = "The judges are delighted!"
	fc.empty_line = "No dishes this time? No worries — come back when your kitchen's been busy!"
	_save(fc, "fair", fc.id)
	return 1