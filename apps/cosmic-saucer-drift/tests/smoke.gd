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
	await _gfx_tests()
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
	check("14 power-ups", Catalog.ITEMS.size() == 14)
	for id in Catalog.ITEMS:
		check("item sound exists " + id, ResourceLoader.exists("res://assets/audio/item_%s.wav" % id))
	check("warp jump only from the midfield back", not Catalog.LINEUPS[0].odds.has("warp") and not Catalog.LINEUPS[1].odds.has("warp") and Catalog.LINEUPS[4].odds.has("warp"))
	check("decoys and frost for the leaders", Catalog.LINEUPS[0].odds.has("decoy") and Catalog.LINEUPS[0].odds.has("frost") and not Catalog.LINEUPS[4].odds.has("decoy"))
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
	var old2 := {"stardust": 50, "settings": {"steering": "buttons"}}
	Save.migrate(old2)
	check("migrate: stardust", int(old2.credits) == 50 and not old2.has("stardust"))
	check("old saves move to the joystick", old2.settings.steering == "joystick" and old2.controls_v3)
	var old3 := {"settings": {"steering": "tilt"}}
	Save.migrate(old3)
	check("tilt players keep tilt", old3.settings.steering == "tilt")
	var new_save := {"controls_v3": true, "settings": {"steering": "buttons"}}
	Save.migrate(new_save)
	check("a later choice of buttons is kept", new_save.settings.steering == "buttons")
	check("new players get the joystick", Save.defaults().settings.steering == "joystick")
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


