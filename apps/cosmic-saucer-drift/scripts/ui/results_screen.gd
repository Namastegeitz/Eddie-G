class_name ResultsScreen
extends RefCounted
## Post-race screen: standings, Race Credits breakdown, stars, unlocks,
## achievements, cup standings, and what to do next.


static func make(race: Node, results: Array, summary: Dictionary) -> Control:
	var req: Dictionary = race.req
	var root := Control.new()
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.06, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	root.add_child(margin)
	var outer := UiKit.vbox(10)
	margin.add_child(outer)
	var place: int = summary.get("place", 0)
	var title := "RACE RESULTS"
	var tcol := Color.WHITE
	match req.mode:
		"boss":
			title = "YOU BEAT %s!" % Catalog.pilot(req.boss).name.to_upper() if place == 1 else "%s WINS" % Catalog.pilot(req.boss).name.to_upper()
			tcol = UiKit.GOLD if place == 1 else UiKit.RED
		"tt":
			var medal: int = summary.get("medal", 0)
			title = ["NO MEDAL", "BRONZE MEDAL", "SILVER MEDAL", "GOLD MEDAL"][medal]
			tcol = [UiKit.DIM, Color(0.8, 0.5, 0.25), Color(0.8, 0.85, 0.95), UiKit.GOLD][medal]
		_:
			if place > 0:
				title = "%s PLACE!" % UiKit.ordinal(place).to_upper()
				tcol = UiKit.GOLD if place == 1 else (UiKit.CYAN if place <= 3 else Color.WHITE)
	outer.add_child(UiKit.label(title, 52, tcol, HORIZONTAL_ALIGNMENT_CENTER))
	var cols := UiKit.hbox(24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(cols)
	# Standings.
	var left := UiKit.vbox(4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(UiKit.panel(left))
	left.add_child(UiKit.label("Standings", 26, UiKit.CYAN))
	for r in results:
		var row := UiKit.hbox(10)
		var col := Color.WHITE if not r.human else UiKit.GOLD
		row.add_child(UiKit.label(UiKit.ordinal(r.place), 22, col))
		var nm := UiKit.label(str(r.name) + ("  (P%d)" % (int(r.slot) + 1) if r.human and req.mode == "versus" else ("  (you)" if r.human else "")), 22, col)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nm)
		row.add_child(UiKit.label(UiKit.time_str(r.time), 22, UiKit.DIM))
		left.add_child(row)
	# Rewards.
	var right := UiKit.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(right)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(UiKit.panel(scroll))
	right.add_child(UiKit.label("Rewards", 26, UiKit.CYAN))
	for line in summary.get("lines", []):
		var row := UiKit.hbox(8)
		var l := UiKit.label(str(line[0]), 20)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(UiKit.label("+%d" % int(line[1]), 20, UiKit.GOLD))
		right.add_child(row)
	var total: int = summary.get("credits", 0)
	var total_lbl := UiKit.label("Race Credits  +%d   (bank %s)" % [total, UiKit.num(Save.credits())], 24, UiKit.GOLD)
	right.add_child(total_lbl)
	if req.mode == "cup":
		var mask: int = summary.get("star_mask", 0)
		var stars := ""
		for b in 3:
			stars += "★" if (mask >> b) & 1 else "☆"
		right.add_child(UiKit.label("%s   Top 3 · Win · %s %s" % [stars, summary.get("challenge", ""), "✔" if summary.get("challenge_ok", false) else "✘"], 20, UiKit.GOLD))
	if req.mode == "daily":
		var ok: bool = summary.get("daily_ok", false)
		right.add_child(UiKit.label("Daily: %s %s" % [summary.get("daily_goal", ""), "✔" if ok else "✘"], 20, UiKit.GREEN if ok else UiKit.RED))
	var facts: Array = race.td.def.get("facts", [])
	if not facts.is_empty():
		var fl := UiKit.label("Did you know? " + str(facts[randi() % facts.size()]), 18, Color(0.8, 0.85, 1.0))
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right.add_child(fl)
	for u in summary.get("unlocks", []):
		var l := UiKit.label("» " + str(u), 20, UiKit.GREEN)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right.add_child(l)
	for a in summary.get("achievements", []):
		right.add_child(UiKit.label("★ " + str(a), 20, UiKit.PINK))
	if summary.get("cup_last", false):
		right.add_child(UiKit.label("Cup standings", 24, UiKit.CYAN))
		var pts: Dictionary = summary.cup_points
		var order: Array = pts.keys()
		order.sort_custom(func(a: String, b: String) -> bool: return int(pts[a]) > int(pts[b]))
		for k in order.size():
			var idx := int(order[k])
			var nm := ""
			for r in results:
				if int(r.idx) == idx:
					nm = r.name + (" (you)" if r.human else "")
			right.add_child(UiKit.label("%s  %s  %d pts" % [UiKit.ordinal(k + 1), nm, int(pts[order[k]])], 20, UiKit.GOLD if k == 0 else Color.WHITE))
	# Buttons.
	var btns := UiKit.hbox(14)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(btns)
	var first: Button = null
	if Ads.can_offer("double_credits") and total > 0:
		var ad := UiKit.button("▶ Watch ad: +%d credits" % total, func() -> void: pass, 22)
		ad.pressed.connect(func() -> void:
			ad.disabled = true
			Ads.show_rewarded("double_credits", func(granted: bool) -> void:
				if granted:
					Save.add_credits(total)
					total_lbl.text = "Race Credits  +%d   (bank %s)" % [total * 2, UiKit.num(Save.credits())]))
		btns.add_child(ad)
	if req.mode == "cup":
		var cup := Game.cup_def(req.cup)
		if int(req.cup_race) < cup.races.size() - 1:
			var nb := UiKit.button("Next race ▶", func() -> void:
				Ads.maybe_interstitial("cup_interstitial", func() -> void: Game.start(Game.cup_request(req.cup, int(req.cup_race) + 1))), 28, 260)
			btns.add_child(nb)
			first = nb
			btns.add_child(UiKit.button("Retry race", func() -> void: Game.restart(), 24))
		else:
			var mb := UiKit.button("Back to cups", func() -> void: Game.go_menu("cups"), 28, 260)
			btns.add_child(mb)
			first = mb
	else:
		var again := UiKit.button("Race again", func() -> void: Game.restart(), 28, 240)
		btns.add_child(again)
		first = again
		if req.mode == "boss" and place == 1:
			btns.add_child(UiKit.button("Pilots", func() -> void: Game.go_menu("pilots"), 24))
	btns.add_child(UiKit.button("Garage", func() -> void: Game.go_menu("garage"), 24))
	btns.add_child(UiKit.button("Menu", func() -> void: Game.go_menu(), 24))
	if first:
		UiKit.focus_later(first)
	return root
