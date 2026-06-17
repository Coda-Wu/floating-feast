class_name IslandMarker extends Area2D
## A gray-box island on the Ocean Map. Draws a placeholder circle, brightens on hover,
## and emits intent signals carrying its Island. Pointer interaction via Area2D (§4);
## visual is custom-drawn so Week 3 swaps in a sprite with no code change (§3).

signal marker_hovered(island)
signal marker_unhovered(island)
signal marker_clicked(island)

const RADIUS := 16.0
const COLOR_FILL := Color(0.55, 0.62, 0.40)
const COLOR_FILL_HOVER := Color(0.80, 0.86, 0.56)
const COLOR_OUTLINE := Color(0.20, 0.24, 0.15)

var _island: Island
var _hovered := false

func setup(island: Island) -> void:
	_island = island
	position = island.position
	queue_redraw()

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR_FILL_HOVER if _hovered else COLOR_FILL)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, COLOR_OUTLINE, 2.0, true)

func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()
	marker_hovered.emit(_island)

func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()
	marker_unhovered.emit(_island)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		marker_clicked.emit(_island)