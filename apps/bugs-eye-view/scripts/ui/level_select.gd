extends Control
## Pick a room and a time of day. Shows best score and badges per level.

var _slot_buttons: Dictionary = {}


func _ready() -> void:
	UIKit.setup_root(self)
	UIKit.background(self)
	var col := UIKit.column(self, 620.0, 12)
	col.add_child(UIKit.title("CHOOSE A ROOM", 44))
	col.add_child(UIKit.label("Each room runs on a daily routine. Finish a room to unlock afternoon and night.", 18, UIKit.DIM))
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
	return p


func _choose(id: StringName) -> void:
	var slot := &"morning"
	var group := _slot_buttons.get(id) as ButtonGroup
	if group and group.get_pressed_button():
		slot = StringName(group.get_pressed_button().get_meta(&"slot"))
	GameManager.current_level = id
	GameManager.current_time_slot = slot
	GameManager.goto("bug_select")
