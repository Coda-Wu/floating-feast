class_name PersistentUI extends CanvasLayer
## Survives screen swaps; renders above all gameplay. Hosts the transition overlay
## now; the HUD + popups land here in Step 3. Instanced/owned by UIManager. (§5)

@onready var _transition_overlay: ColorRect = $TransitionOverlay

func get_transition_overlay() -> ColorRect:
	return _transition_overlay