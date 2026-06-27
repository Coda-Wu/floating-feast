extends Node
## Owns PersistentUI (a CanvasLayer that survives screen swaps) and is the ONLY bridge
## between systems and UI scenes. Listens to SignalBus and pushes updates into UI (§2.6). (§6)


const PAUSE_MENU := preload("res://scenes/ui/PauseMenu.tscn")


var _persistent_ui: CanvasLayer = null
var _hud: Control = null
var _hotbar: Control = null
var _item_tooltip: Control = null
var _resolution_panel: Control = null # IslandScreen controls its lifecycle via hide_resolution_panel()
var _open_modals: Array = [] # dedicated modals currently open (Fridge, Recipe Book, ...)
var _pause_menu: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # still hear Esc to close the menu while the tree is paused


func create_persistent_ui(parent: Node) -> void:
	if _persistent_ui != null:
		return
	var scene: PackedScene = load("res://scenes/ui/PersistentUI.tscn")
	_persistent_ui = scene.instantiate()
	parent.add_child(_persistent_ui)
	SceneRouter.register_overlay(_persistent_ui.get_transition_overlay())
	_hud = _persistent_ui.get_hud()
	_connect_hud_signals()
	_sync_hud_now()
	_hotbar = _persistent_ui.get_hotbar()
	_item_tooltip = _persistent_ui.get_item_tooltip()
	SignalBus.phase_changed.connect(_on_phase_changed)
	#SignalBus.inventory_changed.connect(_on_inventory_changed)
	_hotbar.set_active(_is_hotbar_phase(GameManager.current_phase)) # initial sync
	SignalBus.tutorial_triggered.connect(_on_tutorial_triggered)

func get_persistent_ui() -> CanvasLayer:
	return _persistent_ui

# --- HUD ---
func _connect_hud_signals() -> void:
	SignalBus.day_started.connect(_on_day_started)
	SignalBus.quest_phase_changed.connect(_on_quest_phase_changed)
	SignalBus.coins_changed.connect(_on_coins_changed)
	SignalBus.commission_activated.connect(_on_commission_changed)
	SignalBus.commission_completed.connect(_on_commission_changed)
	SignalBus.dish_cooked.connect(_on_commission_changed) # progress may have changed
	SignalBus.dish_inventory_changed.connect(_on_commission_changed)
	SignalBus.rank_changed.connect(_on_rank_changed)
	SignalBus.fuel_changed.connect(_on_fuel_changed)
	SignalBus.time_changed.connect(_on_time_changed)
	SignalBus.run_buff_applied.connect(_on_run_buff_applied)

func _sync_hud_now() -> void:
	_on_day_started(GameState.day)
	_on_quest_phase_changed(GameState.quest_phase)
	_hud.set_coins(GameState.coins)
	_refresh_commission_hud()
	_hud.set_rank(GameState.rank)
	_hud.set_fuel(GameState.fuel_current, GameState.fuel_max)
	_hud.set_time(GameState.time_minutes)
	_hud.set_buff(GameState.run_buff)

func _on_day_started(day: int) -> void:
	_hud.set_day(day)
	var weather := Database.get_weather(StringName(GameState.weather_id))
	_hud.set_weather(weather.display_name if weather else "—")


func _on_rank_changed(rank: int) -> void:
	_hud.set_rank(rank)

func _on_fuel_changed(current: int, maximum: int) -> void:
	_hud.set_fuel(current, maximum)

func _on_time_changed(minutes: int) -> void:
	_hud.set_time(minutes)

func _on_coins_changed(amount: int) -> void:
	_hud.set_coins(amount)

func _on_quest_phase_changed(_phase: int) -> void:
	_hud.set_quest(QuestManager.get_current_quest_text())

func _on_run_buff_applied(buff: Dictionary) -> void:
	_hud.set_buff(buff)
func show_hud() -> void:
	if _hud: _hud.visible = true

func hide_hud() -> void:
	if _hud: _hud.visible = false


# --- Quick Access hotbar (visible on Ship + Kitchen; mirrors carried inventory) ---
func _is_hotbar_phase(phase: int) -> bool:
	return phase == GameManager.DayPhase.SHIP or phase == GameManager.DayPhase.KITCHEN

func _on_phase_changed(phase: int) -> void:
	_hotbar.set_active(_is_hotbar_phase(phase))

# func _on_inventory_changed(_item_id: String, _count: int) -> void:
# 	_hotbar.refresh()


# --- Item-name tooltip (driven by ItemSlot hover; one shared bubble) ---
func show_item_tooltip(text: String) -> void:
	if _item_tooltip:
		_item_tooltip.show_text(text)

func hide_item_tooltip() -> void:
	if _item_tooltip:
		_item_tooltip.hide_tip()

