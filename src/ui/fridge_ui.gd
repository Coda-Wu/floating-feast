extends Control
## Fridge: storage for carried ingredients + a view of stored dishes. Two tabs (Ingredients / Dishes).
## Ingredients tab shows fridge ⇄ backpack as two grids; tapping a cell transfers one unit (the
## GameState mutators emit, so both grids + the hotbar refresh). Dishes tab displays dish_inventory
## read-only (dishes don't transfer in M1). Dumb view; emits close_requested. (Inventory-UX UX-2)

signal close_requested

@onready var _ing_tab: Button = $Center/Frame/Margin/VBox/Tabs/IngTab
@onready var _dish_tab: Button = $Center/Frame/Margin/VBox/Tabs/DishTab
@onready var _ing_page: HBoxContainer = $Center/Frame/Margin/VBox/IngPage
@onready var _dish_page: VBoxContainer = $Center/Frame/Margin/VBox/DishPage
@onready var _fridge_grid: ItemGrid = $Center/Frame/Margin/VBox/IngPage/FridgeSide/FridgeGrid
@onready var _carried_grid: ItemGrid = $Center/Frame/Margin/VBox/IngPage/CarriedSide/CarriedGrid
@onready var _dish_grid: ItemGrid = $Center/Frame/Margin/VBox/DishPage/DishGrid
@onready var _close_button: Button = $Center/Frame/Margin/VBox/CloseButton

func setup() -> void:
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_ing_tab.pressed.connect(_show_ingredients)
	_dish_tab.pressed.connect(_show_dishes)
	_fridge_grid.cell_clicked.connect(_on_fridge_cell) # fridge → backpack (withdraw)
	_carried_grid.cell_clicked.connect(_on_carried_cell) # backpack → fridge (deposit)
	SignalBus.fridge_changed.connect(_refresh_ingredients)
	SignalBus.inventory_changed.connect(func(_a, _b): _refresh_ingredients())
	_show_ingredients()

func _show_ingredients() -> void:
	_ing_page.visible = true
	_dish_page.visible = false
	_ing_tab.button_pressed = true
	_dish_tab.button_pressed = false
	_refresh_ingredients()

func _show_dishes() -> void:
	_ing_page.visible = false
	_dish_page.visible = true
	_ing_tab.button_pressed = false
	_dish_tab.button_pressed = true
	_refresh_dishes()

func _refresh_ingredients() -> void:
	_fridge_grid.set_items(_ingredient_rows(GameState.fridge_storage), true)
	_carried_grid.set_items(_ingredient_rows(GameState.inventory), true)

func _refresh_dishes() -> void:
	var rows: Array = []
	for e in GameState.get_dish_entries():
		var rec := Database.get_recipe(e["recipe_id"])
		var disp := rec.display_name if rec else String(e["recipe_id"])
		rows.append({"id": e["recipe_id"], "count": int(e["count"]),
			"label": "%s %s" % [disp, "★".repeat(int(e["tier"]))]})
	_dish_grid.set_items(rows, false) # display-only

func _ingredient_rows(store: Dictionary) -> Array:
	var ids := store.keys()
	ids.sort()
	var rows: Array = []
	for item_id in ids:
		if int(store[item_id]) <= 0:
			continue
		rows.append({"id": item_id, "count": int(store[item_id]), "label": Database.get_display_name(item_id)})
	return rows

func _on_fridge_cell(item_id: String) -> void:
	GameState.withdraw_from_fridge(StringName(item_id), 1)

func _on_carried_cell(item_id: String) -> void:
	GameState.deposit_to_fridge(StringName(item_id), 1)