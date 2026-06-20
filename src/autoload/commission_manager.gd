extends Node
## Tracks active commission(s); checks dish_inventory against each requirement; runs delivery
## (consume dishes → coins + on-time bonus + story flag). Soft deadline: deliverable any day,
## the suggested day only grants an additive bonus. Authority for delivery; NpcNode is the surface.
## (§F, locked soft-deadline decision)

func activate(commission_id: StringName) -> bool:
	if GameState.active_commissions.has(String(commission_id)):
		return false
	if Database.get_commission(commission_id) == null:
		push_warning("CommissionManager: unknown commission '%s'" % commission_id)
		return false
	GameState.active_commissions.append(String(commission_id))
	SignalBus.commission_activated.emit(String(commission_id))
	return true

func get_active_for_giver(giver_npc_id: StringName) -> CommissionData:
	for cid in GameState.active_commissions:
		var c := Database.get_commission(StringName(cid))
		if c != null and c.giver_npc_id == giver_npc_id:
			return c
	return null

func owned_count(c: CommissionData) -> int:
	if c.req_dish_id != &"":
		return GameState.count_dishes(c.req_dish_id, c.req_min_tier)
	return GameState.count_dishes_by_family(c.req_family, c.req_min_tier)

func can_fulfill(c: CommissionData) -> bool:
	return owned_count(c) >= c.req_quantity

func deliver(c: CommissionData) -> Dictionary:
	# Returns { ok, coins, on_time }. Caller (NpcNode) shows the result; only called when can_fulfill.
	if not can_fulfill(c):
		return {"ok": false, "coins": 0, "on_time": false}
	var removed := (GameState.remove_dishes(c.req_dish_id, c.req_min_tier, c.req_quantity)
		if c.req_dish_id != &"" else
		GameState.remove_dishes_by_family(c.req_family, c.req_min_tier, c.req_quantity))
	if not removed:
		return {"ok": false, "coins": 0, "on_time": false}
	var on_time := c.on_time_day > 0 and GameState.day <= c.on_time_day
	var coins := c.reward_coins + (c.on_time_bonus if on_time else 0)
	GameState.add_coins(coins)
	GameState.active_commissions.erase(String(c.id))
	if c.reward_story_flag != &"":
		QuestManager.trigger_event(c.reward_story_flag)
	SignalBus.commission_completed.emit(String(c.id))
	AudioManager.play_sfx(&"commission_complete")
	return {"ok": true, "coins": coins, "on_time": on_time}