class_name Minimap
extends Control
## Top-down outline of the track with a dot per racer.

var race: Node
var focus: Racer
var _pts := PackedVector2Array()
var _short := PackedVector2Array()
var _min := Vector2.ZERO
var _scale := 1.0


func setup(p_race: Node, p_focus: Racer) -> void:
	race = p_race
	focus = p_focus
	var td: TrackData = race.td
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in range(0, td.main.n, 3):
		var p := td.main.pts[i]
		lo = lo.min(Vector2(p.x, p.z))
		hi = hi.max(Vector2(p.x, p.z))
	_min = lo
	var span := hi - lo
	_scale = 1.0 / maxf(span.x, span.y)
	for i in range(0, td.main.n, 3):
		_pts.append(Vector2(td.main.pts[i].x, td.main.pts[i].z))
	_pts.append(_pts[0])
	if td.short:
		for i in range(0, td.short.n, 3):
			_short.append(Vector2(td.short.pts[i].x, td.short.pts[i].z))


func _map(p: Vector2) -> Vector2:
	var pad := 10.0
	var s := minf(size.x, size.y) - pad * 2.0
	return Vector2(pad, pad) + (p - _min) * _scale * s


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if race == null:
		return
	var pts := PackedVector2Array()
	for p in _pts:
		pts.append(_map(p))
	draw_polyline(pts, Color(0, 0, 0, 0.5), 9.0)
	draw_polyline(pts, Color(0.8, 0.85, 1.0, 0.85), 4.0)
	if not _short.is_empty() and Save.data.get("found_short", {}).has(race.td.id):
		var sp := PackedVector2Array()
		for p in _short:
			sp.append(_map(p))
		draw_polyline(sp, Color(1.0, 0.6, 0.2, 0.6), 2.0)
	var tdm: TrackData = race.td
	var st := tdm.main.pts[0]
	draw_circle(_map(Vector2(st.x, st.z)), 4.0, Color.WHITE)
	for r: Racer in race.racers:
		var p := _map(Vector2(r.global_position.x, r.global_position.z))
		if r == focus:
			continue
		var c: Color = r.pilot.color
		if r.is_ghost:
			c = Color(1, 1, 1, 0.4)
		draw_circle(p, 5.0, Color(0, 0, 0, 0.6))
		draw_circle(p, 4.0, c)
	if focus:
		var p := _map(Vector2(focus.global_position.x, focus.global_position.z))
		draw_circle(p, 8.0, Color(0, 0, 0, 0.7))
		draw_circle(p, 6.5, Color.WHITE)
		draw_circle(p, 4.0, focus.pilot.color)
