class_name PilotModel
extends Node3D
## An alien pilot in the cockpit: head with its own face (eyes that blink and
## look where you steer, eyelids, highlights, mouths for each mood), outfit,
## accessories, and arms on the control yoke. Built from MeshKit parts and
## baked into a few meshes; face details fade out with distance and are
## swapped for a simple baked face far away.

enum Mood { NEUTRAL, FOCUS, GRIN, DIZZY, CHEER, SAD, SHOCK }

## Per-pilot design.
const LOOKS := {
	"zib": {"head": "egg", "iris": Color(0.1, 0.45, 0.15), "suit": Color(0.95, 0.95, 1.0), "trim": Color(1.0, 0.55, 0.15),
		"acc": "antennae", "spots": true},
	"nova": {"head": "round", "iris": Color(0.95, 0.7, 0.15), "suit": Color(0.12, 0.16, 0.4), "trim": Color(0.3, 0.95, 1.0),
		"acc": "goggles"},
	"gloop": {"head": "drop", "iris": Color(0.35, 0.9, 0.3), "suit": Color(0.6, 0.3, 0.9), "trim": Color(0.85, 0.6, 1.0),
		"acc": "bubbles", "slime": true},
	"krell": {"head": "wide", "iris": Color(0.85, 0.12, 0.1), "suit": Color(0.2, 0.22, 0.28), "trim": Color(1.0, 0.8, 0.25),
		"acc": "captain", "brows": true},
	"vexa": {"head": "round", "iris": Color(0.55, 0.2, 0.85), "suit": Color(0.95, 0.9, 1.0), "trim": Color(1.0, 0.35, 0.65),
		"acc": "crest", "lashes": true, "blush": true},
	"bleep": {"head": "box", "iris": Color(0.2, 0.9, 1.0), "suit": Color(0.55, 0.58, 0.65), "trim": Color(1.0, 0.25, 0.2),
		"acc": "robot", "robot": true},
	"zorba": {"head": "round", "iris": Color(0.45, 0.25, 0.1), "suit": Color(0.85, 0.3, 0.45), "trim": Color(0.3, 0.85, 0.7),
		"acc": "scarf", "blush": true},
	"comet": {"head": "dog", "iris": Color(0.35, 0.2, 0.08), "suit": Color(0.25, 0.45, 0.95), "trim": Color(1.0, 0.85, 0.2),
		"acc": "ears"},
	# Creatures. Extra keys: sclera (eye white colour), iris_glow, eye_scale,
	# skin_glow, lump (knobbly head), fangs, spot_color / spot_glow.
	"imp": {"head": "round", "iris": Color(1.0, 0.72, 0.08), "sclera": Color(1.0, 0.93, 0.6), "iris_glow": 1.4,
		"suit": Color(0.14, 0.1, 0.12), "trim": Color(1.0, 0.45, 0.1), "acc": "horns", "fangs": true, "brows": true},
	"moth": {"head": "round", "iris": Color(0.1, 0.12, 0.2), "sclera": Color(0.06, 0.05, 0.09), "iris_glow": 0.3, "eye_scale": 1.3,
		"suit": Color(0.55, 0.5, 0.42), "trim": Color(0.97, 0.93, 0.78), "acc": "moth"},
	"seer": {"head": "gem", "iris": Color(0.6, 0.3, 1.0), "iris_glow": 1.6, "skin_glow": 0.35,
		"suit": Color(0.12, 0.14, 0.38), "trim": Color(0.6, 0.95, 1.0), "acc": "crystals"},
	"squid": {"head": "mantle", "iris": Color(0.95, 0.85, 0.2), "sclera": Color(0.92, 0.96, 0.82), "iris_glow": 0.5,
		"suit": Color(0.2, 0.12, 0.35), "trim": Color(0.3, 1.0, 0.85), "acc": "tentacles", "slime": true,
		"spots": true, "spot_color": Color(0.3, 1.0, 0.85), "spot_glow": 2.0},
	"jelly": {"head": "bell", "iris": Color(0.15, 0.25, 0.85), "skin_glow": 0.7,
		"suit": Color(0.3, 0.6, 0.9), "trim": Color(1.0, 0.5, 0.9), "acc": "jelly", "slime": true},
	"wraith": {"head": "round", "iris": Color(0.4, 1.0, 1.0), "sclera": Color(0.03, 0.04, 0.08), "iris_glow": 3.0,
		"suit": Color(0.07, 0.07, 0.13), "trim": Color(0.45, 0.95, 1.0), "acc": "hood"},
	"troll": {"head": "wide", "lump": 0.09, "iris": Color(0.9, 0.55, 0.1), "sclera": Color(0.95, 0.9, 0.62),
		"suit": Color(0.35, 0.25, 0.15), "trim": Color(0.55, 0.75, 0.25), "acc": "troll", "brows": true},
	"hive": {"head": "insect", "iris": Color(0.65, 0.06, 0.05), "sclera": Color(0.14, 0.05, 0.04), "iris_glow": 0.7,
		"suit": Color(0.2, 0.18, 0.1), "trim": Color(0.95, 0.75, 0.2), "acc": "hive"},
}

## How far forward the eyes sit for each head shape (share of a sphere's).
const EYE_DEPTH := {"box": 0.78, "bell": 0.9, "mantle": 0.75, "gem": 0.8, "insect": 0.8}

var mood := 0
var _h := 0.4                     # head radius
var _head: Node3D
var _eyes: Array[Node3D] = []      # look pivots (iris + pupil)
var _lids: Array[Node3D] = []
var _mouths: Array[Node3D] = []    # by mouth kind
var _arms: Array[Node3D] = []
var _stars: Node3D
var _near: Array[GeometryInstance3D] = []
var _far: GeometryInstance3D
var _blink := 0.0
var _next_blink := 2.0
var _look := Vector2.ZERO
var _glance := Vector2.ZERO
var _glance_t := 1.5
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _robot := false
var _antennae: Array[Node3D] = []
static var _mats := {}

enum M { SMILE, GRIN, OH, FROWN }


static func _mat(c: Color, rough := 0.5, metal := 0.0, emit := 0.0, coat := 0.0, rim := 0.5) -> StandardMaterial3D:
	var key := "%s|%f|%f|%f|%f|%f" % [c, rough, metal, emit, coat, rim]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
		m.rim_tint = 0.6
	if coat > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = coat
		m.clearcoat_roughness = 0.1
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m


static func _xf(pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot * (PI / 180.0)) * Basis.from_scale(scl), pos)


func _bake(parent: Node3D, m: MeshKit.Merger, near_only := false, node_name := "") -> MeshInstance3D:
	if m.empty():
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = m.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if node_name != "":
		mi.name = node_name
	parent.add_child(mi)
	if near_only:
		_near.append(mi)
	return mi


