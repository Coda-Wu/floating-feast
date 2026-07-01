extends VBoxContainer
## Quests tab — the current main-quest objective + active commissions (list → detail). Read-only.
## (Pause Menu WP-A)

@onready var _objective: Label = $ObjectiveLabel
@onready var _list: VBoxContainer = $Body/CommissionList
@onready var _title: Label = $Body/Detail/TitleLabel
@onready var _detail: Label = $Body/Detail/DetailLabel
@onready var _req: Label = $Body/Detail/ReqLabel
@onready var _progress: Label = $Body/Detail/ProgressLabel
@onready var _reward: Label = $Body/Detail/RewardLabel

var _commissions: Array = [] # CommissionData

func _ready() -> void:
	_objective.text = tr("Objective: %s") % QuestManager.get_current_quest_text()
	for cid in GameState.active_commissions:
		var c := Database.get_commission(StringName(cid))
		if c != null:
			_commissions.append(c)
	for i in _commissions.size():
		var c: CommissionData = _commissions[i]
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "%s  (%d/%d)" % [tr(c.title), CommissionManager.owned_count(c), c.req_quantity]
		btn.pressed.connect(_show_detail.bind(i))
		_list.add_child(btn)
	if _commissions.is_empty():
		_show_empty()
	else:
		_show_detail(0)

func _show_empty() -> void:
	_title.text = tr("No active commissions.")
	for lbl in [_detail, _req, _progress, _reward]:
		lbl.text = ""

func _show_detail(i: int) -> void:
	var c: CommissionData = _commissions[i]
	_title.text = tr(c.title)
	_detail.text = tr(c.detail)
	_req.text = _requirement_text(c)
	_progress.text = tr("Progress: %d / %d") % [CommissionManager.owned_count(c), c.req_quantity]
	_reward.text = _reward_text(c)

func _requirement_text(c: CommissionData) -> String:
	var what := Database.get_display_name(c.req_dish_id) if c.req_dish_id != &"" else String(c.req_family).capitalize()
	if c.req_min_tier > 1:
		return tr("Deliver %d × %s (Tier %d+)") % [c.req_quantity, what, c.req_min_tier]
	return tr("Deliver %d × %s") % [c.req_quantity, what]

func _reward_text(c: CommissionData) -> String:
	var s := tr("Reward: %d coins") % c.reward_coins
	if c.on_time_day > 0 and c.on_time_bonus > 0:
		s += "\n" + (tr("On-time bonus: +%d (by day %d)") % [c.on_time_bonus, c.on_time_day])
	return s
