class_name Draw
extends RefCounted
## Small vector-drawing helpers used by every painter.
##
## Outline pass: painters draw a figure twice. With `outline` > 0 every
## solid shape is drawn grown by that many pixels in `outline_color` (thin
## detail strokes, highlights and shadows are skipped), giving a clean
## sticker-style silhouette; then the figure is drawn normally on top.
## `detail` (0 low, 1 medium, 2 high) lets painters skip fine touches.

static var outline := 0.0
## Batching (see begin_batch): when on, the shapes of one figure are drawn
## with a single draw call. The project setting canopy/render/batch_2d turns
## it off (it is on by default).
static var batching := bool(ProjectSettings.get_setting("canopy/render/batch_2d", true))
static var _b: Batch = null
static var outline_color := Color(0.05, 0.08, 0.06, 0.92)
static var detail := 2


static var _grain: ImageTexture


## A small seamless noise tile (dark and light flecks with alpha) laid over
## ground and grass so flat colours read as soil and turf. Built once.
static func grain() -> Texture2D:
	if _grain:
		return _grain
	var n := FastNoiseLite.new()
	n.seed = 7
	n.frequency = 0.06
	n.fractal_octaves = 3
	var src := n.get_seamless_image(128, 128)
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var v := src.get_pixel(x, y).r
			if v < 0.5:
				img.set_pixel(x, y, Color(0, 0, 0, (0.5 - v) * 0.34))
			else:
				img.set_pixel(x, y, Color(1, 1, 0.9, (v - 0.5) * 0.2))
	_grain = ImageTexture.create_from_image(img)
	return _grain


static func begin_outline(width: float) -> void:
	outline = maxf(0.0, width)


static func end_outline() -> void:
	outline = 0.0


static func _skip(color: Color) -> bool:
	return outline > 0.0 and color.a < 0.6


static func poly(ci: CanvasItem, pts: PackedVector2Array, color: Color) -> void:
	if pts.size() < 3 or _skip(color):
		return
	if outline > 0.0:
		_fill(ci, pts, outline_color)
		var ring := pts.duplicate()
		ring.append(pts[0])
		_polyline_raw(ci, ring, outline_color, outline * 2.0, true)
		return
	_fill(ci, pts, color)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width := 1.0, aa := true) -> void:
	if outline > 0.0:
		if width < 3.0 or _skip(color):
			return
		_line_raw(ci, a, b, outline_color, width + outline * 2.0, true)
		_circle_raw(ci, a, width * 0.5 + outline, outline_color)
		_circle_raw(ci, b, width * 0.5 + outline, outline_color)
		return
	_line_raw(ci, a, b, color, width, aa)


static func polyline(ci: CanvasItem, pts: PackedVector2Array, color: Color, width := 1.0, aa := true) -> void:
	if pts.size() < 2:
		return
	if outline > 0.0:
		if width < 3.0 or _skip(color):
			return
		_polyline_raw(ci, pts, outline_color, width + outline * 2.0, true)
		_circle_raw(ci, pts[0], width * 0.5 + outline, outline_color)
		_circle_raw(ci, pts[pts.size() - 1], width * 0.5 + outline, outline_color)
		return
	_polyline_raw(ci, pts, color, width, aa)
	if width >= 4.0 and detail > 0:
		_circle_raw(ci, pts[0], width * 0.5, color)
		_circle_raw(ci, pts[pts.size() - 1], width * 0.5, color)


static func arc(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, n: int, color: Color, width := 1.0, aa := true) -> void:
	if outline > 0.0:
		if width < 3.0 or _skip(color):
			return
		_arc_raw(ci, c, r, a0, a1, n, outline_color, width + outline * 2.0, true)
		return
	_arc_raw(ci, c, r, a0, a1, n, color, width, aa)


static func rect(ci: CanvasItem, r: Rect2, color: Color, filled := true, width := -1.0) -> void:
	if outline > 0.0:
		if not filled or _skip(color):
			return
		_rect_raw(ci, r.grow(outline), outline_color)
		return
	_rect_raw(ci, r, color, filled, width)


## A rounded body part with a darker rim (lower right) and a soft highlight
## (upper left): reads as a lit, solid shape at any size.
static func shaded(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, rot := 0.0) -> void:
	if outline > 0.0 or detail == 0:
		ellipse(ci, c, rx, ry, color, rot, 28)
		return
	ellipse(ci, c, rx, ry, color.darkened(0.22), rot, 28)
	ellipse(ci, c + Vector2(-rx * 0.05, -ry * 0.07).rotated(rot), rx * 0.93, ry * 0.9, color, rot, 28)
	if detail > 1 and rx > 4.0:
		ellipse(ci, c + Vector2(-rx * 0.34, -ry * 0.4).rotated(rot), rx * 0.34, ry * 0.2, Color(color.lightened(0.35), 0.45), rot - 0.5, 16)


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
	if outline > 0.0:
		if _skip(color) or maxf(rx, ry) < 2.5:
			return
		_fill_convex(ci, ellipse_points(c, rx + outline, ry + outline, rot, n), outline_color)
		return
	_fill_convex(ci, ellipse_points(c, rx, ry, rot, n), color)


