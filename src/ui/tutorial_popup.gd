extends Control
## Modal first-time tip card. Dumb view: shows a TutorialData's text (+ optional image) and
## emits `dismissed`. Instanced + shown by UIManager on tutorial_triggered. (§2, §6)

signal dismissed

@onready var _image: TextureRect = $Center/Panel/Margin/VBox/Image
@onready var _text: Label = $Center/Panel/Margin/VBox/Text
@onready var _got_it_button: Button = $Center/Panel/Margin/VBox/GotItButton

func setup(data: TutorialData) -> void:
	_text.text = data.text
	# Image stays hidden in gray-box (TutorialData.image is null until the Week-3 art swap).
	if data.image != null:
		_image.texture = data.image
		_image.visible = true
	_got_it_button.pressed.connect(func() -> void: dismissed.emit())
