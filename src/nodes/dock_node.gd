extends ExplorationNode
## Dock — the only in-run refuel. The standard 1 fuel was already paid on entry (like every node);
## here Ember drinks a random +1..3, clamped to the tank, so the net is 0/+1/+2. Node-gated (appears
## only when the generator includes it); IslandScreen needs no special-casing — the grant lives here.
## (§4.3, Step 6)

const MIN_REFUEL := 1
const MAX_REFUEL := 3

@onready var _result: Label = $Center/Panel/Margin/Column/Result
@onready var _cast_off: Button = $Center/Panel/Margin/Column/CastOff

func _run() -> void:
	var before := GameState.fuel_current
	GameState.add_fuel(randi_range(MIN_REFUEL, MAX_REFUEL)) # clamps to fuel_max
	var gained := GameState.fuel_current - before # actual gain after clamping
	_result.text = tr("Ember refuels: +%d fuel   (tank %d/%d)") % [gained, GameState.fuel_current, GameState.fuel_max]
	_cast_off.pressed.connect(func() -> void: complete({}, tr("Refueled at the dock (+%d fuel).") % gained))
