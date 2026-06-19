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

func setup(info: Dictionary) -> void:
	# info: { recipe_id, tier, base_stars, bonus_stars, enhancer_count, is_new }
	_new_banner.visible = bool(info.get("is_new", false))
	_dish_name.text = Database.get_display_name(info["recipe_id"])
	var tier := int(info["tier"])
	_star_label.text = _stars(tier)
	var base := int(info.get("base_stars", 2))
	var bonus := int(info.get("bonus_stars", 0))
	var enh := int(info.get("enhancer_count", 0))
	_breakdown_base.text = "Base & execution: %s" % _stars(base)
	if bonus > 0:
		_breakdown_enh.text = "Added spices (×%d): +%s" % [enh, _stars(bonus)]
	else:
		_breakdown_enh.text = "Added spices: — (add spices for more stars)"
	_breakdown_total.text = "= %s  (%s)" % [_stars(tier), _tier_name(tier)]
	_ok_button.pressed.connect(func() -> void: dismissed.emit())
	_ok_button.grab_focus()

func _stars(n: int) -> String:
	return "★".repeat(maxi(n, 0))

func _tier_name(tier: int) -> String:
	match tier:
		1: return "Dubious"
		2: return "Plain"
		3: return "Good"
		4: return "Great"
		_: return "Perfect"