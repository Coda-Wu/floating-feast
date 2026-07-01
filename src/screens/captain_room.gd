extends Node2D
## The walkable Captain's Room. Steering Wheel → Ocean Map; Bed → end day (Phase 4); Sail Door →
## daytime exploration on the current island (Phase 4). Left-edge zone → Cabin (Phase 3). (SHIP.md)

@onready var _player: PlayerCharacter = $PlayerCharacter

var _detector: InteractionDetector

@onready var _to_cabin_zone: Area2D = $ToCabinZone

func _ready() -> void:
	_detector = _player.get_detector()
	_detector.interaction_triggered.connect(_on_interaction_triggered)
	_to_cabin_zone.body_entered.connect(_on_to_cabin)
	_spawn_player()

func _on_to_cabin(body: Node2D) -> void:
	if body is PlayerCharacter:
		SceneRouter.change_screen(load("res://scenes/screens/CabinScene.tscn"), &"from_captain")

func _spawn_player() -> void:
	if SceneRouter.pending_spawn == &"":
		return
	var marker := get_node_or_null("Spawns/%s" % SceneRouter.pending_spawn)
	if marker != null:
		_player.global_position = marker.global_position
		var cam := _player.get_node_or_null("Camera2D")
		if cam is Camera2D:
			cam.reset_smoothing()
	SceneRouter.pending_spawn = &""


func _on_interaction_triggered(interactable: Interactable) -> void:
	match interactable.station_id:
		&"steering_wheel":
			GameManager.request_sail() # → Ocean Map (DESIGN §4)
		&"bed":
			pass # end day (+ confirm) → wired in Phase 4
		&"sail_door":
			pass # set sail: current-island exploration → wired in Phase 4
