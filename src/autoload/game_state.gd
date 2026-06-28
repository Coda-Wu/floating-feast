extends Node
## The runtime model: pure data + persistence + thin mutators that emit change signals.
## NO gameplay rules (deciding rewards / prices / tiers lives in the systems). (§6, §E)


# --- Runtime state ---
var day: int = 1
var coins: int = 50
# --- Player identity (player-set at M2 new-game onboarding; placeholders for now, never hardcoded in UI) ---
var player_name: String = "Saff" # canonical default protagonist name; M2 name-entry overwrites
var ship_name: String = "Saff's Ship" # throwaway placeholder, NOT canon; M2 onboarding writes the real value
var inventory: Array = [] # slot-ordered carried items; each cell null OR { kind:StringName, id:StringName, count:int }. Slots 0-9 = hotbar row 0.
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
var run_buff: Dictionary = {} # run-scoped synergy buff, e.g. { "fungible_yield_mult": 2, "label": ... }; cleared on run exit
var islands_explored_today: Array = [] # world-island ids explored today (one foray/day); cleared at dawn


const DAY_START_MINUTES := 360 # 6:00 AM
const CURFEW_MINUTES := 1560 # 2:00 AM — the day's hard edge


const HOTBAR_SLOTS := 10
const SLOTS_PER_ROW := 10
const BACKPACK_ROWS := 2 # active backpack rows below the hotbar (upgradable later, +1 row of 10 each)
const STACK_MAX := 999
const STARTING_TOOLS: Array[StringName] = [&"watering_can", &"shovel"] # granted at new-game start (GARDEN.md)


func _ready() -> void:
	_ensure_inventory_size()

func _ensure_inventory_size() -> void:
	var target := HOTBAR_SLOTS + BACKPACK_ROWS * SLOTS_PER_ROW
	while inventory.size() < target:
		inventory.append(null)


func would_pass_curfew(minutes: int) -> bool:
	return time_minutes + minutes > CURFEW_MINUTES

func reset_day_clock() -> void:
	time_minutes = DAY_START_MINUTES
	SignalBus.time_changed.emit(time_minutes)


func mark_island_explored(island_id: StringName) -> void:
	if island_id not in islands_explored_today:
		islands_explored_today.append(island_id)

# --- Ingredient inventory mutators (the one place inventory changes + the signal fires) ---
func add_item(item_id: StringName, count: int = 1) -> void:
	if count <= 0:
		return
	var remaining := count
	for i in inventory.size(): # 1) stack onto existing item slots
		if remaining <= 0: break
		if _is_item_slot(inventory[i], item_id):
			var space := STACK_MAX - int(inventory[i]["count"])
			if space > 0:
				var add := mini(space, remaining)
				inventory[i]["count"] += add
				remaining -= add
	for i in inventory.size(): # 2) leftovers into empty slots
		if remaining <= 0: break
		if inventory[i] == null:
			var add := mini(STACK_MAX, remaining)
			inventory[i] = {"kind": &"item", "id": item_id, "count": add}
			remaining -= add
	if remaining > 0:
		push_warning("Inventory full: dropped %d × %s" % [remaining, item_id]) # capacity-full UX is Step 5
	_emit_inventory_changed(item_id)

func remove_item(item_id: StringName, count: int = 1) -> bool:
	if count <= 0:
		return true
	if get_item_count(item_id) < count:
		return false
	var remaining := count
	for i in inventory.size():
		if remaining <= 0: break
		if _is_item_slot(inventory[i], item_id):
			var take := mini(int(inventory[i]["count"]), remaining)
			inventory[i]["count"] -= take
			remaining -= take
			if int(inventory[i]["count"]) <= 0:
				inventory[i] = null
	_emit_inventory_changed(item_id)
	return true

func get_item_count(item_id: StringName) -> int:
	var total := 0
	for slot in inventory:
		if _is_item_slot(slot, item_id):
			total += int(slot["count"])
	return total


# --- Spirit & tool entity tokens (unique, non-stacking; GARDEN.md) ---
func add_spirit(spirit_id: StringName) -> bool:
	return _add_unique_token(&"spirit", spirit_id, true) # gameplay event → emits

func grant_starting_tools() -> void:
	for tool_id in STARTING_TOOLS:
		_add_unique_token(&"tool", tool_id, false) # seed-time → silent (no UI yet)

func _add_unique_token(kind: StringName, id: StringName, emit: bool) -> bool:
	for slot in inventory:
		if slot != null and slot.get("kind") == kind and StringName(slot.get("id")) == id:
			return false # already held (unique)
	for i in inventory.size():
		if inventory[i] == null:
			inventory[i] = {"kind": kind, "id": id, "count": 1}
			if emit:
				SignalBus.inventory_slots_changed.emit()
			return true
	push_warning("No room for %s %s" % [kind, id])
	return false


# --- Auto-sort: merge same-id stacks, order by type, compact to the front (Step 5) ---
func sort_inventory() -> void:
	var merged: Dictionary = {} # "kind|id" -> {kind, id, count}
	var order: Array = [] # first-seen key order (stable before the sort)
	for slot in inventory:
		if slot == null:
			continue
		var key := "%s|%s" % [slot["kind"], slot["id"]]
		if merged.has(key):
			merged[key]["count"] += int(slot["count"])
		else:
			merged[key] = {"kind": slot["kind"], "id": slot["id"], "count": int(slot["count"])}
			order.append(key)
	var tokens: Array = []
	for key in order:
		tokens.append(merged[key])
	tokens.sort_custom(_sort_token_lt)
	var cells: Array = [] # split any over-cap stack (M1 never will, but stay correct)
	for t in tokens:
		var remaining := int(t["count"])
		while remaining > 0:
			var n := mini(STACK_MAX, remaining)
			cells.append({"kind": t["kind"], "id": t["id"], "count": n})
			remaining -= n
	inventory = []
	_ensure_inventory_size()
	for i in mini(cells.size(), inventory.size()):
		inventory[i] = cells[i]
	SignalBus.inventory_slots_changed.emit()

