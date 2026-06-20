extends Node
## The controller: a DayPhase state machine owning day-cycle rules (budget reset, day-end,
## the day's island generation + the traveled path) that asks SceneRouter to change screens.
## Travel lines accumulate per island ENTERED; budget is spent per node RESOLVED (Step 5) —
## two separate systems (§13). (§5, §6)

enum DayPhase {MORNING, OCEAN_MAP, ISLAND, SHIP, KITCHEN, FAIR, DAY_END}

var current_phase: DayPhase = DayPhase.MORNING
var day_islands: Array[Island] = [] # the day's Ocean Map; regenerated at day start
var travel_path: Array[Vector2] = [] # waypoints sailed today: [ship, islandA, ...]
var current_island: Island = null # the island currently being explored
var _last_save: Dictionary = {}

const SHIP_POS := Vector2(86, 300)
const _MIN_ISLANDS := 3
const _MAX_ISLANDS := 5

# DAY_END is an overlay, not a screen, so it is deliberately absent here.
const _PHASE_SCREENS := {
	DayPhase.MORNING: "res://scenes/screens/MorningScreen.tscn",
	DayPhase.OCEAN_MAP: "res://scenes/screens/OceanMapScreen.tscn",
	DayPhase.ISLAND: "res://scenes/screens/IslandScreen.tscn",
	DayPhase.SHIP: "res://scenes/screens/ShipScreen.tscn",
	DayPhase.KITCHEN: "res://scenes/screens/KitchenScene.tscn",
	DayPhase.FAIR: "res://scenes/screens/FairScene.tscn",
}

func _ready() -> void:
	_seed_new_game()

func _seed_new_game() -> void:
	# MVP starting fridge (Appendix A). No save system yet, so this seeds each boot; a real
	# new-game / load flow replaces it later via the serialization seam. Direct set (no signal):
	# this is initial model state, not a gameplay event.
	GameState.inventory = {&"flour": 3, &"sugar": 2, &"olive_oil": 2, &"rice": 2, &"potato": 3, &"tomato": 3, &"eggplant": 1, &"salt": 5, &"rosemary": 1, &"onion": 1}
	GameState.known_recipes.assign([&"roasted_tomato"]) # tutorial's guaranteed recipe; rest are discoverable
	

func start_day() -> void:
	GameState.day_seed = _roll_day_seed()
	GameState.weather_id = _roll_weather(GameState.day_seed)
	day_islands = _generate_day_islands(GameState.day_seed)
	travel_path.assign([SHIP_POS]) # fresh journey from the ship
	current_island = null
	GameState.budget_current = GameState.budget_max
	SignalBus.budget_changed.emit(GameState.budget_current, GameState.budget_max)
	SignalBus.day_started.emit(GameState.day)
	change_phase(DayPhase.MORNING)

func change_phase(next: DayPhase) -> void:
	current_phase = next
	if _PHASE_SCREENS.has(next):
		SceneRouter.change_screen(load(_PHASE_SCREENS[next]))
	else:
		push_warning("GameManager: no screen for phase %s yet." % DayPhase.keys()[next])

# --- Morning / map / island navigation ---
func request_sail() -> void:
	change_phase(DayPhase.OCEAN_MAP)

func request_stay() -> void:
	change_phase(DayPhase.SHIP)

func request_return_to_ship() -> void: # Ocean Map "Return to Ship": end exploration
	change_phase(DayPhase.SHIP)

func request_enter_kitchen() -> void:
	change_phase(DayPhase.KITCHEN)

func request_enter_fair() -> void:
	change_phase(DayPhase.FAIR)

func request_return_to_map() -> void: # Island "Back to Map": pick another island
	change_phase(DayPhase.OCEAN_MAP)

func enter_island(island: Island) -> void:
	current_island = island
	# Commit the waypoint (skip a duplicate if re-entering where we already are).
	if travel_path.is_empty() or travel_path.back().distance_to(island.position) > 1.0:
		travel_path.append(island.position)
	change_phase(DayPhase.ISLAND)

# --- Day end ---
func request_end_day() -> void:
	current_phase = DayPhase.DAY_END # overlay phase: no screen swap
	var overnight_yields := _resolve_overnight_yields() # real garden yields (Week-1 stub realized)
	UIManager.show_day_end_panel(overnight_yields, _on_day_end_confirmed.bind(overnight_yields))

func _on_day_end_confirmed(overnight_yields: Array) -> void:
	for y in overnight_yields:
		GameState.add_item(y["item_id"], int(y["count"])) # crops land in inventory
	SignalBus.day_ended.emit()
	_save_in_memory()
	GameState.day += 1
	start_day()


func _resolve_overnight_yields() -> Array:
	# Sum each potted spirit's overnight produce → [{ item_id, count }] for the DayEndPanel + inventory.
	var totals := {}
	for spirit_id in GameState.garden_slots:
		if spirit_id == null:
			continue
		var spirit := Database.get_spirit(StringName(spirit_id))
		if spirit == null or spirit.produces == &"" or spirit.yield_per_night <= 0:
			continue
		totals[spirit.produces] = int(totals.get(spirit.produces, 0)) + spirit.yield_per_night
	var out: Array = []
	for item_id in totals:
		out.append({"item_id": item_id, "count": int(totals[item_id])})
	return out

	
func _save_in_memory() -> void:
	_last_save = GameState.serialize()
	print("[GameManager] saved (in-memory) at end of day ", _last_save.get("day"))

# --- Day setup ---
func _generate_day_islands(seed: int) -> Array[Island]:
	var templates := Database.get_random_island_templates()
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
		isl.node_chain = NodeChainGenerator.generate(template, seed + (i + 1) * 7919)
		result.append(isl)
	
	# stage the mission island so the commission/Fair chain is reachable in a normal run.
	var _mt := Database.get_island_template(&"island_mission_whale")
	if _mt:
		var _mi := Island.new(_mt.id, Vector2(330, 90))
		_mi.node_chain = NodeChainGenerator.generate(_mt, seed)
		result.append(_mi)
		
	return result

func _roll_day_seed() -> int:
	return hash(str(GameState.day) + "_floating_feast")

func _roll_weather(seed: int) -> String:
	var ids := ["weather_sunny", "weather_rainy", "weather_foggy"]
	return ids[abs(seed) % ids.size()]