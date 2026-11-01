class_name Swatter
extends Hazard
## Fly swatter: hovers over the target with a shrinking warning ring, then
## smacks down. Pooled by the level.

enum { IDLE, AIM, SMACK, HOLD, RETRACT }

const HOVER_HEIGHT := 16.0
const SMACK_TIME := 0.07

var _phase := IDLE
var _t := 0.0
var _target := Vector3.ZERO
var _telegraph := 0.8
var _pool: NodePool
var _paddle: Node3D
var _from_y := 0.0


func _setup() -> void:
	_paddle = get_node_or_null("Paddle")


func strike(target: Vector3, telegraph: float, by: Threat, pool: NodePool) -> void:
	owner_threat = by
	_pool = pool
	_target = target
	_telegraph = telegraph
	_phase = AIM
	_t = 0.0
	busy = true
	global_position = target
	if _paddle:
		_paddle.position = Vector3(0, 40, 0)
	PerceptionSystem.warn_strike(target, telegraph, impact_radius)
	AudioManager.play_at(&"swoosh", target + Vector3.UP * 20.0, -8.0, 0.7)


func _physics_process(delta: float) -> void:
	match _phase:
		AIM:
			_t += delta
			var k := _t / _telegraph
			show_telegraph(_target, impact_radius, k)
			if _paddle:
				_paddle.position.y = lerpf(40.0, HOVER_HEIGHT, minf(k * 1.5, 1.0)) + sin(_t * 18.0) * 0.4
			if _t >= _telegraph:
				_phase = SMACK
				_t = 0.0
				_from_y = _paddle.position.y if _paddle else HOVER_HEIGHT
				AudioManager.play_at(&"swoosh", _target, 0.0, 1.3)
		SMACK:
			_t += delta
			if _paddle:
				_paddle.position.y = lerpf(_from_y, 0.3, minf(_t / SMACK_TIME, 1.0))
			if _t >= SMACK_TIME:
				var landed := resolve_impact(_target)
				if landed:
					AudioManager.play_at(&"smack", _target)
				_phase = HOLD if landed else RETRACT
				_t = 0.0
		HOLD:
			_t += delta
			if _t > 0.35:
				_phase = RETRACT
				_t = 0.0
		RETRACT:
			_t += delta
			if _paddle:
				_paddle.position.y = lerpf(0.3, 45.0, minf(_t / 0.4, 1.0))
			if _t >= 0.4:
				_phase = IDLE
				busy = false
				hide_telegraph()
				if _pool:
					_pool.release(self)
