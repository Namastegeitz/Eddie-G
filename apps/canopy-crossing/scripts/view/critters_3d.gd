class_name Critters3D
extends RefCounted
## Animals built in the game (no model files), jointed so they can move:
## a giraffe whose neck and head swing, a bee for slow-motion close-ups
## (striped fuzzy body, see-through veined wings that beat, legs, antennae,
## compound eyes) and an exotic bird (a scarlet macaw) that flaps. Each
## returns a Node3D; animate with the static helpers below.

static var _wing_mat: StandardMaterial3D
static var _eye_mat: StandardMaterial3D


static func _node(mesh: Mesh, parent: Node3D, name := "", mat: Material = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat if mat != null else Scenery3D.material()
	if name != "":
		mi.name = name
	parent.add_child(mi)
	return mi


# ------------------------------------------------------------------ giraffe

static var _coat_mat: ShaderMaterial

## The giraffe's coat: crisp liver-brown patches split by a net of cream
## lines (worked out per pixel from the surface position, so it stays sharp
## up close), pale underneath. A vertex colour's alpha says how much coat a
## part shows: 1 = full pattern, 0 = just its own colour (hooves, mane).
static func coat() -> ShaderMaterial:
	if _coat_mat == null:
		var sh := Shader.new()
		sh.code = """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 patch_col : source_color = vec4(0.5, 0.28, 0.12, 1.0);
uniform vec4 line_col : source_color = vec4(0.96, 0.88, 0.7, 1.0);
uniform float cell = 0.13;
varying vec3 lp;
varying vec3 ln;
void vertex() { lp = VERTEX; ln = NORMAL; }
vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453);
}
void fragment() {
	vec3 p = lp / cell;
	vec3 ip = floor(p);
	vec3 fp = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	vec3 id1 = vec3(0.0);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 g = vec3(float(x), float(y), float(z));
				vec3 r = g + 0.15 + hash3(ip + g) * 0.7 - fp;
				float d = dot(r, r);
				if (d < d1) { d2 = d1; d1 = d; id1 = ip + g; } else if (d < d2) { d2 = d; }
			}
		}
	}
	float edge = sqrt(d2) - sqrt(d1);
	float m = smoothstep(0.07, 0.13, edge);
	vec3 pc = patch_col.rgb * (0.78 + 0.4 * hash3(id1).x);
	vec3 pattern = mix(line_col.rgb, pc, m);
	pattern = mix(pattern, line_col.rgb, clamp(-ln.y - 0.2, 0.0, 1.0) * 0.8);
	vec3 base = pow(COLOR.rgb, vec3(2.2));
	ALBEDO = mix(base, pattern, COLOR.a);
	ROUGHNESS = 0.8;
	SPECULAR = 0.3;
}
"""
		_coat_mat = ShaderMaterial.new()
		_coat_mat.shader = sh
	return _coat_mat


static func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


## A giraffe about `h` tall (to the top of its horns), facing +X. Nodes:
## "Neck" (pivot at the shoulders; swing it), "Neck/Head", "LegsA", "LegsB", "Body".
static func giraffe(h := 3.0) -> Node3D:
	var s := h / 3.0
	var root := Node3D.new()
	root.name = "Giraffe"
	var coat_c := Color(1, 1, 1, 1)
	var pale := _a(Color("f2dcb0"), 0.0)
	var hoof := _a(Color("2a1a10"), 0.0)
	var mane := _a(Color("6a3e1c"), 0.0)
	var k := Scenery3D.Kit.new()
	# body sloping down from the high shoulders to the rump
	k.blob(Scenery3D.xf(Vector3(0.0, 1.62, 0) * s, 0.0, 0.0, 0.16), Vector3(0.62, 0.34, 0.27) * s, coat_c, 20, 0.0)
	k.blob(Scenery3D.xf(Vector3(0.36, 1.74, 0) * s), Vector3(0.3, 0.3, 0.26) * s, coat_c, 16, 0.0)
	# tail with a dark tuft
	k.tube(PackedVector3Array([Vector3(-0.58, 1.66, 0) * s, Vector3(-0.68, 1.35, 0) * s, Vector3(-0.71, 1.0, 0.02) * s]), 0.03 * s, 0.018 * s, _a(Color("c89850"), 0.3), _a(Color("8a6a3a"), 0.0), 6)
	k.blob(Scenery3D.xf(Vector3(-0.71, 0.94, 0.02) * s), Vector3(0.045, 0.1, 0.045) * s, hoof, 6)
	_node(k.mesh(), root, "Body", coat())
	# legs in two diagonal pairs, so a walk can swing them
	for pair in ["LegsA", "LegsB"]:
		var legs := Node3D.new()
		legs.name = pair
		legs.position = Vector3(0, 1.45, 0) * s
		root.add_child(legs)
		var lk := Scenery3D.Kit.new()
		var spots := [[0.4, 0.15], [-0.42, -0.15]] if pair == "LegsA" else [[0.4, -0.15], [-0.42, 0.15]]
		for sp in spots:
			var top := Vector3(sp[0], 0.0, sp[1]) * s
			var knee := top + Vector3(0.03 if sp[0] > 0.0 else -0.05, -0.72, 0) * s
			var foot := top + Vector3(0.0, -1.42, 0) * s
			lk.tube(PackedVector3Array([top + Vector3(0, 0.1, 0) * s, top.lerp(knee, 0.5), knee]), 0.1 * s, 0.05 * s, coat_c, _a(Color("e8cfa0"), 0.6), 10)
			lk.tube(PackedVector3Array([knee, knee.lerp(foot, 0.5), foot + Vector3(0, 0.05, 0) * s]), 0.05 * s, 0.038 * s, _a(Color("e8cfa0"), 0.35), pale, 8)
			lk.blob(Scenery3D.xf(knee), Vector3(0.055, 0.06, 0.055) * s, _a(Color("e0c490"), 0.2), 8)
			lk.blob(Scenery3D.xf(foot + Vector3(0.015, 0.03, 0) * s), Vector3(0.06, 0.04, 0.055) * s, hoof, 8)
		_node(lk.mesh(), legs, "", coat())
	# the neck, on a pivot at the shoulders, leaning forward
	var neck := Node3D.new()
	neck.name = "Neck"
	neck.position = Vector3(0.48, 1.8, 0) * s
	neck.rotation.z = -0.45
	root.add_child(neck)
	var nk := Scenery3D.Kit.new()
	var npts := PackedVector3Array()
	var steps := 10
	for i in steps + 1:
		npts.append(Vector3(0.015 * sin(i * 0.4), float(i) / steps * 1.3, 0) * s)
	nk.tube(npts, 0.19 * s, 0.085 * s, coat_c, coat_c, 16)
	# the short stiff mane down the back of the neck
	var mpts := PackedVector3Array()
	for i in 8:
		var f := i / 7.0
		mpts.append(Vector3(-lerpf(0.17, 0.08, f) + 0.0, 0.05 + f * 1.2, 0) * s)
	nk.tube(mpts, 0.03 * s, 0.022 * s, mane, mane, 5)
	_node(nk.mesh(), neck, "NeckMesh", coat())
	# the head at the top of the neck, looking forward and a little down
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.3, 0) * s
	head.rotation.z = -0.15
	neck.add_child(head)
	var hk := Scenery3D.Kit.new()
	hk.blob(Scenery3D.xf(Vector3(0.12, 0.0, 0) * s), Vector3(0.2, 0.11, 0.1) * s, _a(Color("d8b070"), 0.25), 26)
	hk.blob(Scenery3D.xf(Vector3(0.3, -0.02, 0) * s), Vector3(0.12, 0.085, 0.085) * s, _a(Color("c89a60"), 0.0), 22)
	hk.blob(Scenery3D.xf(Vector3(0.4, -0.045, 0) * s), Vector3(0.03, 0.045, 0.07) * s, _a(Color("5a3a24"), 0.0), 14)
	for side2 in [-1.0, 1.0]:
		# horns (ossicones) with dark tufted tips, ears, nostrils
		hk.cylinder(Scenery3D.xf(Vector3(-0.02, 0.07, side2 * 0.045) * s, 0.0, side2 * 0.18, 0.15), 0.022 * s, 0.018 * s, 0.17 * s, _a(Color("d8b070"), 0.2), _a(Color("c89a60"), 0.0), 8)
		hk.blob(Scenery3D.xf(Vector3(-0.045, 0.25, side2 * 0.075) * s), Vector3(0.032, 0.035, 0.032) * s, hoof, 6)
		hk.blob(Scenery3D.xf(Vector3(-0.07, 0.06, side2 * 0.13) * s, 0.0, side2 * 0.7, 0.3), Vector3(0.09, 0.022, 0.04) * s, _a(Color("e0c08a"), 0.0), 14)
		hk.blob(Scenery3D.xf(Vector3(0.405, -0.0, side2 * 0.035) * s), Vector3(0.012, 0.008, 0.008) * s, hoof, 5)
	_node(hk.mesh(), head, "HeadMesh", coat())
	for side3 in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.032 * s
		em.height = 0.064 * s
		eye.mesh = em
		eye.material_override = _eye()
		eye.position = Vector3(0.13, 0.045, side3 * 0.088) * s
		head.add_child(eye)
	return root


