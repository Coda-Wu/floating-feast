extends Control
## Generic notice modal: title + message + OK. Reusable one-off announcement (recipe gift +
## substitute reward now; commission / Fair results later). Dumb view; emits dismissed.

signal dismissed

@onready var _title: Label = $Center/Panel/Margin/VBox/Title
@onready var _message: Label = $Center/Panel/Margin/VBox/Message
@onready var _ok_button: Button = $Center/Panel/Margin/VBox/OkButton

func setup(title: String, message: String) -> void:
	_title.text = title
	_message.text = message
	_ok_button.pressed.connect(func() -> void: dismissed.emit())
	_ok_button.grab_focus()