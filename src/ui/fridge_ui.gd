extends Control
## Fridge — open-book layout. Top bookmarks switch Ingredients/Dishes; the left page is a category-
## filtered grid of stored ingredients; clicking one shows its info on the right page (enlarged icon,
## name, and the discovered dishes it makes) with an "Add to Backpack" (withdraw) button. Deposit by
## clicking a hotbar item while open. The Dish page arrives in P-2b. (Parts 1-2)

signal close_requested

const BOOKMARK := preload("res://scenes/ui/Bookmark.tscn")
const ITEM_GRID := preload("res://scenes/ui/ItemGrid.tscn")
const ITEM_SLOT := preload("res://scenes/ui/ItemSlot.tscn")

const TAB_COLORS := {&"ingredients": Color(0.55, 0.75, 0.45), &"dishes": Color(0.80, 0.55, 0.40)}
const CATEGORIES := [
	{"id": &"all", "label": "All", "tag": &"", "color": Color(0.70, 0.70, 0.74)},
	{"id": &"veg", "label": "Veg", "tag": &"vegetable", "color": Color(0.55, 0.75, 0.45)},
	{"id": &"protein", "label": "Meat/Fish", "tag": &"protein", "color": Color(0.82, 0.50, 0.45)},
	{"id": &"grain", "label": "Grain", "tag": &"grain", "color": Color(0.85, 0.75, 0.50)},
	{"id": &"dairy", "label": "Dairy", "tag": &"dairy", "color": Color(0.88, 0.90, 0.96)},
	{"id": &"spice", "label": "Spice", "tag": &"spice", "color": Color(0.75, 0.55, 0.78)},
]

@onready var _book: BookFrame = $BookFrame

var _tab: StringName = &"ingredients"
var _category: StringName = &"all"
var _selected: StringName = &""
var _tab_marks := {}
var _cat_marks := {}
var _ing_left: VBoxContainer
var _left_grid: ItemGrid
var _ing_right: VBoxContainer
var _big_swatch: Panel
var _name_label: Label
var _dish_grid: GridContainer
var _add_button: Button


var _dish_sort := 0 # 0 = Star desc, 1 = Method
var _selected_dish := "" # "recipe_id|tier" key of the selected dish, or ""
var _dish_left: VBoxContainer
var _dish_sort_option: OptionButton
var _dish_left_grid: GridContainer
var _dish_info: VBoxContainer
var _d_swatch: Panel
var _d_name: Label
var _d_stars: Label
var _d_base: HBoxContainer
var _d_spices: HBoxContainer
var _d_add: Button

@export var FRIDGE_BG: Texture2D


func setup() -> void:
	_book.close_requested.connect(func() -> void: close_requested.emit())
	_build_top_bookmarks()
	_build_side_bookmarks()
	_build_left()
	_build_right()
	SignalBus.fridge_changed.connect(_refresh_left)
	SignalBus.hotbar_item_selected.connect(_on_hotbar_deposit)
	SignalBus.dish_inventory_changed.connect(_on_dish_store_changed)
	_select_tab(&"ingredients")
	_select_category(&"all")
	_book.set_background(FRIDGE_BG)

func _on_dish_store_changed() -> void:
	if _tab == &"dishes":
		_refresh_dish_left()
		_update_dish_add()

func _refresh_dish_left() -> void:
	for c in _dish_left_grid.get_children():
		c.queue_free()
	var entries := GameState.get_dish_entries() # [{recipe_id, tier, count}]
	entries.sort_custom(_sort_dishes)
	for e in entries:
		var rec := Database.get_recipe(e["recipe_id"])
		var tier := int(e["tier"])
		var key := "%s|%d" % [e["recipe_id"], tier]
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(54, 46)
		_dish_left_grid.add_child(slot)
		slot.set_item(e["recipe_id"], int(e["count"]), rec.display_name if rec else String(e["recipe_id"]), true)
		slot.set_stars(tier) # stars render on the slot, not the tooltip
		slot.slot_clicked.connect(func(_id): _select_dish(e["recipe_id"], tier))

func _sort_dishes(a: Dictionary, b: Dictionary) -> bool:
	if _dish_sort == 1: # Method: group by station, then tier desc
		var ra := Database.get_recipe(a["recipe_id"]); var rb := Database.get_recipe(b["recipe_id"])
		var sa := String(ra.station_id) if ra else ""; var sb := String(rb.station_id) if rb else ""
		if sa != sb:
			return sa < sb
	else: # Star: tier desc
		if int(a["tier"]) != int(b["tier"]):
			return int(a["tier"]) > int(b["tier"])
	if a["recipe_id"] != b["recipe_id"]:
		return String(a["recipe_id"]) < String(b["recipe_id"])
	return int(a["tier"]) > int(b["tier"])

