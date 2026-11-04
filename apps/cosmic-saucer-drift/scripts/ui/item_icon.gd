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
		"meteor":
			draw_line(c + Vector2(-r, -r), c + Vector2(r * 0.2, r * 0.2), Color(1, 0.8, 0.3), r * 0.35)
			draw_circle(c + Vector2(r * 0.3, r * 0.3), r * 0.55, col)
		"shield":
			draw_arc(c, r, 0, TAU, 32, col, r * 0.22)
			draw_circle(c, r * 0.55, Color(col, 0.35))
		"warp":
			for k in 3:
				var off := Vector2(-r * 0.6 + k * r * 0.55, 0)
				draw_polyline(PackedVector2Array([c + off + Vector2(-r * 0.3, -r * 0.6), c + off + Vector2(r * 0.25, 0), c + off + Vector2(-r * 0.3, r * 0.6)]), col, r * 0.2)
		"bolt":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.6, 0), c + Vector2(0, r), c + Vector2(-r * 0.6, 0)]), col)
			draw_circle(c, r * 0.25, Color.WHITE)
		"mine":
			for k in 8:
				var a := TAU * k / 8.0
				draw_line(c, c + Vector2(cos(a), sin(a)) * r, col, r * 0.15)
			draw_circle(c, r * 0.6, col)
			draw_circle(c, r * 0.25, Color(0.2, 0.1, 0))
		"nebula":
			for k in 5:
				var a := TAU * k / 5.0
				draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.45, r * 0.42, col)
		"blackhole":
			for k in 3:
				draw_arc(c, r * (1.0 - k * 0.28), 0, TAU, 32, col.lightened(0.4 - k * 0.2), r * 0.12)
			draw_circle(c, r * 0.3, Color(0.02, 0, 0.05))
