class_name FairConfig extends Resource
## Trade Fair tuning: judge lines, coins-per-tier payout, and the rank granted. Data-driven so
## Week 3 swaps text/numbers, not code. (§D)

@export var id: StringName
@export var intro_line: String = ""
@export var coins_per_tier: Dictionary = {} # tier(int) -> coins(int)
@export var rank_granted: int = 1
@export var result_line: String = "" # warm line when dishes were submitted
@export var empty_line: String = "" # warm line when nothing was submitted