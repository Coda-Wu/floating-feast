class_name SpiritData extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames ## placeholder now, final in Week 3
@export var temperament: StringName ## calm, shy, greedy, ... (flavor for M1)
@export var preferred_food: StringName ## an ingredient id OR a tag
@export var required_tier: int = 0 ## min cooked-dish tier (matters in Week 2)
@export var well_fed_max: int = 100 ## Well-Fed meter capacity
@export var turns_before_flee: int = 5 ## turn-dot count
@export var tameable: bool = true ## false = untameable tutorial spirit
@export var drop_table: Dictionary = {} ## { item_id(StringName): count(int) } on flee
@export var produces: StringName = &"" # garden: ingredient id this spirit yields overnight
@export var yield_per_night: int = 0
@export var yield_interval_days: int = 1 ## watered-days between yields (GARDEN.md "Production Speed"); 1 = every watered day
@export var native_island: StringName ## WorldIslandData id this spirit hails from (compendium); &"" = unknown
