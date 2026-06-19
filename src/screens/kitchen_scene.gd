extends Node2D
## The walkable kitchen (top-down). Hosts TopDownActor + station Interactables, routes each station
## to its UI (cooking bar floats above the station; Fridge / Recipe Book open as centered modals),
## and pauses movement while a UI is open. (§C.1, §C.2, §F)

const STATION_UI := preload("res://scenes/ui/StationUI.tscn")
const FRIDGE_UI := preload("res://scenes/ui/FridgeUI.tscn")
const RECIPE_BOOK_UI := preload("res://scenes/ui/RecipeBookUI.tscn")

const FLOOR_RECT := Rect2(20, 28, 600, 312)
const FLOOR_COLOR := Color(0.46, 0.38, 0.30)
const FLOOR_EDGE := Color(0.30, 0.24, 0.18)
const ACTOR_START := Vector2(320, 200)
const BAR_GAP := 8.0
const VIEWPORT := Vector2(640, 360)

@onready var _actor: TopDownActor = $TopDownActor
@onready var _ui_layer: CanvasLayer = $UI
@onready var _leave_button: Button = $UI/LeaveButton

var _detector: InteractionDetector
var _open_ui: Control = null

func _ready() -> void:
	_actor.bounds = FLOOR_RECT
	_actor.global_position = ACTOR_START
	_leave_button.pressed.connect(GameManager.request_return_to_ship)
	_detector = _actor.get_detector()
	_detector.interaction_triggered.connect(_on_interaction_triggered)
	queue_redraw()

func _draw() -> void:
	draw_rect(FLOOR_RECT, FLOOR_COLOR)
	draw_rect(FLOOR_RECT, FLOOR_EDGE, false, 3.0)

func _on_interaction_triggered(interactable: Interactable) -> void:
	if _open_ui != null:
		_close_open_ui()
	else:
		_open_ui_for(interactable)

func _open_ui_for(interactable: Interactable) -> void:
	var ui: Control
	match interactable.station_id:
		&"fridge":
			ui = FRIDGE_UI.instantiate()
			_ui_layer.add_child(ui)
			ui.setup()
		&"recipe_book":
			ui = RECIPE_BOOK_UI.instantiate()
			_ui_layer.add_child(ui)
			ui.setup()
		_:
			# prep / mix_bowl / oven → the cooking bar, floated above the station.
			ui = STATION_UI.instantiate()
			_ui_layer.add_child(ui)
			ui.setup(interactable.station_id, interactable.display_name)
			_position_above(ui, interactable)
	if ui.has_signal("close_requested"):
		ui.close_requested.connect(_close_open_ui)
	_open_ui = ui
	_actor.set_movement_enabled(false)
	_detector.set_prompt_enabled(false)

func _position_above(ui: Control, interactable: Interactable) -> void:
	# No Camera2D, so a station's world position == its screen position. Center the bar above the
	# block, then clamp it fully on-screen.
	ui.reset_size()
	var sz: Vector2 = ui.size
	var pos: Vector2 = interactable.global_position - Vector2(sz.x * 0.5, interactable.block_size.y * 0.5 + BAR_GAP + sz.y)
	pos.x = clampf(pos.x, 4.0, VIEWPORT.x - sz.x - 4.0)
	pos.y = clampf(pos.y, 4.0, VIEWPORT.y - sz.y - 4.0)
	ui.position = pos

func _close_open_ui() -> void:
	if is_instance_valid(_open_ui):
		_open_ui.queue_free()
	_open_ui = null
	_actor.set_movement_enabled(true)
	_detector.set_prompt_enabled(true)