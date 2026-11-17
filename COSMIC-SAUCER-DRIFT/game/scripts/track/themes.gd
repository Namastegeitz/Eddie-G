class_name Themes
extends RefCounted
## Look of each world: sky, sun(s) drawn in the sky, light, neon colour, fog,
## backdrop planets and which scenery set to build. Suns are given as the
## direction you look to see them; the first one also lights the scene.

const DATA := {
	"mars": {
		"sky_top": Color(0.32, 0.2, 0.14), "sky_bottom": Color(0.78, 0.52, 0.34),
		"neb_a": Color(0.9, 0.6, 0.4), "neb_b": Color(0.6, 0.35, 0.25), "neb": 0.15, "stars": 0.997,
		"neon": Color(1.0, 0.55, 0.2), "barrier": Color(0.3, 0.18, 0.13),
		"sun": Color(1.0, 0.9, 0.8), "ambient": Color(0.6, 0.42, 0.32), "fog": Color(0.7, 0.45, 0.3),
		"suns": [{"dir": Vector3(0.4, 0.55, -0.7), "color": Color(1.0, 0.95, 0.85), "size": 0.9}],
		"ground": "red", "decor": "canyon", "extras": ["comet", "signs"],
		"planets": [{"pos": Vector3(-900, 700, -1400), "r": 60.0, "a": Color(0.5, 0.45, 0.4), "b": Color(0.35, 0.3, 0.28), "rim": Color(0.9, 0.7, 0.5),
				"moons": [{"r": 9.0, "dist": 2.6, "speed": 0.12, "tilt": 0.3}]},
			{"pos": Vector3(1200, 500, -1900), "r": 30.0, "a": Color(0.6, 0.55, 0.5), "b": Color(0.45, 0.4, 0.38), "rim": Color(0.9, 0.7, 0.5)}],
	},
	"ceres": {
		"sky_top": Color(0.03, 0.02, 0.09), "sky_bottom": Color(0.10, 0.04, 0.16),
		"neb_a": Color(0.55, 0.18, 0.75), "neb_b": Color(0.15, 0.35, 0.9), "neb": 0.6, "stars": 0.985,
		"neon": Color(0.3, 0.9, 1.0), "barrier": Color(0.16, 0.17, 0.25),
		"sun": Color(1.0, 0.95, 0.88), "ambient": Color(0.35, 0.32, 0.5), "fog": Color(0.08, 0.04, 0.15),
		"suns": [{"dir": Vector3(0.4, 0.75, 0.5), "color": Color(1.0, 0.97, 0.88), "size": 0.6}],
		"ground": "", "decor": "asteroids", "extras": ["belt", "satellites", "comet", "gates", "lamps"],
		"planets": [{"pos": Vector3(-1900, -300, -2200), "r": 700.0, "a": Color(0.5, 0.5, 0.52), "b": Color(0.32, 0.32, 0.36), "rim": Color(0.8, 0.85, 1.0),
				"moons": [{"r": 60.0, "dist": 1.9, "speed": 0.05, "tilt": 0.2}]}],
	},
	"io": {
		"sky_top": Color(0.03, 0.02, 0.05), "sky_bottom": Color(0.2, 0.12, 0.05),
		"neb_a": Color(1.0, 0.6, 0.2), "neb_b": Color(0.6, 0.3, 0.1), "neb": 0.2, "stars": 0.99,
		"neon": Color(1.0, 0.75, 0.15), "barrier": Color(0.22, 0.17, 0.08),
		"sun": Color(1.0, 0.92, 0.8), "ambient": Color(0.55, 0.45, 0.3), "fog": Color(0.18, 0.1, 0.03),
		"suns": [{"dir": Vector3(-0.4, 0.6, 0.5), "color": Color(1.0, 0.96, 0.85), "size": 0.5}],
		"ground": "sulphur", "decor": "lava", "extras": ["comet", "signs"],
		"planets": [{"pos": Vector3(-1200, 900, -2600), "r": 1500.0, "a": Color(0.92, 0.8, 0.62), "b": Color(0.72, 0.45, 0.3), "rim": Color(1, 0.85, 0.6), "bands": 14.0,
				"moons": [{"r": 70.0, "dist": 1.45, "speed": 0.06, "tilt": 0.05, "a": Color(0.8, 0.8, 0.85), "b": Color(0.5, 0.5, 0.6)},
					{"r": 45.0, "dist": 1.75, "speed": 0.035, "tilt": -0.1, "a": Color(0.7, 0.6, 0.45), "b": Color(0.45, 0.35, 0.25)}]}],
	},
	"saturn": {
		"sky_top": Color(0.02, 0.02, 0.07), "sky_bottom": Color(0.09, 0.04, 0.13),
		"neb_a": Color(0.85, 0.45, 0.2), "neb_b": Color(0.5, 0.2, 0.6), "neb": 0.45, "stars": 0.985,
		"neon": Color(1.0, 0.3, 0.9), "barrier": Color(0.14, 0.12, 0.22),
		"sun": Color(1.0, 0.9, 0.75), "ambient": Color(0.38, 0.3, 0.45), "fog": Color(0.07, 0.03, 0.1),
		"suns": [{"dir": Vector3(-0.5, 0.6, 0.6), "color": Color(1.0, 0.95, 0.85), "size": 0.35}],
		"ground": "", "decor": "rings", "extras": ["belt", "satellites", "gates", "lamps", "comet"],
		"planets": [{"pos": Vector3(1400, 350, -2300), "r": 900.0, "a": Color(0.95, 0.82, 0.55), "b": Color(0.75, 0.55, 0.35), "rim": Color(1, 0.85, 0.6), "ring": true,
				"moons": [{"r": 55.0, "dist": 2.9, "speed": 0.04, "tilt": 0.25, "a": Color(0.85, 0.8, 0.7), "b": Color(0.55, 0.5, 0.45)}]}],
	},
	"trappist_hot": {
		"sky_top": Color(0.08, 0.01, 0.02), "sky_bottom": Color(0.35, 0.06, 0.03),
		"neb_a": Color(1.0, 0.3, 0.1), "neb_b": Color(0.5, 0.1, 0.15), "neb": 0.35, "stars": 0.993,
		"neon": Color(1.0, 0.35, 0.15), "barrier": Color(0.2, 0.1, 0.08),
		"sun": Color(1.0, 0.55, 0.4), "ambient": Color(0.6, 0.3, 0.25), "fog": Color(0.3, 0.06, 0.03),
		"suns": [{"dir": Vector3(0.3, 0.35, -0.9), "color": Color(1.0, 0.3, 0.15), "size": 7.0}],
		"ground": "lava", "decor": "hot", "extras": ["comet", "signs"],
		"planets": [{"pos": Vector3(1500, 500, 1400), "r": 90.0, "a": Color(0.8, 0.5, 0.4), "b": Color(0.5, 0.3, 0.25), "rim": Color(1, 0.5, 0.3)},
			{"pos": Vector3(-1700, 700, 900), "r": 70.0, "a": Color(0.7, 0.55, 0.5), "b": Color(0.45, 0.35, 0.3), "rim": Color(1, 0.5, 0.3)}],
	},
	"trappist_ocean": {
		"sky_top": Color(0.05, 0.06, 0.14), "sky_bottom": Color(0.35, 0.18, 0.2),
		"neb_a": Color(0.9, 0.4, 0.3), "neb_b": Color(0.3, 0.4, 0.7), "neb": 0.3, "stars": 0.99,
		"neon": Color(0.55, 1.0, 0.4), "barrier": Color(0.12, 0.2, 0.14),
		"sun": Color(1.0, 0.65, 0.5), "ambient": Color(0.5, 0.42, 0.45), "fog": Color(0.25, 0.14, 0.15),
		"suns": [{"dir": Vector3(-0.5, 0.25, -0.8), "color": Color(1.0, 0.4, 0.2), "size": 3.0}],
		"ground": "jungle", "decor": "jungle", "extras": ["comet", "signs"], "aurora": [Color(0.4, 1.0, 0.6), 0.5],
		"planets": [{"pos": Vector3(-1800, 900, 2200), "r": 260.0, "a": Color(0.6, 0.65, 0.8), "b": Color(0.35, 0.4, 0.55), "rim": Color(1, 0.6, 0.5),
				"moons": [{"r": 30.0, "dist": 1.8, "speed": 0.08, "tilt": 0.4}]},
			{"pos": Vector3(1600, 600, 1800), "r": 200.0, "a": Color(0.8, 0.7, 0.6), "b": Color(0.5, 0.45, 0.4), "rim": Color(1, 0.6, 0.5)}],
	},
	"trappist_frozen": {
		"sky_top": Color(0.02, 0.03, 0.08), "sky_bottom": Color(0.14, 0.1, 0.18),
		"neb_a": Color(0.4, 0.5, 0.9), "neb_b": Color(0.7, 0.4, 0.5), "neb": 0.45, "stars": 0.985,
		"neon": Color(0.55, 0.85, 1.0), "barrier": Color(0.2, 0.26, 0.36),
		"sun": Color(1.0, 0.7, 0.6), "ambient": Color(0.42, 0.45, 0.6), "fog": Color(0.1, 0.12, 0.22),
		"suns": [{"dir": Vector3(0.3, 0.3, 0.9), "color": Color(1.0, 0.35, 0.2), "size": 1.6}],
		"ground": "ice", "decor": "ice", "extras": ["comet", "signs"], "aurora": [Color(0.35, 1.0, 0.75), 1.0],
		"planets": [{"pos": Vector3(2000, 700, 1500), "r": 120.0, "a": Color(0.85, 0.85, 0.9), "b": Color(0.6, 0.65, 0.8), "rim": Color(1, 0.6, 0.5),
				"moons": [{"r": 22.0, "dist": 2.2, "speed": 0.1, "tilt": 0.5}]},
			{"pos": Vector3(-1500, 500, -2000), "r": 90.0, "a": Color(0.75, 0.7, 0.7), "b": Color(0.5, 0.5, 0.55), "rim": Color(1, 0.6, 0.5)}],
	},
	"proxima": {
		"sky_top": Color(0.04, 0.01, 0.04), "sky_bottom": Color(0.28, 0.07, 0.07),
		"neb_a": Color(0.9, 0.2, 0.2), "neb_b": Color(0.4, 0.1, 0.4), "neb": 0.3, "stars": 0.99,
		"neon": Color(1.0, 0.3, 0.3), "barrier": Color(0.18, 0.12, 0.14),
		"sun": Color(1.0, 0.5, 0.4), "ambient": Color(0.45, 0.3, 0.32), "fog": Color(0.2, 0.05, 0.05),
		"suns": [{"dir": Vector3(-0.6, 0.18, -0.78), "color": Color(1.0, 0.25, 0.12), "size": 3.2},
			{"dir": Vector3(0.7, 0.5, 0.5), "color": Color(1.0, 0.95, 0.8), "size": 0.15}],
		"ground": "frost", "decor": "twilight", "extras": ["comet", "signs"], "aurora": [Color(1.0, 0.4, 0.5), 0.8],
		"planets": [{"pos": Vector3(1900, 600, -1700), "r": 150.0, "a": Color(0.6, 0.35, 0.4), "b": Color(0.3, 0.18, 0.25), "rim": Color(1.0, 0.4, 0.3),
			"moons": [{"r": 26.0, "dist": 2.0, "speed": 0.07, "tilt": 0.3}]}],
	},
	"station": {
		"sky_top": Color(0.01, 0.01, 0.03), "sky_bottom": Color(0.06, 0.03, 0.06),
		"neb_a": Color(0.6, 0.2, 0.3), "neb_b": Color(0.2, 0.3, 0.7), "neb": 0.3, "stars": 0.985,
		"neon": Color(1.0, 0.6, 0.15), "barrier": Color(0.22, 0.22, 0.26),
		"sun": Color(1.0, 0.6, 0.5), "ambient": Color(0.38, 0.36, 0.42), "fog": Color(0.02, 0.02, 0.05),
		"suns": [{"dir": Vector3(0.6, 0.45, 0.65), "color": Color(1.0, 0.3, 0.15), "size": 2.5}],
		"ground": "", "decor": "station", "extras": ["satellites", "gates", "lamps", "signs", "comet"],
		"planets": [{"pos": Vector3(400, -1600, -2400), "r": 1500.0, "a": Color(0.55, 0.38, 0.32), "b": Color(0.75, 0.75, 0.82), "rim": Color(1, 0.5, 0.4),
				"moons": [{"r": 60.0, "dist": 1.5, "speed": 0.04, "tilt": 0.15}]}],
	},
	"alphacen": {
		"sky_top": Color(0.03, 0.03, 0.1), "sky_bottom": Color(0.16, 0.1, 0.2),
		"neb_a": Color(0.95, 0.7, 0.3), "neb_b": Color(0.4, 0.3, 0.8), "neb": 0.4, "stars": 0.985,
		"neon": Color(1.0, 0.85, 0.35), "barrier": Color(0.2, 0.18, 0.22),
		"sun": Color(1.0, 0.95, 0.82), "ambient": Color(0.48, 0.42, 0.48), "fog": Color(0.08, 0.05, 0.12),
		"suns": [{"dir": Vector3(-0.5, 0.45, -0.75), "color": Color(1.0, 0.95, 0.75), "size": 1.4},
			{"dir": Vector3(-0.2, 0.4, -0.9), "color": Color(1.0, 0.7, 0.4), "size": 1.0}],
		"ground": "", "decor": "twinsuns", "extras": ["belt", "satellites", "gates", "lamps", "comet"],
		"planets": [{"pos": Vector3(-1600, 400, 2100), "r": 220.0, "a": Color(0.75, 0.6, 0.4), "b": Color(0.5, 0.38, 0.25), "rim": Color(1.0, 0.85, 0.5),
			"moons": [{"r": 30.0, "dist": 1.9, "speed": 0.06, "tilt": 0.2}]}],
	},
	"hd189733": {
		"sky_top": Color(0.01, 0.03, 0.12), "sky_bottom": Color(0.05, 0.16, 0.42),
		"neb_a": Color(0.2, 0.4, 1.0), "neb_b": Color(0.5, 0.7, 1.0), "neb": 0.5, "stars": 0.995,
		"neon": Color(0.4, 0.8, 1.0), "barrier": Color(0.12, 0.16, 0.3),
		"sun": Color(1.0, 0.85, 0.65), "ambient": Color(0.35, 0.45, 0.7), "fog": Color(0.05, 0.12, 0.35),
		"suns": [{"dir": Vector3(0.6, 0.35, -0.72), "color": Color(1.0, 0.75, 0.45), "size": 4.5}],
		"ground": "", "decor": "storm", "extras": ["gates", "lamps", "comet"], "aurora": [Color(0.4, 0.7, 1.0), 0.6],
		"planets": [{"pos": Vector3(0, -2600, -600), "r": 2200.0, "a": Color(0.1, 0.25, 0.8), "b": Color(0.05, 0.12, 0.5), "rim": Color(0.5, 0.75, 1.0), "bands": 6.0,
				"moons": [{"r": 90.0, "dist": 1.35, "speed": 0.03, "tilt": 0.1, "a": Color(0.6, 0.65, 0.75), "b": Color(0.35, 0.4, 0.5)}]}],
	},
	"cancri": {
		"sky_top": Color(0.02, 0.01, 0.02), "sky_bottom": Color(0.22, 0.08, 0.04),
		"neb_a": Color(1.0, 0.45, 0.15), "neb_b": Color(0.6, 0.2, 0.3), "neb": 0.25, "stars": 0.99,
		"neon": Color(1.0, 0.5, 0.15), "barrier": Color(0.12, 0.1, 0.12),
		"sun": Color(1.0, 0.85, 0.6), "ambient": Color(0.5, 0.35, 0.3), "fog": Color(0.2, 0.07, 0.03),
		"suns": [{"dir": Vector3(0.45, 0.4, -0.8), "color": Color(1.0, 0.75, 0.4), "size": 9.0}],
		"ground": "lava", "decor": "diamond", "extras": ["gates", "comet", "signs"],
		"planets": [{"pos": Vector3(-2000, 500, -1600), "r": 110.0, "a": Color(0.85, 0.8, 0.75), "b": Color(0.55, 0.5, 0.5), "rim": Color(1.0, 0.7, 0.4)}],
	},
	"kepler16": {
		"sky_top": Color(0.08, 0.04, 0.14), "sky_bottom": Color(0.6, 0.32, 0.25),
		"neb_a": Color(1.0, 0.6, 0.4), "neb_b": Color(0.6, 0.3, 0.6), "neb": 0.3, "stars": 0.993,
		"neon": Color(1.0, 0.6, 0.35), "barrier": Color(0.22, 0.16, 0.2),
		"sun": Color(1.0, 0.75, 0.55), "ambient": Color(0.55, 0.42, 0.45), "fog": Color(0.5, 0.3, 0.25),
		"suns": [{"dir": Vector3(-0.7, 0.18, -0.68), "color": Color(1.0, 0.7, 0.35), "size": 1.6},
			{"dir": Vector3(-0.55, 0.12, -0.83), "color": Color(1.0, 0.35, 0.2), "size": 0.9}],
		"ground": "clouds", "decor": "gas", "extras": ["gates", "lamps", "comet"],
		"planets": [{"pos": Vector3(2100, 900, -1500), "r": 130.0, "a": Color(0.9, 0.75, 0.6), "b": Color(0.6, 0.45, 0.4), "rim": Color(1.0, 0.7, 0.5),
			"moons": [{"r": 18.0, "dist": 2.3, "speed": 0.09, "tilt": 0.3}]}],
	},
	"wasp76": {
		"sky_top": Color(0.15, 0.04, 0.02), "sky_bottom": Color(0.85, 0.35, 0.1),
		"neb_a": Color(1.0, 0.6, 0.2), "neb_b": Color(0.6, 0.15, 0.1), "neb": 0.2, "stars": 0.998,
		"neon": Color(1.0, 0.85, 0.5), "barrier": Color(0.25, 0.12, 0.08),
		"sun": Color(1.0, 0.95, 0.85), "ambient": Color(0.65, 0.4, 0.3), "fog": Color(0.55, 0.2, 0.07),
		"suns": [{"dir": Vector3(0.5, 0.3, 0.8), "color": Color(1.0, 0.97, 0.9), "size": 11.0}],
		"ground": "iron", "decor": "iron", "extras": ["comet", "signs"],
		"planets": [{"pos": Vector3(-1800, 700, 1900), "r": 95.0, "a": Color(0.6, 0.45, 0.4), "b": Color(0.35, 0.25, 0.22), "rim": Color(1.0, 0.8, 0.6)}],
	},
}

