extends Control
## World map: a spinning globe with a pin per rainforest (owned, locked or
## coming soon), the region list, and the selected region's stages (Journey)
## or best distance (Endless). Also the pre-run loadout: which owned
## power-ups to bring.

var args: Dictionary = {}
var mode := "journey"
var selected := ""
var globe: Widgets.Globe
var detail: VBoxContainer
var region_row: HBoxContainer
var mode_btns := {}
var level_sel := -1


func setup(a: Dictionary) -> void:
	args = a
	mode = String(a.get("mode", "journey"))


func _ready() -> void:
	selected = String(Save.data.get("selected_map", "amazon"))
	if not Content.maps.has(selected):
		selected = Content.playable_maps()[0]
	var root := UI.vbox(12)
	var m := UI.margin(root, 24, int(UI.safe_top(self)) + 16, 24, 24)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	root.add_child(TopBar.make(self, true, "World"))
	var seg := UI.hbox(8)
	for md in ["journey", "endless"]:
		var b := UI.button(md.capitalize(), func(): _set_mode(md), UI.PANEL_2, 28, 68)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.add_child(b)
		mode_btns[md] = b
	root.add_child(seg)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var body := UI.vbox(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	globe = Widgets.Globe.new(Vector2(500, 500))
	globe.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	globe.pin_pressed.connect(_select)
	var start := Content.map(selected)
	globe.lon = float(start.get("lon", 0.0)) - 60.0
	globe.focus(selected)
	body.add_child(globe)
	var rs := ScrollContainer.new()
	rs.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rs.custom_minimum_size.y = 128
	region_row = UI.hbox(10)
	rs.add_child(region_row)
	body.add_child(rs)
	detail = UI.vbox(12)
	body.add_child(detail)
	_set_mode(mode)


func _set_mode(md: String) -> void:
	mode = md
	for k in mode_btns:
		UI.paint(mode_btns[k], UI.ACCENT if k == mode else UI.PANEL_2)
	_regions()
	_detail()


func _select(id: String) -> void:
	selected = id
	level_sel = -1
	globe.focus(id)
	Sfx.play("swipe")
	if Content.map(id).get("status", "available") == "available":
		Save.data.selected_map = id
		Save.mark()
	_regions()
	_detail()


func _regions() -> void:
	for ch in region_row.get_children():
		ch.queue_free()
	for id in Content.map_order:
		var mp := Content.map(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(196, 116)
		var sel := id == selected
		b.add_theme_stylebox_override("normal", UI.box(UI.region_color(id).darkened(0.25) if sel else UI.PANEL_2, 20, 3 if sel else 0, UI.ACCENT, 8))
		b.add_theme_stylebox_override("hover", UI.box(UI.region_color(id).darkened(0.15), 20, 0, UI.ACCENT, 8))
		b.add_theme_stylebox_override("pressed", UI.box(UI.region_color(id).darkened(0.35), 20, 0, UI.ACCENT, 8))
		var v := UI.vbox(2)
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 10
		v.offset_top = 8
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var h := UI.hbox(6)
		h.add_child(Widgets.Flag.new(id, Vector2(36, 26)))
		var nl := UI.label(String(mp.name).replace(" Highlands", "").replace(" Basin", ""), 22, UI.TEXT, true)
		h.add_child(nl)
		v.add_child(h)
		var status := ""
		if mp.get("status", "available") != "available":
			status = "Coming soon"
		elif not Save.owns_map(id):
			status = "Locked · Map pack"
		elif mode == "journey":
			status = "%d/%d levels" % [Progress.stages_cleared(id), mp.get("stages", []).size()]
		else:
			status = "Best %d rows" % Progress.best_rows(id)
		v.add_child(UI.label(status, 20, UI.ACCENT if Save.owns_map(id) else UI.MUTED))
		# difficulty tier, then where it is
		var where := UI.hbox(6)
		var tr := Content.tier(Content.tier_of(mp))
		if not tr.is_empty():
			where.add_child(UI.label(String(tr.name), 18, Color(String(tr.color)), true))
			where.add_child(UI.label("·", 18, UI.MUTED))
		var loc := UI.label(String(mp.get("location", "")), 18, UI.MUTED)
		loc.clip_text = true
		loc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		where.add_child(loc)
		v.add_child(where)
		for c in v.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var mid := String(id)
		b.pressed.connect(func(): _select(mid))
		region_row.add_child(b)


func _detail() -> void:
	for ch in detail.get_children():
		ch.queue_free()
	var mp := Content.map(selected)
	var head := UI.hbox(12)
	head.add_child(Widgets.Flag.new(selected, Vector2(60, 44)))
	var tv := UI.vbox(0)
	tv.add_child(UI.label(String(mp.name), 38, UI.ACCENT, true))
	tv.add_child(UI.label(String(mp.get("location", "")), 24, UI.MUTED))
	head.add_child(tv)
	detail.add_child(head)
	var tr := Content.tier(Content.tier_of(mp))
	if not tr.is_empty():
		var trow := UI.hbox(10)
		var chip := UI.panel(Color(String(tr.color)).darkened(0.55), 14, 6)
		chip.add_child(UI.label(String(tr.name).to_upper(), 20, Color(String(tr.color)), true))
		trow.add_child(chip)
		var bl := UI.wrap_label(String(tr.get("blurb", "")), 22, UI.MUTED)
		bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trow.add_child(bl)
		detail.add_child(trow)
	var facts: Array = mp.get("facts", [])
	if not facts.is_empty():
		detail.add_child(UI.wrap_label(String(facts[0]), 25, UI.TEXT))
	if mp.get("status", "available") != "available":
		detail.add_child(UI.label("Coming soon — this region is being mapped.", 28, UI.MUTED, true))
		return
	if not Save.owns_map(selected):
		var prod := Content.product(Store.map_product(selected))
		detail.add_child(UI.wrap_label("Unlock the %s to explore it. It also brings its native pack animals." % String(prod.get("title", "map pack")), 25, UI.MUTED))
		detail.add_child(UI.button("Get %s · %s" % [String(prod.get("title", "")), Store.price_label(prod)], func(): Game.goto("store", {"focus": String(prod.get("id", ""))}), UI.ACCENT, 28, 92))
		if String(Progress.daily_challenge().get("map", "")) == selected:
			detail.add_child(UI.button("Try it free in today's Daily Challenge", func(): Game.start_daily(), Color("2a6a8a"), 26, 84))
		return
	detail.add_child(_animal_row())
	detail.add_child(_loadout())
	if mode == "journey":
		_levels(mp)
	else:
		detail.add_child(UI.label("Best: %d rows · %d pts" % [Progress.best_rows(selected), int(Save.map_progress(selected).get("best_score", 0))], 28, UI.TEXT, true))
		detail.add_child(UI.wrap_label("Endless lanes, rising difficulty. The jungle creeps up behind you — keep moving.", 24, UI.MUTED))
		detail.add_child(UI.button("Play Endless", func(): Game.start_endless(selected), UI.ACCENT, 32, 100))


func _animal_row() -> Control:
	var a := Content.animal(String(Save.data.equipped_animal))
	var row := UI.hbox(12)
	var p := Widgets.Portrait.new(a, Vector2(96, 96))
	row.add_child(p)
	var v := UI.vbox(0)
	v.add_child(UI.label(String(a.name), 28, UI.TEXT, true))
	v.add_child(UI.label("%s · %s · skill Lv %d" % [String(a.ability.name), String(a.ability.summary), Skills.level_of(String(a.id))], 20, UI.MUTED))
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(v.get_child(1) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(v)
	var b := UI.button("Change", func(): Game.goto("animals"), UI.PANEL_3, 24, 72)
	row.add_child(b)
	return row


func _loadout() -> Control:
	var box := UI.vbox(6)
	var items := ["extra_life", "shield_totem", "vine_grapple", "time_slow"]
	var any := false
	for id in items:
		if Save.item_count(id) > 0:
			any = true
	box.add_child(UI.label("Bring power-ups" if any else "Power-ups: none yet (store or daily rewards)", 24, UI.MUTED, true))
	if not any:
		return box
	var row := UI.hbox(8)
	for id in items:
		var n := Save.item_count(id)
		if n <= 0:
			continue
		var c := Content.consumable(id)
		var on: bool = id in Save.data.loadout
		var b := UI.button("%s%s ×%d" % ["On: " if on else "", String(c.name), n], func():
			if id in Save.data.loadout:
				Save.data.loadout.erase(id)
			else:
				Save.data.loadout.append(id)
			Save.mark()
			_detail(), UI.ACCENT if on else UI.PANEL_2, 22, 64)
		row.add_child(b)
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.y = 70
	sc.add_child(row)
	box.add_child(sc)
	return box


## The scene's 10 levels as a grid; the chosen one is described below it.
func _levels(mp: Dictionary) -> void:
	var stages: Array = mp.get("stages", [])
	var cleared_n := Progress.stages_cleared(selected)
	if level_sel < 0 or level_sel >= stages.size() or not Progress.stage_unlocked(selected, level_sel):
		level_sel = mini(cleared_n, stages.size() - 1)
	detail.add_child(UI.label("Levels  ·  %d of %d cleared" % [cleared_n, stages.size()], 26, UI.MUTED, true))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for i in stages.size():
		var unlocked := Progress.stage_unlocked(selected, i)
		var cleared := i < cleared_n
		var c := UI.LOCK
		if cleared:
			c = UI.PANEL_3
		elif unlocked:
			c = UI.ACCENT
		var b := UI.button(str(i + 1) if unlocked else "%d" % (i + 1), func():
			level_sel = i
			_detail(), c, 30, 84)
		b.custom_minimum_size.x = 112
		b.disabled = not unlocked
		if i == level_sel:
			b.add_theme_stylebox_override("normal", UI.box(c.lightened(0.15), 26, 4, Color.WHITE, 22))
		grid.add_child(b)
	detail.add_child(grid)
	var st: Dictionary = stages[level_sel]
	var zones := int(st.get("canopy", {}).get("zones", 0))
	var best := int(Save.map_progress(selected).get("stage_best", {}).get(str(level_sel), 0))
	var lrow := UI.hbox(14)
	var lname := UI.label("Level %d: %s" % [level_sel + 1, String(st.name)], 32, UI.ACCENT, true)
	lname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lrow.add_child(lname)
	lrow.add_child(UI.label("Challenge", 20, UI.MUTED, true))
	lrow.add_child(Widgets.Pips.new(int(st.get("stars", 1)), 5))
	detail.add_child(lrow)
	# hazards that first show up in this level
	var fresh := []
	for slot in mp.get("hazards", {}):
		for e in mp.hazards[slot]:
			if int(e.get("from_level", 1)) == level_sel + 1 and level_sel > 0:
				var nm := String(Content.hazard(String(e.id)).get("name", e.id))
				if not nm in fresh:
					fresh.append(nm)
	if not fresh.is_empty():
		detail.add_child(UI.wrap_label("New here: " + ", ".join(fresh), 23, Color("ffd34a")))
	var info := "%d rows · %d dense-canopy zone%s (switch to first person to see under the leaves)" % [int(st.rows), zones, "" if zones == 1 else "s"]
	if best > 0:
		info += " · best %d pts" % best
	detail.add_child(UI.wrap_label(info, 23, UI.MUTED))
	detail.add_child(UI.button("Play level %d" % (level_sel + 1), func(): Game.start_journey(selected, level_sel), UI.ACCENT, 32, 100))
