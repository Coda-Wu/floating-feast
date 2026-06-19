class_name Cooking extends RefCounted
## Pure cooking-simulation logic: match slotted items against a station's StationRecipes. No state,
## no UI. Greedy assignment is sufficient for the M1 recipe set (few inputs, mostly distinct
## categories); a full bipartite match is a later upgrade if recipes get hairy. (§C.3, §C.4)

const ENHANCER_TAGS := [&"spice", &"flavor"]
# --- Quality Tier (terminal cooks only) ---
const BASE_TIER := 2 # a correctly-cooked dish, base ingredients, no added enhancers = ★★ "Plain"
const MAX_ENHANCER_BONUS := 3 # +1 per added spice/flavor enhancer, up to 3 → ★★★★★ via spices alone
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

## enhancer_count = leftover enhancers a terminal match carried (the `enhancers` array from find_match).
static func compute_tier(enhancer_count: int) -> Dictionary:
	var bonus := clampi(enhancer_count, 0, MAX_ENHANCER_BONUS)
	var tier := clampi(BASE_TIER + bonus, MIN_TIER, MAX_TIER)
	return {"tier": tier, "base_stars": BASE_TIER, "bonus_stars": bonus, "enhancer_count": enhancer_count}
