extends Control
## Trade Fair (M1 stub): submit dishes → tier-judged coins → Rank 1. Submitting trades the dishes
## for coins (a dish sink alongside commissions). Warm on incomplete/empty — no penalty. Data-driven
## by FairConfig so Week 3 swaps text/tuning, not code. (§F, locked: warm-on-incomplete)

const FAIR_CONFIG_ID := &"fair_default"

@onready var _intro: Label = $Center/Panel/Margin/VBox/Intro
@onready var _dish_list: VBoxContainer = $Center/Panel/Margin/VBox/DishScroll/DishList
@onready var _tray_list: VBoxContainer = $Center/Panel/Margin/VBox/TrayList
@onready var _tally: Label = $Center/Panel/Margin/VBox/TallyLabel
@onready var _present_button: Button = $Center/Panel/Margin/VBox/ButtonRow/PresentButton
@onready var _leave_button: Button = $Center/Panel/Margin/VBox/ButtonRow/LeaveButton

var _config: FairConfig
var _submitted: Array = [] # [{recipe_id, tier}] reserved for submission

func _ready() -> void:
	_config = Database.get_fair_config(FAIR_CONFIG_ID)
	_intro.text = tr(_config.intro_line) if _config else tr("Welcome to the Trade Fair!")
	_present_button.pressed.connect(_on_present)
	_leave_button.pressed.connect(GameManager.request_return_to_ship)
	TutorialManager.try_show("fair")
	_refresh()

func _refresh() -> void:
	_refresh_dishes()
	_refresh_tray()

func _refresh_dishes() -> void:
	for c in _dish_list.get_children():
		c.queue_free()
	var any := false
	for e in GameState.get_dish_entries():
		var tier := int(e["tier"])
		var avail := int(e["count"]) - _reserved(e["recipe_id"], tier)
		if avail <= 0:
			continue
		any = true
		var rec := Database.get_recipe(e["recipe_id"])
		var disp := tr(rec.display_name) if rec else String(e["recipe_id"])
		var btn := Button.new()
		btn.text = tr("%s %s ×%d   (worth %d)") % [disp, "★".repeat(tier), avail, _coins_for_tier(tier)]
		btn.pressed.connect(_on_submit.bind(e["recipe_id"], tier))
		_dish_list.add_child(btn)
	if not any:
		var none := Label.new()
		none.text = tr("(No dishes to submit — but you can still say hello!)")
		_dish_list.add_child(none)

func _refresh_tray() -> void:
	for c in _tray_list.get_children():
		c.queue_free()
	var total := 0
	if _submitted.is_empty():
		var lbl := Label.new()
		lbl.text = tr("(nothing submitted yet)")
		_tray_list.add_child(lbl)
	else:
		for entry in _submitted:
			var rec := Database.get_recipe(entry["recipe_id"])
			var disp := tr(rec.display_name) if rec else String(entry["recipe_id"])
			var tier := int(entry["tier"])
			total += _coins_for_tier(tier)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var name_lbl := Label.new()
			name_lbl.text = "%s %s" % [disp, "★".repeat(tier)]
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var remove := Button.new()
			remove.text = "✕"
			remove.pressed.connect(_on_unsubmit.bind(entry))
			row.add_child(name_lbl)
			row.add_child(remove)
			_tray_list.add_child(row)
	_tally.text = tr("Estimated reward: %d coins") % total

func _on_submit(recipe_id: StringName, tier: int) -> void:
	_submitted.append({"recipe_id": recipe_id, "tier": tier})
	_refresh()

func _on_unsubmit(entry: Dictionary) -> void:
	_submitted.erase(entry)
	_refresh()

func _reserved(recipe_id: StringName, tier: int) -> int:
	var n := 0
	for e in _submitted:
		if e["recipe_id"] == recipe_id and int(e["tier"]) == tier:
			n += 1
	return n

func _coins_for_tier(tier: int) -> int:
	if _config and _config.coins_per_tier.has(tier):
		return int(_config.coins_per_tier[tier])
	return tier * 10 # fallback

func _on_present() -> void:
	var total := 0
	var n := _submitted.size()
	for entry in _submitted:
		var tier := int(entry["tier"])
		if GameState.remove_dishes(entry["recipe_id"], tier, 1): # consume the submitted tier
			total += _coins_for_tier(tier)
	_submitted.clear()
	var old_rank := GameState.rank
	GameState.set_rank(_config.rank_granted if _config else 1)
	var rank_up := GameState.rank > old_rank
	if total > 0:
		GameState.add_coins(total)
	AudioManager.play_sfx(&"fair_fanfare")
	UIManager.show_notice(tr("Trade Fair"), _build_result(n, total, rank_up), GameManager.request_return_to_ship)

func _build_result(n: int, coins: int, rank_up: bool) -> String:
	var lines: Array = []
	if n > 0:
		lines.append(tr("%s You presented %d dish%s and earned %d coins!") % [
			(tr(_config.result_line) if _config else tr("Wonderful!")), n, ("es" if n != 1 else ""), coins])
	else:
		lines.append(tr(_config.empty_line) if _config else tr("Come back when your kitchen's been busy!"))
	if rank_up:
		lines.append(tr("You've reached Explorer League Rank %d!") % GameState.rank)
	return "\n".join(lines)