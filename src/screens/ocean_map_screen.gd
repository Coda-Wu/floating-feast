extends Control
## Ocean Map — static fog-of-war world-select. Renders the fixed World Islands (Database) as markers
## at their map_position: unlocked (clear, clickable) when quest_phase >= unlock_phase, else a fogged,
## inert silhouette. Selecting an unlocked island enters it. No procedural arranger or travel routes
## anymore — selection is a fixed, hand-authored level-select. (§2)

const SEA_COLOR := Color(0.16, 0.34, 0.45)
const SHIP_COLOR := Color(0.85, 0.70, 0.45)
const SHIP_RADIUS := 10.0
const VIEWPORT := Vector2(640, 360)
const ISLAND_RADIUS := 26.0
const FONT_SIZE := 9

@onready var _return_button: Button = $ReturnButton

var _islands: Array[WorldIslandData] = []

func _ready() -> void:
	_return_button.pressed.connect(GameManager.request_return_to_ship)
	_islands = Database.get_all_world_islands()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for wi in _islands:
			if _is_unlocked(wi) and not _is_explored(wi) and event.position.distance_to(wi.map_position) <= ISLAND_RADIUS:
				GameManager.enter_world_island(wi)
				return


func _is_explored(wi: WorldIslandData) -> bool:
	return wi.id in GameState.islands_explored_today

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT), SEA_COLOR)
	draw_circle(GameManager.SHIP_POS, SHIP_RADIUS, SHIP_COLOR)
	draw_arc(GameManager.SHIP_POS, SHIP_RADIUS, 0.0, TAU, 24, Color(0.45, 0.32, 0.16), 2.0, true)
	for wi in _islands:
		_draw_island(wi)

func _draw_island(wi: WorldIslandData) -> void:
	var pos := wi.map_position
	if not _is_unlocked(wi):
		draw_circle(pos, ISLAND_RADIUS, Color(0.22, 0.30, 0.36, 0.85)) # fogged silhouette
		draw_arc(pos, ISLAND_RADIUS, 0.0, TAU, 28, Color(0.30, 0.38, 0.44), 2.0, true)
		_draw_label("? ? ?", pos + Vector2(0, ISLAND_RADIUS + 10), Color(0.60, 0.68, 0.72))
		return
	if _is_explored(wi):
		draw_circle(pos, ISLAND_RADIUS, Color(0.40, 0.50, 0.42, 0.7)) # explored: dimmed, inert
		draw_arc(pos, ISLAND_RADIUS, 0.0, TAU, 28, Color(0.32, 0.40, 0.32), 2.0, true)
		_draw_label(tr(wi.display_name), pos + Vector2(0, ISLAND_RADIUS + 10), Color(0.70, 0.75, 0.70))
		_draw_label(tr("Explored today"), pos + Vector2(0, ISLAND_RADIUS + 22), Color(0.62, 0.68, 0.62))
		return
	draw_circle(pos, ISLAND_RADIUS, Color(0.55, 0.70, 0.42)) # available
	draw_arc(pos, ISLAND_RADIUS, 0.0, TAU, 28, Color(0.30, 0.22, 0.14), 2.0, true)
	_draw_label(tr(wi.display_name), pos + Vector2(0, ISLAND_RADIUS + 10), Color.WHITE)
	if wi.cuisine != "":
		_draw_label(tr(wi.cuisine), pos + Vector2(0, ISLAND_RADIUS + 22), Color(0.85, 0.90, 0.75))

func _is_unlocked(wi: WorldIslandData) -> bool:
	return GameState.quest_phase >= wi.unlock_phase

func _draw_label(text: String, center: Vector2, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(center.x - w * 0.5, center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)