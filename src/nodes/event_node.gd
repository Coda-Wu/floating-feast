extends ExplorationNode
## Event node (stub): fires a scripted quest flag via QuestManager, then continues. The seam
## for the mission-island beat; M2 layers Dialogic + the recipe-discovery beat on top. (§9)

@onready var _text_label: Label = $Center/Panel/Margin/VBox/TextLabel
@onready var _continue_button: Button = $Center/Panel/Margin/VBox/ContinueButton

func _run() -> void:
	var flag: StringName = node_def.params.get("flag", &"")
	var advanced := false
	if flag != &"":
		advanced = QuestManager.trigger_event(flag)
	var to_activate: StringName = node_def.params.get("activate_commission", &"") # ADD
	if to_activate != &"": # ADD
		CommissionManager.activate(to_activate) # ADD
	_text_label.text = tr("The objective updates...") if advanced else tr("You sense something has shifted here.")
	_continue_button.pressed.connect(func() -> void: complete({}))