## Swing the giraffe's neck: `k` from -1 (head thrown back) to 1 (swung
## down and forward); `side` swings it across (+ = towards +Z).
static func giraffe_swing(g: Node3D, k: float, t: float, side := 0.0) -> void:
	var neck: Node3D = g.get_node("Neck")
	neck.rotation = Vector3(side, sin(t * 0.7) * 0.08, -0.45 - k * 0.75)
	(neck.get_node("Head") as Node3D).rotation.z = -0.15 + k * 0.45


static func giraffe_walk(g: Node3D, t: float, amount := 1.0) -> void:
	var ph := t * 3.2
	(g.get_node("LegsA") as Node3D).rotation.z = sin(ph) * 0.2 * amount
	(g.get_node("LegsB") as Node3D).rotation.z = -sin(ph) * 0.2 * amount
	(g.get_node("Body") as Node3D).position.y = absf(sin(ph)) * 0.025 * amount


static func _eye() -> StandardMaterial3D:
	if _eye_mat == null:
		_eye_mat = StandardMaterial3D.new()
		_eye_mat.albedo_color = Color(0.05, 0.03, 0.02)
		_eye_mat.roughness = 0.08
		_eye_mat.metallic_specular = 1.0
	return _eye_mat


# ------------------------------------------------------------------ bee

