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
		"warp":
			draw_arc(c + Vector2(-r * 0.55, 0), r * 0.42, 0, TAU, 24, Color(col, 0.6), r * 0.14)
			draw_arc(c + Vector2(r * 0.55, 0), r * 0.42, 0, TAU, 24, col, r * 0.14)
			draw_line(c + Vector2(-r * 0.4, 0), c + Vector2(r * 0.45, 0), Color.WHITE, r * 0.12)
			draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.3, -r * 0.3), c + Vector2(r * 0.7, 0), c + Vector2(r * 0.3, r * 0.3)]), Color.WHITE)
		"decoy":
			for k in 10:
				var a0 := TAU * k / 10.0
				draw_arc(c, r * 0.9, a0, a0 + 0.38, 6, col, r * 0.12)
			draw_arc(c + Vector2(0, -r * 0.1), r * 0.35, PI, TAU, 16, Color(col, 0.8), r * 0.1)
			draw_line(c + Vector2(-r * 0.6, r * 0.15), c + Vector2(r * 0.6, r * 0.15), Color(col, 0.8), r * 0.1)
		"leech":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.55, r * 0.15), c + Vector2(0, r * 0.75), c + Vector2(-r * 0.55, r * 0.15)]), col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.95, -r * 0.2), c + Vector2(-r * 0.4, -r * 0.2), c + Vector2(-r * 0.65, r * 0.15)]), Color.WHITE)
			draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.95, -r * 0.2), c + Vector2(r * 0.4, -r * 0.2), c + Vector2(r * 0.65, r * 0.15)]), Color.WHITE)
		"well":
			var pts := PackedVector2Array()
			for k in 40:
				var a1 := float(k) * 0.42
				pts.append(c + Vector2(cos(a1), sin(a1)) * r * float(k) / 40.0)
			draw_polyline(pts, col, r * 0.16)
			draw_circle(c, r * 0.22, Color(0.05, 0.0, 0.1))
		"frost":
			for k in 6:
				var a2 := TAU * k / 6.0
				var tip := c + Vector2(cos(a2), sin(a2)) * r
				draw_line(c, tip, col, r * 0.13)
				draw_line(tip, tip + Vector2(cos(a2 + 2.4), sin(a2 + 2.4)) * r * 0.3, col, r * 0.1)
				draw_line(tip, tip + Vector2(cos(a2 - 2.4), sin(a2 - 2.4)) * r * 0.3, col, r * 0.1)
		"overcharge":
			draw_arc(c, r * 0.95, 0, TAU, 32, Color(col, 0.7), r * 0.14)
			draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.15, -r * 0.85), c + Vector2(-r * 0.4, r * 0.05), c + Vector2(0, r * 0.05), c + Vector2(-r * 0.15, r * 0.85), c + Vector2(r * 0.4, -r * 0.05), c + Vector2(0, -r * 0.05)]), col)
		"flare":
			draw_circle(c, r * 0.38, Color.WHITE)
			draw_circle(c, r * 0.3, col)
			for k in 10:
				var a3 := TAU * k / 10.0
				var ln := r * (0.95 if k % 2 == 0 else 0.7)
				draw_line(c + Vector2(cos(a3), sin(a3)) * r * 0.48, c + Vector2(cos(a3), sin(a3)) * ln, col, r * 0.1)
		"chain":
			var zz := PackedVector2Array([c + Vector2(-r * 0.9, -r * 0.6), c + Vector2(-r * 0.35, -r * 0.1), c + Vector2(-r * 0.5, r * 0.2), c + Vector2(r * 0.1, -r * 0.2), c + Vector2(0, r * 0.15), c + Vector2(r * 0.9, r * 0.75)])
			draw_polyline(zz, Color.WHITE, r * 0.2)
			draw_polyline(zz, col, r * 0.1)
			draw_circle(c + Vector2(-r * 0.35, -r * 0.1), r * 0.14, col)
			draw_circle(c + Vector2(r * 0.1, -r * 0.2), r * 0.14, col)
		"plasma":
			draw_rect(Rect2(c + Vector2(-r * 0.22, -r * 0.95), Vector2(r * 0.44, r * 1.9)), Color(col, 0.55))
			draw_rect(Rect2(c + Vector2(-r * 0.22, -r * 0.95), Vector2(r * 0.44, r * 1.9)), col, false, r * 0.08)
			for k in 4:
				draw_circle(c + Vector2(0, -r * 0.7 + r * 0.47 * k), r * 0.1, Color.WHITE)
			draw_line(c + Vector2(-r * 0.95, -r * 0.9), c + Vector2(-r * 0.4, -r * 0.9), col, r * 0.1)
			draw_line(c + Vector2(r * 0.4, r * 0.9), c + Vector2(r * 0.95, r * 0.9), col, r * 0.1)
		"stasis":
			for k in 3:
				draw_arc(c, r * (0.45 + 0.25 * k), 0.4, PI - 0.4, 16, Color(col, 1.0 - 0.25 * k), r * 0.1)
				draw_arc(c, r * (0.45 + 0.25 * k), PI + 0.4, TAU - 0.4, 16, Color(col, 1.0 - 0.25 * k), r * 0.1)
			draw_rect(Rect2(c + Vector2(-r * 0.3, -r * 0.3), Vector2(r * 0.2, r * 0.6)), Color.WHITE)
			draw_rect(Rect2(c + Vector2(r * 0.1, -r * 0.3), Vector2(r * 0.2, r * 0.6)), Color.WHITE)
		"cloak":
			for k in 8:
				var a4 := TAU * k / 8.0
				draw_arc(c, r * 0.85, a4, a4 + 0.45, 6, col, r * 0.12)
			draw_arc(c + Vector2(0, -r * 0.05), r * 0.4, PI, TAU, 14, Color(col, 0.7), r * 0.1)
			draw_line(c + Vector2(-r * 0.6, r * 0.2), c + Vector2(r * 0.6, r * 0.2), Color(col, 0.7), r * 0.1)
			draw_line(c + Vector2(-r * 0.5, r * 0.6), c + Vector2(r * 0.5, -r * 0.6), Color(1, 1, 1, 0.6), r * 0.08)
		"repulsor":
			draw_circle(c, r * 0.22, col)
			for k in 3:
				var rr := r * (0.45 + 0.22 * k)
				draw_arc(c, rr, -0.7, 0.7, 10, Color(col, 1.0 - 0.25 * k), r * 0.11)
				draw_arc(c, rr, PI - 0.7, PI + 0.7, 10, Color(col, 1.0 - 0.25 * k), r * 0.11)
		"mine":
			for k in 8:
				var a := TAU * k / 8.0
				draw_line(c, c + Vector2(cos(a), sin(a)) * r, col, r * 0.15)
			draw_circle(c, r * 0.6, col)
			draw_circle(c, r * 0.25, Color(0.2, 0.1, 0))
