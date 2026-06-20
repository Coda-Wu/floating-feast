extends Node
## The thin Quest/Event seam. M1 tracks a single quest_phase int behind a stable API so M2 can
## swap in a real quest graph without touching callers. Maps scripted event flags to phase
## advances (idempotent) and serves gray-box objective text for the HUD. (§6)

const _QUEST_TEXT := {
	0: "Sail out and gather ingredients from the islands.",
	1: "Something's stirring past the reef — go and take a look.",
	2: "Word of your cooking is spreading. Keep the orders coming.",
}

# Scripted event flag -> the phase it advances the player to. Idempotent: an event never
# regresses the phase or fires twice. M2 replaces this with a real quest graph.
const _EVENT_PHASE := {
	&"whale_quest_started": 1,
	&"commission_1_done": 2,
}

const FAIR_PHASE := 2 # the Fair unlocks once the commission delivery advances here

func is_fair_unlocked() -> bool:
	return GameState.quest_phase >= FAIR_PHASE


func get_phase() -> int:
	return GameState.quest_phase

func is_phase(n: int) -> bool:
	return GameState.quest_phase == n

func advance_phase() -> void:
	GameState.quest_phase += 1
	SignalBus.quest_phase_changed.emit(GameState.quest_phase)

func trigger_event(flag: StringName) -> bool:
	# Returns true only the first time this event advances the phase.
	var target := int(_EVENT_PHASE.get(flag, -1))
	if target < 0:
		push_warning("QuestManager: unknown event flag '%s'" % flag)
		return false
	if GameState.quest_phase >= target:
		return false # already at/past this beat — idempotent no-op
	GameState.quest_phase = target
	SignalBus.quest_phase_changed.emit(GameState.quest_phase)
	return true

func get_current_quest_text() -> String:
	return _QUEST_TEXT.get(GameState.quest_phase, "Explore the seas.")

## Forward-unlock: grant a recipe via a scripted beat (wired into an Event/NPC node in Day 13).
## New → record + announce. Already known → conflict guard: a small substitute reward instead.
## The bespoke "you already learned this!" praise dialogue is M2. (§C.5)
func grant_recipe(recipe_id: StringName, substitute_coins: int = 25) -> void:
	var rec := Database.get_recipe(recipe_id)
	var dish_name := rec.display_name if rec else String(recipe_id).capitalize()
	if GameState.mark_recipe_known(recipe_id):
		SignalBus.recipe_discovered.emit(String(recipe_id))
		AudioManager.play_sfx(&"recipe_new")
		UIManager.show_notice("✦ New Recipe! ✦", "%s\n%s" % [dish_name, (rec.codex_path if rec else "")])
	else:
		GameState.add_coins(substitute_coins)
		AudioManager.play_sfx(&"cook_success")
		UIManager.show_notice("Already Known", "You already know how to make %s!\nHere are %d coins instead." % [dish_name, substitute_coins])