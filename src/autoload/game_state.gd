extends Node
## The runtime model: pure data + persistence + thin mutators that emit change signals.
## NO gameplay rules (deciding rewards / prices / tiers lives in the systems). (§6, §E)

# --- Runtime state ---
var day: int = 1
var coins: int = 50
var inventory: Dictionary = {} # ingredient item_id -> count (UNTOUCHED by Week 2)
var fridge_storage: Dictionary = {} # ingredient item_id -> count (home storage; parallel to carried inventory)
var dish_inventory: Dictionary = {} # "recipe_id|tier" -> count (the one Week-2 model extension, §H-1)
var known_recipes: Array[StringName] = [] # recipe ids the player has learned (codex)
var captured_spirits: Array[String] = []
var garden_slots: Array = [null, null, null] # per-slot: spirit id (String) or null; small pot count for M1
var seen_tutorials: Dictionary = {}
var weather_id: String = ""
var day_seed: int = 0
var quest_phase: int = 0
var rank: int = 0 # Explorer League rank; 0 = unranked until the first Fair
var active_commissions: Array = [] # commission ids currently active
var fuel_max: int = 6
var fuel_current: int = 6
var time_minutes: int = 360 # 6:00 AM; the day runs to 1560 (2:00 AM)
var island_depletion: Dictionary = {} # { island_id: { tier_s_id: collected_count } } — generator reads; Step 7 writes + serializes

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
	SignalBus.dish_inventory_changed.emit()

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
	SignalBus.dish_inventory_changed.emit()
	return true


# --- Fridge storage (ingredients only; transfer one unit at a time carried <-> fridge) ---
func get_fridge_count(item_id: StringName) -> int:
	return int(fridge_storage.get(item_id, 0))

func deposit_to_fridge(item_id: StringName, count: int = 1) -> bool:
	if count <= 0 or get_item_count(item_id) < count:
		return false
	remove_item(item_id, count) # emits inventory_changed
	fridge_storage[item_id] = get_fridge_count(item_id) + count
	SignalBus.fridge_changed.emit()
	return true

func withdraw_from_fridge(item_id: StringName, count: int = 1) -> bool:
	if count <= 0 or get_fridge_count(item_id) < count:
		return false
	var left := get_fridge_count(item_id) - count
	if left <= 0:
		fridge_storage.erase(item_id)
	else:
		fridge_storage[item_id] = left
	add_item(item_id, count) # emits inventory_changed
	SignalBus.fridge_changed.emit()
	return true

# --- Family-aware dish queries (for commissions / Fair: match by RecipeData.family_tags) ---
func count_dishes_by_family(family: StringName, min_tier: int = 1) -> int:
	var total := 0
	for key in dish_inventory:
		var parts := String(key).split("|")
		if parts.size() != 2 or int(parts[1]) < min_tier:
			continue
		var rec := Database.get_recipe(StringName(parts[0]))
		if rec != null and rec.family_tags.has(family):
			total += int(dish_inventory[key])
	return total

func remove_dishes_by_family(family: StringName, min_tier: int, n: int) -> bool:
	if n <= 0:
		return true
	if count_dishes_by_family(family, min_tier) < n:
		return false
	# Lowest qualifying tier first (keep the player's best dishes).
	var keys: Array = []
	for key in dish_inventory:
		var parts := String(key).split("|")
		if parts.size() != 2 or int(parts[1]) < min_tier:
			continue
		var rec := Database.get_recipe(StringName(parts[0]))
		if rec != null and rec.family_tags.has(family):
			keys.append({"key": key, "tier": int(parts[1])})
	keys.sort_custom(func(a, b): return a["tier"] < b["tier"])
	var remaining := n
	for entry in keys:
		if remaining <= 0:
			break
		var key: String = entry["key"]
		var have := int(dish_inventory.get(key, 0))
		var take := mini(have, remaining)
		if have - take <= 0:
			dish_inventory.erase(key)
		else:
			dish_inventory[key] = have - take
		remaining -= take
	SignalBus.dish_inventory_changed.emit()
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
		"coins": coins,
		"inventory": inventory.duplicate(true),
		"dish_inventory": dish_inventory.duplicate(true),
		"known_recipes": known_recipes.duplicate(),
		"captured_spirits": captured_spirits.duplicate(),
		"seen_tutorials": seen_tutorials.duplicate(true),
		"weather_id": weather_id,
		"day_seed": day_seed,
		"quest_phase": quest_phase,
		"garden_slots": garden_slots.duplicate(),
		"active_commissions": active_commissions.duplicate(),
		"rank": rank,
		"fridge_storage": fridge_storage.duplicate(true),
		"fuel_current": fuel_current,
		"fuel_max": fuel_max,
		"time_minutes": time_minutes,
	}

func deserialize(d: Dictionary) -> void:
	day = d.get("day", 1)
	coins = d.get("coins", 50)
	inventory = (d.get("inventory", {}) as Dictionary).duplicate(true)
	dish_inventory = (d.get("dish_inventory", {}) as Dictionary).duplicate(true)
	known_recipes.assign(d.get("known_recipes", []))
	captured_spirits.assign(d.get("captured_spirits", []))
	seen_tutorials = (d.get("seen_tutorials", {}) as Dictionary).duplicate(true)
	weather_id = d.get("weather_id", "")
	day_seed = d.get("day_seed", 0)
	quest_phase = d.get("quest_phase", 0)
	garden_slots = (d.get("garden_slots", [null, null, null]) as Array).duplicate()
	active_commissions = (d.get("active_commissions", []) as Array).duplicate()
	rank = d.get("rank", 0)
	fridge_storage = (d.get("fridge_storage", {}) as Dictionary).duplicate(true)
	fuel_current = d.get("fuel_current", 6)
	fuel_max = d.get("fuel_max", 6)
	time_minutes = d.get("time_minutes", 360)

# --- Garden (assign captured spirits to pots; remove permanently consumes) ---
func assign_spirit_to_garden(spirit_id: String, slot: int) -> bool:
	if slot < 0 or slot >= garden_slots.size():
		return false
	if garden_slots[slot] != null or garden_slots.has(spirit_id):
		return false # slot taken, or this spirit already potted
	if not captured_spirits.has(spirit_id):
		return false
	garden_slots[slot] = spirit_id
	return true

func remove_spirit_from_garden(slot: int) -> void:
	# Removing PERMANENTLY consumes the spirit — gone from the roster, not returned.
	if slot < 0 or slot >= garden_slots.size():
		return
	var spirit_id = garden_slots[slot]
	garden_slots[slot] = null
	if spirit_id != null:
		captured_spirits.erase(spirit_id)


# --- Explorer League rank (increases at Fair completion) ---
func set_rank(new_rank: int) -> void:
	if new_rank > rank:
		rank = new_rank
		SignalBus.rank_changed.emit(rank)


# --- Fuel & Time (exploration resources) ---
func spend_fuel(amount: int) -> void:
	if amount <= 0:
		return
	fuel_current = maxi(0, fuel_current - amount)
	SignalBus.fuel_changed.emit(fuel_current, fuel_max)
	# (fuel_depleted is emitted from here in Step 4, where the traversal consumes it)

func add_fuel(amount: int) -> void:
	if amount <= 0:
		return
	fuel_current = mini(fuel_max, fuel_current + amount) # clamp to tank
	SignalBus.fuel_changed.emit(fuel_current, fuel_max)

func advance_time(minutes: int) -> void:
	if minutes <= 0:
		return
	time_minutes += minutes
	SignalBus.time_changed.emit(time_minutes)