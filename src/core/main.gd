class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step12() # TEMP — delete after confirming


# ==== TEMP — delete after Step 12 verify ====
func _verify_step12() -> void:
	for sid in ["spirit_tomato", "spirit_chicken"]:
		if not GameState.captured_spirits.has(sid):
			GameState.captured_spirits.append(sid)
	print("[verify 12] captured (seeded): ", GameState.captured_spirits)