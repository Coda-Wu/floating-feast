extends Node
## The controller: a top-level DayPhase state machine that owns day-cycle rules (budget
## reset, day-end trigger, the day's island generation) and asks SceneRouter to change
## screens. (§5, §6)

enum DayPhase {MORNING, OCEAN_MAP, ISLAND, SHIP, DAY_END}

var current_phase: DayPhase = DayPhase.MORNING
var day_islands: Array[Island] = [] # the day's Ocean Map; regenerated at day start
var _last_save: Dictionary = {}

const SHIP_POS := Vector2(86, 300) # ship's spot on the Ocean Map (travel origin, 4c)
const _MIN_ISLANDS := 3
const _MAX_ISLANDS := 5

# Phases that map to a full screen. DAY_END is an overlay, not a screen. ISLAND registers
# in Step 5.
const _PHASE_SCREENS := {
	DayPhase.MORNING: "res://scenes/screens/MorningScreen.tscn",
	DayPhase.OCEAN_MAP: "res://scenes/screens/OceanMapScreen.tscn",
	DayPhase.SHIP: "res://scenes/screens/ShipScreen.tscn",
}

func start_day() -> void:
	GameState.day_seed = _roll_day_seed()
	GameState.weather_id = _roll_weather(GameState.day_seed)
	day_islands = _generate_day_islands(GameState.day_seed)
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

# --- Morning / map decisions ---
func request_sail() -> void:
	change_phase(DayPhase.OCEAN_MAP)

func request_stay() -> void:
	change_phase(DayPhase.SHIP)

func request_return_to_ship() -> void:
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

# --- Day setup ---
func _generate_day_islands(seed: int) -> Array[Island]:
	var templates: Array[IslandTemplate] = Database.get_random_island_templates()
	var result: Array[Island] = []
	if templates.is_empty():
		push_warning("GameManager: no random island templates found.")
		return result
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var count := rng.randi_range(_MIN_ISLANDS, _MAX_ISLANDS)
	var positions := IslandArranger.arrange(seed, count, SHIP_POS)
	for i in positions.size():
		var template: IslandTemplate = templates[rng.randi() % templates.size()]
		var isl := Island.new(template.id, positions[i])
		# Salt the per-island chain seed so chains don't correlate with positions.
		isl.node_chain = NodeChainGenerator.generate(template, seed + (i + 1) * 7919)
		result.append(isl)
	return result

func _roll_day_seed() -> int:
	return hash(str(GameState.day) + "_floating_feast")

func _roll_weather(seed: int) -> String:
	var ids := ["weather_sunny", "weather_rainy", "weather_foggy"]
	return ids[abs(seed) % ids.size()]