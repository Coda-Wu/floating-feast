class_name ItemSlot extends Panel
## Reusable inventory slot: a center sprite area (gray-box swatch — the Week-3 swap target), a quantity
## number bottom-right (Stardew-style, hidden at 1), an optional hotkey indicator bottom-left, and a
## hover tooltip (the item name follows the cursor, shown via UIManager). Used by the Quick Access
## hotbar and every Fridge grid. Dumb view; emits slot_clicked with its item id. (Inventory-UX polish)

signal slot_clicked(item_id: String)
signal slot_dropped(from_index: int, to_index: int) # built-in drag: source slot → this slot (Step 6)

const BORDER_DEFAULT := Color(0.42, 0.42, 0.48)
const BORDER_SELECTED := Color(0.95, 0.3, 0.3) # red selection outline (Step 4)

@onready var _swatch: ColorRect = $Swatch
@onready var _count: Label = $CountLabel
@onready var _hotkey: Label = $HotkeyLabel
@onready var _star: Label = $StarLabel

var _item_id: StringName = &""
var _item_name: String = ""
var _clickable: bool = true
var _hovered: bool = false
var _count_val := 1
var _panel_style: StyleBoxFlat = null # the slot's own gray-box border; recolored red when selected

var drag_enabled := false # opt-in per context; only the Backpack enables drag (Step 6)
var _slot_index := -1 # this slot's index in GameState.inventory (set by the owning grid)


var _hotkey_val := ""
var _stars_val := 0

func _ready() -> void:
	_panel_style = StyleBoxFlat.new() # gray-box cell background; real art is a Week-3 swap
	_panel_style.bg_color = Color(0.20, 0.20, 0.24, 0.85)
	_panel_style.set_corner_radius_all(4)
	_panel_style.set_border_width_all(1)
	_panel_style.border_color = BORDER_DEFAULT
	add_theme_stylebox_override("panel", _panel_style)

	for lbl in [_count, _hotkey, _star]: # corner labels: small, white, dark outline for legibility
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		lbl.add_theme_constant_override("outline_size", 4)
	for child in [_swatch, _count, _hotkey, _star]: # Panel owns mouse/drop across the whole cell
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_star.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_star.add_theme_font_size_override("font_size", 9)
	
	# Apply cached values now that nodes are ready
	var temp_stars := _stars_val
	set_item(_item_id, _count_val, _item_name, _clickable)
	if temp_stars > 0:
		set_stars(temp_stars)
	set_hotkey(_hotkey_val)

func set_item(item_id: StringName, count: int, item_name: String, clickable: bool = true) -> void:
	_item_id = item_id
	_item_name = item_name
	_clickable = clickable
	_count_val = count
	_stars_val = 0
	if not is_node_ready():
		return
	var occupied := item_id != &""
	_swatch.visible = occupied
	_star.visible = false
	_star.text = ""
	if occupied:
		_swatch.color = color_for(item_id)
	_count.visible = occupied and count > 1 # Stardew: no number on a stack of 1
	_count.text = str(count)
	if _hovered:
		_update_hover() # contents changed under the cursor → refresh tooltip

func set_hotkey(text: String) -> void:
	_hotkey_val = text
	if not is_node_ready():
		return
	_hotkey.text = text
	_hotkey.visible = text != ""

func set_stars(tier: int) -> void:
	_stars_val = tier
	if not is_node_ready():
		return
	_star.text = "★".repeat(maxi(tier, 0)) if tier > 0 else ""
	_star.visible = tier > 0

func set_selected(selected: bool) -> void:
	if _panel_style == null:
		return
	_panel_style.set_border_width_all(2 if selected else 1)
	_panel_style.border_color = BORDER_SELECTED if selected else BORDER_DEFAULT


func _gui_input(event: InputEvent) -> void:
	if not _clickable or _item_id == &"":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		# Draggable slots fire on RELEASE (so a press that becomes a drag doesn't also select);
		# non-draggable slots fire on PRESS for instant feedback (cook stations, hotbar staging).
		var fire := (not mouse_event.pressed) if drag_enabled else mouse_event.pressed
		if fire:
			slot_clicked.emit(String(_item_id))
			accept_event()


func set_slot_index(i: int) -> void:
	_slot_index = i

func _get_drag_data(_at_position: Vector2):
	if not drag_enabled or _item_id == &"":
		return null
	set_drag_preview(_make_drag_preview())
	return {"from": _slot_index}

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return drag_enabled and data is Dictionary and data.has("from")

func _drop_data(_at_position: Vector2, data) -> void:
	slot_dropped.emit(int(data["from"]), _slot_index)

func _make_drag_preview() -> Control:
	var wrap := Control.new()
	var p := ColorRect.new()
	p.color = color_for(_item_id)
	p.size = Vector2(40, 32)
	p.position = -p.size * 0.5 # center on the cursor
	p.modulate.a = 0.8
	wrap.add_child(p)
	return wrap


func _on_mouse_entered() -> void:
	_hovered = true
	_update_hover()

func _on_mouse_exited() -> void:
	_hovered = false
	UIManager.hide_item_tooltip()
	modulate = Color.WHITE

func _update_hover() -> void:
	if _hovered and _item_id != &"":
		UIManager.show_item_tooltip(_item_name)
		modulate = Color(1.12, 1.12, 1.12) # subtle hover brighten
	else:
		UIManager.hide_item_tooltip()
		modulate = Color.WHITE

static func color_for(id: StringName) -> Color:
	return Color.from_hsv(float(abs(hash(id)) % 360) / 360.0, 0.45, 0.85)
