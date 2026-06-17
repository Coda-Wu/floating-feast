class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step6a() # TEMP — delete after confirming


# ==== TEMP — delete after Step 6a verify ====
func _verify_step6a() -> void:
	print("[verify 6a] seen before: ", GameState.seen_tutorials.has("spirit_encounter"))
	TutorialManager.try_show("spirit_encounter") # should show the popup + set the flag
	TutorialManager.try_show("spirit_encounter") # flag now set -> should show NOTHING more
	print("[verify 6a] seen after: ", GameState.seen_tutorials.has("spirit_encounter"))
