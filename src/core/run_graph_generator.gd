class_name RunGraphGenerator extends RefCounted
## Builds one day's RunGraph from a WorldIslandData: a layered DAG (single start, branching middle,
## single terminal) with forward edges, per-node fuel_cost by depth, and node types drawn from the
## island's tiered pools. Consults GameState.island_depletion (skips depleted Tier-S) and excludes
## already-learned recipes, so a run is "random minus the depleted pool." Deterministic per seed. (§3, §9)

const MIN_MIDDLE_LAYERS := 3
const MAX_MIDDLE_LAYERS := 4
const MIN_PER_LAYER := 2
const MAX_PER_LAYER := 3

static func generate(island: WorldIslandData, seed: int) -> RunGraph:
	var g := RunGraph.new()
	if island == null:
		return g
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var shallow := _eligible(island.shallow_pool, island)
	var mid := _eligible(island.mid_pool, island)
	var deep := _eligible(island.deep_pool, island)

	var layers: Array = [] # Array of Array[int]: node indices per column

	# layer 0 — start anchor (no scene, no fuel; the player begins here)
	var start := NodeDefinition.new(&"start", {})
	start.fuel_cost = 0
	g.start_index = _add_node(g, 0, start)
	layers.append([g.start_index])

	# middle layers — the branching body
	var middle := rng.randi_range(MIN_MIDDLE_LAYERS, MAX_MIDDLE_LAYERS)
	for layer in range(1, middle + 1):
		var row: Array = []
		for _k in rng.randi_range(MIN_PER_LAYER, MAX_PER_LAYER):
			var pool: Array = shallow if layer == 1 else mid
			row.append(_add_node(g, layer, _make_node(_pick(pool, rng), layer, false)))
		layers.append(row)

	# terminal — the day's prime reward
	var term_layer := middle + 1
	g.terminal_index = _add_node(g, term_layer, _make_node(_pick(deep, rng), term_layer, true))
	layers.append([g.terminal_index])

	# edges — connect each column forward, guaranteeing connectivity
	for l in range(layers.size() - 1):
		_connect(g, layers[l], layers[l + 1], rng)
	return g

# --- eligibility: the two consultations ---
static func _eligible(pool: Array, island: WorldIslandData) -> Array:
	var out: Array = []
	for entry in pool:
		var p: Dictionary = entry.get("params", {})
		if p.has("recipe_id") and GameState.is_recipe_known(StringName(p["recipe_id"])):
			continue # recipes self-deplete via the learned flag
		if p.has("tier_s_id"):
			var sid := StringName(p["tier_s_id"])
			if _collected(island.id, sid) >= int(island.tier_s_caps.get(sid, 0)):
				continue # capped Tier-S exhausted on this island
		out.append(entry)
	return out

static func _collected(island_id: StringName, tier_s_id: StringName) -> int:
	var st: Dictionary = GameState.island_depletion.get(island_id, {})
	return int(st.get(tier_s_id, 0))

# --- node construction ---
static func _make_node(entry: Dictionary, _layer: int, is_terminal: bool) -> NodeDefinition:
	if entry.is_empty(): # pool exhausted → consumable fallback (Step 7 makes terminals 2× standard)
		var fb := NodeDefinition.new(&"gathering", {})
		fb.fuel_cost = 2 if is_terminal else 1
		return fb
	var nd := NodeDefinition.new(entry["type"], (entry.get("params", {}) as Dictionary).duplicate(true))
	nd.fuel_cost = int(entry.get("fuel_cost", 2 if is_terminal else 1))
	return nd

# --- weighted pick (matches NodeChainGenerator's pattern) ---
static func _pick(pool: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for e in pool:
		total += float(e.get("weight", 1.0))
	if total <= 0.0:
		return {}
	var roll := rng.randf() * total
	for e in pool:
		roll -= float(e.get("weight", 1.0))
		if roll <= 0.0:
			return e
	return pool.back() if not pool.is_empty() else {}

# --- graph plumbing ---
static func _add_node(g: RunGraph, layer: int, nd: NodeDefinition) -> int:
	var i := g.nodes.size()
	g.nodes.append(nd)
	g.layer_of.append(layer)
	return i

static func _add_edge(g: RunGraph, from: int, to: int) -> void:
	if not g.edges.has(from):
		g.edges[from] = []
	if to not in g.edges[from]:
		g.edges[from].append(to)

static func _connect(g: RunGraph, a: Array, b: Array, rng: RandomNumberGenerator) -> void:
	for from in a: # every A-node gets ≥1 outgoing edge
		_add_edge(g, from, b[rng.randi() % b.size()])
	for to in b: # every B-node gets ≥1 incoming edge
		if g.incoming_count(to) == 0:
			_add_edge(g, a[rng.randi() % a.size()], to)