class_name PlayerView
extends Node2D
## The player's animal: hop squash and stretch, idle bob and blinks, the
## ability looks (shield bubble, cloak, climbing, hovering), swimming, and a
## death animation per cause.

const SIZE := 76.0

var wv: WorldView
var t := 0.0
var blink_left := 0.0
var next_blink := 2.0
var land_squash := 0.0
var emote := ""
var emote_t := 0.0
var idle := 0.0
var death_t := 0.0
var _was_hopping := false
var _trail_t := 0.0


func update_view(dt: float) -> void:
	t += dt
	var s := wv.sim
	var dp := s.display_pos()
	position = wv.px(dp.x, dp.y) + Vector2(0, 16)
	next_blink -= dt
	if next_blink <= 0.0:
		blink_left = 0.12
		next_blink = randf_range(2.0, 4.5)
	blink_left -= dt
	land_squash = move_toward(land_squash, 0.0, dt * 6.0)
	if _was_hopping and not s.hopping:
		land_squash = 0.6
	_was_hopping = s.hopping
	if s.hopping or s.state != "play":
		idle = 0.0
	else:
		idle += dt
	if emote_t > 0.0:
		emote_t -= dt
	elif idle > 4.0 and emote == "" and String(Save.data.get("equipped_emote", "")) != "":
		play_emote(String(Content.cosmetic(String(Save.data.equipped_emote)).get("anim", "")))
	if s.state in ["respawn", "dead", "restart", "over"]:
		death_t += dt
	else:
		death_t = 0.0
	_trail_t -= dt
	if not wv.trail.is_empty() and s.hopping and _trail_t <= 0.0:
		_trail_t = 0.05
		var cols: Array = wv.trail.get("art", {}).get("colors", ["#ffffff"])
		wv.fx.trail(position + Vector2(randf_range(-10, 10), -20), Color(String(cols[randi() % cols.size()])), String(wv.trail.get("art", {}).get("shape", "dot")))
	queue_redraw()


func play_emote(kind: String) -> void:
	emote = kind
	emote_t = 1.6
	idle = 0.0
	get_tree().create_timer(1.6).timeout.connect(func(): emote = "")


func _draw() -> void:
	var s := wv.sim
	var anim := {"t": t, "blink": blink_left > 0.0, "flip": s.face.x < 0}
	var lift := s.hop_height()
	var squash := 0.0
	if s.hopping:
		squash = -0.35 * sin(s.hop_t * PI)
	else:
		squash = land_squash * 0.5 + sin(t * 3.0) * 0.04
	var alpha := 1.0
	var extra_lift := 0.0
	for a in s.all_abilities():
		if a.is_active():
			match a.id:
				"hover":
					extra_lift = 0.45 + sin(t * 8.0) * 0.04
				"climb":
					extra_lift = 0.3
				"invincible":
					if a.style == "cloak":
						alpha = 0.35 + 0.1 * sin(t * 10.0)
	if s.swimming:
		squash = 0.15
	if emote == "spin":
		anim.flip = int(t * 8.0) % 2 == 0
	if emote == "wave":
		squash = sin(t * 14.0) * 0.12
	anim.squash = squash
	anim.lift = lift + extra_lift
	var dead := s.state in ["respawn", "dead", "restart", "over"] and s.cause != ""
	if s.invuln > 0.0 and not dead and int(t * 14.0) % 2 == 0 and s.invuln < 1.9:
		alpha *= 0.45
	if dead:
		_draw_dead(anim)
		return
	modulate.a = alpha
	var halo := Color(1.0, 0.95, 0.7, 0.22 + 0.06 * sin(t * 3.0))
	Draw.ellipse(self, Vector2(0, 2), SIZE * 0.5, SIZE * 0.17, halo)
	Draw.ellipse_line(self, Vector2(0, 2), SIZE * 0.5, SIZE * 0.17, Color(1, 1, 1, 0.35), 2)
	AnimalPainter.draw(self, wv.animal, SIZE, anim, wv.look_override)
	if s.swimming:
		var wc := wv.color("water")
		draw_rect(Rect2(-SIZE * 0.5, -SIZE * 0.18, SIZE, SIZE * 0.22), Color(wc, 0.85))
		Draw.ellipse_line(self, Vector2(0, -SIZE * 0.1), SIZE * 0.42, SIZE * 0.1, Color(1, 1, 1, 0.5), 2)
	var shield_up := s.shields > 0
	for a in s.abilities:
		if a.id == "shield" and a.charges > 0:
			shield_up = true
		if a.id == "invincible" and a.is_active() and a.style != "cloak":
			Draw.ellipse(self, Vector2(0, -SIZE * 0.45), SIZE * 0.55, SIZE * 0.55, Color(1, 0.9, 0.4, 0.25 + 0.1 * sin(t * 12.0)))
	if shield_up:
		Draw.ellipse_line(self, Vector2(0, -SIZE * 0.45 - (lift + extra_lift) * SIZE * 0.9), SIZE * 0.56, SIZE * 0.6, Color(0.5, 0.85, 1.0, 0.6 + 0.2 * sin(t * 5.0)), 4)
	if emote == "hearts":
		for i in 3:
			var k := fposmod(t * 0.8 + i / 3.0, 1.0)
			Draw.heart(self, Vector2((i - 1) * 20, -SIZE * (1.0 + k * 0.6)), 9, Color(1, 0.35, 0.5, 1.0 - k))


func _draw_dead(anim: Dictionary) -> void:
	var s := wv.sim
	var k := clampf(death_t / 0.6, 0.0, 1.0)
	match s.cause:
		"crushed":
			AnimalPainter.draw(self, wv.animal, SIZE, anim, wv.look_override, Transform2D(0.0, Vector2(1.3, maxf(0.15, 1.0 - k * 0.85)), 0.0, Vector2.ZERO))
			for i in 4:
				var a := t * 4.0 + i * TAU / 4.0
				Draw.star(self, Vector2(cos(a) * 26, -30 + sin(a) * 8), 6, Color(1, 1, 0.6), 5, 0.45)
		"drowned":
			modulate.a = 1.0 - k
			AnimalPainter.draw(self, wv.animal, SIZE, anim, wv.look_override, Transform2D(0.0, Vector2(0, k * 20.0)))
			Draw.ellipse_line(self, Vector2(0, -6), 20 + k * 30, 8 + k * 10, Color(1, 1, 1, 1.0 - k), 3)
		"burned":
			modulate = Color(0.35, 0.3, 0.3, 1.0 - k * 0.6)
			AnimalPainter.draw(self, wv.animal, SIZE, anim, wv.look_override)
		"fell":
			AnimalPainter.draw(self, wv.animal, SIZE, anim, wv.look_override, Transform2D(t * 6.0, Vector2.ONE * maxf(0.05, 1.0 - k), 0.0, Vector2(0, -10)))
		_:
			modulate.a = 1.0 - k
			AnimalPainter.draw(self, wv.animal, SIZE, anim, wv.look_override)
