class_name PlayerCharacter extends CharacterBody2D
## Reusable Saff — one actor for every walkable scene (garden now; kitchen / living room / future
## ship rooms later). CharacterBody2D so room-edge Area2Ds can drive walk-through transitions.
## SpriteFrames are set per scene (swap rule); move_mode picks side-scroller vs top-down. (GARDEN.md)

enum MoveMode {SIDE_SCROLL, TOP_DOWN}

@export var move_mode: MoveMode = MoveMode.SIDE_SCROLL
@export var speed: float = 300.0
@export var bounds: Rect2 = Rect2(0, 0, 640, 360) # room clamp (gray-box; edge Area2Ds replace this later)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if move_mode == MoveMode.SIDE_SCROLL:
		dir.x = Input.get_axis(&"move_left", &"move_right")
	else:
		dir = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = dir * speed
	move_and_slide()
	global_position.x = clampf(global_position.x, bounds.position.x, bounds.end.x)
	if move_mode == MoveMode.TOP_DOWN:
		global_position.y = clampf(global_position.y, bounds.position.y, bounds.end.y)
	_animate(dir)

func _animate(dir: Vector2) -> void:
	if dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0 # sheet faces right
	if dir.length() > 0.01:
		if _sprite.animation != &"walk":
			_sprite.play(&"walk")
	elif _sprite.animation != &"idle":
		_sprite.play(&"idle")

func set_movement_enabled(enabled: bool) -> void:
	set_physics_process(enabled)
	if not enabled:
		velocity = Vector2.ZERO
		_animate(Vector2.ZERO)

func get_detector() -> InteractionDetector:
	return $InteractionDetector
