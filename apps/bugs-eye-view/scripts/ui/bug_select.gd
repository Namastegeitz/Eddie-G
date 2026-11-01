extends Control
## Pick your bug. Locked bugs show how to unlock them.


func _ready() -> void:
	UIKit.setup_root(self)
	UIKit.background(self)
	var col := UIKit.column(self, 620.0, 12)
	col.add_child(UIKit.title("CHOOSE YOUR BUG", 44))
	var cfg := GameManager.get_level(GameManager.current_level)
	if cfg:
		col.add_child(UIKit.label("%s  -  %s" % [cfg.display_name, String(GameManager.current_time_slot).capitalize()], 20, UIKit.DIM))
	for id in GameManager.BUG_IDS:
		var stats := GameManager.get_bug_stats(id)
		if stats:
			col.add_child(_card(stats))
	col.add_child(UIKit.button("Back", func() -> void: GameManager.goto("level_select")))


func _card(s: BugStats) -> Control:
	var unlocked := SaveSystem.is_bug_unlocked(s.id)
	var p := UIKit.panel()
	var v := UIKit.vbox(6)
	p.add_child(v)
	v.add_child(UIKit.label(s.display_name.to_upper(), 30, UIKit.GOLD if unlocked else UIKit.DIM))
	v.add_child(UIKit.label(s.description, 18, UIKit.TEXT if unlocked else UIKit.DIM))
	for r in [["Speed", s.rating_speed], ["Stealth", s.rating_stealth], ["Toughness", s.rating_toughness]]:
		var row := UIKit.hbox(10)
		var l := UIKit.label(String(r[0]), 16, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT)
		l.custom_minimum_size.x = 110
		row.add_child(l)
		var b := UIKit.bar(float(r[1]), UIKit.GOLD if unlocked else UIKit.DIM)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
		v.add_child(row)
	if unlocked:
		v.add_child(UIKit.button("Play as %s" % s.display_name, func() -> void:
			GameManager.start_level(GameManager.current_level, s.id, GameManager.current_time_slot)))
	else:
		v.add_child(UIKit.label("Locked - " + s.unlock_hint, 18, UIKit.RED))
	return p
