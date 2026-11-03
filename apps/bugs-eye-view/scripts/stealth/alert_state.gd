class_name AlertState
extends RefCounted
## Shared threat awareness: UNAWARE -> SUSPICIOUS (?) -> SEARCHING -> ALERT (!).
## On its own a threat only gets as far as SEARCHING (it goes to look where it
## noticed you). ALERT - the chase - comes from the house-wide alarm gauge in
## PerceptionSystem: when it fills, every threat is alerted at once. Losing
## sight drops ALERT back to SEARCHING, then it cools down.

signal changed(new_state: int)

enum { UNAWARE, SUSPICIOUS, SEARCHING, ALERT }

var state: int = UNAWARE
var suspicion: float = 0.0
var last_known: Vector3 = Vector3.ZERO
var has_target: bool = false
var target_is_lure: bool = false
var search_time: float = 0.0
var since_seen: float = 99.0
var cfg: ThreatConfig


func setup(c: ThreatConfig) -> void:
	cfg = c


static func name_of(s: int) -> String:
	return ["Unaware", "Suspicious", "Searching", "Alert"][clampi(s, 0, 3)]


func add_suspicion(amount: float, pos: Vector3, seen: bool, is_lure: bool = false) -> void:
	suspicion = minf(suspicion + amount, cfg.alert_threshold * 1.5)
	last_known = pos
	has_target = true
	target_is_lure = is_lure
	if seen:
		since_seen = 0.0
	if suspicion >= cfg.alert_threshold and state != ALERT:
		search_time = cfg.search_duration
		_set_state(SEARCHING)
	elif suspicion >= cfg.suspicious_threshold and state == UNAWARE:
		_set_state(SUSPICIOUS)


func tick(delta: float) -> void:
	since_seen += delta
	match state:
		ALERT:
			if since_seen > cfg.lose_sight_time:
				search_time = cfg.search_duration
				_set_state(SEARCHING)
		SEARCHING:
			search_time -= delta
			suspicion = maxf(suspicion - cfg.suspicion_decay * 0.3 * delta, cfg.suspicious_threshold)
			if search_time <= 0.0:
				suspicion = cfg.suspicious_threshold
				_set_state(SUSPICIOUS)
		SUSPICIOUS, UNAWARE:
			if since_seen > 0.5:
				suspicion = maxf(suspicion - cfg.suspicion_decay * delta, 0.0)
			if state == SUSPICIOUS and suspicion <= 0.0:
				has_target = false
				_set_state(UNAWARE)


## After a stun or being fooled: the threat forgets where you were.
func lose_track() -> void:
	since_seen = 99.0
	suspicion = cfg.suspicious_threshold
	_set_state(SUSPICIOUS)


func force(new_state: int, pos: Vector3) -> void:
	last_known = pos
	has_target = true
	target_is_lure = false
	match new_state:
		ALERT:
			suspicion = cfg.alert_threshold
			since_seen = 0.0
		SEARCHING:
			suspicion = maxf(suspicion, cfg.alert_threshold)
			search_time = cfg.search_duration
		SUSPICIOUS:
			suspicion = maxf(suspicion, cfg.suspicious_threshold)
	if new_state > state or new_state == SEARCHING:
		_set_state(new_state)


func reset() -> void:
	suspicion = 0.0
	has_target = false
	since_seen = 99.0
	_set_state(UNAWARE)


func _set_state(s: int) -> void:
	if s != state:
		state = s
		changed.emit(s)
