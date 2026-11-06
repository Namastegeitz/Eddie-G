class_name BugRig
extends Node
## Brings a bug's placeholder body to life: a walking gait for the jointed
## legs (tripod for six legs, alternating for eight), swaying antennae,
## breathing, legs tucked in flight, and an antenna-cleaning idle when the bug
## has been still for a while. Purely visual; reads the parent BugBase.

## "tripod" (insects) or "alternate" (spiders).
@export var gait: String = "tripod"
@export var swing_amount: float = 0.38
@export var lift_amount: float = 0.35

var bug: BugBase
const FP_FRONT_REACH := 0.45
var legs: Array[Node3D] = []
var antennae: Array[Node3D] = []
var abdomen: Node3D
var phase := 0.0
var _t := 0.0
var _abdomen_scale := Vector3.ONE


func _ready() -> void:
	bug = get_parent() as BugBase
	var v := get_parent().get_node_or_null("Visual")
	if v == null:
		return
	for c in v.get_children():
		var n := c as Node3D
		if n == null:
			continue
		if n.has_meta(&"group"):
			legs.append(n)
		elif n.has_meta(&"base") and String(n.name).begins_with("Antenna"):
			antennae.append(n)
	abdomen = v.get_node_or_null("Abdomen") as Node3D
	if abdomen:
		_abdomen_scale = abdomen.scale


func _process(delta: float) -> void:
	if bug == null or bug.dead:
		return
	_t += delta
	var speed := bug.motion_speed()
	var airborne := bug is Fly and (bug as Fly).flying
	var moving := clampf(speed / 3.0, 0.0, 1.0) if not airborne else 0.0
	phase += delta * (5.0 + speed * 0.9) * moving
	var grooming := bug.motion == BugBase.Motion.STILL and bug.still_time > 3.0 and fmod(_t, 5.0) < 1.6
	var k := clampf(12.0 * delta, 0.0, 1.0)
	# Through the bug's own eyes the front pair reaches forward, so you see
	# your legs step into the bottom corners of the view.
	var fp := bug.in_first_person()
	for leg in legs:
		var side := float(leg.get_meta(&"side"))
		var g := int(leg.get_meta(&"group"))
		var base_yaw := float(leg.get_meta(&"base_yaw"))
		if fp and String(leg.name).ends_with("1"):
			base_yaw += side * FP_FRONT_REACH
		var base_z := float(leg.get_meta(&"base_z"))
		var p := phase + (PI if g == 1 else 0.0)
		var yaw := base_yaw + sin(p) * swing_amount * moving * side
		var lift := maxf(cos(p), 0.0) * lift_amount * moving
		if airborne:
			# Legs dangle and fold under the body in flight.
			lift = -0.45
			yaw = base_yaw * 0.6
		elif grooming and String(leg.name).ends_with("1") and side < 0.0:
			# Front leg reaches up to clean the antenna.
			lift = 0.9
			yaw = base_yaw + 0.5 * side
		leg.rotation.y = lerp_angle(leg.rotation.y, yaw, k)
		leg.rotation.z = lerp_angle(leg.rotation.z, base_z + side * lift, k)
	var sensing := bug.sense_active
	for a in antennae:
		var side := float(a.get_meta(&"side"))
		var base: Vector3 = a.get_meta(&"base")
		var rate := 9.0 if sensing else 2.6
		var amp := 0.28 if sensing else 0.12
		var target := base + Vector3(sin(_t * rate + side) * amp, cos(_t * rate * 0.7 + side * 2.0) * amp * side, 0)
		if grooming and side < 0.0:
			target = base + Vector3(-0.8, 0.3, 0)
		a.rotation = a.rotation.lerp(target, k)
	if abdomen:
		var b := 1.0 + sin(_t * (6.0 if speed > 1.0 else 2.2)) * 0.035
		abdomen.scale = _abdomen_scale * Vector3(b, b, 1.0 + (b - 1.0) * 0.5)
