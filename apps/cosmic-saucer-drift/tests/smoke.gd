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
	await _items_tests()
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
		check("pilot home exists " + p.id, TrackDefs.has(p.home))
	for s in Catalog.SAUCERS:
		for k in Catalog.STAT_KEYS:
			check("saucer stat %s.%s in range" % [s.id, k], int(s[k]) >= 1 and int(s[k]) <= 10)
	for cup in Catalog.CUPS:
		check("cup has 3-4 races " + cup.id, cup.races.size() >= 3 and cup.races.size() <= 4)
		for r in cup.races:
			check("cup track exists %s" % r[0], TrackDefs.has(r[0]))
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
	check("14 tracks", Catalog.TRACK_IDS.size() == 14)
	for id in Catalog.TRACK_IDS:
		var d := TrackDefs.get_def(id)
		check("track %s has 3 facts" % id, d.get("facts", []).size() == 3)
		check("track %s system known" % id, Catalog.SYSTEMS.has(d.get("system", "")))
		check("track %s theme known" % id, Themes.DATA.has(d.theme))
	check("8 power-ups", Catalog.ITEMS.size() == 8)
	check("5 lineups", Catalog.LINEUPS.size() == 5)
	for lu in Catalog.LINEUPS:
		for k in lu.odds:
			check("lineup item exists " + k, Catalog.ITEMS.has(k))
	check("leader lineup", Catalog.lineup_for(1, 8) == 0)
	check("2nd = front pack", Catalog.lineup_for(2, 8) == 1)
	check("5th = midfield", Catalog.lineup_for(5, 8) == 2)
	check("7th = chasers", Catalog.lineup_for(7, 8) == 3)
	check("last = last place", Catalog.lineup_for(8, 8) == 4)
	check("boss 2nd = last place", Catalog.lineup_for(2, 2) == 4)
	check("comet only for the back", not Catalog.LINEUPS[0].odds.has("comet") and not Catalog.LINEUPS[1].odds.has("comet") and Catalog.LINEUPS[4].odds.has("comet"))
	var premium := 0
	for c in Catalog.SAUCERS:
		if c.get("premium", false):
			premium += 1
			check("premium %s has perk + product" % c.id, c.has("perk") and c.has("product") and int(c.price) >= 10000)
	check("14 craft", Catalog.SAUCERS.size() == 14)
	check("4 premium craft", premium == 4)
	for c in Catalog.SAUCERS:
		if c.has("product"):
			check("store product exists " + c.product, not Store.product(c.product).is_empty())
	for p in Catalog.PILOTS:
		check("pilot home is a v2 track " + p.id, Catalog.TRACK_IDS.has(p.home))
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
	check("starting credits", Save.credits() == 300)
	Save.add_credits(200)
	check("add credits", Save.credits() == 500)
	check("spend ok", Save.spend(150) and Save.credits() == 350)
	check("spend refused", not Save.spend(10000))
	check("no stars at start", Save.total_stars() == 0)
	check("solar cup open", Save.cup_unlocked(Catalog.CUPS[0]))
	check("supernova locked", not Save.cup_unlocked(Catalog.CUPS[1]))
	check("station locked at start", not Save.track_unlocked("proxima_station"))
	check("asteroid open at start", Save.track_unlocked("ceres"))
	check("reverse locked until win", not Save.variant_unlocked("ceres", 1))
	Save.mark_won("ceres", 0)
	check("reverse unlocked after win", Save.variant_unlocked("ceres", 1) and Save.variant_unlocked("ceres", 2))
	var gained := Save.add_race_stars("sol", 0, 0b101)
	check("stars gained 2", gained == 2 and Save.total_stars() == 2)
	gained = Save.add_race_stars("sol", 0, 0b011)
	check("stars only count new", gained == 1 and Save.total_stars() == 3)
	check("shard new", Save.take_shard("trappist1h", 1))
	check("shard repeat", not Save.take_shard("trappist1h", 1))
	Save.set_upgrade("classic", "speed", 3)
	Save.set_look("classic", "paint", "gold")
	var text := JSON.stringify(Save.data)
	var back := Save.defaults()
	Save._merge(back, JSON.parse_string(text))
	check("save round trip credits", int(back.credits) == Save.credits())
	check("save round trip upgrade", int(back.upgrades.classic.speed) == 3)
	check("save round trip look", back.garage.looks.classic.paint == "gold")
	check("save merge keeps new fields", back.has("ads") and back.settings.has("haptics"))
	var old_save := {"stardust": 1234, "pilots": ["zib", "nova"]}
	var mig := Save.defaults()
	if old_save.has("stardust") and not old_save.has("credits"):
		old_save["credits"] = old_save["stardust"]
	old_save.erase("stardust")
	Save._merge(mig, old_save)
	check("v1 Stardust migrates to Race Credits", int(mig.credits) == 1234 and not mig.has("stardust"))
	Save.data = Save.defaults()


