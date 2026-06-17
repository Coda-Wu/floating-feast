extends Control
## Step-4c STUB: shows which island was entered + a Back to Map button, so the travel
## handoff is testable end to end. Step 5 replaces the body with the real node-chain engine
## (NodeSlot, ResolutionPanel, Next/Exit, budget decrement). (§5, §9)

@onready var _info: Label = $Center/VBox/Info
@onready var _back_button: Button = $Center/VBox/BackButton

func _ready() -> void:
	var island: Island = GameManager.current_island
	if island:
		var tmpl := Database.get_island_template(island.template_id)
		var biome := String(tmpl.biome) if tmpl else "?"
		_info.text = "template: %s    nodes: %d    (%s)" % [island.template_id, island.node_chain.size(), biome]
	else:
		_info.text = "(no island)"
	_back_button.pressed.connect(GameManager.request_return_to_map)