class_name InteractionDetector extends Area2D
## Tracks overlapping Interactables, picks the nearest, drives its prompt bubble, and on the
## `interact` action emits interaction_triggered(nearest). Reusable; child of TopDownActor.
## Pure nearest-by-distance — perspective-agnostic. (§C.1)

signal interaction_triggered(interactable: Interactable)

var _overlapping: Array[Interactable] = []
var _nearest: Interactable = null
var _prompt_enabled := true

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and not _overlapping.has(area):
		_overlapping.append(area)

func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_overlapping.erase(area)
		if area == _nearest:
			area.set_prompt_shown(false)

func _physics_process(_delta: float) -> void:
	var best: Interactable = null
	var best_d := INF
	for it in _overlapping:
		if not is_instance_valid(it):
			continue
		var d := global_position.distance_squared_to(it.global_position)
		if d < best_d:
			best_d = d
			best = it
	if best != _nearest:
		if _nearest != null and is_instance_valid(_nearest):
			_nearest.set_prompt_shown(false)
		_nearest = best
	if _nearest != null:
		_nearest.set_prompt_shown(_prompt_enabled) # idempotent — no-op when unchanged

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and _nearest != null:
		interaction_triggered.emit(_nearest)
		get_viewport().set_input_as_handled()

func set_prompt_enabled(enabled: bool) -> void:
	_prompt_enabled = enabled
	if _nearest != null and is_instance_valid(_nearest):
		_nearest.set_prompt_shown(enabled)