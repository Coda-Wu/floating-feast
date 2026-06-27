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


var _slot_nodes: Array = []

func _ready() -> void:
	for i in GameState.slot_count():
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(46, 38)
		_grid.add_child(slot)
		if i < COLS: # row 0 mirrors the hotbar number keys (1..9, then 0)
			slot.set_hotkey("0" if i == COLS - 1 else str(i + 1))
		_slot_nodes.append(slot)
	refresh()
	SignalBus.inventory_slots_changed.connect(refresh)
	_populate_profile()


func refresh() -> void:
	for i in _slot_nodes.size():
		var token = GameState.get_slot(i)
		if token != null and token.get("kind") == &"item":
			var id := StringName(token["id"])
			_slot_nodes[i].set_item(id, int(token["count"]), Database.get_display_name(id), true)
		else:
			_slot_nodes[i].set_item(&"", 0, "", false)

func _populate_profile() -> void:
	# Read once: the menu is rebuilt on each open, and nothing mutates coins/rank while paused.
	# (If a later step changes coins/rank with the menu open, subscribe to those signals here.)
	_name_label.text = tr("Name: %s") % GameState.player_name
	_ship_label.text = tr("Ship: %s") % GameState.ship_name
	_coins_label.text = tr("Coins: %d") % GameState.coins
	_rank_label.text = (tr("Rank %d") % GameState.rank) if GameState.rank > 0 else tr("Unranked")
