extends Node
## Scene flow, race requests for every mode, and what happens after a race:
## Race Credits, stars, unlocks, cup standings, boss unlocks, time trial medals,
## daily challenge streaks and achievements.

var tuning: Tuning
var request := {}
var cup_state := {}
var last_results: Array = []
var last_summary := {}
var menu_hint := ""
var detected_quality := "high"
var _rng := RandomNumberGenerator.new()

signal orientation_changed

const DAILY_MODS := [
	{"id": "ice_age", "name": "Ice Age", "text": "Every surface is slippery.", "mods": {"grip": 0.55}},
	{"id": "power_hungry", "name": "Power Hungry", "text": "Cores drain twice as fast; pods give 50% more.", "mods": {"drain": 2.0, "pod": 1.5}},
	{"id": "comet_shower", "name": "Comet Shower", "text": "Every crate holds a Comet Strike.", "mods": {"only_item": "comet"}},
	{"id": "moon_bounce", "name": "Moon Bounce", "text": "Low gravity everywhere: big air, big tricks.", "mods": {"gravity": 0.5}},
	{"id": "warp_speed", "name": "Warp Speed", "text": "Everyone flies 12% faster.", "mods": {"speed": 1.12}},
	{"id": "rocket_storm", "name": "Rocket Storm", "text": "Crates only give Homing Rockets.", "mods": {"only_item": "rocket"}},
	{"id": "laser_tag", "name": "Laser Tag", "text": "Crates only give Pulse Lasers. Line up your shots!", "mods": {"only_item": "laser"}},
	{"id": "nitro_rush", "name": "Nitro Rush", "text": "Crates only give Nitro Rockets.", "mods": {"only_item": "nitro"}},
	{"id": "shield_wall", "name": "Clean Race", "text": "Crates only give Ion Shields: pure racing.", "mods": {"only_item": "shield"}},
]
const DAILY_GOALS := [
	{"id": "win", "text": "Win the race"},
	{"id": "pods", "text": "Finish top 3 with 12+ Energy Pods"},
	{"id": "purple", "text": "Finish top 3 with 3 purple drift boosts"},
	{"id": "tricks", "text": "Finish top 3 and land 5 tricks"},
	{"id": "no_hover", "text": "Finish top 3 without Emergency Hover"},
	{"id": "slips", "text": "Finish top 3 and slipstream 3 times"},
]
const TT_PACE := [40.0, 45.0, 49.0]   # average m/s for bronze / silver / gold


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tuning = load("res://resources/tuning.tres")
	get_tree().root.size_changed.connect(fit_orientation)
	fit_orientation()
	detected_quality = Gfx.detect()
	# On phones and in browsers, if a frame runs long don't pile up physics
	# steps to catch up (that turns one slow frame into a stutter).
	if OS.has_feature("web") or OS.has_feature("mobile"):
		Engine.max_physics_steps_per_frame = 3


## The UI is designed on a 1280x720 canvas that scales to fit the screen.
## A phone held upright (a browser can't lock to landscape) would squeeze
## 1280 units into the narrow side and shrink every control to a third, so
## in portrait the canvas becomes 720x1280 instead: buttons, text and the
## HUD keep their size, and screens lay themselves out for the tall shape.
static func portrait_window() -> bool:
	var w := DisplayServer.window_get_size()
	return w.y > w.x and w.x > 0


func fit_orientation() -> void:
	var want := Vector2i(720, 1280) if portrait_window() else Vector2i(1280, 720)
	var win := get_window()
	if win.content_scale_size != want:
		win.content_scale_size = want
		orientation_changed.emit()


func quality() -> String:
	var q: String = Save.setting("quality")
	if q == "auto" or not (q in Gfx.TIERS):
		return detected_quality
	return q


# ---------------------------------------------------------------- fields
func player_entry(slot: int) -> Dictionary:
	var look: Dictionary
	if slot == 0:
		look = Save.player_look()
	else:
		var p2: Dictionary = Save.data.garage.get("p2", {})
		var pid: String = p2.get("pilot", "nova")
		if pid == Save.data.garage.pilot:
			pid = "zib" if pid != "zib" else "nova"
		look = Save.look_for(p2.get("saucer", "bubble"), pid)
	return {"look": look, "upgrades": Save.upgrades_for(look.saucer), "human": true, "slot": slot}


