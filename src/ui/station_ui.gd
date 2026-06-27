extends PanelContainer
## Cooking station bar (Prep / Mixing Bowl / Oven): station name + 4 ItemSlots + Confirm. Ingredients
## are selected from the Quick Access hotbar (SignalBus.hotbar_item_selected). Slotting an item DEDUCTS
## it from inventory immediately (real deduction → the hotbar updates live); returning a slot or
## closing without cooking REFUNDS it. _slots always holds exactly the deducted-but-unfinalized items,
## so _exit_tree() refunds the remainder no matter how we're closed. Prep = 1:1 batch transform; other
## stations recipe-match (→ dish or Dubious Food). Dumb view. (§C.2 + Inventory-UX)

signal close_requested

const SLOT_COUNT := 4
const ITEM_SLOT := preload("res://scenes/ui/ItemSlot.tscn")

@onready var _title: Label = $Margin/VBox/TitleLabel
@onready var _slot_row: HBoxContainer = $Margin/VBox/SlotRow
@onready var _confirm_button: Button = $Margin/VBox/ButtonRow/ConfirmButton
@onready var _close_button: Button = $Margin/VBox/ButtonRow/CloseButton
@onready var _feedback: Label = $Margin/VBox/FeedbackLabel

var _station_id: StringName
var _slots: Array[StringName] = []
var _slot_nodes: Array = []

func setup(station_id: StringName, display_name: String) -> void:
	_station_id = station_id
	_title.text = tr(display_name)
	_slots.resize(SLOT_COUNT)
	_slots.fill(&"")
	for i in SLOT_COUNT:
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(50, 40)
		_slot_row.add_child(slot)
		slot.slot_clicked.connect(_on_slot_returned.bind(i)) # clicking a filled slot returns it
		_slot_nodes.append(slot)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_confirm_button.grab_focus() # ui_accept (Space/Enter) confirms
	SignalBus.hotbar_item_selected.connect(_on_hotbar_item_selected)
	SignalBus.station_ui_opened.emit() # ADD — tells the hotbar keys are live
	_refresh_slots()

# --- slotting: deduct immediately on fill, refund on return ---
func _on_hotbar_item_selected(item_id: String) -> void:
	var id := StringName(item_id)
	if Database.get_ingredient(id) == null:
		return
	var free := _slots.find(&"")
	if free == -1:
		_set_feedback(tr("Slots are full."))
		return
	if GameState.get_item_count(id) <= 0:
		_set_feedback(tr("No more %s to add.") % tr(Database.get_display_name(id)))
		return
	GameState.remove_item(id, 1) # real deduction → inventory_changed → hotbar drops instantly
	_slots[free] = id
	_refresh_slots()

func _on_slot_returned(_item_id: String, i: int) -> void:
	if _slots[i] == &"":
		return
	GameState.add_item(_slots[i], 1) # refund → hotbar climbs instantly
	_slots[i] = &""
	_refresh_slots()

# --- confirm (items are ALREADY deducted; do NOT consume again) ---
func _on_confirm_pressed() -> void:
	var slotted: Array[StringName] = []
	for s in _slots:
		if s != &"":
			slotted.append(s)
	if slotted.is_empty():
		_set_feedback(tr("Add some ingredients first."))
		return

	if _station_id == &"prep":
		_confirm_prep(slotted)
		return

	var result := Cooking.find_match(_station_id, slotted)
	if result.is_empty():
		GameState.add_item(&"dubious_food", 1) # slotted items were consumed into this
		AudioManager.play_sfx(&"cook_fail")
		_set_feedback(tr("That didn't come together... Dubious Food."))
	else:
		var recipe: StationRecipe = result["recipe"]
		if recipe.is_terminal:
			var seasoning := Cooking.evaluate_seasoning(recipe, result["enhancers"])
			for spice_id in seasoning["set_aside"]:
				GameState.add_item(spice_id, 1) # return spices that didn't suit the dish (already deducted at slot time)
			var tier := int(seasoning["tier"])
			var recipe_id := _terminal_recipe_id(recipe)
			GameState.add_dish(recipe_id, tier, 1)
			var is_new := GameState.mark_recipe_known(recipe_id)
			SignalBus.dish_cooked.emit(String(recipe_id), tier)
			if is_new:
				SignalBus.recipe_discovered.emit(String(recipe_id))
			AudioManager.play_sfx(&"recipe_new" if is_new else &"cook_success")
			_set_feedback(tr("You cooked %s!") % tr(Database.get_display_name(recipe_id)))
			UIManager.show_cook_result({
				"recipe_id": recipe_id, "tier": tier, "is_new": is_new,
				"base_stars": Cooking.BASE_TIER,
				"counted": seasoning["counted"], "set_aside": seasoning["set_aside"], "cap": seasoning["cap"],
			})
		else:
			GameState.add_item(recipe.output_item_id, 1)
			AudioManager.play_sfx(&"cook_step")
			_set_feedback(tr("Made %s.") % tr(Database.get_display_name(recipe.output_item_id)))

	_slots.fill(&"") # finalized — nothing left to refund
	_refresh_slots()

func _confirm_prep(slotted: Array[StringName]) -> void:
	# Raw items were already deducted at slot time: transform consumes them; un-preppable items are
	# refunded (locked: items with no prep transform are left unconsumed).
	var produced := {}
	var skipped := 0
	for item_id in slotted:
		var out := Cooking.get_prep_output(item_id)
		if out == &"":
			GameState.add_item(item_id, 1) # refund — couldn't be prepped
			skipped += 1
			continue
		GameState.add_item(out, 1) # produce the mid-stage product
		produced[out] = int(produced.get(out, 0)) + 1
	if produced.is_empty():
		_set_feedback(tr("Nothing here can be prepped."))
	else:
		AudioManager.play_sfx(&"cook_step")
		var parts: Array = []
		for out_id in produced:
			parts.append("%d ×%s" % [produced[out_id], tr(Database.get_display_name(out_id))])
		var msg := tr("Prepped ") + ", ".join(parts)
		if skipped > 0:
			msg += tr("  (%d couldn't be prepped)") % skipped
		_set_feedback(msg)
	_slots.fill(&"")
	_refresh_slots()

func _set_feedback(text: String) -> void:
	_feedback.text = text

func _terminal_recipe_id(recipe: StationRecipe) -> StringName:
	return recipe.output_item_id

func _refresh_slots() -> void:
	for i in _slot_nodes.size():
		var id := _slots[i]
		if id == &"":
			_slot_nodes[i].set_item(&"", 0, "", false) # empty cell
		else:
			_slot_nodes[i].set_item(id, 1, tr(Database.get_display_name(id)), true) # count 1 → no number

# --- refund catch-all: fires on Close, E-toggle, AND Leave-Kitchen-mid-cook ---
func _refund_all_slots() -> void:
	for i in _slots.size():
		if _slots[i] != &"":
			GameState.add_item(_slots[i], 1)
			_slots[i] = &""

func _exit_tree() -> void:
	_refund_all_slots()
	SignalBus.station_ui_closed.emit() # ADD