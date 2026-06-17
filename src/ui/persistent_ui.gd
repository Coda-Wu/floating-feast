class_name PersistentUI extends CanvasLayer
## Survives screen swaps; renders above all gameplay. Hosts the HUD and the
## transition overlay. Instanced/owned by UIManager. (§5)

@onready var _hud: Control = $HUD
@onready var _transition_overlay: ColorRect = $TransitionOverlay

func get_hud() -> Control:
	return _hud

func get_transition_overlay() -> ColorRect:
	return _transition_overlay