extends PanelContainer
## Cooking station bar (Prep / Mixing Bowl / Oven): station name + 4 ingredient slots + Confirm.
## Click an inventory item → reserve it into the next free slot; click a filled slot → release it.
## Slots RESERVE (counts shown are available = owned − reserved); only Confirm consumes, so closing
## without confirming costs nothing. Confirm is a Day-9 stub (logs inputs); Day 10 routes it to the
## cooking simulation. Dumb view: owns its widgets, not the cooking rules. (§C.2)

signal close_requested

const SLOT_COUNT := 4

@onready var _title: Label = $Margin/VBox/TitleLabel
@onready var _slot_row: HBoxContainer = $Margin/VBox/SlotRow
@onready var _confirm_button: Button = $Margin/VBox/ButtonRow/ConfirmButton
@onready var _close_button: Button = $Margin/VBox/ButtonRow/CloseButton
@onready var _inventory_list: VBoxContainer = $Margin/VBox/InvScroll/InventoryList
@onready var _feedback: Label = $Margin/VBox/FeedbackLabel

var _station_id: StringName
var _slots: Array[StringName] = []
var _slot_buttons: Array[Button] = []

func setup(station_id: StringName, display_name: String) -> void:
	_station_id = station_id
	_title.text = display_name
	_slots.resize(SLOT_COUNT)
	_slots.fill(&"")
	_slot_buttons.assign(_slot_row.get_children())
	for i in _slot_buttons.size():
		_slot_buttons[i].focus_mode = Control.FOCUS_NONE
		_slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i))
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_confirm_button.grab_focus() # so ui_accept (Space/Enter) confirms
	_refresh_slots()
	_refresh_inventory()

# --- slotting (reserve / release) ---
func _on_inventory_pressed(item_id: StringName) -> void:
	if _available(item_id) <= 0:
		return
	var free := _slots.find(&"")
	if free == -1:
		return # all slots full
	_slots[free] = item_id
	_refresh_slots()
	_refresh_inventory()

func _on_slot_pressed(i: int) -> void:
	if _slots[i] == &"":
		return
	_slots[i] = &""
	_refresh_slots()
	_refresh_inventory()

func _available(item_id: StringName) -> int:
	return GameState.get_item_count(item_id) - _reserved(item_id)

func _reserved(item_id: StringName) -> int:
	var n := 0
	for s in _slots:
		if s == item_id:
			n += 1
	return n

# --- confirm (consume reserved inputs → produce, via the matcher) ---
func _on_confirm_pressed() -> void:
	var slotted: Array[StringName] = []
	for s in _slots:
		if s != &"":
			slotted.append(s)
	if slotted.is_empty():
		_set_feedback("Add some ingredients first.")
		return

	if _station_id == &"prep": # Prep = 1:1 batch transform, not recipe-matching
		_confirm_prep(slotted)
		return

	var result := Cooking.find_match(_station_id, slotted)
	if result.is_empty():
		_consume(slotted) # mismatch still costs the ingredients
		GameState.add_item(&"dubious_food", 1)
		AudioManager.play_sfx(&"cook_fail")
		_set_feedback("That didn't come together... Dubious Food.")
	else:
		var recipe: StationRecipe = result["recipe"]
		_consume(slotted) # match leaves only enhancers → consume all slotted
		if recipe.is_terminal:
			var breakdown := Cooking.compute_tier(result["enhancers"].size())
			var tier := int(breakdown["tier"])
			var recipe_id := _terminal_recipe_id(recipe) # dish id == output_item_id
			GameState.add_dish(recipe_id, tier, 1) # → the tiered dish store
			var is_new := GameState.mark_recipe_known(recipe_id) # reverse-unlock (guarded: false if known)
			SignalBus.dish_cooked.emit(String(recipe_id), tier)
			if is_new:
				SignalBus.recipe_discovered.emit(String(recipe_id))
			AudioManager.play_sfx(&"recipe_new" if is_new else &"cook_success")
			_set_feedback("You cooked %s!" % Database.get_display_name(recipe_id))
			var info := breakdown.duplicate()
			info["recipe_id"] = recipe_id
			info["is_new"] = is_new
			UIManager.show_cook_result(info)
		else:
			GameState.add_item(recipe.output_item_id, 1) # working item → inventory; chain advances
			AudioManager.play_sfx(&"cook_step")
			_set_feedback("Made %s." % Database.get_display_name(recipe.output_item_id))

	_slots.fill(&"")
	_refresh_slots()
	_refresh_inventory() # the new output now shows up here

func _terminal_recipe_id(recipe: StationRecipe) -> StringName:
	return recipe.output_item_id

func _consume(items: Array[StringName]) -> void:
	for item_id in items:
		GameState.remove_item(item_id, 1)

func _confirm_prep(slotted: Array[StringName]) -> void:
	# Each item that has a prep transform is consumed → its mid-stage product (1:1). Items with no
	# prep transform are left untouched. Never produces Dubious Food.
	var produced := {} # output_id -> count
	var skipped := 0
	for item_id in slotted:
		var out := Cooking.get_prep_output(item_id)
		if out == &"":
			skipped += 1
			continue
		GameState.remove_item(item_id, 1)
		GameState.add_item(out, 1)
		produced[out] = int(produced.get(out, 0)) + 1
	if produced.is_empty():
		_set_feedback("Nothing here can be prepped.")
	else:
		AudioManager.play_sfx(&"cook_step")
		var parts: Array = []
		for out_id in produced:
			parts.append("%d ×%s" % [produced[out_id], Database.get_display_name(out_id)])
		var msg := "Prepped " + ", ".join(parts)
		if skipped > 0:
			msg += "  (%d couldn't be prepped)" % skipped
		_set_feedback(msg)
	_slots.fill(&"")
	_refresh_slots()
	_refresh_inventory()

func _set_feedback(text: String) -> void:
	_feedback.text = text

# --- refresh ---
func _refresh_slots() -> void:
	for i in _slot_buttons.size():
		var id := _slots[i]
		if id == &"":
			_slot_buttons[i].text = "+"
		else:
			var ing := Database.get_ingredient(id)
			_slot_buttons[i].text = ing.display_name if ing else String(id)

func _refresh_inventory() -> void:
	for c in _inventory_list.get_children():
		c.queue_free()
	var ids := GameState.inventory.keys()
	ids.sort()
	var any := false
	for item_id in ids:
		var ing := Database.get_ingredient(item_id)
		if ing == null:
			continue
		any = true
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "%s  ×%d" % [ing.display_name, _available(item_id)]
		btn.disabled = _available(item_id) <= 0
		btn.pressed.connect(_on_inventory_pressed.bind(item_id))
		_inventory_list.add_child(btn)
	if not any:
		var lbl := Label.new()
		lbl.text = "(No ingredients)"
		_inventory_list.add_child(lbl)