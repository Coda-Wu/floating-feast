class_name RunGraph extends RefCounted
## One day's exploration graph: a layered DAG of NodeDefinitions with forward-only edges, a single
## start and a single terminal. Transient — regenerated each day from the World Island and held by
## GameManager (replacing day_islands). IslandScreen renders + walks it one-way in Step 4. (§3)

var nodes: Array[NodeDefinition] = [] # all nodes, indexed
var edges: Dictionary = {} # node_index -> Array[int] (outgoing, toward the terminal)
var layer_of: Array[int] = [] # nodes[i] sits in column layer_of[i]
var start_index: int = -1
var terminal_index: int = -1

func next_of(i: int) -> Array:
	return edges.get(i, [])

func incoming_count(target: int) -> int:
	var n := 0
	for from in edges:
		if target in edges[from]:
			n += 1
	return n

func layer_count() -> int:
	var m := 0
	for l in layer_of:
		m = maxi(m, l)
	return m + 1

func nodes_in_layer(layer: int) -> Array:
	var out: Array = []
	for i in nodes.size():
		if layer_of[i] == layer:
			out.append(i)
	return out