func _field(exclude: Array, count: int, ai_class: int, seed_v: int) -> Array:
	_rng.seed = seed_v
	var pool: Array = []
	for p in Catalog.PILOTS:
		if not (p.id in exclude):
			pool.append(p)
	# Shuffle deterministically.
	for i in range(pool.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: Variant = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var cls: Dictionary = Catalog.AI_CLASSES[clampi(ai_class, 0, 3)]
	var out: Array = []
	for k in count:
		var p: Dictionary = pool[k % pool.size()]
		var max_s := clampi(2 + ai_class, 2, Catalog.SAUCERS.size())
		var sc: Dictionary = Catalog.SAUCERS[_rng.randi_range(0, max_s - 1)]
		var lvl := ai_class + (1 if _rng.randf() < 0.4 else 0)
		var up := {}
		for st in Catalog.STAT_KEYS:
			up[st] = clampi(lvl, 0, 5)
		var paint: Dictionary = Catalog.PAINTS[_rng.randi_range(0, Catalog.PAINTS.size() - 1)]
		var trail: Dictionary = Catalog.TRAILS[_rng.randi_range(0, Catalog.TRAILS.size() - 1)]
		var decal: Dictionary = Catalog.DECALS[_rng.randi_range(0, Catalog.DECALS.size() - 1)]
		out.append({"look": {"saucer": sc.id, "pilot": p.id, "paint": paint.id, "decal": decal.id, "dome": "clear", "trail": trail.id},
			"upgrades": up, "human": false, "style": p.style,
			"skill": clampf(float(cls.skill) + _rng.randf_range(-0.08, 0.06), 0.2, 1.0), "speed": cls.speed})
	return out


func quick_request(track: String, variant: int, ai_class: int) -> Dictionary:
	var me := player_entry(0)
	var racers: Array = [me]
	racers.append_array(_field([me.look.pilot], 7, ai_class, Time.get_ticks_usec()))
	return {"mode": "quick", "track": track, "variant": variant, "ai_class": ai_class, "racers": racers}


func versus_request(track: String, variant: int, ai_class: int) -> Dictionary:
	var p1 := player_entry(0)
	var p2 := player_entry(1)
	var racers: Array = [p1, p2]
	racers.append_array(_field([p1.look.pilot, p2.look.pilot], 6, ai_class, Time.get_ticks_usec()))
	return {"mode": "versus", "track": track, "variant": variant, "ai_class": ai_class, "racers": racers}


func tt_request(track: String, variant: int) -> Dictionary:
	return {"mode": "tt", "track": track, "variant": variant, "ai_class": 0, "racers": [player_entry(0)]}


func boss_request(pilot_id: String) -> Dictionary:
	var p := Catalog.pilot(pilot_id)
	var me := player_entry(0)
	var boss := {"look": {"saucer": _boss_saucer(pilot_id), "pilot": pilot_id, "paint": "stock", "decal": "stars", "dome": "smoke", "trail": "gold"},
		"upgrades": {"speed": 2, "accel": 2, "handling": 2, "efficiency": 2}, "human": false, "style": p.style, "skill": 0.92, "speed": 0.99}
	return {"mode": "boss", "track": p.home, "variant": 0, "ai_class": 2, "boss": pilot_id, "boss_edge": 1.0, "racers": [me, boss]}


func _boss_saucer(pilot_id: String) -> String:
	match pilot_id:
		"krell":
			return "mothership"
		"vexa":
			return "manta"
		"comet":
			return "rocket"
		"zorba":
			return "ring"
		"bleep":
			return "classic"
	return "bubble"


func cup_request(cup_id: String, race_i: int) -> Dictionary:
	var cup := cup_def(cup_id)
	if race_i == 0 or cup_state.get("cup", "") != cup_id:
		var me := player_entry(0)
		cup_state = {"cup": cup_id, "race": 0, "points": {}, "field": _field([me.look.pilot], 7, int(cup["class"]), Time.get_ticks_usec()), "places": []}
	elif int(cup_state.get("snap_race", -1)) == race_i:
		# Retrying a race: undo the points it gave.
		cup_state.points = cup_state.snap.duplicate()
		cup_state.places = cup_state.snap_places.duplicate()
	cup_state["snap"] = cup_state.points.duplicate()
	cup_state["snap_places"] = cup_state.places.duplicate()
	cup_state["snap_race"] = race_i
	cup_state.race = race_i
	var r: Array = cup.races[race_i]
	var racers: Array = [player_entry(0)]
	racers.append_array(cup_state.field)
	return {"mode": "cup", "cup": cup_id, "cup_race": race_i, "track": r[0], "variant": r[1], "challenge": r[2],
		"ai_class": cup["class"], "racers": racers}


func cup_def(cup_id: String) -> Dictionary:
	for c in Catalog.CUPS:
		if c.id == cup_id:
			return c
	return Catalog.CUPS[0]


func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


func daily_info(date := "") -> Dictionary:
	if date == "":
		date = today()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("csd-daily-" + date)
	var track: String = Catalog.TRACK_IDS[rng.randi_range(0, Catalog.TRACK_IDS.size() - 1)]
	var variant := 1 if rng.randf() < 0.3 else 0
	var mod: Dictionary = DAILY_MODS[rng.randi_range(0, DAILY_MODS.size() - 1)]
	var goal: Dictionary = DAILY_GOALS[rng.randi_range(0, DAILY_GOALS.size() - 1)]
	var streak := int(Save.data.daily.streak)
	var reward := 400 + 60 * mini(streak, 7)
	return {"date": date, "track": track, "variant": variant, "mod": mod, "goal": goal, "reward": reward,
		"done": Save.data.daily.last_done == date}


func daily_request() -> Dictionary:
	var info := daily_info()
	var me := player_entry(0)
	var racers: Array = [me]
	racers.append_array(_field([me.look.pilot], 7, clampi(int(Save.setting("difficulty")), 0, 3), hash(info.date)))
	return {"mode": "daily", "track": info.track, "variant": info.variant, "ai_class": Save.setting("difficulty"),
		"daily": info, "mods": info.mod.mods, "racers": racers}


# ---------------------------------------------------------------- flow
func start(req: Dictionary) -> void:
	request = req
	InputRouter.two_player = req.get("mode", "") == "versus"
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/race.tscn")


func restart() -> void:
	if request.mode == "cup":
		start(cup_request(request.cup, request.cup_race))
	else:
		var r := request.duplicate(true)
		start(r)


func go_menu(hint := "") -> void:
	menu_hint = hint
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func pause_menu(race: Node) -> Control:
	return PauseMenu.make(race)


# ---------------------------------------------------------------- after a race
func on_race_finished(race: Node, results: Array) -> void:
	last_results = results
	var req: Dictionary = race.req
	var me: Dictionary = {}
	for r in results:
		if r.human and r.slot == 0:
			me = r
	var summary := {"mode": req.mode, "lines": [], "credits": 0, "stars": 0, "unlocks": [], "achievements": [], "place": 0}
	if me.is_empty():
		last_summary = summary
		race.show_panel(ResultsScreen.make(race, results, summary))
		return
	var place: int = me.place
	var st: Dictionary = me.stats
	summary.place = place
	var td: TrackData = race.td
	# Career stats.
	Save.stat_add("races", 1)
	Save.stat_add("distance", st.dist)
	Save.stat_add("drift_dist", st.drift_dist)
	Save.stat_add("tricks", st.tricks)
	Save.stat_add("pods", st.pods)
	Save.stat_add("hits", st.hits)
	Save.stat_add("items", st.items)
	Save.stat_add("purple", st.purple)
	Save.stat_add("slips", st.slips)
	Save.stat_add("near", st.near)
	Save.stat_add("shortcuts", st.shortcuts)
	Save.stat_max("top_speed", st.top * 3.6)
	if place <= 3:
		Save.stat_add("podiums", 1)
	if place == 1 and req.mode != "tt":
		Save.stat_add("wins", 1)
		Save.mark_won(td.id, td.variant)
		if td.variant == Catalog.V_MIRROR:
			Save.stat_add("mirror_wins", 1)
	var bl: float = st.get("best_lap", INF)
	var key := "%s:%d" % [td.id, td.variant]
	if bl < float(Save.data.best_lap.get(key, INF)):
		Save.data.best_lap[key] = bl
	# Race Credits.
	var mult := 1.0
	match req.mode:
		"tt", "versus":
			mult = 0.5
		"boss":
			mult = 0.0
	var base := int(float(Catalog.PLACE_REWARD[clampi(place - 1, 0, 7)]) * mult)
	if req.mode == "tt":
		base = 100
	_line(summary, "%s place" % UiKit.ordinal(place) if req.mode != "tt" else "Time trial run", base)
	_line(summary, "Energy Pods x%d" % st.pods, st.pods * 2)
	_line(summary, "Tricks x%d" % st.tricks, st.tricks * 5)
	_line(summary, "Item hits x%d" % st.hits, st.hits * 10)
	match req.mode:
		"cup":
			_after_cup(req, me, summary)
		"boss":
			_after_boss(req, place, summary)
		"tt":
			_after_tt(req, me, td, summary)
		"daily":
			_after_daily(req, me, summary)
	if req.mode != "tt" and place == 1:
		var won_key := "%s:%d" % [td.id, td.variant]
		if td.variant == 0 and not Save.data.get("_told_" + won_key, false):
			Save.data["_told_" + won_key] = true
			summary.unlocks.append("Reverse + Mirror %s unlocked" % td.name)
	Save.add_credits(summary.credits)
	Save.data.ads.races = int(Save.data.ads.races) + 1
	summary.achievements = Achievements.check(st, place, req)
	Save.flush()
	last_summary = summary
	Events.log_event("race_finish", {"mode": req.mode, "track": td.id, "variant": td.variant, "place": place, "time": me.time})
	race.show_panel(ResultsScreen.make(race, results, summary))


func _line(summary: Dictionary, text: String, amount: int) -> void:
	if amount <= 0:
		return
	summary.lines.append([text, amount])
	summary.credits += amount


func challenge_met(ch_id: String, me: Dictionary, results: Array) -> bool:
	if not Catalog.CHALLENGES.has(ch_id):
		return false
	var c: Array = Catalog.CHALLENGES[ch_id]
	var st: Dictionary = me.stats
	match ch_id:
		"no_hover":
			return int(st.hover_count) == 0
		"margin2":
			if me.place != 1 or results.size() < 2:
				return false
			return float(results[1].time) - float(me.time) >= 2.0
	return float(st.get(c[1], 0)) >= float(c[2])


func _after_cup(req: Dictionary, me: Dictionary, summary: Dictionary) -> void:
	var cup := cup_def(req.cup)
	var place: int = me.place
	var mask := 0
	if place <= 3:
		mask |= 1
	if place == 1:
		mask |= 2
	var ch_ok := challenge_met(req.challenge, me, last_results)
	if ch_ok:
		mask |= 4
	var before := Save.total_stars()
	var gained := Save.add_race_stars(req.cup, req.cup_race, mask)
	summary.stars = gained
	summary["star_mask"] = mask
	summary["challenge"] = Catalog.CHALLENGES[req.challenge][0]
	summary["challenge_ok"] = ch_ok
	if gained > 0:
		_line(summary, "New stars x%d" % gained, gained * 50)
	# Cup points.
	for r in last_results:
		var pts: int = Catalog.CUP_POINTS[clampi(int(r.place) - 1, 0, 7)]
		var k := str(r.idx)
		cup_state.points[k] = int(cup_state.points.get(k, 0)) + pts
	cup_state.places.append(place)
	summary["cup_points"] = cup_state.points.duplicate()
	summary["cup_last"] = req.cup_race == cup.races.size() - 1
	if summary.cup_last:
		var order: Array = cup_state.points.keys()
		order.sort_custom(func(a: String, b: String) -> bool: return int(cup_state.points[a]) > int(cup_state.points[b]))
		var cup_place := order.find(str(me.idx)) + 1
		summary["cup_place"] = cup_place
		var best := int(Save.data.cup_best.get(req.cup, 99))
		if cup_place < best:
			Save.data.cup_best[req.cup] = cup_place
		if cup_place <= 3:
			var prize: int = [1500, 900, 600][cup_place - 1]
			_line(summary, "%s trophy" % ["Gold", "Silver", "Bronze"][cup_place - 1], prize)
			Save.stat_add("cups_podium", 1)
			if cup_place == 1:
				Save.stat_add("cups_won", 1)
		Events.log_event("cup_complete", {"cup": req.cup, "place": cup_place})
	_unlock_messages(before, summary)


func _unlock_messages(before: int, summary: Dictionary) -> void:
	var now := Save.total_stars()
	for c in Catalog.CUPS:
		if int(c.stars) > before and int(c.stars) <= now:
			summary.unlocks.append("%s unlocked!" % c.name)
	for p in Catalog.PILOTS:
		if p.unlock == "boss" and int(p.stars) > before and int(p.stars) <= now:
			summary.unlocks.append("Boss race: %s is ready to race you" % p.name)
	for s in Catalog.SAUCERS:
		if int(s.stars) > before and int(s.stars) <= now and int(s.stars) > 0:
			summary.unlocks.append("%s can now be bought in the Garage" % s.name)


func _after_boss(req: Dictionary, place: int, summary: Dictionary) -> void:
	var p := Catalog.pilot(req.boss)
	if place == 1:
		var first: bool = not Save.data.bosses.get(req.boss, false)
		Save.data.bosses[req.boss] = true
		Save.unlock_pilot(req.boss)
		if first:
			_line(summary, "Beat %s" % p.name, 500)
			summary.unlocks.append("%s joins your crew! (%s)" % [p.name, p.passive_name])
			Save.stat_add("bosses", 1)
			Events.log_event("unlock", {"type": "pilot", "id": req.boss})
	else:
		summary.unlocks.append("%s wins this time. Try again!" % p.name)


func tt_medal(td: TrackData, t: float) -> int:
	var dist := td.main.length * float(td.laps)
	var m := 0
	for k in 3:
		if t <= dist / TT_PACE[k]:
			m = k + 1
	return m


func tt_target(td: TrackData, medal: int) -> float:
	return td.main.length * float(td.laps) / TT_PACE[medal - 1]


func _after_tt(req: Dictionary, me: Dictionary, td: TrackData, summary: Dictionary) -> void:
	var key := "%s:%d" % [td.id, td.variant]
	var t: float = me.time
	var prev: float = Save.data.best_time.get(key, INF)
	if t < prev:
		Save.data.best_time[key] = t
		summary.unlocks.append("New best time %s!" % UiKit.time_str(t))
	var medal := tt_medal(td, t)
	var old := int(Save.data.medals.get(key, 0))
	summary["medal"] = medal
	if medal > old:
		Save.data.medals[key] = medal
		_line(summary, "%s medal" % ["", "Bronze", "Silver", "Gold"][medal], [0, 150, 300, 600][medal] - [0, 150, 300, 600][old])
	if medal < 3:
		summary.unlocks.append("Next medal: %s" % UiKit.time_str(tt_target(td, medal + 1)))


func daily_goal_met(goal_id: String, me: Dictionary) -> bool:
	var st: Dictionary = me.stats
	var top3: bool = int(me.place) <= 3
	match goal_id:
		"win":
			return int(me.place) == 1
		"pods":
			return top3 and int(st.pods) >= 12
		"purple":
			return top3 and int(st.purple) >= 3
		"tricks":
			return top3 and int(st.tricks) >= 5
		"no_hover":
			return top3 and int(st.hover_count) == 0
		"slips":
			return top3 and int(st.slips) >= 3
	return false


func _after_daily(req: Dictionary, me: Dictionary, summary: Dictionary) -> void:
	var info: Dictionary = req.daily
	var ok := daily_goal_met(info.goal.id, me)
	summary["daily_ok"] = ok
	summary["daily_goal"] = info.goal.text
	if not ok:
		return
	var d: Dictionary = Save.data.daily
	if d.last_done == info.date:
		summary.unlocks.append("Daily challenge already done today")
		return
	var yesterday := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
	d.streak = int(d.streak) + 1 if d.last_done == yesterday else 1
	d.best_streak = maxi(int(d.best_streak), int(d.streak))
	d.last_done = info.date
	_line(summary, "Daily challenge (streak %d)" % d.streak, int(info.reward))
	Save.stat_add("dailies", 1)
	Events.log_event("daily_complete", {"streak": d.streak})
