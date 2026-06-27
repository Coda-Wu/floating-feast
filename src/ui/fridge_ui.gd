extends Control
## Fridge — open-book layout. Top bookmarks switch Ingredients/Dishes. LEFT page = paginated grids
## (never scrolls); RIGHT page = info panel (scrolls if long). Ingredient page: category side-bookmarks
## filter stored ingredients; selecting one shows its info + the discovered dishes it makes, with Add
## to Backpack (withdraw); deposit by clicking a hotbar item. Dish page: tier-separated dish slots
## (stars on the slot) + sort dropdown; selecting shows base ingredients + compatible spices as icons.
## (Parts 1-2, P-4 + polish)

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
const DISH_COLS := 4
const DISH_ROWS := 3
const DISH_PER_PAGE := DISH_COLS * DISH_ROWS

@onready var _book: BookFrame = $BookFrame

var _tab: StringName = &"ingredients"
var _category: StringName = &"all"
var _selected: StringName = &""
var _selected_dish := ""
var _dish_sort := 0
var _dish_page := 0
var _tab_marks := {}
var _cat_marks := {}

# ingredient page
var _ing_left: VBoxContainer
var _left_grid: ItemGrid
var _ing_right: VBoxContainer
var _big_swatch: Panel
var _name_label: Label
var _dish_grid: GridContainer
var _add_button: Button
# dish page
var _dish_left: VBoxContainer
var _dish_sort_option: OptionButton
var _dish_grid_left: GridContainer
var _dish_prev: Button
var _dish_next: Button
var _dish_page_label: Label
var _dish_info: VBoxContainer
var _d_swatch: Panel
var _d_name: Label
var _d_stars: Label
var _d_base: HBoxContainer
var _d_spices: HBoxContainer
var _d_add: Button

func setup() -> void:
	_book.close_requested.connect(func() -> void: close_requested.emit())
	_book.get_left_page().alignment = BoxContainer.ALIGNMENT_BEGIN # top-pack the pages
	_book.get_right_page().alignment = BoxContainer.ALIGNMENT_BEGIN
	_build_top_bookmarks()
	_build_side_bookmarks()
	_build_left()
	_build_right()
	SignalBus.fridge_changed.connect(_refresh_left)
	SignalBus.dish_inventory_changed.connect(_on_dish_store_changed)
	SignalBus.hotbar_item_selected.connect(_on_hotbar_deposit)
	_select_tab(&"ingredients")
	_select_category(&"all")

func _build_top_bookmarks() -> void:
	for tab in [&"ingredients", &"dishes"]:
		var bm: Bookmark = BOOKMARK.instantiate()
		_book.get_top_bookmarks().add_child(bm)
		bm.setup(tab, tr("Ingredients") if tab == &"ingredients" else tr("Dishes"), TAB_COLORS[tab])
		bm.selected.connect(func(id): _select_tab(StringName(id)))
		_tab_marks[tab] = bm

func _build_side_bookmarks() -> void:
	for cat in CATEGORIES:
		var bm: Bookmark = BOOKMARK.instantiate()
		_book.get_side_bookmarks().add_child(bm)
		bm.setup(cat["id"], tr(cat["label"]), cat["color"])
		bm.selected.connect(func(id): _select_category(StringName(id)))
		_cat_marks[cat["id"]] = bm

func _build_left() -> void:
	var host := _book.get_left_page()
	_ing_left = VBoxContainer.new()
	_ing_left.add_theme_constant_override("separation", 4)
	host.add_child(_ing_left)
	var hdr := Label.new(); hdr.text = tr("In Fridge"); hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ing_left.add_child(hdr)
	_left_grid = ITEM_GRID.instantiate()
	var ing_center := CenterContainer.new()
	ing_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ing_center.add_child(_left_grid)
	_ing_left.add_child(ing_center)
	_left_grid.cell_clicked.connect(func(id): _select_ingredient(StringName(id)))
	_build_dish_left(host)

func _build_dish_left(host: Control) -> void:
	_dish_left = VBoxContainer.new()
	_dish_left.add_theme_constant_override("separation", 4)
	host.add_child(_dish_left)
	var bar := HBoxContainer.new(); bar.add_theme_constant_override("separation", 6)
	_dish_left.add_child(bar)
	var lbl := Label.new(); lbl.text = tr("Dishes"); lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(lbl)
	_dish_sort_option = OptionButton.new()
	_dish_sort_option.add_item(tr("Star ★→☆"), 0)
	_dish_sort_option.add_item(tr("Method"), 1)
	_dish_sort_option.item_selected.connect(func(i): _dish_sort = i; _dish_page = 0; _refresh_dish_left())
	bar.add_child(_dish_sort_option)
	_dish_grid_left = GridContainer.new(); _dish_grid_left.columns = DISH_COLS
	_dish_grid_left.add_theme_constant_override("h_separation", 4)
	_dish_grid_left.add_theme_constant_override("v_separation", 4)
	var dish_center := CenterContainer.new()
	dish_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dish_center.add_child(_dish_grid_left)
	_dish_left.add_child(dish_center)
	var nav := HBoxContainer.new(); nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 8)
	_dish_left.add_child(nav)
	_dish_prev = Button.new(); _dish_prev.text = "◀"; _dish_prev.focus_mode = Control.FOCUS_NONE
	_dish_page_label = Label.new(); _dish_page_label.text = "1/1"
	_dish_next = Button.new(); _dish_next.text = "▶"; _dish_next.focus_mode = Control.FOCUS_NONE
	_dish_prev.pressed.connect(func(): _dish_page -= 1; _refresh_dish_left())
	_dish_next.pressed.connect(func(): _dish_page += 1; _refresh_dish_left())
	nav.add_child(_dish_prev); nav.add_child(_dish_page_label); nav.add_child(_dish_next)

