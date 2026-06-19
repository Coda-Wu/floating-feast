extends Control
## Garden: assign tamed spirits to pots for overnight crop yield. Slot-based for M1 (2D-pot drag
## deferred to M2). Assigning places a captured-but-unplaced spirit; removing PERMANENTLY consumes
## it. Interaction panel — orchestrates via GameState helpers; emits close_requested. (§F)

signal close_requested

@onready var _body: VBoxContainer = $Center/Panel/Margin/VBox/Body
@onready var _close_button: Button = $Center/Panel/Margin/VBox/CloseButton

var _assigning_slot := -1 # -1 = showing pots; >=0 = showing the picker for that pot

func setup() -> void:
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	TutorialManager.try_show("garden")
	_rebuild()

func _rebuild() -> void:
	for c in _body.get_children():
		c.queue_free()
	if _assigning_slot >= 0:
		_build_picker()
	else:
		_build_slots()

func _build_slots() -> void:
	for i in GameState.garden_slots.size():
		_body.add_child(_slot_row(i, GameState.garden_slots[i]))

func _slot_row(i: int, spirit_id) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var btn := Button.new()
	if spirit_id == null:
		label.text = "Pot %d: (empty)" % (i + 1)
		btn.text = "Assign"
		btn.disabled = _available_spirits().is_empty()
		btn.pressed.connect(func() -> void:
			_assigning_slot = i
			_rebuild())
	else:
		var spirit := Database.get_spirit(StringName(spirit_id))
		label.text = "Pot %d: %s  (%s)" % [(i + 1), (spirit.display_name if spirit else String(spirit_id)), _produces_text(spirit)]
		btn.text = "Remove"
		btn.pressed.connect(_confirm_remove.bind(i))
	row.add_child(btn)
	return row

func _build_picker() -> void:
	var header := Label.new()
	header.text = "Choose a spirit for Pot %d:" % (_assigning_slot + 1)
	_body.add_child(header)
	for spirit_id in _available_spirits():
		var spirit := Database.get_spirit(StringName(spirit_id))
		var btn := Button.new()
		btn.text = "%s  (→ %s)" % [(spirit.display_name if spirit else String(spirit_id)), _produces_text(spirit)]
		btn.pressed.connect(func() -> void:
			GameState.assign_spirit_to_garden(spirit_id, _assigning_slot)
			_assigning_slot = -1
			_rebuild())
		_body.add_child(btn)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(func() -> void:
		_assigning_slot = -1
		_rebuild())
	_body.add_child(cancel)

func _confirm_remove(slot: int) -> void:
	var spirit := Database.get_spirit(StringName(GameState.garden_slots[slot]))
	var name_txt := spirit.display_name if spirit else String(GameState.garden_slots[slot])
	UIManager.show_warning_popup(
		"Remove %s from the garden? It will be gone for good." % name_txt,
		func() -> void:
			GameState.remove_spirit_from_garden(slot)
			_rebuild(),
		"Remove", "Keep")

func _available_spirits() -> Array:
	var placed := {}
	for s in GameState.garden_slots:
		if s != null:
			placed[s] = true
	var out: Array = []
	for sid in GameState.captured_spirits:
		if not placed.has(sid):
			out.append(sid)
	return out

func _produces_text(spirit) -> String:
	if spirit and spirit.produces != &"" and spirit.yield_per_night > 0:
		return "%s ×%d/night" % [Database.get_display_name(spirit.produces), spirit.yield_per_night]
	return "no yield"