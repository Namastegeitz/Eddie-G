extends Control
## Every menu screen: title, home, play modes (cups, quick race, time trial,
## boss races, daily challenge, 2 players), garage, pilots, achievements,
## stats, settings and how to play. Built in code on top of a 3D backdrop.

var stage: MenuStage
var content: Control
var header_title: Label
var credits_lbl: Label
var stars_lbl: Label
var dust_lbl: Label
var back_btn: Button
var _screen := ""
var _history: Array[String] = []
var _sel := {}            # per-screen selections (track, variant, class, ...)
var _toast: Label
var _swallow_until := 0
var _fab := Callable()     # start button pinned bottom-right on track pickers
var _fab_text := ""
var _fab_focus := false    # give the pinned button the focus (Racers page: Enter = START)
var _focus_target: Control = null
var _studio: PortraitStudio
var _portrait_wait := {}   # pilot id -> TextureRects waiting for their portrait
var _rx := {}              # Racers / Pilots page widgets updated in place


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
	dust_lbl = UiKit.label("", 24, Color(1.0, 0.75, 0.95))
	header.add_child(dust_lbl)
	credits_lbl = UiKit.label("", 24, UiKit.PINK)
	header.add_child(credits_lbl)
	content = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(content)
	_toast = UiKit.label("", 26, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_toast)
	_studio = PortraitStudio.new()
	add_child(_studio)
	_studio.portrait_ready.connect(_on_portrait)
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
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _screen != "home" and _screen != "title":
			go_back()
		else:
			Save.flush()
			get_tree().quit()


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
	dust_lbl.text = "✦ %s" % UiKit.num(Upgrades.stardust())


func show_screen(sname: String, push := true) -> void:
	# Re-showing the same screen (after a toggle or purchase) keeps the scroll
	# position and the focused button, so lists don't jump back to the top.
	var keep := {}
	if sname == _screen and not push:
		var sc := _find_scroll(content)
		var f := get_viewport().gui_get_focus_owner()
		keep = {"scroll": sc.scroll_vertical if sc else 0, "focus": _button_index(content, f) if f else -1}
	if push and _screen != "" and _screen != sname and _screen != "title":
		_history.append(_screen)
	_screen = sname
	_fab = Callable()
	_fab_focus = false
	_focus_target = null
	_rx = {}
	for c in content.get_children():
		c.queue_free()
	refresh_header()
	back_btn.visible = sname != "home" and sname != "title"
	# Screens that show a different craft or pilot set the look themselves
	# (showing the player's first built the craft twice per click).
	if not (sname in ["garage", "racers", "pilots"]):
		stage.show_look(Save.player_look())
	stage.frame(3.6 if sname != "title" else 0.0)
	stage.focus_pilot(sname == "racers" or sname == "pilots")
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
		"racers":
			title = "Racers"
			root = _racers()
		"wonders":
			title = "Super Upgrades"
			root = _wonders()
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
		if _fab_focus:
			_focus_target = fab
	if keep.is_empty():
		_focus_first(root)
		# List screens with no buttons (Achievements, Stats): focus Back so a
		# pad or keyboard can still leave (and scroll with follow_focus).
		if _find_button(root) == null and back_btn.visible:
			UiKit.focus_later(back_btn)
	else:
		_restore_view(keep)


func _find_scroll(n: Node) -> ScrollContainer:
	if n is ScrollContainer:
		return n
	for c in n.get_children():
		var f := _find_scroll(c)
		if f:
			return f
	return null


## Position of a button among the screen's buttons (depth first), or -1.
func _button_index(root: Node, target: Control) -> int:
	var list: Array[Button] = []
	_collect_buttons(root, list)
	return list.find(target)


func _collect_buttons(n: Node, out: Array[Button]) -> void:
	if n is Button and not n.is_queued_for_deletion():
		out.append(n)
	for c in n.get_children():
		_collect_buttons(c, out)