static func get_theme(id: String) -> Dictionary:
	return DATA.get(id, DATA["ceres"])


## Direction the main light shines (from the first sun toward the track).
static func light_dir(theme: Dictionary) -> Vector3:
	var suns: Array = theme.get("suns", [])
	if suns.is_empty():
		return Vector3(-0.4, -0.75, -0.5).normalized()
	return -Vector3(suns[0].dir).normalized()


## Point the sky shader's sun uniforms at a theme's suns.
static func apply_sky(mat: ShaderMaterial, theme: Dictionary) -> void:
	mat.set_shader_parameter("top_color", theme.sky_top)
	mat.set_shader_parameter("bottom_color", theme.sky_bottom)
	mat.set_shader_parameter("nebula_a", theme.neb_a)
	mat.set_shader_parameter("nebula_b", theme.neb_b)
	mat.set_shader_parameter("nebula_strength", theme.neb)
	mat.set_shader_parameter("star_amount", theme.get("stars", 0.985))
	var aur: Array = theme.get("aurora", [])
	mat.set_shader_parameter("aurora_color", Color(aur[0]) if not aur.is_empty() else Color(0.3, 1.0, 0.6))
	mat.set_shader_parameter("aurora_strength", float(aur[1]) if aur.size() > 1 else 0.0)
	mat.set_shader_parameter("shooting_stars", 1.0)
	var suns: Array = theme.get("suns", [])
	for k in 2:
		var on := k < suns.size()
		var sun: Dictionary = suns[k] if on else {}
		mat.set_shader_parameter("sun%d_dir" % (k + 1), Vector3(sun.get("dir", Vector3.UP)).normalized())
		mat.set_shader_parameter("sun%d_color" % (k + 1), sun.get("color", Color.BLACK))
		mat.set_shader_parameter("sun%d_size" % (k + 1), deg_to_rad(float(sun.get("size", 0.0))) if on else 0.0)
