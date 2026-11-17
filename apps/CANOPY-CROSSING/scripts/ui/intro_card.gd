class_name IntroCard
extends Control
## Region intro: name, the globe spinning to its real location, a real fact
## or two, the hazards to expect and a few native animals. Shown the first
## time you enter a region (and from the pause menu).

signal closed


static func make(map_id: String) -> IntroCard:
	var c := IntroCard.new()
	c._build(map_id)
	return c


func _build(map_id: String) -> void:
	var m := Content.map(map_id)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.06, 0.04, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := UI.panel(UI.PANEL, 34, 30)
	panel.add_theme_stylebox_override("panel", UI.box(UI.PANEL, 34, 4, UI.region_color(map_id).lightened(0.2), 30))
	panel.custom_minimum_size = Vector2(660, 0)
	center.add_child(UI.margin(panel, 20, 50, 20, 40))
	var box := UI.vbox(16)
	panel.add_child(box)
	var head := UI.hbox(14)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(Widgets.Flag.new(map_id, Vector2(70, 50)))
	var tv := UI.vbox(0)
	tv.add_child(UI.label(String(m.name), 46, UI.ACCENT, true))
	tv.add_child(UI.label(String(m.get("location", "")), 26, UI.MUTED))
	head.add_child(tv)
	box.add_child(head)
	var globe := Widgets.Globe.new(Vector2(300, 300))
	globe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var start: Dictionary = Content.map(String(Save.data.get("selected_map", "amazon")))
	globe.lon = float(start.get("lon", -60.0)) - 120.0
	globe.focus(map_id)
	globe.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(globe)
	for f in m.get("facts", []).slice(0, 2):
		var fl := UI.wrap_label("• " + String(f), 27, UI.TEXT)
		fl.custom_minimum_size.x = 590
		box.add_child(fl)
	var hzs: Array = m.get("intro_hazards", [])
	if not hzs.is_empty():
		box.add_child(UI.label("Watch out for", 30, UI.ACCENT, true))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 12)
		for hid in hzs:
			var hz := Content.hazard(String(hid))
			var cell := UI.hbox(10)
			cell.add_child(Widgets.HazardIcon.new(hz, Vector2(120, 86)))
			var hv := UI.vbox(0)
			var n := UI.wrap_label(String(hz.get("name", hid)), 24, UI.TEXT)
			n.add_theme_font_override("font", UI.font(true))
			n.custom_minimum_size.x = 160
			hv.add_child(n)
			var d := UI.wrap_label(String(hz.get("desc", "")), 19, UI.MUTED)
			d.custom_minimum_size.x = 160
			hv.add_child(d)
			cell.add_child(hv)
			grid.add_child(cell)
		box.add_child(grid)
	var tip := UI.hbox(12)
	var eye := Widgets.EyeButton.new(84)
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(eye)
	var tl := UI.wrap_label("Dense canopy hides parts of every level from above. Tap the eye to switch to first person and see under the leaves.", 24, UI.TEXT)
	tl.custom_minimum_size.x = 470
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip.add_child(tl)
	box.add_child(tip)
	var natives: Array = m.get("native_animals", [])
	if not natives.is_empty():
		box.add_child(UI.label("Native animals", 30, UI.ACCENT, true))
		var row := UI.hbox(4)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		for aid in natives.slice(0, 5):
			var p := Widgets.Portrait.new(Content.animal(String(aid)), Vector2(110, 110))
			p.silhouette = not Save.owns_animal(String(aid))
			row.add_child(p)
		box.add_child(row)
	var go := UI.button("Let's go!", func():
		closed.emit()
		queue_free(), UI.ACCENT, 34, 96)
	box.add_child(go)
	Sfx.play("intro")
