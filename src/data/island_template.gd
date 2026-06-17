class_name IslandTemplate extends Resource

@export var id: StringName
@export var biome: StringName = &"mediterranean"
@export var is_mission: bool = false

## Random islands: weighted generation between min and max nodes.
@export var min_nodes: int = 2
@export var max_nodes: int = 3
@export var spawn_rules: Array[Dictionary] = []
##   each: { "type": StringName, "weight": float, "params": Dictionary }

## Mission islands (is_mission = true): a fixed, ordered chain instead.
@export var fixed_nodes: Array[Dictionary] = []
##   each: { "type": StringName, "params": Dictionary }