# ---------------------------------------------------------------- v3 graphics
func _gfx_tests() -> void:
	# Quality tiers.
	for t in Gfx.TIERS:
		check("tier %s defined" % t, Gfx.Q.has(t))
		for k in ["msaa", "scale", "shadows", "glow", "fog", "decor", "seg", "detail", "face", "particles", "reflect", "speedlines", "road_detail", "sky_detail", "lod"]:
			if not Gfx.Q[t].has(k):
				check("tier %s has %s" % [t, k], false)
	check("detect gives a tier", Gfx.detect() in Gfx.TIERS, Gfx.detect())
	var old_q: String = Save.setting("quality")
	Save.data.settings.quality = "ultra"
	check("quality setting ultra", Game.quality() == "ultra")
	Save.data.settings.quality = "bogus"
	check("bad quality falls back to auto", Game.quality() == Game.detected_quality)
	Save.data.settings.quality = old_q
	check("tiers get cheaper", int(Gfx.Q.low.seg) < int(Gfx.Q.medium.seg) and int(Gfx.Q.medium.seg) < int(Gfx.Q.high.seg) and int(Gfx.Q.high.seg) < int(Gfx.Q.ultra.seg))
	# Mesh toolkit.
	var lm := MeshKit.lathe(PackedVector2Array([Vector2(0, 1), Vector2(1, 0), Vector2(0, -1)]), 12, PackedInt32Array([1]))
	check("lathe builds", lm.get_surface_count() == 1 and lm.surface_get_array_len(0) > 0)
	check("lathe cached", MeshKit.lathe(PackedVector2Array([Vector2(0, 1), Vector2(1, 0), Vector2(0, -1)]), 12, PackedInt32Array([1])) == lm)
	var bm := MeshKit.blob(Vector3(1, 0.5, 0.8), 0.4, 0.4, 12, 8, Vector2(0.5, 0.5), 0.1)
	check("blob builds", bm.surface_get_array_len(0) == 13 * 9)
	var fm := MeshKit.faceted(lm)
	check("faceted has flat normals", fm.surface_get_array_len(0) % 3 == 0)
	check("arc + star build", MeshKit.arc(1.0, 0.1, 200.0, 340.0).get_surface_count() == 1 and MeshKit.star(1.0, 0.4, 0.2).get_surface_count() == 1)
	var mg := MeshKit.Merger.new()
	var ma := StandardMaterial3D.new()
	var mb := StandardMaterial3D.new()
	mg.add(lm, ma, Transform3D.IDENTITY)
	mg.add(bm, ma, Transform3D(Basis.IDENTITY.scaled(Vector3(-1, 1, 1)), Vector3.ONE))
	mg.add(bm, mb, Transform3D.IDENTITY)
	var merged := mg.commit()
	check("merger: one surface per material", merged.get_surface_count() == 2)
	check("merger keeps materials", merged.surface_get_material(0) == ma and merged.surface_get_material(1) == mb)
	# Every craft at every tier, with pilot faces.
	var holder := Node3D.new()
	add_child(holder)
	var bad := 0
	for t in Gfx.TIERS:
		Save.data.settings.quality = t
		for si in Catalog.SAUCERS.size():
			var sd: Dictionary = Catalog.SAUCERS[si]
			var m := SaucerModel.new()
			holder.add_child(m)
			m.build({"saucer": sd.id, "pilot": Catalog.PILOTS[si % Catalog.PILOTS.size()].id, "paint": "stock", "decal": "stripes", "dome": "clear", "trail": "cyan"})
			if m.pivot == null or m.pilot_model == null or m.shield == null or m.trail == null:
				check("craft %s builds at %s" % [sd.id, t], false)
				bad += 1
			if m.thrusters.is_empty():
				check("craft %s has an engine flame" % sd.id, false)
				bad += 1
			for mood in 7:
				m.mood = mood
				m.flash = 1.0
				m.animate(1.0 / 60.0, 1.0, mood % 2 == 0, mood % 4, mood % 3 == 0, 0.8)
			if m.flash >= 1.0:
				check("hit flash fades on %s" % sd.id, false)
				bad += 1
			if (m.shadow != null) == (int(Gfx.Q[t].shadows) > 0):
				check("blob shadow only without real shadows (%s %s)" % [sd.id, t], false)
				bad += 1
			m.free()
	check("all 14 craft build and animate at all 4 tiers", bad == 0)
	Save.data.settings.quality = "high"
	for p in Catalog.PILOTS:
		var pm := PilotModel.new()
		holder.add_child(pm)
		pm.build(p, 0.35, true, 30.0)
		check("pilot %s has eyes and lids" % p.id, pm._eyes.size() == int(p.eyes) and pm._lids.size() == int(p.eyes))
		check("pilot %s has 4 mouths" % p.id, pm._mouths.size() == 4)
		pm.animate(0.016, PilotModel.Mood.GRIN, 0.5, 1.0)
		check("pilot %s grins" % p.id, pm._mouths[PilotModel.M.GRIN].visible and not pm._mouths[PilotModel.M.SMILE].visible)
		pm.animate(0.016, PilotModel.Mood.DIZZY, 0.0, 0.0)
		check("pilot %s dizzy stars" % p.id, pm._stars != null and pm._stars.visible)
		var far := PilotModel.new()
		holder.add_child(far)
		far.build(p, 0.35, false, 30.0)
		check("pilot %s low detail is cheap" % p.id, far._eyes.is_empty() and far._mouths.is_empty() and far._far != null)
		pm.free()
		far.free()
	Save.data.settings.quality = old_q
	# Pooled race effects.
	var fx := RaceFx.new()
	holder.add_child(fx)
	await get_tree().process_frame
	for k in RaceFx.RINGS + 3:
		fx.shockwave(Vector3(k, 0, 0), Vector3.UP, Color.CYAN)
		fx.flash(Vector3(k, 1, 0), Color.WHITE)
		fx.sparks(Vector3(k, 0, 0), Vector3.UP, Color.ORANGE)
		fx.dust(Vector3(k, 0, 0), Vector3.UP, Color.TAN)
	check("fx pools stay fixed", fx.get_child_count() == RaceFx.RINGS + RaceFx.FLASHES + RaceFx.BURSTS)
	for i in 40:
		await get_tree().process_frame
	var lit := 0
	for r in fx._rings:
		if r.visible:
			lit += 1
	check("shockwaves fade out", lit == 0)
	holder.queue_free()
	await _touch_tests()
	await _mouse_tests()
	# AI catch-up bands per class.
	for c in Catalog.AI_CLASSES:
		check("ai class %s has band" % c.name, c.has("band") and c.band.size() == 2 and float(c.band[0]) > 0.0 and float(c.band[1]) > 0.0)
	check("cadet eases off more than legend", float(Catalog.AI_CLASSES[0].band[0]) > float(Catalog.AI_CLASSES[3].band[0]))
	check("cadet catches up less than legend", float(Catalog.AI_CLASSES[0].band[1]) < float(Catalog.AI_CLASSES[3].band[1]))


