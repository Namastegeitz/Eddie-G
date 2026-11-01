class_name RunStats
extends RefCounted
## Everything that happened during one attempt at a level, plus scoring.

var level_id: StringName
var bug_id: StringName
var crumbs: int = 0
var crumbs_required: int = 0
var golden: bool = false
var time: float = 0.0
var close_calls: int = 0
var lures_used: int = 0
var threats_stunned: int = 0
var hits_taken: int = 0
var ever_alerted: bool = false
var won: bool = false
var cause: StringName = &""


func badges(par_time: float) -> Dictionary:
	return {
		"ghost": won and not ever_alerted,
		"speedrun": won and time <= par_time,
		"golden": golden,
	}


## Returns {total, lines: Array[[label, points]]}.
func score(cfg: ScoringConfig, par_time: float) -> Dictionary:
	var lines: Array = []
	lines.append(["Crumbs x%d" % crumbs, crumbs * cfg.crumb_points])
	if golden:
		lines.append(["Golden Crumb", cfg.golden_points])
	if close_calls > 0:
		lines.append(["Close calls x%d" % close_calls, close_calls * cfg.close_call_points])
	if lures_used > 0:
		lines.append(["Lures used x%d" % lures_used, lures_used * cfg.lure_points])
	if threats_stunned > 0:
		lines.append(["Threats turned x%d" % threats_stunned, threats_stunned * cfg.stun_points])
	if won and not ever_alerted:
		lines.append(["Ghost (never spotted)", cfg.ghost_bonus])
	if won and time < par_time:
		lines.append(["Under par", int((par_time - time) * cfg.speed_bonus_per_second)])
	if hits_taken > 0:
		lines.append(["Hits taken x%d" % hits_taken, -hits_taken * cfg.hit_penalty])
	var total := 0
	for l: Array in lines:
		total += int(l[1])
	return {"total": maxi(total, 0), "lines": lines}
