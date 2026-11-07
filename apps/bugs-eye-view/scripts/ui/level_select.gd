extends Control
## Pick a room and a time of day. Shows best score and badges per level.

var _slot_buttons: Dictionary = {}


func _ready() -> void:
	UIKit.setup_root(self)
	UIKit.background(self)
	var col := UIKit.column(self, 620.0, 12)
	col.add_child(UIKit.title("CHOOSE A ROOM", 44))
	col.add_child(UIKit.label("Each room runs on a daily routine. Finish a room to unlock afternoon and night. " +
		"Behind every room are ten mini maps - inside the walls, under the sink, the basement, the attic - " +
		"with small tasks and gem shards worth credits for the Armory.", 18, UIKit.DIM))
	col.add_child(UIKit.button("Armory  (%d credits)" % SaveSystem.credits(), func() -> void: GameManager.goto("armory"), 54.0))
	for id in GameManager.LEVEL_IDS:
		var cfg := GameManager.get_level(id)
		if cfg:
			col.add_child(_card(cfg))
	col.add_child(UIKit.button("Back", func() -> void: GameManager.goto("main_menu")))


func _card(cfg: LevelConfig) -> Control:
	var unlocked := GameManager.is_level_unlocked(cfg.id)
	var rec := SaveSystem.get_level_record(cfg.id)
	var p := UIKit.panel()
	var v := UIKit.vbox(8)
	p.add_child(v)
	v.add_child(UIKit.label(cfg.display_name.to_upper(), 30, UIKit.GOLD if unlocked else UIKit.DIM))
	v.add_child(UIKit.label(cfg.description, 18, UIKit.TEXT if unlocked else UIKit.DIM))
	if not unlocked:
		var prev := GameManager.get_level(cfg.unlock_after)
		v.add_child(UIKit.label("Locked - escape the %s first" % (prev.display_name if prev else "previous room"), 18, UIKit.RED))
		return p
	var b: Dictionary = rec["badges"]
	var info := "Best %d" % int(rec["best_score"]) if bool(rec["completed"]) else "Not escaped yet"
	info += "   |   %s %s %s %s" % ["GHOST" if bool(b["ghost"]) else "ghost", "SPEED" if bool(b["speedrun"]) else "speed",
		"GOLD" if bool(b["golden"]) else "gold", "GEMS" if bool(b.get("gem_hunter", false)) else "gems"]
	info += "   |   Boss: %s" % cfg.boss_name
	var sharp := "relaxed" if cfg.animal_awareness < 1.15 else ("watchful" if cfg.animal_awareness < 1.45 else "sharp")
	info += "   |   Animals: %s" % sharp
	v.add_child(UIKit.label(info, 16, UIKit.DIM))
	var slots := UIKit.hbox(8)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(slots)
	var group := ButtonGroup.new()
	_slot_buttons[cfg.id] = group
	for slot in cfg.time_slots:
		var sb := Button.new()
		sb.text = slot.capitalize()
		sb.toggle_mode = true
		sb.button_group = group
		sb.custom_minimum_size = Vector2(130, 52)
		sb.disabled = not GameManager.is_slot_unlocked(cfg.id, StringName(slot))
		sb.button_pressed = slot == "morning"
		sb.set_meta(&"slot", slot)
		slots.add_child(sb)
	v.add_child(UIKit.button("Play %s" % cfg.display_name, func() -> void: _choose(cfg.id)))
	v.add_child(_minis(cfg))
	return p


## The room's ten mini maps: numbered tiles (theme and task), done ones
## ticked, locked ones dimmed; the crawl space shows only when it's open.
func _minis(cfg: LevelConfig) -> Control:
	var box := UIKit.vbox(6)
	box.name = "Minis_%s" % cfg.id
	var done := 0
	for mid in MiniMaps.ids_for(cfg.id):
		if SaveSystem.is_mini_done(mid):
			done += 1
	box.add_child(UIKit.label("MINI MAPS  %d / 9 done" % mini(done, 9), 18, UIKit.GOLD))
	var grid := GridContainer.new()
	var w := get_viewport_rect().size.x if is_inside_tree() else 720.0
	grid.columns = 10 if w >= 1000.0 else 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var center := CenterContainer.new()
	center.add_child(grid)
	box.add_child(center)
	for mid in MiniMaps.ids_for(cfg.id):
		grid.add_child(_tile(mid))
	return box


func _tile(mid: StringName) -> Control:
	var mc := GameManager.get_level(mid)
	var open := GameManager.is_mini_unlocked(mid)
	var b := Button.new()
	b.name = "Mini_%s" % mid
	b.custom_minimum_size = Vector2(64, 74)
	b.add_theme_font_size_override("font_size", 13)
	if mc.hidden_map:
		b.text = "CRAWL\nSPACE" if open else "?"
		b.tooltip_text = "A hidden crawl space - it opens up now and then after a mini map" if not open else mc.description
		if open:
			b.add_theme_color_override("font_color", ItemDef.RARITY_COLORS[3])
	else:
		var task_short: String = {"shards": "shards", "timed": "timed", "key": "key", "summit": "climb"}.get(mc.task, mc.task)
		var theme_short: String = {"sink": "sink", "walls": "walls", "basement": "cellar", "attic": "attic"}.get(mc.theme, mc.theme)
		var mark := " *" if SaveSystem.is_mini_done(mid) else ""
		b.text = "%d%s\n%s\n%s" % [mc.mini_index, mark, theme_short, task_short]
		b.tooltip_text = mc.display_name + " - " + mc.description
	b.disabled = not open
	b.pressed.connect(func() -> void: _choose(mid))
	return b


func _choose(id: StringName) -> void:
	var slot := &"morning"
	var group := _slot_buttons.get(id) as ButtonGroup
	if group and group.get_pressed_button():
		slot = StringName(group.get_pressed_button().get_meta(&"slot"))
	GameManager.current_level = id
	GameManager.current_time_slot = slot
	GameManager.goto("bug_select")