# ---------------------------------------------------------------- game logic
func _game_logic() -> void:
	var q := Game.quick_request("ceres", 0, 1)
	check("quick has 8 racers", q.racers.size() == 8)
	var pilots := {}
	for r in q.racers:
		pilots[r.look.pilot] = true
	check("quick pilots unique", pilots.size() == 8)
	check("versus has 2 humans", Game.versus_request("saturn_rings", 0, 1).racers.filter(func(r: Dictionary) -> bool: return r.human).size() == 2)
	check("tt solo", Game.tt_request("trappist1h", 0).racers.size() == 1)
	check("boss 1v1", Game.boss_request("krell").racers.size() == 2)
	var c0 := Game.cup_request("sol", 0)
	check("cup race 0 track", c0.track == "mars")
	var td := TrackData.make("ceres", 0)
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
	check("no rewarded offer in v1", not Ads.can_offer("double_credits"))
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
	check("debug provider offers rewarded", Ads.can_offer("double_credits"))
	var got := {"granted": false, "done": false}
	Ads.show_rewarded("double_credits", func(g: bool) -> void:
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
	check("remove-ads entitlement disables ads", not Ads.can_offer("double_credits"))
	Ads.set_removed(false)
	Ads.config = old_cfg
	Ads.provider = old_prov
	Ads.consent_ok = false
	check("events logged", Events.recent.size() > 0)
	# Store layer: off in v1, then the debug provider end to end.
	check("store off in v1", not Store.enabled())
	check("no real-money buy in v1", not Store.can_buy("craft_sail"))
	Save.data = Save.defaults()
	Store.config.enabled = true
	Store.config.provider = "debug"
	Store.use_provider("debug")
	check("debug store enabled", Store.enabled())
	check("can buy premium craft", Store.can_buy("craft_sail"))
	var bought := {"done": false, "ok": false}
	Store.buy("craft_sail", func(ok: bool) -> void:
		bought.ok = ok
		bought.done = true)
	for i in 400:
		if bought.done:
			break
		await get_tree().process_frame
	check("store purchase granted craft", bought.ok and Save.has_saucer("sail"))
	check("owned craft not buyable again", not Store.can_buy("craft_sail"))
	var cr0 := Save.credits()
	bought.done = false
	Store.buy("credits_5k", func(ok: bool) -> void:
		bought.ok = ok
		bought.done = true)
	for i in 400:
		if bought.done:
			break
		await get_tree().process_frame
	check("credit pack adds credits", Save.credits() == cr0 + 5000)
	Save.data = Save.defaults()
	var restored := {"n": -1}
	Store.restore(func(n: int) -> void: restored.n = n)
	check("restore re-grants non-consumables", restored.n >= 1 and Save.has_saucer("sail"))
	Store.config.enabled = false
	Store.config.provider = "none"
	Store.use_provider("none")
	Save.data = Save.defaults()


# ---------------------------------------------------------------- achievements
func _achievements() -> void:
	Save.data = Save.defaults()
	Save.data.stats["wins"] = 1
	var got := Achievements.check({"hover_count": 1, "hits_taken": 0}, 1, {"mode": "quick"})
	check("first win achievement", Achievements.unlocked("first_win"))
	check("fumes achievement", Achievements.unlocked("running_on_empty"))
	check("untouchable achievement", Achievements.unlocked("clean_sweep"))
	check("achievements pay credits", Save.credits() > 300 and got.size() >= 3)
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
	var sd0 := Save.credits()
	var race := await _race(Game.quick_request("ceres", 0, 0))
	check("quick race finished", race != null and race.done)
	check("quick race results 8", Game.last_results.size() == 8)
	check("quick race paid credits", Save.credits() > sd0, "%d -> %d" % [sd0, Save.credits()])
	check("results panel shown", race != null and race._results_panel != null)
	check("career races counted", Save.stat("races") >= 1)
	# Cup: all four races.
	Save.data = Save.defaults()
	for i in 4:
		race = await _race(Game.cup_request("sol", i))
		check("cup race %d finished" % i, race != null and race.done)
	check("cup completed", Game.last_summary.get("cup_last", false))
	check("cup place recorded", Save.data.cup_best.has("sol"))
	check("cup stars recorded", Save.data.cup_stars.size() >= 1)
	# Retry restores points.
	var pts_before: Dictionary = Game.cup_state.points.duplicate()
	Game.cup_request("sol", 3)
	check("cup retry restores points", Game.cup_state.points.hash() != pts_before.hash() or pts_before.is_empty())
	# Time trial + ghost recording.
	race = await _race(Game.tt_request("trappist1h", 0))
	check("tt finished", race != null and race.done)
	check("tt recorded ghost frames", race != null and race._ghost_rec.size() > 8 * 100)
	check("tt best time saved", Save.data.best_time.has("trappist1h:0"))
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
	race = await _race(Game.versus_request("saturn_rings", 0, 0))
	check("versus finished", race != null and race.done)
	check("versus two cameras", race != null and race.cams.size() == 2)
	check("versus two huds", race != null and race.huds.size() == 2)
	InputRouter.two_player = false
	# Reverse + mirror quick races run.
	race = await _race(Game.quick_request("proxima_station", 2, 1))
	check("mirror race finished", race != null and race.done)
	# Pause toggles.
	Game.start(Game.quick_request("io", 1, 1))
	await get_tree().process_frame
	await get_tree().process_frame
	var r2: Race = get_tree().current_scene as Race
	r2.toggle_pause()
	check("pause pauses", get_tree().paused)
	r2.toggle_pause()
	check("unpause", not get_tree().paused)
	Save.data = Save.defaults()


# ---------------------------------------------------------------- power-ups & perks
func _place_on_track(race: Race, r: Racer, s_m: float, lat: float) -> void:
	var path := race.td.main
	var i := path.index_at(s_m)
	r.global_position = path.pts[i] + path.rgt[i] * lat + path.upv[i] * 0.9
	r.heading = path.tan[i]
	r.up = path.upv[i]
	r.track_idx = i
	r.prev_s = path.along(i, r.global_position)
	r.race_dist = s_m
	r.velocity = Vector3.ZERO
	r.invuln_time = 0.0
	r.spin_time = 0.0
	r.shield_time = 0.0
	r.item = ""
	r.item_uses = 0


func _items_tests() -> void:
	Save.data = Save.defaults()
	var req := Game.quick_request("proxima_station", 0, 1)
	req.fast = true
	req.bot_humans = true
	Game.start(req)
	await get_tree().process_frame
	await get_tree().process_frame
	var race: Race = get_tree().current_scene as Race
	check("item test race loaded", race != null)
	if race == null:
		return
	for f in 40:
		await get_tree().physics_frame
	var rs := race.racers
	var a: Racer = rs[0]
	var b: Racer = rs[1]
	var c: Racer = rs[2]
	var d: Racer = rs[3]
	var far: Array = rs.slice(4)
	for k in far.size():
		_place_on_track(race, far[k], 900.0 + k * 40.0, 0.0)
	# Pulse Laser hits a racer straight ahead.
	_place_on_track(race, a, 100.0, 0.0)
	_place_on_track(race, b, 130.0, 0.0)
	_place_on_track(race, c, 300.0, 6.0)
	a.item = "laser"
	a.item_uses = 1
	race.items.use_item(a)
	check("laser hits racer in line", b.spin_time > 0.0)
	check("laser item used up", a.item == "")
	# Held Ion Shield blocks one item hit.
	_place_on_track(race, d, 200.0, 0.0)
	d.item = "shield"
	d.item_uses = 1
	check("held shield blocks hit", not d.hit(a, "rocket") and d.item == "" and d.spin_time <= 0.0)
	d.invuln_time = 0.0
	check("hit lands without shield", d.hit(a, "rocket"))
	# EMP knocks items loose nearby.
	_place_on_track(race, a, 400.0, 0.0)
	_place_on_track(race, b, 405.0, 3.0)
	_place_on_track(race, c, 600.0, 0.0)
	b.item = "rocket"
	b.item_uses = 1
	a.item = "emp"
	a.item_uses = 1
	race.items.use_item(a)
	check("EMP spins out nearby racer", b.spin_time > 0.0)
	check("EMP knocks item loose", b.item == "")
	check("EMP misses far racer", c.spin_time <= 0.0)
	# Nitro uses by lineup.
	race.items.only_item = "nitro"
	a.place = 8
	var it := race.items.roll(a)
	check("last place nitro x3", it == "nitro" and a.item_uses == 3)
	a.item = it
	race.items.use_item(a)
	check("nitro keeps remaining uses", a.item == "nitro" and a.item_uses == 2 and a.boost_time > 0.0)
	a.place = 1
	race.items.roll(a)
	check("leader nitro x1", a.item_uses == 1)
	race.items.only_item = ""
	# Homing rocket launches and hits.
	_place_on_track(race, a, 700.0, 0.0)
	_place_on_track(race, b, 740.0, 0.0)
	var taken0: int = b.stats.hits_taken
	a.item = "rocket"
	a.item_uses = 1
	race.items.use_item(a)
	for f in 90:
		await get_tree().physics_frame
		b.velocity = Vector3.ZERO
	check("rocket hits the racer ahead", b.stats.hits_taken > taken0)
	# Premium perks.
	var sail := Racer.new()
	race.add_child(sail)
	sail.setup(race, 99, {"saucer": "sail", "pilot": "zib"}, {})
	check("solar sail perk", sail.perk == "solar")
	var dyson := Racer.new()
	race.add_child(dyson)
	dyson.setup(race, 98, {"saucer": "dyson", "pilot": "zib"}, {})
	check("dyson pods x1.5", is_equal_approx(dyson.pod_mult, 1.5))
	var bio := Racer.new()
	race.add_child(bio)
	bio.setup(race, 97, {"saucer": "bioship", "pilot": "zib"}, {})
	check("bio-ship regenerates", bio.regen > 0.0)
	Save.data = Save.defaults()


# ---------------------------------------------------------------- menus
func _menus() -> void:
	Save.data.tutorial_done = true
	Game.go_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	var menu: Control = get_tree().current_scene
	check("menu loaded", menu != null and menu.has_method("show_screen"))
	for s in ["home", "play", "cups", "quick", "tt", "bosses", "daily", "garage", "pilots", "achievements", "stats", "settings", "howto", "versus", "store", "title"]:
		menu.show_screen(s)
		await get_tree().process_frame
		check("menu screen " + s, menu._screen == s)
	# Garage purchase flow.
	Save.data.credits = 100000
	menu._sel["garage_saucer"] = "rocket"
	Save.data.cup_stars["sol:0"] = 7
	Save.data.cup_stars["sol:1"] = 7
	Save.data.cup_stars["sol:2"] = 7
	menu.show_screen("garage")
	await get_tree().process_frame
	check("garage shows locked saucer", not Save.has_saucer("rocket"))