## A honeybee `size` long, facing +X. Nodes: "WingL", "WingR" (beat them).
## `simple` (in the game): fewer pieces to draw, for bees seen from afar.
static func bee(size := 0.06, simple := false) -> Node3D:
	var s := size / 0.06
	var root := Node3D.new()
	root.name = "Bee"
	var k := Scenery3D.Kit.new()
	var gold := Color("d8a032")
	var black := Color("1a120a")
	var fuzz := Color("c89a52")
	# abdomen in rings of gold and black
	for i in 6:
		var x := -0.006 - i * 0.0055
		var r := 0.0125 * (1.0 - absf(i - 2.0) * 0.14)
		k.blob(Scenery3D.xf(Vector3(x, 0, 0) * s), Vector3(0.0045, r, r) * s, gold if i % 2 == 0 else black, 22)
	k.blob(Scenery3D.xf(Vector3(-0.037, 0, 0) * s), Vector3(0.004, 0.004, 0.004) * s, black, 12)
	# thorax and head
	k.blob(Scenery3D.xf(Vector3(0.006, 0.001, 0) * s), Vector3(0.011, 0.01, 0.01) * s, Color("6a4a22"), 24)
	k.blob(Scenery3D.xf(Vector3(0.02, 0.0, 0) * s), Vector3(0.007, 0.008, 0.008) * s, black, 20)
	# fuzz: fine hairs all over the thorax and the front of the abdomen
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 420:
		var a := rng.randf() * TAU
		var c := Vector3(rng.randf_range(-0.012, 0.015), sin(a) * 0.0097, cos(a) * 0.0097) * s
		if c.x < -0.004 * s:
			c = Vector3(c.x, c.y * 1.2, c.z * 1.2)
		var dir := (c - Vector3(c.x * 0.6, 0, 0)).normalized()
		var hl := rng.randf_range(0.0012, 0.0024) * s
		var hc := fuzz.lerp(Color("e8c890"), rng.randf() * 0.6)
		k.tube(PackedVector3Array([c, c + dir * hl + Vector3(-0.0008, 0.0004, 0) * s]), 0.00011 * s, 0.00003 * s, hc, hc.lightened(0.25), 3)
	# legs
	for side in [-1.0, 1.0]:
		for j in 3:
			var hip := Vector3(0.012 - j * 0.006, -0.006, side * 0.004) * s
			k.tube(PackedVector3Array([hip, hip + Vector3(0.002, -0.006, side * 0.008) * s, hip + Vector3(-0.002, -0.014, side * 0.01) * s]), 0.0009 * s, 0.0005 * s, black, black, 6)
		# antennae
		var base := Vector3(0.026, 0.004, side * 0.003) * s
		k.tube(PackedVector3Array([base, base + Vector3(0.004, 0.008, side * 0.003) * s, base + Vector3(0.011, 0.01, side * 0.005) * s]), 0.0007 * s, 0.0005 * s, black, black, 6)
	if simple:
		for side4 in [-1.0, 1.0]:
			k.blob(Scenery3D.xf(Vector3(0.0215, 0.0025, side4 * 0.0062) * s), Vector3(0.0034, 0.0058, 0.0027) * s, Color("140c06"), 8)
	_node(k.mesh(), root, "Body")
	# big dark compound eyes
	for side2 in ([] if simple else [-1.0, 1.0]):
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.0045 * s
		em.height = 0.009 * s
		eye.mesh = em
		eye.material_override = _eye()
		eye.position = Vector3(0.0215, 0.0025, side2 * 0.0062) * s
		eye.scale = Vector3(0.75, 1.3, 0.6)
		root.add_child(eye)
	# wings: see-through, veined, on hinges at the thorax
	for side3 in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.name = "WingL" if side3 < 0.0 else "WingR"
		hinge.position = Vector3(0.008, 0.009, side3 * 0.004) * s
		root.add_child(hinge)
		for w in (1 if simple else 2):
			var wing := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.034, 0.013) * s if w == 0 else Vector2(0.022, 0.009) * s
			wing.mesh = qm
			wing.material_override = _wing()
			wing.rotation_degrees = Vector3(90, 0, 0)
			wing.position = Vector3(-0.012 - w * 0.004, 0.0, side3 * (0.008 + w * 0.002)) * s
			hinge.add_child(wing)
	return root


