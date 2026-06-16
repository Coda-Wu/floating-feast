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
	# Hand the transition overlay to SceneRouter, which owns the fade logic.
	SceneRouter.register_overlay(_persistent_ui.get_transition_overlay())

func get_persistent_ui() -> CanvasLayer:
	return _persistent_ui

# --- Filled in Step 3 (HUD + panels live inside PersistentUI) ---
func show_hud() -> void: pass
func hide_hud() -> void: pass
func show_resolution_panel(rewards) -> void: pass
func show_day_end_panel(yields) -> void: pass
func show_warning_popup(message: String, on_confirm: Callable) -> void: pass