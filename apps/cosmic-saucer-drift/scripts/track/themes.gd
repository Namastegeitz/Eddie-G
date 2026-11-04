class_name Themes
extends RefCounted
## Look of each track: sky, light, neon colour, fog, backdrop planets.

const DATA := {
	"asteroid": {
		"sky_top": Color(0.03, 0.02, 0.09), "sky_bottom": Color(0.10, 0.04, 0.16),
		"neb_a": Color(0.55, 0.18, 0.75), "neb_b": Color(0.15, 0.35, 0.9), "neb": 0.7,
		"neon": Color(0.3, 0.9, 1.0), "barrier": Color(0.16, 0.17, 0.25),
		"sun": Color(1.0, 0.92, 0.85), "sun_dir": Vector3(-0.4, -0.75, -0.5), "ambient": Color(0.35, 0.32, 0.5),
		"fog": Color(0.08, 0.04, 0.15), "ground": "",
		"planets": [{"pos": Vector3(-2200, 500, -2600), "r": 650.0, "a": Color(0.85, 0.55, 0.4), "b": Color(0.55, 0.3, 0.3), "rim": Color(1, 0.6, 0.5)}],
	},
	"saturn": {
		"sky_top": Color(0.02, 0.02, 0.07), "sky_bottom": Color(0.09, 0.04, 0.13),
		"neb_a": Color(0.85, 0.45, 0.2), "neb_b": Color(0.5, 0.2, 0.6), "neb": 0.55,
		"neon": Color(1.0, 0.3, 0.9), "barrier": Color(0.14, 0.12, 0.22),
		"sun": Color(1.0, 0.9, 0.75), "sun_dir": Vector3(0.5, -0.6, -0.6), "ambient": Color(0.38, 0.3, 0.45),
		"fog": Color(0.07, 0.03, 0.1), "ground": "",
		"planets": [{"pos": Vector3(1400, 350, -2300), "r": 900.0, "a": Color(0.95, 0.82, 0.55), "b": Color(0.75, 0.55, 0.35), "rim": Color(1, 0.85, 0.6), "ring": true}],
	},
	"jungle": {
		"sky_top": Color(0.04, 0.10, 0.10), "sky_bottom": Color(0.14, 0.28, 0.18),
		"neb_a": Color(0.2, 0.8, 0.5), "neb_b": Color(0.6, 0.9, 0.3), "neb": 0.35,
		"neon": Color(0.55, 1.0, 0.3), "barrier": Color(0.12, 0.2, 0.14),
		"sun": Color(0.95, 1.0, 0.85), "sun_dir": Vector3(-0.3, -0.8, 0.4), "ambient": Color(0.4, 0.55, 0.42),
		"fog": Color(0.1, 0.22, 0.15), "ground": "jungle",
		"planets": [{"pos": Vector3(-1800, 900, 2200), "r": 1100.0, "a": Color(0.4, 0.6, 0.95), "b": Color(0.25, 0.35, 0.7), "rim": Color(0.7, 0.9, 1)}],
	},
	"ice": {
		"sky_top": Color(0.02, 0.04, 0.12), "sky_bottom": Color(0.14, 0.22, 0.36),
		"neb_a": Color(0.3, 0.7, 1.0), "neb_b": Color(0.8, 0.9, 1.0), "neb": 0.6,
		"neon": Color(0.55, 0.85, 1.0), "barrier": Color(0.2, 0.26, 0.36),
		"sun": Color(0.85, 0.92, 1.0), "sun_dir": Vector3(0.3, -0.7, 0.6), "ambient": Color(0.45, 0.5, 0.65),
		"fog": Color(0.12, 0.18, 0.3), "ground": "ice",
		"planets": [{"pos": Vector3(2000, 700, 1500), "r": 500.0, "a": Color(0.95, 0.95, 1.0), "b": Color(0.6, 0.75, 0.95), "rim": Color(0.7, 0.9, 1)}],
	},
	"station": {
		"sky_top": Color(0.01, 0.01, 0.03), "sky_bottom": Color(0.04, 0.04, 0.09),
		"neb_a": Color(0.2, 0.3, 0.7), "neb_b": Color(0.6, 0.3, 0.2), "neb": 0.3,
		"neon": Color(1.0, 0.6, 0.15), "barrier": Color(0.22, 0.22, 0.26),
		"sun": Color(1.0, 0.97, 0.9), "sun_dir": Vector3(-0.6, -0.5, -0.4), "ambient": Color(0.38, 0.38, 0.45),
		"fog": Color(0.02, 0.02, 0.05), "ground": "",
		"planets": [{"pos": Vector3(400, -1600, -2400), "r": 1500.0, "a": Color(0.25, 0.5, 0.95), "b": Color(0.3, 0.7, 0.35), "rim": Color(0.5, 0.8, 1)}],
	},
	"lava": {
		"sky_top": Color(0.08, 0.02, 0.02), "sky_bottom": Color(0.28, 0.07, 0.03),
		"neb_a": Color(1.0, 0.3, 0.1), "neb_b": Color(0.6, 0.1, 0.25), "neb": 0.45,
		"neon": Color(1.0, 0.45, 0.1), "barrier": Color(0.18, 0.12, 0.11),
		"sun": Color(1.0, 0.75, 0.55), "sun_dir": Vector3(0.4, -0.6, 0.5), "ambient": Color(0.55, 0.35, 0.3),
		"fog": Color(0.22, 0.06, 0.03), "ground": "lava",
		"planets": [{"pos": Vector3(-1500, 600, -2500), "r": 700.0, "a": Color(0.9, 0.4, 0.2), "b": Color(0.5, 0.15, 0.1), "rim": Color(1, 0.5, 0.3)}],
	},
}

static func get_theme(id: String) -> Dictionary:
	return DATA.get(id, DATA["asteroid"])
