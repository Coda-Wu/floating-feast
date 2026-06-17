extends Node
## The controller: a top-level DayPhase state machine that owns day-cycle rules
## (budget reset at day start, day-end trigger) and asks SceneRouter to change
## screens. (§5, §6)

enum DayPhase {MORNING, OCEAN_MAP, ISLAND, SHIP, DAY_END}

var current_phase: DayPhase = DayPhase.MORNING
var _last_save: Dictionary = {} # in-memory save; disk drops in later via the same seam

# Phases that map to a full screen. DAY_END is an overlay, not a screen, so it is
# deliberately absent. OCEAN_MAP / ISLAND register in Steps 4 / 5.
const _PHASE_SCREENS := {
	DayPhase.MORNING: "res://scenes/screens/MorningScreen.tscn",
	DayPhase.SHIP: "res://scenes/screens/ShipScreen.tscn",
}

func start_day() -> void:
	GameState.day_seed = _roll_day_seed()
	GameState.weather_id = _roll_weather(GameState.day_seed)
	GameState.budget_current = GameState.budget_max
	SignalBus.budget_changed.emit(GameState.budget_current, GameState.budget_max)
	SignalBus.day_started.emit(GameState.day)
	change_phase(DayPhase.MORNING)

func change_phase(next: DayPhase) -> void:
	current_phase = next
	if _PHASE_SCREENS.has(next):
		SceneRouter.change_screen(load(_PHASE_SCREENS[next]))
	else:
		push_warning("GameManager: no screen for phase %s yet (coming in a later step)." % DayPhase.keys()[next])

# --- Morning decisions ---
func request_sail() -> void:
	change_phase(DayPhase.OCEAN_MAP) # inert until Step 4 registers the Ocean Map screen

func request_stay() -> void:
	change_phase(DayPhase.SHIP)

# --- Day end ---
func request_end_day() -> void:
	current_phase = DayPhase.DAY_END # overlay phase: no screen swap
	var overnight_yields: Array = [] # empty stub in Week 1
	UIManager.show_day_end_panel(overnight_yields, _on_day_end_confirmed)

func _on_day_end_confirmed() -> void:
	SignalBus.day_ended.emit()
	_save_in_memory()
	GameState.day += 1
	start_day()

func _save_in_memory() -> void:
	_last_save = GameState.serialize()
	print("[GameManager] saved (in-memory) at end of day ", _last_save.get("day"))

# --- Gray-box helpers (Step 4 formalizes seed use for the island arranger) ---
func _roll_day_seed() -> int:
	return hash(str(GameState.day) + "_floating_feast")

func _roll_weather(seed: int) -> String:
	var ids := ["weather_sunny", "weather_rainy", "weather_foggy"]
	return ids[abs(seed) % ids.size()]