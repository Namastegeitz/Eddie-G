class_name FxLayer
extends Node2D
## Lightweight particles, rings and floating text for game feel.

var parts: Array[Dictionary] = []


func burst(p: Vector2, c: Color, n := 10, speed := 220.0, kind := "dot", r := 5.0, up := 0.0) -> void:
	for i in n:
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a)) * speed * randf_range(0.4, 1.0) + Vector2(0, -up)
		parts.append({"p": p, "v": v, "life": 0.0, "max": randf_range(0.4, 0.75), "c": c, "r": r * randf_range(0.7, 1.3), "k": kind, "g": 420.0, "rot": randf() * TAU})


func ring(p: Vector2, c: Color, r0: float, r1: float, life := 0.45, squash := 0.45) -> void:
	parts.append({"p": p, "v": Vector2.ZERO, "life": 0.0, "max": life, "c": c, "r": r0, "r1": r1, "k": "ring", "g": 0.0, "sq": squash})


func text(p: Vector2, s: String, c: Color, size := 34) -> void:
	parts.append({"p": p, "v": Vector2(0, -70), "life": 0.0, "max": 0.9, "c": c, "r": float(size), "k": "text", "s": s, "g": 0.0})


func trail(p: Vector2, c: Color, shape: String) -> void:
	parts.append({"p": p, "v": Vector2(randf_range(-20, 20), randf_range(-30, 10)), "life": 0.0, "max": 0.6, "c": c, "r": 6.0, "k": shape, "g": 30.0, "rot": randf() * TAU})


func _process(dt: float) -> void:
	if parts.is_empty():
		return
	for p in parts:
		p.life += dt
		p.v.y += float(p.g) * dt
		p.p += p.v * dt
	parts = parts.filter(func(p): return p.life < p.max)
	queue_redraw()


func _draw() -> void:
	var font := UI.font(true)
	for p in parts:
		var k: float = p.life / p.max
		var c: Color = p.c
		c.a *= 1.0 - k
		match String(p.k):
			"ring":
				var r := lerpf(float(p.r), float(p.r1), k)
				Draw.ellipse_line(self, p.p, r, r * float(p.sq), c, 3.0)
			"text":
				var size := int(p.r)
				var w := font.get_string_size(String(p.s), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
				draw_string_outline(font, p.p - Vector2(w * 0.5, 0), String(p.s), HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0, 0, 0, c.a * 0.6))
				draw_string(font, p.p - Vector2(w * 0.5, 0), String(p.s), HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)
			"leaf":
				Draw.leaf(self, p.p, Vector2(cos(float(p.rot) + k * 4.0), sin(float(p.rot) + k * 4.0)), float(p.r) * 2.2, float(p.r) * 0.8, c)
			"petal":
				Draw.ellipse(self, p.p, float(p.r), float(p.r) * 0.5, c, float(p.rot) + k * 3.0)
			"bubble":
				Draw.ellipse_line(self, p.p, float(p.r), float(p.r), c, 2.0)
			"spark", "star":
				Draw.star(self, p.p, float(p.r) * (1.2 - k * 0.5), c, 4, 0.35)
			_:
				Draw.ellipse(self, p.p, float(p.r) * (1.0 - k * 0.5), float(p.r) * (1.0 - k * 0.5), c)
