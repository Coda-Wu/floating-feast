extends Control
## Post-node resolution overlay: shows gathered rewards, then Continue (next node) and/or a
## context-labelled Exit. Dumb view — emits next_pressed / exit_pressed. (§5, §9)

signal next_pressed
signal exit_pressed

@onready var _reward_list: VBoxContainer = $Center/Panel/Margin/VBox/RewardList
@onready var _empty_hint: Label = $Center/Panel/Margin/VBox/EmptyHint
@onready var _message: Label = $Center/Panel/Margin/VBox/Message
@onready var _next_button: Button = $Center/Panel/Margin/VBox/Buttons/NextButton
@onready var _exit_button: Button = $Center/Panel/Margin/VBox/Buttons/ExitButton

func setup(rewards: Dictionary, show_next: bool, message: String, exit_label: String) -> void:
	for child in _reward_list.get_children():
		child.queue_free()
	_empty_hint.visible = rewards.is_empty()
	for item_id in rewards:
		var ing := Database.get_ingredient(item_id)
		var disp := ing.display_name if ing else String(item_id)
		var row := Label.new()
		row.text = "%s ×%d" % [disp, int(rewards[item_id])]
		_reward_list.add_child(row)
	_message.text = message
	_message.visible = not message.is_empty()
	_next_button.visible = show_next
	_exit_button.text = exit_label
	_next_button.pressed.connect(func() -> void: next_pressed.emit())
	_exit_button.pressed.connect(func() -> void: exit_pressed.emit())
