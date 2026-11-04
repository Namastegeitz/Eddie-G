class_name Atmosphere
extends Control
## Screen-space dressing over the world: the canopy frame (foliage down both
## sides and hanging from the top, in the region's palette), mist that hides
## the rows far ahead, light shafts, rain and gust leaves. Per-region looks
## come from the map's "atmosphere" and "palette" blocks.

var wv: WorldView
var atm: Dictionary = {}
var t := 0.0
var _gust := []


func setup(world_view: WorldView) -> void:
	wv = world_view
	atm = wv.map.get("atmosphere", {})
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	var vp := size
	var T := WorldView.T
	var fx := wv.field_x
	var fw := Lane.COLS * T
	var canopy := wv.color("canopy")
	var dark := wv.color("canopy_dark")
	var scroll := wv.cam_row * T
	# light shafts
	var shafts := float(atm.get("light_shafts", 0.0))
	if shafts > 0.0:
		for i in 3:
			var x := fx + fposmod(i * 310.0 + t * 6.0 - scroll * 0.05, fw + 400.0) - 200.0
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 90, 0), Vector2(x + 260, vp.y), Vector2(x + 120, vp.y)]),
				Color(1.0, 0.97, 0.75, 0.05 * shafts * (0.7 + 0.3 * sin(t * 0.7 + i))))
	# mist far ahead (top of the screen)
	var mist := maxf(0.0, float(atm.get("mist", 0.0)) - wv.reveal * 0.35)
	if mist > 0.0:
		var fog := Color(String(atm.get("fog_color", "#e6ece6")))
		var bands := 16
		for i in bands:
			var k := float(i) / bands
			var a := mist * pow(1.0 - k, 1.6) * 0.95
			draw_rect(Rect2(0, k * vp.y * 0.6, vp.x, vp.y * 0.6 / bands + 1), Color(fog, a))
		for i in 5:
			var y := fposmod(i * 140.0 + scroll * 0.3, vp.y * 0.7)
			Draw.ellipse(self, Vector2(fposmod(i * 260.0 + t * 12.0, vp.x + 300) - 150, y), 220, 40, Color(fog, mist * 0.18))
	# rain
	var rain := float(atm.get("rain", 0.0))
	rain = maxf(rain, wv.sim.world.downpour(wv.sim.wt))
	if rain > 0.02:
		var n := int(80 * rain)
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in n:
			var x2 := fposmod(rng.randf() * vp.x + t * 120.0, vp.x)
			var y2 := fposmod(rng.randf() * vp.y + t * 900.0 * rng.randf_range(0.8, 1.2), vp.y)
			draw_line(Vector2(x2, y2), Vector2(x2 - 6, y2 + 26), Color(0.8, 0.9, 1.0, 0.35 * rain), 2)
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.1, 0.15, 0.25, 0.12 * rain))
	# gust warning
	var gw := wv.sim.world.gust_warning(wv.sim.wt)
	if float(gw[0]) > 0.0:
		var dir := float(gw[1])
		var k2 := float(gw[0])
		for i in 14:
			var y3 := fposmod(i * 97.0, vp.y)
			var x3 := fposmod(i * 211.0 + t * 700.0 * dir, vp.x + 200) - 100
			Draw.leaf(self, Vector2(x3, y3 + sin(t * 6.0 + i) * 20), Vector2(dir, 0.2), 22, 8, Color(0.6, 0.85, 0.4, 0.75 * k2))
		var cx := vp.x * 0.5
		var ay := vp.y * 0.36
		draw_colored_polygon(PackedVector2Array([Vector2(cx + dir * 70, ay), Vector2(cx - dir * 30, ay - 40), Vector2(cx - dir * 30, ay + 40)]), Color(1, 1, 1, 0.45 * k2))
		draw_rect(Rect2(cx - 110 if dir > 0 else cx - 10, ay - 14, 120, 28), Color(1, 1, 1, 0.45 * k2))
	# canopy frame: solid foliage beyond the play field, leaves reaching in
	for side: int in [-1, 1]:
		var edge := fx if side < 0 else fx + fw
		var inward := -float(side)
		var solid_from := 0.0 if side < 0 else edge + 30.0
		var solid_to := edge - 30.0 if side < 0 else vp.x
		if solid_to - solid_from > 1.0:
			draw_rect(Rect2(solid_from, 0, solid_to - solid_from, vp.y), dark)
		var y := -fposmod(scroll * 0.9, 90.0) - 90.0
		var i := 0
		while y < vp.y + 90:
			Draw.ellipse(self, Vector2(edge + side * 36.0, y + 30), 34, 40, dark)
			for j in 3:
				var ang := (0.15 + j * 0.3) * (1.0 if j % 2 == 0 else -1.0) + sin(t * 1.2 + i + j) * 0.06
				var d := Vector2(inward * cos(ang), sin(ang) * 0.8 - 0.2)
				Draw.leaf(self, Vector2(edge + side * 14.0, y + j * 24), d, 44 + j * 6, 16, canopy.darkened(0.12 * j) if (i + j) % 2 == 0 else canopy.lightened(0.06))
			y += 90.0
			i += 1
	# hanging leaves at the very top
	for k in int(vp.x / 70.0) + 2:
		var x4 := k * 70.0 - fposmod(t * 4.0, 70.0)
		var hang := 26.0 + 14.0 * sin(k * 1.9)
		draw_line(Vector2(x4, 0), Vector2(x4 + sin(t + k) * 4.0, hang), dark, 3)
		Draw.leaf(self, Vector2(x4 + sin(t + k) * 4.0, hang), Vector2(sin(k * 1.3) * 0.5, 1), 34, 12, canopy if k % 2 == 0 else canopy.darkened(0.15))
	draw_rect(Rect2(0, 0, vp.x, 10), dark)
