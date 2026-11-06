class_name BouncePad
extends Area3D
## Something springy - a kitchen sponge, a sofa cushion, a mushroom cap.
## Step or hop onto it and it flings you up in an arc onto `target` (a
## counter, a shelf, the top of the shed). Steer a little in the air.

## Where the arc lands (world space, on the top of the surface).
@export var target: Vector3 = Vector3.ZERO
## How far above the higher end the arc peaks.
@export var apex_above: float = 6.0
## Shown when you're standing next to it the first time.
@export var label: String = "sponge"

var launches := 0
var _cd := 0.0
var _visual: Node3D
var _rest_scale := Vector3.ONE


func _ready() -> void:
	collision_layer = Phys.ZONE
	collision_mask = Phys.PLAYER
	monitorable = false
	add_to_group(&"bounce_pad")
	body_entered.connect(_on_body_entered)
	_visual = get_parent().get_node_or_null("Mesh") as Node3D if get_parent() else null
	if _visual:
		_rest_scale = _visual.scale


func _physics_process(delta: float) -> void:
	_cd = maxf(_cd - delta, 0.0)
	if _cd <= 0.0 and monitoring:
		# A bug that stayed on the pad (or landed back on it) goes again.
		for b in get_overlapping_bodies():
			if b is BugBase:
				_on_body_entered(b)
				break


func _on_body_entered(b: Node3D) -> void:
	var bug := b as BugBase
	if bug == null or bug.dead or _cd > 0.0 or bug.stuck_time > 0.0:
		return
	if launch(bug):
		_cd = 0.6


## The velocity and flight time that carry `from` to `target` over the apex.
func arc_from(from: Vector3, g: float) -> Array:
	var to := target + Vector3.UP * 0.4
	var peak := maxf(from.y, to.y) + apex_above
	var vy := sqrt(2.0 * g * maxf(peak - from.y, 0.1))
	var t := vy / g + sqrt(2.0 * maxf(peak - to.y, 0.0) / g)
	var h := Vector3(to.x - from.x, 0.0, to.z - from.z) / maxf(t, 0.05)
	return [h + Vector3.UP * vy, t]


func launch(bug: BugBase) -> bool:
	var arc := arc_from(bug.global_position, bug.air_gravity())
	if not bug.launch(arc[0], arc[1]):
		return false
	launches += 1
	AudioManager.play_at(&"boing", global_position, -2.0, randf_range(0.9, 1.1))
	if _visual:
		var tw := create_tween()
		tw.tween_property(_visual, "scale", _rest_scale * Vector3(1.15, 0.55, 1.15), 0.06)
		tw.tween_property(_visual, "scale", _rest_scale, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return true