## pilot: Catalog pilot dict. h: head radius. detail: false = far face only.
func build(pilot: Dictionary, h: float, detail: bool, lod: float) -> void:
	_rng.seed = hash(pilot.id)
	_h = h
	var lk: Dictionary = pilot.get("look", LOOKS.get(pilot.id, LOOKS.zib))
	_robot = lk.get("robot", false)
	var skin_c: Color = pilot.color
	var skin := _mat(skin_c, 0.12 if lk.get("slime", false) else (0.3 if _robot else 0.55), 0.85 if _robot else 0.0, 0.0,
		1.0 if lk.get("slime", false) or _robot else 0.3, 0.6)
	if float(lk.get("skin_glow", 0.0)) > 0.0:
		skin = _mat(skin_c, 0.15, 0.0, float(lk.skin_glow), 1.0, 0.8)
	var suit := _mat(lk.suit, 0.6, 0.0, 0.0, 0.0, 0.3)
	var trim := _mat(lk.trim, 0.4, 0.2, 0.4)
	var glove := _mat(Color(0.95, 0.95, 0.98), 0.5)
	var dark := _mat(Color(0.05, 0.04, 0.07), 0.3)
	var seg := 16 if detail else 10
	# Body: torso, collar, emblem, control yoke.
	var body := MeshKit.Merger.new()
	if not lk.get("slime", false):
		body.add(MeshKit.blob(Vector3(0.78, 0.62, 0.55) * h, 1.0, 0.8, seg, 10), suit, _xf(Vector3(0, -1.2 * h, 0.05 * h)))
		body.add(_torus(0.32 * h, 0.44 * h), trim, _xf(Vector3(0, -0.66 * h, 0.0), Vector3.ZERO, Vector3(1.0, 0.7, 1.0)))
		body.add(MeshKit.star(0.16 * h, 0.07 * h, 0.05 * h), _mat(lk.trim, 0.3, 0.0, 1.5), _xf(Vector3(0.28 * h, -0.95 * h, -0.5 * h), Vector3(-15, 0, 0)))
	else:
		body.add(MeshKit.blob(Vector3(0.95, 0.75, 0.8) * h, 1.0, 1.0, seg, 10, Vector2(0.8, 0.8), 0.1), skin, _xf(Vector3(0, -1.05 * h, 0)))
	body.add(MeshKit.blob(Vector3(0.55, 0.06, 0.08) * h, 0.5, 0.5, 10, 6), _mat(Color(0.2, 0.2, 0.25), 0.3, 0.8), _xf(Vector3(0, -1.0 * h, -0.95 * h)))
	body.add(MeshKit.blob(Vector3(0.07, 0.07, 0.07) * h, 1.0, 1.0, 8, 6), _mat(Color(1.0, 0.25, 0.2), 0.3, 0.0, 2.0), _xf(Vector3(0.0, -0.92 * h, -0.95 * h)))
	_bake(self, body, false, "Body")
	# Arms on the yoke (animated).
	if not lk.get("slime", false) and detail:
		for sx: float in [-1.0, 1.0]:
			var arm := Node3D.new()
			arm.position = Vector3(sx * 0.62 * h, -0.95 * h, 0.0)
			add_child(arm)
			var am := MeshKit.Merger.new()
			am.add(MeshKit.blob(Vector3(0.17, 0.17, 0.5) * h, 1.0, 1.0, 10, 8), suit, _xf(Vector3(-sx * 0.12 * h, -0.08 * h, -0.42 * h), Vector3(10, sx * 18.0, 0)))
			am.add(MeshKit.blob(Vector3(0.16, 0.14, 0.16) * h, 1.0, 1.0, 10, 6), glove if not _robot else skin, _xf(Vector3(-sx * 0.3 * h, -0.08 * h, -0.9 * h)))
			_bake(arm, am, true)
			_arms.append(arm)
	# Head.
	_head = Node3D.new()
	_head.name = "Head"
	add_child(_head)
	var hm := MeshKit.Merger.new()
	var head_mesh: Mesh
	var lump := float(lk.get("lump", 0.0))
	match String(lk.head):
		"egg":
			head_mesh = MeshKit.blob(Vector3(0.95, 1.0, 0.92) * h, 1.0, 1.0, seg + 4, 14, Vector2(1.22, 1.15), lump)
		"drop":
			head_mesh = MeshKit.blob(Vector3(1.0, 1.0, 0.95) * h, 1.0, 1.0, seg + 4, 14, Vector2(0.72, 0.72), maxf(lump, 0.06))
		"wide":
			head_mesh = MeshKit.blob(Vector3(1.15, 0.92, 0.95) * h, 0.9, 1.0, seg + 4, 14, Vector2(0.95, 1.0), lump)
		"box":
			head_mesh = MeshKit.blob(Vector3(1.0, 0.88, 0.9) * h, 0.3, 0.3, seg + 4, 14)
		"gem":
			# Cut crystal: few facets, flat shaded.
			head_mesh = MeshKit.faceted(MeshKit.blob(Vector3(0.95, 1.05, 0.95) * h, 1.0, 0.85, 9, 7, Vector2(0.8, 0.8)))
		"mantle":
			# Squid mantle: tall and tapering to a point.
			head_mesh = MeshKit.blob(Vector3(0.95, 1.3, 0.95) * h, 1.0, 1.0, seg + 4, 14, Vector2(0.45, 0.45), maxf(lump, 0.03))
		"bell":
			# Jellyfish bell: wide and flat-topped.
			head_mesh = MeshKit.blob(Vector3(1.1, 0.9, 1.1) * h, 0.6, 1.0, seg + 4, 14, Vector2(0.75, 0.75))
		"insect":
			head_mesh = MeshKit.blob(Vector3(0.92, 1.12, 0.95) * h, 1.0, 0.9, seg + 4, 14, Vector2(0.8, 0.85), lump)
		_:
			head_mesh = MeshKit.blob(Vector3.ONE * h, 1.0, 1.0, seg + 4, 14, Vector2.ONE, lump)
	hm.add(head_mesh, skin, Transform3D.IDENTITY)
	var neck := MeshKit.blob(Vector3(0.32, 0.4, 0.32) * h, 1.0, 1.0, 10, 6)
	if not lk.get("slime", false):
		_bake(self, _one(neck, skin if not _robot else _mat(Color(0.3, 0.3, 0.35), 0.4, 0.8), _xf(Vector3(0, -0.75 * h, 0))), false)
	_accessories(lk, hm, skin, h, detail)
	# Eyes.
	var n_eyes: int = pilot.get("eyes", 2)
	var spots := _eye_spots(n_eyes, String(lk.head))
	var er := h * (0.36 if n_eyes == 1 else (0.24 if n_eyes >= 3 else 0.28)) * float(lk.get("eye_scale", 1.0))
	if _robot:
		er = h * 0.34
	var white := _mat(lk.get("sclera", Color(0.98, 0.98, 1.0)), 0.15, 0.0, 0.0, 1.0, 0.0)
	var iris := _mat(lk.iris, 0.25, 0.0, float(lk.get("iris_glow", 0.35 if _robot else 0.15)), 1.0, 0.0)
	var pupil := _mat(Color(0.02, 0.02, 0.04), 0.1, 0.0, 0.0, 1.0, 0.0)
	var shine := _mat(Color(1, 1, 1), 0.2, 0.0, 2.5, 0.0, 0.0)
	var far_face := MeshKit.Merger.new()
	for sp: Vector3 in spots:
		var ep := _on_head(sp, h, String(lk.head))
		var r := er * (1.15 if sp.z > 0.5 else 1.0)
		var eye_static: MeshKit.Merger = hm if detail else MeshKit.Merger.new()
		if _robot:
			eye_static.add(MeshKit.lathe(PackedVector2Array([Vector2(0, 0.2), Vector2(1.0, 0.2), Vector2(1.15, 0.0), Vector2(1.0, -0.3)]), 18, PackedInt32Array([1, 2])),
				_mat(Color(0.2, 0.2, 0.25), 0.3, 0.9), _xf(ep, Vector3(-90, 0, 0), Vector3.ONE * r))
		eye_static.add(MeshKit.blob(Vector3.ONE * r, 1.0, 1.0, 14, 10), white if not _robot else _mat(Color(0.05, 0.08, 0.1), 0.05, 0.0, 0.0, 1.0, 0.0), _xf(ep))
		eye_static.add(MeshKit.blob(Vector3.ONE * r * 0.15, 1.0, 1.0, 8, 6), shine, _xf(ep + Vector3(r * 0.3, r * 0.35, -r * 0.84)))
		eye_static.add(MeshKit.blob(Vector3.ONE * r * 0.08, 1.0, 1.0, 6, 4), shine, _xf(ep + Vector3(-r * 0.25, -r * 0.3, -r * 0.86)))
		# Far version: eyeball + fixed pupil.
		if not detail:
			far_face.add(MeshKit.blob(Vector3.ONE * r, 1.0, 1.0, 10, 6), white, _xf(ep))
		far_face.add(MeshKit.blob(Vector3(0.5, 0.55, 0.25) * r, 1.0, 1.0, 8, 6), pupil, _xf(ep + Vector3(0, 0, -r * 0.9)))
		if not detail:
			continue
		var look := Node3D.new()
		look.position = ep
		_head.add_child(look)
		var lm := MeshKit.Merger.new()
		lm.add(MeshKit.blob(Vector3(0.62, 0.62, 0.22) * r, 1.0, 1.0, 14, 8), iris, _xf(Vector3(0, 0, -r * 0.86)))
		if not _robot:
			lm.add(MeshKit.blob(Vector3(0.32, 0.36, 0.14) * r, 1.0, 1.0, 10, 6), pupil, _xf(Vector3(0, 0, -r * 0.97)))
		else:
			lm.add(MeshKit.blob(Vector3(0.3, 0.3, 0.12) * r, 1.0, 1.0, 10, 6), _mat(Color(0.7, 1.0, 1.0), 0.1, 0.0, 3.0), _xf(Vector3(0, 0, -r * 0.98)))
		_bake(look, lm, true)
		_eyes.append(look)
		var lid := Node3D.new()
		lid.position = ep
		_head.add_child(lid)
		var lidm := MeshKit.Merger.new()
		var hemi := SphereMesh.new()
		hemi.radius = r * 1.16
		hemi.height = r * 1.16
		hemi.is_hemisphere = true
		hemi.radial_segments = 16
		hemi.rings = 6
		lidm.add(hemi, skin if not _robot else _mat(Color(0.35, 0.36, 0.42), 0.3, 0.9), Transform3D.IDENTITY)
		if lk.get("lashes", false):
			for k in 3:
				lidm.add(MeshKit.blob(Vector3(0.05, 0.22, 0.04) * r, 1.0, 1.0, 6, 4), dark,
					_xf(Vector3((float(k) - 1.0) * 0.45 * r, r * 1.05, -r * 0.35), Vector3(-30, 0, (float(k) - 1.0) * -25.0)))
		_bake(lid, lidm, true)
		_lids.append(lid)
	# Angry captain brows.
	if lk.get("brows", false):
		for sp: Vector3 in spots:
			if sp.y < 0.2:
				continue
			var ep := _on_head(sp, h, String(lk.head))
			var side := signf(sp.x) if absf(sp.x) > 0.01 else 1.0
			hm.add(MeshKit.blob(Vector3(0.3, 0.07, 0.08) * h, 0.6, 0.6, 10, 6), dark, _xf(ep + Vector3(0, er * 1.3, -er * 0.35), Vector3(0, 0, side * 18.0)))
	_bake(_head, hm, false, "HeadMesh")
	# Mouths, one per mood shape.
	var my := -0.42 if String(lk.head) != "dog" else -0.62
	var mouth_at := Vector3(0, my * h, -_surface_z(String(lk.head), my) * h - 0.015 * h)
	if String(lk.head) == "dog":
		mouth_at = Vector3(0, -0.5 * h, -1.02 * h)
	var lip := _mat(skin_c.darkened(0.55), 0.4)
	var mouth_dark := _mat(Color(0.18, 0.04, 0.08), 0.5)
	var teeth := _mat(Color(1, 1, 1), 0.3)
	var tongue := _mat(Color(1.0, 0.4, 0.5), 0.4)
	var mw := h * (0.3 if n_eyes != 4 else 0.38)
	if _robot:
		lip = _mat(lk.iris, 0.2, 0.0, 2.5)
		mouth_dark = lip
	if detail:
		for kind in 4:
			var node := Node3D.new()
			node.position = mouth_at
			_head.add_child(node)
			var mm := MeshKit.Merger.new()
			match kind:
				M.SMILE:
					mm.add(MeshKit.arc(mw, h * 0.045, 205.0, 335.0), lip, _xf(Vector3(0, mw * 0.55, 0)))
				M.GRIN:
					mm.add(MeshKit.blob(Vector3(mw * 1.0, mw * 0.55, h * 0.1), 1.0, 1.0, 14, 8, Vector2(1.0, 1.0), 0.0), mouth_dark, _xf(Vector3(0, -mw * 0.1, 0.06 * h)))
					if not _robot:
						mm.add(MeshKit.blob(Vector3(mw * 0.78, mw * 0.13, h * 0.05), 0.5, 0.6, 10, 6), teeth, _xf(Vector3(0, mw * 0.25, -0.01 * h)))
						mm.add(MeshKit.blob(Vector3(mw * 0.5, mw * 0.22, h * 0.05), 1.0, 1.0, 10, 6), tongue, _xf(Vector3(0, -mw * 0.38, 0.0)))
				M.OH:
					mm.add(MeshKit.blob(Vector3(mw * 0.42, mw * 0.5, h * 0.08), 1.0, 1.0, 12, 8), mouth_dark, _xf(Vector3(0, -mw * 0.1, 0.04 * h)))
				M.FROWN:
					mm.add(MeshKit.arc(mw * 0.8, h * 0.045, 25.0, 155.0), lip, _xf(Vector3(0, -mw * 0.75, 0)))
			_bake(node, mm, true)
			node.visible = kind == M.SMILE
			_mouths.append(node)
	far_face.add(MeshKit.arc(mw, h * 0.06, 205.0, 335.0, 8, 4), lip, _xf(mouth_at + Vector3(0, mw * 0.55, 0)))
	if lk.get("fangs", false):
		var fangs := MeshKit.Merger.new()
		for sx: float in [-1.0, 1.0]:
			fangs.add(MeshKit.blob(Vector3(0.05, 0.11, 0.05) * h, 1.0, 1.0, 8, 6, Vector2(0.12, 0.12)), teeth,
				_xf(mouth_at + Vector3(sx * mw * 0.55, -mw * 0.12, -0.03 * h), Vector3(0, 0, 180)))
		_bake(_head, fangs, false, "Fangs")
	_far = _bake(_head, far_face, false, "FarFace")
	# Dizzy stars.
	if detail:
		_stars = Node3D.new()
		_stars.position = Vector3(0, h * 1.25, 0)
		_head.add_child(_stars)
		var sm := MeshKit.Merger.new()
		for k in 3:
			var a := TAU * float(k) / 3.0
			sm.add(MeshKit.star(h * 0.2, h * 0.09, h * 0.07), _mat(Color(1.0, 0.9, 0.3), 0.3, 0.0, 2.0), _xf(Vector3(cos(a), 0, sin(a)) * h * 0.75))
		_bake(_stars, sm, true)
		_stars.visible = false
	# Distance swap between the detailed face and the baked far face.
	if detail:
		for g in _near:
			g.visibility_range_end = lod
			g.visibility_range_end_margin = 4.0
		_far.visibility_range_begin = lod
		_far.visibility_range_begin_margin = 4.0
	_next_blink = _rng.randf_range(1.0, 4.0)


