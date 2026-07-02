class_name GardenPot extends Control
## A garden pot. Gray-box now (empty). Holds exactly one spirit (planting via drag = G3;
## shovel removal = G6). Renders the pot + the planted spirit swatch. (GARDEN.md)

const SIZE := Vector2(40, 34)
const POT_COLOR := Color(0.55, 0.36, 0.24)
const RIM_COLOR := Color(0.42, 0.27, 0.18)

const DIG_TIME := 1.0

var _spirit_id: StringName = &"" # empty = no spirit
var pot_index := -1
var _watered := false
var _targeted := false
var _hold := 0.0


signal water_requested(pot_index: int)
signal spirit_dropped(pot_index: int, from_slot: int)
signal remove_requested(pot_index: int)


func _ready() -> void:
	custom_minimum_size = SIZE
	queue_redraw()

func _process(delta: float) -> void:
	var active := UIManager.active_tool == &"shovel" and not is_empty()
	var over := active and Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())
	if over != _targeted:
		_targeted = over
		queue_redraw()
	if over and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_hold += delta
		queue_redraw()
		if _hold >= DIG_TIME:
			_hold = 0.0
			_targeted = false
			remove_requested.emit(pot_index) # dig SFX hook goes here once a cue exists
		if _hold >= DIG_TIME:
			_hold = 0.0
			_targeted = false
			AudioManager.play_sfx(&"dig") # dig complete (silent until Week-3 audio)
			remove_requested.emit(pot_index)

	elif _hold > 0.0:
		_hold = 0.0 # released or moved off → cancel
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
		var c := ItemSlot.color_for(_spirit_id)
		if _targeted:
			c.a = 0.4 # shovel-targeted: dim (vulnerable to removal)
		draw_circle(Vector2(w * 0.5, h * 0.18), 7.0, c)
	if _watered and _spirit_id != &"":
		draw_circle(Vector2(w * 0.82, h * 0.06), 3.0, Color(0.35, 0.6, 0.95))
	if _hold > 0.0: # hold-to-dig radial
		var frac: float = _hold / DIG_TIME
		draw_arc(Vector2(w * 0.5, h * 0.18), 11.0, -PI / 2, -PI / 2 + TAU * frac, 24, Color(0.95, 0.85, 0.3), 2.5)


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
