class_name IslandArranger extends RefCounted
## Places island positions for one day via rejection sampling: random points within an
## on-screen rect, keeping a min distance between islands and from the ship. Deliberately
## NOT a packing solver — gray-box correct, never hangs, cheap to upgrade later. (§13)

const VIEWPORT := Vector2(640, 360)
const MARGIN := 46.0 # keep islands fully on-screen
const MIN_ISLAND_DIST := 84.0 # spacing between island centers
const MIN_SHIP_DIST := 78.0 # keep islands clear of the ship
const MAX_ATTEMPTS := 40 # rejection-sampling tries per island

static func arrange(seed: int, count: int, ship_pos: Vector2) -> Array[Vector2]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var lo := Vector2(MARGIN, MARGIN)
	var hi := VIEWPORT - Vector2(MARGIN, MARGIN)
	var placed: Array[Vector2] = []
	for i in count:
		for attempt in MAX_ATTEMPTS:
			var p := Vector2(rng.randf_range(lo.x, hi.x), rng.randf_range(lo.y, hi.y))
			if p.distance_to(ship_pos) < MIN_SHIP_DIST:
				continue
			var ok := true
			for q in placed:
				if p.distance_to(q) < MIN_ISLAND_DIST:
					ok = false
					break
			if ok:
				placed.append(p)
				break
		# Attempts exhausted -> simply place fewer islands today. Acceptable for
		# gray-box; the arranger never hard-fails or loops forever.
	return placed