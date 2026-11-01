class_name ScentTrail
extends RefCounted
## Ring buffer of scent points the player leaves behind. Points decay over
## time and grow stronger when the player lingers. The dog follows the trail;
## water and vinegar wipe it. No allocations per frame.

var cfg: StealthConfig
var positions: PackedVector3Array
var strengths: PackedFloat32Array
var stamps: PackedInt32Array
var _head := 0
var _count := 0
var _stamp := 0
var _last_drop := Vector3.INF


func _init(c: StealthConfig) -> void:
	cfg = c
	positions.resize(cfg.scent_max_points)
	strengths.resize(cfg.scent_max_points)
	stamps.resize(cfg.scent_max_points)
	clear()


func clear() -> void:
	for i in strengths.size():
		strengths[i] = 0.0
		stamps[i] = -1
	_head = 0
	_count = 0
	_last_drop = Vector3.INF


func update(pos: Vector3, delta: float, active: bool) -> void:
	var decay := cfg.scent_decay * delta
	for i in strengths.size():
		if strengths[i] > 0.0:
			strengths[i] = maxf(strengths[i] - decay, 0.0)
	if not active:
		return
	if _last_drop == Vector3.INF or pos.distance_to(_last_drop) >= cfg.scent_drop_distance:
		positions[_head] = pos
		strengths[_head] = 1.0
		_stamp += 1
		stamps[_head] = _stamp
		_head = (_head + 1) % positions.size()
		_count = mini(_count + 1, positions.size())
		_last_drop = pos
	else:
		var last := (_head - 1 + positions.size()) % positions.size()
		strengths[last] = minf(strengths[last] + cfg.scent_linger_gain * delta, cfg.scent_max_strength)


func wipe_sphere(center: Vector3, radius: float) -> void:
	var r2 := radius * radius
	for i in positions.size():
		if strengths[i] > 0.0 and positions[i].distance_squared_to(center) <= r2:
			strengths[i] = 0.0
	if _last_drop != Vector3.INF and _last_drop.distance_squared_to(center) <= r2:
		_last_drop = Vector3.INF


func active_count() -> int:
	var n := 0
	for s in strengths:
		if s > cfg.scent_min_strength:
			n += 1
	return n


## Newest point fresher than `after_stamp` within `radius` of `from`.
## Returns the buffer index or -1. Jumping to the newest reachable point lets
## a tracker cut corners like a real nose would.
func next_point(from: Vector3, radius: float, after_stamp: int) -> int:
	var best := -1
	var best_stamp := after_stamp
	var r2 := radius * radius
	for i in positions.size():
		if strengths[i] > cfg.scent_min_strength and stamps[i] > best_stamp \
				and positions[i].distance_squared_to(from) <= r2:
			best = i
			best_stamp = stamps[i]
	return best


## Strongest point within radius (used to pick up a cold trail). -1 if none.
func strongest_near(from: Vector3, radius: float) -> int:
	var best := -1
	var best_s := cfg.scent_min_strength
	var r2 := radius * radius
	for i in positions.size():
		if strengths[i] > best_s and positions[i].distance_squared_to(from) <= r2:
			best = i
			best_s = strengths[i]
	return best
