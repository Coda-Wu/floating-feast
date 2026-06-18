class_name TopDownActor extends CharacterBody2D
## Reusable top-down character: 8-direction movement via the move_* actions, a runtime-assigned
## AnimatedSprite2D (§3 swap rule — null in gray-box → placeholder), and (8b) a child
## InteractionDetector. The kitchen and any future walkable space reuse this. (§C.1)

@export var speed: float = 100.0
@export var bounds: Rect2 = Rect2(0, 0, 640, 360) # room clamp (gray-box; physics collision later)
@export var sprite_frames: SpriteFrames # Week-3 swap target; null in gray-box

const RADIUS := 9.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing := Vector2.DOWN
var _use_placeholder := true

func _ready() -> void:
	if sprite_frames != null: # Week-3 path
		_sprite.sprite_frames = sprite_frames
		_sprite.visible = true
		_use_placeholder = false
	else:
		_sprite.visible = false
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = dir * speed
	move_and_slide()
	# Gray-box room clamp — replaced by wall/station collision once there's something to hit.
	global_position.x = clampf(global_position.x, bounds.position.x + RADIUS, bounds.end.x - RADIUS)
	global_position.y = clampf(global_position.y, bounds.position.y + RADIUS, bounds.end.y - RADIUS)
	if dir.length() > 0.01:
		_facing = dir.normalized()
		if _use_placeholder:
			queue_redraw()

func _draw() -> void:
	if not _use_placeholder:
		return
	draw_circle(Vector2.ZERO, RADIUS, Color(0.90, 0.78, 0.55)) # body
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 20, Color(0.45, 0.33, 0.18), 1.5, true)
	draw_circle(_facing * (RADIUS - 2.0), 2.5, Color(0.30, 0.20, 0.10)) # facing nub (previews 8-dir)