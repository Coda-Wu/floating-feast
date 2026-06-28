extends Node2D
## The walkable spirit garden (side-scroller). Gray-box room; Leave returns to the ship.
## Player (G2b), pot rack (G2c), planting/watering/removal (G3–G6) arrive next. (GARDEN.md)

const SKY_COLOR := Color(0.62, 0.78, 0.86)
const GROUND_RECT := Rect2(0, 280, 640, 80)
const GROUND_COLOR := Color(0.42, 0.34, 0.26)

const RACK_RECT := Rect2(232, 256, 176, 10)
const RACK_COLOR := Color(0.5, 0.36, 0.22)


@onready var _leave_button: Button = $UI/LeaveButton

func _ready() -> void:
	_leave_button.pressed.connect(GameManager.request_return_to_ship)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), SKY_COLOR) # gray-box backdrop (Week-3 art swap)
	draw_rect(GROUND_RECT, GROUND_COLOR)
	draw_rect(RACK_RECT, RACK_COLOR) # gray-box pot rack (pots sit on top)
