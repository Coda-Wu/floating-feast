extends Control
## Day-end resolution overlay: lists overnight yields (empty stub in Week 1) then
## confirms. Instanced + shown by UIManager; emits `confirmed` on Sleep. (§5, §6)

signal confirmed

@onready var _yield_list: VBoxContainer = $Center/Panel/Margin/VBox/YieldList
@onready var _empty_hint: Label = $Center/Panel/Margin/VBox/EmptyHint
@onready var _confirm_button: Button = $Center/Panel/Margin/VBox/ConfirmButton

func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm)

func setup(yields: Array) -> void:
	# yields: Array of { "item_id": StringName, "count": int }. Empty in Week 1;
	# the garden fills this in Week 2 with no change to this panel.
	for child in _yield_list.get_children():
		child.queue_free()
	_empty_hint.visible = yields.is_empty()
	for y in yields:
		var ing := Database.get_ingredient(y["item_id"])
		var label_text := ing.display_name if ing else String(y["item_id"])
		var row := Label.new()
		row.text = "%s ×%d" % [label_text, int(y["count"])]
		_yield_list.add_child(row)

func _on_confirm() -> void:
	confirmed.emit()
