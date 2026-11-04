extends Node
## Journey progress, records, the daily reward, the daily challenge and the
## Expedition Pass (season reward track). Rules come from content files.

signal changed

var day_override := -1


func today() -> int:
	if day_override >= 0:
		return day_override
	var d := Time.get_date_dict_from_system()
	return int(Time.get_unix_time_from_datetime_dict({"year": d.year, "month": d.month, "day": d.day,
		"hour": 0, "minute": 0, "second": 0}) / 86400)


func day_of(date_string: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(date_string + "T00:00:00") / 86400)


# ------------------------------------------------------------------ journey

func stages_cleared(map_id: String) -> int:
	return int(Save.map_progress(map_id).get("cleared", 0))


func stage_unlocked(map_id: String, index: int) -> bool:
	return index <= stages_cleared(map_id)


func map_complete(map_id: String) -> bool:
	return stages_cleared(map_id) >= Content.map(map_id).get("stages", []).size()


## Next region in map order after this one (for the milestone prompt).
func next_map(map_id: String) -> String:
	var order := Content.playable_maps()
	var i := order.find(map_id)
	if i >= 0 and i + 1 < order.size():
		return order[i + 1]
	return ""


## Store a finished run. Returns {"new_best": bool, "stage_cleared": bool, "xp": int}.
func record_run(r: Dictionary) -> Dictionary:
	var out := {"new_best": false, "stage_cleared": false, "xp": 0}
	var map_id := String(r.map)
	var mp := Save.map_progress(map_id)
	var stats: Dictionary = Save.data.stats
	stats.runs = int(stats.get("runs", 0)) + 1
	stats.rows = int(stats.get("rows", 0)) + int(r.rows)
	stats.collected = int(stats.get("collected", 0)) + int(r.get("collected", 0))
	stats.best_combo = maxi(int(stats.get("best_combo", 0)), int(r.get("best_combo", 0)))
	if r.get("cause", "") != "":
		var deaths: Dictionary = stats.get("deaths", {})
		deaths[r.cause] = int(deaths.get(r.cause, 0)) + 1
		stats.deaths = deaths
	match String(r.mode):
		"journey":
			var sb: Dictionary = mp.get("stage_best", {})
			var key := str(r.stage)
			if int(r.score) > int(sb.get(key, 0)):
				sb[key] = int(r.score)
				out.new_best = true
			mp.stage_best = sb
			if r.won and int(r.stage) >= int(mp.cleared):
				mp.cleared = int(r.stage) + 1
				out.stage_cleared = true
		"endless":
			if int(r.rows) > int(mp.best_rows):
				mp.best_rows = int(r.rows)
				out.new_best = true
			mp.best_score = maxi(int(mp.best_score), int(r.score))
		"daily":
			var dc: Dictionary = Save.data.daily_challenge
			if int(dc.get("day", -1)) != today():
				dc.day = today()
				dc.best = 0
				dc.rewarded = false
			if int(r.rows) > int(dc.best):
				dc.best = int(r.rows)
				out.new_best = true
	var season := pass_def()
	var xpr: Dictionary = season.get("xp", {"per_row": 1})
	var xp := int(r.rows) * int(xpr.get("per_row", 1)) + int(r.get("collected", 0)) * int(xpr.get("per_collectible", 0))
	if r.get("won", false):
		xp += int(xpr.get("stage_clear", 30))
	if r.mode == "daily":
		xp += int(xpr.get("daily_challenge", 40)) if not Save.data.daily_challenge.get("xp_given", false) else 0
		Save.data.daily_challenge["xp_given"] = true
	if r.mode != "tutorial":
		add_pass_xp(xp)
	out.xp = xp
	Save.mark()
	changed.emit()
	return out


func best_rows(map_id: String) -> int:
	return int(Save.map_progress(map_id).get("best_rows", 0))


# ------------------------------------------------------------------ daily reward

func daily_reward_ready() -> bool:
	return int(Save.data.daily.get("last_day", -1)) != today()


func daily_reward_index() -> int:
	var d: Dictionary = Save.data.daily
	var streak := int(d.get("streak", 0))
	if int(d.get("last_day", -1)) != today() - 1 and int(d.get("last_day", -1)) != today():
		streak = 0
	var cycle: Array = Content.daily_rewards.get("cycle", [])
	if cycle.is_empty():
		return 0
	return streak % cycle.size()