func _select_dish(recipe_id: StringName, tier: int) -> void:
	_selected_dish = "%s|%d" % [recipe_id, tier]
	var rec := Database.get_recipe(recipe_id)
	_d_swatch.visible = true
	var sb := StyleBoxFlat.new(); sb.bg_color = ItemSlot.color_for(recipe_id); sb.set_corner_radius_all(6)
	_d_swatch.add_theme_stylebox_override("panel", sb)
	_d_name.text = rec.display_name if rec else String(recipe_id)
	_d_stars.text = "★".repeat(tier) + "  (cap %d)" % (rec.tier_cap if rec else 5)
	for c in _d_base.get_children(): c.queue_free()
	for base in CookingInfo.get_base_ingredients(recipe_id):
		var nm := Database.get_display_name(base["ref"])
		if bool(base["is_tag"]):
			nm += " (any)"
		for _i in int(base["count"]): # repeat the icon per unit (no number overlay)
			var slot: ItemSlot = ITEM_SLOT.instantiate()
			slot.custom_minimum_size = Vector2(40, 36)
			_d_base.add_child(slot)
			slot.set_item(base["ref"], 1, nm, false)
	for c in _d_spices.get_children(): c.queue_free()
	for spice_id in CookingInfo.get_compatible_spices(recipe_id):
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(40, 36)
		_d_spices.add_child(slot)
		slot.set_item(spice_id, 1, Database.get_display_name(spice_id), false)
	_update_dish_add()

func _show_empty_dish_right() -> void:
	_selected_dish = ""
	_d_swatch.visible = false
	_d_name.text = "Select a dish"
	_d_stars.text = ""
	for c in _d_base.get_children(): c.queue_free()
	for c in _d_spices.get_children(): c.queue_free()
	_d_add.disabled = true

func _update_dish_add() -> void:
	if _selected_dish == "":
		_d_add.disabled = true
		return
	var parts := _selected_dish.split("|")
	var have := int(GameState.dish_inventory.get(_selected_dish, 0))
	_d_add.disabled = have <= 0
	_d_add.text = "Add to Backpack" if have > 0 else "None of this tier left"

func _on_dish_add() -> void:
	# Dishes live in the shared dish store (no carried/fridge split) — "Add to Backpack" is a no-op
	# transfer in M1; kept for parity with the ingredient page. Dishes are consumed by feeding/
	# commissions/Fair directly. Surface a gentle note instead of moving anything.
	if _selected_dish != "":
		_d_add.text = "Dishes travel with you already"


func _build_top_bookmarks() -> void:
	for tab in [&"ingredients", &"dishes"]:
		var bm: Bookmark = BOOKMARK.instantiate()
		_book.get_top_bookmarks().add_child(bm)
		bm.setup(tab, "Ingredients" if tab == &"ingredients" else "Dishes", TAB_COLORS[tab])
		bm.selected.connect(func(id): _select_tab(StringName(id)))
		_tab_marks[tab] = bm

func _build_side_bookmarks() -> void:
	for cat in CATEGORIES:
		var bm: Bookmark = BOOKMARK.instantiate()
		_book.get_side_bookmarks().add_child(bm)
		bm.setup(cat["id"], cat["label"], cat["color"])
		bm.selected.connect(func(id): _select_category(StringName(id)))
		_cat_marks[cat["id"]] = bm

func _build_left() -> void:
	var host := _book.get_left_page()
	_ing_left = VBoxContainer.new()
	_ing_left.add_theme_constant_override("separation", 4)
	host.add_child(_ing_left)
	var hdr := Label.new(); hdr.text = "In Fridge"; hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ing_left.add_child(hdr)
	_left_grid = ITEM_GRID.instantiate()
	_ing_left.add_child(_left_grid)
	_left_grid.cell_clicked.connect(func(id): _select_ingredient(StringName(id)))
	_build_dish_left(host)


func _build_right() -> void:
	var host := _book.get_right_page()
	_ing_right = VBoxContainer.new()
	_ing_right.add_theme_constant_override("separation", 6)
	host.add_child(_ing_right)
	var sw_center := CenterContainer.new()
	_ing_right.add_child(sw_center)
	_big_swatch = Panel.new(); _big_swatch.custom_minimum_size = Vector2(64, 64)
	sw_center.add_child(_big_swatch)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 16)
	_ing_right.add_child(_name_label)
	_ing_right.add_child(HSeparator.new())
	var dlbl := Label.new(); dlbl.text = "Dishes you can make:"
	_ing_right.add_child(dlbl)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 120)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ing_right.add_child(scroll)
	_dish_grid = GridContainer.new(); _dish_grid.columns = 4
	_dish_grid.add_theme_constant_override("h_separation", 4)
	_dish_grid.add_theme_constant_override("v_separation", 4)
	_dish_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_dish_grid)
	_add_button = Button.new(); _add_button.text = "Add to Backpack"
	_add_button.pressed.connect(_on_add_to_backpack)
	_ing_right.add_child(_add_button)
	_build_dish_right(host)

	_show_empty_right()

func _stub(text: String) -> Control:
	var c := CenterContainer.new()
	var l := Label.new(); l.text = text; l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.custom_minimum_size = Vector2(220, 0); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(l)
	return c

# --- tab / category selection ---
func _select_tab(tab: StringName) -> void:
	_tab = tab
	for t in _tab_marks:
		_tab_marks[t].set_selected(t == tab)
	var on_ing := tab == &"ingredients"
	_ing_left.visible = on_ing
	_dish_left.visible = not on_ing
	_ing_right.visible = on_ing
	_dish_info.visible = not on_ing
	_book.get_side_bookmarks().visible = on_ing
	if on_ing:
		_refresh_left()
	else:
		_refresh_dish_left()
		_show_empty_dish_right()

