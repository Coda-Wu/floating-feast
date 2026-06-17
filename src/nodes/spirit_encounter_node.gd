extends ExplorationNode
## Playable Spirit Encounter (§9). Turn-based tasting: feed inventory items to raise the
## Well-Fed meter before the turn dots run out. Preferred food (matches preferred_food id OR
## tag) is worth PREFERRED_MULTIPLIER×, so the craving cue is load-bearing — wrong food can't
## fill the meter in the turn budget. Filling tames (tameable) or earns a gift (untameable);
## running out / giving up flees with drops. Feeding consumes the item. (§4.2, §9)

const PREFERRED_MULTIPLIER := 2.5

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
	TutorialManager.try_show("spirit_encounter") # first-time only (gating lives in the manager)
	_setup_spirit_view()
	_well_fed_bar.max_value = _spirit.well_fed_max
	_well_fed_bar.value = 0
	_give_up_button.text = "Give Up"
	_give_up_button.pressed.connect(_on_give_up)
	_refresh_cue()
	_refresh_dots()
	_refresh_feed_list()

func _pick_spirit() -> SpiritData:
	var direct: StringName = node_def.params.get("spirit_id", &"") # scripted/debug override
	if direct != &"":
		return Database.get_spirit(direct)
	var pool: Array = node_def.params.get("spirit_pool", [])
	if pool.is_empty():
		return null
	return Database.get_spirit(pool[randi() % pool.size()])

func _setup_spirit_view() -> void:
	_spirit_name.text = _spirit.display_name
	if _spirit.sprite_frames != null: # Week-3 path
		_spirit_sprite.sprite_frames = _spirit.sprite_frames
		_spirit_sprite.visible = true
		_spirit_sprite.play(&"idle")
		_spirit_placeholder.color = Color(_spirit_placeholder.color, 0.0)
		_spirit_name.visible = false

# --- feeding ---
func _on_feed(item_id: StringName) -> void:
	if _resolved:
		return
	var ing := Database.get_ingredient(item_id)
	if ing == null or GameState.get_item_count(item_id) <= 0:
		return
	GameState.remove_item(item_id, 1) # feeding consumes the item
	_fullness = mini(_spirit.well_fed_max, _fullness + _fullness_for(ing))
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

func _on_give_up() -> void:
	if not _resolved:
		_flee()

func _fullness_for(ing: IngredientData) -> int:
	var mult := PREFERRED_MULTIPLIER if _is_preferred(ing) else 1.0
	return int(round(ing.base_fullness * mult))

func _is_preferred(ing: IngredientData) -> bool:
	var pref := _spirit.preferred_food
	return ing.id == pref or ing.tags.has(pref)

# --- outcomes ---
func _succeed() -> void:
	_resolved = true
	if _spirit.tameable:
		if not GameState.captured_spirits.has(String(_spirit.id)):
			GameState.captured_spirits.append(String(_spirit.id))
		SignalBus.spirit_tamed.emit(_spirit)
		complete({}, "You befriended the %s!" % _spirit.display_name)
	else:
		# Untameable but well-fed → leaves a gift. Reuses spirit_fled (it leaves, isn't captured);
		# the message carries the friendly framing. (§7: no speculative "gifted" signal.)
		var drops := _drops()
		SignalBus.spirit_fled.emit(_spirit, drops)
		complete(drops, "The %s happily shared a gift before drifting off." % _spirit.display_name)

func _flee() -> void:
	_resolved = true
	var drops := _drops()
	SignalBus.spirit_fled.emit(_spirit, drops)
	complete(drops, "The %s slipped away, leaving a little behind." % _spirit.display_name)

func _drops() -> Dictionary:
	var out := {}
	for k in _spirit.drop_table:
		out[k] = int(_spirit.drop_table[k])
	return out

# --- UI refresh ---
func _refresh_cue() -> void:
	var text := "I'm craving %s..." % _humanize_preferred(_spirit.preferred_food)
	if _spirit.required_tier > 0: # always 0 in Week 1; matters once cooking exists
		text += "  (needs Tier %d)" % _spirit.required_tier
	_cue_label.text = text

func _humanize_preferred(pref: StringName) -> String:
	var ing := Database.get_ingredient(pref)
	if ing != null:
		return ing.display_name
	return String(pref).capitalize() # a tag like "vegetable" -> "Vegetable"

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
	var ids := GameState.inventory.keys()
	ids.sort()
	var any := false
	for item_id in ids:
		var count := GameState.get_item_count(item_id)
		if count <= 0:
			continue
		var ing := Database.get_ingredient(item_id)
		if ing == null:
			continue
		any = true
		var btn := Button.new()
		var likes := "  (likes!)" if _is_preferred(ing) else ""
		btn.text = "%s ×%d   (+%d%s)" % [ing.display_name, count, _fullness_for(ing), likes]
		btn.pressed.connect(_on_feed.bind(item_id))
		_feed_list.add_child(btn)
	if not any:
		var none := Label.new()
		none.text = "(No food to feed!)"
		_feed_list.add_child(none)