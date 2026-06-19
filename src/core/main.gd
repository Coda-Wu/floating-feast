class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_step10a() # TEMP — delete after confirming


# ==== TEMP — delete after Step 10a verify ====
func _verify_step10a() -> void:
	_print_match("oven", [&"tomato"]) # → roasted_tomato (terminal)
	_print_match("prep", [&"tomato"]) # → chopped_vegetable
	_print_match("mix_bowl", [&"chopped_vegetable", &"chopped_vegetable", &"olive_oil"]) # → oiled_vegetable
	_print_match("oven", [&"oiled_vegetable"]) # → med_roasted_vegetables
	_print_match("oven", [&"oiled_vegetable", &"rosemary", &"onion"]) # → med_roasted_vegetables + 2 enhancers
	_print_match("mix_bowl", [&"chopped_vegetable", &"olive_oil"]) # → classic_rustic_salad
	_print_match("oven", [&"flour"]) # → NO MATCH (Dubious)
	_print_match("oven", [&"tomato", &"potato"]) # → NO MATCH (Dubious)

func _print_match(station: String, items: Array) -> void:
	var r := Cooking.find_match(StringName(station), items)
	if r.is_empty():
		print("[verify 10a] %-9s %s -> NO MATCH (Dubious Food)" % [station, items])
	else:
		var sr: StationRecipe = r["recipe"]
		print("[verify 10a] %-9s %s -> %s (terminal=%s, enhancers=%s)" % [station, items, sr.output_item_id, sr.is_terminal, r["enhancers"]])