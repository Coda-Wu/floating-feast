extends Node2D
## The walkable Cabin (main ship hub). Cook stations / fridge / recipe book are Interactables; press-E
## opens the matching UI (ported from kitchen_scene). Doors = 2c, edge zone = Phase 3, day loop = Phase 4. (SHIP.md)

const STATION_UI := preload("res://scenes/ui/StationUI.tscn")
const FRIDGE_UI := preload("res://scenes/ui/FridgeUI.tscn")
const RECIPE_BOOK_UI := preload("res://scenes/ui/RecipeBookUI.tscn")
const BAR_GAP := 8.0
const VIEWPORT := Vector2(640, 360)

@onready var _player: PlayerCharacter = $PlayerCharacter
@onready var _ui_layer: CanvasLayer = $UI
@onready var _to_captain_zone: Area2D = $ToCaptainZone


var _detector: InteractionDetector
var _open_ui: Control = null


func _ready() -> void:
	_detector = _player.get_detector()
	_detector.interaction_triggered.connect(_on_interaction_triggered)
	_to_captain_zone.body_entered.connect(_on_to_captain)
	_spawn_player()

func _on_interaction_triggered(interactable: Interactable) -> void:
	if _open_ui != null:
		_close_open_ui()
		return
	match interactable.station_id:
		&"garden_door":
			SceneRouter.change_screen(load("res://scenes/screens/GardenScene.tscn"), &"garden")
		_:
			_open_ui_for(interactable)


func _on_to_captain(body: Node2D) -> void:
	if body is PlayerCharacter:
		SceneRouter.change_screen(load("res://scenes/screens/CaptainRoom.tscn"), &"from_cabin")

func _spawn_player() -> void:
	if SceneRouter.pending_spawn == &"":
		return
	var marker := get_node_or_null("Spawns/%s" % SceneRouter.pending_spawn)
	if marker != null:
		_player.global_position = marker.global_position
		var cam := _player.get_node_or_null("Camera2D")
		if cam is Camera2D:
			cam.reset_smoothing()
	SceneRouter.pending_spawn = &""


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
			ui = STATION_UI.instantiate()
			_ui_layer.add_child(ui)
			ui.setup(interactable.station_id, interactable.display_name)
			_position_above(ui, interactable)
	if ui.has_signal("close_requested"):
		ui.close_requested.connect(_close_open_ui)
	_open_ui = ui
	_player.set_movement_enabled(false)
	_detector.set_prompt_enabled(false)

func _position_above(ui: Control, interactable: Interactable) -> void:
	ui.reset_size()
	var sz: Vector2 = ui.size
	var anchor: Vector2 = interactable.get_global_transform_with_canvas().origin # screen-space, camera-aware
	var pos: Vector2 = anchor - Vector2(sz.x * 0.5, interactable.block_size.y * 0.5 + BAR_GAP + sz.y)
	pos.x = clampf(pos.x, 4.0, VIEWPORT.x - sz.x - 4.0)
	pos.y = clampf(pos.y, 4.0, VIEWPORT.y - sz.y - 4.0)
	ui.position = pos


func _close_open_ui() -> void:
	if is_instance_valid(_open_ui):
		_open_ui.queue_free()
	_open_ui = null
	_player.set_movement_enabled(true)
	_detector.set_prompt_enabled(true)
