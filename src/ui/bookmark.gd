class_name Bookmark extends Panel
## Reusable book bookmark (top tab or side category). Colored swatch + cursor tooltip (no permanent
## label), selected highlight. Emits selected(id). (Parts 1-2)

signal selected(id: String)

@onready var _swatch: ColorRect = $Swatch

var _id: StringName = &""
var _label := ""
var _hovered := false
var _is_selected := false

func _ready() -> void:
	mouse_entered.connect(func() -> void:
		_hovered = true; UIManager.show_item_tooltip(_label); _restyle())
	mouse_exited.connect(func() -> void:
		_hovered = false; UIManager.hide_item_tooltip(); _restyle())
	_restyle()

func setup(id: StringName, label: String, color: Color) -> void:
	_id = id
	_label = label
	_swatch.color = color

func set_selected(v: bool) -> void:
	_is_selected = v
	_restyle()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(String(_id))
		accept_event()

func _restyle() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.30, 0.22, 0.14) if _is_selected else Color(0.20, 0.16, 0.12)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(2 if _is_selected else 1)
	sb.border_color = Color(0.95, 0.85, 0.55) if _is_selected else Color(0.45, 0.38, 0.30)
	add_theme_stylebox_override("panel", sb)
	modulate = Color(1.1, 1.1, 1.1) if _hovered else Color.WHITE