class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step4a() # TEMP — delete after confirming


# ==== TEMP — delete after Step 4a verify ====
func _verify_step4a() -> void:
	SignalBus.day_started.connect(_print_day_islands)
	_print_day_islands(GameState.day) # day 1 already started before this connect

func _print_day_islands(day: int) -> void:
	print("[verify 4a] day %d  seed %d  ->  %d islands" % [day, GameState.day_seed, GameManager.day_islands.size()])
	for i in GameManager.day_islands.size():
		var isl: Island = GameManager.day_islands[i]
		var types: Array = []
		for nd in isl.node_chain:
			types.append(String(nd.type))
		print("    island %d  template=%s  pos=%s  chain=%s" % [i, isl.template_id, isl.position.round(), types])