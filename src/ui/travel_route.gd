class_name TravelRoute extends Node2D
## Reusable Ocean-Map travel line: dashed quadratic Béziers that bend around intervening
## islands via a control-point nudge (NOT pathfinding, per §13). Draws already-sailed
## segments in full and animates the newest one growing toward its island. Custom _draw
## dashes are the gray-box form of §13's "Line2D Bézier" — same curve math, no dash texture
## needed; upgradeable to a textured Line2D later.

signal travel_finished

const SAMPLES := 30
const DASH_LEN := 7.0
const GAP_LEN := 5.0
const WIDTH := 2.5
const LINE_COLOR := Color(0.95, 0.95, 0.86, 0.9)
const HEAD_COLOR := Color(0.97, 0.86, 0.55) # the "ship" sailing the line
const HEAD_RADIUS := 4.0
const AVOID_RADIUS := 30.0 # how close to a segment an island must be to bend the curve
const ENDPOINT_SKIP := 22.0 # ignore the islands sitting at the segment's own endpoints
const MAX_OFFSET := 52.0 # clamp the nudge so the curve stays on-screen
const NUDGE_STRENGTH := 1.4
const TRAVEL_TIME := 0.55

var _committed: Array[PackedVector2Array] = [] # already-sailed segments (drawn in full)
var _active := PackedVector2Array() # the segment currently animating
var _active_len := 0.0
var _draw_len := 0.0 # how much of _active to draw (grows 0 -> len)
var _elapsed := 0.0
var _animating := false

func set_committed(waypoints: Array[Vector2], obstacles: Array[Vector2]) -> void:
	_committed.clear()
	for i in range(waypoints.size() - 1):
		_committed.append(_build_curve(waypoints[i], waypoints[i + 1], obstacles))
	queue_redraw()

func animate_to(from: Vector2, to: Vector2, obstacles: Array[Vector2]) -> void:
	_active = _build_curve(from, to, obstacles)
	_active_len = _polyline_length(_active)
	_draw_len = 0.0
	_elapsed = 0.0
	_animating = true

func _process(delta: float) -> void:
	if not _animating:
		return
	_elapsed += delta
	var t := clampf(_elapsed / TRAVEL_TIME, 0.0, 1.0)
	_draw_len = _active_len * (1.0 - pow(1.0 - t, 2.0)) # ease-out: decelerate into the island
	queue_redraw()
	if t >= 1.0:
		_animating = false
		travel_finished.emit()

func _draw() -> void:
	for poly in _committed:
		_draw_dashed(poly, _polyline_length(poly))
	if _active.size() > 1:
		_draw_dashed(_active, _draw_len)
		draw_circle(_point_at_length(_active, _draw_len), HEAD_RADIUS, HEAD_COLOR)

# --- curve building ---
func _build_curve(p0: Vector2, p2: Vector2, obstacles: Array[Vector2]) -> PackedVector2Array:
	var control := _control_point(p0, p2, obstacles)
	var pts := PackedVector2Array()
	for i in range(SAMPLES + 1):
		var t := float(i) / float(SAMPLES)
		var omt := 1.0 - t
		pts.append(omt * omt * p0 + 2.0 * omt * t * control + t * t * p2)
	return pts

func _control_point(p0: Vector2, p2: Vector2, obstacles: Array[Vector2]) -> Vector2:
	var mid := (p0 + p2) * 0.5
	var seg := p2 - p0
	if seg.length() < 1.0:
		return mid
	var normal := Vector2(-seg.y, seg.x).normalized()
	var offset := 0.0
	for c in obstacles:
		if c.distance_to(p0) < ENDPOINT_SKIP or c.distance_to(p2) < ENDPOINT_SKIP:
			continue # don't dodge the islands we're starting from / heading to
		var closest := Geometry2D.get_closest_point_to_segment(c, p0, p2)
		var d := c.distance_to(closest)
		if d < AVOID_RADIUS:
			var side := signf((c - p0).dot(normal))
			if side == 0.0:
				side = 1.0
			offset += -side * (AVOID_RADIUS - d) # push the control point to the far side
	offset = clampf(offset, -MAX_OFFSET, MAX_OFFSET)
	return mid + normal * offset * NUDGE_STRENGTH

# --- dashed drawing along cumulative arc length (dashes flow across segment joins) ---
func _draw_dashed(poly: PackedVector2Array, max_len: float) -> void:
	if poly.size() < 2 or max_len <= 0.0:
		return
	var walked := 0.0
	var phase := 0.0 # position within the dash+gap pattern
	for i in range(poly.size() - 1):
		var a := poly[i]
		var b := poly[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len <= 0.0001:
			continue
		var dir := (b - a) / seg_len
		var s := 0.0
		while s < seg_len:
			var phase_end := DASH_LEN if phase < DASH_LEN else (DASH_LEN + GAP_LEN)
			var step := minf(phase_end - phase, seg_len - s)
			if walked + step > max_len:
				step = max_len - walked
			if step <= 0.0:
				return
			if phase < DASH_LEN:
				draw_line(a + dir * s, a + dir * (s + step), LINE_COLOR, WIDTH, true)
			s += step
			walked += step
			phase += step
			if phase >= DASH_LEN + GAP_LEN:
				phase -= DASH_LEN + GAP_LEN
			if walked >= max_len:
				return

func _polyline_length(poly: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(poly.size() - 1):
		total += poly[i].distance_to(poly[i + 1])
	return total

func _point_at_length(poly: PackedVector2Array, target: float) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var walked := 0.0
	for i in range(poly.size() - 1):
		var seg := poly[i].distance_to(poly[i + 1])
		if seg > 0.0 and walked + seg >= target:
			return poly[i].lerp(poly[i + 1], (target - walked) / seg)
		walked += seg
	return poly[poly.size() - 1]