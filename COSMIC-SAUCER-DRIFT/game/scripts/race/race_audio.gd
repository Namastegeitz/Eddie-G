class_name RaceAudio
extends Node
## Engine sounds: a 2D engine loop for each local player (pitch follows
## speed, rises on boost, sputters in Emergency Hover) and quieter 3D
## engines on the AI saucers.

var race: Node
var _players := {}   # racer idx -> AudioStreamPlayer / AudioStreamPlayer3D


func setup(p_race: Node) -> void:
	race = p_race
	var s := Audio.stream("engine")
	if s == null:
		return
	for r: Racer in race.racers:
		if r.is_ghost:
			continue
		if r.is_human:
			var p := AudioStreamPlayer.new()
			p.stream = s
			p.bus = "SFX"
			p.volume_db = -10.0 if race.humans.size() == 1 else -14.0
			add_child(p)
			p.play()
			_players[r.idx] = p
		else:
			var p3 := AudioStreamPlayer3D.new()
			p3.stream = s
			p3.bus = "SFX"
			p3.unit_size = 6.0
			p3.max_distance = 60.0
			p3.volume_db = -14.0
			r.add_child(p3)
			p3.play()
			_players[r.idx] = p3


func _process(_dt: float) -> void:
	for r: Racer in race.racers:
		if not _players.has(r.idx):
			continue
		var p: Node = _players[r.idx]
		var ratio := clampf(r.fwd_speed / maxf(r.max_speed, 1.0), 0.0, 1.5)
		var pitch := 0.55 + ratio * 0.75 + (0.18 if r.boost_time > 0.0 else 0.0)
		if r.emergency:
			pitch *= 0.8 + 0.1 * sin(Time.get_ticks_msec() * 0.03)
		p.set("pitch_scale", maxf(pitch, 0.2))
