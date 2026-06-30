extends Node2D
## The walkable Captain's Room. Steering Wheel → Ocean Map; Bed → end day (Phase 4); Sail Door →
## daytime exploration on the current island (Phase 4). Left-edge zone → Cabin (Phase 3). (SHIP.md)

@onready var _player: PlayerCharacter = $PlayerCharacter

var _detector: InteractionDetector

func _ready() -> void:
	_detector = _player.get_detector()
	_detector.interaction_triggered.connect(_on_interaction_triggered)

func _on_interaction_triggered(interactable: Interactable) -> void:
	match interactable.station_id:
		&"steering_wheel":
			GameManager.request_sail() # → Ocean Map (DESIGN §4)
		&"bed":
			pass # end day (+ confirm) → wired in Phase 4
		&"sail_door":
			pass # set sail: current-island exploration → wired in Phase 4