## Beat the bee's wings (`t` in the bee's own time: slow it down for slow motion).
static func bee_beat(b: Node3D, t: float) -> void:
	var flap := sin(t * 230.0 * TAU / 10.0) * 0.9
	(b.get_node("WingL") as Node3D).rotation = Vector3(-flap, 0.0, 0.25)
	(b.get_node("WingR") as Node3D).rotation = Vector3(flap, 0.0, 0.25)


static func _wing() -> StandardMaterial3D:
	if _wing_mat == null:
		var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.9, 0.95, 1.0, 0.36))
		# dark veins
		for v in 7:
			var y0 := 8 + v * 7
			for x in 128:
				var y := int(y0 + sin(x * 0.05 + v) * 2.0 + (x - 64) * 0.04 * (v - 3))
				if y >= 0 and y < 64:
					img.set_pixel(x, y, Color(0.2, 0.16, 0.1, 0.7))
		for x2 in range(10, 128, 22):
			for y2 in 64:
				img.set_pixel(x2 + int(y2 * 0.2), y2, Color(0.2, 0.16, 0.1, 0.55)) if x2 + int(y2 * 0.2) < 128 else null
		_wing_mat = StandardMaterial3D.new()
		_wing_mat.albedo_texture = ImageTexture.create_from_image(img)
		_wing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_wing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_wing_mat.roughness = 0.15
		_wing_mat.metallic_specular = 0.9
	return _wing_mat


