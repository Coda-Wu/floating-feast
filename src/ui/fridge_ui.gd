extends Control
## Fridge: browse the pantry (ingredients) and stored dishes. One shared inventory in M1, so this
## is a browse surface (no withdraw needed). The Dishes section is populated once the dish store
## exists (Day 11). Dumb view; emits close_requested. (§C.2)

signal close_requested

@onready var _ing_list: VBoxContainer = $Center/Panel/Margin/VBox/IngScroll/IngList
@onready var _dish_list: VBoxContainer = $Center/Panel/Margin/VBox/DishScroll/DishList
@onready var _close_button: Button = $Center/Panel/Margin/VBox/CloseButton

func setup() -> void:
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_populate_ingredients()
	_populate_dishes()

func _populate_ingredients() -> void:
	for c in _ing_list.get_children():
		c.queue_free()
	var ids := GameState.inventory.keys()
	ids.sort()
	if ids.is_empty():
		_ing_list.add_child(_row("(empty)"))
		return
	for item_id in ids:
		var ing := Database.get_ingredient(item_id)
		var disp := ing.display_name if ing else String(item_id)
		_ing_list.add_child(_row("%s  ×%d" % [disp, GameState.get_item_count(item_id)]))

func _populate_dishes() -> void:
	for c in _dish_list.get_children():
		c.queue_free()
	# Day 11: list GameState.dish_inventory (keyed "recipe_id|tier"). Empty until then.
	_dish_list.add_child(_row("No dishes yet — cook something! (Day 11)"))

func _row(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	return lbl