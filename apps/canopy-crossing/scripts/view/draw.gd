class_name Draw
extends RefCounted
## Small vector-drawing helpers used by every painter.


static func ellipse_points(c: Vector2, rx: float, ry: float, rot := 0.0, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n)
	var cr := cos(rot)
	var sr := sin(rot)
	for i in n:
		var a := TAU * i / n
		var p := Vector2(cos(a) * rx, sin(a) * ry)
		pts[i] = c + Vector2(p.x * cr - p.y * sr, p.x * sr + p.y * cr)
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, rot := 0.0, n := 24) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	ci.draw_colored_polygon(ellipse_points(c, rx, ry, rot, n), color)


static func ellipse_line(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, width := 2.0, rot := 0.0) -> void:
	var pts := ellipse_points(c, rx, ry, rot, 28)
	pts.append(pts[0])
	ci.draw_polyline(pts, color, width, true)


static func rrect_points(r: Rect2, rad: float, seg := 5) -> PackedVector2Array:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	var starts := [-PI * 0.5, 0.0, PI * 0.5, PI]
	for k in 4:
		for i in seg + 1:
			var a: float = starts[k] + PI * 0.5 * i / seg
			var p: Vector2 = corners[k] + Vector2(cos(a), sin(a)) * rad
			if pts.is_empty() or pts[pts.size() - 1].distance_squared_to(p) > 0.01:
				pts.append(p)
	if pts.size() > 2 and pts[0].distance_squared_to(pts[pts.size() - 1]) <= 0.01:
		pts.remove_at(pts.size() - 1)
	return pts


static func rrect(ci: CanvasItem, r: Rect2, rad: float, color: Color) -> void:
	if r.size.x <= 0.5 or r.size.y <= 0.5:
		return
	ci.draw_colored_polygon(rrect_points(r, rad), color)


## A raised block: darker side face below, top face above, soft shadow.
static func slab(ci: CanvasItem, r: Rect2, rad: float, top: Color, depth := 7.0, shadow := true) -> void:
	if shadow:
		rrect(ci, Rect2(r.position + Vector2(4, depth + 4), r.size), rad, Color(0, 0, 0, 0.22))
	rrect(ci, Rect2(r.position + Vector2(0, depth), r.size), rad, top.darkened(0.32))
	rrect(ci, r, rad, top)


static func shadow(ci: CanvasItem, c: Vector2, rx: float, ry: float, a := 0.25) -> void:
	ellipse(ci, c, rx, ry, Color(0, 0, 0, a))


static func leaf(ci: CanvasItem, base: Vector2, dir: Vector2, length: float, width: float, color: Color) -> void:
	if dir.length_squared() < 0.0001 or length < 0.5 or width < 0.2:
		return
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	var tip := base + n * length
	var mid := base + n * length * 0.45
	var pts := PackedVector2Array([base, mid + side * width, tip, mid - side * width])
	ci.draw_colored_polygon(pts, color)
	ci.draw_line(base, tip, color.darkened(0.25), maxf(1.0, width * 0.12), true)


static func star(ci: CanvasItem, c: Vector2, r: float, color: Color, points := 5, inner := 0.45, rot := -PI / 2) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var rr := r if i % 2 == 0 else r * inner
		var a := rot + PI * i / points
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, color)


static func gem(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.8, -r * 0.2)])
	ci.draw_colored_polygon(pts, color)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.2), c + Vector2(0, -r * 0.05)]), color.lightened(0.35))
	ci.draw_polyline(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.8, -r * 0.2), c + Vector2(0, -r)]),
		color.darkened(0.4), maxf(1.0, r * 0.12), true)


static func heart(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	ellipse(ci, c + Vector2(-r * 0.45, -r * 0.2), r * 0.55, r * 0.55, color)
	ellipse(ci, c + Vector2(r * 0.45, -r * 0.2), r * 0.55, r * 0.55, color)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.98, -r * 0.05), c + Vector2(r * 0.98, -r * 0.05), c + Vector2(0, r * 0.95)]), color)


static func berry_icon(ci: CanvasItem, c: Vector2, r: float) -> void:
	ellipse(ci, c + Vector2(-r * 0.35, r * 0.15), r * 0.55, r * 0.55, Color("c81e2a"))
	ellipse(ci, c + Vector2(r * 0.38, r * 0.2), r * 0.55, r * 0.55, Color("e8343a"))
	ellipse(ci, c + Vector2(0, -r * 0.2), r * 0.55, r * 0.55, Color("f04a4a"))
	ellipse(ci, c + Vector2(-r * 0.15, -r * 0.4), r * 0.16, r * 0.12, Color(1, 1, 1, 0.7))
	leaf(ci, c + Vector2(0, -r * 0.6), Vector2(0.8, -1), r * 0.7, r * 0.25, Color("3fae4a"))


static func amber_icon(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		var a := PI / 6 + TAU * i / 6
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pts, Color("f2a01a"))
	var inner := PackedVector2Array()
	for i in 6:
		var a2 := PI / 6 + TAU * i / 6
		inner.append(c + Vector2(cos(a2), sin(a2)) * r * 0.62)
	ci.draw_colored_polygon(inner, Color("ffc94a"))
	ellipse(ci, c + Vector2(-r * 0.25, -r * 0.3), r * 0.18, r * 0.12, Color(1, 1, 1, 0.75), -0.6)
	ellipse(ci, c + Vector2(r * 0.15, r * 0.15), r * 0.12, r * 0.08, Color("a0601a"), 0.4)
