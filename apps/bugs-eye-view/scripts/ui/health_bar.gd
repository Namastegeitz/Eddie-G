class_name HealthBar
extends Control
## The bug's health: a bar that drains when you're hurt (a pale trail shows
## what you just lost), glows as it heals on its own, turns gold past full
## (cheese) and has a tick at every whole hit for bugs that can take more
## than one. It flashes red while a second snap trap would finish you.

var player: BugBase
var _shown := 100.0
var _trail := 100.0
var _glow := 0.0
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(190, 20)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind_player(p: BugBase) -> void:
	player = p
	_shown = p.health
	_trail = p.health
	p.health_changed.connect(func(_h: float, gain: float) -> void:
		if gain > 0.0:
			_glow = 1.0)


func _process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	var h := player.health
	_shown = lerpf(_shown, h, clampf(14.0 * delta, 0.0, 1.0))
	_trail = h if h > _trail else move_toward(_trail, h, 40.0 * delta)
	_glow = maxf(_glow - delta * 1.5, 0.0)
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var w := size.x
	var hgt := size.y
	var full := BugBase.MAX_HEALTH
	var px := w / full
	var danger := player.trap_danger()
	# Frame and background.
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, hgt)), Color(0, 0, 0, 0.55))
	var shown := minf(_shown, full)
	# What you just lost.
	var trail := minf(_trail, full)
	if trail > shown:
		draw_rect(Rect2(shown * px, 2, (trail - shown) * px, hgt - 4), Color(1.0, 0.85, 0.75, 0.75))
	var f := clampf(shown / full, 0.0, 1.0)
	var col := Color(0.3, 0.85, 0.35).lerp(Color(1.0, 0.85, 0.2), clampf((0.65 - f) / 0.35, 0.0, 1.0))
	if f < 0.3:
		col = Color(0.95, 0.25, 0.2)
	if player.is_regenerating():
		col = col.lightened(0.12 + 0.1 * sin(_t * 6.0))
	if _glow > 0.0:
		col = col.lerp(Color(0.85, 1.0, 0.85), _glow * 0.6)
	draw_rect(Rect2(2, 2, maxf(shown * px - 4, 0.0), hgt - 4), col)
	# Past full (cheese): an extra gold layer over the top half.
	if _shown > full + 0.5:
		draw_rect(Rect2(2, 2, maxf((_shown - full) * px - 4, 0.0), (hgt - 4) * 0.5), Color(1.0, 0.8, 0.25))
	# A tick at every whole hit (bugs that can take more than one).
	var step := player.hit_damage()
	if step < full - 0.5:
		var x := step
		while x < full - 0.5:
			draw_line(Vector2(x * px, 2), Vector2(x * px, hgt - 2), Color(0, 0, 0, 0.6), 2.0)
			x += step
	var edge := Color(1, 1, 1, 0.8)
	if danger:
		edge = Color(1.0, 0.2, 0.15, 0.6 + 0.4 * sin(_t * 10.0))
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, hgt)), edge, false, 2.0)