func _build_right() -> void:
	var host := _book.get_right_page()
	_ing_right = VBoxContainer.new()
	_ing_right.add_theme_constant_override("separation", 6)
	host.add_child(_ing_right)
	var sw_center := CenterContainer.new(); _ing_right.add_child(sw_center)
	_big_swatch = Panel.new(); _big_swatch.custom_minimum_size = Vector2(56, 56)
	sw_center.add_child(_big_swatch)
	_name_label = Label.new(); _name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_name_label.custom_minimum_size = Vector2(160, 0)
	_ing_right.add_child(_name_label)
	_ing_right.add_child(HSeparator.new())
	var dlbl := Label.new(); dlbl.text = tr("Dishes you can make:")
	_ing_right.add_child(dlbl)
	_dish_grid = GridContainer.new(); _dish_grid.columns = 4
	_dish_grid.add_theme_constant_override("h_separation", 4)
	_dish_grid.add_theme_constant_override("v_separation", 4)
	_ing_right.add_child(_dish_grid)
	_add_button = Button.new(); _add_button.text = tr("Add to Backpack")
	_add_button.pressed.connect(_on_add_to_backpack)
	_ing_right.add_child(_add_button)
	_build_dish_right(host)
	_show_empty_right()

func _build_dish_right(host: Control) -> void:
	_dish_info = VBoxContainer.new()
	_dish_info.add_theme_constant_override("separation", 6)
	host.add_child(_dish_info)
	var sw_center := CenterContainer.new(); _dish_info.add_child(sw_center)
	_d_swatch = Panel.new(); _d_swatch.custom_minimum_size = Vector2(56, 56)
	sw_center.add_child(_d_swatch)
	_d_name = Label.new(); _d_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_name.add_theme_font_size_override("font_size", 15)
	_d_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	_d_name.custom_minimum_size = Vector2(160, 0)
	_dish_info.add_child(_d_name)
	_d_stars = Label.new(); _d_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_stars.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_dish_info.add_child(_d_stars)
	_dish_info.add_child(HSeparator.new())
	var b := Label.new(); b.text = tr("Base ingredients:"); _dish_info.add_child(b)
	_d_base = HBoxContainer.new(); _d_base.add_theme_constant_override("separation", 4)
	_dish_info.add_child(_d_base)
	var s := Label.new(); s.text = tr("Spices that raise its tier:"); _dish_info.add_child(s)
	_d_spices = HBoxContainer.new(); _d_spices.add_theme_constant_override("separation", 4)
	_dish_info.add_child(_d_spices)
	_d_add = Button.new(); _d_add.text = tr("Add to Backpack")
	_d_add.pressed.connect(_on_dish_add)
	_dish_info.add_child(_d_add)

# --- tab / category ---
func _select_tab(tab: StringName) -> void:
	_tab = tab
	for t in _tab_marks:
		_tab_marks[t].set_selected(t == tab)
	var on_ing := tab == &"ingredients"
	_ing_left.visible = on_ing
	_dish_left.visible = not on_ing
	_ing_right.visible = on_ing
	_dish_info.visible = not on_ing
	for c in _cat_marks:
		_cat_marks[c].visible = on_ing
	if on_ing:
		_refresh_left()
	else:
		_dish_page = 0
		_refresh_dish_left()
		_show_empty_dish_right()

func _select_category(cat: StringName) -> void:
	if _tab != &"ingredients":
		return
	_category = cat
	for c in _cat_marks:
		_cat_marks[c].set_selected(c == cat)
	_refresh_left()

# --- ingredient left grid ---
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
		rows.append({"id": item_id, "count": int(GameState.fridge_storage[item_id]), "label": tr(ing.display_name)})
	_left_grid.set_items(rows, true)
	_update_add_button()

func _tag_for(cat: StringName) -> StringName:
	for c in CATEGORIES:
		if c["id"] == cat:
			return c["tag"]
	return &""

# --- ingredient right info ---
func _select_ingredient(id: StringName) -> void:
	_selected = id
	var ing := Database.get_ingredient(id)
	_big_swatch.visible = true
	_apply_swatch(_big_swatch, ItemSlot.color_for(id))
	_name_label.text = tr(ing.display_name) if ing else String(id)
	for c in _dish_grid.get_children():
		c.queue_free()
	for dish_id in CookingInfo.get_dishes_using(id, true):
		var rec := Database.get_recipe(dish_id)
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(46, 40)
		_dish_grid.add_child(slot)
		slot.set_item(dish_id, 1, tr(rec.display_name) if rec else String(dish_id), false)
	_update_add_button()

