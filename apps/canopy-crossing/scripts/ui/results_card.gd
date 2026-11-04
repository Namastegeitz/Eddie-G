class_name ResultsCard
extends Control
## End of a run: what happened, what you earned, and where to go next.


static func make(screen, won: bool, rows: int, berries: int, amber: int, rec: Dictionary, extra: Array) -> ResultsCard:
	var c := ResultsCard.new()
	c._build(screen, won, rows, berries, amber, rec, extra)
	return c


func _build(screen, won: bool, rows: int, berries: int, amber: int, rec: Dictionary, extra: Array) -> void:
	var cfg: Dictionary = screen.cfg
	var map: Dictionary = screen.map
	var sim: RunSim = screen.sim
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UI.panel(UI.PANEL, 34, 30)
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var box := UI.vbox(14)
	panel.add_child(box)
	var title := "Run over"
	match String(cfg.mode):
		"tutorial":
			title = "You made it!"
		"journey":
			title = "Level cleared!" if won else "So close!"
		"daily":
			title = "Daily challenge"
	box.add_child(UI.label(title, 48, UI.ACCENT, true, HORIZONTAL_ALIGNMENT_CENTER))
	if not won and sim.cause_text != "":
		box.add_child(UI.label(sim.cause_text, 26, Color("ffc8b8"), false, HORIZONTAL_ALIGNMENT_CENTER))
	var p := Widgets.Portrait.new(screen.animal, Vector2(170, 170))
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(p)
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 30)
	stats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var add_row := func(k: String, v: String, col := UI.TEXT):
		stats.add_child(UI.label(k, 28, UI.MUTED))
		stats.add_child(UI.label(v, 30, col, true))
	add_row.call("Distance", "%d rows" % rows)
	add_row.call("Score", str(sim.score))
	if cfg.mode == "endless":
		add_row.call("Best", "%d rows" % Progress.best_rows(String(map.id)))
	var mult := Economy.berry_multiplier()
	add_row.call("Berries", "+%d%s" % [berries, ("  (x%s)" % str(mult)) if mult > 1.0 else ""], Color("ff9a9a"))
	if amber > 0:
		add_row.call("Amber", "+%d" % amber, UI.AMBER)
	if int(rec.get("xp", 0)) > 0:
		add_row.call("Pass XP", "+%d" % int(rec.xp), Color("9ad8ff"))
	box.add_child(stats)
	for e in extra:
		box.add_child(UI.label(String(e), 26, Color("9cf06a"), true, HORIZONTAL_ALIGNMENT_CENTER))
	if rec.get("new_best", false) and cfg.mode != "tutorial":
		box.add_child(UI.label("New best!", 34, Color("9cf06a"), true, HORIZONTAL_ALIGNMENT_CENTER))
	if berries > 0 and cfg.mode != "tutorial":
		var dbl := UI.button("Watch a video: double to %d Berries" % (berries * 2), func(): pass, UI.BLUE, 26, 80)
		dbl.pressed.connect(func():
			dbl.disabled = true
			screen.double_berries(berries, func(ok):
				dbl.text = "Doubled! +%d Berries" % berries if ok else "No reward this time"))
		box.add_child(dbl)
	var row := UI.hbox(12)
	match String(cfg.mode):
		"tutorial":
			box.add_child(UI.wrap_label("Spend your Berries on a new animal, then pick a region to explore.", 26, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
			var go := UI.button("Meet the animals", func(): screen.leave("animals"), UI.ACCENT, 32, 96)
			box.add_child(go)
			return
		"journey":
			var stages: Array = map.get("stages", [])
			if won and int(cfg.get("stage", 0)) + 1 < stages.size():
				box.add_child(UI.button("Next level: %s" % String(stages[int(cfg.stage) + 1].name), func(): screen.leave("next"), UI.ACCENT, 30, 92))
			box.add_child(UI.button("Retry" if not won else "Play again", func(): screen.leave("retry"), UI.PANEL_3 if won else UI.ACCENT, 30, 88))
		_:
			box.add_child(UI.button("Run again", func(): screen.leave("retry"), UI.ACCENT, 30, 92))
	var b1 := UI.button("Animals", func(): screen.leave("animals"))
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b1)
	var b2 := UI.button("World", func(): screen.leave("world"))
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b2)
	var b3 := UI.button("Home", func(): screen.leave("home"))
	b3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b3)
	box.add_child(row)
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.3)
	Sfx.play("results" if won else "fail_jingle")