func _restore_view(keep: Dictionary) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var sc := _find_scroll(content)
	if sc:
		sc.scroll_vertical = int(keep.get("scroll", 0))
	var list: Array[Button] = []
	_collect_buttons(content, list)
	var i := int(keep.get("focus", -1))
	if i >= 0 and i < list.size() and list[i].is_visible_in_tree() and not list[i].disabled:
		list[i].grab_focus()
	elif not list.is_empty():
		_focus_first(content)


func _focus_first(n: Node) -> void:
	await get_tree().process_frame
	if not is_instance_valid(n):
		return
	var b: Control = _find_button(n)
	if is_instance_valid(_focus_target) and _focus_target.is_inside_tree():
		b = _focus_target
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
	scroll.follow_focus = true   # a pad or keyboard moving down the list scrolls it
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
	# One tap (or Enter / pad A) to race: repeats your last Quick Race setup.
	var lr := Game.last_race()
	var now := UiKit.button("RACE NOW ▶", func() -> void:
		_to_racers(func() -> Dictionary: return Game.race_now_request()), 42, 0)
	now.name = "RaceNow"
	now.custom_minimum_size.y = 100
	now.add_theme_stylebox_override("normal", UiKit.box(Color(0.34, 0.12, 0.46), 18, UiKit.GOLD, 3))
	now.add_theme_stylebox_override("hover", UiKit.box(Color(0.44, 0.16, 0.58), 18, UiKit.GOLD, 3))
	v.add_child(now)
	var lr_name: String = TrackDefs.get_def(lr.track).name
	if int(lr.variant) > 0:
		lr_name += " " + String(Catalog.VARIANT_NAMES[int(lr.variant)])
	v.add_child(UiKit.label("%s  ·  %s rivals" % [lr_name, Catalog.AI_CLASSES[int(lr["class"])].name], 18, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var play := UiKit.button("All game modes", func() -> void: show_screen("play"), 28, 0)
	play.custom_minimum_size.y = 64
	v.add_child(play)
	var info := Game.daily_info()
	var daily_text := "Daily Challenge" + ("  ✔ done" if info.done else "  ● new!")
	v.add_child(UiKit.button(daily_text, func() -> void: show_screen("daily"), 26))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	var entries: Array = [["Hangar", "garage"], ["Pilots", "pilots"], ["Super Upgrades ✦", "wonders"], ["Achievements", "achievements"], ["Stats", "stats"], ["Settings", "settings"], ["How to Play", "howto"]]
	if Store.enabled() and Store.config.show_store_button:
		entries.insert(0, ["Store", "store"])
	for pair in entries:
		var target: String = pair[1]
		var b := UiKit.button(pair[0], func() -> void: show_screen(target), 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(b)
	var look := Save.player_look()
	v.add_child(_wrap("Flying %s with %s  ·  %d / %d Star Shards" % [Catalog.saucer(look.saucer).name, Catalog.pilot(look.pilot).name, Save.shard_total(), Catalog.TRACK_IDS.size() * 3], 18))
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
			var b := UiKit.button("Start %s  (%s rivals)" % [cup.name, cls.name], func() -> void:
				_to_racers(func() -> Dictionary: return Game.cup_request(cid, 0)), 22)
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
	var bdef := BiomeBuilder.pick_for(cur, String(cdef.theme))
	if not bdef.is_empty():
		v.add_child(_wrap("Scenery: %s. %s (Settings > Volcanic biome)" % [bdef.name, bdef.text], 16, Color(1.0, 0.7, 0.45)))
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
		var quick := func() -> void:
			_to_racers(func() -> Dictionary: return Game.quick_request(cur, var_i, int(_sel["class"])))
		_fab = quick
		_fab_text = "RACE ▶"
		var go := UiKit.button("RACE ▶", quick, 32)
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
		var trial := func() -> void:
			_to_racers(func() -> Dictionary: return Game.tt_request(cur, var_i))
		_fab = trial
		_fab_text = "START ▶"
		var go := UiKit.button("START TRIAL ▶", trial, 32)
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
			_to_racers(func() -> Dictionary:
				var req: Dictionary = make_req.call()
				req["free_item"] = granted
				return req)))
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
	if not _sel.has("versus_track") or not Save.track_unlocked(String(_sel["versus_track"])):
		_sel["versus_track"] = "ceres"
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
			box.add_child(UiKit.button("Race %s%s" % [p.name, " again" if beaten else ""], func() -> void:
				_to_racers(func() -> Dictionary: return Game.boss_request(pid)), 22))
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
		v.add_child(UiKit.button("Race it again (no reward)", func() -> void:
			_to_racers(func() -> Dictionary: return Game.daily_request()), 22))
	else:
		var go := UiKit.button("START CHALLENGE ▶", func() -> void:
			_to_racers(func() -> Dictionary: return Game.daily_request()), 32)
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
	# Craft picker: standard fleet, the HD (Meshy) fleet, then premium.
	for group in [["Alien fleet", false, false], ["HD fleet · realistic, with a full 3D cockpit", false, true], ["Premium craft", true, false]]:
		v.add_child(UiKit.label(group[0], 18, UiKit.GOLD if group[1] else (UiKit.CYAN if group[2] else UiKit.DIM)))
		var srow := HFlowContainer.new()
		srow.add_theme_constant_override("h_separation", 8)
		srow.add_theme_constant_override("v_separation", 8)
		v.add_child(srow)
		for s in Catalog.SAUCERS:
			if bool(s.get("premium", false)) != group[1] or bool(s.get("hd", false)) != group[2]:
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
	var mods_tab := "Wonder ✦" if not Upgrades.wonder(sid).is_empty() else "Mods ✦"
	for t in [["upgrades", "Upgrades"], ["mods", mods_tab], ["paints", "Paint"], ["decals", "Decal"], ["domes", "Dome"], ["trails", "Trail"]]:
		var tid: String = t[0]
		var b := UiKit.button(t[1], func() -> void:
			_sel["garage_tab"] = tid
			show_screen("garage", false), 18)
		if tid == _sel["garage_tab"]:
			b.add_theme_stylebox_override("normal", UiKit.box(Color(0.25, 0.15, 0.5), 16, UiKit.GOLD, 3))
		tabs.add_child(b)
	var tab: String = _sel["garage_tab"]
	if tab == "mods":
		v.add_child(_wonder_card(sid, "garage"))
	elif tab == "upgrades":
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


# ---------------------------------------------------------------- super upgrades & wonders
func _wonders() -> Control:
	var lp := _left_panel(900)
	var v: VBoxContainer = lp[1]
	v.add_child(_wrap("✦ Stardust: %s. Earn it with clean, long drifts (no walls, no hits); every finish adds a little more. Spend it on each premium craft's Technical Wonder and on mods for any craft." % UiKit.num(Upgrades.stardust()), 18, Color(1.0, 0.8, 0.95)))
	var grid := GridContainer.new()
	grid.columns = 2 if _avail_w() >= 1100.0 else 1
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for w: Dictionary in Content.wonders:
		var card := _wonder_card(String(w.craft), "wonders")
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
	# Global perks.
	var perks := Upgrades.perks()
	v.add_child(UiKit.label("Global perks (every craft)", 22, UiKit.GOLD))
	if perks.is_empty():
		v.add_child(_wrap("Take any Wonder to Transcendent to unlock its perk for your whole fleet.", 17, UiKit.DIM))
	for pk: Dictionary in perks:
		v.add_child(_wrap("✔ %s: %s" % [pk.name, pk.text], 18, UiKit.GREEN))
	# Mod shop.
	v.add_child(UiKit.label("Mod workshop", 22, UiKit.GOLD))
	v.add_child(_wrap("Bought once, fitted to any craft (Hangar > Mods). Three mods of one set on a craft add the set bonus.", 17, UiKit.DIM))
	for sl: Dictionary in Content.slots:
		v.add_child(UiKit.label("%s  ·  %s" % [sl.name, sl.text], 18, UiKit.CYAN))
		for m: Dictionary in Content.mods_for_slot(String(sl.id)):
			v.add_child(_mod_row(m))
	v.add_child(UiKit.label("Sets", 22, UiKit.GOLD))
	for st: Dictionary in Content.sets:
		v.add_child(_wrap("%s set  ·  %s: %s" % [st.name, st.bonus_name, st.bonus_text], 17, st.get("color", UiKit.PINK)))
	return lp[0]


func _mod_row(m: Dictionary) -> Control:
	var row := UiKit.hbox(10)
	var set_def: Dictionary = Content.set_by_id.get(String(m.get("set", "")), {})
	var name := UiKit.label(String(m.name), 19, set_def.get("color", Color.WHITE))
	name.custom_minimum_size = Vector2(230, 0)
	row.add_child(name)
	var txt := ", ".join(Effects.describe(m.effects))
	if not set_def.is_empty():
		txt += "   (%s set)" % set_def.name
	row.add_child(_wrap(txt, 16, UiKit.DIM))
	var mid := String(m.id)
	if Upgrades.owns_mod(mid):
		row.add_child(UiKit.label("Owned", 17, UiKit.GREEN))
	else:
		var cost := int(m.cost)
		var b := UiKit.button("✦ %d" % cost, func() -> void:
			if Upgrades.buy_mod(mid):
				Events.log_event("purchase", {"type": "mod", "id": mid, "stardust": cost})
				toast("%s added to the workshop" % m.name, Color(1.0, 0.8, 0.95))
			else:
				toast("Not enough Stardust - drift clean and long!", UiKit.RED)
			show_screen(_screen, false), 18, 110)
		b.disabled = Upgrades.stardust() < cost
		row.add_child(b)
	return row


## One craft's Super Upgrades card: Wonder tier bar and next tier, mod
## slots (tap to cycle through owned mods), set bonus, overclock with its
## heat meter, and the global perk the Wonder unlocks.
func _wonder_card(craft: String, from_screen: String) -> Control:
	var sdef := Catalog.saucer(craft)
	var w := Upgrades.wonder(craft)
	var owned := Save.has_saucer(craft)
	var box := UiKit.vbox(6)
	var card := PanelContainer.new()
	var accent: Color = w.get("color", UiKit.CYAN) if not w.is_empty() else UiKit.CYAN
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.12, 0.07, 0.24, 0.95), 18, UiKit.GOLD if sdef.get("premium", false) else UiKit.CYAN.darkened(0.4), 3))
	card.add_child(box)
	var title := ("★ " if sdef.get("premium", false) else "") + String(sdef.name)
	_row(box, [UiKit.label(title, 24, UiKit.GOLD if sdef.get("premium", false) else UiKit.CYAN),
		UiKit.label("" if owned else "   (not owned yet)", 16, UiKit.RED)])
	var redraw := func() -> void:
		refresh_header()
		show_screen(from_screen, false)
	if not w.is_empty():
		var t := Upgrades.tier(craft)
		box.add_child(UiKit.label("%s  ·  %s" % [w.name, w.get("tagline", "")], 20, accent))
		box.add_child(_wrap(String(w.text), 15, UiKit.DIM))
		# Tier bar.
		var bar := UiKit.hbox(4)
		box.add_child(bar)
		for i in 3:
			var seg := PanelContainer.new()
			seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var on := i < t
			seg.add_theme_stylebox_override("panel", UiKit.box(accent.darkened(0.35) if on else Color(0, 0, 0, 0.35), 8, accent if on else accent.darkened(0.6), 2))
			var tl := UiKit.label(String(w.tiers[i].name), 14, Color.WHITE if on else UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
			seg.add_child(tl)
			bar.add_child(seg)
		if t > 0:
			box.add_child(_wrap("%s: %s" % [w.tiers[t - 1].name, w.tiers[t - 1].get("text", "")], 15, Color.WHITE))
		var cost := Upgrades.next_cost(craft)
		if cost >= 0:
			var verb: String = ["Build Prototype", "Refine", "Transcend"][t]
			var b := UiKit.button("%s  ✦ %s" % [verb, UiKit.num(cost)], func() -> void:
				if Upgrades.buy_tier(craft):
					Events.log_event("purchase", {"type": "wonder", "id": craft, "tier": Upgrades.tier(craft)})
					toast("%s: %s!" % [w.name, Upgrades.TIER_NAMES[Upgrades.tier(craft)]], accent)
					if Upgrades.tier(craft) == 3:
						toast("Global perk unlocked: %s" % w.global_perk.name, UiKit.GREEN)
				else:
					toast("Not enough Stardust" if owned else "Unlock the craft first", UiKit.RED)
				redraw.call(), 18)
			b.disabled = not owned or Upgrades.stardust() < cost
			box.add_child(b)
		else:
			box.add_child(UiKit.label("✔ Fully transcended", 17, UiKit.GREEN))
		# Overclock + heat meter.
		var lv := Upgrades.overclock(craft)
		var lvd: Dictionary = Upgrades.levels()[lv]
		var orow := UiKit.hbox(8)
		box.add_child(orow)
		var ob := UiKit.button("Overclock %d%% %s ▸" % [int(lvd.pct), lvd.name], func() -> void:
			Upgrades.set_overclock(craft, (Upgrades.overclock(craft) + 1) % Upgrades.levels().size())
			redraw.call(), 16)
		ob.disabled = t == 0
		orow.add_child(ob)
		var heat := Upgrades.heat_per_use(craft, Upgrades.kit_for(craft).get("effects", {}))
		var hc := Color(1.0, 0.6, 0.1).lerp(Color(1.0, 0.15, 0.1), clampf(heat / 60.0, 0.0, 1.0))
		orow.add_child(UiKit.label("Heat", 15, hc))
		orow.add_child(_bar(heat / 100.0, hc, 120))
		var heat_txt := "no heat" if heat <= 0.0 else ("burnout risk!" if heat >= 50.0 else "%d heat a use" % int(heat))
		orow.add_child(UiKit.label(heat_txt, 14, hc if heat > 0.0 else UiKit.DIM))
		# Global perk.
		var gp: Dictionary = w.global_perk
		var have_perk := t >= 3
		box.add_child(_wrap("%s Transcendent perk · %s: %s" % ["✔" if have_perk else "Locked ·", gp.name, gp.text], 15, UiKit.GREEN if have_perk else UiKit.DIM))
	# Mod slots.
	var fit := Upgrades.fitted(craft)
	var srow := HFlowContainer.new()
	srow.add_theme_constant_override("h_separation", 6)
	srow.add_theme_constant_override("v_separation", 6)
	box.add_child(srow)
	for sl: Dictionary in Content.slots:
		var slot := String(sl.id)
		var cur := String(fit.get(slot, ""))
		var label := "%s: %s" % [sl.name, Content.mod_by_id[cur].name if cur != "" else "empty"]
		var mb := UiKit.button(label + " ▸", func() -> void:
			var opts: Array = [""]
			for m: Dictionary in Content.mods_for_slot(slot):
				if Upgrades.owns_mod(String(m.id)):
					opts.append(String(m.id))
			if opts.size() == 1:
				toast("No %s mods yet: buy some in Super Upgrades" % sl.name, UiKit.DIM)
				return
			var i := opts.find(String(Upgrades.fitted(craft).get(slot, "")))
			Upgrades.fit(craft, slot, opts[(i + 1) % opts.size()])
			redraw.call(), 15)
		if cur != "":
			var sd: Dictionary = Content.set_by_id.get(String(Content.mod_by_id[cur].get("set", "")), {})
			if not sd.is_empty():
				mb.add_theme_color_override("font_color", sd.color)
		srow.add_child(mb)
	var sb := Upgrades.set_bonus(craft)
	if not sb.is_empty():
		box.add_child(_wrap("%s set bonus · %s: %s" % [sb.name, sb.bonus_name, sb.bonus_text], 15, sb.get("color", UiKit.PINK)))
	var fx: Dictionary = Upgrades.kit_for(craft).get("effects", {})
	if not fx.is_empty():
		box.add_child(_wrap("In races: " + ", ".join(Effects.describe(fx)), 14, Color(0.8, 0.85, 1.0)))
	if from_screen == "wonders":
		box.add_child(UiKit.button("Open in Hangar ▸", func() -> void:
			_sel["garage_saucer"] = craft
			_sel["garage_tab"] = "mods"
			show_screen("garage"), 15))
	return card


# ---------------------------------------------------------------- pilots & racers
## Every race started from the menus goes through the Racers page: pick your
## pilot, see who you're up against, then START. builder makes the race
## request; it runs again when you switch pilot so no rival shares yours.
func _to_racers(builder: Callable) -> void:
	_sel["racers_builder"] = builder
	_sel["racers_req"] = builder.call()
	_sel.erase("racers_pick")
	show_screen("racers")


func _start_from_racers() -> void:
	var req: Dictionary = _sel.get("racers_req", {})
	if req.is_empty() or Game.is_loading():
		return
	stage.focus_pilot(false)
	Game.start(req)


func _pilots() -> Control:
	var lp := _left_panel(800)
	var v: VBoxContainer = lp[1]
	_pilot_browser(v, false)
	return lp[0]


func _racers() -> Control:
	if not _sel.has("racers_builder"):
		_sel["racers_builder"] = func() -> Dictionary: return Game.race_now_request()
		_sel["racers_req"] = Game.race_now_request()
	var req: Dictionary = _sel["racers_req"]
	var lp := _left_panel(800)
	var v: VBoxContainer = lp[1]
	v.add_child(_wrap(_race_title(req), 22, UiKit.GOLD))
	_pilot_browser(v, true)
	var go := UiKit.button("START ▶", _start_from_racers, 36)
	go.custom_minimum_size.y = 84
	go.add_theme_stylebox_override("normal", UiKit.box(Color(0.34, 0.12, 0.46), 18, UiKit.GOLD, 3))
	v.add_child(go)
	_fab = _start_from_racers
	_fab_text = "START ▶"
	_fab_focus = true
	return lp[0]


func _race_title(req: Dictionary) -> String:
	var track: String = TrackDefs.get_def(String(req.get("track", "mars"))).name
	var vi := int(req.get("variant", 0))
	if vi > 0:
		track += " " + String(Catalog.VARIANT_NAMES[vi])
	match String(req.get("mode", "")):
		"cup":
			return "%s  ·  Race %d: %s" % [Game.cup_def(String(req.cup)).name, int(req.get("cup_race", 0)) + 1, track]
		"tt":
			return "Time Trial  ·  %s" % track
		"boss":
			return "Boss Race vs %s  ·  %s" % [Catalog.pilot(String(req.boss)).name, track]
		"daily":
			return "Daily Challenge  ·  %s  ·  %s" % [track, req.daily.mod.name]
	return "Quick Race  ·  %s  ·  %s rivals" % [track, Catalog.AI_CLASSES[clampi(int(req.get("ai_class", 1)), 0, 3)].name]


## Pilot detail + (race only) rival strip + card grid. Picking a card updates
## the page in place (no rebuild, so the scroll position stays put).
func _pilot_browser(v: VBoxContainer, in_race: bool) -> void:
	if not _sel.has("racers_pick"):
		_sel["racers_pick"] = Save.data.garage.pilot
	var detail := UiKit.hbox(16)
	v.add_child(UiKit.panel(detail))
	var big_holder := CenterContainer.new()
	detail.add_child(big_holder)
	_rx["big_holder"] = big_holder
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_child(info)
	_rx["name"] = UiKit.label("", 32)
	info.add_child(_rx["name"])
	_rx["ability"] = _wrap("", 19, UiKit.GREEN)
	info.add_child(_rx["ability"])
	_rx["blurb"] = _wrap("", 17, UiKit.DIM)
	info.add_child(_rx["blurb"])
	_rx["action"] = UiKit.hbox(8)
	info.add_child(_rx["action"])
	if in_race:
		v.add_child(UiKit.label("Racing against", 18, UiKit.DIM))
		var strip := HFlowContainer.new()
		strip.add_theme_constant_override("h_separation", 6)
		strip.add_theme_constant_override("v_separation", 6)
		v.add_child(strip)
		_rx["strip"] = strip
	v.add_child(UiKit.label("Choose your pilot", 20, UiKit.CYAN))
	var grid := GridContainer.new()
	grid.columns = 4 if _avail_w() >= 900.0 else 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	var cards := {}
	for p in Catalog.PILOTS:
		var pid: String = p.id
		var card := _pilot_card(p, func() -> void: _pick_pilot(pid))
		grid.add_child(card)
		cards[pid] = card
	_rx["cards"] = cards
	_refresh_pilots()


func _pick_pilot(pid: String) -> void:
	_sel["racers_pick"] = pid
	if Save.has_pilot(pid) and pid != Save.data.garage.pilot:
		Save.data.garage.pilot = pid
		Save.mark()
		toast("%s takes the controls" % Catalog.pilot(pid).name, Catalog.pilot(pid).color)
		if _sel.has("racers_builder") and _screen == "racers":
			_sel["racers_req"] = (_sel["racers_builder"] as Callable).call()
	_refresh_pilots()


func _refresh_pilots() -> void:
	if _rx.is_empty():
		return
	var pid: String = _sel.get("racers_pick", Save.data.garage.pilot)
	var p := Catalog.pilot(pid)
	var have := Save.has_pilot(pid)
	stage.show_look(Save.look_for(Save.data.garage.saucer, pid))
	var holder: Control = _rx["big_holder"]
	for c in holder.get_children():
		c.queue_free()
	holder.add_child(_portrait_frame(p, 132))
	var nm: Label = _rx["name"]
	nm.text = p.name + ("   ✦ creature" if p.get("kind", "") == "creature" else "")
	nm.add_theme_color_override("font_color", p.color)
	(_rx["ability"] as Label).text = "%s: %s" % [p.passive_name, p.passive_text]
	var blurb := String(p.get("blurb", ""))
	(_rx["blurb"] as Label).text = blurb if blurb != "" else "Home track: %s." % TrackDefs.get_def(p.home).name
	var action: HBoxContainer = _rx["action"]
	for c in action.get_children():
		c.queue_free()
	if have:
		var flying: bool = pid == Save.data.garage.pilot
		action.add_child(UiKit.label("✔ Your pilot" if flying else "In your crew", 18, UiKit.GREEN))
	elif String(p.get("unlock", "")) == "credits":
		var price := int(p.get("price", 0))
		var buy := UiKit.button("Unlock for %s CR" % UiKit.num(price), func() -> void:
			if Save.buy_pilot(pid):
				Events.log_event("purchase", {"type": "pilot", "id": pid, "price": price})
				toast("%s joins your crew!" % p.name, p.color)
				refresh_header()
				_pick_pilot(pid)
			else:
				toast("Not enough Race Credits", UiKit.RED), 20)
		action.add_child(buy)
	else:
		action.add_child(UiKit.label(Catalog.pilot_unlock_text(p), 17, UiKit.RED))
		action.add_child(UiKit.button("Boss Races ▸", func() -> void: show_screen("bosses"), 18))
	var cards: Dictionary = _rx.get("cards", {})
	for id: String in cards:
		_style_card(cards[id], id == pid, id == Save.data.garage.pilot, Save.has_pilot(id))
	if _rx.has("strip"):
		var strip: HFlowContainer = _rx["strip"]
		for c in strip.get_children():
			c.queue_free()
		var req: Dictionary = _sel.get("racers_req", {})
		var n := 0
		for e: Dictionary in req.get("racers", []):
			if e.get("human", false) and int(e.get("slot", 0)) == 0:
				continue
			var rp := Catalog.pilot(String(e.look.pilot))
			var cell := UiKit.vbox(0)
			cell.add_child(_portrait_frame(rp, 64))
			var l := UiKit.label(rp.name.get_slice(" ", 0), 13, rp.color, HORIZONTAL_ALIGNMENT_CENTER)
			l.custom_minimum_size = Vector2(70, 0)
			cell.add_child(l)
			strip.add_child(cell)
			n += 1
		if n == 0:
			strip.add_child(UiKit.label("Nobody: a solo run against your ghost.", 17, UiKit.DIM))


func _pilot_card(p: Dictionary, on_pick: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 190)
	b.focus_mode = Control.FOCUS_ALL
	b.name = "Card_" + String(p.id)
	b.pressed.connect(func() -> void:
		Audio.ui("click")
		on_pick.call())
	var col := UiKit.vbox(2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(_portrait_frame(p, 110))
	col.add_child(cc)
	var nm := UiKit.label(String(p.name), 17 if String(p.name).length() <= 14 else 14, p.color, HORIZONTAL_ALIGNMENT_CENTER)
	nm.clip_text = true
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(nm)
	var sub := UiKit.label("", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	sub.name = "Sub"
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(sub)
	b.set_meta("pilot", p)
	return b


func _style_card(b: Button, picked: bool, flying: bool, have: bool) -> void:
	var p: Dictionary = b.get_meta("pilot")
	var bg := Color(0.12, 0.08, 0.26, 0.95)
	var border := UiKit.CYAN.darkened(0.5)
	var bw := 2
	if p.get("kind", "") == "creature":
		bg = Color(0.16, 0.06, 0.2, 0.95)
		border = UiKit.PINK.darkened(0.45)
	if flying:
		border = UiKit.GREEN
		bw = 3
	if picked:
		bg = Color(0.25, 0.15, 0.5)
		border = UiKit.GOLD
		bw = 3
	b.add_theme_stylebox_override("normal", UiKit.box(bg, 16, border, bw))
	b.add_theme_stylebox_override("hover", UiKit.box(bg.lightened(0.08), 16, border, bw))
	b.add_theme_stylebox_override("pressed", UiKit.box(bg.lightened(0.12), 16, UiKit.GOLD, 3))
	b.add_theme_stylebox_override("focus", UiKit.box(Color(0, 0, 0, 0), 16, Color.WHITE, 2))
	b.modulate = Color(1, 1, 1, 1.0 if have else 0.62)
	var sub: Label = b.find_child("Sub", true, false)
	if sub:
		if flying:
			sub.text = "✔ flying"
		elif have:
			sub.text = String(p.passive_name)
		elif String(p.get("unlock", "")) == "credits":
			sub.text = "%s CR" % UiKit.num(int(p.get("price", 0)))
		else:
			sub.text = "Boss · %d ★" % int(p.get("stars", 0))


## A pilot portrait in a round frame tinted with the pilot's colour. The
## picture is painted off screen on first use and cached for the session.
func _portrait_frame(p: Dictionary, px: int) -> Control:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var c: Color = p.color
	frame.add_theme_stylebox_override("panel", UiKit.box(Color(c.r * 0.22, c.g * 0.18, c.b * 0.3, 1.0), px / 2, c.darkened(0.2), 2))
	frame.custom_minimum_size = Vector2(px, px)
	var t := TextureRect.new()
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(t)
	var pid := String(p.id)
	var tex := PortraitStudio.texture(pid)
	if tex:
		t.texture = tex
	else:
		if not _portrait_wait.has(pid):
			_portrait_wait[pid] = []
		_portrait_wait[pid].append(t)
		_studio.request(pid)
	return frame


func _on_portrait(pid: String, tex: Texture2D) -> void:
	for t: Variant in _portrait_wait.get(pid, []):
		if is_instance_valid(t):
			(t as TextureRect).texture = tex
	_portrait_wait.erase(pid)


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
		["Star Shards", "%d / %d" % [Save.shard_total(), Catalog.TRACK_IDS.size() * 3]], ["Daily challenges", "%d (best streak %d)" % [Save.stat("dailies"), int(Save.data.daily.best_streak)]],
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
		["Volcanic biome", "biome", ["auto", "eerie", "divine", "off"], {"auto": "Auto (volcanic worlds)", "eerie": "Eerie on rocky worlds", "divine": "Divine on rocky worlds", "off": "Off (classic scenery)"}],
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
			_sel.clear()
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
