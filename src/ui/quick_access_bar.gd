extends Control
## Persistent Quick Access hotbar: the primary surface for selecting carried ingredients while
## cooking. Mirrors GameState.inventory across 10 ItemSlots, paginated, each with a fixed hotkey
## indicator (1-9, then 0). Clicking a slot emits SignalBus.hotbar_item_selected → an open StationUI
## stages that item. Shown only on Ship + Kitchen (UIManager toggles via phase). (UX-1 + polish)

const SLOTS := 10
const ITEM_SLOT := preload("res://scenes/ui/ItemSlot.tscn")

@onready var _slots_row: HBoxContainer = $Center/Panel/Margin/HBox/SlotsRow
@onready var _prev: Button = $Center/Panel/Margin/HBox/PrevButton
@onready var _next: Button = $Center/Panel/Margin/HBox/NextButton

var _slot_nodes: Array = []
var _page := 0
var _station_open := false

func _ready() -> void:
	for i in SLOTS:
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(52, 40)
		_slots_row.add_child(slot)
		slot.set_hotkey("0" if i == SLOTS - 1 else str(i + 1)) # 1-9, then 0
		slot.slot_clicked.connect(_on_slot_clicked)
		_slot_nodes.append(slot)
	_prev.focus_mode = Control.FOCUS_NONE
	_next.focus_mode = Control.FOCUS_NONE
	_prev.pressed.connect(func() -> void:
		_page -= 1
		refresh())
	_next.pressed.connect(func() -> void:
		_page += 1
		refresh())
	refresh()
	SignalBus.station_ui_opened.connect(func() -> void: _station_open = true)
	SignalBus.station_ui_closed.connect(func() -> void: _station_open = false)

func set_active(active: bool) -> void:
	visible = active
	if active:
		refresh()

func refresh() -> void:
	var items := _carried_items()
	var page_count := maxi(1, ceili(float(items.size()) / float(SLOTS)))
	_page = clampi(_page, 0, page_count - 1)
	var start := _page * SLOTS
	for i in _slot_nodes.size():
		var slot: ItemSlot = _slot_nodes[i]
		var idx := start + i
		if idx < items.size():
			var id: StringName = items[idx]
			slot.set_item(id, GameState.get_item_count(id), Database.get_display_name(id), true)
		else:
			slot.set_item(&"", 0, "", false) # empty slot keeps its hotkey number, hides swatch/count
	_prev.disabled = _page <= 0
	_next.disabled = _page >= page_count - 1

func _on_slot_clicked(item_id: String) -> void:
	SignalBus.hotbar_item_selected.emit(item_id)

func _carried_items() -> Array[StringName]:
	var ids: Array[StringName] = []
	for k in GameState.inventory.keys():
		if int(GameState.inventory[k]) > 0:
			ids.append(StringName(k))
	ids.sort()
	return ids

func _input(event: InputEvent) -> void:
	# Number-key hotbar selection — only when the bar is visible AND a station is consuming, so stray
	# digits elsewhere do nothing. Routes through the same signal a click emits (staging/deduction/
	# refund identical). (UX-3)
	if not visible or not _station_open:
		return
	for i in SLOTS:
		var action := "hotbar_0" if i == SLOTS - 1 else "hotbar_%d" % (i + 1)
		if event.is_action_pressed(action):
			_select_slot(i)
			get_viewport().set_input_as_handled()
			return

func _select_slot(i: int) -> void:
	# i is the on-screen slot index (0-9); resolve to the item on the current page, mirroring a click.
	var items := _carried_items()
	var idx := _page * SLOTS + i
	if idx < items.size():
		SignalBus.hotbar_item_selected.emit(String(items[idx]))
