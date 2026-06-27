extends Control
## Recipe Book — open-book codex mirroring the Fridge. LEFT page: known dishes (base recipe only,
## not tier-split) + sort dropdown; fits without scrolling. RIGHT page: the dish's icon + name, its
## cooking steps as visual rows ([ingredient icons] → [station icon] → [output icon], quantity by
## repeated icons), and a compatible-spice row; scrolls if long/wide. Reads CookingInfo. (P-3, P-4)

signal close_requested

const ITEM_SLOT := preload("res://scenes/ui/ItemSlot.tscn")

const STATION_COLORS := {
	&"prep": Color(0.80, 0.72, 0.55), &"mix_bowl": Color(0.62, 0.78, 0.60), &"oven": Color(0.78, 0.45, 0.35),
}
const STATION_NAMES := {&"prep": "Prep", &"mix_bowl": "Mixing Bowl", &"oven": "Oven"}

@onready var _book: BookFrame = $BookFrame

var _sort := 0
var _selected: StringName = &""
var _left_grid: GridContainer
var _sort_option: OptionButton
var _right: VBoxContainer
var _r_swatch: Panel
var _r_name: Label
var _steps_box: VBoxContainer
var _spice_row: HBoxContainer

func setup() -> void:
	_book.close_requested.connect(func() -> void: close_requested.emit())
	_book.get_left_page().alignment = BoxContainer.ALIGNMENT_BEGIN # top-pack (fixes content sitting low)
	_book.get_right_page().alignment = BoxContainer.ALIGNMENT_BEGIN
	_build_left()
	_build_right()
	SignalBus.recipe_discovered.connect(func(_id): _refresh_left())
	_refresh_left()
	_show_empty_right()

func _build_left() -> void:
	var host := _book.get_left_page()
	var col := VBoxContainer.new(); col.add_theme_constant_override("separation", 4)
	host.add_child(col)
	var bar := HBoxContainer.new(); bar.add_theme_constant_override("separation", 6)
	col.add_child(bar)
	var lbl := Label.new(); lbl.text = tr("Recipes"); lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(lbl)
	_sort_option = OptionButton.new()
	_sort_option.add_item(tr("Tier ★→☆"), 0)
	_sort_option.add_item(tr("Method"), 1)
	_sort_option.item_selected.connect(func(i): _sort = i; _refresh_left())
	bar.add_child(_sort_option)
	_left_grid = GridContainer.new(); _left_grid.columns = 4
	_left_grid.add_theme_constant_override("h_separation", 4)
	_left_grid.add_theme_constant_override("v_separation", 4)
	col.add_child(_left_grid)

func _build_right() -> void:
	var host := _book.get_right_page()
	_right = VBoxContainer.new(); _right.add_theme_constant_override("separation", 6)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(_right)
	var sw_center := CenterContainer.new(); _right.add_child(sw_center)
	_r_swatch = Panel.new(); _r_swatch.custom_minimum_size = Vector2(52, 52)
	sw_center.add_child(_r_swatch)
	_r_name = Label.new(); _r_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_r_name.add_theme_font_size_override("font_size", 15)
	_r_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	_r_name.custom_minimum_size = Vector2(160, 0)
	_right.add_child(_r_name)
	_right.add_child(HSeparator.new())
	var steps_lbl := Label.new(); steps_lbl.text = tr("How to cook it:")
	_right.add_child(steps_lbl)
	_steps_box = VBoxContainer.new(); _steps_box.add_theme_constant_override("separation", 6)
	_right.add_child(_steps_box)
	_right.add_child(HSeparator.new())
	var spice_lbl := Label.new(); spice_lbl.text = tr("Spices to raise its tier:")
	_right.add_child(spice_lbl)
	_spice_row = HBoxContainer.new(); _spice_row.add_theme_constant_override("separation", 4)
	_right.add_child(_spice_row)