## How far the face surface sits in front of the head centre at height y
## (both in head radii), matching the head blob of each shape.
static func _surface_z(head: String, y: float) -> float:
	var sz := 1.0
	var sy := 1.0
	var tz := 1.0
	match head:
		"egg":
			sz = 0.92
			tz = 1.15
		"drop":
			sz = 0.95
			tz = 0.72
		"wide":
			sz = 0.95
			sy = 0.92
		"box":
			return 0.9
		"gem":
			sz = 0.9
			sy = 1.05
			tz = 0.8
		"mantle":
			sz = 0.95
			sy = 1.3
			tz = 0.45
		"bell":
			sz = 1.08
			sy = 0.9
			tz = 0.75
		"insect":
			sz = 0.95
			sy = 1.12
			tz = 0.85
	var k := clampf(y / sy, -1.0, 1.0)
	return sz * sqrt(1.0 - k * k) * lerpf(1.0, tz, (k + 1.0) * 0.5)


static func _align_y(n: Vector3) -> Basis:
	var x := n.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = n.cross(Vector3.RIGHT)
	x = x.normalized()
	return Basis(x, n, x.cross(n).normalized())


static func _torus(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 20
	t.ring_segments = 8
	return t


static func _one(mesh: Mesh, mat: Material, xf: Transform3D) -> MeshKit.Merger:
	var m := MeshKit.Merger.new()
	m.add(mesh, mat, xf)
	return m


## Eye placements on the face: x across, y up, z = 1 for the big centre eye.
static func _eye_spots(n: int, head: String) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var yb := 0.12 if head != "dog" else 0.18
	match n:
		1:
			out.append(Vector3(0, yb + 0.05, 1))
		3:
			out.append(Vector3(-0.48, yb, 0))
			out.append(Vector3(0.0, yb + 0.32, 0))
			out.append(Vector3(0.48, yb, 0))
		4:
			out.append(Vector3(-0.5, yb + 0.25, 0))
			out.append(Vector3(0.5, yb + 0.25, 0))
			out.append(Vector3(-0.3, yb - 0.12, 0))
			out.append(Vector3(0.3, yb - 0.12, 0))
		_:
			out.append(Vector3(-0.38, yb, 0))
			out.append(Vector3(0.38, yb, 0))
	return out


## A point on the front of the head for face position (x, y in head radii).
static func _on_head(sp: Vector3, h: float, head: String) -> Vector3:
	var sx := 1.0 if head != "wide" else 1.15
	var x := sp.x * h * sx * 0.92
	var y := sp.y * h
	var rr := h * (0.95 if head != "box" else 1.1)
	var z2 := rr * rr - (x / sx) * (x / sx) - y * y
	var z := sqrt(maxf(z2, 0.02 * h * h)) * float(EYE_DEPTH.get(head, 0.82))
	if head == "box":
		z = h * 0.84
	return Vector3(x, y, -z)


func _accessories(lk: Dictionary, hm: MeshKit.Merger, skin: Material, h: float, detail: bool) -> void:
	var trim := _mat(lk.trim, 0.35, 0.3, 0.3)
	var metal := _mat(Color(0.75, 0.76, 0.8), 0.2, 0.9, 0.0, 1.0)
	var gold := _mat(Color(1.0, 0.78, 0.3), 0.25, 0.9, 0.0, 1.0)
	match String(lk.acc):
		"antennae":
			for sx: float in [-1.0, 1.0]:
				var ant := Node3D.new()
				ant.position = Vector3(sx * 0.42 * h, 0.82 * h, 0)
				ant.rotation_degrees = Vector3(0, 0, -sx * 18.0)
				_head.add_child(ant)
				var am := MeshKit.Merger.new()
				am.add(MeshKit.blob(Vector3(0.05, 0.36, 0.05) * h, 1.0, 1.0, 6, 6, Vector2(0.6, 0.6)), skin, _xf(Vector3(0, 0.32 * h, 0)))
				am.add(MeshKit.blob(Vector3.ONE * 0.13 * h, 1.0, 1.0, 10, 6), _mat(lk.trim, 0.3, 0.0, 2.2), _xf(Vector3(0, 0.72 * h, 0)))
				_bake(ant, am, false)
				_antennae.append(ant)
		"goggles":
			for sx: float in [-1.0, 1.0]:
				hm.add(_torus(0.15 * h, 0.24 * h), metal, _xf(Vector3(sx * 0.3 * h, 0.66 * h, -0.62 * h), Vector3(70, 0, 0)))
				hm.add(MeshKit.blob(Vector3(0.17, 0.17, 0.05) * h, 1.0, 1.0, 12, 6), _mat(Color(0.4, 0.9, 1.0, 1.0), 0.05, 0.3, 0.6, 1.0), _xf(Vector3(sx * 0.3 * h, 0.67 * h, -0.62 * h), Vector3(-20, 0, 0)))
			hm.add(_torus(0.96 * h, 1.03 * h), _mat(Color(0.15, 0.15, 0.2), 0.5), _xf(Vector3(0, 0.55 * h, 0.0), Vector3(-18, 0, 0)))
			# Swept crest of hair.
			hm.add(MeshKit.blob(Vector3(0.22, 0.45, 0.55) * h, 1.0, 1.0, 12, 8, Vector2(0.4, 0.6), 0.0, Vector2(0.0, 1.2)), trim, _xf(Vector3(0, 0.78 * h, 0.15 * h), Vector3(-25, 0, 0)))
		"bubbles":
			var bub := _mat(lk.suit.lightened(0.3), 0.08, 0.0, 0.2, 1.0)
			for k in 5:
				var a := TAU * float(k) / 5.0 + 0.4
				var p := Vector3(cos(a) * 0.75, 0.45 + 0.2 * sin(a * 2.0), sin(a) * 0.75) * h
				hm.add(MeshKit.blob(Vector3.ONE * h * (0.1 + 0.04 * float(k % 3)), 1.0, 1.0, 8, 6), bub, _xf(p))
			hm.add(MeshKit.blob(Vector3(0.12, 0.2, 0.12) * h, 1.0, 1.0, 8, 6, Vector2(0.4, 0.4)), skin, _xf(Vector3(0.85 * h, -0.45 * h, -0.2 * h), Vector3(0, 0, 180)))
		"captain":
			var cap := _mat(Color(0.15, 0.16, 0.25), 0.45)
			hm.add(MeshKit.lathe(PackedVector2Array([Vector2(0, 0.5), Vector2(0.75, 0.48), Vector2(0.95, 0.3), Vector2(0.9, 0.0), Vector2(0, 0.0)]), 20, PackedInt32Array([2, 3])),
				cap, _xf(Vector3(0, 0.62 * h, 0), Vector3(-8, 0, 0), Vector3.ONE * h))
			hm.add(MeshKit.blob(Vector3(0.75, 0.04, 0.42) * h, 0.4, 1.0, 14, 6), _mat(Color(0.05, 0.05, 0.08), 0.3), _xf(Vector3(0, 0.62 * h, -0.75 * h), Vector3(12, 0, 0)))
			hm.add(MeshKit.star(0.16 * h, 0.07 * h, 0.05 * h), gold, _xf(Vector3(0, 0.88 * h, -0.86 * h), Vector3(-15, 0, 0)))
			hm.add(_torus(0.88 * h, 0.95 * h), gold, _xf(Vector3(0, 0.66 * h, 0), Vector3(-8, 0, 0)))
			# Tusks.
			for sx: float in [-1.0, 1.0]:
				hm.add(MeshKit.blob(Vector3(0.06, 0.2, 0.06) * h, 1.0, 1.0, 8, 6, Vector2(0.2, 0.2)), _mat(Color(1.0, 0.97, 0.88), 0.3),
					_xf(Vector3(sx * 0.4 * h, -0.62 * h, -0.62 * h), Vector3(-10, 0, sx * -12.0)))
		"crest":
			for k in 3:
				var a := (float(k) - 1.0) * 28.0
				hm.add(MeshKit.blob(Vector3(0.1, 0.42, 0.18) * h, 1.0, 1.0, 10, 8, Vector2(0.3, 0.6)), trim,
					_xf(Vector3((float(k) - 1.0) * 0.28 * h, 0.95 * h, 0.1 * h), Vector3(-15, 0, -a)))
			for sx: float in [-1.0, 1.0]:
				hm.add(MeshKit.star(0.13 * h, 0.06 * h, 0.05 * h), gold, _xf(Vector3(sx * 0.98 * h, -0.35 * h, 0), Vector3(0, sx * 90.0, 0)))
		"robot":
			hm.add(MeshKit.blob(Vector3(0.04, 0.4, 0.04) * h, 1.0, 1.0, 6, 4), metal, _xf(Vector3(0.3 * h, 1.1 * h, 0)))
			for sx: float in [-1.0, 1.0]:
				hm.add(MeshKit.lathe(PackedVector2Array([Vector2(0, 0.15), Vector2(0.22, 0.15), Vector2(0.25, -0.15), Vector2(0, -0.15)]), 12, PackedInt32Array([1, 2])),
					metal, _xf(Vector3(sx * 1.0 * h, 0, 0), Vector3(0, 0, 90), Vector3.ONE * h))
			for k in 4:
				hm.add(MeshKit.blob(Vector3(0.05, 0.05, 0.03) * h, 0.4, 0.4, 6, 4), _mat(Color(0.2, 0.2, 0.25), 0.4, 0.8),
					_xf(Vector3((float(k) - 1.5) * 0.45 * h, 0.72 * h, -0.8 * h)))
			var tip := Node3D.new()
			tip.position = Vector3(0.3 * h, 1.55 * h, 0)
			_head.add_child(tip)
			_bake(tip, _one(MeshKit.blob(Vector3.ONE * 0.12 * h, 1.0, 1.0, 10, 6), _mat(Color(1.0, 0.2, 0.15), 0.3, 0.0, 3.0), Transform3D.IDENTITY), false)
			_antennae.append(tip)
		"scarf":
			hm.add(MeshKit.lathe(PackedVector2Array([Vector2(0.7, 0.2), Vector2(0.8, 0.1), Vector2(0.8, -0.08), Vector2(0.7, -0.16)]), 22, PackedInt32Array()),
				trim, _xf(Vector3(0, 0.74 * h, 0.12 * h), Vector3(-22, 0, 0), Vector3.ONE * h))
			hm.add(MeshKit.blob(Vector3.ONE * 0.34 * h, 1.0, 1.0, 14, 8), skin, _xf(Vector3(0, 1.08 * h, 0.3 * h)))
			hm.add(_torus(0.32 * h, 0.4 * h), trim, _xf(Vector3(0, 0.98 * h, 0.28 * h), Vector3(-15, 0, 0)))
			for sx: float in [-1.0, 1.0]:
				hm.add(_torus(0.12 * h, 0.16 * h), gold, _xf(Vector3(sx * 0.98 * h, -0.42 * h, 0), Vector3(0, 0, 90)))
		"ears":
			# Snout, nose, floppy ears, collar tag.
			hm.add(MeshKit.blob(Vector3(0.48, 0.36, 0.42) * h, 1.0, 1.0, 14, 8), _mat(Color(lk.trim).lerp(Color(0.95, 0.85, 0.7), 0.85), 0.55),
				_xf(Vector3(0, -0.32 * h, -0.72 * h)))
			hm.add(MeshKit.blob(Vector3(0.17, 0.12, 0.12) * h, 1.0, 1.0, 10, 6), _mat(Color(0.05, 0.04, 0.05), 0.15, 0.0, 0.0, 1.0),
				_xf(Vector3(0, -0.16 * h, -1.1 * h)))
			for sx: float in [-1.0, 1.0]:
				var ear := Node3D.new()
				ear.position = Vector3(sx * 0.82 * h, 0.55 * h, 0.05 * h)
				_head.add_child(ear)
				_bake(ear, _one(MeshKit.blob(Vector3(0.2, 0.55, 0.32) * h, 1.0, 1.0, 10, 8, Vector2(0.7, 0.7)), _mat(Color(0.45, 0.28, 0.18), 0.6),
					_xf(Vector3(sx * 0.12 * h, -0.4 * h, 0), Vector3(0, 0, sx * 20.0))), false)
				_antennae.append(ear)
		"horns":
			var horn := _mat(Color(0.2, 0.09, 0.07), 0.35, 0.1, 0.0, 0.6)
			var ember := _mat(Color(1.0, 0.5, 0.1), 0.3, 0.0, 3.0)
			for sx: float in [-1.0, 1.0]:
				var b0 := Vector3(sx * 0.45 * h, 0.72 * h, 0.0)
				hm.add(MeshKit.blob(Vector3(0.14, 0.24, 0.14) * h, 1.0, 1.0, 10, 6, Vector2(0.6, 0.6)), horn,
					_xf(b0 + Vector3(sx * 0.06 * h, 0.16 * h, 0), Vector3(0, 0, -sx * 28.0)))
				hm.add(MeshKit.blob(Vector3(0.09, 0.22, 0.09) * h, 1.0, 1.0, 8, 6, Vector2(0.15, 0.15)), horn,
					_xf(b0 + Vector3(sx * 0.24 * h, 0.44 * h, 0.06 * h), Vector3(-15, 0, -sx * 58.0)))
				# Pointed bat ears.
				hm.add(MeshKit.blob(Vector3(0.07, 0.34, 0.2) * h, 1.0, 1.0, 8, 6, Vector2(0.1, 0.35)), skin,
					_xf(Vector3(sx * 0.93 * h, 0.12 * h, 0.08 * h), Vector3(0, 0, -sx * 62.0)))
			# Ember tongues flicker on the crown.
			var fl := Node3D.new()
			fl.position = Vector3(0, 0.9 * h, 0.12 * h)
			_head.add_child(fl)
			var flm := MeshKit.Merger.new()
			for k in 3:
				var off := absf(float(k) - 1.0)
				flm.add(MeshKit.blob(Vector3(0.07, 0.18 - 0.05 * off, 0.07) * h, 1.0, 1.0, 8, 6, Vector2(0.1, 0.1)), ember,
					_xf(Vector3((float(k) - 1.0) * 0.16 * h, (0.1 - 0.04 * off) * h, 0)))
			_bake(fl, flm, false)
			_antennae.append(fl)
		"moth":
			var fuzz := _mat(Color(lk.trim), 0.95, 0.0, 0.0, 0.0, 0.8)
			# Fluffy ruff around the neck.
			for k in 10:
				var a := TAU * float(k) / 10.0
				hm.add(MeshKit.blob(Vector3.ONE * 0.24 * h, 1.0, 1.0, 8, 6, Vector2.ONE, 0.15), fuzz,
					_xf(Vector3(cos(a) * 0.62 * h, -0.72 * h, sin(a) * 0.55 * h)))
			# Feathery antennae (they sway).
			for sx: float in [-1.0, 1.0]:
				var ant := Node3D.new()
				ant.position = Vector3(sx * 0.3 * h, 0.82 * h, -0.2 * h)
				ant.rotation_degrees = Vector3(-18, 0, -sx * 25.0)
				_head.add_child(ant)
				var am := MeshKit.Merger.new()
				am.add(MeshKit.blob(Vector3(0.035, 0.5, 0.035) * h, 1.0, 1.0, 6, 6), _mat(Color(0.35, 0.3, 0.25), 0.6), _xf(Vector3(0, 0.5 * h, 0)))
				for j in 6:
					var y := (0.3 + 0.12 * float(j)) * h
					var l := (0.2 - 0.022 * float(j)) * h
					for side: float in [-1.0, 1.0]:
						am.add(MeshKit.blob(Vector3(l, 0.03 * h, 0.05 * h), 1.0, 1.0, 6, 4), fuzz,
							_xf(Vector3(side * l * 0.9, y + l * 0.3, 0), Vector3(0, 0, side * 30.0)))
				_bake(ant, am, false)
				_antennae.append(ant)
			# Dusty wings folded behind the head, with blue eye spots.
			var wc: Color = (skin as StandardMaterial3D).albedo_color
			var wing := _mat(wc.darkened(0.12), 0.85, 0.0, 0.0, 0.0, 0.7)
			var spot := _mat(Color(0.35, 0.55, 0.95), 0.4, 0.0, 0.8)
			for sx: float in [-1.0, 1.0]:
				var p := Vector3(sx * 0.95 * h, 0.2 * h, 0.75 * h)
				hm.add(MeshKit.blob(Vector3(0.75, 0.55, 0.06) * h, 1.0, 1.0, 14, 8, Vector2(1.2, 1.0)), wing, _xf(p, Vector3(0, sx * 35.0, sx * -20.0)))
				hm.add(MeshKit.blob(Vector3(0.2, 0.2, 0.03) * h, 1.0, 1.0, 10, 6), spot,
					_xf(p + Vector3(sx * 0.12 * h, 0.08 * h, -0.08 * h), Vector3(0, sx * 35.0, sx * -20.0)))
		"crystals":
			var cry := _mat(Color(lk.trim), 0.1, 0.2, 1.2, 1.0)
			for k in 5:
				var a := (float(k) - 2.0) * 22.0
				var ln := (0.55 - 0.1 * absf(float(k) - 2.0)) * h
				hm.add(MeshKit.faceted(MeshKit.blob(Vector3(0.1 * h, ln, 0.1 * h), 1.0, 0.6, 6, 4, Vector2(0.05, 0.05))), cry,
					_xf(Vector3(sin(deg_to_rad(a)) * 0.6 * h, 0.72 * h + ln * 0.6, 0.15 * h), Vector3(-10, 0, -a)))
			# A shard floats beside the head (it bobs with the antennae).
			var orb := Node3D.new()
			orb.position = Vector3(0.98 * h, 0.55 * h, -0.2 * h)
			_head.add_child(orb)
			_bake(orb, _one(MeshKit.faceted(MeshKit.blob(Vector3.ONE * 0.13 * h, 1.0, 0.6, 6, 4)), cry, Transform3D.IDENTITY), false)
			_antennae.append(orb)
			hm.add(_torus(0.62 * h, 0.78 * h), _mat(Color(lk.suit), 0.6), _xf(Vector3(0, -0.66 * h, 0.05 * h), Vector3.ZERO, Vector3(1.0, 1.4, 1.0)))
		"tentacles":
			var sc: Color = (skin as StandardMaterial3D).albedo_color
			var band := _mat(sc.darkened(0.3), 0.25, 0.0, 0.0, 0.8)
			for k in 6:
				var ar := deg_to_rad(lerpf(-70.0, 70.0, float(k) / 5.0))
				var t := Node3D.new()
				t.position = Vector3(sin(ar) * 0.5 * h, -0.55 * h, -cos(ar) * 0.5 * h + 0.1 * h)
				_head.add_child(t)
				var tm := MeshKit.Merger.new()
				var p := Vector3.ZERO
				var r := 0.11 * h
				for j in 4:
					tm.add(MeshKit.blob(Vector3(r, 0.15 * h, r), 1.0, 1.0, 8, 6), band if j % 2 == 1 else skin, _xf(p + Vector3(0, -0.11 * h, 0)))
					p += Vector3(sin(ar) * 0.04 * h, -0.19 * h, -0.04 * h * float(j))
					r *= 0.8
				tm.add(MeshKit.blob(Vector3.ONE * r * 1.1, 1.0, 1.0, 8, 6), skin, _xf(p + Vector3(0, -0.05 * h, -0.05 * h)))
				_bake(t, tm, false)
				_antennae.append(t)
		"jelly":
			var core := _mat(Color(lk.trim), 0.2, 0.0, 2.2)
			hm.add(MeshKit.blob(Vector3.ONE * 0.32 * h, 1.0, 1.0, 10, 8, Vector2.ONE, 0.2), core, _xf(Vector3(0, 0.42 * h, 0.25 * h)))
			var jc: Color = (skin as StandardMaterial3D).albedo_color
			var frill := _mat(jc.lightened(0.25), 0.2, 0.0, 0.9, 0.8)
			for k in 14:
				var a := TAU * float(k) / 14.0
				hm.add(MeshKit.blob(Vector3(0.18, 0.09, 0.12) * h, 1.0, 1.0, 8, 4), frill,
					_xf(Vector3(cos(a) * 1.0 * h, -0.5 * h, sin(a) * 1.0 * h), Vector3(0, -rad_to_deg(a), 0)))
			# Trailing tendrils (they sway).
			for k in 5:
				var a := TAU * (float(k) + 0.5) / 5.0
				var t := Node3D.new()
				t.position = Vector3(cos(a) * 0.7 * h, -0.55 * h, sin(a) * 0.7 * h)
				_head.add_child(t)
				_bake(t, _one(MeshKit.blob(Vector3(0.05, 0.55, 0.05) * h, 1.0, 1.0, 6, 6, Vector2(0.3, 0.3)), frill, _xf(Vector3(0, -0.5 * h, 0))), false)
				_antennae.append(t)
		"hood":
			var cloth := _mat(Color(lk.suit), 0.9, 0.0, 0.0, 0.0, 0.4)
			# A deep hood over and behind the head, open at the face.
			hm.add(MeshKit.blob(Vector3(1.22, 1.25, 1.2) * h, 1.0, 1.0, 16, 10, Vector2(0.55, 0.75)), cloth, _xf(Vector3(0, 0.14 * h, 0.5 * h), Vector3(-12, 0, 0)))
			hm.add(MeshKit.arc(1.0 * h, 0.12 * h, 25.0, 155.0, 14, 6), cloth, _xf(Vector3(0, -0.02 * h, -0.55 * h)))
			# Ghost wisps stream behind.
			var wisp := _mat(Color(lk.trim), 0.2, 0.0, 1.6)
			for k in 3:
				var t := Node3D.new()
				t.position = Vector3((float(k) - 1.0) * 0.45 * h, -0.1 * h * float(k), 1.35 * h)
				_head.add_child(t)
				_bake(t, _one(MeshKit.blob(Vector3(0.12, 0.12, 0.45) * h, 1.0, 1.0, 8, 6, Vector2(0.3, 0.3)), wisp, _xf(Vector3(0, 0, 0.35 * h), Vector3(90, 0, 0))), false)
				_antennae.append(t)
		"troll":
			var tc: Color = (skin as StandardMaterial3D).albedo_color
			var wart := _mat(tc.darkened(0.35), 0.85)
			hm.add(MeshKit.blob(Vector3(0.22, 0.3, 0.24) * h, 1.0, 1.0, 12, 8, Vector2(0.8, 0.8), 0.1), skin, _xf(Vector3(0, -0.12 * h, -1.0 * h), Vector3(-15, 0, 0)))
			for k in 6:
				var a := float(k) * 1.9 + 0.3
				var wp := _on_head(Vector3(cos(a) * 0.75, 0.15 + sin(a) * 0.45, 0), h, "wide") * Vector3(1.0, 1.0, 1.12)
				hm.add(MeshKit.blob(Vector3.ONE * (0.05 + 0.02 * float(k % 3)) * h, 1.0, 1.0, 6, 4), wart, _xf(wp))
			for sx: float in [-1.0, 1.0]:
				hm.add(MeshKit.blob(Vector3(0.07, 0.2, 0.07) * h, 1.0, 1.0, 8, 6, Vector2(0.2, 0.2)), _mat(Color(0.95, 0.9, 0.72), 0.4),
					_xf(Vector3(sx * 0.34 * h, -0.5 * h, -0.86 * h), Vector3(-15, 0, sx * 10.0)))
			var moss := _mat(Color(0.3, 0.55, 0.18), 1.0)
			for k in 5:
				var a := TAU * float(k) / 5.0
				hm.add(MeshKit.blob(Vector3(0.22, 0.12, 0.22) * h, 1.0, 1.0, 8, 5, Vector2.ONE, 0.3), moss,
					_xf(Vector3(cos(a) * 0.45 * h, 0.8 * h, sin(a) * 0.4 * h + 0.1 * h)))
			# A little red toadstool on the crown.
			hm.add(MeshKit.blob(Vector3(0.06, 0.14, 0.06) * h, 1.0, 1.0, 8, 4), _mat(Color(0.95, 0.92, 0.85), 0.6), _xf(Vector3(0.3 * h, 0.98 * h, 0.15 * h)))
			hm.add(MeshKit.blob(Vector3(0.2, 0.1, 0.2) * h, 1.0, 1.0, 12, 6, Vector2(0.5, 0.5)), _mat(Color(0.85, 0.12, 0.1), 0.5), _xf(Vector3(0.3 * h, 1.12 * h, 0.15 * h)))
		"hive":
			var chitin := _mat(Color(lk.suit).lightened(0.15), 0.25, 0.3, 0.0, 1.0)
			# Brain dome: a thousand minds in one helmet.
			hm.add(MeshKit.blob(Vector3(0.62, 0.42, 0.6) * h, 1.0, 1.0, 12, 8, Vector2.ONE, 0.28), _mat(Color(1.0, 0.55, 0.65), 0.4, 0.0, 0.5), _xf(Vector3(0, 0.88 * h, 0.12 * h)))
			hm.add(_torus(0.62 * h, 0.7 * h), _mat(Color(lk.trim), 0.3, 0.7), _xf(Vector3(0, 0.74 * h, 0.12 * h)))
			for sx: float in [-1.0, 1.0]:
				# Mandibles beside the mouth.
				hm.add(MeshKit.arc(0.2 * h, 0.05 * h, 200.0, 290.0, 8, 6), chitin, _xf(Vector3(sx * 0.3 * h, -0.42 * h, -0.86 * h), Vector3(0, 0, 0.0 if sx < 0.0 else 180.0)))
				# Segmented antennae (they sway).
				var ant := Node3D.new()
				ant.position = Vector3(sx * 0.32 * h, 0.7 * h, -0.45 * h)
				ant.rotation_degrees = Vector3(-30, 0, -sx * 20.0)
				_head.add_child(ant)
				var am := MeshKit.Merger.new()
				for j in 5:
					am.add(MeshKit.blob(Vector3.ONE * (0.07 - 0.008 * float(j)) * h, 1.0, 1.0, 6, 4), chitin, _xf(Vector3(0, (0.1 + 0.13 * float(j)) * h, -0.03 * h * float(j))))
				_bake(ant, am, false)
				_antennae.append(ant)
			# Ridged plates down the cheeks.
			for sx: float in [-1.0, 1.0]:
				hm.add(MeshKit.blob(Vector3(0.1, 0.45, 0.3) * h, 1.0, 1.0, 8, 6), chitin, _xf(Vector3(sx * 0.86 * h, 0.0, 0.0), Vector3(0, 0, sx * 10.0)))
	if lk.get("spots", false):
		var spot := _mat(lk.get("spot_color", Color(lk.iris).lerp(Color(0.1, 0.4, 0.1), 0.4)), 0.6, 0.0, float(lk.get("spot_glow", 0.0)))
		for k in 4:
			var a := float(k) * 1.4 + 0.5
			var p := Vector3(cos(a) * 0.55, 0.7, sin(a) * 0.55 + 0.1).normalized() * h * 1.08
			hm.add(MeshKit.blob(Vector3(0.12, 0.04, 0.12) * h, 1.0, 1.0, 8, 4), spot, Transform3D(_align_y(p.normalized()), p))
	if lk.get("blush", false) and detail:
		var blush := _mat(Color(1.0, 0.45, 0.55), 0.7)
		for sx: float in [-1.0, 1.0]:
			hm.add(MeshKit.blob(Vector3(0.16, 0.09, 0.05) * h, 1.0, 1.0, 10, 6), blush, _xf(_on_head(Vector3(sx * 0.62, -0.22, 0), h, String(lk.head)) + Vector3(0, 0, 0.02 * h)))


## Per-frame animation. steer: -1..1, speed: 0..1.5.
func animate(dt: float, p_mood: int, steer: float, speed: float) -> void:
	_t += dt
	if p_mood != mood:
		mood = p_mood
		for k in _mouths.size():
			_mouths[k].visible = k == _mouth_for(mood)
		if _stars:
			_stars.visible = mood == Mood.DIZZY
	# Blinking.
	_next_blink -= dt
	if _next_blink <= 0.0:
		_blink = 0.16
		_next_blink = _rng.randf_range(1.8, 4.5)
	_blink = maxf(0.0, _blink - dt)
	var open := _lid_open()
	if _blink > 0.0:
		open = -95.0
	for lid in _lids:
		lid.rotation_degrees.x = lerpf(lid.rotation_degrees.x, open, 1.0 - exp(-30.0 * dt))
	# Eyes: look where you steer, with the odd glance around.
	_glance_t -= dt
	if _glance_t <= 0.0:
		_glance_t = _rng.randf_range(1.2, 3.5)
		_glance = Vector2(_rng.randf_range(-0.5, 0.5), _rng.randf_range(-0.25, 0.3)) if _rng.randf() < 0.6 else Vector2.ZERO
	var want := Vector2(-steer * 0.7, 0.0) + _glance * 0.6
	if mood == Mood.DIZZY:
		want = Vector2(cos(_t * 9.0), sin(_t * 9.0)) * 0.55
	elif mood == Mood.FOCUS:
		want = Vector2(-steer * 0.9, -0.1)
	_look = _look.lerp(want, 1.0 - exp(-12.0 * dt))
	for k in _eyes.size():
		var e := _eyes[k]
		var flip := -1.0 if (mood == Mood.DIZZY and k % 2 == 1) else 1.0
		e.rotation = Vector3(_look.y * 0.6, _look.x * 0.7 * flip, 0.0)
	# Head: lean into turns, bob with speed, celebrate.
	if _head:
		var bob := sin(_t * (6.0 + speed * 6.0)) * 0.015 * _h * (1.0 + speed)
		var tilt := -steer * 0.22
		var nod := 0.0
		match mood:
			Mood.CHEER:
				bob = absf(sin(_t * 9.0)) * 0.18 * _h
				tilt = sin(_t * 4.5) * 0.18
			Mood.DIZZY:
				tilt = sin(_t * 5.0) * 0.25
				nod = cos(_t * 5.0) * 0.12
			Mood.SAD:
				nod = 0.22
			Mood.SHOCK:
				bob = 0.08 * _h
		_head.position.y = lerpf(_head.position.y, bob, 1.0 - exp(-14.0 * dt))
		_head.rotation = _head.rotation.lerp(Vector3(nod, -steer * 0.25, tilt), 1.0 - exp(-8.0 * dt))
	if _stars and _stars.visible:
		_stars.rotate_y(dt * 5.0)
	for k in _antennae.size():
		_antennae[k].rotation.x = sin(_t * 7.0 + float(k)) * 0.12 * (0.3 + speed) - speed * 0.25
	# Arms: on the yoke, or up in the air to cheer.
	for k in _arms.size():
		var arm := _arms[k]
		var sx := -1.0 if k == 0 else 1.0
		var target := Vector3(steer * sx * 0.25, 0.0, 0.0)
		if mood == Mood.CHEER:
			target = Vector3(2.2 + sin(_t * 9.0 + float(k)) * 0.25, 0.0, sx * -0.5)
		elif mood == Mood.SHOCK:
			target = Vector3(0.6, 0.0, sx * -0.3)
		arm.rotation = arm.rotation.lerp(target, 1.0 - exp(-10.0 * dt))


func _lid_open() -> float:
	match mood:
		Mood.FOCUS:
			return 24.0
		Mood.GRIN:
			return 62.0
		Mood.SHOCK:
			return 85.0
		Mood.SAD:
			return 12.0
		Mood.CHEER:
			return -88.0
		Mood.DIZZY:
			return 50.0
	return 55.0


static func _mouth_for(m: int) -> int:
	match m:
		Mood.GRIN, Mood.CHEER:
			return M.GRIN
		Mood.DIZZY, Mood.SHOCK:
			return M.OH
		Mood.SAD:
			return M.FROWN
	return M.SMILE
