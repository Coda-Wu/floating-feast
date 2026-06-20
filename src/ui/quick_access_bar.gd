extends Control
## Persistent Quick Access hotbar: the primary surface for selecting carried ingredients while
## cooking. Mirrors GameState.inventory (raw + intermediate items) across 10 slots, paginated.
## Clicking a slot emits SignalBus.hotbar_item_selected → an open StationUI stages that item into a
## cook slot. Shown only on the Ship hub + Kitchen (UIManager toggles via phase). Dumb view: shows
## owned counts, holds no cooking logic. (Inventory-UX UX-1)

const SLOTS := 10

@onready var _slots_row: HBoxContainer = $Center/Panel/Margin/HBox/SlotsRow
@onready var _prev: Button = $Center/Panel/Margin/HBox/PrevButton
@onready var _next: Button = $Center/Panel/Margin/HBox/NextButton

var _slot_buttons: Array = []
var _page := 0
var _page_items: Array[StringName] = []

func _ready() -> void:
	_slot_buttons = _slots_row.get_children()
	for i in _slot_buttons.size():
		var btn: Button = _slot_buttons[i]
		btn.focus_mode = Control.FOCUS_NONE # never steal focus from the station's Confirm
		btn.clip_text = true
		btn.pressed.connect(_on_slot_pressed.bind(i))
	_prev.focus_mode = Control.FOCUS_NONE
	_next.focus_mode = Control.FOCUS_NONE
	_prev.pressed.connect(func() -> void:
		_page -= 1
		refresh())
	_next.pressed.connect(func() -> void:
		_page += 1
		refresh())
	refresh()

func set_active(active: bool) -> void:
	visible = active
	if active:
		refresh()

func refresh() -> void:
	var items := _carried_items()
	var page_count := maxi(1, ceili(float(items.size()) / float(SLOTS)))
	_page = clampi(_page, 0, page_count - 1)
	_page_items.clear()
	var start := _page * SLOTS
	for i in _slot_buttons.size():
		var btn: Button = _slot_buttons[i]
		var idx := start + i
		if idx < items.size():
			var id: StringName = items[idx]
			_page_items.append(id)
			btn.text = "%s\n×%d" % [Database.get_display_name(id), GameState.get_item_count(id)]
			btn.disabled = false
		else:
			btn.text = ""
			btn.disabled = true
	_prev.disabled = _page <= 0
	_next.disabled = _page >= page_count - 1

func _on_slot_pressed(i: int) -> void:
	if i < _page_items.size():
		SignalBus.hotbar_item_selected.emit(String(_page_items[i]))

func _carried_items() -> Array[StringName]:
	var ids: Array[StringName] = []
	for k in GameState.inventory.keys():
		if int(GameState.inventory[k]) > 0:
			ids.append(StringName(k))
	ids.sort()
	return ids
