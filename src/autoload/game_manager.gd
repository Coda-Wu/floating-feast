extends Node
## The controller: a DayPhase state machine owning day-cycle rules (budget reset, day-end,
## the day's island generation + the traveled path) that asks SceneRouter to change screens.
## Travel lines accumulate per island ENTERED; budget is spent per node RESOLVED (Step 5) —
## two separate systems (§13). (§5, §6)

enum DayPhase {MORNING, OCEAN_MAP, ISLAND, SHIP, KITCHEN, FAIR, DAY_END, GARDEN, TITLE}


var current_phase: DayPhase = DayPhase.MORNING


var _last_save: Dictionary = {}
var run_graph: RunGraph = null # the day's exploration DAG, generated on island entry (replaces the bridge)
var current_world_island: WorldIslandData = null
var _time_accum := 0.0

const SHIP_POS := Vector2(86, 300)
const FAINT_COIN_LOSS := 25 # capped; the faint never costs items/recipes/spirits/progress (§11)
const SHIP_TIME_RATE := 1.0 # in-game minutes per real second while walking the ship (SHIP.md)


# DAY_END is an overlay, not a screen, so it is deliberately absent here.
const _PHASE_SCREENS := {
	DayPhase.OCEAN_MAP: "res://scenes/screens/OceanMapScreen.tscn",
	DayPhase.ISLAND: "res://scenes/screens/IslandScreen.tscn",
	DayPhase.SHIP: "res://scenes/screens/CaptainRoom.tscn",
	DayPhase.FAIR: "res://scenes/screens/FairScene.tscn",
	DayPhase.GARDEN: "res://scenes/screens/GardenScene.tscn",
	DayPhase.TITLE: "res://scenes/screens/TitleScreen.tscn",

}


func _ready() -> void:
	_seed_new_game()

func _seed_new_game() -> void:
	# MVP starting fridge (Appendix A). No save system yet, so this seeds each boot; a real
	# new-game / load flow replaces it later via the serialization seam. Direct set (no signal):
	# this is initial model state, not a gameplay event.
	GameState._load_inventory({&"flour": 3, &"sugar": 2, &"olive_oil": 2, &"rice": 2, &"potato": 3, &"tomato": 3, &"eggplant": 1, &"salt": 5, &"rosemary": 1, &"onion": 1})
	GameState.known_recipes.assign([&"roasted_tomato"]) # tutorial's guaranteed recipe; rest are discoverable
	GameState.grant_starting_tools() # shovel + watering can (kind: tool); GARDEN.md
	current_world_island = Database.get_world_island(&"cat_island") # M1 home; the Sail Door's destination

	
func start_day() -> void:
	GameState.day_seed = _roll_day_seed()
	GameState.weather_id = _roll_weather(GameState.day_seed)
	SignalBus.day_started.emit(GameState.day)
	GameState.add_fuel(GameState.fuel_max) # Ember rests overnight → tank refills (clamps to max)
	GameState.reset_day_clock() # back to 6:00 AM
	GameState.islands_explored_today.clear()
	change_phase(DayPhase.SHIP, &"morning") # wake up in the Cabin (SHIP.md); MorningScreen retired

func show_title() -> void:
	UIManager.hide_hud()
	change_phase(DayPhase.TITLE) # not a hotbar phase; the time ticker skips it

func new_game() -> void:
	GameState.reset()
	_seed_new_game()
	UIManager.show_hud()
	start_day()
		# TEMP P-2b — dishes across tiers + methods for the Dishes tab
	GameState.known_recipes.assign([&"roasted_tomato", &"med_roasted_vegetables", &"classic_rustic_salad", &"hummus"])
	GameState.add_dish(&"roasted_tomato", 2, 1)
	GameState.add_dish(&"roasted_tomato", 3, 2)
	GameState.add_dish(&"med_roasted_vegetables", 5, 1)
	GameState.add_dish(&"med_roasted_vegetables", 3, 1)
	GameState.add_dish(&"classic_rustic_salad", 4, 1)
	GameState.add_dish(&"hummus", 2, 1)
	GameState.known_recipes.assign([&"roasted_tomato", &"med_roasted_vegetables", &"classic_rustic_salad", &"hummus"])
	# TEMP G3 — a spirit in the hotbar to drag-plant; remove after testing
	GameState.inventory[0] = {"kind": &"spirit", "id": &"spirit_tomato", "count": 1}
	SignalBus.inventory_slots_changed.emit()


func _process(delta: float) -> void:
	if current_phase != DayPhase.SHIP and current_phase != DayPhase.GARDEN:
		return # time is node-driven during exploration; static in menus/fair
	_time_accum += delta * SHIP_TIME_RATE
	if _time_accum >= 1.0:
		var mins := int(_time_accum)
		_time_accum -= mins
		GameState.advance_time(mins) # emits time_changed → HUD clock ticks
		if GameState.time_minutes >= GameState.CURFEW_MINUTES:
			_time_accum = 0.0
			request_end_day() # 2 AM on the ship → doze off (no penalty), day ends

func change_phase(next: DayPhase, spawn: StringName = &"") -> void:
	current_phase = next
	SignalBus.phase_changed.emit(next)
	if _PHASE_SCREENS.has(next):
		SceneRouter.change_screen(load(_PHASE_SCREENS[next]), spawn)
	else:
		push_warning("GameManager: no screen for phase %s yet." % DayPhase.keys()[next])


# --- Morning / map / island navigation ---
func request_sail() -> void:
	change_phase(DayPhase.OCEAN_MAP)


func request_return_to_ship() -> void: # exploration / Ocean Map exits → land in the Cabin (the hub)
	current_phase = DayPhase.SHIP
	SignalBus.phase_changed.emit(DayPhase.SHIP)
	SceneRouter.change_screen(load("res://scenes/screens/CabinScene.tscn"))


func request_enter_garden() -> void:
	change_phase(DayPhase.GARDEN)


func request_enter_fair() -> void:
	change_phase(DayPhase.FAIR)

func request_return_to_map() -> void: # Island "Back to Map": pick another island
	change_phase(DayPhase.OCEAN_MAP)


func enter_world_island(wi: WorldIslandData) -> void:
	current_world_island = wi
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
	# Per potted spirit: a watered pot advances toward its yield interval; on reaching it the spirit
	# produces and the counter resets. Unwatered pots pause (no progress). watered resets each day.
	var totals := {}
	for pot in GameState.garden_slots:
		if pot == null:
			continue
		var spirit := Database.get_spirit(StringName(pot["spirit"]))
		if spirit == null:
			pot["watered"] = false
			continue
		if pot.get("watered", false):
			pot["progress"] = int(pot.get("progress", 0)) + 1
			if pot["progress"] >= maxi(1, spirit.yield_interval_days):
				if spirit.produces != &"" and spirit.yield_per_night > 0:
					totals[spirit.produces] = int(totals.get(spirit.produces, 0)) + spirit.yield_per_night
				pot["progress"] = 0
		pot["watered"] = false # new day → must water again
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
	var ids := ["weather_sunny", "weather_rainy"]
	return ids[abs(seed) % ids.size()]


func apply_faint_penalty() -> void:
	var lost := mini(GameState.coins, FAINT_COIN_LOSS)
	if lost > 0:
		GameState.try_spend_coins(lost) # emits coins_changed → HUD updates
