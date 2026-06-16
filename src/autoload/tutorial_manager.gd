extends Node
## First-time pop-ups. try_show(id) fires once, records the "seen" flag in
## GameState, and respects a master `enabled` switch. The visual popup is shown
## via UIManager (wired later); the gating logic is real now. (§6)

var enabled: bool = true # master switch — set false to suppress all tutorials

func try_show(mechanic_id: String) -> void:
	if not enabled:
		return
	if GameState.seen_tutorials.has(mechanic_id):
		return
	GameState.seen_tutorials[mechanic_id] = true
	SignalBus.tutorial_triggered.emit(mechanic_id)
	# Later: UIManager shows the TutorialData popup for `mechanic_id`.

func reset_seen(mechanic_id: String) -> void:
	GameState.seen_tutorials.erase(mechanic_id)