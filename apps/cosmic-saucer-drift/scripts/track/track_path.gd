class_name TrackPath
extends RefCounted
## A road ribbon sampled at even spacing: position, frame (tangent, right,
## up), width and surface per sample. Used for the main loop and shortcuts.

const STEP := 2.0

var closed := true
var n := 0
var step := STEP
var length := 0.0
var pts := PackedVector3Array()
var tan := PackedVector3Array()
var rgt := PackedVector3Array()
var upv := PackedVector3Array()
var wid := PackedFloat32Array()
var bank := PackedFloat32Array()
var surf := PackedInt32Array()
var curv := PackedFloat32Array()   # signed, + = turning right (1/m)
var ctrl_s := PackedFloat32Array() # distance along the path at each control point


## Build from control points. widths/banks are per control point.
func build(ctrl: Array, widths: Array, banks: Array, is_closed: bool, auto_bank := 0.0) -> void:
	closed = is_closed
	var m := ctrl.size()
	var dense := PackedVector3Array()
	var dense_w := PackedFloat32Array()
	var dense_b := PackedFloat32Array()
	var sub := 16
	var segs := m if closed else m - 1
	for i in segs:
		var p0: Vector3 = ctrl[_ci(i - 1, m)]
		var p1: Vector3 = ctrl[_ci(i, m)]
		var p2: Vector3 = ctrl[_ci(i + 1, m)]
		var p3: Vector3 = ctrl[_ci(i + 2, m)]
		var w1: float = widths[_ci(i, m)]
		var w2: float = widths[_ci(i + 1, m)]
		var b1: float = banks[_ci(i, m)]
		var b2: float = banks[_ci(i + 1, m)]
		var last := sub if (not closed and i == segs - 1) else sub - 1
		for k in last + 1:
			var t := float(k) / float(sub)
			dense.append(catmull(p0, p1, p2, p3, t))
			var e := smoothstep(0.0, 1.0, t)
			dense_w.append(lerpf(w1, w2, e))
			dense_b.append(lerpf(b1, b2, e))
	# Arc length of the dense polyline.
	var cum := PackedFloat32Array()
	cum.resize(dense.size() + (1 if closed else 0))
	cum[0] = 0.0
	for i in range(1, cum.size()):
		cum[i] = cum[i - 1] + dense[i - 1].distance_to(dense[i % dense.size()])
	length = cum[cum.size() - 1]
	ctrl_s.resize(segs + 1)
	for k in segs + 1:
		ctrl_s[k] = cum[mini(k * sub, cum.size() - 1)]
	n = maxi(8, roundi(length / STEP))
	step = length / float(n if closed else n - 1)
	pts.resize(n)
	wid.resize(n)
	bank.resize(n)
	var j := 0
	for i in n:
		var s := step * float(i)
		while j < cum.size() - 2 and cum[j + 1] < s:
			j += 1
		var seg := maxf(cum[j + 1] - cum[j], 0.0001)
		var f := clampf((s - cum[j]) / seg, 0.0, 1.0)
		var a := dense[j]
		var b := dense[(j + 1) % dense.size()]
		pts[i] = a.lerp(b, f)
		wid[i] = lerpf(dense_w[j], dense_w[(j + 1) % dense.size()], f)
		bank[i] = lerpf(dense_b[j], dense_b[(j + 1) % dense.size()], f)
	_frames(auto_bank)
	surf.resize(n)
	surf.fill(0)


func _ci(i: int, m: int) -> int:
	return posmod(i, m) if closed else clampi(i, 0, m - 1)


## Centripetal Catmull-Rom between p1 and p2.
static func catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t0 := 0.0
	var t1 := t0 + maxf(pow(p0.distance_to(p1), 0.5), 0.01)
	var t2 := t1 + maxf(pow(p1.distance_to(p2), 0.5), 0.01)
	var t3 := t2 + maxf(pow(p2.distance_to(p3), 0.5), 0.01)
	var tt := lerpf(t1, t2, t)
	var a1 := p0 * (t1 - tt) / (t1 - t0) + p1 * (tt - t0) / (t1 - t0)
	var a2 := p1 * (t2 - tt) / (t2 - t1) + p2 * (tt - t1) / (t2 - t1)
	var a3 := p2 * (t3 - tt) / (t3 - t2) + p3 * (tt - t2) / (t3 - t2)
	var b1 := a1 * (t2 - tt) / (t2 - t0) + a2 * (tt - t0) / (t2 - t0)
	var b2 := a2 * (t3 - tt) / (t3 - t1) + a3 * (tt - t1) / (t3 - t1)
	return b1 * (t2 - tt) / (t2 - t1) + b2 * (tt - t1) / (t2 - t1)


