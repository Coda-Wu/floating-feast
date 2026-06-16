extends Node
## The thin Quest/Event seam. M1 tracks a single quest_phase int behind a stable
## API so M2 can swap in a real quest graph without touching callers. (§6)

func get_phase() -> int:
	return GameState.quest_phase

func is_phase(n: int) -> bool:
	return GameState.quest_phase == n

func advance_phase() -> void:
	GameState.quest_phase += 1
	SignalBus.quest_phase_changed.emit(GameState.quest_phase)