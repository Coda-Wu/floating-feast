class_name CommissionData extends Resource
## A soft-deadline commission: deliver N dishes (by id OR family) at a min tier to a giver NPC →
## coins + story flag. No turn limit; the optional suggested-day grants only an additive on-time
## bonus, never a gate. (§D, locked soft-deadline decision)

@export var id: StringName
@export var title: String = ""
@export var detail: String = ""
@export var giver_npc_id: StringName = &""

# Requirement — match by dish_id OR family (leave the other empty).
@export var req_dish_id: StringName = &""
@export var req_family: StringName = &""
@export var req_min_tier: int = 1
@export var req_quantity: int = 1

# Reward.
@export var reward_coins: int = 0
@export var reward_story_flag: StringName = &""
@export var on_time_day: int = 0 # 0 = no suggested day; >0 grants on_time_bonus if delivered by then
@export var on_time_bonus: int = 0