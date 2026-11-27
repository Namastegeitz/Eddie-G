class_name ColourFilter
extends CanvasLayer
## Settings > Colour-blind filter: a full-screen colour correction drawn over
## everything (game, HUD, menus). Off by default; costs one full-screen pass
## only while it's on.

const MODES := {"protanopia": 1, "deuteranopia": 2, "tritanopia": 3}
var rect: ColorRect


func _init() -> void:
	name = "ColourFilter"
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/colourblind.gdshader")
	rect.material = mat
	add_child(rect)


func set_mode(m: String) -> void:
	(rect.material as ShaderMaterial).set_shader_parameter("mode", int(MODES.get(m, 2)))
