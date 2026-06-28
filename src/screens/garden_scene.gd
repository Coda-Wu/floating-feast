extends Node2D
## The walkable spirit garden (side-scroller). Gray-box room; Leave returns to the ship.
## Player (G2b), pot rack (G2c), planting/watering/removal (G3–G6) arrive next. (GARDEN.md)

const SKY_COLOR := Color(0.62, 0.78, 0.86)
const GROUND_RECT := Rect2(0, 280, 640, 80)
const GROUND_COLOR := Color(0.42, 0.34, 0.26)

const RACK_RECT := Rect2(232, 256, 176, 10)
const RACK_COLOR := Color(0.5, 0.36, 0.22)


@onready var _leave_button: Button = $UI/LeaveButton

@onready var _pots: Array = $UI/Pots.get_children()

func _ready() -> void:
	_leave_button.pressed.connect(GameManager.request_return_to_ship)
	for i in _pots.size():
		_pots[i].pot_index = i
		_pots[i].spirit_dropped.connect(_on_spirit_dropped)
		_refresh_pot(i)
		_pots[i].water_requested.connect(_on_water_requested)
		_pots[i].remove_requested.connect(_on_remove_requested)


	queue_redraw()

func _on_spirit_dropped(pot_index: int, from_slot: int) -> void:
	if GameState.plant_spirit(from_slot, pot_index):
		_refresh_pot(pot_index)

func _refresh_pot(i: int) -> void:
	var pot = GameState.garden_slots[i]
	if pot == null:
		_pots[i].set_spirit(&"")
		_pots[i].set_watered(false)
	else:
		_pots[i].set_spirit(StringName(pot["spirit"]))
		_pots[i].set_watered(bool(pot.get("watered", false)))

func _on_water_requested(pot_index: int) -> void:
	if GameState.water_pot(pot_index):
		_refresh_pot(pot_index) # show the droplet (splash polish later)

func _on_remove_requested(pot_index: int) -> void:
	if GameState.remove_potted_spirit(pot_index):
		_refresh_pot(pot_index)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), SKY_COLOR) # gray-box backdrop (Week-3 art swap)
	draw_rect(GROUND_RECT, GROUND_COLOR)
	draw_rect(RACK_RECT, RACK_COLOR) # gray-box pot rack (pots sit on top)
