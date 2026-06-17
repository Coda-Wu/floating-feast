extends Control
## Hosts an island's node chain. Instances the current node into NodeSlot, decrements budget
## per resolve, presents the ResolutionPanel, and routes Next / Exit / overshoot-truncation.
## Travel lines accumulate per island entered; budget is spent per node resolved (§13). (§5, §9)

const NODE_SCENES := {} # 5b fills this (shop / npc / event); empty now → all use the fallback
const FALLBACK_NODE := preload("res://scenes/nodes/PlaceholderNode.tscn")

@onready var _node_slot: Control = $NodeSlot

var _chain: Array[NodeDefinition] = []
var _index := 0
var _pending_warn := false # current resolution: Exit means skipping remaining nodes → warn
var _pending_to_ship := false # current resolution: a direct Exit goes to the Ship (out of time)

func _ready() -> void:
	var island: Island = GameManager.current_island
	if island == null:
		push_error("IslandScreen: no current_island.")
		return
	_chain = island.node_chain
	SignalBus.island_entered.emit(island)
	if _chain.is_empty():
		_exit_to_map()
		return
	_index = 0
	_start_node(_index)

func _start_node(i: int) -> void:
	_clear_slot()
	var def := _chain[i]
	var scene: PackedScene = NODE_SCENES.get(def.type, FALLBACK_NODE)
	var node: ExplorationNode = scene.instantiate()
	_node_slot.add_child(node) # add first → @onready resolves before start()
	node.node_completed.connect(_on_node_completed)
	SignalBus.node_started.emit(def)
	node.start(def)

func _on_node_completed(rewards: Dictionary) -> void:
	var def := _chain[_index]
	for item_id in rewards: # 1) rewards into inventory (via the one mutator)
		GameState.add_item(item_id, int(rewards[item_id]))
	SignalBus.node_resolved.emit(def, rewards)
	GameState.spend_budget(1) # 2) one Time per resolved node
	_clear_slot() # 3) free the finished node, then resolve
	_present_resolution(rewards)

func _present_resolution(rewards: Dictionary) -> void:
	var is_last := _index >= _chain.size() - 1
	var out_of_time := GameState.budget_current <= 0
	var show_next := not is_last and not out_of_time
	_pending_warn = show_next
	_pending_to_ship = out_of_time

	var message := ""
	var exit_label := "Leave Early"
	if out_of_time and not is_last:
		message = "Out of time — best head back before dark."
		exit_label = "Return to Ship"
	elif out_of_time and is_last:
		message = "You've explored the whole island, and the light is fading."
		exit_label = "Return to Ship"
	elif is_last:
		message = "That's the whole island explored."
		exit_label = "Back to Map"

	UIManager.show_resolution_panel(rewards, show_next, message, exit_label,
		_on_resolution_next, _on_resolution_exit)

func _on_resolution_next() -> void:
	UIManager.hide_resolution_panel()
	_index += 1
	_start_node(_index)

func _on_resolution_exit() -> void:
	if _pending_warn:
		# Layer the warning OVER the still-present resolution panel. Confirm → leave; Cancel
		# (handled in UIManager) just drops the warning, returning to the resolution.
		UIManager.show_warning_popup(
			"Unvisited spots on this island will be lost. Head back to the map?",
			_exit_to_map)
	elif _pending_to_ship:
		_exit_to_ship()
	else:
		_exit_to_map()

func _exit_to_map() -> void:
	UIManager.hide_resolution_panel()
	SignalBus.island_exited.emit()
	GameManager.request_return_to_map()

func _exit_to_ship() -> void:
	UIManager.hide_resolution_panel()
	SignalBus.island_exited.emit()
	GameManager.request_return_to_ship()

func _clear_slot() -> void:
	for child in _node_slot.get_children():
		child.queue_free()