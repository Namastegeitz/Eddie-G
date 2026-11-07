class_name Wonder
extends RefCounted
## A Technical Wonder running on one racer (premium craft only). The
## definition and tier numbers come from content/wonders.json; `mech` picks
## the behaviour:
##   spinnaker  Photon Spinnaker: drifts charge the sail, faster when tacking
##              into the stellar wind (and the turn tightens); fire for a
##              light slingshot.
##   lighthouse Lighthouse Cloak: charges over time; fire for a magnetar pulse
##              that shoves rivals, then phase out on the music's beat.
##   jet        Relativistic Jet: drifts and flat-out speed spin up the disk;
##              fire for a huge straight-line burst with little steering.
##   harvest    Stellar Harvest: clean drifts feed the swarm; fire for a
##              nova overdrive (speed, acceleration, core refill).
## Overclock multiplies power and adds heat per use; at 100 heat the Wonder
## burns out: offline for a while and the engine sputters.

var r: Racer
var def: Dictionary
var mech := ""
var tier := 1
var p: Dictionary
var color := Color.WHITE
var power := 1.0
var level: Dictionary
var charge_mult := 1.0
var heat_per_use := 0.0
var heat_per_sec := 0.0
var oc: Dictionary

var charge := 0.0          # 0..100
var heat := 0.0            # 0..100; only rises when overclocked
var active := 0.0          # seconds left of the active phase
var active_len := 0.0
var burnout := 0.0         # seconds the Wonder stays offline
var sputter := 0.0         # seconds of burnout speed loss
var uses := 0
var burnouts := 0
var tack := 0.0            # 0..1, how hard the Spinnaker is tacking (HUD)
var phase_on := false      # Lighthouse: phased this tick
var _beat_period := 1.0
var _t := 0.0


func _init(racer: Racer, cfg: Dictionary) -> void:
	r = racer
	def = Content.wonder_for(String(cfg.get("craft", "")))
	mech = String(def.get("mechanic", ""))
	tier = clampi(int(cfg.get("tier", 1)), 1, 3)
	p = def.tiers[tier - 1].params
	color = def.get("color", Color.WHITE)
	oc = Content.overclock
	var levels: Array = oc.get("levels", [{"pct": 100, "power": 1.0, "heat": 0.0}])
	level = levels[clampi(int(cfg.get("overclock", 0)), 0, levels.size() - 1)]
	power = float(level.power) * Effects.mult(r.fx, "wonder_power_pct")
	charge_mult = Effects.mult(r.fx, "wonder_charge_pct")
	var heat_k := float(level.heat) * Effects.mult(r.fx, "heat_pct")
	heat_per_use = float(def.get("heat_per_use", 25)) * heat_k
	heat_per_sec = float(def.get("heat_per_second", 0)) * heat_k
	_beat_period = Audio.beat_seconds("race") * float(p.get("beats", 2))


func overclocked() -> bool:
	return heat_per_use > 0.0 or heat_per_sec > 0.0


func min_charge() -> float:
	return float(p.get("min_charge", 100))


func ready() -> bool:
	return burnout <= 0.0 and active <= 0.0 and charge >= min_charge() and not r.finished


## Speed-up applied while a Wonder is running; never stacks with a boost
## (the racer takes the larger of the two).
func _boosted(v: float) -> float:
	return 1.0 + (v - 1.0) * (1.0 + (power - 1.0) * 0.5)


func tick(dt: float) -> void:
	_t += dt
	burnout = maxf(0.0, burnout - dt)
	sputter = maxf(0.0, sputter - dt)
	phase_on = false
	tack = 0.0
	if active > 0.0:
		active -= dt
		heat += heat_per_sec * dt
		if mech == "lighthouse" and _beat_on():
			phase_on = true
			r.cloak_time = maxf(r.cloak_time, dt * 2.0)
		if active <= 0.0:
			active = 0.0
			r.emit_signal("event", "wonder_end", {"mech": mech})
	else:
		heat = maxf(0.0, heat - float(oc.get("heat_decay", 3.0)) * dt)
	if heat >= 100.0:
		_burn()
		return
	if burnout > 0.0 or r.finished or not r.race.racing:
		return
	var gain := 0.0
	match mech:
		"spinnaker":
			if r.drift_dir != 0:
				tack = _tack()
				gain = float(p.charge_drift) + float(p.charge_tack) * tack
		"lighthouse":
			gain = float(p.charge_rate)
		"jet":
			if r.drift_dir != 0:
				gain += float(p.charge_drift)
			if r.grounded and r.fwd_speed > r.max_speed * 0.85:
				gain += float(p.charge_speed)
	if active <= 0.0:
		charge = minf(100.0, charge + gain * charge_mult * dt)


