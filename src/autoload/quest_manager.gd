extends Node
## The thin Quest/Event seam. M1 tracks a single quest_phase int behind a stable API so M2 can
## swap in a real quest graph without touching callers. Maps scripted event flags to phase
## advances (idempotent) and serves gray-box objective text for the HUD. (§6)

const _QUEST_TEXT := {
	0: "Sail out and gather ingredients from the islands.",
	1: "Something's stirring past the reef — go and take a look.",
}

# Scripted event flag -> the phase it advances the player to. Idempotent: an event never
# regresses the phase or fires twice. M2 replaces this with a real quest graph.
const _EVENT_PHASE := {
	&"whale_quest_started": 1,
}

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