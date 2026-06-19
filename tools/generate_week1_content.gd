@tool
extends EditorScript
## Dev-only Week-1 content generator. Run via File > Run in the Script Editor.
## Writes every .tres into res://resources/. Safe to re-run (overwrites) or delete
## once the data exists. NOT autoloaded, NOT shipped. (Step 2b)

const BASE := "res://resources/"

func _run() -> void:
	_ensure_dirs(["ingredients", "spirits", "islands", "shops", "weather", "tutorials", "recipes", "station_recipes"])
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
	print("[Week-1 content] wrote %d resources into %s" % [n, BASE])
	EditorInterface.get_resource_filesystem().scan() # refresh the FileSystem dock

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
		{"id": &"onion", "name": "Onion", "tags": [&"vegetable", &"spice"], "full": 6, "qual": 2, "src": &"spirit_drop"},
		{"id": &"chickpeas", "name": "Chickpeas", "tags": [&"vegetable"], "full": 9, "qual": 2, "src": &"spirit_drop"},
		{"id": &"rosemary", "name": "Rosemary", "tags": [&"spice"], "full": 2, "qual": 3, "src": &"spirit_drop"},
		{"id": &"sugar", "name": "Sugar", "tags": [&"spice"], "full": 4, "qual": 1, "src": &"spirit_drop"},
		{"id": &"salt", "name": "Salt", "tags": [&"spice"], "full": 1, "qual": 1, "src": &"shop"},
		{"id": &"lemon", "name": "Lemon", "tags": [&"fruit", &"spice"], "full": 5, "qual": 3, "src": &"orchard"},
		{"id": &"flour", "name": "Flour", "tags": [&"staple", &"grain"], "full": 5, "qual": 1, "src": &"shop"},
		{"id": &"rice", "name": "Rice", "tags": [&"grain", &"staple"], "full": 6, "qual": 1, "src": &"shop"},
		{"id": &"olive_oil", "name": "Olive Oil", "tags": [&"staple"], "full": 3, "qual": 2, "src": &"shop"},
		{"id": &"egg", "name": "Egg", "tags": [], "full": 6, "qual": 2, "src": &"spirit_drop"},
		{"id": &"fish", "name": "Fish", "tags": [], "full": 7, "qual": 2, "src": &"butchery"},
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
	chicken.drop_table = {&"egg": 1}
	_save(chicken, "spirits", chicken.id)
	return 3

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
		{"type": &"npc", "params": {"text": "The whole bay's gone quiet... everyone's hiding from something out past the reef."}},
		{"type": &"event", "params": {"flag": &"whale_quest_started"}},
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
		{"id": &"roasted_tomato", "name": "Roasted Tomato", "fam": [&"roasted", &"vegetable"], "st": &"oven", "codex": "Tomato → [Oven]", "sr": &"sr_roasted_tomato"},
		{"id": &"roasted_potato", "name": "Roasted Potato", "fam": [&"roasted", &"vegetable"], "st": &"oven", "codex": "Potato → [Oven]", "sr": &"sr_roasted_potato"},
		{"id": &"roasted_eggplant", "name": "Roasted Eggplant", "fam": [&"roasted", &"vegetable"], "st": &"oven", "codex": "Eggplant → [Oven]", "sr": &"sr_roasted_eggplant"},
		{"id": &"med_roasted_vegetables", "name": "Mediterranean Roasted Vegetables", "fam": [&"roasted", &"vegetable"], "st": &"oven", "codex": "Veg → [Prep] ·2 → [Mixing Bowl] +Olive Oil → [Oven]", "sr": &"sr_med_roasted_vegetables"},
		{"id": &"classic_rustic_salad", "name": "Classic Rustic Salad", "fam": [&"salad", &"vegetable"], "st": &"mix_bowl", "codex": "Veg → [Prep] → [Mixing Bowl] +Olive Oil", "sr": &"sr_classic_rustic_salad"},
		{"id": &"hummus", "name": "Hummus", "fam": [&"dip"], "st": &"mix_bowl", "codex": "Chickpeas + Lemon + Olive Oil → [Mixing Bowl]", "sr": &"sr_hummus"},
	]
	for r in rows:
		var rec := RecipeData.new()
		rec.id = r["id"]
		rec.display_name = r["name"]
		rec.family_tags.assign(r["fam"])
		rec.station_id = r["st"]
		rec.codex_path = r["codex"]
		rec.terminal_recipe_id = r["sr"]
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