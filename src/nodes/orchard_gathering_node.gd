extends ExplorationNode
## Playable Orchard gathering minigame (§9). A 25s fruit-catch: move the basket with the mouse
## to catch falling fruit (each catch → +1 of that specific IngredientData — the reward follows
## the action), dodging hazards (durian/bomb/beehive) that cost time when caught. The fruit that
## falls is the island's orchard-sourced pool queried from Database (add a fruit to the data → it
## falls here automatically). First-time tutorial via TutorialManager; countdown gated behind
## Start so the tip never eats the clock. (§4, §9)

const DURATION := 25.0
const SPAWN_INTERVAL := 0.72
const FALL_SPEED_MIN := 100.0
const FALL_SPEED_MAX := 140.0
const HAZARD_CHANCE := 0.28
const HAZARD_TIME_PENALTY := 3.0
const ITEM_SIZE := Vector2(22, 22)
const BASKET_SIZE := Vector2(64, 16)
const BASKET_Y := 322.0
const PLAY_RECT := Rect2(8, 52, 624, 300)
const VIEWPORT := Vector2(640, 360)

const HAZARDS := [&"durian", &"bomb", &"beehive"]
const HAZARD_COLOR := Color(0.75, 0.18, 0.16)
const BASKET_COLOR := Color(0.62, 0.44, 0.26)
const BASKET_RIM := Color(0.40, 0.27, 0.14)
const FIELD_COLOR := Color(0.30, 0.42, 0.24)

# Gray-box fruit colors (final art replaces these with sprites; color → ingredient is the
# legible stand-in). Unlisted fruits fall back to a hue hashed from the id.
const FRUIT_COLORS := {
	&"lemon": Color(0.95, 0.84, 0.30),
	&"fig": Color(0.55, 0.36, 0.60),
	&"grape": Color(0.45, 0.55, 0.30),
}

@onready var _timer_label: Label = $TopLeft/TimerLabel
@onready var _basket_label: Label = $TopLeft/BasketLabel
@onready var _legend: HBoxContainer = $TopLeft/Legend
@onready var _ready_overlay: CenterContainer = $Ready
@onready var _start_button: Button = $Ready/ReadyVBox/StartButton

var _fruit_pool: Array[IngredientData] = []
var _items: Array = [] # each: { id, pos, speed, hazard, color }
var _basket_x := VIEWPORT.x * 0.5
var _time_left := DURATION
var _spawn_accum := 0.0
var _caught: Dictionary = {} # fruit_id -> count  (exactly the rewards shape IslandScreen wants)
var _caught_total := 0
var _playing := false
var _resolved := false
var _rng := RandomNumberGenerator.new()

func _run() -> void:
	_rng.randomize()
	_fruit_pool = Database.get_ingredients_by_source(&"orchard")
	_build_legend()
	_time_left = DURATION
	_timer_label.text = tr("Time: %.1f") % _time_left
	_basket_label.text = tr("Basket: 0")
	_ready_overlay.visible = true
	_start_button.pressed.connect(_begin)
	set_process(false) # nothing moves until Start
	TutorialManager.try_show("orchard") # first-time tip pops over the ready screen

func _begin() -> void:
	if _playing or _resolved:
		return
	if _fruit_pool.is_empty():
		push_warning("OrchardGatheringNode: no orchard-sourced ingredients.")
		complete({}, tr("The orchard was bare today."))
		return
	_ready_overlay.visible = false
	_playing = true
	set_process(true)

