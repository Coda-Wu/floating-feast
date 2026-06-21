extends PanelContainer
## Reusable paged item grid: shows a page of {id, count, label} cells as ItemSlots; clicking a cell
## emits cell_clicked(item_id). Used by both Fridge tabs and both transfer panes. Dumb view. (UX-2 + polish)
class_name ItemGrid

signal cell_clicked(item_id: String)

const COLS := 4
const ROWS := 3
const PAGE := COLS * ROWS
const ITEM_SLOT := preload("res://scenes/ui/ItemSlot.tscn")

var _grid: GridContainer
var _prev: Button
var _next: Button
var _page_label: Label
var _cells: Array = []

var _items: Array = []
var _page := 0
var _clickable := true

func _ready() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	root.add_child(_grid)
	for i in PAGE:
		var cell: ItemSlot = ITEM_SLOT.instantiate()
		cell.custom_minimum_size = Vector2(42, 36) # was (58, 46) — 4 cols now fit the fixed page width
		cell.slot_clicked.connect(func(item_id: String): cell_clicked.emit(item_id))
		_grid.add_child(cell)
		_cells.append(cell)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 8)
	root.add_child(nav)
	_prev = Button.new(); _prev.text = "◀"; _prev.focus_mode = Control.FOCUS_NONE
	_page_label = Label.new(); _page_label.text = "1/1"
	_next = Button.new(); _next.text = "▶"; _next.focus_mode = Control.FOCUS_NONE
	_prev.pressed.connect(func(): _page -= 1; _render())
	_next.pressed.connect(func(): _page += 1; _render())
	nav.add_child(_prev); nav.add_child(_page_label); nav.add_child(_next)

func set_items(items: Array, clickable: bool = true) -> void:
	_items = items
	_clickable = clickable
	_render()

func _render() -> void:
	var page_count := maxi(1, ceili(float(_items.size()) / float(PAGE)))
	_page = clampi(_page, 0, page_count - 1)
	var start := _page * PAGE
	for i in _cells.size():
		var cell: ItemSlot = _cells[i]
		var idx := start + i
		if idx < _items.size():
			var it: Dictionary = _items[idx]
			cell.set_item(StringName(it["id"]), int(it["count"]), String(it["label"]), _clickable)
		else:
			cell.set_item(&"", 0, "", false)
	_prev.disabled = _page <= 0
	_next.disabled = _page >= page_count - 1
	_page_label.text = "%d/%d" % [_page + 1, page_count]