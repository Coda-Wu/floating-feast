extends Node
## Owns PersistentUI (a CanvasLayer that survives screen swaps) and is the ONLY
## bridge between systems and UI scenes. Listens to SignalBus and pushes updates
## into UI scenes (canonical flow §2.6). (§6)

var _persistent_ui: CanvasLayer = null
var _hud: Control = null

func create_persistent_ui(parent: Node) -> void:
	if _persistent_ui != null:
		return
	var scene: PackedScene = load("res://scenes/ui/PersistentUI.tscn")
	_persistent_ui = scene.instantiate()
	parent.add_child(_persistent_ui)
	SceneRouter.register_overlay(_persistent_ui.get_transition_overlay())
	_hud = _persistent_ui.get_hud()
	_connect_hud_signals()
	_sync_hud_now() # initial pull — keeps the HUD correct even if created mid-day

func get_persistent_ui() -> CanvasLayer:
	return _persistent_ui

# --- HUD: subscribe to the bus, push into the passive view ---
func _connect_hud_signals() -> void:
	SignalBus.day_started.connect(_on_day_started)
	SignalBus.budget_changed.connect(_on_budget_changed)
	SignalBus.quest_phase_changed.connect(_on_quest_phase_changed)

func _sync_hud_now() -> void:
	_on_day_started(GameState.day)
	_on_budget_changed(GameState.budget_current, GameState.budget_max)
	_on_quest_phase_changed(GameState.quest_phase)

func _on_day_started(day: int) -> void:
	_hud.set_day(day)
	var weather := Database.get_weather(StringName(GameState.weather_id))
	_hud.set_weather(weather.display_name if weather else "—")

func _on_budget_changed(current: int, maximum: int) -> void:
	_hud.set_budget(current, maximum)

func _on_quest_phase_changed(_phase: int) -> void:
	_hud.set_quest(QuestManager.get_current_quest_text())

func show_hud() -> void:
	if _hud:
		_hud.visible = true

func hide_hud() -> void:
	if _hud:
		_hud.visible = false

# --- Day-end resolution overlay ---
func show_day_end_panel(yields: Array, on_confirm: Callable) -> void:
	var panel = load("res://scenes/ui/DayEndPanel.tscn").instantiate() # untyped: setup/confirmed not on Control
	_persistent_ui.add_child(panel) # _ready runs here -> @onready vars resolve
	panel.setup(yields)
	panel.confirmed.connect(func() -> void:
		panel.queue_free()
		on_confirm.call()
	)

# --- Filled in Step 5 ---
func show_resolution_panel(rewards) -> void: pass
func show_warning_popup(message: String, on_confirm: Callable) -> void: pass