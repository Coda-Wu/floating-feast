extends Node
## The controller: a top-level DayPhase state machine that owns day-cycle rules
## (budget reset at day start, day-end trigger) and asks SceneRouter to change
## screens. Transitions + routing wired in Step 3. (§5, §6)

enum DayPhase {MORNING, OCEAN_MAP, ISLAND, SHIP, DAY_END}

var current_phase: DayPhase = DayPhase.MORNING

func start_day() -> void:
	# Step 3: reset budget, emit day_started + budget_changed, enter MORNING.
	pass

func change_phase(next: DayPhase) -> void:
	# Step 3: validate the transition, ask SceneRouter for the matching screen.
	current_phase = next

func end_day() -> void:
	# Step 3: DayEndPanel -> confirm -> in-memory save -> day++ -> start_day().
	pass