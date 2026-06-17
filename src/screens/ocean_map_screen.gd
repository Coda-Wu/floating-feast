extends Control
## The Ocean Map: renders the day's islands as markers, previews each island's chain on
## hover, animates the dashed travel line on click, and offers Return to Ship. Sea + ship
## are painted in _draw() (no covering Control, so Area2D picking works). (§5, §9)

const IslandMarkerScene := preload("res://scenes/ui/IslandMarker.tscn")

const NODE_LABELS := {
	&"gathering": "Forage", &"spirit_encounter": "Spirit", &"shop": "Shop",
	&"butchery": "Butcher", &"npc": "NPC", &"event": "Event",
}

const SEA_COLOR := Color(0.16, 0.34, 0.45)
const SHIP_COLOR := Color(0.85, 0.70, 0.45)
const SHIP_RADIUS := 10.0
const VIEWPORT := Vector2(640, 360)

@onready var _travel_route: TravelRoute = $TravelRoute
@onready var _marker_layer: Node2D = $MarkerLayer
@onready var _preview: PanelContainer = $NodePreview
@onready var _preview_row: HBoxContainer = $NodePreview/PMargin/Row
@onready var _return_button: Button = $ReturnButton

var _obstacles: Array[Vector2] = []
var _traveling := false

func _ready() -> void:
	get_viewport().physics_object_picking = true
	_preview.hide()
	_return_button.pressed.connect(GameManager.request_return_to_ship)
	for isl in GameManager.day_islands:
		_obstacles.append(isl.position)
	_travel_route.set_committed(GameManager.travel_path, _obstacles) # redraw already-sailed legs
	_spawn_markers()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT), SEA_COLOR)
	draw_circle(GameManager.SHIP_POS, SHIP_RADIUS, SHIP_COLOR)
	draw_arc(GameManager.SHIP_POS, SHIP_RADIUS, 0.0, TAU, 24, Color(0.45, 0.32, 0.16), 2.0, true)

func _spawn_markers() -> void:
	for island in GameManager.day_islands:
		var marker := IslandMarkerScene.instantiate()
		_marker_layer.add_child(marker)
		marker.setup(island)
		marker.marker_hovered.connect(_on_marker_hovered)
		marker.marker_unhovered.connect(_on_marker_unhovered)
		marker.marker_clicked.connect(_on_marker_clicked)

func _on_marker_hovered(island) -> void:
	if _traveling:
		return
	for child in _preview_row.get_children():
		_preview_row.remove_child(child)
		child.queue_free()
	for nd in island.node_chain:
		var lbl := Label.new()
		lbl.text = NODE_LABELS.get(nd.type, String(nd.type))
		_preview_row.add_child(lbl)
	_preview.show()
	_preview.reset_size()
	var sz := _preview.size
	var pos: Vector2 = island.position + Vector2(IslandMarker.RADIUS + 6.0, -IslandMarker.RADIUS)
	pos.x = clampf(pos.x, 4.0, VIEWPORT.x - sz.x - 4.0)
	pos.y = clampf(pos.y, 4.0, VIEWPORT.y - sz.y - 4.0)
	_preview.position = pos

func _on_marker_unhovered(_island) -> void:
	_preview.hide()

func _on_marker_clicked(island) -> void:
	if _traveling:
		return
	var from: Vector2 = GameManager.travel_path.back()
	if from.distance_to(island.position) <= 1.0:
		GameManager.enter_island(island) # already here — skip the zero-length sail
		return
	_traveling = true
	_preview.hide()
	_return_button.disabled = true
	_travel_route.animate_to(from, island.position, _obstacles)
	await _travel_route.travel_finished
	GameManager.enter_island(island)
