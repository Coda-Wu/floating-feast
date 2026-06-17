extends Node
## The thin Quest/Event seam. M1 tracks a single quest_phase int behind a stable
## API so M2 can swap in a real quest graph without touching callers. Also serves
## gray-box objective text for the HUD. (§6)

const _QUEST_TEXT := {
	0: "Sail out and gather ingredients from the islands.",
	1: "Something's stirring past the reef — go and take a look.",
}

func get_phase() -> int:
	return GameState.quest_phase

func is_phase(n: int) -> bool:
	return GameState.quest_phase == n

func advance_phase() -> void:
	GameState.quest_phase += 1
	SignalBus.quest_phase_changed.emit(GameState.quest_phase)

func get_current_quest_text() -> String:
	return _QUEST_TEXT.get(GameState.quest_phase, "Explore the seas.")