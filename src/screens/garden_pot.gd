class_name GardenPot extends Control
## A garden pot. Gray-box now (empty). Holds exactly one spirit (planting via drag = G3;
## shovel removal = G6). Renders the pot + the planted spirit swatch. (GARDEN.md)

const SIZE := Vector2(40, 34)
const POT_COLOR := Color(0.55, 0.36, 0.24)
const RIM_COLOR := Color(0.42, 0.27, 0.18)

var _spirit_id: StringName = &"" # empty = no spirit

var pot_index := -1


var _watered := false

signal water_requested(pot_index: int)
signal spirit_dropped(pot_index: int, from_slot: int)


func _ready() -> void:
	custom_minimum_size = SIZE
	queue_redraw()

func set_spirit(spirit_id: StringName) -> void:
	_spirit_id = spirit_id
	queue_redraw()


func set_watered(v: bool) -> void:
	_watered = v
	queue_redraw()


func is_empty() -> bool:
	return _spirit_id == &""

func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not is_empty():
		return false # one spirit per pot
	if not (data is Dictionary and data.has("from")):
		return false
	var token = GameState.get_slot(int(data["from"]))
	return token != null and token.get("kind") == &"spirit"

func _drop_data(_at_position: Vector2, data) -> void:
	spirit_dropped.emit(pot_index, int(data["from"]))


func _draw() -> void:
	var w := size.x
	var h := size.y
	var body := PackedVector2Array([
		Vector2(w * 0.18, h * 0.34), Vector2(w * 0.82, h * 0.34),
		Vector2(w * 0.70, h), Vector2(w * 0.30, h)])
	draw_colored_polygon(body, POT_COLOR) # gray-box pot body (Week-3 art swap)
	draw_rect(Rect2(w * 0.12, h * 0.18, w * 0.76, h * 0.18), RIM_COLOR) # rim
	if _spirit_id != &"":
		draw_circle(Vector2(w * 0.5, h * 0.18), 7.0, ItemSlot.color_for(_spirit_id)) # planted spirit
	if _watered and _spirit_id != &"":
		draw_circle(Vector2(size.x * 0.82, size.y * 0.06), 3.0, Color(0.35, 0.6, 0.95)) # watered marker


func _gui_input(event: InputEvent) -> void:
	if is_empty() or UIManager.active_tool != &"watering_can":
		return
	var spray := false
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
			and (event as InputEventMouseButton).pressed:
		spray = true
	elif event is InputEventMouseMotion and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		spray = true
	if spray:
		water_requested.emit(pot_index)
		accept_event()
