extends Control
## Every menu screen: title, home, play modes (cups, quick race, time trial,
## boss races, daily challenge, 2 players), garage, pilots, achievements,
## stats, settings and how to play. Built in code on top of a 3D backdrop.

var stage: MenuStage
var content: Control
var header_title: Label
var credits_lbl: Label
var stars_lbl: Label
var back_btn: Button
var _screen := ""
var _history: Array[String] = []
var _sel := {}            # per-screen selections (track, variant, class, ...)
var _toast: Label
var _swallow_until := 0
var _fab := Callable()     # start button pinned bottom-right on track pickers
var _fab_text := ""


func _ready() -> void:
	theme = UiKit.theme()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 3D backdrop.
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	svc.add_child(sv)
	stage = MenuStage.new()
	sv.add_child(stage)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.0, 0.06, 0.25)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	# Layout: header + content.
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var col := UiKit.vbox(14)
	margin.add_child(col)
	var header := UiKit.hbox(14)
	col.add_child(header)
	back_btn = UiKit.button("◀ Back", go_back, 22, 130)
	header.add_child(back_btn)
	header_title = UiKit.label("", 34, UiKit.CYAN)
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_title)
	stars_lbl = UiKit.label("", 24, UiKit.GOLD)
	header.add_child(stars_lbl)
	credits_lbl = UiKit.label("", 24, UiKit.PINK)
	header.add_child(credits_lbl)
	content = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(content)
	_toast = UiKit.label("", 26, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_toast)
	UiKit.place(_toast, Vector2(0.5, 1), Vector2(-400, -70), Vector2(800, 50))
	Audio.music("menu")
	Game.orientation_changed.connect(func() -> void:
		if _screen != "":
			show_screen(_screen, false))
	var hint := Game.menu_hint
	Game.menu_hint = ""
	if hint != "":
		_history = ["home"]
		show_screen(hint)
	elif not Save.data.tutorial_done:
		show_screen("title")
	else:
		show_screen("title")


## The title screen takes any tap, click, key or button. This runs before
## the menu's controls see the event: they cover the screen and would
## otherwise swallow taps and clicks, so only keys and pads got through.
func _input(e: InputEvent) -> void:
	var pointer := e is InputEventScreenTouch or e is InputEventMouseButton or e is InputEventScreenDrag or e is InputEventMouseMotion
	if pointer and Time.get_ticks_msec() < _swallow_until:
		# The rest of the tap that left the title (its release, and the
		# mouse events a phone makes from it) must not press a button on
		# the next screen.
		get_viewport().set_input_as_handled()
		return
	if _screen != "title":
		return
	var tap := e is InputEventScreenTouch or e is InputEventMouseButton or e is InputEventKey or e is InputEventJoypadButton
	if tap and e.is_pressed():
		get_viewport().set_input_as_handled()
		_swallow_until = Time.get_ticks_msec() + 400
		show_screen("howto" if not Save.data.tutorial_done else "home")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") and _screen != "title" and _screen != "home":
		go_back()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _screen != "home" and _screen != "title":
		go_back()


func toast(text: String, color := UiKit.GOLD) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)


func go_back() -> void:
	if _history.is_empty():
		show_screen("home", false)
		return
	show_screen(_history.pop_back(), false)


func refresh_header() -> void:
	credits_lbl.text = "%s CR" % UiKit.num(Save.credits())
	stars_lbl.text = "★ %d" % Save.total_stars()


func show_screen(sname: String, push := true) -> void:
	if push and _screen != "" and _screen != sname and _screen != "title":
		_history.append(_screen)
	_screen = sname
	_fab = Callable()
	for c in content.get_children():
		c.queue_free()
	refresh_header()
	back_btn.visible = sname != "home" and sname != "title"
	stage.show_look(Save.player_look())
	stage.frame(3.6 if sname != "title" else 0.0)
	var title := ""
	var root: Control
	match sname:
		"title":
			root = _title()
		"home":
			title = "COSMIC SAUCER DRIFT"
			root = _home()
		"play":
			title = "Play"
			root = _play()
		"cups":
			title = "Galactic Cups"
			root = _cups()
		"quick":
			title = "Quick Race"
			root = _track_picker("quick")
		"tt":
			title = "Time Trial"
			root = _track_picker("tt")
		"versus":
			title = "2 Players"
			root = _versus()
		"bosses":
			title = "Boss Races"
			root = _bosses()
		"daily":
			title = "Daily Challenge"
			root = _daily()
		"garage":
			title = "Hangar"
			root = _garage()
		"pilots":
			title = "Pilots"
			root = _pilots()
		"achievements":
			title = "Achievements"
			root = _achievements()
		"stats":
			title = "Career Stats"
			root = _stats()
		"settings":
			title = "Settings"
			root = _settings()
		"howto":
			title = "How to Play"
			root = _howto()
		"store":
			title = "Store"
			root = _store()
		_:
			root = _home()
	header_title.text = title
	header_title.get_parent().visible = sname != "title"
	content.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# On phones the start button at the end of a long track list is off
	# screen; keep one pinned in the corner as well.
	if _fab.is_valid():
		var fab := UiKit.button(_fab_text, _fab, 34, 280)
		fab.name = "PinnedStart"
		fab.custom_minimum_size.y = 84
		content.add_child(fab)
		UiKit.place(fab, Vector2(1, 1), Vector2(-300, -96), Vector2(290, 88))
	_focus_first(root)


func _focus_first(n: Node) -> void:
	await get_tree().process_frame
	if not is_instance_valid(n):
		return
	var b := _find_button(n)
	if b and is_instance_valid(b) and b.is_inside_tree():
		b.grab_focus()


func _find_button(n: Node) -> Button:
	if n is Button and (n as Button).visible and not (n as Button).disabled:
		return n
	for c in n.get_children():
		var f := _find_button(c)
		if f:
			return f
	return null


