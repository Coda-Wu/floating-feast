class_name ItemSlot extends Panel
## Reusable inventory slot: a center sprite area (gray-box swatch — the Week-3 swap target), a quantity
## number bottom-right (Stardew-style, hidden at 1), an optional hotkey indicator bottom-left, and a
## hover tooltip (the item name follows the cursor, shown via UIManager). Used by the Quick Access
## hotbar and every Fridge grid. Dumb view; emits slot_clicked with its item id. (Inventory-UX polish)

signal slot_clicked(item_id: String)

@onready var _swatch: ColorRect = $Swatch
@onready var _count: Label = $CountLabel
@onready var _hotkey: Label = $HotkeyLabel

var _item_id: StringName = &""
var _item_name: String = ""
var _clickable: bool = true
var _hovered: bool = false

func _ready() -> void:
	var sb := StyleBoxFlat.new() # gray-box cell background; real art is a Week-3 swap
	sb.bg_color = Color(0.20, 0.20, 0.24, 0.85)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.42, 0.42, 0.48)
	add_theme_stylebox_override("panel", sb)
	for lbl in [_count, _hotkey]: # corner labels: small, white, dark outline for legibility
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		lbl.add_theme_constant_override("outline_size", 4)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_item(item_id: StringName, count: int, item_name: String, clickable: bool = true) -> void:
	_item_id = item_id
	_item_name = item_name
	_clickable = clickable
	var occupied := item_id != &""
	_swatch.visible = occupied
	if occupied:
		_swatch.color = _color_for(item_id)
	_count.visible = occupied and count > 1 # Stardew: no number on a stack of 1
	_count.text = str(count)
	if _hovered:
		_update_hover() # contents changed under the cursor → refresh tooltip

func set_hotkey(text: String) -> void:
	_hotkey.text = text
	_hotkey.visible = text != ""

func _gui_input(event: InputEvent) -> void:
	if not _clickable or _item_id == &"":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		slot_clicked.emit(String(_item_id))
		accept_event()

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

func _color_for(id: StringName) -> Color:
	return Color.from_hsv(float(abs(hash(id)) % 360) / 360.0, 0.45, 0.85)