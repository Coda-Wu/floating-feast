extends Node
## Owns PersistentUI (a CanvasLayer that survives screen swaps) and is the ONLY
## bridge between systems and UI scenes. (§5, §6)

var _persistent_ui: CanvasLayer = null

func create_persistent_ui(parent: Node) -> void:
	if _persistent_ui != null:
		return
	var scene: PackedScene = load("res://scenes/ui/PersistentUI.tscn")
	_persistent_ui = scene.instantiate()
	parent.add_child(_persistent_ui)
	SceneRouter.register_overlay(_persistent_ui.get_transition_overlay())

func get_persistent_ui() -> CanvasLayer:
	return _persistent_ui

# --- Day-end resolution overlay ---
func show_day_end_panel(yields: Array, on_confirm: Callable) -> void:
	var panel = load("res://scenes/ui/DayEndPanel.tscn").instantiate() # untyped: setup/confirmed not on Control
	_persistent_ui.add_child(panel) # _ready runs here -> @onready vars resolve
	panel.setup(yields)
	panel.confirmed.connect(func() -> void:
		panel.queue_free()
		on_confirm.call()
	)

# --- Filled in 3b ---
func show_hud() -> void: pass
func hide_hud() -> void: pass

# --- Filled in Step 5 ---
func show_resolution_panel(rewards) -> void: pass
func show_warning_popup(message: String, on_confirm: Callable) -> void: pass