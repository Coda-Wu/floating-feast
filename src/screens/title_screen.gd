extends Control
## Title / main menu — New Game + Quit. No save system yet, so no Continue. (WP-C)

@onready var _new_game: Button = $Center/VBox/NewGameButton
@onready var _quit: Button = $Center/VBox/QuitButton

func _ready() -> void:
	_new_game.focus_mode = Control.FOCUS_NONE
	_quit.focus_mode = Control.FOCUS_NONE
	_new_game.pressed.connect(GameManager.new_game)
	_quit.pressed.connect(func() -> void: get_tree().quit())
