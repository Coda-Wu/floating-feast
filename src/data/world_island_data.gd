class_name WorldIslandData extends Resource
## A fixed, hand-authored World Island on the static Ocean Map (level-select). Unlocked by main-quest
## progress (quest_phase >= unlock_phase); locked ones render fogged. Node/reward pools + Tier-S caps
## are added in Step 3 (the generator's source); this is identity + unlock + map placement only. (§2)

@export var id: StringName
@export var display_name: String = ""
@export var cuisine: String = "" # flavor label, e.g. "Mediterranean"
@export var unlock_phase: int = 0 # GameState.quest_phase >= this → unlocked (0 = always)
@export var map_position: Vector2 = Vector2.ZERO # marker centre on the 640×360 ocean map