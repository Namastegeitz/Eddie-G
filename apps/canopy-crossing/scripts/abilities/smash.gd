extends Ability
## Button: knock the nearest obstacle ahead out of the way: a mover in this
## lane or the next two, or a brush tile in front. It's gone for one lap.


func has_button() -> bool:
	return true


func _activate() -> bool:
	var w: World = run.world
	var best: Ent = null
	var best_lane: Lane = null
	var best_d := 3.2
	for dr in [0, 1, 2]:
		var l: Lane = w.lane(run.row + dr)
		var tile: Dictionary = l.tile_at(int(floorf(run.x)))
		if dr == 1 and tile.get("kind", "") == "brush":
			l.tiles.erase(int(floorf(run.x)))
			run.call("_fx", "smash", {"tile": true, "srow": run.row + dr})
			return true
		for e in l.ents:
			if e.platform or not e.active(run.wt):
				continue
			var ex := w.ent_x(l, e, run.wt) + e.length * 0.5
			var d: float = absf(ex - run.x) + float(dr) * 0.6
			if d < best_d:
				best_d = d
				best = e
				best_lane = l
	if best == null:
		return false
	var lap := Lane.WRAP / maxf(0.3, absf(best_lane.speed)) if best_lane.speed != 0.0 else 4.0
	best.disabled_until = run.wt + minf(lap, 9.0)
	run.call("_fx", "smash", {"srow": best_lane.row})
	return true
