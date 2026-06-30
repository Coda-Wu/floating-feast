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

var _detector: InteractionDetector
var _open_ui: Control = null

func _ready() -> void:
	_detector = _player.get_detector()
	_detector.interaction_triggered.connect(_on_interaction_triggered)

func _on_interaction_triggered(interactable: Interactable) -> void:
	if _open_ui != null:
		_close_open_ui()
		return
	match interactable.station_id:
		&"garden_door":
			GameManager.request_enter_garden()
		_:
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
	var pos: Vector2 = interactable.global_position - Vector2(sz.x * 0.5, interactable.block_size.y * 0.5 + BAR_GAP + sz.y)
	pos.x = clampf(pos.x, 4.0, VIEWPORT.x - sz.x - 4.0)
	pos.y = clampf(pos.y, 4.0, VIEWPORT.y - sz.y - 4.0)
	ui.position = pos

func _close_open_ui() -> void:
	if is_instance_valid(_open_ui):
		_open_ui.queue_free()
	_open_ui = null
	_player.set_movement_enabled(true)
	_detector.set_prompt_enabled(true)
