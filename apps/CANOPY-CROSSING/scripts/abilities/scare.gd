extends Ability
## Button: startle what's near. targets "predators": up to `count` predators
## within `radius` rows lose interest for `duration` s. targets "any" with
## "push": shove the nearest mover back `push` tiles (the tomato frog's puff).


func has_button() -> bool:
	return true


func _activate() -> bool:
	var w: World = run.world
	var radius := int(p.get("radius", 3))
	var count := int(p.get("count", 99))
	if String(p.get("targets", "predators")) == "any":
		var best: Ent = null
		var best_l: Lane = null
		var best_d := 2.6
		for dr in range(0, radius + 1):
			var l: Lane = w.lane(run.row + dr)
			for e in l.ents:
				if e.platform:
					continue
				var d := absf(w.ent_x(l, e, run.wt) + e.length * 0.5 - run.x) + dr * 0.5
				if d < best_d:
					best_d = d
					best = e
					best_l = l
		if best == null:
			return false
		var away := -signf(best_l.speed) if best_l.speed != 0.0 else -1.0
		best.pushed += away * float(p.get("push", 2.0))
		run.call("_fx", "scare", {"srow": best_l.row})
		return true
	var hits := []
	for dr in range(-radius, radius + 1):
		var l2: Lane = w.lane(run.row + dr)
		for pr in l2.preds:
			if pr.kind != "swooper":
				hits.append([absi(dr), pr])
	for s in w.swoopers_near(run.row, radius):
		hits.append([0, s])
	if hits.is_empty():
		return false
	hits.sort_custom(func(a, b): return a[0] < b[0])
	var until: float = run.wt + float(p.get("duration", 3.0))
	for i in mini(count, hits.size()):
		hits[i][1]["distracted_until"] = until
	run.call("_fx", "scare", {})
	return true
