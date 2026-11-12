extends Node
## Renders the short film (scripts/ui/film_screen.gd) to a video file:
## run through tools/render_film.sh, which uses Godot's movie writer and ffmpeg.
## `-- --seek=T` starts at T seconds (for checking single frames).
func _ready() -> void:
	Save.set_setting("music", 0.7)
	Save.set_setting("sfx", 0.9)
	var seek := 0.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seek="):
			seek = float(a.substr(7))
	var layer := CanvasLayer.new()
	add_child(layer)
	var holder := Control.new()
	layer.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var film: Control = load("res://scripts/ui/film_screen.gd").new()
	film.setup({"movie": true, "seek": seek})
	holder.add_child(film)
	film.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
