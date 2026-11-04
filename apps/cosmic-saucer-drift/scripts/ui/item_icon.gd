class_name ItemIcon
extends Control
## Draws a simple vector icon for an item id (no image files needed).

var item := "":
	set(v):
		item = v
		queue_redraw()


func _draw() -> void:
	var s := size
	var c := s * 0.5
	var r := minf(s.x, s.y) * 0.38
	if item == "":
		return
	var col: Color = Catalog.ITEMS[item].color
	match item:
		"tractor":
			draw_circle(c + Vector2(0, -r * 0.5), r * 0.45, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.2), c + Vector2(r * 0.3, -r * 0.2), c + Vector2(r * 0.9, r), c + Vector2(-r * 0.9, r)]), Color(col, 0.45))
		"comet":
			draw_line(c + Vector2(-r, -r), c + Vector2(r * 0.2, r * 0.2), Color(0.7, 0.9, 1.0, 0.7), r * 0.45)
			draw_circle(c + Vector2(r * 0.3, r * 0.3), r * 0.5, col)
		"shield":
			draw_arc(c, r, 0, TAU, 32, col, r * 0.22)
			draw_circle(c, r * 0.55, Color(col, 0.35))
		"rocket":
			var pts := PackedVector2Array([c + Vector2(r * 0.9, -r * 0.9), c + Vector2(r * 0.2, r * 0.2), c + Vector2(-r * 0.2, -r * 0.2)])
			draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.95, -r * 0.95), c + Vector2(-r * 0.35, r * 0.05), c + Vector2(-r * 0.05, r * 0.35)]), Color(0.9, 0.9, 0.95))
			draw_colored_polygon(pts, col)
			draw_circle(c + Vector2(-r * 0.45, r * 0.45), r * 0.3, Color(1.0, 0.75, 0.2))
		"laser":
			draw_line(c + Vector2(-r, r * 0.3), c + Vector2(r, -r * 0.3), col, r * 0.3)
			draw_line(c + Vector2(-r, r * 0.3), c + Vector2(r, -r * 0.3), Color.WHITE, r * 0.1)
			draw_circle(c + Vector2(-r * 0.8, r * 0.25), r * 0.28, col)
		"emp":
			for k in 3:
				draw_arc(c, r * (0.35 + k * 0.3), 0, TAU, 32, Color(col, 1.0 - k * 0.25), r * 0.12)
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.15, -r * 0.45), c + Vector2(r * 0.1, -r * 0.05), c + Vector2(-r * 0.1, r * 0.05), c + Vector2(r * 0.15, r * 0.45)]), Color.WHITE, r * 0.12)
		"nitro":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.25, -r), c + Vector2(r * 0.25, -r), c + Vector2(r * 0.35, r * 0.4), c + Vector2(-r * 0.35, r * 0.4)]), col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.35, r * 0.4), c + Vector2(r * 0.35, r * 0.4), c + Vector2(0, r * 1.05)]), Color(1.0, 0.8, 0.2))
		"mine":
			for k in 8:
				var a := TAU * k / 8.0
				draw_line(c, c + Vector2(cos(a), sin(a)) * r, col, r * 0.15)
			draw_circle(c, r * 0.6, col)
			draw_circle(c, r * 0.25, Color(0.2, 0.1, 0))
