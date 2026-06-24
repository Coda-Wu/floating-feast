extends Control
## Hosts the day's exploration as a previewable, one-way path map (GameManager.run_graph). Renders the
## DAG in columns with fuel-cost pips + a cursor tooltip; the player advances along edges from the
## current node, paying fuel on entry and forfeiting the branches not taken. Running a node reuses the
## ExplorationNode contract (instance into NodeSlot, start(def), node_completed → rewards). Auto-returns
## (loot kept) on reaching the terminal or running out of affordable fuel; manual Retreat is always
## available. (§3, §4, §11)

const NODE_SCENES := {
	&"gathering": preload("res://scenes/nodes/OrchardGatheringNode.tscn"),
	&"spirit_encounter": preload("res://scenes/nodes/SpiritEncounterNode.tscn"),
	&"shop": preload("res://scenes/nodes/ShopNode.tscn"),
	&"butchery": preload("res://scenes/nodes/ShopNode.tscn"),
	&"npc": preload("res://scenes/nodes/NpcNode.tscn"),
	&"event": preload("res://scenes/nodes/EventNode.tscn"),
	&"dock": preload("res://scenes/nodes/DockNode.tscn"),
	&"reward": preload("res://scenes/nodes/RewardNode.tscn"),
	&"synergy": preload("res://scenes/nodes/SynergyEventNode.tscn"),
}
const FALLBACK_NODE := preload("res://scenes/nodes/PlaceholderNode.tscn") # also stands in for terminal "reward" nodes until Step 7

const NODE_LABELS := {
	&"start": "Start", &"gathering": "Forage", &"spirit_encounter": "Spirit", &"shop": "Shop",
	&"butchery": "Butcher", &"npc": "NPC", &"event": "Event", &"reward": "Reward", &"dock": "Dock", &"synergy": "Shrine",

}
const NODE_COLORS := {
	&"start": Color(0.70, 0.70, 0.74), &"gathering": Color(0.55, 0.75, 0.45), &"spirit_encounter": Color(0.78, 0.55, 0.80),
	&"shop": Color(0.85, 0.75, 0.50), &"butchery": Color(0.82, 0.50, 0.45), &"npc": Color(0.55, 0.70, 0.85),
	&"event": Color(0.80, 0.70, 0.40), &"reward": Color(0.95, 0.80, 0.35), &"dock": Color(0.40, 0.62, 0.78), &"synergy": Color(0.70, 0.45, 0.85),
}
const MAP_BG := Color(0.13, 0.20, 0.24)
const NODE_RADIUS := 18.0
const LAYER_X0 := 72.0
const LAYER_DX := 96.0
const CENTER_Y := 162.0
const ROW_DY := 66.0
const FONT_SIZE := 9

@onready var _node_slot: Control = $NodeSlot
@onready var _retreat_button: Button = $RetreatButton

var _graph: RunGraph
var _pos: Array[Vector2] = []
var _current := -1
var _visited := {}
var _hover := -1
var _on_map := false
var _running_node: Node = null

func _ready() -> void:
	_graph = GameManager.run_graph
	if _graph == null or _graph.nodes.is_empty():
		push_error("IslandScreen: no run_graph.")
		GameManager.request_return_to_map()
		return
	_retreat_button.pressed.connect(_retreat)
	_layout_nodes()
	_current = _graph.start_index
	_visited[_current] = true
	_show_map()

func _layout_nodes() -> void:
	_pos.resize(_graph.nodes.size())
	for layer in _graph.layer_count():
		var row := _graph.nodes_in_layer(layer)
		var x := LAYER_X0 + layer * LAYER_DX
		for k in row.size():
			_pos[row[k]] = Vector2(x, CENTER_Y + (k - (row.size() - 1) * 0.5) * ROW_DY)

# --- map view ---
func _show_map() -> void:
	_clear_node()
	_node_slot.hide()
	_retreat_button.show()
	_on_map = true
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not _on_map:
		return
	if event is InputEventMouseMotion:
		var h := _node_at(event.position)
		if h != _hover:
			_hover = h
			if h != -1:
				UIManager.show_item_tooltip(_tooltip_for(h))
			else:
				UIManager.hide_item_tooltip()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var i := _node_at(event.position)
		if i != -1 and i in _graph.next_of(_current) and _affordable(i):
			_enter_node(i)

func _node_at(p: Vector2) -> int:
	for i in _pos.size():
		if p.distance_to(_pos[i]) <= NODE_RADIUS:
			return i
	return -1

func _affordable(i: int) -> bool:
	return GameState.fuel_current >= _graph.nodes[i].fuel_cost

func _any_affordable_ahead() -> bool:
	for n in _graph.next_of(_current):
		if _affordable(n):
			return true
	return false

func _tooltip_for(i: int) -> String:
	var nd := _graph.nodes[i]
	var label: String = NODE_LABELS.get(nd.type, String(nd.type))
	if i == _current:
		return "%s — you are here" % label
	if i in _graph.next_of(_current):
		return "%s — %d fuel%s" % [label, nd.fuel_cost, ("" if _affordable(i) else "  (not enough fuel)")]
	return label

# --- entering & running a node ---
func _enter_node(i: int) -> void:
	var minutes := _time_cost(_graph.nodes[i])
	if GameState.would_pass_curfew(minutes):
		_faint() # 2 AM — denied the next step (loot kept, capped coin loss)
		return
	if GameManager.current_world_island != null:
		GameState.mark_island_explored(GameManager.current_world_island.id) # first node commits the day's run
	GameState.spend_fuel(_graph.nodes[i].fuel_cost) # fuel paid on entry (§4.1)
	GameState.advance_time(minutes) # time advances on entry (§4.2) — never gates, only wraps the day
	UIManager.hide_item_tooltip()
	_hover = -1
	_current = i
	_visited[i] = true
	_run_node(i)