func _select_category(cat: StringName) -> void:
	_category = cat
	for c in _cat_marks:
		_cat_marks[c].set_selected(c == cat)
	_refresh_left()

# --- left grid ---
func _refresh_left() -> void:
	if _tab != &"ingredients":
		return
	var tag := _tag_for(_category)
	var rows: Array = []
	var ids := GameState.fridge_storage.keys()
	ids.sort()
	for item_id in ids:
		if int(GameState.fridge_storage[item_id]) <= 0:
			continue
		var ing := Database.get_ingredient(item_id)
		if ing == null or (tag != &"" and not ing.tags.has(tag)):
			continue
		rows.append({"id": item_id, "count": int(GameState.fridge_storage[item_id]), "label": ing.display_name})
	_left_grid.set_items(rows, true)
	_update_add_button()

func _tag_for(cat: StringName) -> StringName:
	for c in CATEGORIES:
		if c["id"] == cat:
			return c["tag"]
	return &""


func _build_dish_left(host: Control) -> void:
	_dish_left = VBoxContainer.new()
	_dish_left.add_theme_constant_override("separation", 4)
	host.add_child(_dish_left)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	_dish_left.add_child(bar)
	var lbl := Label.new(); lbl.text = "Dishes"; lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(lbl)
	_dish_sort_option = OptionButton.new()
	_dish_sort_option.add_item("Star ★→☆", 0)
	_dish_sort_option.add_item("Method", 1)
	_dish_sort_option.item_selected.connect(func(i): _dish_sort = i; _refresh_dish_left())
	bar.add_child(_dish_sort_option)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 250)
	_dish_left.add_child(scroll)
	_dish_left_grid = GridContainer.new(); _dish_left_grid.columns = 4
	_dish_left_grid.add_theme_constant_override("h_separation", 4)
	_dish_left_grid.add_theme_constant_override("v_separation", 4)
	_dish_left_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_dish_left_grid)


# --- right info panel ---
func _select_ingredient(id: StringName) -> void:
	_selected = id
	var ing := Database.get_ingredient(id)
	_big_swatch.visible = true
	_apply_swatch(ItemSlot.color_for(id))
	_name_label.text = ing.display_name if ing else String(id)
	for c in _dish_grid.get_children():
		c.queue_free()
	for dish_id in CookingInfo.get_dishes_using(id, true):
		var rec := Database.get_recipe(dish_id)
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(52, 44)
		_dish_grid.add_child(slot)
		slot.set_item(dish_id, 1, rec.display_name if rec else String(dish_id), false)
	_update_add_button()

func _show_empty_right() -> void:
	_selected = &""
	_big_swatch.visible = false
	_name_label.text = "Select an ingredient"
	for c in _dish_grid.get_children():
		c.queue_free()
	_add_button.disabled = true

func _update_add_button() -> void:
	var n := GameState.get_fridge_count(_selected)
	_add_button.disabled = _selected == &"" or n <= 0
	_add_button.text = "Add to Backpack" if n > 0 else "None left in fridge"

func _apply_swatch(color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	_big_swatch.add_theme_stylebox_override("panel", sb)

func _build_dish_right(host: Control) -> void:
	_dish_info = VBoxContainer.new()
	_dish_info.add_theme_constant_override("separation", 6)
	host.add_child(_dish_info)
	var sw_center := CenterContainer.new(); _dish_info.add_child(sw_center)
	_d_swatch = Panel.new(); _d_swatch.custom_minimum_size = Vector2(64, 64)
	sw_center.add_child(_d_swatch)
	_d_name = Label.new(); _d_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_name.add_theme_font_size_override("font_size", 16)
	_dish_info.add_child(_d_name)
	_d_stars = Label.new(); _d_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_stars.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_dish_info.add_child(_d_stars)
	_dish_info.add_child(HSeparator.new())
	var b := Label.new(); b.text = "Base ingredients:"; _dish_info.add_child(b)
	_d_base = HBoxContainer.new(); _d_base.add_theme_constant_override("separation", 4)
	_dish_info.add_child(_d_base)
	var s := Label.new(); s.text = "Spices that raise its tier:"; _dish_info.add_child(s)
	_d_spices = HBoxContainer.new(); _d_spices.add_theme_constant_override("separation", 4)
	_dish_info.add_child(_d_spices)
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dish_info.add_child(spacer)
	_d_add = Button.new(); _d_add.text = "Add to Backpack"
	_d_add.pressed.connect(_on_dish_add)
	_dish_info.add_child(_d_add)


# --- transfer ---
func _on_add_to_backpack() -> void:
	if _selected != &"":
		GameState.withdraw_from_fridge(_selected, 1) # → carried; emits fridge_changed (+ inventory_changed → hotbar)

func _on_hotbar_deposit(item_id: String) -> void:
	GameState.deposit_to_fridge(StringName(item_id), 1) # carried → fridge
