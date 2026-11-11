class_name HandSlap
extends Hazard
## A person leans over a table, counter or shelf and slaps at you with an
## open hand: their own right arm reaches up over the spot while the warning
## ring shrinks, then the palm smacks down. Each person has one (it moves
## their arm through Human.set_reach).

enum { IDLE, AIM, SMACK, HOLD, RETRACT }

## How high the palm hovers over the spot while it aims.
const HOVER := 9.0
const SMACK_TIME := 0.08
const HOLD_TIME := 0.3
const RETRACT_TIME := 0.35

var _phase := IDLE
var _t := 0.0
var _target := Vector3.ZERO
var _telegraph := 0.7
var _human: Human
## Slaps that hit (for tests and the HUD).
var landed := 0


func _setup() -> void:
	hit_cause = &"slapped"
	impact_radius = 2.6
	# A bare hand on a pot just hurts the hand: no clang, no rebound.
	can_rebound = false


func strike(target: Vector3, telegraph: float, by: Human) -> void:
	owner_threat = by
	_human = by
	_target = target
	_telegraph = maxf(telegraph, 0.3)
	_phase = AIM
	_t = 0.0
	busy = true
	PerceptionSystem.warn_strike(target, _telegraph, impact_radius)
	AudioManager.play_at(&"whoosh", target + Vector3.UP * 10.0, -10.0, 1.3)


func _physics_process(delta: float) -> void:
	if _phase == IDLE or _human == null:
		return
	_t += delta
	match _phase:
		AIM:
			var k := _t / _telegraph
			show_telegraph(_target, impact_radius, k)
			var lift := lerpf(HOVER * 1.6, HOVER, minf(k * 1.5, 1.0)) + sin(_t * 16.0) * 0.3
			_human.set_reach(_target + Vector3.UP * lift, minf(_t / 0.25, 1.0))
			if _t >= _telegraph:
				_phase = SMACK
				_t = 0.0
				AudioManager.play_at(&"swoosh", _target, -4.0, 1.5)
		SMACK:
			var s := minf(_t / SMACK_TIME, 1.0)
			_human.set_reach(_target + Vector3.UP * lerpf(HOVER, 0.7, s), 1.0)
			if s >= 1.0:
				var p := PerceptionSystem.player
				var before := p.health if p else 0.0
				resolve_impact(_target)
				AudioManager.play_at(&"smack", _target, 2.0, 1.25)
				if p and (p.dead or p.health < before):
					landed += 1
				_phase = HOLD
				_t = 0.0
		HOLD:
			_human.set_reach(_target + Vector3.UP * 0.7, 1.0)
			if _t >= HOLD_TIME:
				_phase = RETRACT
				_t = 0.0
		RETRACT:
			var r := minf(_t / RETRACT_TIME, 1.0)
			_human.set_reach(_target + Vector3.UP * lerpf(0.7, HOVER * 1.5, r), 1.0 - r)
			if r >= 1.0:
				cancel()


## Stops the slap (stunned, gone, or done) and lowers the arm.
func cancel() -> void:
	_phase = IDLE
	busy = false
	hide_telegraph()
	if _human:
		_human.set_reach(_target, 0.0)
