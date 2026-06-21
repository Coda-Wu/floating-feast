class_name CookingInfo extends RefCounted
## Static query helpers deriving cooking relationships from the recipe data, for the Fridge and
## Recipe Book UIs. Pure reads over Database/GameState; no state. (Parts 1-2)

# --- a dish's full station pipeline, ordered producers-first, with demand-propagated counts ---
## Returns [{ station_id, inputs:[{ ref, count, is_tag }], output_id, runs }] — `runs` = how many times
## this step executes to satisfy the dish (so counts are the real totals a player handles).
static func get_recipe_steps(recipe_id: StringName) -> Array:
	var dish := Database.get_recipe(recipe_id)
	if dish == null:
		return []
	var terminal := Database.get_station_recipe(dish.terminal_recipe_id)
	if terminal == null:
		return []
	var ordered: Array = [] # StationRecipes, post-order (producers before consumers)
	_collect_steps(terminal, ordered, {})
	# Run-counts: terminal runs once; an intermediate runs as many times as its output is demanded
	# upstream (every M1 recipe outputs 1 per run). Walk consumers→producers to propagate demand.
	var runs := {terminal.id: 1}
	for i in range(ordered.size() - 1, -1, -1):
		var sr: StationRecipe = ordered[i]
		var run := int(runs.get(sr.id, 1))
		for req in sr.inputs:
			var producer := _producer_of(req["match"])
			if producer != null:
				runs[producer.id] = int(runs.get(producer.id, 0)) + int(req.get("count", 1)) * run
	var out: Array = []
	for sr: StationRecipe in ordered:
		var run := int(runs.get(sr.id, 1))
		var inputs: Array = []
		for req in sr.inputs:
			inputs.append({"ref": req["match"], "count": int(req.get("count", 1)) * run,
				"is_tag": Database.get_ingredient(req["match"]) == null})
		out.append({"station_id": sr.station_id, "inputs": inputs, "output_id": sr.output_item_id, "runs": run})
	return out

# --- a dish's raw (non-intermediate) ingredients, aggregated with totals ---
static func get_base_ingredients(recipe_id: StringName) -> Array:
	var dish := Database.get_recipe(recipe_id)
	if dish == null:
		return []
	var terminal := Database.get_station_recipe(dish.terminal_recipe_id)
	if terminal == null:
		return []
	var totals := {}
	_accumulate_raw(terminal, 1, totals)
	var out: Array = []
	for ref in totals:
		out.append({"ref": ref, "count": int(totals[ref]["count"]), "is_tag": bool(totals[ref]["is_tag"])})
	return out

# --- spices whose flavor profile improves a dish (flavor_tags ∩ accepted_flavors) ---
static func get_compatible_spices(recipe_id: StringName) -> Array:
	var dish := Database.get_recipe(recipe_id)
	if dish == null:
		return []
	var out: Array = []
	for ing: IngredientData in Database.get_all_ingredients():
		if ing.flavor_tags.is_empty():
			continue
		for f in ing.flavor_tags:
			if dish.accepted_flavors.has(f):
				out.append(ing.id)
				break
	return out

# --- known dishes an ingredient contributes to (as a raw input, a tag it satisfies, or a spice) ---
static func get_dishes_using(ingredient_id: StringName, only_known: bool = true) -> Array:
	var ing := Database.get_ingredient(ingredient_id)
	var out: Array = []
	for rec: RecipeData in Database.get_all_recipes():
		if only_known and not GameState.is_recipe_known(rec.id):
			continue
		if _recipe_uses(rec.id, ingredient_id, ing):
			out.append(rec.id)
	return out

# --- internals ---
static func _collect_steps(sr: StationRecipe, ordered: Array, visited: Dictionary) -> void:
	if visited.has(sr.id):
		return
	visited[sr.id] = true
	for req in sr.inputs:
		var producer := _producer_of(req["match"])
		if producer != null:
			_collect_steps(producer, ordered, visited)
	ordered.append(sr)

static func _accumulate_raw(sr: StationRecipe, multiplier: int, totals: Dictionary) -> void:
	for req in sr.inputs:
		var ref: StringName = req["match"]
		var count := int(req.get("count", 1)) * multiplier
		var producer := _producer_of(ref)
		if producer != null:
			_accumulate_raw(producer, count, totals) # intermediate → recurse into its raw inputs
		elif totals.has(ref):
			totals[ref]["count"] = int(totals[ref]["count"]) + count
		else:
			totals[ref] = {"count": count, "is_tag": Database.get_ingredient(ref) == null}

static func _producer_of(item_or_tag: StringName) -> StationRecipe:
	for sr: StationRecipe in Database.get_all_station_recipes():
		if sr.output_item_id == item_or_tag: # intermediates have a producing recipe; raw/tags don't
			return sr
	return null

static func _recipe_uses(recipe_id: StringName, ingredient_id: StringName, ing: IngredientData) -> bool:
	for base in get_base_ingredients(recipe_id):
		if base["ref"] == ingredient_id:
			return true
		if bool(base["is_tag"]) and ing != null and ing.tags.has(base["ref"]):
			return true # base is a category this ingredient satisfies
	if ing != null and not ing.flavor_tags.is_empty():
		return get_compatible_spices(recipe_id).has(ingredient_id) # a compatible spice "is for" this dish
	return false