func _frames(auto_bank: float) -> void:
	tan.resize(n)
	rgt.resize(n)
	upv.resize(n)
	curv.resize(n)
	for i in n:
		var a := pts[wi(i - 1)]
		var b := pts[wi(i + 1)]
		if not closed:
			a = pts[maxi(i - 1, 0)]
			b = pts[mini(i + 1, n - 1)]
		tan[i] = (b - a).normalized()
	for i in n:
		var t0 := tan[wi(i - 2)] if closed else tan[maxi(i - 2, 0)]
		var t1 := tan[wi(i + 2)] if closed else tan[mini(i + 2, n - 1)]
		var ang := asin(clampf(Vector2(t0.x, t0.z).normalized().cross(Vector2(t1.x, t1.z).normalized()), -1.0, 1.0))
		curv[i] = ang / (4.0 * step)
	# Smooth curvature a little so auto-banking and the AI line are stable.
	var sm := curv.duplicate()
	for i in n:
		var acc := 0.0
		for k in range(-3, 4):
			acc += curv[wi(i + k)] if closed else curv[clampi(i + k, 0, n - 1)]
		sm[i] = acc / 7.0
	curv = sm
	for i in n:
		var t := tan[i]
		var u := (Vector3.UP - t * t.dot(Vector3.UP)).normalized()
		var b_deg := bank[i] + clampf(curv[i] * auto_bank, -18.0, 18.0)
		bank[i] = b_deg
		u = u.rotated(t, deg_to_rad(b_deg))
		upv[i] = u
		rgt[i] = t.cross(u).normalized()


func wi(i: int) -> int:
	return posmod(i, n) if closed else clampi(i, 0, n - 1)


## Index of the nearest sample, searched around a hint.
func nearest(p: Vector3, hint: int, window: int) -> int:
	var best := clampi(hint, 0, n - 1)
	var bd := INF
	if window >= n / 2 or window < 0:
		for i in n:
			var d := pts[i].distance_squared_to(p)
			if d < bd:
				bd = d
				best = i
		return best
	for k in range(-window, window + 1):
		var i := wi(hint + k)
		var d := pts[i].distance_squared_to(p)
		if d < bd:
			bd = d
			best = i
	return best


## Distance along the path at sample i plus the projected offset.
func along(i: int, p: Vector3) -> float:
	return float(i) * step + clampf((p - pts[i]).dot(tan[i]), -step, step)


func lateral(i: int, p: Vector3) -> float:
	return (p - pts[i]).dot(rgt[i])


func height(i: int, p: Vector3) -> float:
	return (p - pts[i]).dot(upv[i])


## Sample index for a distance along the path (wrapped when closed).
func index_at(s: float) -> int:
	if closed:
		return posmod(roundi(s / step), n)
	return clampi(roundi(s / step), 0, n - 1)


func point_at(s: float, lat := 0.0, up_off := 0.0) -> Vector3:
	var i := index_at(s)
	return pts[i] + rgt[i] * lat + upv[i] * up_off


func frac_index(f: float) -> int:
	return index_at(f * length)


## Distance along the path of a (fractional) control point index.
func s_of_cp(c: float) -> float:
	var m := ctrl_s.size() - 1
	if closed:
		c = fposmod(c, float(m))
	else:
		c = clampf(c, 0.0, float(m))
	var i := mini(floori(c), m - 1)
	return lerpf(ctrl_s[i], ctrl_s[i + 1], c - float(i))


## Wrapped signed difference b - a along a closed path.
func delta(a: float, b: float) -> float:
	var d := b - a
	if closed:
		d = fposmod(d + length * 0.5, length) - length * 0.5
	return d
