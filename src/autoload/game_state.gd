extends Node
## The runtime model: pure data + persistence + thin mutators that emit change
## signals. NO gameplay rules (deciding rewards / prices lives in the systems). (§6)

# --- Runtime state ---
var day: int = 1
var budget_max: int = 4
var budget_current: int = 4
var coins: int = 50 # forward-prep for the Step-5 shop (gray-box starting value)
var inventory: Dictionary = {} # item_id -> count
var captured_spirits: Array[String] = [] # spirit ids
var seen_tutorials: Dictionary = {} # mechanic_id -> true
var weather_id: String = ""
var day_seed: int = 0
var quest_phase: int = 0

# --- Inventory mutators (the one place inventory changes + the signal fires) ---
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

# --- Coin mutators (no coins signal yet — no Week-1 consumer; add one when a HUD needs it) ---
func add_coins(amount: int) -> void:
	if amount > 0:
		coins += amount

func try_spend_coins(amount: int) -> bool:
	if amount <= 0 or coins < amount:
		return false
	coins -= amount
	return true

# --- Serialization seam (disk save drops in later with no refactor) ---
func serialize() -> Dictionary:
	return {
		"day": day,
		"budget_max": budget_max,
		"budget_current": budget_current,
		"coins": coins,
		"inventory": inventory.duplicate(true),
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
	captured_spirits.assign(d.get("captured_spirits", []))
	seen_tutorials = (d.get("seen_tutorials", {}) as Dictionary).duplicate(true)
	weather_id = d.get("weather_id", "")
	day_seed = d.get("day_seed", 0)
	quest_phase = d.get("quest_phase", 0)