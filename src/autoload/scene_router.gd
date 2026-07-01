extends Node
## Mechanical screen swap + reusable fade: 0.5s fade-to-black -> swap the scene
## under ScreenHost -> 0.5s fade-in. No loading bars. Called by GameManager. (§5, §6)

const FADE_TIME := 0.5

var _screen_host: Node = null # handed over by Main.tscn when it is ready
var _overlay: ColorRect = null # handed over by UIManager (lives in PersistentUI)
var _current_screen: Node = null
var _is_transitioning: bool = false
var pending_spawn: StringName = &""


func register_host(host: Node) -> void:
	_screen_host = host

func register_overlay(overlay: ColorRect) -> void:
	_overlay = overlay

func change_screen(scene: PackedScene, spawn: StringName = &"") -> void:
	if _is_transitioning:
		return
	if _screen_host == null:
		push_error("SceneRouter.change_screen: no ScreenHost registered.")
		return
	_is_transitioning = true
	pending_spawn = spawn
	await _fade_to_black()
	if is_instance_valid(_current_screen):
		_current_screen.queue_free()
	var inst: Node = scene.instantiate()
	_screen_host.add_child(inst)
	_current_screen = inst
	await _fade_from_black()
	_is_transitioning = false

	_is_transitioning = false

func _fade_to_black() -> void:
	if _overlay == null:
		return
	_overlay.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_TIME)
	await tween.finished

func _fade_from_black() -> void:
	if _overlay == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, FADE_TIME)
	await tween.finished
	_overlay.visible = false