func _process(delta: float) -> void:
	if not _playing:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_finish()
		return
	_timer_label.text = tr("Time: %.1f") % _time_left
	var half := BASKET_SIZE.x * 0.5
	_basket_x = clampf(get_local_mouse_position().x, PLAY_RECT.position.x + half, PLAY_RECT.end.x - half)
	_spawn_accum += delta
	if _spawn_accum >= SPAWN_INTERVAL:
		_spawn_accum -= SPAWN_INTERVAL
		_spawn_item()
	var basket_rect := _basket_rect()
	var keep: Array = []
	for item in _items:
		item["pos"].y += item["speed"] * delta
		if Rect2(item["pos"], ITEM_SIZE).intersects(basket_rect):
			_on_caught(item) # caught → tally fruit or apply penalty; drop it
			continue
		if item["pos"].y > VIEWPORT.y: # fell past the bottom → missed (no penalty)
			continue
		keep.append(item)
	_items = keep
	queue_redraw()

func _spawn_item() -> void:
	var is_hazard := _rng.randf() < HAZARD_CHANCE
	var x := _rng.randf_range(PLAY_RECT.position.x, PLAY_RECT.end.x - ITEM_SIZE.x)
	var item := {
		"pos": Vector2(x, PLAY_RECT.position.y - ITEM_SIZE.y),
		"speed": _rng.randf_range(FALL_SPEED_MIN, FALL_SPEED_MAX),
		"hazard": is_hazard,
	}
	if is_hazard:
		item["id"] = HAZARDS[_rng.randi() % HAZARDS.size()]
		item["color"] = HAZARD_COLOR
	else:
		var fruit: IngredientData = _fruit_pool[_rng.randi() % _fruit_pool.size()]
		item["id"] = fruit.id
		item["color"] = _fruit_color(fruit.id)
	_items.append(item)

func _on_caught(item: Dictionary) -> void:
	if item["hazard"]:
		_time_left = maxf(0.0, _time_left - HAZARD_TIME_PENALTY)
	else:
		var id: StringName = item["id"]
		_caught[id] = int(_caught.get(id, 0)) + 1
		_caught_total += 1
		_basket_label.text = tr("Basket: %d") % _caught_total

func _finish() -> void:
	if _resolved:
		return
	_resolved = true
	_playing = false
	set_process(false)
	queue_redraw()
	var msg := tr("Gathered a basketful!") if not _caught.is_empty() else tr("The fruit all slipped past you this time.")
	complete(_caught.duplicate(), msg)

# --- drawing ---
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT), FIELD_COLOR)
	for item in _items:
		if item["hazard"]:
			draw_rect(Rect2(item["pos"], ITEM_SIZE), item["color"]) # hazards: squares + X
			var p: Vector2 = item["pos"]
			draw_line(p, p + ITEM_SIZE, Color.WHITE, 2.0)
			draw_line(p + Vector2(ITEM_SIZE.x, 0), p + Vector2(0, ITEM_SIZE.y), Color.WHITE, 2.0)
		else:
			draw_circle(item["pos"] + ITEM_SIZE * 0.5, ITEM_SIZE.x * 0.5, item["color"]) # fruit: circles
	if not _resolved:
		var br := _basket_rect()
		draw_rect(br, BASKET_COLOR)
		draw_rect(br, BASKET_RIM, false, 2.0)

# --- helpers ---
func _basket_rect() -> Rect2:
	return Rect2(Vector2(_basket_x - BASKET_SIZE.x * 0.5, BASKET_Y), BASKET_SIZE)

func _fruit_color(id: StringName) -> Color:
	if FRUIT_COLORS.has(id):
		return FRUIT_COLORS[id]
	return Color.from_hsv(float(abs(hash(id)) % 360) / 360.0, 0.55, 0.85)

func _build_legend() -> void:
	for c in _legend.get_children():
		c.queue_free()
	for fruit in _fruit_pool:
		_legend.add_child(_legend_entry(_fruit_color(fruit.id), tr(fruit.display_name)))
	_legend.add_child(_legend_entry(HAZARD_COLOR, tr("hazards -%ds") % int(HAZARD_TIME_PENALTY)))

func _legend_entry(color: Color, text: String) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(12, 12)
	swatch.color = color
	var lbl := Label.new()
	lbl.text = text
	box.add_child(swatch)
	box.add_child(lbl)
	return box