class_name Interactable extends Area2D
## A reusable proximity-interaction target (kitchen station now; ship door later). A pure
## descriptor + self-drawn gray-box block and prompt bubble — holds NO UI or interaction logic.
## The consuming scene routes on station_id and decides what an interaction does, which keeps
## one component serving stations and doors and keeps station UI kitchen-local. (§C.1)
var _prompt_node: Node2D
const _FONT := 8

@export var station_id: StringName = &""
@export var display_name: String = "Station"
@export var block_color: Color = Color(0.7, 0.7, 0.7)
@export var block_size: Vector2 = Vector2(46, 32)
@export var gray_box: bool = true ## false = invisible area over real art; draws only the [E] prompt


var _prompt_shown := false

func _ready() -> void:
	# Fresh per-instance shape (never share the scene's resource, or differing block_sizes clash).
	var shape := RectangleShape2D.new()
	shape.size = block_size
	$CollisionShape2D.shape = shape
	# Create the prompt delegate node
	_prompt_node = Node2D.new()
	_prompt_node.z_index = 50 # Force rendering above other actors/tiles
	_prompt_node.z_as_relative = false # Ignore parent's Z-index
	_prompt_node.visible = false
	_prompt_node.draw.connect(_on_prompt_draw)
	add_child(_prompt_node)
	
	queue_redraw()

func get_prompt() -> String:
	return "[E]  %s" % tr(display_name)

func set_prompt_shown(v: bool) -> void:
	if _prompt_shown == v:
		return
	_prompt_shown = v
	_prompt_node.visible = v
	if v:
		_prompt_node.queue_redraw()
func _draw() -> void:
	var half := block_size * 0.5
	if gray_box:
		draw_rect(Rect2(-half, block_size), block_color)
		draw_rect(Rect2(-half, block_size), block_color.darkened(0.4), false, 2.0)
		_draw_text_centered(tr(display_name), Vector2.ZERO, Color(0.15, 0.12, 0.10))
	# Prompt drawing is now handled by _prompt_node, so we do not call _draw_prompt here.
func _on_prompt_draw() -> void:
	var half := block_size * 0.5
	_draw_prompt(_prompt_node, get_prompt(), -half.y - 8.0)


func _draw_text_centered(text: String, center: Vector2, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _FONT)
	var baseline := center.y + (font.get_ascent(_FONT) - font.get_descent(_FONT)) * 0.5
	draw_string(font, Vector2(center.x - sz.x * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _FONT, color)

func _draw_prompt(canvas_item: CanvasItem, text: String, bottom_y: float) -> void:
	var font := ThemeDB.fallback_font
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _FONT)
	var pad := Vector2(5, 3)
	var box := Rect2(Vector2(-sz.x * 0.5 - pad.x, bottom_y - sz.y - pad.y * 2), Vector2(sz.x + pad.x * 2, sz.y + pad.y * 2))
	canvas_item.draw_rect(box, Color(0.12, 0.12, 0.14, 0.92))
	canvas_item.draw_rect(box, Color(0.95, 0.95, 0.86, 0.9), false, 1.0)
	canvas_item.draw_string(font, Vector2(-sz.x * 0.5, box.position.y + pad.y + font.get_ascent(_FONT)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _FONT, Color(0.95, 0.95, 0.86))