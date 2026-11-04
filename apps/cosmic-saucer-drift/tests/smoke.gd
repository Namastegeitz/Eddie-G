extends Node
## Smoke + flow tests. godot --headless --path . res://tests/smoke.tscn --fixed-fps 60
## Prints PASS/FAIL per check and "SMOKE n passed, m failed".

var passed := 0
var failed := 0


func check(what: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL ", what, ("  (" + detail + ")") if detail != "" else "")


func _ready() -> void:
	# Hand "current scene" to a placeholder so scene changes don't free us.
	var holder := Node.new()
	holder.name = "Holder"
	get_tree().root.add_child.call_deferred(holder)
	await get_tree().process_frame
	get_tree().current_scene = holder
	Save.disabled = true
	Save.data = Save.defaults()
	await _data()
	await _save_tests()
	await _game_logic()
	await _ads()
	await _achievements()
	await _races()
	await _menus()
	print("SMOKE %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


# ---------------------------------------------------------------- data
func _data() -> void:
	var ids := {}
	for p in Catalog.PILOTS:
		check("pilot id unique " + p.id, not ids.has(p.id))
		ids[p.id] = true
		check("pilot home exists " + p.id, TrackDefs.DEFS.has(p.home))
	for s in Catalog.SAUCERS:
		for k in Catalog.STAT_KEYS:
			check("saucer stat %s.%s in range" % [s.id, k], int(s[k]) >= 1 and int(s[k]) <= 10)
	for cup in Catalog.CUPS:
		check("cup has 4 races " + cup.id, cup.races.size() == 4)
		for r in cup.races:
			check("cup track exists %s" % r[0], TrackDefs.DEFS.has(r[0]))
			check("cup challenge exists %s" % r[2], Catalog.CHALLENGES.has(r[2]))
	for id in Catalog.TRACK_IDS:
		for v in 3:
			var td := TrackData.make(id, v)
			check("track %s v%d length sane" % [id, v], td.main.length > 1000.0 and td.main.length < 4000.0, str(td.main.length))
			check("track %s v%d has shortcut" % [id, v], td.short != null)
			check("track %s v%d has 3 shards" % [id, v], td.shards.size() == 3)
			var pods := 0
			var crates := 0
			for f in td.feats:
				if f.t == "pod":
					pods += 1
				elif f.t == "crate":
					crates += 1
			check("track %s v%d pods >= 15" % [id, v], pods >= 15, str(pods))
			check("track %s v%d crate rows >= 3" % [id, v], crates >= 12, str(crates))
			var opened := 0
			for i in td.main.n:
				opened += td.open_l[i] + td.open_r[i]
			check("track %s v%d shortcut opening" % [id, v], opened > 0 or td.short_lift_start)
	var a := Game.daily_info("2026-01-01")
	var b := Game.daily_info("2026-01-01")
	check("daily deterministic", a.track == b.track and a.mod.id == b.mod.id and a.goal.id == b.goal.id)
	var seen := {}
	for d in 30:
		var info := Game.daily_info("2026-02-%02d" % (d % 28 + 1))
		seen[info.mod.id] = true
	check("daily varies", seen.size() >= 3)


# ---------------------------------------------------------------- save
func _save_tests() -> void:
	Save.data = Save.defaults()
	check("starting stardust", Save.stardust() == 300)
	Save.add_stardust(200)
	check("add stardust", Save.stardust() == 500)
	check("spend ok", Save.spend(150) and Save.stardust() == 350)
	check("spend refused", not Save.spend(10000))
	check("no stars at start", Save.total_stars() == 0)
	check("nebula open", Save.cup_unlocked(Catalog.CUPS[0]))
	check("supernova locked", not Save.cup_unlocked(Catalog.CUPS[1]))
	check("station locked at start", not Save.track_unlocked("orbital_station"))
	check("asteroid open at start", Save.track_unlocked("asteroid_belt"))
	check("reverse locked until win", not Save.variant_unlocked("asteroid_belt", 1))
	Save.mark_won("asteroid_belt", 0)
	check("reverse unlocked after win", Save.variant_unlocked("asteroid_belt", 1) and Save.variant_unlocked("asteroid_belt", 2))
	var gained := Save.add_race_stars("nebula", 0, 0b101)
	check("stars gained 2", gained == 2 and Save.total_stars() == 2)
	gained = Save.add_race_stars("nebula", 0, 0b011)
	check("stars only count new", gained == 1 and Save.total_stars() == 3)
	check("shard new", Save.take_shard("comet_ice", 1))
	check("shard repeat", not Save.take_shard("comet_ice", 1))
	Save.set_upgrade("classic", "speed", 3)
	Save.set_look("classic", "paint", "gold")
	var text := JSON.stringify(Save.data)
	var back := Save.defaults()
	Save._merge(back, JSON.parse_string(text))
	check("save round trip stardust", int(back.stardust) == Save.stardust())
	check("save round trip upgrade", int(back.upgrades.classic.speed) == 3)
	check("save round trip look", back.garage.looks.classic.paint == "gold")
	check("save merge keeps new fields", back.has("ads") and back.settings.has("haptics"))
	Save.data = Save.defaults()


# ---------------------------------------------------------------- game logic
func _game_logic() -> void:
	var q := Game.quick_request("asteroid_belt", 0, 1)
	check("quick has 8 racers", q.racers.size() == 8)
	var pilots := {}
	for r in q.racers:
		pilots[r.look.pilot] = true
	check("quick pilots unique", pilots.size() == 8)
	check("versus has 2 humans", Game.versus_request("neon_ring", 0, 1).racers.filter(func(r: Dictionary) -> bool: return r.human).size() == 2)
	check("tt solo", Game.tt_request("comet_ice", 0).racers.size() == 1)
	check("boss 1v1", Game.boss_request("krell").racers.size() == 2)
	var c0 := Game.cup_request("nebula", 0)
	check("cup race 0 track", c0.track == "asteroid_belt")
	var td := TrackData.make("asteroid_belt", 0)
	check("tt medal gold fast", Game.tt_medal(td, 10.0) == 3)
	check("tt medal none slow", Game.tt_medal(td, 9999.0) == 0)
	var me := {"place": 1, "time": 100.0, "stats": {"pods": 15, "tricks": 5, "purple": 3, "hover_count": 0, "slips": 3, "hits": 3, "shards": 1, "shortcuts": 1, "lead_laps": 1}}
	var res := [me, {"place": 2, "time": 103.0}]
	for ch in Catalog.CHALLENGES:
		check("challenge met " + ch, Game.challenge_met(ch, me, res))
	for g in Game.DAILY_GOALS:
		check("daily goal met " + g.id, Game.daily_goal_met(g.id, me))
	var slow := {"place": 5, "time": 130.0, "stats": {"pods": 0, "tricks": 0, "purple": 0, "hover_count": 2, "slips": 0, "hits": 0, "shards": 0, "shortcuts": 0, "lead_laps": 0}}
	check("challenge not met no_hover", not Game.challenge_met("no_hover", slow, res))
	check("daily goal not met win", not Game.daily_goal_met("win", slow))


# ---------------------------------------------------------------- ads
func _ads() -> void:
	check("ads off in v1", not Ads.enabled())
	check("no rewarded offer in v1", not Ads.can_offer("double_stardust"))
	var called := {"inter": false}
	Ads.maybe_interstitial("cup_interstitial", func() -> void: called.inter = true)
	check("interstitial skipped calls through", called.inter)
	# Exercise the debug provider end to end.
	var cfg := AdsConfig.new()
	cfg.enabled = true
	cfg.provider = "debug"
	cfg.min_sessions_before_interstitial = 0
	cfg.min_races_before_interstitial = 0
	cfg.races_between_interstitials = 0
	var old_cfg := Ads.config
	var old_prov := Ads.provider
	Ads.config = cfg
	var dp := DebugAdProvider.new()
	dp.host = Ads
	dp.initialize(cfg)
	Ads.provider = dp
	Ads.consent_ok = true
	check("debug provider offers rewarded", Ads.can_offer("double_stardust"))
	var got := {"granted": false, "done": false}
	Ads.show_rewarded("double_stardust", func(g: bool) -> void:
		got.granted = g
		got.done = true)
	for i in 400:
		if got.done:
			break
		await get_tree().process_frame
	check("rewarded granted", got.granted)
	var inter := {"done": false}
	Ads.maybe_interstitial("cup_interstitial", func() -> void: inter.done = true)
	for i in 400:
		if inter.done:
			break
		await get_tree().process_frame
	check("interstitial shown then continues", inter.done)
	Ads.set_removed(true)
	check("remove-ads entitlement disables ads", not Ads.can_offer("double_stardust"))
	Ads.set_removed(false)
	Ads.config = old_cfg
	Ads.provider = old_prov
	Ads.consent_ok = false
	check("events logged", Events.recent.size() > 0)


# ---------------------------------------------------------------- achievements
func _achievements() -> void:
	Save.data = Save.defaults()
	Save.data.stats["wins"] = 1
	var got := Achievements.check({"hover_count": 1, "hits_taken": 0}, 1, {"mode": "quick"})
	check("first win achievement", Achievements.unlocked("first_win"))
	check("fumes achievement", Achievements.unlocked("running_on_empty"))
	check("untouchable achievement", Achievements.unlocked("clean_sweep"))
	check("achievements pay stardust", Save.stardust() > 300 and got.size() >= 3)
	Save.data = Save.defaults()


# ---------------------------------------------------------------- races
func _race(req: Dictionary, frames_limit := 9000) -> Race:
	req.fast = true
	req.laps = 1
	req.bot_humans = true
	Game.start(req)
	await get_tree().process_frame
	await get_tree().process_frame
	var race: Race = get_tree().current_scene as Race
	var f := 0
	while race and is_instance_valid(race) and not race.done and f < frames_limit:
		await get_tree().physics_frame
		f += 1
	return race


func _races() -> void:
	Save.data = Save.defaults()
	var sd0 := Save.stardust()
	var race := await _race(Game.quick_request("asteroid_belt", 0, 0))
	check("quick race finished", race != null and race.done)
	check("quick race results 8", Game.last_results.size() == 8)
	check("quick race paid stardust", Save.stardust() > sd0, "%d -> %d" % [sd0, Save.stardust()])
	check("results panel shown", race != null and race._results_panel != null)
	check("career races counted", Save.stat("races") >= 1)
	# Cup: all four races.
	Save.data = Save.defaults()
	for i in 4:
		race = await _race(Game.cup_request("nebula", i))
		check("cup race %d finished" % i, race != null and race.done)
	check("cup completed", Game.last_summary.get("cup_last", false))
	check("cup place recorded", Save.data.cup_best.has("nebula"))
	check("cup stars recorded", Save.data.cup_stars.size() >= 1)
	# Retry restores points.
	var pts_before: Dictionary = Game.cup_state.points.duplicate()
	Game.cup_request("nebula", 3)
	check("cup retry restores points", Game.cup_state.points.hash() != pts_before.hash() or pts_before.is_empty())
	# Time trial + ghost recording.
	race = await _race(Game.tt_request("comet_ice", 0))
	check("tt finished", race != null and race.done)
	check("tt recorded ghost frames", race != null and race._ghost_rec.size() > 8 * 100)
	check("tt best time saved", Save.data.best_time.has("comet_ice:0"))
	check("tt has no crates", race != null and race.pickups.crates.is_empty())
	# Boss.
	race = await _race(Game.boss_request("gloop"))
	check("boss race finished", race != null and race.done)
	check("boss race 2 racers", race != null and race.racers.size() == 2)
	# Daily.
	race = await _race(Game.daily_request())
	check("daily finished", race != null and race.done)
	check("daily summary", Game.last_summary.has("daily_ok"))
	# Versus split-screen.
	race = await _race(Game.versus_request("neon_ring", 0, 0))
	check("versus finished", race != null and race.done)
	check("versus two cameras", race != null and race.cams.size() == 2)
	check("versus two huds", race != null and race.huds.size() == 2)
	InputRouter.two_player = false
	# Reverse + mirror quick races run.
	race = await _race(Game.quick_request("orbital_station", 2, 1))
	check("mirror race finished", race != null and race.done)
	# Pause toggles.
	Game.start(Game.quick_request("lava_moon", 1, 1))
	await get_tree().process_frame
	await get_tree().process_frame
	var r2: Race = get_tree().current_scene as Race
	r2.toggle_pause()
	check("pause pauses", get_tree().paused)
	r2.toggle_pause()
	check("unpause", not get_tree().paused)
	Save.data = Save.defaults()


# ---------------------------------------------------------------- menus
func _menus() -> void:
	Save.data.tutorial_done = true
	Game.go_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	var menu: Control = get_tree().current_scene
	check("menu loaded", menu != null and menu.has_method("show_screen"))
	for s in ["home", "play", "cups", "quick", "tt", "bosses", "daily", "garage", "pilots", "achievements", "stats", "settings", "howto", "versus", "title"]:
		menu.show_screen(s)
		await get_tree().process_frame
		check("menu screen " + s, menu._screen == s)
	# Garage purchase flow.
	Save.data.stardust = 100000
	menu._sel["garage_saucer"] = "rocket"
	Save.data.cup_stars["nebula:0"] = 7
	Save.data.cup_stars["nebula:1"] = 7
	Save.data.cup_stars["nebula:2"] = 7
	menu.show_screen("garage")
	await get_tree().process_frame
	check("garage shows locked saucer", not Save.has_saucer("rocket"))
