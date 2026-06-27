extends ExplorationNode
## Playable Spirit Encounter (§9), extended for the cook→feed link. Turn-based tasting: feed food
## to fill the Well-Fed meter before the turn dots run out. `required_tier` is the pickiness dial —
## 0 = easygoing (eats raw + dishes; preferred_food gives a raw bonus); >0 = gourmet (refuses raw,
## accepts ONLY dishes whose family matches preferred_food at tier ≥ required_tier). Dishes give
## flat tier-scaled fullness. Refused feeds cost nothing. (§4.2, §C, §D)

const PREFERRED_MULTIPLIER := 2.5
const DISH_FULLNESS_PER_TIER := 20

@onready var _well_fed_bar: ProgressBar = $Center/Column/WellFedBar
@onready var _turn_dots: HBoxContainer = $Center/Column/TurnDots
@onready var _cue_label: Label = $Center/Column/CueBubble/CueMargin/CueLabel
@onready var _spirit_placeholder: ColorRect = $Center/Column/SpiritView/Placeholder
@onready var _spirit_sprite: AnimatedSprite2D = $Center/Column/SpiritView/Sprite
@onready var _spirit_name: Label = $Center/Column/SpiritView/NameLabel
@onready var _feed_list: VBoxContainer = $Center/Column/FeedScroll/FeedList
@onready var _give_up_button: Button = $Center/Column/GiveUpButton

var _spirit: SpiritData
var _fullness := 0
var _turns_used := 0
var _resolved := false

func _run() -> void:
	_spirit = _pick_spirit()
	if _spirit == null:
		push_warning("SpiritEncounterNode: no spirit (params=%s)" % node_def.params)
		complete({})
		return
	SignalBus.spirit_encountered.emit(_spirit)
	TutorialManager.try_show("spirit_encounter")
	if _spirit.required_tier > 0:
		TutorialManager.try_show("dish_feeding") # first gourmet → explain dish-feeding
	_setup_spirit_view()
	_well_fed_bar.max_value = _spirit.well_fed_max
	_well_fed_bar.value = 0
	_give_up_button.text = tr("Give Up")
	_give_up_button.pressed.connect(_on_give_up)
	_refresh_cue()
	_refresh_dots()
	_refresh_feed_list()

func _pick_spirit() -> SpiritData:
	var direct: StringName = node_def.params.get("spirit_id", &"")
	if direct != &"":
		return Database.get_spirit(direct)
	var pool: Array = node_def.params.get("spirit_pool", [])
	if pool.is_empty():
		return null
	return Database.get_spirit(pool[randi() % pool.size()])

func _setup_spirit_view() -> void:
	_spirit_name.text = tr(_spirit.display_name)
	if _spirit.sprite_frames != null: # Week-3 path
		_spirit_sprite.sprite_frames = _spirit.sprite_frames
		_spirit_sprite.visible = true
		_spirit_sprite.play(&"idle")
		_spirit_placeholder.color = Color(_spirit_placeholder.color, 0.0)
		_spirit_name.visible = false

# --- feeding: raw ingredient ---
func _on_feed_item(item_id: StringName) -> void:
	if _resolved:
		return
	var ing := Database.get_ingredient(item_id)
	if ing == null or GameState.get_item_count(item_id) <= 0:
		return
	if not _accepts_raw(ing):
		return
	GameState.remove_item(item_id, 1)
	_apply_feed(_fullness_for_item(ing))

# --- feeding: cooked dish ---
func _on_feed_dish(recipe_id: StringName, tier: int) -> void:
	if _resolved:
		return
	var recipe := Database.get_recipe(recipe_id)
	if recipe == null or not _accepts_dish(recipe, tier):
		return
	if not GameState.remove_dishes(recipe_id, tier, 1): # consumes the clicked tier (lowest qualifying)
		return
	_apply_feed(_fullness_for_dish(tier))

func _on_give_up() -> void:
	if not _resolved:
		_flee()

func _apply_feed(amount: int) -> void:
	_fullness = mini(_spirit.well_fed_max, _fullness + amount)
	_turns_used += 1
	_well_fed_bar.value = _fullness
	_refresh_dots()
	_refresh_feed_list()
	if _fullness >= _spirit.well_fed_max:
		_succeed()
	elif _turns_used >= _spirit.turns_before_flee:
		_flee()
	else:
		_refresh_cue()

# --- accept/refuse gate ---
func _accepts_raw(ing: IngredientData) -> bool:
	return _spirit.required_tier == 0 # gourmets refuse all raw food

func _accepts_dish(recipe: RecipeData, tier: int) -> bool:
	if _spirit.required_tier == 0:
		return true # easygoing: any dish accepted
	return tier >= _spirit.required_tier and recipe.family_tags.has(_spirit.preferred_food)

