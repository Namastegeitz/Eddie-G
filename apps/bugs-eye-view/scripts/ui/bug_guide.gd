class_name BugGuide
extends CanvasLayer
## "How to play" card for a bug: its picture, and one line per button with
## the button's name as you'd press it (the on-screen label on touch, the key
## otherwise). Shown the first time you play each bug (the game waits until
## you tap "Got it"), and from the pause menu's Controls.

signal closed

var stats: BugStats
var labels: Dictionary = {}
var _root: Control


static func portrait(id: StringName) -> Texture2D:
	var path := "res://assets/icons/bugs/%s.png" % id
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## The guide's lines as [button name, text] pairs ("" for a plain tip).
static func lines_for(s: BugStats, action_labels: Dictionary) -> Array:
	var out: Array = []
	for g in s.guide:
		var parts := String(g).split("|", true, 1)
		if parts.size() < 2:
			continue
		var action := parts[0]
		var text := parts[1]
		var key := ""
		match action:
			"tip":
				key = ""
			"move":
				key = "Move"
			_:
				if InputRouter.is_touch_mode():
					key = String(action_labels.get(action, action.capitalize()))
				else:
					key = InputRouter.binding_text(action)
		out.append([key, text])
	return out


## A panel listing the guide, for use inside other screens.
static func build_panel(s: BugStats, action_labels: Dictionary, with_portrait: bool = true) -> Control:
	var p := UIKit.panel()
	var v := UIKit.vbox(8)
	p.add_child(v)
	var head := UIKit.hbox(14)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(head)
	var tex := portrait(s.id) if with_portrait else null
	if tex:
		var img := TextureRect.new()
		img.texture = tex
		img.custom_minimum_size = Vector2(96, 96)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(img)
	var titles := UIKit.vbox(2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	titles.add_child(UIKit.label("HOW TO PLAY", 15, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	titles.add_child(UIKit.label(s.display_name.to_upper(), 30, UIKit.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	if s.tagline != "":
		var tl := UIKit.label(s.tagline, 16, UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		titles.add_child(tl)
	for line: Array in lines_for(s, action_labels):
		var row := UIKit.hbox(10)
		v.add_child(row)
		var key := String(line[0])
		if key != "":
			var pill := UIKit.label(key.to_upper(), 15, UIKit.INK)
			pill.custom_minimum_size.x = 112
			var bg := PanelContainer.new()
			bg.add_theme_stylebox_override("panel", UIKit._box(UIKit.GOLD, UIKit.GOLD, 1, 8))
			bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bg.add_child(pill)
			row.add_child(bg)
		var text := UIKit.label(String(line[1]), 17, UIKit.TEXT if key != "" else UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
	return p


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	UIKit.setup_root(_root)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var col := UIKit.column(_root, 620.0, 14)
	col.add_child(build_panel(stats, labels))
	var ok := UIKit.button("Got it - let's go", close)
	ok.name = "GotIt"
	col.add_child(ok)


func close() -> void:
	closed.emit()
	queue_free()
