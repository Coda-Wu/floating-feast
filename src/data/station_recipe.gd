class_name StationRecipe extends Resource
## Drives the cooking simulation: at a station, match slotted items against `inputs`; on a match,
## consume them and produce `output_item_id` (a finished dish if `is_terminal`). (§C.3, §C.4)

@export var id: StringName
@export var station_id: StringName # prep, mix_bowl, oven
@export var inputs: Array[Dictionary] = [] # [{ match: StringName(tag|item_id), count: int }, ...]
@export var output_item_id: StringName
@export var is_terminal: bool = false # true → produces a finished dish (tier computed Day 11)