func _sort_token_lt(a, b) -> bool:
	var ka := _sort_key(a)
	var kb := _sort_key(b)
	for i in ka.size():
		if ka[i] != kb[i]:
			return ka[i] < kb[i]
	return false

func _sort_key(token) -> Array:
	var id := StringName(token["id"])
	var category := ""
	var name := String(id)
	if token["kind"] == &"item":
		var ing := Database.get_ingredient(id)
		if ing != null:
			category = String(ing.tags[0]) if ing.tags.size() > 0 else ""
			name = ing.display_name
	return [String(token["kind"]), category, name, String(id)]


# --- Trash: empty exactly one slot (whole stack); Step 5 ---
func clear_slot(index: int) -> void:
	if index < 0 or index >= inventory.size() or inventory[index] == null:
		return
	var token = inventory[index]
	inventory[index] = null
	if token.get("kind") == &"item":
		_emit_inventory_changed(StringName(token["id"])) # emits both ID + slots signals
	else:
		SignalBus.inventory_slots_changed.emit() # non-item kinds: positional only


func apply_run_buff(buff: Dictionary) -> void:
	run_buff = buff.duplicate(true)
	SignalBus.run_buff_applied.emit(run_buff)

func clear_run_buff() -> void:
	if run_buff.is_empty():
		return
	run_buff = {}
	SignalBus.run_buff_applied.emit(run_buff)

func has_run_buff() -> bool:
	return not run_buff.is_empty()


# --- Drag move: empty→move, same item→merge (overflow stays in source), different→swap (Step 6) ---
func move_slot(from: int, to: int) -> void:
	if from == to:
		return
	if from < 0 or from >= inventory.size() or to < 0 or to >= inventory.size():
		return
	var src = inventory[from]
	if src == null:
		return
	var dst = inventory[to]
	if dst == null:
		inventory[to] = src
		inventory[from] = null
	elif dst["kind"] == src["kind"] and StringName(dst["id"]) == StringName(src["id"]):
		var space := STACK_MAX - int(dst["count"]) # merge; overflow stays behind
		var moved := mini(space, int(src["count"]))
		if moved > 0:
			dst["count"] += moved
			src["count"] -= moved
			if int(src["count"]) <= 0:
				inventory[from] = null
	else:
		inventory[from] = dst
		inventory[to] = src
	SignalBus.inventory_slots_changed.emit()


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
		"player_name": player_name,
		"ship_name": ship_name,
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
		"island_depletion": island_depletion.duplicate(true),
	}

func deserialize(d: Dictionary) -> void:
	day = d.get("day", 1)
	coins = d.get("coins", 50)
	player_name = d.get("player_name", "Saff")
	ship_name = d.get("ship_name", "Saff's Ship")
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
	island_depletion = (d.get("island_depletion", {}) as Dictionary).duplicate(true)
	_load_inventory(d.get("inventory", []))

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


# --- Plant a carried spirit token into a pot (bag → pot; GARDEN.md / G3) ---
func plant_spirit(from_slot: int, pot_index: int) -> bool:
	if pot_index < 0 or pot_index >= garden_slots.size():
		return false
	if garden_slots[pot_index] != null:
		return false # one spirit per pot
	var token = get_slot(from_slot)
	if token == null or token.get("kind") != &"spirit":
		return false
	garden_slots[pot_index] = String(token["id"]) # the spirit moves bag → pot
	inventory[from_slot] = null
	SignalBus.inventory_slots_changed.emit() # hotbar drops the spirit
	return true


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


func record_tier_s_collected(island_id: StringName, tier_s_id: StringName) -> void:
	var st: Dictionary = island_depletion.get(island_id, {})
	st[tier_s_id] = int(st.get(tier_s_id, 0)) + 1
	island_depletion[island_id] = st


# --- Inventory utility helpers ---
func _is_item_slot(slot, item_id: StringName) -> bool:
	return slot != null and slot.get("kind") == &"item" and StringName(slot.get("id")) == item_id

func _emit_inventory_changed(item_id: StringName) -> void:
	SignalBus.inventory_changed.emit(item_id, get_item_count(item_id)) # ID consumers (fridge)
	SignalBus.inventory_slots_changed.emit() # positional consumers (hotbar/backpack)

func get_slot(i: int):
	return inventory[i] if i >= 0 and i < inventory.size() else null

func slot_count() -> int:
	return inventory.size()

func get_carried_item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot in inventory:
		if slot != null and slot.get("kind") == &"item":
			var id := StringName(slot["id"])
			if id not in ids:
				ids.append(id)
	return ids

func _load_inventory(data) -> void:
	inventory = []
	_ensure_inventory_size()
	if data is Array:
		for i in mini(data.size(), inventory.size()):
			var s = data[i]
			inventory[i] = (s.duplicate(true) if s is Dictionary else null)
	elif data is Dictionary: # legacy {id:count} save → fill slots in order
		var idx := 0
		for id in data:
			if idx >= inventory.size(): break
			inventory[idx] = {"kind": &"item", "id": StringName(id), "count": int(data[id])}
			idx += 1
	SignalBus.inventory_slots_changed.emit()
