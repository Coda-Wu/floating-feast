extends VBoxContainer
## Leave Game tab — Return to Title / Quit to Desktop, each with a confirm. (Pause Menu WP-C)

@onready var _return: Button = $ReturnButton
@onready var _quit: Button = $QuitButton

func _ready() -> void:
	_return.focus_mode = Control.FOCUS_NONE
	_quit.focus_mode = Control.FOCUS_NONE
	_return.pressed.connect(_on_return_to_title)
	_quit.pressed.connect(_on_quit)

func _on_return_to_title() -> void:
	UIManager.show_warning_popup(tr("Return to the title screen? Unsaved progress is lost."),
		_confirm_return, tr("Return to Title"), tr("Cancel"))

func _confirm_return() -> void:
	UIManager.close_pause_menu() # unpause + free the menu BEFORE the fade
	GameManager.show_title()

func _on_quit() -> void:
	UIManager.show_warning_popup(tr("Quit to desktop? Unsaved progress is lost."),
		_confirm_quit, tr("Quit"), tr("Cancel"))

func _confirm_quit() -> void:
	get_tree().quit()
