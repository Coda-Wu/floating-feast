extends Control
## Terminal-cook result: shows the dish, its star tier, and the contributing-factor breakdown
## (base + added spices = total) — the Demo Scope's quality-legibility surface. Doubles as the
## "New Recipe" announcement via a banner when the cook was a discovery. Dumb view: renders a
## finished breakdown, recomputes nothing; emits dismissed. (§C.6, §C.5)

signal dismissed

@onready var _new_banner: Label = $Center/Panel/Margin/VBox/NewBanner
@onready var _dish_name: Label = $Center/Panel/Margin/VBox/DishName
@onready var _star_label: Label = $Center/Panel/Margin/VBox/StarLabel
@onready var _breakdown_base: Label = $Center/Panel/Margin/VBox/BreakdownBase
@onready var _breakdown_enh: Label = $Center/Panel/Margin/VBox/BreakdownEnh
@onready var _breakdown_total: Label = $Center/Panel/Margin/VBox/BreakdownTotal
@onready var _ok_button: Button = $Center/Panel/Margin/VBox/OkButton
@onready var _set_aside_label: Label = $Center/Panel/Margin/VBox/SetAsideLabel

func setup(info: Dictionary) -> void:
	_new_banner.visible = bool(info.get("is_new", false))
	_dish_name.text = tr(Database.get_display_name(info["recipe_id"]))
	var tier := int(info["tier"])
	_star_label.text = _stars(tier)
	var base := int(info.get("base_stars", 2))
	var counted: Array = info.get("counted", [])
	var set_aside: Array = info.get("set_aside", [])
	var cap := int(info.get("cap", 5))
	_breakdown_base.text = tr("Base & execution: %s") % _stars(base)
	if counted.size() > 0:
		_breakdown_enh.text = tr("Compatible spices (×%d): +%s") % [counted.size(), _stars(counted.size())]
	else:
		_breakdown_enh.text = tr("Spices: — (add a compatible spice for more stars)")
	var total := "= %s  (%s)" % [_stars(tier), _tier_name(tier)]
	if tier >= cap:
		total += tr("  — best this dish can be")
	_breakdown_total.text = total
	if set_aside.size() > 0:
		var names: Array = []
		for sid in set_aside:
			names.append(tr(Database.get_display_name(sid)))
		_set_aside_label.text = tr("Set aside (didn't suit this dish): %s") % ", ".join(names)
		_set_aside_label.visible = true
	else:
		_set_aside_label.visible = false
	_ok_button.pressed.connect(func() -> void: dismissed.emit())
	_ok_button.grab_focus()

func _stars(n: int) -> String:
	return "★".repeat(maxi(n, 0))

func _tier_name(tier: int) -> String:
	match tier:
		1: return tr("Dubious")
		2: return tr("Plain")
		3: return tr("Good")
		4: return tr("Great")
		_: return tr("Perfect")