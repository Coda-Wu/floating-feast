extends ExplorationNode
## Synergy Event — an early-path choice: sacrifice coins or fuel for a run-scoped buff that doubles
## FUNGIBLE yields for the rest of the run. The buff never multiplies capped Tier-S (enforced in
## IslandScreen by the tier_s_id tag). One per run: only offered when no buff is active, and it sits
## only in the shallow pool so a single layer-1 pick can grant it. Declining leaves the run unchanged.
## (§4.4, Step 8)

const COIN_COST := 30
const FUEL_COST := 2
const YIELD_MULT := 2

@onready var _body: Label = $Center/Panel/Margin/Column/Body
@onready var _coin_button: Button = $Center/Panel/Margin/Column/CoinButton
@onready var _fuel_button: Button = $Center/Panel/Margin/Column/FuelButton
@onready var _decline_button: Button = $Center/Panel/Margin/Column/DeclineButton

func _run() -> void:
	if GameState.has_run_buff():
		_body.text = "The spirits have already blessed your voyage today."
		_coin_button.hide(); _fuel_button.hide()
		_decline_button.text = "Move on"
		_decline_button.pressed.connect(func() -> void: complete({}, "Already blessed."))
		return
	_body.text = "A shrine hums with promise. Make an offering, and today's harvest turns bountiful (×%d fungible yields)." % YIELD_MULT
	_coin_button.text = "Offer %d coins" % COIN_COST
	_coin_button.disabled = GameState.coins < COIN_COST
	_coin_button.pressed.connect(_take_coins)
	_fuel_button.text = "Burn %d fuel" % FUEL_COST
	_fuel_button.disabled = GameState.fuel_current < FUEL_COST
	_fuel_button.pressed.connect(_take_fuel)
	_decline_button.text = "Decline"
	_decline_button.pressed.connect(func() -> void: complete({}, "You leave the shrine untouched."))

func _take_coins() -> void:
	GameState.spend_coins(COIN_COST) # swap if your coin-spend method differs (must emit coins_changed)
	_grant("offered coins")

func _take_fuel() -> void:
	GameState.spend_fuel(FUEL_COST)
	_grant("burned fuel")

func _grant(how: String) -> void:
	GameState.apply_run_buff({"fungible_yield_mult": YIELD_MULT, "label": "Bountiful Harvest (×%d)" % YIELD_MULT})
	complete({}, "You %s — a Bountiful Harvest blessing settles over the voyage!" % how)