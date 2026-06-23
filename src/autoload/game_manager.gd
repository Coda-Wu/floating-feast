extends Node
## The controller: a DayPhase state machine owning day-cycle rules (budget reset, day-end,
## the day's island generation + the traveled path) that asks SceneRouter to change screens.
## Travel lines accumulate per island ENTERED; budget is spent per node RESOLVED (Step 5) —
## two separate systems (§13). (§5, §6)

enum DayPhase {MORNING, OCEAN_MAP, ISLAND, SHIP, KITCHEN, FAIR, DAY_END}

var current_phase: DayPhase = DayPhase.MORNING


var _last_save: Dictionary = {}
var run_graph: RunGraph = null # the day's exploration DAG, generated on island entry (replaces the bridge)

const SHIP_POS := Vector2(86, 300)
const FAINT_COIN_LOSS := 25 # capped; the faint never costs items/recipes/spirits/progress (§11)


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
	SignalBus.day_started.emit(GameState.day)
	GameState.add_fuel(GameState.fuel_max) # Ember rests overnight → tank refills (clamps to max)
	GameState.reset_day_clock() # back to 6:00 AM
	change_phase(DayPhase.MORNING)

func change_phase(next: DayPhase) -> void:
	current_phase = next
	SignalBus.phase_changed.emit(next)
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


func enter_world_island(wi: WorldIslandData) -> void:
	run_graph = RunGraphGenerator.generate(wi, GameState.day_seed)
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


func _roll_day_seed() -> int:
	return hash(str(GameState.day) + "_floating_feast")

func _roll_weather(seed: int) -> String:
	var ids := ["weather_sunny", "weather_rainy", "weather_foggy"]
	return ids[abs(seed) % ids.size()]


func apply_faint_penalty() -> void:
	var lost := mini(GameState.coins, FAINT_COIN_LOSS)
	if lost > 0:
		GameState.try_spend_coins(lost) # emits coins_changed → HUD updates
