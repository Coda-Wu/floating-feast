extends Control
## Persistent Quick Access hotbar = ROW 0 of carried inventory (GameState slots 0-9), fixed positions
## (no pagination — backpack rows hold the rest). Renders each slot's token by index; click or number
## key emits hotbar_item_selected for an open StationUI to stage. Red-outline selection + drag arrive
## in later Pause-Menu steps. Shown only on Ship + Kitchen. (Pause Menu Step 2)

const HOTBAR_SLOTS := 10
const ITEM_SLOT := preload("res://scenes/ui/ItemSlot.tscn")

@onready var _slots_row: HBoxContainer = $Center/Panel/Margin/HBox/SlotsRow

var _slot_nodes: Array = []
var _station_open := false

func _ready() -> void:
	for i in HOTBAR_SLOTS:
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(52, 40)
		_slots_row.add_child(slot)
		slot.drag_enabled = true
		slot.set_slot_index(i)

		slot.set_hotkey("0" if i == HOTBAR_SLOTS - 1 else str(i + 1))
		slot.slot_clicked.connect(_on_slot_clicked.bind(i))
		_slot_nodes.append(slot)
	refresh()
	SignalBus.inventory_slots_changed.connect(refresh)
	SignalBus.station_ui_opened.connect(func() -> void: _station_open = true)
	SignalBus.station_ui_closed.connect(func() -> void: _station_open = false)

func set_active(active: bool) -> void:
	visible = active
	if active:
		refresh()

func refresh() -> void:
	for i in _slot_nodes.size():
		var token = GameState.get_slot(i)
		if token != null:
			var id := StringName(token["id"])
			_slot_nodes[i].set_item(id, int(token["count"]), Database.get_display_name(id), true)
		else:
			_slot_nodes[i].set_item(&"", 0, "", false)

func _on_slot_clicked(_item_id: String, i: int) -> void:
	var token = GameState.get_slot(i)
	if token == null:
		return
	var kind = token.get("kind")
	if kind == &"tool":
		var tid := StringName(token["id"])
		SignalBus.tool_selected.emit(&"" if UIManager.active_tool == tid else tid) # toggle
	else:
		if UIManager.active_tool != &"":
			SignalBus.tool_selected.emit(&"") # any non-tool click exits tool mode
		if kind == &"item":
			SignalBus.hotbar_item_selected.emit(String(token["id"]))


func _input(event: InputEvent) -> void:
	if not visible or not _station_open:
		return
	for i in HOTBAR_SLOTS:
		var action := "hotbar_0" if i == HOTBAR_SLOTS - 1 else "hotbar_%d" % (i + 1)
		if event.is_action_pressed(action):
			var token = GameState.get_slot(i)
			if token != null and token.get("kind") == &"item":
				SignalBus.hotbar_item_selected.emit(String(token["id"]))
			get_viewport().set_input_as_handled()
			return