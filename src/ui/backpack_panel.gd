extends VBoxContainer
## Backpack tab content for the Pause Menu. The carried inventory as a 10-col grid of ItemSlots
## bound to GameState slots by index (row 0 = hotbar slots 0-9, mirroring the Quick Access bar's
## number keys; rows 1+ = backpack rows). Display-only here — reads the slot array positionally and
## repaints on inventory_slots_changed. Selection/number-keys = Step 4, drag = Step 6, profile = 3c.

const ITEM_SLOT := preload("res://scenes/ui/ItemSlot.tscn")
const COLS := 10

@onready var _grid: GridContainer = $Grid
@onready var _name_label: Label = $Profile/Fields/NameLabel
@onready var _ship_label: Label = $Profile/Fields/ShipLabel
@onready var _coins_label: Label = $Profile/Fields/CoinsLabel
@onready var _rank_label: Label = $Profile/Fields/RankLabel
@onready var _sort_button: Button = $Toolbar/SortButton
@onready var _trash_button: Button = $Toolbar/TrashButton


var _slot_nodes: Array = []
var _selected_index := -1 # menu-local selection; -1 = none (Step 4)


func _ready() -> void:
	for i in GameState.slot_count():
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(46, 38)
		_grid.add_child(slot)
		slot.drag_enabled = true
		slot.click_on_release = true # release-fire so a press-drag doesn't also select
		slot.set_slot_index(i)
		slot.slot_dropped.connect(_on_slot_dropped)
		
		if i < COLS: # row 0 mirrors the hotbar number keys (1..9, then 0)
			slot.set_hotkey("0" if i == COLS - 1 else str(i + 1))
		slot.slot_clicked.connect(_on_slot_clicked.bind(i)) # all slots are selectable
		_slot_nodes.append(slot)

	_sort_button.focus_mode = Control.FOCUS_NONE
	_sort_button.pressed.connect(_on_sort_pressed)
	_trash_button.focus_mode = Control.FOCUS_NONE
	_trash_button.disabled = true # enabled only when a slot is selected (5c)
	_trash_button.pressed.connect(_on_trash_pressed)


	refresh()
	SignalBus.inventory_slots_changed.connect(refresh)
	_populate_profile()


func refresh() -> void:
	for i in _slot_nodes.size():
		var token = GameState.get_slot(i)
		if token != null:
			var id := StringName(token["id"])
			_slot_nodes[i].set_item(id, int(token["count"]), Database.get_display_name(id), true)
		else:
			_slot_nodes[i].set_item(&"", 0, "", false)


func _on_slot_clicked(_item_id: String, index: int) -> void:
	_select(-1 if index == _selected_index else index) # click the selected slot again to clear

func _select(index: int) -> void:
	if index == _selected_index:
		return
	if _selected_index >= 0:
		_slot_nodes[_selected_index].set_selected(false)
	_selected_index = index
	if _selected_index >= 0:
		_slot_nodes[_selected_index].set_selected(true)
	_trash_button.disabled = not _can_trash(_selected_index)


func _unhandled_input(event: InputEvent) -> void:
	if not visible: # only the active Backpack tab reacts to number keys
		return
	for i in COLS:
		var action := "hotbar_0" if i == COLS - 1 else "hotbar_%d" % (i + 1)
		if event.is_action_pressed(action):
			_select_from_key(i)
			get_viewport().set_input_as_handled()
			return

func _select_from_key(index: int) -> void:
	var token = GameState.get_slot(index)
	if token == null or token.get("kind") != &"item": # filled slots only, like click
		return
	_select(-1 if index == _selected_index else index)


func _on_sort_pressed() -> void:
	_select(-1) # positions are about to change — drop the highlight
	GameState.sort_inventory()


func _on_trash_pressed() -> void:
	if not _can_trash(_selected_index):
		return
	var token = GameState.get_slot(_selected_index)
	var index := _selected_index
	var id := StringName(token["id"])
	var msg := tr("Throw away %d × %s?") % [int(token["count"]), tr(Database.get_display_name(id))]
	UIManager.show_warning_popup(msg, _confirm_trash.bind(index), tr("Throw Away"), tr("Keep"))


func _can_trash(index: int) -> bool:
	if index < 0:
		return false
	var token = GameState.get_slot(index)
	return token != null and token.get("kind") != &"tool" # tools are protected (GARDEN.md)


func _confirm_trash(index: int) -> void:
	GameState.clear_slot(index)
	_select(-1)


func _on_slot_dropped(from_index: int, to_index: int) -> void:
	_select(-1) # positions change — drop the highlight
	GameState.move_slot(from_index, to_index)


func _populate_profile() -> void:
	# Read once: the menu is rebuilt on each open, and nothing mutates coins/rank while paused.
	# (If a later step changes coins/rank with the menu open, subscribe to those signals here.)
	_name_label.text = tr("Name: %s") % GameState.player_name
	_ship_label.text = tr("Ship: %s") % GameState.ship_name
	_coins_label.text = tr("Coins: %d") % GameState.coins
	_rank_label.text = (tr("Rank %d") % GameState.rank) if GameState.rank > 0 else tr("Unranked")
