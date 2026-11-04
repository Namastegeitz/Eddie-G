extends SceneTree
## Rasterises icon.svg into the PNG icons the export presets need.

func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://icon.svg")
	var fg := FileAccess.get_file_as_string("res://assets/icons/icon_fg.svg")
	for sz in [1024, 512, 192, 180, 152, 120]:
		var img := Image.new()
		img.load_svg_from_buffer(svg.to_utf8_buffer(), sz / 256.0)
		img.save_png("res://assets/icons/icon_%d.png" % sz)
	var f := Image.new()
	f.load_svg_from_buffer(fg.to_utf8_buffer(), 432.0 / 256.0)
	f.save_png("res://assets/icons/adaptive_foreground.png")
	print("icons done")
	quit()
