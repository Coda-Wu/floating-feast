class_name NodeChainGenerator extends RefCounted
## Builds an island's node chain from its IslandTemplate. Mission islands use their fixed
## ordered list; random islands roll a count and weighted-pick each slot. Deterministic
## for a given seed. (§9)

static func generate(template: IslandTemplate, seed: int) -> Array[NodeDefinition]:
	var chain: Array[NodeDefinition] = []
	if template == null:
		return chain

	if template.is_mission:
		for entry in template.fixed_nodes:
			chain.append(NodeDefinition.new(entry["type"], (entry.get("params", {}) as Dictionary).duplicate(true)))
		return chain

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var count := rng.randi_range(template.min_nodes, template.max_nodes)
	for i in count:
		var rule := _weighted_pick(template.spawn_rules, rng)
		if rule.is_empty():
			continue
		chain.append(NodeDefinition.new(rule["type"], (rule.get("params", {}) as Dictionary).duplicate(true)))
	return chain

static func _weighted_pick(rules: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for r in rules:
		total += float(r.get("weight", 1.0))
	if total <= 0.0:
		return {}
	var roll := rng.randf() * total
	for r in rules:
		roll -= float(r.get("weight", 1.0))
		if roll <= 0.0:
			return r
	return rules.back() if not rules.is_empty() else {}