func _refresh_left() -> void:
	for c in _left_grid.get_children():
		c.queue_free()
	var recipes: Array = []
	for rec: RecipeData in Database.get_all_recipes():
		if GameState.is_recipe_known(rec.id):
			recipes.append(rec)
	recipes.sort_custom(_sort_recipes)
	for rec in recipes:
		var slot: ItemSlot = ITEM_SLOT.instantiate()
		slot.custom_minimum_size = Vector2(46, 40)
		_left_grid.add_child(slot)
		slot.set_item(rec.id, 1, tr(rec.display_name), true)
		slot.slot_clicked.connect(func(_id, r = rec.id): _select_recipe(r))
	if recipes.is_empty():
		var none := Label.new(); none.text = tr("No recipes learned yet.")
		_left_grid.add_child(none)

func _sort_recipes(a: RecipeData, b: RecipeData) -> bool:
	if _sort == 1:
		if a.station_id != b.station_id:
			return String(a.station_id) < String(b.station_id)
	else:
		if a.tier_cap != b.tier_cap:
			return a.tier_cap > b.tier_cap
	return a.display_name < b.display_name

func _select_recipe(recipe_id: StringName) -> void:
	_selected = recipe_id
	var rec := Database.get_recipe(recipe_id)
	_r_swatch.visible = true
	var sb := StyleBoxFlat.new(); sb.bg_color = ItemSlot.color_for(recipe_id); sb.set_corner_radius_all(6)
	_r_swatch.add_theme_stylebox_override("panel", sb)
	_r_name.text = (tr(rec.display_name) if rec else String(recipe_id)) + (tr("  (cap %d★)") % rec.tier_cap if rec else "")
	_build_steps(recipe_id)
	_build_spices(recipe_id)

func _build_steps(recipe_id: StringName) -> void:
	for c in _steps_box.get_children():
		c.queue_free()
	for step in CookingInfo.get_recipe_steps(recipe_id):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		for inp in step["inputs"]:
			var nm := tr(Database.get_display_name(inp["ref"]))
			if bool(inp["is_tag"]):
				nm += tr(" (any)")
			for _i in int(inp["count"]):
				row.add_child(_icon(inp["ref"], nm))
		row.add_child(_arrow())
		row.add_child(_station_icon(step["station_id"]))
		row.add_child(_arrow())
		row.add_child(_icon(step["output_id"], tr(Database.get_display_name(step["output_id"]))))
		_steps_box.add_child(row)

func _build_spices(recipe_id: StringName) -> void:
	for c in _spice_row.get_children():
		c.queue_free()
	var spices := CookingInfo.get_compatible_spices(recipe_id)
	if spices.is_empty():
		var none := Label.new(); none.text = tr("(none)")
		_spice_row.add_child(none)
		return
	for spice_id in spices:
		_spice_row.add_child(_icon(spice_id, tr(Database.get_display_name(spice_id))))

func _show_empty_right() -> void:
	_selected = &""
	_r_swatch.visible = false
	_r_name.text = tr("Select a recipe")
	for c in _steps_box.get_children(): c.queue_free()
	for c in _spice_row.get_children(): c.queue_free()

func _icon(ref: StringName, tip: String, sz := Vector2(34, 30)) -> ItemSlot:
	var slot: ItemSlot = ITEM_SLOT.instantiate()
	slot.custom_minimum_size = sz
	slot.set_item(ref, 1, tip, false)
	return slot

func _station_icon(station_id: StringName) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(34, 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = STATION_COLORS.get(station_id, Color(0.5, 0.5, 0.5))
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.25, 0.20, 0.14)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var nm := tr(String(STATION_NAMES.get(station_id, station_id)))
	p.mouse_entered.connect(func() -> void: UIManager.show_item_tooltip(nm))
	p.mouse_exited.connect(func() -> void: UIManager.hide_item_tooltip())
	return p

func _arrow() -> Label:
	var l := Label.new()
	l.text = "→"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