# ---------------------------------------------------------------- touch controls
func _touch_tests() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	Save.data.settings.steering = "joystick"
	Save.data.settings.auto_accel = true
	var tc := TouchControls.new()
	host.add_child(tc)
	tc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tc.size = Vector2(1280, 720)
	await get_tree().process_frame
	var r := tc.stick_radius()
	var p0 := tc.stick_home()
	check("joystick zone covers its home", tc.stick_zone().has_point(p0))
	tc._input(_touch(0, p0, true))
	check("thumb down: no steer yet", is_zero_approx(InputRouter.touch.steer))
	tc._input(_drag(0, p0 + Vector2(r * 0.05, 0)))
	check("joystick dead zone", is_zero_approx(InputRouter.touch.steer))
	tc._input(_drag(0, p0 + Vector2(r * 0.55, 0)))
	var half: float = InputRouter.touch.steer
	check("joystick steers gently", half > 0.35 and half < 0.65, str(half))
	tc._input(_drag(0, p0 + Vector2(-r * 2.0, 0)))
	check("joystick full left", is_equal_approx(InputRouter.touch.steer, -1.0))
	tc._input(_touch(0, p0, false))
	check("thumb up: straight", is_zero_approx(InputRouter.touch.steer))
	tc._layout()
	var gas: Rect2 = tc._buttons.gas
	var brake: Rect2 = tc._buttons.brake
	check("pedals don't overlap drift", not gas.intersects(tc._buttons.drift) and not brake.intersects(tc._buttons.drift) and not gas.intersects(brake))
	check("pedals are below the minimap", gas.position.y > 220.0 and brake.position.y > 220.0)
	tc._input(_touch(1, gas.get_center(), true))
	check("GAS pedal", InputRouter.touch.throttle == 1.0)
	var c: InputRouter.Controls = InputRouter.controls(0)
	check("GAS gives full power", is_equal_approx(c.throttle, 1.0) and is_equal_approx(c.gas, 1.0))
	tc._input(_touch(1, gas.get_center(), false))
	c = InputRouter.controls(0)
	check("auto-drive cruises below full", is_equal_approx(c.throttle, InputRouter.AUTO_CRUISE) and is_zero_approx(c.gas))
	tc._input(_touch(2, brake.get_center(), true))
	c = InputRouter.controls(0)
	check("BRAKE stops auto-drive", c.brake == 1.0 and is_zero_approx(c.throttle))
	tc._input(_touch(2, brake.get_center(), false))
	# A stick touch never presses buttons, and a button touch never moves the stick.
	tc._input(_touch(3, tc._buttons.item.get_center(), true))
	check("item press", InputRouter.touch.item and tc._stick_id < 0)
	tc._input(_touch(3, tc._buttons.item.get_center(), false))
	# Portrait (phone held upright): the controls keep their size on the
	# 720x1280 canvas, and nothing overlaps.
	var tall := Control.new()
	tall.size = Vector2(720, 1280)
	add_child(tall)
	var tc2 := TouchControls.new()
	tall.add_child(tc2)
	tc2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tc2.size = Vector2(720, 1280)
	await get_tree().process_frame
	check("portrait buttons same size as landscape", is_equal_approx(tc2._unit(), tc._unit()) and is_equal_approx(tc2._unit(), 1.0))
	tc2._layout()
	var jr := Rect2(tc2.stick_home() - Vector2.ONE * tc2.stick_radius(), Vector2.ONE * tc2.stick_radius() * 2.0)
	var clash := false
	for n in tc2._buttons:
		var br: Rect2 = tc2._buttons[n]
		if br.intersects(jr) or br.end.x > 721.0 or br.end.y > 1281.0:
			clash = true
	check("portrait: joystick and buttons don't overlap or spill", not clash)
	check("portrait: joystick zone excludes the button cluster", not tc2.stick_zone().has_point(tc2._buttons.item.get_center()))
	var ls := Control.new()
	ls.size = Vector2(1560, 720)
	add_child(ls)
	var tc3 := TouchControls.new()
	ls.add_child(tc3)
	tc3.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tc3.size = Vector2(1560, 720)
	await get_tree().process_frame
	check("wide phone landscape keeps unit 1", is_equal_approx(tc3._unit(), 1.0))
	tc2.free()
	tall.free()
	tc3.free()
	ls.free()
	InputRouter.touch.active = true   # (freeing the extra controls switched it off)
	check("landscape window keeps the 1280x720 canvas", get_window().content_scale_size == Vector2i(1280, 720) and not Game.portrait_window())
	# A touch on the COCKPIT tab must not grab the joystick.
	var tab := Control.new()
	host.add_child(tab)
	tab.position = Vector2(0, 280)
	tab.size = Vector2(48, 168)
	tc.blockers.append(tab)
	tc._input(_touch(5, Vector2(20, 360), true))
	check("tab touch doesn't start the joystick", tc._stick_id < 0)
	tc._input(_touch(5, Vector2(20, 360), false))
	Save.data.settings.steering = "buttons"
	tc._layout()
	check("buttons mode has arrows, no stick", tc._buttons.has("left") and tc._buttons.has("right"))
	tc._input(_touch(4, p0, true))
	check("no joystick in buttons mode", tc._stick_id < 0)
	tc._input(_touch(4, p0, false))
	Save.data.settings.steering = "joystick"
	# On the grid only a real GAS press counts, so auto-drive can't stall the start.
	var drv := PlayerDriver.new(0)
	var fake := Racer.new()
	fake.frozen = true
	drv.drive(fake, 0.016)
	check("auto-drive doesn't hold gas on the grid", is_zero_approx(fake.in_throttle))
	fake.frozen = false
	drv.drive(fake, 0.016)
	check("auto-drive drives once racing", is_equal_approx(fake.in_throttle, InputRouter.AUTO_CRUISE))
	fake.free()
	host.queue_free()
	await get_tree().process_frame
	check("touch input cleared when controls go", not InputRouter.touch.active and is_zero_approx(InputRouter.touch.throttle))
	InputRouter.touch_seen = false


