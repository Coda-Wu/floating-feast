extends ExplorationNode
## NPC node (stub dialogue) + commission delivery surface. If this NPC (params.giver_id) has a
## fulfillable active commission, show Deliver → CommissionManager runs it → warm result. The manager
## is the authority; this node only renders. Tutorial: commission. M2: Dialogic. (§9, §F)

@onready var _name_label: Label = $Center/Panel/Margin/VBox/NameLabel
@onready var _text_label: Label = $Center/Panel/Margin/VBox/TextLabel
@onready var _continue_button: Button = $Center/Panel/Margin/VBox/ContinueButton

const _DEFAULT_LINES := [
	"Fair winds today! Caught anything tasty out there?",
	"Welcome, traveler. The spirits hereabouts are a shy bunch.",
	"A cook, are you? You'll find good pickings on these isles.",
]

var _giver_id: StringName
var _commission: CommissionData

func _run() -> void:
	_giver_id = node_def.params.get("giver_id", &"")
	var text := String(node_def.params.get("text", ""))
	if text.is_empty():
		text = _DEFAULT_LINES[randi() % _DEFAULT_LINES.size()]
	_name_label.text = "Islander"
	_text_label.text = text
	_continue_button.pressed.connect(func() -> void: complete({}))
	if _giver_id != &"":
		_commission = CommissionManager.get_active_for_giver(_giver_id)
	if _commission != null:
		TutorialManager.try_show("commission")
		_add_commission_ui()

func _add_commission_ui() -> void:
	var box := _continue_button.get_parent()
	var status := Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD
	status.custom_minimum_size = Vector2(300, 0)
	var owned := CommissionManager.owned_count(_commission)
	status.text = "» %s: %s (have %d/%d)" % [_commission.title, _commission.detail, owned, _commission.req_quantity]
	box.add_child(status)
	box.move_child(status, _continue_button.get_index()) # above Continue
	if CommissionManager.can_fulfill(_commission):
		var deliver := Button.new()
		deliver.text = "Deliver  (%d dishes)" % _commission.req_quantity
		deliver.pressed.connect(_on_deliver)
		box.add_child(deliver)
		box.move_child(deliver, _continue_button.get_index())
		_deliver_button = deliver

var _deliver_button: Button

func _on_deliver() -> void:
	var result := CommissionManager.deliver(_commission)
	if not result["ok"]:
		return
	if is_instance_valid(_deliver_button):
		_deliver_button.queue_free()
	var bonus := "  (+%d on-time bonus!)" % _commission.on_time_bonus if result["on_time"] else ""
	_text_label.text = "Wonderful — exactly what I needed! Here's %d coins.%s" % [result["coins"], bonus]