# --- Tutorials (System -> SignalBus -> UIManager -> UI, §2.6) ---
func _on_tutorial_triggered(mechanic_id: String) -> void:
	var data := Database.get_tutorial(StringName(mechanic_id))
	if data == null:
		push_warning("UIManager: no TutorialData for '%s'" % mechanic_id)
		return # seen-flag is already set by TutorialManager; just no popup to show
	var popup = load("res://scenes/ui/TutorialPopup.tscn").instantiate()
	_persistent_ui.add_child(popup)
	popup.setup(data)
	popup.dismissed.connect(func() -> void: popup.queue_free())


# --- Day-end resolution overlay ---
func show_day_end_panel(yields: Array, on_confirm: Callable) -> void:
	var panel = load("res://scenes/ui/DayEndPanel.tscn").instantiate()
	_persistent_ui.add_child(panel)
	panel.setup(yields)
	panel.confirmed.connect(func() -> void:
		panel.queue_free()
		on_confirm.call())


# --- Cook result (terminal-cook breakdown + discovery banner; over the kitchen station bar) ---
func show_cook_result(info: Dictionary, on_dismiss: Callable = func(): pass ) -> void:
	var panel = load("res://scenes/ui/CookResultPanel.tscn").instantiate()
	_persistent_ui.add_child(panel)
	panel.setup(info)
	panel.dismissed.connect(func() -> void:
		panel.queue_free()
		on_dismiss.call())


# --- Node resolution panel (NOT auto-freed; IslandScreen hides it explicitly) ---
func show_resolution_panel(rewards: Dictionary, show_next: bool, message: String,
		exit_label: String, on_next: Callable, on_exit: Callable) -> void:
	hide_resolution_panel() # clear any stale panel
	var panel = load("res://scenes/ui/ResolutionPanel.tscn").instantiate()
	_persistent_ui.add_child(panel)
	panel.setup(rewards, show_next, message, exit_label)
	panel.next_pressed.connect(on_next)
	panel.exit_pressed.connect(on_exit)
	_resolution_panel = panel

func hide_resolution_panel() -> void:
	if is_instance_valid(_resolution_panel):
		_resolution_panel.queue_free()
	_resolution_panel = null

# --- Voluntary-exit warning (layers over the resolution panel) ---
func show_warning_popup(message: String, on_confirm: Callable, confirm_label: String = "", cancel_label: String = "") -> void:
	var popup = load("res://scenes/ui/WarningPopup.tscn").instantiate()
	_persistent_ui.add_child(popup)
	popup.setup(message, confirm_label, cancel_label)
	popup.confirmed.connect(func() -> void:
		popup.queue_free()
		on_confirm.call())
	popup.cancelled.connect(func() -> void:
		popup.queue_free())

# --- Generic notice (recipe gift / substitute reward / later: commission + Fair results) ---
func show_notice(title: String, message: String, on_dismiss: Callable = func(): pass ) -> void:
	var panel = load("res://scenes/ui/NoticePanel.tscn").instantiate()
	_persistent_ui.add_child(panel)
	panel.setup(title, message)
	panel.dismissed.connect(func() -> void:
		panel.queue_free()
		on_dismiss.call())

# --- Garden panel (opened from the ship hub) ---
func show_garden_panel() -> void:
	var panel = load("res://scenes/ui/GardenPanel.tscn").instantiate()
	_persistent_ui.add_child(panel)
	panel.setup()
	panel.close_requested.connect(func() -> void: panel.queue_free())


# --- Commission HUD (updated when an NPC asks for something, or when you cook) ---
func _on_commission_changed(_a = null, _b = null) -> void:
	_refresh_commission_hud()

func _refresh_commission_hud() -> void:
	if GameState.active_commissions.is_empty():
		_hud.set_commission("")
		return
	var c := Database.get_commission(StringName(GameState.active_commissions[0]))
	if c == null:
		_hud.set_commission("")
		return
	_hud.set_commission("◆ %s (%d/%d)" % [tr(c.title), CommissionManager.owned_count(c), c.req_quantity])


# --- modal registry (gates whether Esc may open the pause menu) ---
func register_modal(node: Node) -> void:
	if node not in _open_modals:
		_open_modals.append(node)

func unregister_modal(node: Node) -> void:
	_open_modals.erase(node)

func is_modal_open() -> bool:
	return not _open_modals.is_empty()

# --- pause menu ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _pause_menu != null:
			close_pause_menu()
		elif not is_modal_open():
			open_pause_menu()
		# else: a dedicated UI owns the screen — Esc does nothing (gating rule)
		get_viewport().set_input_as_handled()

func open_pause_menu() -> void:
	if _pause_menu != null:
		return
	_pause_menu = PAUSE_MENU.instantiate()
	add_child(_pause_menu)
	_pause_menu.close_requested.connect(close_pause_menu)
	get_tree().paused = true

func close_pause_menu() -> void:
	if _pause_menu == null:
		return
	get_tree().paused = false
	_pause_menu.queue_free()
	_pause_menu = null