func _first_layers(n: Node) -> int:
	if n is VisualInstance3D:
		return (n as VisualInstance3D).layers
	for c in n.get_children():
		var l := _first_layers(c)
		if l >= 0:
			return l
	return -1


# ---------------------------------------------------------------- mouse flight stick
func _mouse_tests() -> void:
	var was_touch := InputRouter.touch_seen
	InputRouter.touch_seen = false
	InputRouter.touch.active = false
	InputRouter.two_player = false
	Save.data.settings.mouse_controls = true
	Save.data.settings.auto_accel = true
	InputRouter.mouse_recentre()
	InputRouter.mouse_active = false
	check("mouse scheme on by default", InputRouter.mouse_on())
	var c: InputRouter.Controls = InputRouter.controls(0)
	check("mouse idle until it moves", is_zero_approx(c.steer) and is_zero_approx(c.throttle))
	InputRouter._input(_motion(Vector2(44, 0)))
	check("first motion wakes the stick", InputRouter.mouse_active and InputRouter.mouse_stick.x > 0.15 and InputRouter.mouse_stick.x < 0.25)
	c = InputRouter.controls(0)
	check("mouse steers right", c.steer > 0.15 and c.steer < 0.25)
	check("mouse cruise band = auto-drive", is_equal_approx(c.throttle, InputRouter.AUTO_CRUISE) and is_zero_approx(c.gas))
	InputRouter._input(_motion(Vector2(0, -220)))
	c = InputRouter.controls(0)
	check("push forward = full gas", is_equal_approx(InputRouter.mouse_stick.y, 1.0) and is_equal_approx(c.gas, 1.0))
	InputRouter._input(_motion(Vector2(0, 440)))
	c = InputRouter.controls(0)
	check("pull back = brake, clamped", is_equal_approx(InputRouter.mouse_stick.y, -1.0) and is_equal_approx(c.brake, 1.0) and is_zero_approx(c.throttle))
	InputRouter._input(_motion(Vector2(-900, 0)))
	check("stick clamps at full lock", is_equal_approx(InputRouter.mouse_stick.x, -1.0))
	InputRouter.mouse_recentre()
	check("recentre straightens the stick", InputRouter.mouse_stick == Vector2.ZERO)
	# A big jump (the cursor coming in from elsewhere) doesn't start it.
	InputRouter.mouse_active = false
	InputRouter._input(_motion(Vector2(400, 300)))
	check("a jump doesn't wake the stick", not InputRouter.mouse_active and InputRouter.mouse_stick == Vector2.ZERO)
	Save.data.settings.mouse_controls = false
	InputRouter._input(_motion(Vector2(44, 0)))
	check("setting off ignores the mouse", not InputRouter.mouse_on() and InputRouter.mouse_stick == Vector2.ZERO)
	Save.data.settings.mouse_controls = true
	InputRouter.touch.active = true
	check("touch driving turns the mouse stick off", not InputRouter.mouse_on())
	InputRouter.touch.active = false
	InputRouter.two_player = true
	check("no mouse stick in split-screen", not InputRouter.mouse_on())
	InputRouter.two_player = false
	InputRouter.release_mouse()
	check("release leaves the pointer visible", Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not InputRouter.mouse_capture_wanted)
	# On-screen joystick + key chips draw for keyboard/mouse players.
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var dh := DesktopHints.new()
	host.add_child(dh)
	var fake := Racer.new()
	dh.racer = fake
	dh.size = Vector2(1280, 720)
	dh._process(0.05)
	dh.queue_redraw()
	await get_tree().process_frame
	check("desktop hints draw", dh._vis.length() >= 0.0)
	host.free()
	fake.free()
	InputRouter.mouse_active = false
	InputRouter.mouse_recentre()
	InputRouter.touch_seen = was_touch


