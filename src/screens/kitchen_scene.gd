extends Node2D
## The walkable kitchen (top-down). Hosts TopDownActor + (8b) station Interactables. World-space
## scene under ScreenHost; floor drawn gray-box, character clamped to the room. (§C.1, §F)

const FLOOR_RECT := Rect2(20, 28, 600, 312) # the walkable room (x, y, w, h)
const FLOOR_COLOR := Color(0.46, 0.38, 0.30)
const FLOOR_EDGE := Color(0.30, 0.24, 0.18)
const ACTOR_START := Vector2(320, 200)

@onready var _actor: TopDownActor = $TopDownActor
@onready var _leave_button: Button = $UI/LeaveButton

func _ready() -> void:
	_actor.bounds = FLOOR_RECT
	_actor.global_position = ACTOR_START
	_leave_button.pressed.connect(GameManager.request_return_to_ship)
	queue_redraw()

func _draw() -> void:
	draw_rect(FLOOR_RECT, FLOOR_COLOR)
	draw_rect(FLOOR_RECT, FLOOR_EDGE, false, 3.0)