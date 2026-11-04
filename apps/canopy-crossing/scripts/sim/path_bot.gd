class_name PathBot
extends RefCounted
## Plans a crossing by searching the run's future: it clones the RunSim,
## tries each move (or waiting), and keeps the clones that are still alive.
## Hazards are pure functions of time, so this look-ahead is exact. Used by
## the tests to prove every stage can be beaten with a free starter, and by
## the autoplay demo.

const DT := 1.0 / 60.0
const DECIDE := 0.1
const MOVES := [Vector2i(0, 1), Vector2i.ZERO, Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]

var decide := DECIDE          # seconds between decisions (demo mode plays slower)
var nodes_expanded := 0
var best_row := 0
var max_nodes := 60000


## Returns the list of moves (Vector2i.ZERO = wait one decision) that reaches
## `goal_row` alive, or [] if none was found within the node budget.
func plan(sim: RunSim, goal_row: int) -> Array:
	nodes_expanded = 0
	var heap := _Heap.new()
	var start := sim.clone()
	heap.push(_score(start), [start, []])
	var seen := {}
	while heap.size() > 0 and nodes_expanded < max_nodes:
		var item: Array = heap.pop()
		var s: RunSim = item[0]
		var path: Array = item[1]
		nodes_expanded += 1
		best_row = maxi(best_row, s.row)
		for mv in MOVES:
			if mv.y < 0 and s.row <= 0:
				continue
			var c := s.clone()
			if mv != Vector2i.ZERO:
				if not c.hop(mv):
					continue
			var steps := 0
			while steps < 40:
				c.step(DT)
				steps += 1
				if c.state != "play":
					break
				if not c.hopping and steps * DT >= decide - 0.0001:
					break
			if c.state == "won" or (c.state == "play" and c.row >= goal_row and not c.hopping):
				var done := path.duplicate()
				done.append(mv)
				return done
			if c.state != "play":
				continue
			var key := "%d:%d:%d" % [c.row, int(roundf(c.x * 4.0)), int(roundf(c.t / decide))]
			if seen.has(key):
				continue
			seen[key] = true
			var np := path.duplicate()
			np.append(mv)
			heap.push(_score(c), [c, np])
	return []


func _score(s: RunSim) -> float:
	# Prefer progress, then less time spent; small bias to the middle columns.
	return float(s.row) * 10.0 - s.t * 1.2 - absf(s.x - 4.5) * 0.15


## Play a plan on a sim, returning the sim's final state.
static func replay(sim: RunSim, moves: Array) -> RunSim:
	for mv in moves:
		if mv != Vector2i.ZERO:
			sim.hop(mv)
		var steps := 0
		while steps < 40:
			sim.step(DT)
			steps += 1
			if sim.state != "play":
				return sim
			if not sim.hopping and steps * DT >= DECIDE - 0.0001:
				break
	return sim


class _Heap:
	var keys: Array[float] = []
	var vals: Array = []

	func size() -> int:
		return keys.size()

	func push(k: float, v) -> void:
		keys.append(k)
		vals.append(v)
		var i := keys.size() - 1
		while i > 0:
			var p := (i - 1) >> 1
			if keys[p] >= keys[i]:
				break
			_swap(i, p)
			i = p

	func pop():
		var top = vals[0]
		var last := keys.size() - 1
		_swap(0, last)
		keys.pop_back()
		vals.pop_back()
		var i := 0
		var n := keys.size()
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var m := i
			if l < n and keys[l] > keys[m]:
				m = l
			if r < n and keys[r] > keys[m]:
				m = r
			if m == i:
				break
			_swap(i, m)
			i = m
		return top

	func _swap(a: int, b: int) -> void:
		var tk := keys[a]
		keys[a] = keys[b]
		keys[b] = tk
		var tv = vals[a]
		vals[a] = vals[b]
		vals[b] = tv
