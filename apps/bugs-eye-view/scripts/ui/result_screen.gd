extends CanvasLayer
## Win / caught screen: cause, score breakdown, badges, crumbs banked, unlocks.

const CAUSES := {
	&"stomped": "Stomped by a giant foot",
	&"swatted": "Swatted!",
	&"pounced": "Pounced on",
	&"vacuumed": "Sucked into the vacuum",
	&"sprayed": "Overcome by bug spray",
	&"drained": "Washed down the drain",
	&"fell": "Fell out of the world",
}

var _root: Control
var _col: VBoxContainer


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	UIKit.setup_root(_root)
	add_child(_root)
	_root.visible = false
	GameManager.run_finished.connect(show_result)


func bind(_lvl: Level) -> void:
	pass


func show_result(r: Dictionary) -> void:
	for c in _root.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_col = UIKit.column(_root, 560.0, 10)
	var won := bool(r.get("won", false))
	_col.add_child(UIKit.title("ESCAPED!" if won else "SQUISHED!", 54))
	if not won:
		_col.add_child(UIKit.label(String(CAUSES.get(StringName(r.get("cause", &"")), "Caught!")), 24, UIKit.RED))
	_col.add_child(UIKit.label("Time %s" % _fmt_time(float(r.get("time", 0.0))), 20, UIKit.DIM))
	var sc: Dictionary = r.get("score", {})
	var p := UIKit.panel()
	var lines := UIKit.vbox(4)
	p.add_child(lines)
	for l: Array in sc.get("lines", []):
		var row := UIKit.hbox()
		var a := UIKit.label(String(l[0]), 20, UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(a)
		var v := int(l[1])
		row.add_child(UIKit.label(("+%d" % v) if v >= 0 else str(v), 20, UIKit.GOLD if v >= 0 else UIKit.RED, HORIZONTAL_ALIGNMENT_RIGHT))
		lines.add_child(row)
	lines.add_child(UIKit.label("SCORE %d" % int(sc.get("total", 0)), 30, UIKit.GOLD))
	_col.add_child(p)
	var badges: Dictionary = r.get("badges", {})
	var newly: Array = r.get("new_badges", [])
	var brow := UIKit.hbox(8)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	for b in [["ghost", "GHOST"], ["speedrun", "SPEEDRUN"], ["golden", "GOLDEN CRUMB"]]:
		var got := bool(badges.get(b[0], false))
		var text := String(b[1]) + (" NEW!" if newly.has(b[0]) else "")
		brow.add_child(UIKit.label(text, 16, UIKit.GOLD if got else Color(0.35, 0.33, 0.3)))
	_col.add_child(brow)
	_col.add_child(UIKit.label("+%d crumbs delivered to the colony" % int(r.get("banked", 0)), 20, UIKit.TEXT))
	for u in r.get("unlocks", []):
		_col.add_child(UIKit.label(String(u), 24, UIKit.GREEN))
	var next := GameManager.next_level_id()
	if won and next != &"" and GameManager.is_level_unlocked(next):
		_col.add_child(UIKit.button("Next level", func() -> void:
			GameManager.current_level = next
			GameManager.goto("bug_select")))
	_col.add_child(UIKit.button("Retry", GameManager.restart_level))
	_col.add_child(UIKit.button("Colony", func() -> void: GameManager.goto("colony")))
	_col.add_child(UIKit.button("Main menu", func() -> void: GameManager.goto("main_menu")))
	_root.visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.3)


static func _fmt_time(t: float) -> String:
	return "%d:%02d" % [floori(t / 60.0), int(t) % 60]