func _fullness_for_item(ing: IngredientData) -> int:
	var mult := PREFERRED_MULTIPLIER if _is_preferred_raw(ing) else 1.0
	return int(round(ing.base_fullness * mult))

func _fullness_for_dish(tier: int) -> int:
	return DISH_FULLNESS_PER_TIER * tier

func _is_preferred_raw(ing: IngredientData) -> bool:
	var pref := _spirit.preferred_food
	return ing.id == pref or ing.tags.has(pref)

# --- outcomes ---
func _succeed() -> void:
	_resolved = true
	if _spirit.tameable:
		if not GameState.captured_spirits.has(String(_spirit.id)):
			GameState.captured_spirits.append(String(_spirit.id))
		SignalBus.spirit_tamed.emit(_spirit)
		complete({}, tr("You befriended the %s!") % tr(_spirit.display_name))
	else:
		var drops := _drops()
		SignalBus.spirit_fled.emit(_spirit, drops)
		complete(drops, tr("The %s happily shared a gift before drifting off.") % tr(_spirit.display_name))

func _flee() -> void:
	_resolved = true
	var drops := _drops()
	SignalBus.spirit_fled.emit(_spirit, drops)
	complete(drops, tr("The %s slipped away, leaving a little behind.") % tr(_spirit.display_name))

func _drops() -> Dictionary:
	var out := {}
	for k in _spirit.drop_table:
		out[k] = int(_spirit.drop_table[k])
	return out

# --- UI refresh ---
func _refresh_cue() -> void:
	if _spirit.required_tier > 0:
		_cue_label.text = tr("I'm craving a %s dish... (Tier %d+)") % [_humanize_preferred(_spirit.preferred_food), _spirit.required_tier]
	else:
		_cue_label.text = tr("I'm craving %s...") % _humanize_preferred(_spirit.preferred_food)

func _humanize_preferred(pref: StringName) -> String:
	var ing := Database.get_ingredient(pref)
	if ing != null:
		return tr(ing.display_name)
	return String(pref).capitalize() # a tag/family like "roasted" -> "Roasted"

func _refresh_dots() -> void:
	for c in _turn_dots.get_children():
		c.queue_free()
	var remaining := _spirit.turns_before_flee - _turns_used
	for i in _spirit.turns_before_flee:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.color = Color(0.95, 0.82, 0.45) if i < remaining else Color(0.30, 0.30, 0.30)
		_turn_dots.add_child(dot)

func _refresh_feed_list() -> void:
	for c in _feed_list.get_children():
		c.queue_free()
	var rows_added := 0
	# Raw ingredients — only for easygoing spirits (gourmets refuse raw); working items excluded.
	if _spirit.required_tier == 0:
		var ids := GameState.get_carried_item_ids()
		for item_id in ids:
			var count := GameState.get_item_count(item_id)
			if count <= 0:
				continue
			var ing := Database.get_ingredient(item_id)
			if ing == null or ing.tags.has(&"intermediate"): # locked: working items aren't food
				continue
			var btn := Button.new()
			var likes := tr("  (likes!)") if _is_preferred_raw(ing) else ""
			btn.text = tr("%s ×%d   (+%d%s)") % [tr(ing.display_name), count, _fullness_for_item(ing), likes]
			btn.pressed.connect(_on_feed_item.bind(item_id))
			_feed_list.add_child(btn)
			rows_added += 1
	# Dishes — tier-scaled; gated dishes shown disabled.
	var entries := GameState.get_dish_entries()
	if not entries.is_empty():
		var header := Label.new()
		header.text = tr("— Dishes —")
		_feed_list.add_child(header)
		for e in entries:
			var recipe := Database.get_recipe(e["recipe_id"])
			if recipe == null:
				continue
			var tier := int(e["tier"])
			var count := int(e["count"])
			var stars := "★".repeat(tier)
			var btn := Button.new()
			if _accepts_dish(recipe, tier):
				btn.text = tr("%s %s ×%d   (+%d)") % [tr(recipe.display_name), stars, count, _fullness_for_dish(tier)]
			else:
				btn.text = tr("%s %s ×%d") % [tr(recipe.display_name), stars, count]
				btn.disabled = true
			btn.pressed.connect(_on_feed_dish.bind(e["recipe_id"], tier))
			_feed_list.add_child(btn)
			rows_added += 1
	if rows_added == 0:
		var none := Label.new()
		if _spirit.required_tier > 0:
			none.text = tr("(Cook a %s dish, Tier %d+, to win me over!)") % [_humanize_preferred(_spirit.preferred_food), _spirit.required_tier]
		else:
			none.text = tr("(No food to feed!)")
		_feed_list.add_child(none)