func _show_empty_right() -> void:
	_selected = &""
	_big_swatch.visible = false
	_name_label.text = tr("Select an ingredient")
	for c in _dish_grid.get_children():
		c.queue_free()
	_add_button.disabled = true

func _update_add_button() -> void:
	var n := GameState.get_fridge_count(_selected)
	_add_button.disabled = _selected == &"" or n <= 0
	_add_button.text = tr("Add to Backpack") if n > 0 else tr("None left in fridge")

# --- dish left grid (paginated) ---
func _on_dish_store_changed() -> void:
	if _tab == &"dishes":
		_refresh_dish_left()
		_update_dish_add()

func _refresh_dish_left() -> void:
	for c in _dish_grid_left.get_children():
		c.queue_free()
	var entries := GameState.get_dish_entries()
	entries.sort_custom(_sort_dishes)
	var page_count := maxi(1, ceili(float(entries.size()) / float(DISH_PER_PAGE)))
	_dish_page = clampi(_dish_page, 0, page_count - 1)
	var start := _dish_page * DISH_PER_PAGE
	for i in range(start, mini(start + DISH_PER_PAGE, entries.size())):
		var e = entries[i]
		var rec := Database.get_recipe(e["recipe_id"])
		var tier := int(e["tier"])
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(42, 36)
		_dish_grid_left.add_child(slot)
		slot.set_item(e["recipe_id"], int(e["count"]), tr(rec.display_name) if rec else String(e["recipe_id"]), true)
		slot.set_stars(tier)
		slot.slot_clicked.connect(func(_id, rid = e["recipe_id"], t = tier): _select_dish(rid, t))
	_dish_prev.disabled = _dish_page <= 0
	_dish_next.disabled = _dish_page >= page_count - 1
	_dish_page_label.text = "%d/%d" % [_dish_page + 1, page_count]

func _sort_dishes(a: Dictionary, b: Dictionary) -> bool:
	if _dish_sort == 1:
		var ra := Database.get_recipe(a["recipe_id"]); var rb := Database.get_recipe(b["recipe_id"])
		var sa := String(ra.station_id) if ra else ""; var sb := String(rb.station_id) if rb else ""
		if sa != sb:
			return sa < sb
	else:
		if int(a["tier"]) != int(b["tier"]):
			return int(a["tier"]) > int(b["tier"])
	if a["recipe_id"] != b["recipe_id"]:
		return String(a["recipe_id"]) < String(b["recipe_id"])
	return int(a["tier"]) > int(b["tier"])

# --- dish right info ---
func _select_dish(recipe_id: StringName, tier: int) -> void:
	_selected_dish = "%s|%d" % [recipe_id, tier]
	var rec := Database.get_recipe(recipe_id)
	_d_swatch.visible = true
	_apply_swatch(_d_swatch, ItemSlot.color_for(recipe_id))
	_d_name.text = tr(rec.display_name) if rec else String(recipe_id)
	_d_stars.text = "★".repeat(tier) + tr("  (cap %d)") % (rec.tier_cap if rec else 5)
	for c in _d_base.get_children(): c.queue_free()
	for base in CookingInfo.get_base_ingredients(recipe_id):
		var nm := tr(Database.get_display_name(base["ref"]))
		if bool(base["is_tag"]):
			nm += tr(" (any)")
		for _i in int(base["count"]):
			var slot: ItemSlot = ITEM_SLOT.instantiate()
			slot.custom_minimum_size = Vector2(36, 32)
			_d_base.add_child(slot)
			slot.set_item(base["ref"], 1, nm, false)
	for c in _d_spices.get_children(): c.queue_free()
	for spice_id in CookingInfo.get_compatible_spices(recipe_id):
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(36, 32)
		_d_spices.add_child(slot)
		slot.set_item(spice_id, 1, tr(Database.get_display_name(spice_id)), false)
	_update_dish_add()

func _show_empty_dish_right() -> void:
	_selected_dish = ""
	_d_swatch.visible = false
	_d_name.text = tr("Select a dish")
	_d_stars.text = ""
	for c in _d_base.get_children(): c.queue_free()
	for c in _d_spices.get_children(): c.queue_free()
	_d_add.disabled = true

func _update_dish_add() -> void:
	if _selected_dish == "":
		_d_add.disabled = true
		return
	var have := int(GameState.dish_inventory.get(_selected_dish, 0))
	_d_add.disabled = have <= 0
	_d_add.text = tr("Add to Backpack") if have > 0 else tr("None of this tier left")

func _on_dish_add() -> void:
	if _selected_dish != "":
		_d_add.text = tr("Dishes travel with you already") # single dish store (no transfer) — parity note

# --- shared / transfer ---
func _apply_swatch(panel: Panel, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)

func _on_add_to_backpack() -> void:
	if _selected != &"":
		GameState.withdraw_from_fridge(_selected, 1)

func _on_hotbar_deposit(item_id: String) -> void:
	GameState.deposit_to_fridge(StringName(item_id), 1)
