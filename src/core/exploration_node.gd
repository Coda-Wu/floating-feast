class_name ExplorationNode extends Control
## Base for every exploration-node scene. IslandScreen instances a node, calls start(def),
## and waits for node_completed. Subclasses override _run() and read node_def; they call
## complete(rewards) when the interaction resolves. (§9)

signal node_completed(rewards: Dictionary) # {item_id: count}, possibly empty

var node_def: NodeDefinition

func start(def: NodeDefinition) -> void:
	node_def = def
	_run()

func _run() -> void:
	push_warning("ExplorationNode subclass did not override _run().")

func complete(rewards: Dictionary = {}) -> void:
	node_completed.emit(rewards)