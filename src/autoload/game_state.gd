extends Node
## The runtime model: pure data + persistence, NO gameplay rules.
## Mutation helpers + signal emission are wired in Steps 2-3. (§6)

# --- Runtime state ---
var day: int = 1
var budget_max: int = 4
var budget_current: int = 4
var inventory: Dictionary = {} # item_id -> count
var captured_spirits: Array[String] = [] # spirit ids
var seen_tutorials: Dictionary = {} # mechanic_id -> true
var weather_id: String = ""
var day_seed: int = 0
var quest_phase: int = 0

# --- Serialization seam (disk save drops in later with no refactor) ---
func serialize() -> Dictionary:
	return {
		"day": day,
		"budget_max": budget_max,
		"budget_current": budget_current,
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
	inventory = (d.get("inventory", {}) as Dictionary).duplicate(true)
	captured_spirits.assign(d.get("captured_spirits", []))
	seen_tutorials = (d.get("seen_tutorials", {}) as Dictionary).duplicate(true)
	weather_id = d.get("weather_id", "")
	day_seed = d.get("day_seed", 0)
	quest_phase = d.get("quest_phase", 0)