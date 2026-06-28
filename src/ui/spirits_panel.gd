extends HBoxContainer
## Spirits tab — read-only compendium of befriended spirits (the persistent captured_spirits ledger).
## Grid of ItemSlots on the left; selecting one shows its detail on the right. (GARDEN.md §7 / G7)

const ITEM_SLOT := preload("res://scenes/ui/ItemSlot.tscn")

@onready var _grid: GridContainer = $Grid
@onready var _name_label: Label = $Detail/NameLabel
@onready var _liked_label: Label = $Detail/LikedLabel
@onready var _island_label: Label = $Detail/IslandLabel
@onready var _production_label: Label = $Detail/ProductionLabel
@onready var _yield_label: Label = $Detail/YieldLabel


var _slot_nodes: Array = []
var _spirit_ids: Array = []
var _selected := -1

func _ready() -> void:
	_spirit_ids = GameState.captured_spirits.duplicate()
	for i in _spirit_ids.size():
		var sid := StringName(_spirit_ids[i])
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(46, 38)
		_grid.add_child(slot)
		slot.set_item(sid, 1, Database.get_display_name(sid), true)
		slot.slot_clicked.connect(_on_slot_clicked.bind(i))
		_slot_nodes.append(slot)
	if _spirit_ids.is_empty():
		_name_label.text = tr("No spirits discovered yet.")
	else:
		_select(0)

func _on_slot_clicked(_item_id: String, i: int) -> void:
	_select(i)

func _select(i: int) -> void:
	if _selected >= 0 and _selected < _slot_nodes.size():
		_slot_nodes[_selected].set_selected(false)
	_selected = i
	_slot_nodes[i].set_selected(true)
	_show_detail(StringName(_spirit_ids[i]))

func _show_detail(spirit_id: StringName) -> void:
	_name_label.text = Database.get_display_name(spirit_id)
	var s := Database.get_spirit(spirit_id)
	if s == null:
		return
	_liked_label.text = tr("Liked Food: %s") % (Database.get_display_name(s.preferred_food) if s.preferred_food != &"" else "—")
	_island_label.text = tr("Native Island: %s") % _island_name(s.native_island)
	var prod := tr("every day") if s.yield_interval_days <= 1 else (tr("every %d days") % s.yield_interval_days)
	_production_label.text = tr("Production: %s") % prod
	if s.produces != &"" and s.yield_per_night > 0:
		_yield_label.text = tr("Yield: %s") % ("%s ×%d" % [Database.get_display_name(s.produces), s.yield_per_night])
	else:
		_yield_label.text = tr("Yield: %s") % "—"

func _island_name(island_id: StringName) -> String:
	if island_id == &"":
		return "—"
	var wi := Database.get_world_island(island_id)
	return tr(wi.display_name) if wi != null else String(island_id).capitalize()
