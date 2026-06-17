extends Control
## Voluntary mid-chain exit confirmation. Dumb view — emits confirmed / cancelled.
## Shown layered over the ResolutionPanel; Cancel returns to it, Confirm leaves. (§1, §5)

signal confirmed
signal cancelled

@onready var _message: Label = $Center/Panel/Margin/VBox/Message
@onready var _confirm_button: Button = $Center/Panel/Margin/VBox/Buttons/ConfirmButton
@onready var _cancel_button: Button = $Center/Panel/Margin/VBox/Buttons/CancelButton

func setup(message: String) -> void:
	_message.text = message
	_confirm_button.pressed.connect(func() -> void: confirmed.emit())
	_cancel_button.pressed.connect(func() -> void: cancelled.emit())