static func ellipse_line(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, width := 2.0, rot := 0.0) -> void:
	if outline > 0.0 and (width < 3.0 or _skip(color)):
		return
	var pts := ellipse_points(c, rx, ry, rot, 28)
	pts.append(pts[0])
	_polyline_raw(ci, pts, outline_color if outline > 0.0 else color, width + outline * 2.0, true)


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
	if outline > 0.0:
		if _skip(color):
			return
		_fill_convex(ci, rrect_points(r.grow(outline), rad + outline), outline_color)
		return
	_fill_convex(ci, rrect_points(r, rad), color)


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
	poly(ci, pts, color)
	if outline <= 0.0:
		_line_raw(ci, base, tip, color.darkened(0.25), maxf(1.0, width * 0.12), true)


static func star(ci: CanvasItem, c: Vector2, r: float, color: Color, points := 5, inner := 0.45, rot := -PI / 2) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var rr := r if i % 2 == 0 else r * inner
		var a := rot + PI * i / points
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	poly(ci, pts, color)


static func gem(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.8, -r * 0.2)])
	_fill(ci, pts, color)
	_fill(ci, PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.2), c + Vector2(0, -r * 0.05)]), color.lightened(0.35))
	_polyline_raw(ci, PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.8, -r * 0.2), c + Vector2(0, -r)]),
		color.darkened(0.4), maxf(1.0, r * 0.12), true)


static func heart(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	ellipse(ci, c + Vector2(-r * 0.45, -r * 0.2), r * 0.55, r * 0.55, color)
	ellipse(ci, c + Vector2(r * 0.45, -r * 0.2), r * 0.55, r * 0.55, color)
	_fill(ci, PackedVector2Array([c + Vector2(-r * 0.98, -r * 0.05), c + Vector2(r * 0.98, -r * 0.05), c + Vector2(0, r * 0.95)]), color)


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
	_fill(ci, pts, Color("f2a01a"))
	var inner := PackedVector2Array()
	for i in 6:
		var a2 := PI / 6 + TAU * i / 6
		inner.append(c + Vector2(cos(a2), sin(a2)) * r * 0.62)
	_fill(ci, inner, Color("ffc94a"))
	ellipse(ci, c + Vector2(-r * 0.25, -r * 0.3), r * 0.18, r * 0.12, Color(1, 1, 1, 0.75), -0.6)
	ellipse(ci, c + Vector2(r * 0.15, r * 0.15), r * 0.12, r * 0.08, Color("a0601a"), 0.4)



# ====================================================================== batching

## Godot's Compatibility renderer gives every filled polygon its own draw
## call, so a painted animal (dozens of ellipses) cost dozens of draw calls,
## and a busy bird's-eye screen over a thousand. Between begin_batch(ci) and
## end_batch(ci) the helpers above collect their triangles instead, and the
## figure is drawn with one call. Anything drawn directly (a texture, a
## change of transform) first flushes what has been collected, so the order
## of what's painted never changes.
class Batch:
	var ci: CanvasItem
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()

	func _color(n: int, color: Color) -> void:
		var c := PackedColorArray()
		c.resize(n)
		c.fill(color)
		cols.append_array(c)

	func add(points: PackedVector2Array, color: Color, tris: PackedInt32Array) -> void:
		var base := pts.size()
		pts.append_array(points)
		_color(points.size(), color)
		var k := idx.size()
		idx.resize(k + tris.size())
		for t in tris:
			idx[k] = base + t
			k += 1

	## A convex outline as a fan from its first point (no temporary arrays).
	func add_fan(points: PackedVector2Array, color: Color) -> void:
		var n := points.size()
		var base := pts.size()
		pts.append_array(points)
		_color(n, color)
		var k := idx.size()
		idx.resize(k + (n - 2) * 3)
		for i in range(1, n - 1):
			idx[k] = base
			idx[k + 1] = base + i
			idx[k + 2] = base + i + 1
			k += 3

	func flush() -> void:
		if idx.is_empty():
			return
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)
		pts = PackedVector2Array()
		cols = PackedColorArray()
		idx = PackedInt32Array()


