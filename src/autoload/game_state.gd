extends Node
## The runtime model: pure data + persistence + thin mutators that emit change signals.
## NO gameplay rules (deciding rewards / prices / tiers lives in the systems). (§6, §E)

# --- Runtime state ---
var day: int = 1
var budget_max: int = 4
var budget_current: int = 4
var coins: int = 50
var inventory: Dictionary = {} # ingredient item_id -> count (UNTOUCHED by Week 2)
var dish_inventory: Dictionary = {} # "recipe_id|tier" -> count (the one Week-2 model extension, §H-1)
var known_recipes: Array[StringName] = [] # recipe ids the player has learned (codex)
var captured_spirits: Array[String] = []
var seen_tutorials: Dictionary = {}
var weather_id: String = ""
var day_seed: int = 0
var quest_phase: int = 0

# --- Ingredient inventory mutators (the one place inventory changes + the signal fires) ---
func add_item(item_id: StringName, count: int = 1) -> void:
	if count <= 0:
		return
	var new_count := int(inventory.get(item_id, 0)) + count
	inventory[item_id] = new_count
	SignalBus.inventory_changed.emit(item_id, new_count)

func remove_item(item_id: StringName, count: int = 1) -> bool:
	var have := int(inventory.get(item_id, 0))
	if have < count:
		return false
	var new_count := have - count
	if new_count <= 0:
		inventory.erase(item_id)
		new_count = 0
	else:
		inventory[item_id] = new_count
	SignalBus.inventory_changed.emit(item_id, new_count)
	return true

func get_item_count(item_id: StringName) -> int:
	return int(inventory.get(item_id, 0))

# --- Budget ---
func spend_budget(amount: int = 1) -> void:
	if amount <= 0:
		return
	budget_current = maxi(0, budget_current - amount)
	SignalBus.budget_changed.emit(budget_current, budget_max)
	if budget_current == 0:
		SignalBus.budget_depleted.emit()

# --- Coins (now emit coins_changed; consumed by the HUD + later payouts) ---
func add_coins(amount: int) -> void:
	if amount > 0:
		coins += amount
		SignalBus.coins_changed.emit(coins)

func try_spend_coins(amount: int) -> bool:
	if amount <= 0 or coins < amount:
		return false
	coins -= amount
	SignalBus.coins_changed.emit(coins)
	return true

# --- Dish store (parallel, tier-aware; ingredient inventory untouched, §H-1) ---
func _dish_key(recipe_id: StringName, tier: int) -> String:
	return "%s|%d" % [recipe_id, tier]

func add_dish(recipe_id: StringName, tier: int, n: int = 1) -> void:
	if n <= 0:
		return
	var key := _dish_key(recipe_id, tier)
	dish_inventory[key] = int(dish_inventory.get(key, 0)) + n

func count_dishes(recipe_id: StringName, min_tier: int = 1) -> int:
	var total := 0
	for key in dish_inventory:
		var parts := String(key).split("|")
		if parts.size() == 2 and StringName(parts[0]) == recipe_id and int(parts[1]) >= min_tier:
			total += int(dish_inventory[key])
	return total

func remove_dishes(recipe_id: StringName, min_tier: int, n: int) -> bool:
	if n <= 0:
		return true
	if count_dishes(recipe_id, min_tier) < n:
		return false
	# Consume lowest qualifying tier first, so the player keeps their best dishes.
	var tiers: Array = []
	for key in dish_inventory:
		var parts := String(key).split("|")
		if parts.size() == 2 and StringName(parts[0]) == recipe_id and int(parts[1]) >= min_tier:
			tiers.append(int(parts[1]))
	tiers.sort()
	var remaining := n
	for tier in tiers:
		if remaining <= 0:
			break
		var key := _dish_key(recipe_id, tier)
		var have := int(dish_inventory.get(key, 0))
		var take := mini(have, remaining)
		if have - take <= 0:
			dish_inventory.erase(key)
		else:
			dish_inventory[key] = have - take
		remaining -= take
	return true

func get_dish_entries() -> Array:
	# [{ recipe_id, tier, count }], sorted by recipe then tier desc — for Fridge / Recipe Book.
	var out: Array = []
	for key in dish_inventory:
		var parts := String(key).split("|")
		if parts.size() != 2:
			continue
		out.append({"recipe_id": StringName(parts[0]), "tier": int(parts[1]), "count": int(dish_inventory[key])})
	out.sort_custom(func(a, b):
		if a["recipe_id"] == b["recipe_id"]:
			return a["tier"] > b["tier"]
		return String(a["recipe_id"]) < String(b["recipe_id"]))
	return out

# --- Known recipes (codex) ---
func is_recipe_known(recipe_id: StringName) -> bool:
	return known_recipes.has(recipe_id)

func mark_recipe_known(recipe_id: StringName) -> bool:
	# Returns true only if newly added (drives the first-cook "New Recipe" pop in 11b).
	if known_recipes.has(recipe_id):
		return false
	known_recipes.append(recipe_id)
	return true

# --- Serialization seam (additive: ingredient inventory keys unchanged) ---
func serialize() -> Dictionary:
	return {
		"day": day,
		"budget_max": budget_max,
		"budget_current": budget_current,
		"coins": coins,
		"inventory": inventory.duplicate(true),
		"dish_inventory": dish_inventory.duplicate(true),
		"known_recipes": known_recipes.duplicate(),
		"captured_spirits": captured_spirits.duplicate(),
		"seen_tutorials": seen_tutorials.duplicate(true),
		"weather_id": weather_id,
		"day_seed": day_seed,
		"quest_phase": quest_phase,
	}

func deserialize(d: Dictionary) -> void:
	day = d.get("day", 1)
	budget_max = d.get("budget_max", 4)
	budget_current = d.get("budget_current", 4)
	coins = d.get("coins", 50)
	inventory = (d.get("inventory", {}) as Dictionary).duplicate(true)
	dish_inventory = (d.get("dish_inventory", {}) as Dictionary).duplicate(true)
	known_recipes.assign(d.get("known_recipes", []))
	captured_spirits.assign(d.get("captured_spirits", []))
	seen_tutorials = (d.get("seen_tutorials", {}) as Dictionary).duplicate(true)
	weather_id = d.get("weather_id", "")
	day_seed = d.get("day_seed", 0)
	quest_phase = d.get("quest_phase", 0)