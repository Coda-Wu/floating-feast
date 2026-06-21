class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	
	_verify_part3() # TEMP — delete after confirming


# ==== TEMP — delete after Part 3 verify ====
func _verify_part3() -> void:
	_check("oven", [&"tomato"]) # T2 baseline
	_check("oven", [&"tomato", &"rosemary"]) # T3, herbal compatible
	_check("oven", [&"tomato", &"sugar"]) # T2, sugar set aside  ← THE FIX
	_check("oven", [&"tomato", &"salt", &"onion", &"rosemary"]) # T3, 2 set aside (cap 3, beyond-cap)
	_check("oven", [&"oiled_vegetable", &"rosemary", &"onion", &"salt"]) # T5, 3 distinct spices
	_check("oven", [&"oiled_vegetable", &"rosemary", &"rosemary", &"rosemary"]) # T3, dupes set aside
	_check("mix_bowl", [&"chickpeas", &"lemon", &"olive_oil"]) # hummus T2 (lemon = base input)
	_check("mix_bowl", [&"chickpeas", &"lemon", &"olive_oil", &"rosemary"]) # hummus T2, rosemary set aside

func _check(station: String, items: Array) -> void:
	var r := Cooking.find_match(StringName(station), items)
	if r.is_empty():
		print("[P3] %-9s %s -> NO MATCH (Dubious)" % [station, items]); return
	var sr: StationRecipe = r["recipe"]
	if not sr.is_terminal:
		print("[P3] %-9s %s -> %s (non-terminal)" % [station, items, sr.output_item_id]); return
	var s := Cooking.evaluate_seasoning(sr, r["enhancers"])
	print("[P3] %-9s %s -> %s  T%d/cap%d | counted=%s set_aside=%s" % [station, items, sr.output_item_id, s["tier"], s["cap"], s["counted"], s["set_aside"]])