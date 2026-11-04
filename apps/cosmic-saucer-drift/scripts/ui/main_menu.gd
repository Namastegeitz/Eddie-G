extends Control
## Temporary menu (replaced by the full menu in phase 5).


func _ready() -> void:
	theme = UiKit.theme()
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var v := UiKit.vbox(12)
	c.add_child(v)
	v.add_child(UiKit.label("COSMIC SAUCER DRIFT", 64, UiKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	for id in Catalog.TRACK_IDS:
		var tid: String = id
		v.add_child(UiKit.button(TrackDefs.get_def(tid).name, func() -> void: Game.start(Game.quick_request(tid, 0, 1)), 24, 420))
