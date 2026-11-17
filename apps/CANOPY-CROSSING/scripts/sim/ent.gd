class_name Ent
extends RefCounted
## One moving thing in a lane: a mover (deadly) or a platform (rideable).
## Its position is a pure function of time, so the whole lane can be asked
## "where will you be at time t?" without stepping anything.

var hazard := ""
var platform := false
var length := 1.0
var motion := "linear"      # linear | pendulum | static
var offset := 0.0           # linear: distance along the wrap; others: left edge at rest
var amp := 0.0
var period := 1.0
var phase := 0.0
var dive_period := 0.0
var dive_phase := 0.0
var dive_warn := 0.0
var dive_under := 0.0
var disabled_until := -1.0  # smashed / scared away until this world time
var pushed := 0.0           # tomato-frog push, eased back over time
var segment_of := -1        # bridges: index of the first segment of the same bridge


func x_left(speed: float, t: float) -> float:
	match motion:
		"linear":
			return fposmod(offset + speed * t + pushed, Lane.WRAP) - Lane.MARGIN
		"pendulum":
			return offset + amp * sin(TAU * t / period + phase) + pushed
		_:
			return offset + pushed


func velocity(speed: float, t: float) -> float:
	match motion:
		"linear":
			return speed
		"pendulum":
			return amp * TAU / period * cos(TAU * t / period + phase)
		_:
			return 0.0


## "up" | "warn" | "under" for diving platforms; always "up" otherwise.
func dive_state(t: float) -> String:
	if dive_period <= 0.0:
		return "up"
	var u := fposmod(t + dive_phase, dive_period)
	if u < dive_warn:
		return "warn"
	if u < dive_warn + dive_under:
		return "under"
	return "up"


func dive_progress(t: float) -> float:
	if dive_period <= 0.0:
		return 0.0
	var u := fposmod(t + dive_phase, dive_period)
	if u < dive_warn:
		return u / dive_warn
	if u < dive_warn + dive_under:
		return 1.0
	return 0.0


func active(t: float) -> bool:
	return t >= disabled_until
