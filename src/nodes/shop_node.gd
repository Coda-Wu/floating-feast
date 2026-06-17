extends ExplorationNode
## Buy-menu node (and the Butchery, via a different stock_id param). Lists a ShopStock; Buy →
## coins down, item → inventory immediately (§9). Completes empty (purchases already landed).
## Reads GameState.coins directly — no coins signal yet (2c). Visiting = 1 node = 1 Time (§4.1).

@onready var _title: Label = $Center/Panel/Margin/VBox/Title
@onready var _coins_label: Label = $Center/Panel/Margin/VBox/CoinsLabel
@onready var _entry_list: VBoxContainer = $Center/Panel/Margin/VBox/EntryList
@onready var _leave_button: Button = $Center/Panel/Margin/VBox/LeaveButton

var _rows: Array = [] # [{ id, price, buy_button, bought_label, count }]

func _run() -> void:
	var stock_id: StringName = node_def.params.get("stock_id", &"")
	_title.text = "Butchery" if stock_id == &"stock_butchery" else "Island Shop"
	_leave_button.pressed.connect(func() -> void: complete({}))
	var stock := Database.get_shop_stock(stock_id)
	if stock == null:
		push_warning("ShopNode: no stock for id '%s'" % stock_id)
		_refresh_coins()
		return
	for entry in stock.entries:
		_add_entry_row(entry["ingredient_id"], int(entry["price"]))
	_refresh_coins()
	_refresh_buttons()

func _add_entry_row(ingredient_id: StringName, price: int) -> void:
	var ing := Database.get_ingredient(ingredient_id)
	var disp := ing.display_name if ing else String(ingredient_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name_label := Label.new()
	name_label.text = "%s — %d c" % [disp, price]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bought_label := Label.new()
	var buy_button := Button.new()
	buy_button.text = "Buy"
	row.add_child(name_label)
	row.add_child(bought_label)
	row.add_child(buy_button)
	_entry_list.add_child(row)
	var rec := {"id": ingredient_id, "price": price, "buy_button": buy_button, "bought_label": bought_label, "count": 0}
	buy_button.pressed.connect(_on_buy.bind(rec))
	_rows.append(rec)

func _on_buy(rec: Dictionary) -> void:
	if not GameState.try_spend_coins(int(rec["price"])):
		return
	GameState.add_item(rec["id"], 1)
	rec["count"] = int(rec["count"]) + 1
	rec["bought_label"].text = "×%d" % rec["count"]
	_refresh_coins()
	_refresh_buttons()

func _refresh_coins() -> void:
	_coins_label.text = "Coins: %d" % GameState.coins

func _refresh_buttons() -> void:
	for rec in _rows:
		rec["buy_button"].disabled = GameState.coins < int(rec["price"])