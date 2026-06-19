extends Node
## Owns PersistentUI (a CanvasLayer that survives screen swaps) and is the ONLY bridge
## between systems and UI scenes. Listens to SignalBus and pushes updates into UI (§2.6). (§6)

var _persistent_ui: CanvasLayer = null
var _hud: Control = null
var _resolution_panel: Control = null # IslandScreen controls its lifecycle via hide_resolution_panel()

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
	SignalBus.tutorial_triggered.connect(_on_tutorial_triggered)

func get_persistent_ui() -> CanvasLayer:
	return _persistent_ui

# --- HUD ---
func _connect_hud_signals() -> void:
	SignalBus.day_started.connect(_on_day_started)
	SignalBus.budget_changed.connect(_on_budget_changed)
	SignalBus.quest_phase_changed.connect(_on_quest_phase_changed)
	SignalBus.coins_changed.connect(_on_coins_changed)

func _sync_hud_now() -> void:
	_on_day_started(GameState.day)
	_on_budget_changed(GameState.budget_current, GameState.budget_max)
	_on_quest_phase_changed(GameState.quest_phase)
	_hud.set_coins(GameState.coins)

func _on_day_started(day: int) -> void:
	_hud.set_day(day)
	var weather := Database.get_weather(StringName(GameState.weather_id))
	_hud.set_weather(weather.display_name if weather else "—")

func _on_budget_changed(current: int, maximum: int) -> void:
	_hud.set_budget(current, maximum)

func _on_coins_changed(amount: int) -> void:
	_hud.set_coins(amount)

func _on_quest_phase_changed(_phase: int) -> void:
	_hud.set_quest(QuestManager.get_current_quest_text())

func show_hud() -> void:
	if _hud: _hud.visible = true

func hide_hud() -> void:
	if _hud: _hud.visible = false

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
