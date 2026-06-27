extends ExplorationNode
## Reward / Chest — grants the terminal prize from params and shows a claim screen. Handles a learned
## recipe and/or an item bundle (the Tier-S geode, or the doubled consumable haul on a depleted
## island). The recipe is granted here; items flow through complete(rewards). Counted-Tier-S depletion
## is recorded by IslandScreen on completion. (§7)

@onready var _body: Label = $Center/Panel/Margin/Column/Body
@onready var _claim: Button = $Center/Panel/Margin/Column/Claim

func _run() -> void:
	var p := node_def.params
	var rewards := {}
	var lines: Array = []
	if p.has("recipe_id"):
		var rid := StringName(p["recipe_id"])
		if GameState.mark_recipe_known(rid):
			SignalBus.recipe_discovered.emit(String(rid))
		var rec := Database.get_recipe(rid)
		lines.append(tr("Recipe learned: %s") % (tr(rec.display_name) if rec else String(rid)))
	if p.has("item_id"):
		var count := int(p.get("count", 1))
		rewards[StringName(p["item_id"])] = count
		lines.append(tr("Found: %s ×%d") % [_item_name(StringName(p["item_id"])), count])
	if lines.is_empty():
		lines.append(tr("Nothing of note here."))
	_body.text = "\n".join(lines)
	_claim.pressed.connect(func() -> void: complete(rewards, _body.text))

func _item_name(id: StringName) -> String:
	var ing := Database.get_ingredient(id)
	return tr(ing.display_name) if ing != null else String(id).capitalize()