# ---------------------------------------------------------------- helpers
## Width available for a screen's panel (the viewport minus the margins).
func _avail_w() -> float:
	return get_viewport().get_visible_rect().size.x - 52.0


func _left_panel(width := 640.0) -> Array:
	## Returns [root, inner vbox]: a scrollable panel on the left.
	var root := HBoxContainer.new()
	var p := PanelContainer.new()
	# Never wider than the screen (portrait phones are 720 units wide).
	width = minf(width, _avail_w())
	p.custom_minimum_size = Vector2(width, 0)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(p)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	var v := UiKit.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	return [root, v]


func _row(parent: Control, items: Array) -> HBoxContainer:
	var h := UiKit.hbox(10)
	parent.add_child(h)
	for it in items:
		h.add_child(it)
	return h


func _wrap(text: String, size := 20, color := UiKit.DIM) -> Label:
	var l := UiKit.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _bar(frac: float, color: Color, w := 220.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 16)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.draw.connect(func() -> void:
		c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0, 0, 0, 0.5))
		c.draw_rect(Rect2(Vector2.ZERO, Vector2(c.size.x * clampf(frac, 0.0, 1.0), c.size.y)), color))
	return c


func _stars_text(mask: int) -> String:
	var s := ""
	for b in 3:
		s += "★" if (mask >> b) & 1 else "☆"
	return s