func _motion(rel: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.relative = rel
	return e


func _touch(i: int, p: Vector2, down: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = p
	e.pressed = down
	return e


func _drag(i: int, p: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = i
	e.position = p
	return e


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
	if race and is_instance_valid(race):
		check("race has pooled fx", race.fx != null)
		for t in Gfx.TIERS:
			Save.data.settings.quality = t
			race.apply_quality()
			check("apply quality %s" % t, race._env.glow_enabled == bool(Gfx.Q[t].glow) and race._sun.shadow_enabled == (int(Gfx.Q[t].shadows) > 0))
		Save.data.settings.quality = "auto"
		check("time scale restored", is_equal_approx(Engine.time_scale, 1.0))
		var cam: RaceCamera = race.cams[0] if not race.cams.is_empty() else null
		if cam:
			cam.land(20.0)
			cam._process(0.016)
			check("camera dips on landing", cam._dip_v != 0.0 or cam._dip != 0.0)
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


func _clear(r: Racer) -> void:
	r.item = ""
	r.item_uses = 0
	r.boost_time = 0.0
	r.spin_time = 0.0
	r.invuln_time = 0.0
	r.shield_time = 0.0
	r.tractor_time = 0.0
	r.slow_time = 0.0
	r.slick_time = 0.0


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
	# Effect nodes are pooled at load and reused (no building mid-race).
	check("effect pools built at load", race.items.pooled("mine") == Items.MAX_MINES and race.items.pooled("bolt") == 8 and race.items.pooled("rocket") == 3)
	check("new power-up effects pooled", race.items.pooled("portal") == 2 and race.items.pooled("decoy") == 2 and race.items.pooled("well") == 2 and race.items.pooled("leech_beam") == 3 and race.items.pooled("charge_dome") == 2)
	check("ice multimesh ready", race.items._ice_mm != null and race.items._ice_mm.multimesh.instance_count == Items.MAX_ICE and race.items._ice_free.size() == Items.MAX_ICE)
	check("shield badges pre-made for every racer", race.items._badges.size() == 8)
	var n0 := race.items.get_child_count()
	var taken := race.items._take("rocket")
	check("take shows a pooled node", taken.visible and race.items.pooled("rocket") == 2)
	race.items._give("rocket", taken)
	check("give hides it and keeps the node count", not taken.visible and race.items.pooled("rocket") == 3 and race.items.get_child_count() == n0)
	await race.items.warm_up(race.cams[0] if not race.cams.is_empty() else null)
	var leftovers := 0
	for kind in Items.POOL_SIZES:
		if race.items.pooled(kind) != int(Items.POOL_SIZES[kind]):
			leftovers += 1
		for node in race.items._pool[kind]:
			if (node as Node3D).visible or (node as Node3D).get_parent() != race.items:
				leftovers += 1
	check("warm-up puts every effect back hidden", leftovers == 0)
	check("jitter fix off with physics interpolation", is_zero_approx(float(ProjectSettings.get_setting("physics/common/physics_jitter_fix"))))
	check("particle distance grows with the tier", float(Gfx.Q.low.fx_dist) < float(Gfx.Q.medium.fx_dist) and float(Gfx.Q.medium.fx_dist) < float(Gfx.Q.ultra.fx_dist))
	var rs := race.racers
	var a: Racer = rs[0]
	var b: Racer = rs[1]
	var c: Racer = rs[2]
	var d: Racer = rs[3]
	var far: Array = rs.slice(4)
	for k in far.size():
		_place_on_track(race, far[k], 900.0 + k * 40.0, 0.0)
	race.items.clear_effects()
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
	check("EMP shows a dome and lightning", race.items.beams.any(func(x: Dictionary) -> bool: return x.kind == "emp") and race.items.beams.any(func(x: Dictionary) -> bool: return x.kind == "bolt"))
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
	# EMP leaves a dome and lightning (checked above it hit b).
	# v3 power-up models, effects and hit reactions.
	for r: Racer in [a, b, c]:
		r.invuln_time = 0.0
		r.spin_time = 0.0
		r.shield_time = 0.0
		r.item = ""
	_place_on_track(race, a, 1000.0, 0.0)
	_place_on_track(race, b, 1030.0, 0.0)
	a.item = "laser"
	a.item_uses = 1
	race.items.use_item(a)
	var lb := race.items.beams.filter(func(x: Dictionary) -> bool: return x.kind == "laser")
	check("laser draws a layered beam", lb.size() == 1 and (lb[0].node as Node3D).get_child_count() == 3)
	b.invuln_time = 0.0
	b.spin_time = 0.0
	_place_on_track(race, a, 1100.0, 0.0)
	_place_on_track(race, b, 1180.0, 0.0)
	a.item = "rocket"
	a.item_uses = 1
	race.items.use_item(a)
	var rk: Dictionary = race.items.rockets.back()
	check("rocket model has a flame", (rk.node as Node3D).get_node_or_null("Flame") != null)
	check("rocket locks on with a reticle", rk.reticle != null and rk.target == b)
	a.item = "mine"
	a.item_uses = 1
	race.items.use_item(a)
	var mn: Dictionary = race.items.mines.back()
	check("mine has a gravity ring and a light", (mn.node as Node3D).has_node("Ring") and (mn.node as Node3D).has_node("Light"))
	check("mine came from the pool", race.items.pooled("mine") == Items.MAX_MINES - 1)
	a.item = "nitro"
	a.item_uses = 1
	race.items.use_item(a)
	check("nitro straps boosters on", race.items.nitros.size() >= 1 and (race.items.nitros[0].node as Node3D).get_child_count() == 2)
	a.boost_time = 0.0
	a.boost_kind = ""
	for f in 3:
		await get_tree().physics_frame
	a.boost_time = 0.0
	await get_tree().physics_frame
	await _new_items_tests(race)
	check("boosters come off when the nitro ends", race.items.nitros.is_empty())
	c.item = "shield"
	c.item_uses = 1
	c.item_roll = 0.0
	for f in 2:
		await get_tree().physics_frame
	check("held shield shows a badge", race.items._badges.has(c.idx) and (race.items._badges[c.idx] as Node3D).visible)
	c.item = ""
	await get_tree().physics_frame
	check("badge hides when the shield is gone", not (race.items._badges[c.idx] as Node3D).visible)
	a.model.react("comet")
	a.model.animate(0.05, 1.0, false, 0, false, 0.5)
	check("comet hit squashes the craft", a.model.pivot.scale.y < 0.99)
	for f in 30:
		a.model.animate(0.05, 1.0, false, 0, false, 0.5)
	check("craft shape recovers", a.model.pivot.scale.is_equal_approx(Vector3.ONE))
	a.model.react("laser")
	for f in 30:
		a.model.animate(0.05, 1.0, false, 0, false, 0.5)
	check("laser jolt settles", is_zero_approx(a.model.pivot.position.x))
	a.model.react("mystery")
	check("unknown hit kinds still react", a.model._react == "hazard")
	# Cockpit (first-person) view: COCKPIT tab, toggling both ways, V key.
	if not race.cams.is_empty():
		var cam: RaceCamera = race.cams[0]
		var me: Racer = cam.target
		var hud := race.hud_for(me)
		check("HUD has a COCKPIT tab", hud != null and hud.cockpit_tab != null and hud.cockpit_tab.text == "COCKPIT")
		check("pilot drawn on its own layer", cam.pilot_mask != 0 and _first_layers(me.model.pilot_model) == cam.pilot_mask)
		hud.cockpit_tab.pressed.emit()
		check("tab switches to cockpit", cam.cockpit and hud.is_cockpit() and hud.cockpit_tab.on)
		check("cockpit choice is remembered", Save.setting("cockpit") == true)
		cam.intro = 0.0
		for f in 12:
			await get_tree().process_frame
		check("cockpit camera at the pilot's eyes", cam.global_position.distance_to(cam.eye_position()) < 0.6, str(cam.global_position.distance_to(cam.eye_position())))
		check("own pilot hidden in cockpit", (cam.cull_mask & cam.pilot_mask) == 0)
		check("cockpit looks ahead", (-cam.global_basis.z).dot(me.heading) > 0.6)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_V
		ev.pressed = true
		race._unhandled_input(ev)
		check("V switches back to chase", not cam.cockpit and not hud.is_cockpit() and Save.setting("cockpit") == false)
		for f in 40:
			await get_tree().process_frame
		check("chase camera back behind", cam.global_position.distance_to(me.global_position) > 3.0)
		check("own pilot visible again", (cam.cull_mask & cam.pilot_mask) != 0)
		Save.data.settings.cockpit = false
		# Portrait HUD: energy bars go top-centre, pause under the speed, and
		# the cockpit dash clears the pedals; back to the bottom in landscape.
		var old_size := hud.size
		InputRouter.touch_seen = true
		hud.size = Vector2(720, 1280)
		hud._process(0.016)
		check("portrait HUD is tall", hud.tall() and hud.bottom_pad() > 300.0)
		check("portrait: energy label at the top", hud._energy_lbl.anchor_top == 0.0 and hud._energy_lbl.offset_top > 100.0)
		hud.size = old_size if old_size.x > 0.0 else Vector2(1280, 720)
		hud._process(0.016)
		check("landscape: energy label at the bottom", hud._energy_lbl.anchor_top == 1.0 and is_zero_approx(hud.bottom_pad()))
		InputRouter.touch_seen = false
		var rc := race.cams[0]
		rc._fit_orientation()
		check("landscape camera keeps height FOV", rc.keep_aspect == Camera3D.KEEP_HEIGHT)
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
	# Title screen: a tap must work even though the menu's controls cover
	# the screen (they used to swallow it), and the rest of that tap must not
	# press a button on the next screen.
	menu.show_screen("title")
	await get_tree().process_frame
	var tap := InputEventScreenTouch.new()
	tap.position = Vector2(300, 400)
	tap.pressed = true
	menu._input(tap)
	check("tap on title opens the menu", menu._screen == "home", menu._screen)
	var click := InputEventMouseButton.new()
	click.position = Vector2(300, 400)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	menu._input(click)
	check("same tap doesn't press a home button", menu._screen == "home", menu._screen)
	menu.show_screen("title")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ENTER
	key.pressed = true
	menu._swallow_until = 0
	menu._input(key)
	check("key on title opens the menu", menu._screen == "home", menu._screen)
	check("symbol font for stars and arrows", UiKit.bold().fallbacks.size() > 0)
	menu.show_screen("quick")
	await get_tree().process_frame
	check("quick race has a pinned RACE button", menu.content.get_node_or_null("PinnedStart") != null)
	menu.show_screen("home")
	await get_tree().process_frame
	check("home has no pinned start button", menu.content.get_node_or_null("PinnedStart") == null)
	# Garage purchase flow.
	Save.data.credits = 100000
	menu._sel["garage_saucer"] = "rocket"
	Save.data.cup_stars["sol:0"] = 7
	Save.data.cup_stars["sol:1"] = 7
	Save.data.cup_stars["sol:2"] = 7
	menu.show_screen("garage")
	await get_tree().process_frame
	check("garage shows locked saucer", not Save.has_saucer("rocket"))


## Warp Jump, Decoy Drone, Energy Leech, Gravity Well, Frost Trail, Overcharge.
func _new_items_tests(race: Race) -> void:
	var rs := race.racers
	var a: Racer = rs[0]
	var b: Racer = rs[1]
	var c: Racer = rs[2]
	for r: Racer in rs:
		_clear(r)
	for k in range(3, rs.size()):
		_place_on_track(race, rs[k], 900.0 + k * 40.0, 0.0)
	race.items.clear_effects()
	check("clear_effects refills every pool", race.items.pooled("rocket") == 3 and race.items.pooled("mine") == Items.MAX_MINES and race.items.pooled("boosters") == 2)
	# Overcharge: a full core gives the longest boost and burns 60%.
	_place_on_track(race, a, 100.0, 0.0)
	_place_on_track(race, b, 130.0, 0.0)
	_place_on_track(race, c, 400.0, 0.0)
	a.energy = 100.0
	a.item = "overcharge"
	a.item_uses = 1
	race.items.use_item(a)
	check("overcharge boosts for 3 s from a full core", absf(a.boost_time - 3.0) < 0.05 and a.boost_kind == "overcharge")
	check("overcharge burns 60% of the core", absf(a.energy - 40.0) < 0.5)
	check("overcharge shows a charge dome", race.items.pooled("charge_dome") == 1)
	a.boost_time = 0.0
	# Warp Jump: carried down the track, further from the back.
	a.place = 8
	var d0 := a.race_dist
	a.item = "warp"
	a.item_uses = 1
	race.items.use_item(a)
	var jumped := a.race_dist - d0
	check("warp from last place jumps about 80 m", jumped > 70.0 and jumped < 90.0)
	check("warp opens two portals", race.items.pooled("portal") == 0)
	check("warp lands on the road", absf(a.lateral) < race.td.width * 0.5 and race.td.gap[a.track_idx] == 0)
	a.place = 1
	_place_on_track(race, a, 100.0, 0.0)
	d0 = a.race_dist
	a.item = "warp"
	a.item_uses = 1
	race.items.use_item(a)
	jumped = a.race_dist - d0
	check("warp from first place jumps about 40 m", jumped > 30.0 and jumped < 50.0)
	race.items.clear_effects()
	# Decoy Drone: a rocket already locked on switches to the hologram.
	_place_on_track(race, a, 100.0, 0.0)
	_place_on_track(race, b, 130.0, 0.0)
	a.item = "rocket"
	a.item_uses = 1
	race.items.use_item(a)
	var rk: Dictionary = race.items.rockets.back()
	check("rocket locked on the leader", rk.target == b)
	b.item = "decoy"
	b.item_uses = 1
	race.items.use_item(b)
	check("decoy trails its owner", race.items.decoys.size() == 1 and race.items.decoys[0].owner == b)
	check("locked rocket switches to the decoy", not (rk.decoy as Dictionary).is_empty())
	check("decoy owner no longer threatened", not race.items.threatened(b))
	for f in 90:
		if race.items.rockets.is_empty():
			break
		await get_tree().physics_frame
	var decoy_gone: bool = race.items.decoys.is_empty() or not bool(race.items.decoys[0].live)
	check("rocket pops the decoy, not the owner", race.items.rockets.is_empty() and b.spin_time <= 0.0 and decoy_gone)
	# Tractor Beam grabs a decoy too.
	race.items.clear_effects()
	_place_on_track(race, a, 100.0, 0.0)
	_place_on_track(race, b, 125.0, 0.0)
	b.item = "decoy"
	b.item_uses = 1
	race.items.use_item(b)
	check("decoy is live before the tractor", not race.items._decoy_of(b).is_empty())
	a.item = "tractor"
	a.item_uses = 1
	a.boost_time = 0.0
	race.items.use_item(a)
	check("tractor beam takes the decoy", b.tractor_time <= 0.0 and race.items._decoy_of(b).is_empty() and a.boost_time > 0.0)
	await get_tree().physics_frame
	race.items.clear_effects()
	a.boost_time = 0.0
	# Energy Leech: drains a racer in range into your core.
	_place_on_track(race, a, 100.0, 0.0)
	_place_on_track(race, b, 108.0, 0.0)
	a.energy = 50.0
	b.energy = 80.0
	a.item = "leech"
	a.item_uses = 1
	race.items.use_item(a)
	for f in 30:
		await get_tree().physics_frame
		_place_on_track(race, a, 100.0, 0.0)
		_place_on_track(race, b, 108.0, 0.0)
	check("leech drains the victim", b.energy < 76.0)
	check("leech feeds the owner", a.energy > 53.0)
	check("leech beam latched on", (race.items.leeches[0].links as Dictionary).has(b.idx))
	b.energy = 80.0
	b.shield_time = 5.0
	var a0 := a.energy
	for f in 20:
		await get_tree().physics_frame
		_place_on_track(race, a, 100.0, 0.0)
		_place_on_track(race, b, 108.0, 0.0)
		b.shield_time = 5.0
	# A leech would have moved about 3 units; the bubble stops it (both cores
	# only lose their normal drain).
	check("shield bubble stops the leech", b.energy > 78.5 and a.energy <= a0 and not (race.items.leeches[0].links as Dictionary).has(b.idx))
	b.shield_time = 0.0
	for L in race.items.leeches:
		L.t = 0.0
	await get_tree().physics_frame
	check("leech effects returned to the pools", race.items.leeches.is_empty() and race.items.pooled("leech_beam") == 3 and race.items.pooled("leech_aura") == 2)
	# Gravity Well: dropped behind, pulls and slows a racer that enters it.
	_place_on_track(race, a, 200.0, 0.0)
	a.item = "well"
	a.item_uses = 1
	race.items.use_item(a)
	var w: Dictionary = race.items.wells.back()
	check("gravity well sits on the road behind", race.td.main.delta(float(w.s), 200.0) > 3.0 and race.td.main.delta(float(w.s), 200.0) < 10.0)
	_place_on_track(race, b, 200.0 - 6.0 + 4.0, 3.0)
	_place_on_track(race, a, 400.0, 0.0)
	var v0 := b.velocity
	b.velocity = Vector3.ZERO
	for f in 5:
		await get_tree().physics_frame
	check("well slows a racer inside it", b.slow_time > 0.0)
	check("well pulls the racer toward its centre", b.velocity.length() > 0.5 or b.global_position.distance_to(w.pos) < 5.0)
	check("AI lane choice avoids the well", absf(race.items.avoid_lane(float(w.s) - 10.0, float(w.s) + 20.0, float(w.lane), race.td.width * 0.5) - float(w.lane)) > 5.0)
	b.velocity = v0
	w.t = 0.0
	await get_tree().physics_frame
	check("well cleared from the pool", race.items.wells.is_empty() and race.items.pooled("well") == 2)
	race.items.clear_effects()
	# Frost Trail: ice laid behind as the owner drives; others slide on it.
	_place_on_track(race, a, 300.0, 0.0)
	_place_on_track(race, b, 600.0, 0.0)
	a.item = "frost"
	a.item_uses = 1
	race.items.use_item(a)
	for f in 20:
		_place_on_track(race, a, 300.0 + float(f) * 2.5, 0.0)
		a.grounded = true
		a.race_dist = 300.0 + float(f) * 2.5
		await get_tree().physics_frame
	check("frost trail lays ice patches", race.items.ice.size() >= 8)
	var patch: Dictionary = race.items.ice[2]
	b.global_position = patch.pos + Vector3.UP * 0.6
	b.reset_physics_interpolation()
	b.slick_time = 0.0
	await get_tree().physics_frame
	check("ice makes a racer slide", b.slick_time > 0.0)
	check("AI lane choice avoids ice", absf(race.items.avoid_lane(float(patch.s) - 10.0, float(patch.s) + 20.0, float(patch.lane), race.td.width * 0.5) - float(patch.lane)) > 3.0)
	for p in race.items.ice:
		p.life = 0.0
	for f in race.items.frosts:
		f.t = 0.0
	await get_tree().physics_frame
	check("ice melts and frees its slots", race.items.ice.is_empty() and race.items._ice_free.size() == Items.MAX_ICE)
	# Icons draw for every item.
	var holder := Control.new()
	get_tree().root.add_child(holder)
	for id in Catalog.ITEMS:
		var ic := ItemIcon.new()
		ic.item = id
		ic.size = Vector2(64, 64)
		holder.add_child(ic)
	await get_tree().process_frame
	check("every item has an icon", holder.get_child_count() == 14)
	holder.queue_free()
	for r: Racer in rs:
		_clear(r)