# ------------------------------------------------------------------ birds

## An exotic bird (scarlet macaw colours by default) `span` across the
## wings, flying towards +X. Nodes: "WingL", "WingR".
static func bird(span := 0.9, body := Color("d8241a"), wing_mid := Color("f2c21a"), wing_tip := Color("2a5ad8")) -> Node3D:
	var s := span / 0.9
	var root := Node3D.new()
	var k := Scenery3D.Kit.new()
	k.blob(Scenery3D.xf(Vector3(0, 0, 0)), Vector3(0.16, 0.06, 0.06) * s, body, 10)
	k.blob(Scenery3D.xf(Vector3(0.16, 0.02, 0) * s), Vector3(0.05, 0.05, 0.045) * s, body, 8)
	k.blob(Scenery3D.xf(Vector3(0.2, 0.0, 0) * s), Vector3(0.03, 0.035, 0.03) * s, Color("f2ead8"), 6)
	k.blob(Scenery3D.xf(Vector3(0.235, -0.005, 0) * s, 0.0, 0.0, -0.4), Vector3(0.025, 0.03, 0.02) * s, Color("2a2420"), 6)
	# long tail
	k.tube(PackedVector3Array([Vector3(-0.14, 0, 0) * s, Vector3(-0.32, -0.02, 0) * s, Vector3(-0.5, -0.03, 0) * s]), 0.035 * s, 0.01 * s, body, wing_tip, 5)
	_node(k.mesh(), root, "Body")
	for side in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.name = "WingL" if side < 0.0 else "WingR"
		hinge.position = Vector3(0.02, 0.03, side * 0.04) * s
		root.add_child(hinge)
		var wk := Scenery3D.Kit.new()
		# a fan of overlapping feathers: coverts near the body, long flight
		# feathers out to the tip, swept back
		for f in 9:
			var t := f / 8.0
			var c := body.lerp(wing_mid, clampf(t * 2.2, 0.0, 1.0)).lerp(wing_tip, clampf(t * 2.0 - 0.9, 0.0, 1.0))
			var yaw := lerpf(-PI * 0.5 + 0.15, -0.35, t)
			if side < 0.0:
				yaw = PI - yaw
			var base := Vector3(-0.01 - t * 0.02, 0.0, side * (0.02 + t * 0.26)) * s
			wk.blade(Scenery3D.xf(base, yaw, 0.0, 0.0), lerpf(0.2, 0.3, t) * s, 0.11 * s, c, c.darkened(0.12), -0.05, 2)
		# the bright shoulder coverts on top
		wk.blob(Scenery3D.xf(Vector3(-0.03, 0.01, side * 0.1) * s), Vector3(0.07, 0.015, 0.09) * s, wing_mid, 8)
		_node(wk.mesh(), hinge)
	return root


## Folds a bird's wings back along its body and sits it upright (perched).
static func perch(b: Node3D) -> void:
	(b.get_node("WingL") as Node3D).rotation = Vector3(0.15, 1.35, 0)
	(b.get_node("WingR") as Node3D).rotation = Vector3(-0.15, -1.35, 0)
	b.rotation.z = 0.7


static func bird_flap(b: Node3D, t: float) -> void:
	var f := sin(t * 9.0) * 0.7
	(b.get_node("WingL") as Node3D).rotation.x = f
	(b.get_node("WingR") as Node3D).rotation.x = -f


# ------------------------------------------------------------------ flowers

