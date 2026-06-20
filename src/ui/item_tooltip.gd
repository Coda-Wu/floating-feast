extends PanelContainer
## Cursor-following item-name tooltip. Shown by UIManager when a slot is hovered; sits at the
## top-right of the cursor and follows it. (Inventory-UX polish)

const OFFSET := Vector2(13, 5) # x: right of the cursor; y: gap above it

@onready var _label: Label = $Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.13, 0.94)
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.55, 0.55, 0.62)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	add_theme_stylebox_override("panel", sb)
	visible = false

func show_text(text: String) -> void:
	_label.text = text
	visible = true
	_reposition()

func hide_tip() -> void:
	visible = false

func _process(_delta: float) -> void:
	if visible:
		_reposition()

func _reposition() -> void:
	reset_size()
	var mouse := get_viewport().get_mouse_position()
	var vp := get_viewport_rect().size
	var pos := Vector2(mouse.x + OFFSET.x, mouse.y - size.y - OFFSET.y) # top-right of the cursor
	pos.x = clampf(pos.x, 2.0, vp.x - size.x - 2.0)
	pos.y = clampf(pos.y, 2.0, vp.y - size.y - 2.0)
	position = pos