static func begin_batch(ci: CanvasItem) -> void:
	if not batching or _b != null:
		return
	_b = Batch.new()
	_b.ci = ci


static func end_batch(ci: CanvasItem) -> void:
	if _b != null and _b.ci == ci:
		_b.flush()
		_b = null


static func _batching(ci: CanvasItem) -> bool:
	return _b != null and _b.ci == ci


## Use these instead of the CanvasItem methods inside painters.
static func set_transform(ci: CanvasItem, pos: Vector2, rot := 0.0, scl := Vector2.ONE) -> void:
	if _batching(ci):
		_b.flush()
	ci.draw_set_transform(pos, rot, scl)


static func set_transform_matrix(ci: CanvasItem, xf: Transform2D) -> void:
	if _batching(ci):
		_b.flush()
	ci.draw_set_transform_matrix(xf)


static func texture_rect(ci: CanvasItem, tex: Texture2D, r: Rect2, tile := false, modulate := Color.WHITE) -> void:
	if _batching(ci):
		_b.flush()
	ci.draw_texture_rect(tex, r, tile, modulate)


static func _fill(ci: CanvasItem, pts: PackedVector2Array, color: Color) -> void:
	if not _batching(ci):
		ci.draw_colored_polygon(pts, color)
		return
	if pts.size() < 3:
		return
	var tris := Geometry2D.triangulate_polygon(pts)
	if tris.is_empty():
		return
	_b.add(pts, color, tris)


## A convex outline (ellipses, rounded rectangles): a fan, no triangulation.
static func _fill_convex(ci: CanvasItem, pts: PackedVector2Array, color: Color) -> void:
	if not _batching(ci):
		ci.draw_colored_polygon(pts, color)
		return
	if pts.size() < 3:
		return
	_b.add_fan(pts, color)


## A line as a quad, with a 1-unit soft edge when antialiased (as Godot's own).
static func _seg(a: Vector2, b: Vector2, color: Color, width: float, aa: bool) -> void:
	var d := b - a
	if d.length_squared() < 0.0001:
		return
	var nrm := Vector2(-d.y, d.x).normalized()
	var h := maxf(0.5, width * 0.5)
	var o := nrm * h
	_b.add(PackedVector2Array([a - o, a + o, b + o, b - o]), color, PackedInt32Array([0, 1, 2, 0, 2, 3]))
	if aa:
		var f := nrm * (h + 1.0)
		var clear := Color(color, 0.0)
		var base := _b.pts.size()
		_b.pts.append_array(PackedVector2Array([a + o, b + o, b + f, a + f, a - o, b - o, b - f, a - f]))
		_b.cols.append_array(PackedColorArray([color, color, clear, clear, color, color, clear, clear]))
		for t in [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7]:
			_b.idx.append(base + t)


static func _line_raw(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width := -1.0, aa := false) -> void:
	if not _batching(ci):
		ci.draw_line(a, b, color, width, aa)
		return
	_seg(a, b, color, maxf(1.0, width), aa)


static func _polyline_raw(ci: CanvasItem, pts: PackedVector2Array, color: Color, width := -1.0, aa := false) -> void:
	if not _batching(ci):
		ci.draw_polyline(pts, color, width, aa)
		return
	var w := maxf(1.0, width)
	for i in pts.size() - 1:
		_seg(pts[i], pts[i + 1], color, w, aa)
	if w >= 3.0:
		# round joins, so thick bends don't show notches
		for i in range(1, pts.size() - 1):
			_circle_fan(pts[i], w * 0.5, color)


static func _circle_fan(c: Vector2, r: float, color: Color) -> void:
	var n := clampi(int(r * 0.9), 8, 32)
	_fill_convex(_b.ci, ellipse_points(c, r, r, 0.0, n), color)


static func _circle_raw(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	if not _batching(ci):
		ci.draw_circle(c, r, color)
		return
	if r > 0.0:
		_circle_fan(c, r, color)


static func _arc_raw(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, n: int, color: Color, width := -1.0, aa := false) -> void:
	if not _batching(ci):
		ci.draw_arc(c, r, a0, a1, n, color, width, aa)
		return
	var pts := PackedVector2Array()
	for i in n:
		var a := a0 + (a1 - a0) * i / maxf(1.0, n - 1)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_polyline_raw(ci, pts, color, width, aa)


static func _rect_raw(ci: CanvasItem, r: Rect2, color: Color, filled := true, width := -1.0) -> void:
	if not _batching(ci):
		ci.draw_rect(r, color, filled, width)
		return
	if filled:
		_b.add(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), color, PackedInt32Array([0, 1, 2, 0, 2, 3]))
	else:
		var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
		_polyline_raw(ci, PackedVector2Array(c), color, width, false)
