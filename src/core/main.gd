class_name Main extends Node2D
## The persistent root. Holds ScreenHost (the swappable screen slot) and performs
## the boot handoffs the autoloads can't do themselves (they exist before the scene
## tree). The last line is temporary scaffolding, replaced by GameManager in Step 3. (§5)

@onready var _screen_host: Control = $ScreenHost

func _ready() -> void:
	SceneRouter.register_host(_screen_host)
	UIManager.create_persistent_ui(self )
	GameManager.start_day()
	_verify_p1() # TEMP — delete after confirming


# ==== TEMP — delete after P-1 verify ====
func _verify_p1() -> void:
	GameState.known_recipes.assign([&"roasted_tomato", &"roasted_potato", &"roasted_eggplant",
		&"med_roasted_vegetables", &"classic_rustic_salad", &"hummus"])
	print("--- recipe steps ---")
	for rid in [&"roasted_tomato", &"classic_rustic_salad", &"med_roasted_vegetables", &"hummus"]:
		print("  ", rid, ":")
		for step in CookingInfo.get_recipe_steps(rid):
			var ins: Array = []
			for i in step["inputs"]:
				ins.append("%sx%d%s" % [i["ref"], i["count"], "(tag)" if i["is_tag"] else ""])
			print("    [%s] %s -> %s" % [step["station_id"], ins, step["output_id"]])
	print("--- base ingredients ---")
	for rid in [&"med_roasted_vegetables", &"classic_rustic_salad", &"hummus"]:
		var b: Array = []
		for x in CookingInfo.get_base_ingredients(rid):
			b.append("%sx%d%s" % [x["ref"], x["count"], "(tag)" if x["is_tag"] else ""])
		print("  ", rid, ": ", b)
	print("--- compatible spices ---")
	for rid in [&"roasted_tomato", &"classic_rustic_salad", &"hummus"]:
		print("  ", rid, ": ", CookingInfo.get_compatible_spices(rid))
	print("--- dishes using ingredient ---")
	for iid in [&"tomato", &"olive_oil", &"rosemary", &"lemon", &"sugar"]:
		print("  ", iid, ": ", CookingInfo.get_dishes_using(iid))