func _time_cost(nd: NodeDefinition) -> int:
	return 120 if nd.fuel_cost >= 2 else 60 # heavy nodes take 2 in-game hours; standard 1


func _faint() -> void:
	UIManager.hide_item_tooltip()
	GameManager.apply_faint_penalty()
	SignalBus.day_auto_returned.emit(&"curfew")
	SignalBus.island_exited.emit()
	UIManager.show_resolution_panel({}, false,
		"It's 2 AM — you drifted off on the way back. (coin - 25)",
		"Wake up", _wake, _wake)

func _wake() -> void:
	UIManager.hide_resolution_panel()
	GameManager.request_return_to_ship() # faint sends you home to the ship, not the map

func _run_node(i: int) -> void:
	_clear_node()
	_on_map = false
	_retreat_button.hide()
	var def := _graph.nodes[i]
	var scene: PackedScene = NODE_SCENES.get(def.type, FALLBACK_NODE)
	var node: ExplorationNode = scene.instantiate()
	_running_node = node
	_node_slot.add_child(node)
	node.node_completed.connect(_on_node_completed)
	_node_slot.show()
	SignalBus.node_started.emit(def)
	node.start(def)

func _on_node_completed(rewards: Dictionary, outcome_text: String) -> void:
	var def := _graph.nodes[_current]
	var is_tier_s := def.params.has("tier_s_id")
	var mult := 1
	if GameState.has_run_buff() and not is_tier_s:
		mult = int(GameState.run_buff.get("fungible_yield_mult", 1)) # buff doubles FUNGIBLE yields only — never Tier-S
	var granted := {}
	for item_id in rewards:
		granted[item_id] = int(rewards[item_id]) * mult
		GameState.add_item(item_id, granted[item_id])
	if is_tier_s and GameManager.current_world_island != null:
		GameState.record_tier_s_collected(GameManager.current_world_island.id, StringName(def.params["tier_s_id"]))
	SignalBus.node_resolved.emit(def, granted)
	_clear_node()
	var ending := _current == _graph.terminal_index or not _any_affordable_ahead()
	var msg := outcome_text
	if _current == _graph.terminal_index:
		msg = (msg + "\n" if msg != "" else "") + "You reached the day's prize."
	elif ending:
		msg = (msg + "\n" if msg != "" else "") + "Ember's tank is too low to press on."
	var label := "Set sail home" if ending else "Continue"
	UIManager.show_resolution_panel(granted, false, msg, label, _on_ack.bind(ending), _on_ack.bind(ending))

func _on_ack(ending: bool) -> void:
	UIManager.hide_resolution_panel()
	if ending:
		SignalBus.island_exited.emit()
		GameManager.request_return_to_ship()
	else:
		_show_map()
		

func _retreat() -> void:
	UIManager.hide_item_tooltip()
	SignalBus.island_exited.emit()
	GameManager.request_return_to_ship()

func _clear_node() -> void:
	if _running_node != null:
		_running_node.queue_free()
		_running_node = null


func _exit_tree() -> void:
	GameState.clear_run_buff() # run-scoped: never outlives the run, however we leave

	
# --- drawing the previewable map ---
func _draw() -> void:
	if not _on_map:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), MAP_BG)
	for from in _graph.edges:
		for to in _graph.edges[from]:
			var lit := _visited.has(from)
			draw_line(_pos[from], _pos[to], Color(0.85, 0.80, 0.55, 0.9) if lit else Color(0.4, 0.4, 0.36, 0.45), 2.0, true)
	for i in _graph.nodes.size():
		_draw_node(i)

func _draw_node(i: int) -> void:
	var nd := _graph.nodes[i]
	var p := _pos[i]
	var reachable := i in _graph.next_of(_current)
	var col: Color = NODE_COLORS.get(nd.type, Color(0.6, 0.6, 0.6))
	if i == _current:
		pass # base colour + white "you are here" ring
	elif _visited.has(i):
		col = col.darkened(0.4) # already-walked path
	elif reachable and not _affordable(i):
		col = col.darkened(0.5) # reachable but unaffordable
	elif not reachable:
		col = Color(col, 0.5) # not reachable from here (preview / forfeited)
	draw_circle(p, NODE_RADIUS, col)
	if i == _current:
		draw_arc(p, NODE_RADIUS + 3, 0, TAU, 28, Color(1, 1, 1, 0.95), 2.5, true)
	elif reachable and _affordable(i):
		draw_arc(p, NODE_RADIUS + 2, 0, TAU, 28, Color(0.98, 0.92, 0.55), 2.0, true)
	_draw_label(NODE_LABELS.get(nd.type, String(nd.type)), p + Vector2(0, -NODE_RADIUS - 4), Color.WHITE)
	if nd.fuel_cost > 0:
		_draw_fuel(p + Vector2(0, NODE_RADIUS + 8), nd.fuel_cost)

func _draw_fuel(center: Vector2, cost: int) -> void:
	var gap := 9.0
	var x0 := center.x - (cost - 1) * gap * 0.5
	for k in cost:
		draw_circle(Vector2(x0 + k * gap, center.y), 3.0, Color(0.95, 0.65, 0.20))

func _draw_label(text: String, center: Vector2, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(center.x - w * 0.5, center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)