func daily_reward() -> Dictionary:
	var cycle: Array = Content.daily_rewards.get("cycle", [])
	if cycle.is_empty():
		return {}
	return cycle[daily_reward_index()]


func claim_daily_reward() -> Dictionary:
	if not daily_reward_ready():
		return {}
	var entry := daily_reward()
	var d: Dictionary = Save.data.daily
	var continuing := int(d.get("last_day", -1)) == today() - 1
	d.streak = (int(d.get("streak", 0)) + 1) if continuing else 1
	d.last_day = today()
	Economy.give_reward(entry.get("reward", {}), "daily_reward")
	Analytics.event("daily_reward", {"day": entry.get("day", 0)})
	Save.mark()
	changed.emit()
	return entry


# ------------------------------------------------------------------ daily challenge

func daily_challenge() -> Dictionary:
	var maps := Content.playable_maps()
	if maps.is_empty():
		return {}
	var day := today()
	return {"map": maps[absi(hash(["daily_map", day])) % maps.size()], "seed": absi(hash(["daily_seed", day])) % 1000000, "day": day}


func daily_best() -> int:
	var dc: Dictionary = Save.data.daily_challenge
	return int(dc.get("best", 0)) if int(dc.get("day", -1)) == today() else 0


# ------------------------------------------------------------------ season pass

func current_season() -> Dictionary:
	var seasons: Array = Content.live_ops.get("seasons", [])
	var day := today()
	var best: Dictionary = {}
	for s in seasons:
		if day_of(String(s.start)) <= day and day <= day_of(String(s.end)):
			return s
		if day_of(String(s.start)) <= day:
			best = s
	if best.is_empty() and not seasons.is_empty():
		best = seasons[0]
	return best


func pass_def() -> Dictionary:
	return Content.season(String(current_season().get("pass", "")))


func season_days_left() -> int:
	var s := current_season()
	if s.is_empty():
		return 0
	return maxi(0, day_of(String(s.end)) - today() + 1)


func _sync_pass() -> Dictionary:
	var sid := String(current_season().get("id", ""))
	var p: Dictionary = Save.data.pass
	if String(p.get("season", "")) != sid:
		Save.data.pass = {"season": sid, "xp": 0, "premium": false, "claimed_free": [], "claimed_premium": []}
		Save.mark()
	return Save.data.pass


func pass_xp() -> int:
	return int(_sync_pass().xp)


func pass_tier() -> int:
	var def := pass_def()
	var per := int(def.get("xp_per_tier", 120))
	return mini(def.get("tiers", []).size(), pass_xp() / maxi(1, per))


func add_pass_xp(n: int) -> void:
	var p := _sync_pass()
	p.xp = int(p.xp) + maxi(0, n)
	Save.mark()
	changed.emit()


func is_premium() -> bool:
	return bool(_sync_pass().get("premium", false))


func set_premium() -> void:
	var p := _sync_pass()
	p.premium = true
	Save.mark()
	changed.emit()


func can_claim(tier: int, track: String) -> bool:
	var p := _sync_pass()
	if tier > pass_tier():
		return false
	if track == "premium" and not p.premium:
		return false
	return not has_int(p.get("claimed_" + track, []), tier)


## JSON numbers come back as floats: compare tier numbers by value.
static func has_int(list: Array, v: int) -> bool:
	for x in list:
		if int(x) == v:
			return true
	return false


func claim(tier: int, track: String) -> Dictionary:
	if not can_claim(tier, track):
		return {}
	var def := pass_def()
	for t in def.get("tiers", []):
		if int(t.tier) == tier:
			var r: Dictionary = t.get(track, {})
			var p := _sync_pass()
			p["claimed_" + track].append(tier)
			Economy.give_reward(r, "pass_%s_%d" % [track, tier])
			Analytics.event("pass_claim", {"tier": tier, "track": track})
			Save.mark()
			changed.emit()
			return r
	return {}


func claimable_count() -> int:
	var n := 0
	for t in range(1, pass_tier() + 1):
		if can_claim(t, "free"):
			n += 1
		if can_claim(t, "premium"):
			n += 1
	return n
