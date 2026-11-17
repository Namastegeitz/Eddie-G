extends Node
## Renders every animal (and its skins) to a contact sheet PNG.
##   xvfb-run godot --path . --rendering-driver opengl3 res://tools/portrait_sheet.tscn -- --no-boot --out=/tmp/animals.png

func _ready() -> void:
	var out := "user://animals.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var cols := 8
	var cell := Vector2(220, 250)
	var n := Content.animal_order.size()
	var rows := int(ceil(float(n) / cols))
	var sv := SubViewport.new()
	sv.size = Vector2i(int(cols * cell.x), int(rows * cell.y))
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.transparent_bg = false
	add_child(sv)
	var bg := ColorRect.new()
	bg.color = Color("1d5034")
	bg.size = Vector2(sv.size)
	sv.add_child(bg)
	for i in n:
		var a := Content.animal(Content.animal_order[i])
		var p := Widgets.Portrait.new(a, Vector2(200, 200))
		p.animate = false
		p.position = Vector2((i % cols) * cell.x + 10, (i / cols) * cell.y)
		p.size = Vector2(200, 200)
		sv.add_child(p)
		var l := Label.new()
		l.text = "%d %s" % [int(a.number), String(a.name)]
		l.add_theme_font_override("font", UI.font(true))
		l.add_theme_font_size_override("font_size", 17)
		l.position = Vector2((i % cols) * cell.x + 6, (i / cols) * cell.y + 205)
		sv.add_child(l)
	for f in 4:
		await RenderingServer.frame_post_draw
	sv.get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
