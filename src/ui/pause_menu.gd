extends CanvasLayer
## Universal Pause Menu — Stardew-style all-in-one screen (Backpack / Spirits / NPCs / Quests /
## Settings / Leave Game). Opened via Esc from any gameplay state; UIManager gates it and pauses the
## tree, and this scene is PROCESS_MODE_ALWAYS so it runs while paused. Step 1 = shell + tab switching;
## each tab's real content arrives in a later step. (Pause Menu §1-2)

signal close_requested

const TAB_TITLES := ["Backpack", "Spirits", "NPCs", "Quests", "Settings", "Leave Game"]
const BACKPACK_PANEL := preload("res://scenes/ui/BackpackPanel.tscn")
const SPIRITS_PANEL := preload("res://scenes/ui/SpiritsPanel.tscn")
const QUESTS_PANEL := preload("res://scenes/ui/QuestsPanel.tscn")


@onready var _tabs: HBoxContainer = $Root/Center/Frame/Margin/VBox/TopRow/Tabs
@onready var _close_button: Button = $Root/Center/Frame/Margin/VBox/TopRow/CloseButton
@onready var _content: PanelContainer = $Root/Center/Frame/Margin/VBox/Content

var _tab_buttons: Array = []
var _panels: Array[Control] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep running while get_tree().paused
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_tab_buttons = _tabs.get_children()
	for i in _tab_buttons.size():
		var btn: Button = _tab_buttons[i]
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_select_tab.bind(i))
		var panel := _make_panel(i) # later steps swap specific panels for real content
		_content.add_child(panel)
		_panels.append(panel)
	_select_tab(0)

func _make_panel(i: int) -> Control:
	# Placeholder for every tab in Step 1. Backpack/Spirits/Quests get real content in later steps;
	# NPCs/Settings/Leave stay stubs until their step.
	if i == 0: # Backpack — real content (Step 3); the other tabs stay stubs until their step
		return BACKPACK_PANEL.instantiate()
	if i == 1: # Spirits — compendium (G7)
		return SPIRITS_PANEL.instantiate()
	if i == 3: # Quests — active list + detail (Step 9)
		return QUESTS_PANEL.instantiate()

	var c := CenterContainer.new()
	var l := Label.new()
	l.text = "%s\n(coming soon)" % TAB_TITLES[i]
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(l)
	return c

func _select_tab(i: int) -> void:
	for k in _panels.size():
		_panels[k].visible = (k == i)
		_tab_buttons[k].button_pressed = (k == i)