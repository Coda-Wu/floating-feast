class_name ExplorationNode extends Control
## Base for every exploration-node scene. IslandScreen instances a node, calls start(def),
## and waits for node_completed. Subclasses override _run() and read node_def; they call
## complete(rewards, outcome_text) when the interaction resolves. (§9)

signal node_completed(rewards: Dictionary, outcome_text: String) # rewards: {item_id: count}

var node_def: NodeDefinition

func start(def: NodeDefinition) -> void:
	node_def = def
	_run()

func _run() -> void:
	push_warning("ExplorationNode subclass did not override _run().")

func complete(rewards: Dictionary = {}, outcome_text: String = "") -> void:
	node_completed.emit(rewards, outcome_text)