## How squarely the craft points into the stellar wind (0..1).
func _tack() -> float:
	var wind: Vector3 = r.race.stellar_wind
	var h := Vector3(r.heading.x, 0.0, r.heading.z)
	if h.length_squared() < 0.01:
		return 0.0
	return clampf((-h.normalized().dot(wind) - 0.2) / 0.6, 0.0, 1.0)


## On a beat of the race music (every `beats` beats), for `blink` seconds.
func _beat_on() -> bool:
	var t := Audio.music_position()
	if t < 0.0:
		t = _t
	return fmod(t, _beat_period) < float(p.get("blink", 0.16)) * (1.0 + (power - 1.0) * 0.5)


func activate() -> bool:
	if not ready():
		return false
	var frac := charge / 100.0
	match mech:
		"spinnaker":
			active_len = float(p.burst_time) * frac * power
			r.velocity += r.heading * float(p.impulse) * frac * power
		"jet":
			active_len = float(p.jet_time) * frac * power
			r.velocity += r.heading * float(p.impulse) * frac * power
		"lighthouse":
			active_len = float(p.active_time) * power
			_pulse()
		"harvest":
			active_len = float(p.overdrive_time) * frac * power
			r.add_energy(float(p.energy) * frac * power)
	active = active_len
	charge = 0.0
	uses += 1
	heat += heat_per_use
	r.stats["wonders"] = int(r.stats.get("wonders", 0)) + 1
	r.emit_signal("event", "wonder", {"mech": mech, "color": color, "power": power, "time": active_len})
	return true


## Magnetar pulse: shove every rival in range sideways, away from us.
func _pulse() -> void:
	var radius := float(p.pulse_radius) * (1.0 + (power - 1.0) * 0.5)
	for o: Racer in r.race.racers:
		if o == r or o.is_ghost or o.finished or o.rescue_time > 0.0 or o.phased() or o.shield_time > 0.0:
			continue
		var d := o.global_position - r.global_position
		var dist := d.length()
		if dist > radius:
			continue
		var right := o.heading.cross(o.up).normalized()
		var side := signf(d.dot(right))
		if side == 0.0:
			side = 1.0
		var k := 1.0 - 0.5 * dist / radius
		o.velocity += right * side * float(p.pulse_push) * k * power
		o.velocity *= float(p.pulse_slow)
		o.wobble_time = maxf(o.wobble_time, 0.5)
		o.emit_signal("event", "pulsed", {"by": r})


func _burn() -> void:
	burnout = float(oc.get("burnout_time", 5.0))
	sputter = float(oc.get("burnout_slow_time", 2.5))
	active = 0.0
	charge = 0.0
	heat = float(oc.get("cool_to", 35))
	burnouts += 1
	r.emit_signal("event", "burnout", {})


# ---------------------------------------------------------------- hooks read by Racer
## Top-speed factor while the Wonder runs (compared with the boost factor).
func speed_mult() -> float:
	if active <= 0.0:
		return 1.0
	match mech:
		"spinnaker":
			return _boosted(float(p.burst_speed))
		"jet":
			return _boosted(float(p.jet_speed))
		"harvest":
			return _boosted(float(p.overdrive_speed))
	return 1.0


## True while the Wonder pushes the craft forward like a boost.
func thrusting() -> bool:
	return active > 0.0 and mech != "lighthouse"


func accel_mult() -> float:
	if active <= 0.0:
		return 1.0
	match mech:
		"jet":
			return float(p.jet_accel)
		"harvest":
			return float(p.overdrive_accel)
	return 1.0


## Engine sputter after a burnout.
func sputter_mult() -> float:
	return float(oc.get("burnout_speed", 0.88)) if sputter > 0.0 else 1.0


## Steering factor: the jet barely turns; tacking tightens a drift.
func turn_mult() -> float:
	if mech == "jet" and active > 0.0:
		return float(p.jet_steer)
	if mech == "spinnaker" and r.drift_dir != 0 and burnout <= 0.0:
		return 1.0 + float(p.tack_turn) * _tack()
	return 1.0


## A drift just ended. Stellar Harvest banks clean drifts into the swarm.
func on_drift_end(seconds: float, clean: bool) -> void:
	if mech != "harvest" or not clean or burnout > 0.0 or active > 0.0:
		return
	if seconds >= float(p.min_drift):
		charge = minf(100.0, charge + float(p.per_clean_second) * seconds * charge_mult)


## What the HUD shows under the meter.
func status_text() -> String:
	if burnout > 0.0:
		return "BURNOUT %.0f" % ceilf(burnout)
	if active > 0.0:
		return "ACTIVE"
	if charge >= min_charge():
		return "READY"
	if mech == "spinnaker" and tack > 0.2:
		return "TACKING"
	return ""


## AI: when to fire.
func ai_wants(straight: bool, rival_near: bool) -> bool:
	if not ready():
		return false
	match mech:
		"lighthouse":
			return rival_near
		"spinnaker", "jet":
			return straight and charge >= maxf(min_charge(), 85.0)
		"harvest":
			return charge >= 80.0
	return false