## A red hibiscus on a leafy stem, about `h` tall, for bees to work: five
## ruffled petals, a long stamen column dusted with pollen. The bloom faces
## +X and a little up; "Bloom" is its centre (where a bee hovers).
static func flower(h := 1.2) -> Node3D:
	var s := h / 1.2
	var root := Node3D.new()
	var k := Scenery3D.Kit.new()
	var stem_top := Vector3(0.05, 1.12, 0) * s
	k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.03, 0.5, 0.02) * s, stem_top]), 0.014 * s, 0.009 * s, Color("2a5a1a"), Color("3a7a24"), 6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 9:
		var y := rng.randf_range(0.15, 0.95)
		var a := rng.randf() * TAU
		k.blade(Scenery3D.xf(Vector3(0.02, y, 0.01) * s, a, -0.5), 0.22 * s, 0.11 * s, Color("2a6a1e"), Color("4a9a2a"), 0.35, 4)
	_node(k.mesh(), root)
	var bloom := Node3D.new()
	bloom.name = "Bloom"
	bloom.position = stem_top + Vector3(0.02, 0.03, 0) * s
	bloom.rotation = Vector3(0, 0, -1.0)
	root.add_child(bloom)
	var pk := Scenery3D.Kit.new()
	var red := Color("d81e2a")
	for i in 5:
		var a2 := TAU * i / 5.0
		# each petal: broad, curving outwards, deeper red at the heart
		_petal(pk, Scenery3D.xf(Vector3.ZERO, a2, -0.3, 0.0), 0.11 * s, 0.12 * s, Color("6a0614"), red, float(i))
	# the stamen column with pollen and five stigma pads
	var col_top := Vector3(0, 0.1, 0) * s
	pk.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, 0.05, 0) * s, col_top]), 0.004 * s, 0.003 * s, Color("e8c0a0"), Color("f2d0b0"), 6)
	for j in 14:
		var yy := rng.randf_range(0.055, 0.09)
		var aa := rng.randf() * TAU
		pk.blob(Scenery3D.xf(Vector3(cos(aa) * 0.006, yy, sin(aa) * 0.006) * s), Vector3(0.003, 0.003, 0.003) * s, Color("f6c21a"), 10)
	for q in 5:
		var aq := TAU * q / 5.0
		pk.blob(Scenery3D.xf(col_top + Vector3(cos(aq) * 0.006, 0.004, sin(aq) * 0.006) * s), Vector3(0.003, 0.003, 0.003) * s, Color("b8102a"), 10)
	_node(pk.mesh(), bloom, "Petals")
	return root



## One hibiscus petal: broad at the tip, cupped across, curling outwards,
## its edge ruffled, fine veins running out from a deep red heart.
static func _petal(k: Scenery3D.Kit, xf: Transform3D, length: float, width: float, heart: Color, tip: Color, salt: float) -> void:
	var nl := 14
	var nw := 10
	var base := k.v.size()
	var up := (xf.basis * Vector3.UP).normalized()
	for i in nl + 1:
		var t := float(i) / nl
		var w := width * 0.5 * pow(sin(PI * clampf(t * 0.78 + 0.12, 0.0, 1.0)), 0.6)
		for j in nw + 1:
			var v := float(j) / nw * 2.0 - 1.0
			var x := v * w
			var y := v * v * w * 0.3 - t * t * length * 0.12
			y += sin(v * 7.0 + salt * 1.7 + t * 2.0) * 0.07 * w * t * t
			var c := heart.lerp(tip, smoothstep(0.0, 0.45, t))
			if absf(sin(v * PI * 3.5)) < 0.12 and t > 0.08:
				c = c.darkened(0.14)
			c = c.lightened(0.06 * (1.0 - absf(v)) * t)
			k._add(xf * Vector3(x, y, t * length), up, c)
	for i in nl:
		for j in nw:
			var a := base + i * (nw + 1) + j
			k.quad(a, a + nw + 1, a + nw + 2, a + 1)
