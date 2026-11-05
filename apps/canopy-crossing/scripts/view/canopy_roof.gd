class_name CanopyRoof
extends Node2D
## Bird's-eye view of dense-canopy zones: a solid roof of leaves over those
## rows, hiding everything underneath (traffic, logs, predators). Only the
## player marker shows through. A sign at the edge of each zone points to
## the first-person view, which sees under the leaves.

var wv: WorldView
var t := 0.0


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	var T := WorldView.T
	var vis := wv.visible_rows()
	var x0 := -wv.field_x - 40.0
	var w := wv.vp.x + 80.0
	var canopy := wv.color("canopy")
	var dark := wv.color("canopy_dark")
	var font := UI.font(true)
	for r in range(vis.x, vis.y + 1):
		var l := wv.sim.world.lane(r)
		if not l.covered:
			continue
		# each scene tints its own roof
		var sc := Scenery3D.scene_def(wv.sim.world.map, l.scene)
		var canopy_l := canopy.lerp(Scenery3D.col(sc, {}, "leaf", canopy.to_html()), 0.6) if sc.has("colors") else canopy
		var y := -r * T
		var below := wv.sim.world.lane(r - 1).covered
		var above := wv.sim.world.lane(r + 1).covered
		draw_rect(Rect2(x0, y - T * 0.5 - (0.0 if above else 10.0), w, T + (0.0 if above else 10.0) + (0.0 if below else 10.0)), dark)
		var rng := RandomNumberGenerator.new()
		rng.seed = r * 7919 + 3
		var n := int(w / 46.0) + 2
		for i in n:
			var cx := x0 + i * 46.0 + rng.randf_range(-10, 10)
			var cy := y + rng.randf_range(-T * 0.35, T * 0.35)
			var sway := sin(t * 1.3 + i * 0.7 + r) * 3.0
			Draw.ellipse(self, Vector2(cx + sway, cy), rng.randf_range(26, 38), rng.randf_range(20, 30), canopy_l.darkened(rng.randf_range(0.0, 0.3)))
			Draw.leaf(self, Vector2(cx + sway, cy), Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)), 34, 12, canopy_l.lightened(rng.randf_range(0.0, 0.18)))
		if not below:
			# scalloped edge and a sign pointing to first-person view
			for i in n:
				Draw.ellipse(self, Vector2(x0 + i * 46.0 + 23.0, y + T * 0.5 + 6.0), 26, 16, canopy_l.darkened(0.15))
			var text := "Too thick to see from above"
			var fs := 22
			var name := String(Scenery3D.scene_def(wv.sim.world.map, l.scene).get("name", ""))
			var tw := maxf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
			var cxm := Lane.COLS * T * 0.5
			var h := 40.0 if name == "" else 66.0
			var pill := Rect2(cxm - tw * 0.5 - 52, y + T * 0.5 - h + 10.0, tw + 72, h)
			Draw.rrect(self, pill, 20, Color(0.02, 0.08, 0.05, 0.85))
			_eye(Vector2(pill.position.x + 26, pill.get_center().y), 13)
			if name != "":
				draw_string(font, Vector2(pill.position.x + 46, pill.position.y + 28), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.ACCENT)
			draw_string(font, Vector2(pill.position.x + 46, pill.end.y - 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.92))


func _eye(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		pts.append(c + Vector2(-cos(a) * r * 1.4, -sin(a) * r * 0.8))
	for i in range(1, 12):
		var a2 := PI * i / 12.0
		pts.append(c + Vector2(cos(a2) * r * 1.4, sin(a2) * r * 0.8))
	draw_colored_polygon(pts, Color.WHITE)
	Draw.ellipse(self, c, r * 0.5, r * 0.5, Color("2a6fe0"))
	Draw.ellipse(self, c, r * 0.25, r * 0.25, Color.BLACK)