# ---------------------------------------------------------------- title & home
func _title() -> Control:
	var root := Control.new()
	var v := UiKit.vbox(6)
	root.add_child(v)
	UiKit.place(v, Vector2(0.5, 0.0), Vector2(-500, 30), Vector2(1000, 260))
	var tk := clampf(_avail_w() / 1100.0, 0.6, 1.0)
	var t1 := UiKit.label("COSMIC SAUCER", int(92 * tk), UiKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(t1)
	var t2 := UiKit.label("D R I F T", int(64 * tk), UiKit.PINK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(t2)
	var tap := UiKit.label("Tap or press any button", 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(tap)
	UiKit.place(tap, Vector2(0.5, 1.0), Vector2(-400, -110), Vector2(800, 50))
	var tw := tap.create_tween().set_loops()
	tw.tween_property(tap, "modulate:a", 0.25, 0.8)
	tw.tween_property(tap, "modulate:a", 1.0, 0.8)
	var ver := UiKit.label("v%s" % ProjectSettings.get_setting("application/config/version"), 16, UiKit.DIM)
	root.add_child(ver)
	UiKit.place(ver, Vector2(0, 1), Vector2(0, -30), Vector2(200, 24))
	return root


func _home() -> Control:
	var lp := _left_panel(560)
	var v: VBoxContainer = lp[1]
	var play := UiKit.button("PLAY", func() -> void: show_screen("play"), 40, 0)
	play.custom_minimum_size.y = 90
	v.add_child(play)
	var info := Game.daily_info()
	var daily_text := "Daily Challenge" + ("  ✔ done" if info.done else "  ● new!")
	v.add_child(UiKit.button(daily_text, func() -> void: show_screen("daily"), 26))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	var entries: Array = [["Hangar", "garage"], ["Pilots", "pilots"], ["Achievements", "achievements"], ["Stats", "stats"], ["Settings", "settings"], ["How to Play", "howto"]]
	if Store.enabled() and Store.config.show_store_button:
		entries.insert(0, ["Store", "store"])
	for pair in entries:
		var target: String = pair[1]
		var b := UiKit.button(pair[0], func() -> void: show_screen(target), 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(b)
	var look := Save.player_look()
	v.add_child(_wrap("Flying %s with %s  ·  %d / 42 Star Shards" % [Catalog.saucer(look.saucer).name, Catalog.pilot(look.pilot).name, Save.shard_total()], 18))
	return lp[0]


func _play() -> Control:
	var lp := _left_panel(600)
	var v: VBoxContainer = lp[1]
	var entries := [
		["Galactic Cups", "cups", "4 races, points, 3 stars per race. Stars unlock everything."],
		["Quick Race", "quick", "Any unlocked track against 7 rivals."],
		["Time Trial", "tt", "Solo laps against your ghost. Earn medals."],
		["Boss Races", "bosses", "Beat a pilot 1-on-1 to add them to your crew."],
		["Daily Challenge", "daily", "A new twist every day. Keep your streak going."],
		["2 Players", "versus", "Split-screen on one screen with gamepads or a keyboard."],
	]
	for e in entries:
		var target: String = e[1]
		var b := UiKit.button(e[0], func() -> void: show_screen(target), 28)
		v.add_child(b)
		v.add_child(_wrap(e[2], 18))
	return lp[0]


# ---------------------------------------------------------------- cups
func _cups() -> Control:
	var lp := _left_panel(760)
	var v: VBoxContainer = lp[1]
	for cup in Catalog.CUPS:
		var unlocked := Save.cup_unlocked(cup)
		var box := UiKit.vbox(4)
		var p := UiKit.panel(box, Color(cup.color.r * 0.25, cup.color.g * 0.2, cup.color.b * 0.3, 0.9))
		v.add_child(p)
		var have := 0
		var n_races: int = cup.races.size()
		for i in n_races:
			var m := Save.race_stars(cup.id, i)
			have += (m & 1) + ((m >> 1) & 1) + ((m >> 2) & 1)
		var best := int(Save.data.cup_best.get(cup.id, 0))
		var trophy := ""
		if best >= 1 and best <= 3:
			trophy = "   %s trophy" % ["Gold", "Silver", "Bronze"][best - 1]
		_row(box, [UiKit.label(cup.name, 28, cup.color), UiKit.label("  ★ %d/%d%s" % [have, n_races * 3, trophy], 22, UiKit.GOLD)])
		var sysd: Dictionary = Catalog.SYSTEMS.get(cup.system, {})
		if not sysd.is_empty():
			box.add_child(_wrap("%s - %s" % [sysd.distance.capitalize() if sysd.distance == "home" else sysd.distance, sysd.text], 16, UiKit.DIM))
		else:
			box.add_child(_wrap("The finale: reverse and mirror tracks from every system against Legend-class rivals.", 16, UiKit.DIM))
		var cls: Dictionary = Catalog.AI_CLASSES[int(cup["class"])]
		for i in n_races:
			var r: Array = cup.races[i]
			var td_name: String = TrackDefs.get_def(r[0]).name
			var var_name: String = Catalog.VARIANT_NAMES[int(r[1])]
			box.add_child(UiKit.label("%d. %s %s   %s   %s" % [i + 1, td_name, var_name, _stars_text(Save.race_stars(cup.id, i)), Catalog.CHALLENGES[r[2]][0]], 18, Color.WHITE if unlocked else UiKit.DIM))
		if unlocked:
			var cid: String = cup.id
			var b := UiKit.button("Start %s  (%s rivals)" % [cup.name, cls.name], func() -> void: Game.start(Game.cup_request(cid, 0)), 22)
			box.add_child(b)
		else:
			box.add_child(UiKit.label("Locked: earn %d stars (you have %d)" % [cup.stars, Save.total_stars()], 20, UiKit.RED))
	return lp[0]


# ---------------------------------------------------------------- track picker (quick race / time trial)
func _track_picker(mode: String) -> Control:
	var lp := _left_panel(780)
	var v: VBoxContainer = lp[1]
	if not _sel.has(mode + "_track"):
		_sel[mode + "_track"] = "mars"
		_sel[mode + "_variant"] = 0
	if not _sel.has("class"):
		_sel["class"] = clampi(int(Save.setting("difficulty")), 0, 3)
	var grid: GridContainer = null
	var last_sys := ""
	for id in Catalog.TRACK_IDS:
		var tid: String = id
		var def := TrackDefs.get_def(tid)
		if def.system != last_sys:
			last_sys = def.system
			var sysd: Dictionary = Catalog.SYSTEMS[last_sys]
			v.add_child(UiKit.label("%s  ·  %s" % [sysd.name, sysd.distance], 20, UiKit.GOLD))
			grid = GridContainer.new()
			# One column on a narrow (portrait) screen so names aren't cut off.
			grid.columns = 2 if _avail_w() >= 900.0 else 1
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 8)
			v.add_child(grid)
		var open := Save.track_unlocked(tid)
		var b := UiKit.button(def.name if open else def.name + " (locked)", func() -> void:
			_sel[mode + "_track"] = tid
			if not Save.variant_unlocked(tid, int(_sel[mode + "_variant"])):
				_sel[mode + "_variant"] = 0
			show_screen(mode, false), 22)
		b.disabled = not open
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if tid == _sel[mode + "_track"]:
			b.add_theme_stylebox_override("normal", UiKit.box(Color(0.25, 0.15, 0.5), 16, UiKit.GOLD, 3))
		grid.add_child(b)
	var cur: String = _sel[mode + "_track"]
	var cdef := TrackDefs.get_def(cur)
	v.add_child(UiKit.label(cdef.name, 30, UiKit.CYAN))
	v.add_child(_wrap(cdef.blurb, 20))
	v.add_child(_fact_card(cur))
	var vrow := UiKit.hbox(10)
	v.add_child(vrow)
	for vi in 3:
		var vv := vi
		var unlocked := Save.variant_unlocked(cur, vv)
		var label: String = ["Normal", "Reverse", "Mirror"][vv] if unlocked else "%s (win Normal)" % ["Normal", "Reverse", "Mirror"][vv]
		var b := UiKit.button(label, func() -> void:
			_sel[mode + "_variant"] = vv
			show_screen(mode, false), 20)
		b.disabled = not unlocked
		if vv == int(_sel[mode + "_variant"]):
			b.add_theme_stylebox_override("normal", UiKit.box(Color(0.25, 0.15, 0.5), 16, UiKit.GOLD, 3))
		vrow.add_child(b)
	var var_i: int = _sel[mode + "_variant"]
	var key := "%s:%d" % [cur, var_i]
	var shards: Array = Save.shards_for(cur)
	var sh_n := 0
	for s in shards:
		if s:
			sh_n += 1
	v.add_child(UiKit.label("Star Shards found: %d/3   Best lap: %s" % [sh_n, UiKit.time_str(float(Save.data.best_lap.get(key, 0.0)))], 20, UiKit.GOLD))
	if mode == "quick":
		var crow := UiKit.hbox(8)
		v.add_child(crow)
		crow.add_child(UiKit.label("Rivals:", 22))
		for ci in 4:
			var cc := ci
			var b := UiKit.button(Catalog.AI_CLASSES[cc].name, func() -> void:
				_sel["class"] = cc
				Save.set_setting("difficulty", cc)
				show_screen(mode, false), 20)
			if cc == int(_sel["class"]):
				b.add_theme_stylebox_override("normal", UiKit.box(Color(0.25, 0.15, 0.5), 16, UiKit.GOLD, 3))
			crow.add_child(b)
		_fab = func() -> void: Game.start(Game.quick_request(cur, var_i, int(_sel["class"])))
		_fab_text = "RACE ▶"
		var go := UiKit.button("RACE ▶", func() -> void: Game.start(Game.quick_request(cur, var_i, int(_sel["class"]))), 32)
		v.add_child(go)
		UiKit.focus_later(go)
		_free_item_offer(v, func() -> Dictionary: return Game.quick_request(cur, var_i, int(_sel["class"])))
	else:
		var td := TrackData.make(cur, var_i)
		var best: float = Save.data.best_time.get(key, 0.0)
		var medal := int(Save.data.medals.get(key, 0))
		v.add_child(UiKit.label("Best: %s   Medal: %s" % [UiKit.time_str(best), ["none", "Bronze", "Silver", "Gold"][medal]], 22))
		v.add_child(UiKit.label("Bronze %s · Silver %s · Gold %s" % [UiKit.time_str(Game.tt_target(td, 1)), UiKit.time_str(Game.tt_target(td, 2)), UiKit.time_str(Game.tt_target(td, 3))], 20, UiKit.DIM))
		v.add_child(_wrap("No crates or rivals: just you, the Energy Pods and your ghost.", 18))
		_fab = func() -> void: Game.start(Game.tt_request(cur, var_i))
		_fab_text = "START ▶"
		var go := UiKit.button("START TRIAL ▶", func() -> void: Game.start(Game.tt_request(cur, var_i)), 32)
		v.add_child(go)
	return lp[0]


# ---------------------------------------------------------------- store (real money, off in v1)
func _store() -> Control:
	var lp := _left_panel(760)
	var v: VBoxContainer = lp[1]
	if not Store.enabled():
		v.add_child(_wrap("The store isn't open in this version. Every craft can be unlocked with Race Credits in the Hangar.", 20))
		return lp[0]
	for p in Store.PRODUCTS:
		var pid: String = p.id
		var row := UiKit.hbox(10)
		v.add_child(row)
		var title := pid
		match String(p.type):
			"craft":
				title = Catalog.saucer(p.grant).name
			"bundle":
				title = "Premium Fleet (all 4 premium craft)"
			"credits":
				title = "%s Race Credits" % UiKit.num(int(p.grant))
			"entitlement":
				title = "Remove ads"
		var l := UiKit.label(title, 20)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if Store.owned(pid):
			row.add_child(UiKit.label("Owned", 18, UiKit.GREEN))
		else:
			var b := UiKit.button(Store.price_text(pid), func() -> void: pass, 20, 140)
			b.pressed.connect(func() -> void:
				b.disabled = true
				Store.buy(pid, func(_ok: bool) -> void: show_screen("store", false)))
			row.add_child(b)
	v.add_child(UiKit.button("Restore purchases", func() -> void:
		Store.restore(func(n: int) -> void:
			toast("Restored %d item(s)" % n)
			show_screen("store", false)), 20))
	return lp[0]


## Real-world facts about a track's planet or moon.
func _fact_card(track_id: String) -> Control:
	var def := TrackDefs.get_def(track_id)
	var box := UiKit.vbox(2)
	var sysd: Dictionary = Catalog.SYSTEMS.get(def.get("system", ""), {})
	if not sysd.is_empty():
		box.add_child(UiKit.label("Real world · %s · %s" % [sysd.name, sysd.star], 16, UiKit.GOLD))
	for f in def.get("facts", []):
		box.add_child(_wrap("• " + str(f), 17, Color(0.85, 0.88, 1.0)))
	return UiKit.panel(box, Color(0.08, 0.1, 0.22, 0.9))


## Rewarded-ad placement "free_item": only appears when ads are switched on.
func _free_item_offer(parent: Control, make_req: Callable) -> void:
	if not Ads.can_offer("free_item"):
		return
	var b := UiKit.button("▶ Watch an ad: start holding a free item", func() -> void: pass, 20)
	b.pressed.connect(func() -> void:
		b.disabled = true
		Ads.show_rewarded("free_item", func(granted: bool) -> void:
			var req: Dictionary = make_req.call()
			req["free_item"] = granted
			Game.start(req)))
	parent.add_child(b)


# ---------------------------------------------------------------- versus
func _versus() -> Control:
	var lp := _left_panel(780)
	var v: VBoxContainer = lp[1]
	var p2: Dictionary = Save.data.garage.get("p2", {"pilot": "nova", "saucer": "bubble"})
	v.add_child(_wrap("Player 1 uses your Hangar craft and pilot. Player 2 picks below. Keyboard: P1 = WASD, Space drift, E item. P2 = arrows, / drift, . item. Or plug in two gamepads.", 18))
	var pilots: Array = []
	for p in Catalog.PILOTS:
		if Save.has_pilot(p.id):
			pilots.append(p.id)
	var saucers: Array = []
	for s in Catalog.SAUCERS:
		if Save.has_saucer(s.id):
			saucers.append(s.id)
	var cycle := func(list: Array, cur: String, key: String) -> void:
		var i := list.find(cur)
		var nxt: String = list[(i + 1) % list.size()]
		var g2: Dictionary = Save.data.garage.get("p2", {"pilot": "nova", "saucer": "bubble"})
		g2[key] = nxt
		Save.data.garage["p2"] = g2
		Save.mark()
		stage.show_look(Save.look_for(g2.get("saucer", "bubble"), g2.get("pilot", "nova")))
		show_screen("versus", false)
	v.add_child(UiKit.button("P2 pilot: %s ▸" % Catalog.pilot(p2.get("pilot", "nova")).name, func() -> void: cycle.call(pilots, p2.get("pilot", "nova"), "pilot"), 22))
	v.add_child(UiKit.button("P2 craft: %s ▸" % Catalog.saucer(p2.get("saucer", "bubble")).name, func() -> void: cycle.call(saucers, p2.get("saucer", "bubble"), "saucer"), 22))
	if not _sel.has("versus_track"):
		_sel["versus_track"] = "asteroid_belt"
	var tracks: Array = []
	for id in Catalog.TRACK_IDS:
		if Save.track_unlocked(id):
			tracks.append(id)
	var cur: String = _sel["versus_track"]
	v.add_child(UiKit.button("Track: %s ▸" % TrackDefs.get_def(cur).name, func() -> void:
		_sel["versus_track"] = tracks[(tracks.find(cur) + 1) % tracks.size()]
		show_screen("versus", false), 22))
	var pads := Input.get_connected_joypads().size()
	v.add_child(UiKit.label("Gamepads connected: %d" % pads, 20, UiKit.GREEN if pads >= 1 else UiKit.DIM))
	v.add_child(UiKit.button("START 2-PLAYER RACE ▶", func() -> void:
		InputRouter.two_player = true
		Game.start(Game.versus_request(cur, 0, int(Save.setting("difficulty")))), 30))
	return lp[0]


# ---------------------------------------------------------------- bosses
func _bosses() -> Control:
	var lp := _left_panel(800)
	var v: VBoxContainer = lp[1]
	v.add_child(_wrap("Each boss races you 1-on-1 on their home track. Win to add them to your crew and use their ability.", 18))
	for p in Catalog.PILOTS:
		if p.unlock != "boss":
			continue
		var box := UiKit.vbox(4)
		v.add_child(UiKit.panel(box))
		var beaten: bool = Save.data.bosses.get(p.id, false)
		var ready := Save.total_stars() >= int(p.stars)
		_row(box, [UiKit.label(p.name, 26, p.color), UiKit.label("  " + ("BEATEN" if beaten else ("READY" if ready else "needs %d stars" % p.stars)), 20, UiKit.GREEN if beaten else (UiKit.GOLD if ready else UiKit.RED))])
		box.add_child(UiKit.label("%s: %s" % [p.passive_name, p.passive_text], 18, Color.WHITE))
		box.add_child(UiKit.label("Home track: %s · Drives %s" % [TrackDefs.get_def(p.home).name, {"clean": "a clean racing line", "aggressive": "aggressively, bumps and fires early", "hoarder": "defensively, hoards items"}[p.style]], 18, UiKit.DIM))
		if ready:
			var pid: String = p.id
			box.add_child(UiKit.button("Race %s%s" % [p.name, " again" if beaten else ""], func() -> void: Game.start(Game.boss_request(pid)), 22))
	return lp[0]


# ---------------------------------------------------------------- daily
func _daily() -> Control:
	var lp := _left_panel(760)
	var v: VBoxContainer = lp[1]
	var info := Game.daily_info()
	v.add_child(UiKit.label(info.date, 22, UiKit.DIM))
	v.add_child(UiKit.label("%s %s" % [TrackDefs.get_def(info.track).name, Catalog.VARIANT_NAMES[info.variant]], 30, UiKit.CYAN))
	v.add_child(UiKit.label("Twist: %s" % info.mod.name, 26, UiKit.PINK))
	v.add_child(_wrap(info.mod.text, 20, Color.WHITE))
	v.add_child(UiKit.label("Goal: %s" % info.goal.text, 24, UiKit.GOLD))
	var streak := int(Save.data.daily.streak)
	v.add_child(UiKit.label("Reward: %d Race Credits   Streak: %d (best %d)" % [info.reward, streak, int(Save.data.daily.best_streak)], 20))
	v.add_child(_wrap("Finish on consecutive days to grow your streak: +60 credits a day, up to a week. Works offline.", 18))
	if info.done:
		v.add_child(UiKit.label("Done for today. New challenge tomorrow!", 24, UiKit.GREEN))
		v.add_child(UiKit.button("Race it again (no reward)", func() -> void: Game.start(Game.daily_request()), 22))
	else:
		var go := UiKit.button("START CHALLENGE ▶", func() -> void: Game.start(Game.daily_request()), 32)
		v.add_child(go)
	return lp[0]


# ---------------------------------------------------------------- garage
func _garage() -> Control:
	var lp := _left_panel(720)
	var v: VBoxContainer = lp[1]
	var g: Dictionary = Save.data.garage
	if not _sel.has("garage_saucer"):
		_sel["garage_saucer"] = g.saucer
	if not _sel.has("garage_tab"):
		_sel["garage_tab"] = "upgrades"
	var sid: String = _sel["garage_saucer"]
	var sdef := Catalog.saucer(sid)
	stage.show_look(Save.look_for(sid, g.pilot))
	# Craft picker: standard fleet, then premium.
	for group in [["Alien fleet", false], ["Premium craft", true]]:
		v.add_child(UiKit.label(group[0], 18, UiKit.GOLD if group[1] else UiKit.DIM))
		var srow := HFlowContainer.new()
		srow.add_theme_constant_override("h_separation", 8)
		srow.add_theme_constant_override("v_separation", 8)
		v.add_child(srow)
		for s in Catalog.SAUCERS:
			if bool(s.get("premium", false)) != group[1]:
				continue
			var id: String = s.id
			var b := UiKit.button(("★ " if s.get("premium", false) else "") + s.name, func() -> void:
				_sel["garage_saucer"] = id
				show_screen("garage", false), 18)
			if id == sid:
				b.add_theme_stylebox_override("normal", UiKit.box(Color(0.25, 0.15, 0.5), 16, UiKit.GOLD, 3))
			elif s.get("premium", false):
				b.add_theme_stylebox_override("normal", UiKit.box(Color(0.22, 0.14, 0.08), 16, UiKit.GOLD.darkened(0.2), 2))
			if not Save.has_saucer(id):
				b.modulate = Color(1, 1, 1, 0.6)
			srow.add_child(b)
	v.add_child(UiKit.label(("★ PREMIUM  " if sdef.get("premium", false) else "") + sdef.name, 30, UiKit.GOLD if sdef.get("premium", false) else UiKit.CYAN))
	v.add_child(_wrap(sdef.blurb, 18))
	if sdef.has("perk_text"):
		v.add_child(UiKit.label("Perk: " + str(sdef.perk_text), 18, UiKit.GREEN))
	var owned := Save.has_saucer(sid)
	if not owned:
		var can := Save.total_stars() >= int(sdef.stars)
		if not can:
			v.add_child(UiKit.label("Needs %d stars (you have %d)" % [sdef.stars, Save.total_stars()], 22, UiKit.RED))
		var buy := UiKit.button("Unlock for %s CR" % UiKit.num(int(sdef.price)), func() -> void:
			if Save.spend(int(sdef.price)):
				Save.unlock_saucer(sid)
				Events.log_event("purchase", {"type": "saucer", "id": sid, "price": sdef.price})
				toast("%s is yours!" % sdef.name)
				show_screen("garage", false)
			else:
				toast("Not enough Race Credits", UiKit.RED), 24)
		buy.disabled = not can
		v.add_child(buy)
		# Real-money option (store layer: hidden while switched off).
		var pid: String = sdef.get("product", "")
		if pid != "" and Store.can_buy(pid):
			var rb := UiKit.button("Buy now  %s" % Store.price_text(pid), func() -> void: pass, 22)
			rb.pressed.connect(func() -> void:
				rb.disabled = true
				Store.buy(pid, func(ok: bool) -> void:
					toast("%s is yours!" % sdef.name if ok else "Purchase cancelled", UiKit.GOLD if ok else UiKit.DIM)
					show_screen("garage", false)))
			v.add_child(rb)
		if sdef.get("premium", false):
			var races_needed := ceili(maxf(float(int(sdef.price) - Save.credits()), 0.0) / 450.0)
			if races_needed > 0:
				v.add_child(UiKit.label("About %d more race wins' worth of credits to go" % races_needed, 16, UiKit.DIM))
	elif g.saucer != sid:
		v.add_child(UiKit.button("Fly this craft", func() -> void:
			Save.data.garage.saucer = sid
			Save.mark()
			toast("Now flying the %s" % sdef.name)
			show_screen("garage", false), 24))
	else:
		v.add_child(UiKit.label("Currently flying", 20, UiKit.GREEN))
	# Tabs.
	var tabs := UiKit.hbox(6)
	v.add_child(tabs)
	for t in [["upgrades", "Upgrades"], ["paints", "Paint"], ["decals", "Decal"], ["domes", "Dome"], ["trails", "Trail"]]:
		var tid: String = t[0]
		var b := UiKit.button(t[1], func() -> void:
			_sel["garage_tab"] = tid
			show_screen("garage", false), 18)
		if tid == _sel["garage_tab"]:
			b.add_theme_stylebox_override("normal", UiKit.box(Color(0.25, 0.15, 0.5), 16, UiKit.GOLD, 3))
		tabs.add_child(b)
	var tab: String = _sel["garage_tab"]
	if tab == "upgrades":
		for st in Catalog.STAT_KEYS:
			var stat: String = st
			var lvl := Save.upgrade_level(sid, stat)
			var base := float(sdef[stat])
			var val := base + lvl * Catalog.UPGRADE_STEP
			var row := UiKit.hbox(10)
			v.add_child(row)
			var nm := UiKit.label(Catalog.STAT_NAMES[stat], 20)
			nm.custom_minimum_size = Vector2(190, 0)
			row.add_child(nm)
			row.add_child(_bar(val / 12.5, UiKit.CYAN, 200))
			row.add_child(UiKit.label("%d/5" % lvl, 18, UiKit.DIM))
			if lvl < 5:
				var cost: int = Catalog.UPGRADE_COSTS[lvl]
				var ub := UiKit.button("+ %s CR" % UiKit.num(cost), func() -> void:
					if Save.spend(cost):
						Save.set_upgrade(sid, stat, lvl + 1)
						Events.log_event("purchase", {"type": "upgrade", "id": sid + ":" + stat, "price": cost})
						for a in Achievements.check_menu():
							toast("Achievement: " + str(a), UiKit.PINK)
						show_screen("garage", false)
					else:
						toast("Not enough Race Credits", UiKit.RED), 18)
				ub.disabled = not owned
				row.add_child(ub)
	else:
		var list: Array = {"paints": Catalog.PAINTS, "decals": Catalog.DECALS, "domes": Catalog.DOMES, "trails": Catalog.TRAILS}[tab]
		var key: String = {"paints": "paint", "decals": "decal", "domes": "dome", "trails": "trail"}[tab]
		var cur_look := Save.look_for(sid, g.pilot)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		v.add_child(flow)
		for item in list:
			var iid: String = item.id
			var have := Save.owns(tab, iid)
			var price: int = item.price
			var text: String = item.name if have else "%s  %s CR" % [item.name, UiKit.num(price)]
			var b := UiKit.button(text, func() -> void:
				if not Save.owns(tab, iid):
					if not Save.spend(price):
						toast("Not enough Race Credits", UiKit.RED)
						return
					Save.buy(tab, iid)
					Events.log_event("purchase", {"type": tab, "id": iid, "price": price})
					for a in Achievements.check_menu():
						toast("Achievement: " + str(a), UiKit.PINK)
				Save.set_look(sid, key, iid)
				show_screen("garage", false), 18)
			if item.has("color") and Color(item.color).a > 0.0:
				var c: Color = item.color
				b.add_theme_stylebox_override("normal", UiKit.box(Color(c.r * 0.5, c.g * 0.5, c.b * 0.5, 0.95), 16, c, 3))
			if cur_look[key] == iid:
				b.text = "✔ " + b.text
			flow.add_child(b)
		v.add_child(_wrap("Cosmetics change looks only, never speed.", 16))
	return lp[0]


# ---------------------------------------------------------------- pilots
func _pilots() -> Control:
	var lp := _left_panel(780)
	var v: VBoxContainer = lp[1]
	var cur: String = Save.data.garage.pilot
	for p in Catalog.PILOTS:
		var box := UiKit.vbox(2)
		v.add_child(UiKit.panel(box))
		var have := Save.has_pilot(p.id)
		_row(box, [UiKit.label(p.name, 26, p.color), UiKit.label("  " + ("✔ selected" if p.id == cur else ""), 20, UiKit.GREEN)])
		box.add_child(UiKit.label("%s: %s" % [p.passive_name, p.passive_text], 18, Color.WHITE))
		if have:
			if p.id != cur:
				var pid: String = p.id
				box.add_child(UiKit.button("Choose %s" % p.name, func() -> void:
					Save.data.garage.pilot = pid
					Save.mark()
					stage.show_look(Save.player_look())
					show_screen("pilots", false), 20))
		else:
			box.add_child(UiKit.label("Beat them in a Boss Race (needs %d stars)" % p.stars, 18, UiKit.RED))
	return lp[0]


# ---------------------------------------------------------------- achievements & stats
func _achievements() -> Control:
	var lp := _left_panel(820)
	var v: VBoxContainer = lp[1]
	var got := 0
	for id in Achievements.LIST:
		if Achievements.unlocked(id):
			got += 1
	v.add_child(UiKit.label("%d / %d unlocked" % [got, Achievements.LIST.size()], 24, UiKit.GOLD))
	for id in Achievements.LIST:
		var a: Array = Achievements.LIST[id]
		var done := Achievements.unlocked(id)
		var p := Achievements.progress(id)
		var row := UiKit.hbox(10)
		v.add_child(row)
		var col := UiKit.vbox(0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(UiKit.label(("✔ " if done else "") + str(a[0]), 22, UiKit.GOLD if done else Color.WHITE))
		col.add_child(UiKit.label("%s  (+%d)" % [a[1], a[5]], 16, UiKit.DIM))
		row.add_child(_bar(p.x / maxf(p.y, 1.0), UiKit.GOLD if done else UiKit.CYAN, 160))
	return lp[0]


func _stats() -> Control:
	var lp := _left_panel(820)
	var v: VBoxContainer = lp[1]
	var rows := [
		["Races", "%d" % Save.stat("races")], ["Wins", "%d" % Save.stat("wins")], ["Podiums", "%d" % Save.stat("podiums")],
		["Cups won", "%d" % Save.stat("cups_won")], ["Bosses beaten", "%d" % Save.stat("bosses")],
		["Distance flown", "%.1f km" % (Save.stat("distance") / 1000.0)], ["Distance drifted", "%.1f km" % (Save.stat("drift_dist") / 1000.0)],
		["Purple boosts", "%d" % Save.stat("purple")], ["Tricks landed", "%d" % Save.stat("tricks")], ["Energy Pods", "%d" % Save.stat("pods")],
		["Item hits", "%d" % Save.stat("hits")], ["Near misses", "%d" % Save.stat("near")], ["Slipstreams", "%d" % Save.stat("slips")],
		["Shortcuts taken", "%d" % Save.stat("shortcuts")], ["Top speed", "%d km/h" % Save.stat("top_speed")],
		["Star Shards", "%d / 42" % Save.shard_total()], ["Daily challenges", "%d (best streak %d)" % [Save.stat("dailies"), int(Save.data.daily.best_streak)]],
		["Race Credits earned", "%d" % Save.stat("credits_earned")],
	]
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 30)
	v.add_child(g)
	for r in rows:
		g.add_child(UiKit.label(r[0], 20, UiKit.DIM))
		g.add_child(UiKit.label(r[1], 20))
	v.add_child(UiKit.label("Best times", 24, UiKit.CYAN))
	for id in Catalog.TRACK_IDS:
		for vi in 3:
			var key := "%s:%d" % [id, vi]
			if Save.data.best_time.has(key) or Save.data.best_lap.has(key):
				v.add_child(UiKit.label("%s %s   race %s   lap %s" % [TrackDefs.get_def(id).name, Catalog.VARIANT_NAMES[vi], UiKit.time_str(float(Save.data.best_time.get(key, 0.0))), UiKit.time_str(float(Save.data.best_lap.get(key, 0.0)))], 18))
	return lp[0]


# ---------------------------------------------------------------- settings
func _settings() -> Control:
	var lp := _left_panel(820)
	var v: VBoxContainer = lp[1]
	for vol in [["Master volume", "master"], ["Music", "music"], ["Sound effects", "sfx"]]:
		var k: String = vol[1]
		var row := UiKit.hbox(12)
		v.add_child(row)
		var l := UiKit.label(vol[0], 20)
		l.custom_minimum_size = Vector2(220, 0)
		row.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = Save.setting(k)
		s.custom_minimum_size = Vector2(320, 40)
		s.value_changed.connect(func(x: float) -> void:
			Save.set_setting(k, x)
			Audio.apply_volumes())
		row.add_child(s)
	var toggles := [
		["Steering", "steering", ["joystick", "buttons", "tilt"], {"joystick": "Joystick", "buttons": "◀ ▶ buttons", "tilt": "Tilt the phone"}],
		["Auto-drive (touch)", "auto_accel", [true, false], {true: "On: GAS for full power", false: "Off: hold GAS to go"}],
		["Invert tilt", "tilt_invert", [false, true], {true: "On", false: "Off"}],
		["Vibration", "haptics", [true, false], {true: "On", false: "Off"}],
		["Screen shake", "shake", [true, false], {true: "On", false: "Off"}],
		["Camera", "camera", ["far", "near"], {"far": "Far", "near": "Close"}],
		["Cockpit view (first person)", "cockpit", [false, true], {false: "Off: chase camera", true: "On"}],
		["Graphics", "quality", ["auto", "low", "medium", "high", "ultra"], {"auto": "Auto", "low": "Low", "medium": "Medium", "high": "High", "ultra": "Ultra"}],
		["Mouse controls", "mouse_controls", [true, false], {true: "On: stick + throttle", false: "Off"}],
		["Key hints (keyboard/mouse)", "key_hints", [true, false], {true: "On", false: "Off"}],
		["Show FPS", "show_fps", [false, true], {true: "On", false: "Off"}],
		["Frame cap", "fps_cap", [0, 30], {0: "Off (smoothest)", 30: "30 fps (battery)"}],
		["Glide deploy", "glide_auto", [false, true], {false: "Hold SHIFT (pad: D-pad up)", true: "Automatic (as on touch)"}],
	]
	for t in toggles:
		var key: String = t[1]
		var opts: Array = t[2]
		var names: Dictionary = t[3]
		var row := UiKit.hbox(12)
		v.add_child(row)
		var l := UiKit.label(t[0], 20)
		l.custom_minimum_size = Vector2(320, 0)
		row.add_child(l)
		var cur: Variant = Save.setting(key)
		var shown := str(names.get(cur, str(cur)))
		if key == "quality" and cur == "auto":
			shown = "Auto (%s)" % String(Game.detected_quality).capitalize()
		var b := UiKit.button(shown + " ▸", func() -> void:
			var i := opts.find(Save.setting(key))
			Save.set_setting(key, opts[(i + 1) % opts.size()])
			show_screen("settings", false), 20, 260)
		row.add_child(b)
	var srow := UiKit.hbox(12)
	v.add_child(srow)
	var sl := UiKit.label("Tilt sensitivity", 20)
	sl.custom_minimum_size = Vector2(220, 0)
	srow.add_child(sl)
	var ts := HSlider.new()
	ts.min_value = 0.4
	ts.max_value = 2.0
	ts.step = 0.1
	ts.value = Save.setting("tilt_sensitivity")
	ts.custom_minimum_size = Vector2(320, 40)
	ts.value_changed.connect(func(x: float) -> void: Save.set_setting("tilt_sensitivity", x))
	srow.add_child(ts)
	v.add_child(_wrap("Privacy: Cosmic Saucer Drift collects no personal data. Progress is saved only on this device. No ads in this version.", 16))
	var reset := UiKit.button("Reset all progress…", func() -> void: pass, 20)
	reset.pressed.connect(func() -> void:
		if reset.text.begins_with("Tap again"):
			Save.reset_all()
			toast("Progress reset", UiKit.RED)
			show_screen("home", false)
		else:
			reset.text = "Tap again to erase everything")
	v.add_child(reset)
	v.add_child(UiKit.label("Cosmic Saucer Drift v%s · made with Godot" % ProjectSettings.get_setting("application/config/version"), 16, UiKit.DIM))
	return lp[0]


# ---------------------------------------------------------------- how to play
func _howto() -> Control:
	var lp := _left_panel(860)
	var v: VBoxContainer = lp[1]
	var touch := InputRouter.touch_seen
	var lines := [
		["Steer & go", "Your saucer drives itself. Steer with the joystick: put your thumb down anywhere in the lower left and slide. Push the stick up (or hold the GAS pedal) for full power; pull it down (or hold BRAKE) to slow down. Brake into a corner to turn tighter; keep holding when stopped to reverse. (◀ ▶ buttons or tilt steering in Settings.)" if touch else "Keyboard: A/D or the arrows steer, W/Up is gas, S/Down brakes; the on-screen joystick shows what you're pressing. Mouse: it's a flight stick and throttle lever. Slide left/right to steer, push forward for full power, pull back to brake (it stays where you leave it; click to capture the pointer, Esc frees it). Left button drifts, right button fires your item, middle button looks back. Gamepad: stick, RT gas, LT brake."],
		["Cockpit view", "Tap the COCKPIT tab on the left edge of the screen any time in a race to fly first-person from your pilot's seat, and tap it again for the chase camera (keyboard: V, gamepad: Back). The game remembers your choice."],
		["Drift = Plasma Boost", "Hold DRIFT while steering into a corner. Sparks turn blue, orange, then purple. Let go to boost: the longer the drift, the bigger the boost."],
		["Keep your core charged", "Your Dark Matter core drains as you fly. Grab glowing Energy Pods, land tricks, slipstream and near-miss hazards to refill it. If it empties you drop into a slow Emergency Hover until you grab a pod."],
		["Tricks", "Press DRIFT while in the air (off ramps, geysers, bouncy moss) to spin. Land it cleanly for a boost and energy. Land mid-spin and you wobble."],
		["Glide", "Airborne off a ramp or an edge? Hold SHIFT (D-pad up on a pad; automatic on phones) to unfold energy wings: thrusters hold your speed, you sink slowly and steer hard, so you can aim back at the road. Hold BRAKE to flare and stretch the glide; let go of SHIFT to drop."],
		["Crates & items", "Fly through glowing crates for a random power-up, then press ITEM. Racers further back get stronger items."],
		["Rocket start", "Press gas right as the countdown hits GO. Too early and your engine stalls."],
		["Secrets", "Every track hides a shortcut and 3 Star Shards. Win a track to unlock its Reverse and Mirror versions."],
	]
	for l in lines:
		v.add_child(UiKit.label(l[0], 24, UiKit.CYAN))
		v.add_child(_wrap(l[1], 19, Color.WHITE))
	v.add_child(UiKit.label("Power-ups", 26, UiKit.GOLD))
	for id in Catalog.ITEMS:
		var it: Dictionary = Catalog.ITEMS[id]
		var row := UiKit.hbox(10)
		var icon := ItemIcon.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.item = id
		row.add_child(icon)
		row.add_child(_wrap("%s (%s): %s" % [it.name, it.kind, it.text], 17, Color.WHITE))
		v.add_child(row)
	v.add_child(UiKit.label("Lineups: what each place can pull from a crate", 22, UiKit.CYAN))
	for lu in Catalog.LINEUPS:
		var names: Array = []
		for k in lu.odds:
			names.append(Catalog.ITEMS[k].name + ("" if k != "nitro" else " x%d" % lu.nitro))
		v.add_child(_wrap("%s (%s): %s" % [lu.name, lu.places, ", ".join(names)], 17, Color(0.85, 0.88, 1.0)))
	v.add_child(UiKit.button("Got it! Let's race ▶", func() -> void:
		if not Save.data.tutorial_done:
			Save.data.tutorial_done = true
			Save.mark()
			Events.log_event("tutorial_complete", {})
		show_screen("home", false), 28))
	return lp[0]
