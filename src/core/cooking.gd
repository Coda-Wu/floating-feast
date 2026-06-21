class_name Cooking extends RefCounted
## Pure cooking-simulation logic: match slotted items against a station's StationRecipes. No state,
## no UI. Greedy assignment is sufficient for the M1 recipe set (few inputs, mostly distinct
## categories); a full bipartite match is a later upgrade if recipes get hairy. (§C.3, §C.4)


const PREP_STATION := &"prep"
const ENHANCER_TAGS := [&"spice", &"flavor"]
# --- Quality Tier & spice compatibility (terminal cooks only) ---
const BASE_TIER := 2 # correctly-cooked, base ingredients, no compatible spice = ★★ Plain
const MIN_TIER := 1
const MAX_TIER := 5


## Returns { recipe: StationRecipe, enhancers: Array } or {} if nothing matches.
static func find_match(station_id: StringName, slot_items: Array) -> Dictionary:
	var best := {}
	var best_specificity := -1
	for recipe: StationRecipe in Database.get_station_recipes_for(station_id):
		var attempt := _try_match(recipe, slot_items)
		if attempt.is_empty():
			continue
		var spec := _required_total(recipe)
		if spec > best_specificity: # most specific (most required inputs) wins
			best_specificity = spec
			best = {"recipe": recipe, "enhancers": attempt["enhancers"]}
	return best

static func _try_match(recipe: StationRecipe, slot_items: Array) -> Dictionary:
	var remaining: Array = slot_items.duplicate()
	for req in recipe.inputs:
		var need := int(req.get("count", 1))
		var key: StringName = req["match"]
		var i := 0
		while i < remaining.size() and need > 0:
			if _item_matches(remaining[i], key):
				remaining.remove_at(i)
				need -= 1
			else:
				i += 1
		if need > 0:
			return {} # requirement unmet
	if remaining.is_empty():
		return {"enhancers": []}
	# Leftovers: allowed only on terminal recipes, and only if every leftover is an enhancer.
	if not recipe.is_terminal:
		return {}
	for item_id in remaining:
		if not is_enhancer(item_id):
			return {}
	return {"enhancers": remaining}

static func _item_matches(item_id: StringName, key: StringName) -> bool:
	if item_id == key:
		return true
	var ing := Database.get_ingredient(item_id)
	return ing != null and ing.tags.has(key)

static func is_enhancer(item_id: StringName) -> bool:
	var ing := Database.get_ingredient(item_id)
	if ing == null:
		return false
	for t in ENHANCER_TAGS:
		if ing.tags.has(t):
			return true
	return false

static func _required_total(recipe: StationRecipe) -> int:
	var total := 0
	for req in recipe.inputs:
		total += int(req.get("count", 1))
	return total


## Prep is a 1:1 batch transform, not a combinatorial recipe: each raw ingredient maps to its
## mid-stage product independently. Returns the output for one item, or &"" if it can't be prepped.
## Sourced from single-input Prep StationRecipes (e.g. sr_chop_vegetable), so new prep transforms
## are just more single-input recipes — no special-casing here. (user logic adj.)
static func get_prep_output(item_id: StringName) -> StringName:
	for recipe: StationRecipe in Database.get_station_recipes_for(PREP_STATION):
		if recipe.inputs.size() == 1 and int(recipe.inputs[0].get("count", 1)) == 1:
			if _item_matches(item_id, recipe.inputs[0]["match"]):
				return recipe.output_item_id
	return &""


## Sort a terminal cook's leftover spices into counted (distinct, compatible, within the dish's cap)
## vs set_aside (incompatible, duplicate, or beyond the cap — returned to inventory), and compute the
## final tier (clamped to the dish's per-recipe cap). spice_items are find_match's leftover enhancers
## (already guaranteed spice-tagged). (superseding tier rules)
static func evaluate_seasoning(terminal_recipe: StationRecipe, spice_items: Array) -> Dictionary:
	var dish := Database.get_recipe(terminal_recipe.output_item_id) # terminal output_item_id == dish id
	var accepted: Array = dish.accepted_flavors if dish else []
	var cap: int = dish.tier_cap if dish else MAX_TIER
	var headroom: int = maxi(0, cap - BASE_TIER) # how many spices can actually raise this dish
	var counted: Array = [] # distinct + compatible + within headroom → consumed, +1 each
	var set_aside: Array = [] # incompatible / duplicate / beyond cap → returned
	var counted_types := {}
	for item_id in spice_items:
		if _spice_compatible(item_id, accepted) and not counted_types.has(item_id) and counted.size() < headroom:
			counted_types[item_id] = true
			counted.append(item_id)
		else:
			set_aside.append(item_id)
	return {
		"tier": clampi(BASE_TIER + counted.size(), MIN_TIER, cap),
		"counted": counted, "set_aside": set_aside, "cap": cap,
	}

## A spice improves a dish iff its flavor profile intersects the dish's accepted flavors.
static func _spice_compatible(item_id: StringName, accepted_flavors: Array) -> bool:
	var ing := Database.get_ingredient(item_id)
	if ing == null:
		return false
	for f in ing.flavor_tags:
		if accepted_flavors.has(f):
			return true
	return false