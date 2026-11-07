class_name ResBuilder
## Writes every tunable .tres: materials, stealth/scoring config, bug stats,
## threat configs, upgrades, routines, level configs and the sound library.
## These files are the editable source of truth afterwards.

const MAT_DIR := "res://assets/materials/"


static func save(res: Resource, path: String, force: bool) -> Resource:
	if not force and ResourceLoader.exists(path):
		return load(path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("save failed %s (%d)" % [path, err])
	return load(path)


static func _mat(color: Color, rough: float = 0.8, metal: float = 0.0, alpha: bool = false,
		unshaded: bool = false, emission: Color = Color(0, 0, 0, 0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if alpha or color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission.a > 0.0:
		m.emission_enabled = true
		m.emission = Color(emission.r, emission.g, emission.b)
		m.emission_energy_multiplier = emission.a
	return m


## Surface detail: material -> [texture, world units per repeat, bump strength].
## Textures come from tools/generate_textures.py (near-white detail tinted by
## the material colour), mapped triplanar in the object's own space so they
## stick to moving people, pets and props.
const TEXTURED := {
	# Rooms
	"tile": ["tile", 48.0, 1.0], "wood": ["wood", 40.0, 0.8], "dark_wood": ["wood", 40.0, 0.8],
	"fence": ["wood", 60.0, 1.0], "counter_stone": ["stone", 30.0, 0.6],
	"wall_paint": ["plaster", 50.0, 0.5], "wall_blue": ["plaster", 50.0, 0.5], "ceiling": ["plaster", 50.0, 0.4],
	"carpet": ["carpet", 16.0, 0.8], "rug": ["carpet", 14.0, 0.8], "grass": ["grass", 22.0, 0.8],
	"soil": ["soil", 24.0, 0.9], "patio": ["patio", 70.0, 1.0], "paper": ["plaster", 20.0, 0.3],
	"cloth_red": ["fabric", 6.0, 0.7], "cloth_blue": ["fabric", 8.0, 0.7],
	"leaf_green": ["leaf", 10.0, 0.6], "leaves": ["leaf", 8.0, 0.6],
	"metal": ["metal", 20.0, 0.4], "dark_metal": ["metal", 12.0, 0.4], "fridge_white": ["plaster", 40.0, 0.2],
	# Climbing junk and bounce pads
	"insulation": ["carpet", 3.0, 1.0], "drywall": ["plaster", 30.0, 0.4], "concrete": ["stone", 30.0, 0.8],
	"cardboard": ["plaster", 14.0, 0.5], "brick": ["patio", 12.0, 1.0], "terracotta": ["stone", 10.0, 0.6],
	"sponge": ["carpet", 4.0, 1.0], "scourer": ["carpet", 3.0, 1.0], "book_green": ["fabric", 4.0, 0.5],
	# People
	"skin": ["skin", 6.0, 0.5], "hair": ["hair", 4.0, 0.8], "jeans": ["denim", 4.0, 0.8],
	"shirt": ["fabric", 3.0, 0.7], "hazmat": ["fabric", 6.0, 0.5], "shoe": ["stone", 5.0, 0.5],
	"belt": ["stone", 3.0, 0.5],
	# Pets
	"cat_orange": ["fur", 3.0, 0.9], "dog_brown": ["fur", 4.0, 0.9], "dog_white": ["fur", 4.0, 0.9],
	"dog_black": ["fur", 4.0, 0.9], "fur_dark": ["fur", 4.0, 0.9], "cat_stripe": ["fur", 3.0, 0.9],
	# Bugs
	"roach": ["chitin", 1.2, 0.6], "roach_light": ["chitin", 1.2, 0.6], "roach_dark": ["chitin", 1.2, 0.6],
	"ant": ["chitin", 1.0, 0.5], "cricket": ["chitin", 1.4, 0.6], "cricket_dark": ["chitin", 1.4, 0.6],
	"stink": ["chitin", 1.2, 0.8], "stink_edge": ["chitin", 1.2, 0.8], "spider": ["chitin", 1.2, 0.5],
	"spider_band": ["chitin", 1.0, 0.5], "fly": ["chitin", 1.0, 0.5], "fly_belly": ["chitin", 1.0, 0.5],
	"fly_stripe": ["chitin", 1.0, 0.5], "ladybug_red": ["chitin", 1.0, 0.25], "firefly_body": ["chitin", 1.0, 0.5],
	"firefly_orange": ["chitin", 1.0, 0.5],
}
## Floors and walls are seen at a low angle from bug height: keep them sharp.
const ANISOTROPIC := ["tile", "wood", "dark_wood", "carpet", "rug", "grass", "soil", "patio", "wall_paint", "wall_blue", "fence"]


static func _texture(m: StandardMaterial3D, spec: Array) -> void:
	var tex := String(spec[0])
	var units := float(spec[1])
	m.albedo_texture = load("res://assets/textures/%s.png" % tex)
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/%s_n.png" % tex)
	m.normal_scale = float(spec[2])
	m.uv1_triplanar = true
	m.uv1_world_triplanar = false
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3.ONE / units
	# The detail maps average a little under white: keep the colour as it was.
	var c := m.albedo_color
	m.albedo_color = Color(minf(c.r * 1.07, 1.0), minf(c.g * 1.07, 1.0), minf(c.b * 1.07, 1.0), c.a)


static func materials(force: bool) -> void:
	var defs := {
		"tile": _mat(Color(0.58, 0.55, 0.49), 0.6),
		"wood": _mat(Color(0.58, 0.41, 0.24)),
		"dark_wood": _mat(Color(0.33, 0.2, 0.11)),
		"counter_stone": _mat(Color(0.42, 0.42, 0.44), 0.4),
		"metal": _mat(Color(0.72, 0.73, 0.76), 0.3, 0.8),
		"dark_metal": _mat(Color(0.18, 0.18, 0.2), 0.4, 0.6),
		"fridge_white": _mat(Color(0.93, 0.93, 0.9), 0.3),
		"wall_paint": _mat(Color(0.82, 0.76, 0.62)),
		"wall_blue": _mat(Color(0.5, 0.6, 0.68)),
		"ceiling": _mat(Color(0.92, 0.9, 0.86)),
		"cloth_red": _mat(Color(0.62, 0.16, 0.14), 1.0),
		"cloth_blue": _mat(Color(0.2, 0.32, 0.55), 1.0),
		"carpet": _mat(Color(0.45, 0.32, 0.22), 1.0),
		"rug": _mat(Color(0.55, 0.42, 0.62), 1.0),
		"glass": _mat(Color(0.7, 0.85, 0.95, 0.35), 0.1),
		"window": _mat(Color(0.75, 0.9, 1.0), 0.2, 0.0, false, true),
		"chip_bag": _mat(Color(0.95, 0.65, 0.1), 0.3, 0.5),
		"foil": _mat(Color(0.85, 0.86, 0.9), 0.15, 1.0),
		"paper": _mat(Color(0.92, 0.9, 0.84)),
		"grass": _mat(Color(0.32, 0.55, 0.22), 1.0),
		"soil": _mat(Color(0.3, 0.2, 0.12), 1.0),
		"patio": _mat(Color(0.5, 0.47, 0.42), 0.9),
		"fence": _mat(Color(0.55, 0.42, 0.3)),
		"leaf_green": _mat(Color(0.25, 0.6, 0.2)),
		"flower": _mat(Color(0.95, 0.4, 0.55)),
		"leaves": _mat(Color(0.7, 0.45, 0.15), 1.0),
		"crumb": _mat(Color(0.86, 0.66, 0.34)),
		"golden": _mat(Color(1.0, 0.8, 0.2), 0.2, 0.9, false, false, Color(1.0, 0.7, 0.2, 1.5)),
		"skin": _mat(Color(0.86, 0.66, 0.52)),
		"jeans": _mat(Color(0.22, 0.3, 0.5)),
		"shirt": _mat(Color(0.75, 0.3, 0.25)),
		"shoe": _mat(Color(0.2, 0.17, 0.15)),
		"hazmat": _mat(Color(0.95, 0.85, 0.15)),
		"cat_orange": _mat(Color(0.9, 0.55, 0.2)),
		"dog_brown": _mat(Color(0.7, 0.47, 0.24)),
		"vacuum": _mat(Color(0.12, 0.12, 0.14), 0.3, 0.5),
		"swatter": _mat(Color(0.85, 0.15, 0.12), 0.6),
		"roach": _mat(Color(0.42, 0.24, 0.1), 0.35),
		"fly": _mat(Color(0.15, 0.15, 0.17), 0.4),
		"fly_eye": _mat(Color(0.75, 0.1, 0.1), 0.2),
		"wing": _mat(Color(0.85, 0.9, 1.0, 0.35), 0.1),
		"spider": _mat(Color(0.08, 0.07, 0.07), 0.5),
		"web": _mat(Color(0.95, 0.95, 1.0, 0.65), 0.5, 0.0, true, true),
		"water": _mat(Color(0.35, 0.6, 0.9, 0.55), 0.05),
		"spray": _mat(Color(0.55, 0.95, 0.35, 0.35), 1.0, 0.0, true, true),
		"fog": _mat(Color(0.55, 0.9, 0.35, 0.45), 1.0, 0.0, true, true),
		"beacon": _mat(Color(1.0, 0.8, 0.25, 0.55), 1.0, 0.0, true, true),
		"screen_glow": _mat(Color(0.7, 0.85, 1.0), 1.0, 0.0, false, true),
		"tv_screen": _mat(Color(0.35, 0.55, 0.95), 1.0, 0.0, false, true),
		"shadow_tint": _mat(Color(0.0, 0.0, 0.0, 0.32), 1.0, 0.0, true, true),
		"light_tint": _mat(Color(1.0, 0.9, 0.55, 0.16), 1.0, 0.0, true, true),
		"hole": _mat(Color(0.02, 0.015, 0.01), 1.0, 0.0, false, true),
		"arrow": _mat(Color(1.0, 0.8, 0.25), 1.0, 0.0, false, true),
		"gust": _mat(Color(0.9, 0.95, 1.0, 0.12), 1.0, 0.0, true, true),
		"lamp": _mat(Color(1.0, 0.92, 0.7), 1.0, 0.0, false, true),
		"plastic_white": _mat(Color(0.95, 0.95, 0.95), 0.4),
		"grape": _mat(Color(0.45, 0.15, 0.5), 0.3),
		"pea": _mat(Color(0.4, 0.75, 0.25), 0.4),
		"ball": _mat(Color(0.9, 0.2, 0.2), 0.5),
		# People
		"hair": _mat(Color(0.23, 0.15, 0.09), 0.9),
		"eye_white": _mat(Color(0.96, 0.95, 0.92), 0.3),
		"iris": _mat(Color(0.2, 0.32, 0.45), 0.2),
		"pupil": _mat(Color(0.02, 0.02, 0.03), 0.05),
		"lips": _mat(Color(0.72, 0.38, 0.36), 0.6),
		"belt": _mat(Color(0.25, 0.16, 0.1), 0.5),
		"goggles": _mat(Color(0.15, 0.25, 0.3, 0.75), 0.1, 0.3),
		# Bug detail
		"roach_light": _mat(Color(0.78, 0.6, 0.38), 0.4),
		"roach_wing": _mat(Color(0.55, 0.3, 0.12), 0.15, 0.1),
		"roach_dark": _mat(Color(0.2, 0.11, 0.05), 0.4),
		"fly_stripe": _mat(Color(0.55, 0.55, 0.52), 0.6),
		"fly_belly": _mat(Color(0.42, 0.38, 0.3), 0.6),
		"wing_vein": _mat(Color(0.25, 0.22, 0.2, 0.7), 0.4),
		"spider_mark": _mat(Color(0.82, 0.78, 0.7), 0.6),
		"spider_band": _mat(Color(0.38, 0.28, 0.2), 0.6),
		"spider_eye": _mat(Color(0.05, 0.05, 0.06), 0.05, 0.4, false, false, Color(0.6, 0.1, 0.1, 0.4)),
		"fang": _mat(Color(0.4, 0.05, 0.05), 0.3),
		# Bug food
		"sugar": _mat(Color(0.98, 0.98, 1.0), 0.25, 0.0, false, false, Color(1, 1, 1, 0.25)),
		"cheese": _mat(Color(1.0, 0.8, 0.25), 0.5),
		"cheese_hole": _mat(Color(0.75, 0.55, 0.12), 0.7),
		"mint": _mat(Color(0.3, 0.8, 0.45), 0.5),
		"honey": _mat(Color(1.0, 0.65, 0.08, 0.85), 0.05, 0.0, false, false, Color(1.0, 0.55, 0.05, 0.6)),
		"coffee": _mat(Color(0.3, 0.17, 0.08), 0.35),
		"kibble": _mat(Color(0.55, 0.33, 0.16), 0.9),
		# Crumb gems (glow a little so they read from a distance)
		"gem_amethyst": _mat(Color(0.62, 0.3, 0.95, 0.85), 0.05, 0.2, false, false, Color(0.6, 0.25, 1.0, 1.2)),
		"gem_amber": _mat(Color(1.0, 0.6, 0.1, 0.85), 0.05, 0.2, false, false, Color(1.0, 0.5, 0.05, 1.2)),
		"gem_emerald": _mat(Color(0.15, 0.9, 0.45, 0.85), 0.05, 0.2, false, false, Color(0.1, 0.9, 0.4, 1.2)),
		"gem_ruby": _mat(Color(0.95, 0.12, 0.2, 0.85), 0.05, 0.2, false, false, Color(1.0, 0.1, 0.15, 1.2)),
		"gem_diamond": _mat(Color(0.92, 0.97, 1.0, 0.8), 0.02, 0.3, false, false, Color(0.8, 0.95, 1.0, 1.4)),
		"gem_sapphire": _mat(Color(0.15, 0.35, 1.0, 0.85), 0.05, 0.2, false, false, Color(0.15, 0.4, 1.0, 1.2)),
		"sparkle": _mat(Color(1.0, 1.0, 0.9), 1.0, 0.0, false, true),
		"heat": _mat(Color(1.0, 0.6, 0.3, 0.22), 1.0, 0.0, true, true),
		"dog_white": _mat(Color(0.95, 0.92, 0.85), 0.9),
		"ant": _mat(Color(0.3, 0.09, 0.05), 0.25, 0.1),
		"cricket": _mat(Color(0.38, 0.26, 0.13), 0.5),
		"cricket_dark": _mat(Color(0.17, 0.11, 0.06), 0.4),
		"ladybug_red": _mat(Color(0.86, 0.1, 0.07), 0.15, 0.1),
		"ladybug_black": _mat(Color(0.05, 0.05, 0.05), 0.3),
		"firefly_body": _mat(Color(0.14, 0.12, 0.11), 0.4),
		"firefly_orange": _mat(Color(0.92, 0.45, 0.15), 0.5),
		"firefly_glow": _mat(Color(0.85, 1.0, 0.35), 0.3, 0.0, false, false, Color(0.75, 1.0, 0.25, 3.0)),
		"stink": _mat(Color(0.42, 0.38, 0.3), 0.8),
		"stink_edge": _mat(Color(0.68, 0.63, 0.52), 0.8),
		"stink_cloud": _mat(Color(0.55, 0.78, 0.25, 0.2), 1.0, 0.0, true, true),
		"dog_black": _mat(Color(0.1, 0.09, 0.08), 0.6),
		"fur_dark": _mat(Color(0.36, 0.22, 0.12), 0.9),
		# Wet, glossy eyes: the light makes the sparkle.
		"pet_eye_dog": _mat(Color(0.3, 0.17, 0.08), 0.04),
		"pet_eye_cat": _mat(Color(0.45, 0.75, 0.25), 0.04),
		"cat_stripe": _mat(Color(0.62, 0.32, 0.1), 0.9),
		# Climbing junk and bounce pads.
		"cardboard": _mat(Color(0.66, 0.5, 0.32), 0.9),
		"label_red": _mat(Color(0.78, 0.2, 0.15), 0.5, 0.1),
		"label_blue": _mat(Color(0.2, 0.38, 0.75), 0.5, 0.1),
		"book_green": _mat(Color(0.16, 0.38, 0.22), 0.7),
		"terracotta": _mat(Color(0.72, 0.36, 0.2), 0.85),
		"brick": _mat(Color(0.6, 0.24, 0.16), 0.9),
		"sponge": _mat(Color(0.98, 0.84, 0.25), 1.0),
		"scourer": _mat(Color(0.22, 0.55, 0.25), 1.0),
		"mushroom": _mat(Color(0.85, 0.15, 0.12), 0.45),
		# Treasures: a beam over the epic and legendary ones.
		"smoke": _mat(Color(0.62, 0.62, 0.6, 0.45), 1.0, 0.0, true, true),
		"shard": _mat(Color(0.45, 0.95, 1.0, 0.9), 0.05, 0.3, false, false, Color(0.3, 0.9, 1.0, 1.6)),
		"brass": _mat(Color(0.85, 0.65, 0.25), 0.3, 0.7, false, false, Color(1.0, 0.7, 0.2, 0.25)),
		"insulation": _mat(Color(0.95, 0.6, 0.65), 1.0),
		"drywall": _mat(Color(0.82, 0.8, 0.75), 0.95),
		"concrete": _mat(Color(0.52, 0.52, 0.5), 0.95),
		"copper": _mat(Color(0.78, 0.45, 0.25), 0.3, 0.7),
		"rarity_beam": _mat(Color(1.0, 0.8, 0.3, 0.22), 1.0, 0.0, true, true),
		"rarity_beam_epic": _mat(Color(0.75, 0.4, 1.0, 0.2), 1.0, 0.0, true, true),
		"pearl": _mat(Color(0.96, 0.94, 0.9), 0.15, 0.2, false, false, Color(0.9, 0.9, 1.0, 0.25)),
		"silver": _mat(Color(0.8, 0.82, 0.86), 0.22, 0.55, false, false, Color(0.75, 0.8, 0.9, 0.18)),
		"gold": _mat(Color(0.93, 0.68, 0.22), 0.25, 0.6, false, false, Color(1.0, 0.62, 0.15, 0.3)),
		"acorn": _mat(Color(0.55, 0.36, 0.17), 0.7),
		"shell": _mat(Color(0.82, 0.68, 0.48), 0.5),
		# Power-up tokens: glowing coins.
		"power_turbo": _mat(Color(0.2, 0.85, 1.0), 0.25, 0.3, false, false, Color(0.2, 0.8, 1.0, 1.6)),
		"power_spring": _mat(Color(0.55, 1.0, 0.25), 0.25, 0.3, false, false, Color(0.5, 1.0, 0.2, 1.6)),
		"power_radar": _mat(Color(1.0, 0.55, 0.15), 0.25, 0.3, false, false, Color(1.0, 0.5, 0.1, 1.6)),
		"power_double": _mat(Color(1.0, 0.85, 0.2), 0.25, 0.6, false, false, Color(1.0, 0.8, 0.2, 1.6)),
		"power_shrink": _mat(Color(0.85, 0.4, 1.0), 0.25, 0.3, false, false, Color(0.8, 0.35, 1.0, 1.6)),
	}
	for k: String in defs.keys():
		var mat: StandardMaterial3D = defs[k]
		if TEXTURED.has(k):
			_texture(mat, TEXTURED[k])
			if k in ANISOTROPIC:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if k in ["web", "beacon", "shadow_tint", "light_tint", "gust", "spray", "fog", "heat", "stink_cloud", "rarity_beam", "rarity_beam_epic", "smoke"]:
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		if k in ["shadow_tint", "light_tint", "gust", "beacon", "heat", "rarity_beam", "rarity_beam_epic", "smoke"]:
			mat.disable_receive_shadows = true
		save(mat, MAT_DIR + k + ".tres", force)


## Bug food (short boosts) and crumb gems (rare powers).
static func items(force: bool) -> void:
	var defs := [
		["sugar_cube", "Sugar Cube", ItemDef.Kind.FOOD, &"speed", 8.0, 1.35, 40, Color(1, 1, 1),
			"Faster for 8 seconds, and your meters are topped up."],
		["cheese", "Cheese Crumb", ItemDef.Kind.FOOD, &"hearty", 0.0, 1.0, 60, Color(1, 0.8, 0.25),
			"One extra shell: you can take another hit."],
		["mint_leaf", "Mint Leaf", ItemDef.Kind.FOOD, &"fresh", 15.0, 1.0, 40, Color(0.3, 0.8, 0.45),
			"No scent trail for 15 seconds. Dogs lose you."],
		["honey_drop", "Honey Drop", ItemDef.Kind.FOOD, &"soft_step", 12.0, 0.3, 40, Color(1, 0.65, 0.1),
			"Sticky, quiet feet: 70% quieter for 12 seconds."],
		["coffee_bean", "Coffee Bean", ItemDef.Kind.FOOD, &"wired", 10.0, 1.0, 40, Color(0.45, 0.25, 0.1),
			"Wired: fast dodges, Sense and stamina never run out (10 s)."],
		["kibble", "Dog Kibble", ItemDef.Kind.FOOD, &"big_meal", 0.0, 2.0, 30, Color(0.55, 0.33, 0.16),
			"A feast - counts as 2 crumbs."],
		["gem_amethyst", "Amethyst Gem", ItemDef.Kind.GEM, &"cloak", 12.0, 0.2, 300, Color(0.62, 0.3, 0.95),
			"Shadow Cloak: almost invisible for 12 seconds."],
		["gem_amber", "Amber Gem", ItemDef.Kind.GEM, &"freeze", 5.0, 1.0, 300, Color(1, 0.6, 0.1),
			"Time Freeze: every person and pet stops for 5 seconds."],
		["gem_emerald", "Emerald Gem", ItemDef.Kind.GEM, &"calm", 12.0, 1.0, 300, Color(0.15, 0.9, 0.45),
			"Calm: the alarm empties and stays empty for 12 seconds."],
		["gem_ruby", "Ruby Gem", ItemDef.Kind.GEM, &"iron_shell", 8.0, 1.0, 300, Color(0.95, 0.12, 0.2),
			"Iron Shell: nothing can hurt you for 8 seconds."],
		["gem_diamond", "Diamond Gem", ItemDef.Kind.GEM, &"magnet", 12.0, 25.0, 300, Color(0.92, 0.97, 1),
			"Crumb Magnet: nearby crumbs fly to you for 12 seconds."],
		["gem_sapphire", "Sapphire Gem", ItemDef.Kind.GEM, &"decoy", 8.0, 3.0, 300, Color(0.15, 0.35, 1),
			"Echo Decoy: a humming shard lures threats to where you stood."],
		# Power-ups: two of each hidden in the corners of every room.
		["power_turbo", "Turbo", ItemDef.Kind.POWER, &"turbo", 12.0, 1.6, 120, Color(0.2, 0.85, 1.0),
			"60% faster for 12 seconds - hold Run to really fly."],
		["power_spring", "Spring Legs", ItemDef.Kind.POWER, &"spring", 15.0, 1.8, 120, Color(0.55, 1.0, 0.25),
			"Jumps and leaps go much higher for 15 seconds."],
		["power_radar", "Bug Radar", ItemDef.Kind.POWER, &"radar", 20.0, 90.0, 120, Color(1.0, 0.55, 0.15),
			"Crumbs and power-ups show on screen for 20 seconds."],
		["power_double", "Double Crumbs", ItemDef.Kind.POWER, &"double", 25.0, 2.0, 120, Color(1.0, 0.85, 0.2),
			"Every crumb counts twice for 25 seconds."],
		["power_shrink", "Shrink", ItemDef.Kind.POWER, &"shrink", 15.0, 0.55, 120, Color(0.85, 0.4, 1.0),
			"Tiny for 15 seconds: any gap hides you and you're hard to see."],
		# The mini maps' key.
		["brass_key", "Brass Key", ItemDef.Kind.KEY, &"", 0.0, 1.0, 50, Color(0.95, 0.75, 0.3),
			"The way out is open!"],
	]
	# Crumb gems are showcase pieces too.
	var gem_rarity := {"gem_amber": [1, "Kitchen"], "gem_diamond": [3, "Kitchen"], "gem_amethyst": [1, "Living Room"],
		"gem_sapphire": [2, "Living Room"], "gem_ruby": [2, "Backyard"], "gem_emerald": [2, "Backyard"]}
	for d: Array in defs:
		var it := ItemDef.new()
		it.id = StringName(d[0])
		it.display_name = d[1]
		it.kind = d[2]
		it.effect = d[3]
		it.duration = d[4]
		it.amount = d[5]
		it.points = d[6]
		it.color = d[7]
		it.blurb = d[8]
		if gem_rarity.has(d[0]):
			it.rarity = gem_rarity[d[0]][0]
			it.found_in = gem_rarity[d[0]][1]
		save(it, "res://resources/items/%s.tres" % d[0], force)
	for d: Array in TREASURES:
		var it := ItemDef.new()
		it.id = StringName(d[0])
		it.display_name = d[1]
		it.kind = ItemDef.Kind.TREASURE
		it.rarity = d[2]
		it.found_in = d[3]
		it.points = [75, 200, 450, 1000][int(d[2])]
		it.color = ItemDef.RARITY_COLORS[int(d[2])]
		it.duration = 0.0
		it.blurb = d[4]
		save(it, "res://resources/items/%s.tres" % d[0], force)


## Lost trinkets for the showcase: [id, name, rarity 0-3, room, blurb].
## Common ones sit low; legendary ones crown the hardest climbs.
const TREASURES := [
	["treasure_button", "Lost Button", 0, "Kitchen", "Popped off a shirt. A fine shield for a bug."],
	["treasure_bead", "Glass Bead", 0, "Kitchen", "Rolled under everything. Shines like a moon."],
	["treasure_teaspoon", "Doll's Teaspoon", 1, "Kitchen", "Tiny, silver, and exactly your size."],
	["treasure_sea_glass", "Sea Glass", 1, "Kitchen", "Worn smooth by a faraway sea."],
	["treasure_thimble", "Golden Thimble", 2, "Kitchen", "A golden helmet fit for a beetle king."],
	["treasure_ring", "The Lost Wedding Ring", 3, "Kitchen", "Everyone searched for weeks. You found it."],
	["treasure_toy_brick", "Toy Brick", 0, "Living Room", "Four studs and a lot of pain for bare feet."],
	["treasure_marble", "Cat's-Eye Marble", 0, "Living Room", "A swirl of colour frozen in glass."],
	["treasure_pearl", "Loose Pearl", 1, "Living Room", "Slipped off a necklace long ago."],
	["treasure_gear", "Watch Gear", 1, "Living Room", "Still remembers ticking."],
	["treasure_earring", "Crystal Earring", 2, "Living Room", "Throws rainbows across the room."],
	["treasure_brooch", "Grandma's Star Brooch", 3, "Living Room", "Gold and ruby, lost behind the books for years."],
	["treasure_acorn_cap", "Acorn Cap", 0, "Backyard", "A perfect little bowl. Or hat."],
	["treasure_snail_shell", "Spiral Snail Shell", 0, "Backyard", "Nobody's home. Lovely spiral, though."],
	["treasure_old_coin", "Old Coin", 1, "Backyard", "Dug up from under the lawn, older than the house."],
	["treasure_beetle_shell", "Jewel Beetle Shell", 1, "Backyard", "Green and gold like a cousin's armour."],
	["treasure_clover", "Four-Leaf Clover", 2, "Backyard", "One in ten thousand. Lucky you."],
	["treasure_golden_acorn", "The Golden Acorn", 3, "Backyard", "The legend of the yard. Solid gold."],
]


static func configs(force: bool) -> void:
	save(StealthConfig.new(), "res://resources/config/stealth_config.tres", force)
	save(ScoringConfig.new(), "res://resources/config/scoring_config.tres", force)


static func bugs(force: bool) -> void:
	var r := BugStats.new()
	r.id = &"cockroach"
	r.display_name = "Cockroach"
	r.description = "Fast on the ground and tough as nails. Squeezes flat into gaps, survives one extra hit, plays dead, smells crumbs and loves the dark."
	r.scene_path = "res://scenes/bugs/cockroach.tscn"
	r.color = Color(0.42, 0.24, 0.1)
	r.rating_speed = 0.8
	r.rating_stealth = 0.5
	r.rating_toughness = 0.9
	r.max_hits = 2
	r.knockdown_time = 1.0
	r.move_speed = 9.0
	r.climb_speed_mult = 0.8
	r.sprint_speed = 15.0
	r.acceleration = 70.0
	r.jump_velocity = 7.0
	r.noise_mult = 0.9
	r.camo_tags = PackedStringArray(["dark_wood", "soil"])
	r.sense_max = 5.0
	r.sense_regen = 0.4
	r.sense_range = 60.0
	r.dodge_speed = 20.0
	r.push_force = 0.6
	r.tagline = "Fast, tough, and gone the moment the lights come on."
	r.guide = PackedStringArray([
		"move|Push into a wall, cupboard or table leg to climb it; walk over the top onto it",
		"primary|Sprint: run faster - louder and easier to spot",
		"secondary|Squeeze: flatten into gaps to hide completely",
		"jump|Hop over small things",
		"dodge|Tap to dash out from under a stomp; hold to run faster",
		"sense|Smell: your antennae point to the nearest crumb",
		"tip|Stand still to blend in. Near a suspicious threat you play dead.",
	])
	save(r, "res://resources/bugs/cockroach.tres", force)

	var f := BugStats.new()
	f.id = &"fly"
	f.display_name = "Fly"
	f.description = "Erratic, buzzy flight in full 3D. Burst-dodge swats and see strikes in slow motion - but it can't stay airborne forever, and buzzing is loud."
	f.scene_path = "res://scenes/bugs/fly.tscn"
	f.color = Color(0.15, 0.15, 0.17)
	f.unlock_hint = "escape a room as the Cockroach"
	f.rating_speed = 1.0
	f.rating_stealth = 0.35
	f.rating_toughness = 0.2
	f.max_hits = 1
	f.move_speed = 4.0
	f.climb_speed_mult = 0.9
	f.acceleration = 50.0
	f.flight_speed = 13.0
	f.boost_speed = 21.0
	f.flight_accel = 5.0
	f.drift = 1.1
	f.stamina_max = 10.0
	f.stamina_regen = 2.5
	f.visibility_mult = 1.1
	f.camo_tags = PackedStringArray(["dark_wood", "glass", "wall"])
	f.sense_max = 6.0
	f.sense_regen = 0.6
	f.dodge_speed = 22.0
	f.dodge_duration = 0.15
	f.dodge_cooldown = 0.7
	f.unlock_after_bug = &"cockroach"
	f.tagline = "Buzzing, darting, hovering - the whole room is yours."
	# Compound eyes see almost all the way round.
	f.fp_fov = 100.0
	f.guide = PackedStringArray([
		"move|Push into a wall, cupboard or table leg to climb it; walk over the top onto it",
		"jump|Take off, and fly up",
		"secondary|Fly down, land, or cling to a wall or ceiling",
		"primary|Boost: faster, but tiring",
		"dodge|Burst sideways (twice quickly to loop, with Down to dive); hold to fly faster",
		"interact|Pester a person or pet by their head",
		"sense|Slow motion (kicks in by itself when a swat is coming)",
		"tip|Let go to hover. Warm air over the stove and lamps refills your wings.",
	])
	save(f, "res://resources/bugs/fly.tres", force)

	var s := BugStats.new()
	s.id = &"spider"
	s.display_name = "Spider"
	s.description = "Master of stealth and height. Crawls on walls and ceilings, zips on web lines that become bridges, spins traps and feels footsteps through the floor. Slow in the open."
	s.scene_path = "res://scenes/bugs/spider.tscn"
	s.color = Color(0.08, 0.07, 0.07)
	s.unlock_hint = "escape a room as the Fly"
	s.unlock_after_bug = &"fly"
	s.tagline = "Walls, ceilings and webs: the master of stealth."
	s.fp_fov = 96.0
	s.guide = PackedStringArray([
		"move|Walk on floors, up walls and across ceilings",
		"primary|Web zip to where you aim (tap the spot on a touch screen)",
		"secondary|Web trap: slows anything that walks into it",
		"jump|Leap off a wall or ceiling",
		"dodge|Tap to dash; hold to run faster",
		"sense|Feel footsteps through the floor as ripples",
		"tip|Your web lines stay behind as bridges.",
	])
	s.rating_speed = 0.55
	s.rating_stealth = 0.95
	s.rating_toughness = 0.3
	s.max_hits = 1
	s.move_speed = 7.0
	s.can_climb = false
	s.floor_speed_mult = 0.6
	s.wall_speed = 7.5
	s.jump_velocity = 9.0
	s.visibility_mult = 0.85
	s.noise_mult = 0.5
	s.camo_tags = PackedStringArray(["wall", "web", "dark_wood"])
	s.web_range = 32.0
	s.zip_speed = 32.0
	s.web_cooldown = 0.5
	s.bridge_duration = 10.0
	s.sense_max = 6.0
	s.sense_range = 70.0
	s.dodge_speed = 14.0
	s.dodge_duration = 0.15
	s.dodge_cooldown = 0.8
	save(s, "res://resources/bugs/spider.tres", force)
	_new_bugs(force)


## The five bugs added after the first three, each out of the shade once you
## escape a room as the one before it.
static func _new_bugs(force: bool) -> void:
	var a := BugStats.new()
	a.id = &"ant"
	a.display_name = "Ant"
	a.tagline = "Tiny, sneaky, and never really alone."
	a.description = "So small it hides in any gap without squeezing and is hard to spot. Sends a column of decoy ants marching off to lead threats away."
	a.scene_path = "res://scenes/bugs/ant.tscn"
	a.color = Color(0.3, 0.09, 0.05)
	a.unlock_hint = "escape a room as the Spider"
	a.unlock_after_bug = &"spider"
	a.rating_speed = 0.7
	a.rating_stealth = 0.9
	a.rating_toughness = 0.2
	a.max_hits = 1
	a.move_speed = 5.5
	a.climb_speed_mult = 0.95
	a.sprint_speed = 9.0
	a.jump_velocity = 6.0
	a.push_force = 0.2
	a.visibility_mult = 0.6
	a.noise_mult = 0.5
	a.camo_tags = PackedStringArray(["soil", "dark_wood", "leaves"])
	a.gap_crawler = true
	a.tiny = true
	a.ability_cooldown = 9.0
	a.ability_duration = 7.0
	a.sense_max = 5.0
	a.guide = PackedStringArray([
		"move|Push into a wall, cupboard or table leg to climb it; walk over the top onto it",
		"primary|Sprint",
		"secondary|Decoys: a column of ants marches off - threats follow them",
		"jump|Hop",
		"dodge|Tap to dash; hold to run faster",
		"sense|Scout: your antennae point to the nearest crumb",
		"tip|You're tiny: any gap hides you without squeezing, and you're hard to see.",
	])
	save(a, "res://resources/bugs/ant.tres", force)

	var c := BugStats.new()
	c.id = &"cricket"
	c.display_name = "Cricket"
	c.tagline = "Leaps across the room and throws its voice."
	c.description = "Charge up a huge leap onto chairs and boxes. Chirp to throw your voice: threats go to look where the sound came from, not where you are."
	c.scene_path = "res://scenes/bugs/cricket.tscn"
	c.color = Color(0.35, 0.24, 0.12)
	c.unlock_hint = "escape a room as the Ant"
	c.unlock_after_bug = &"ant"
	c.fp_fov = 90.0
	c.rating_speed = 0.75
	c.rating_stealth = 0.6
	c.rating_toughness = 0.35
	c.max_hits = 1
	c.move_speed = 6.0
	c.climb_speed_mult = 0.6
	c.sprint_speed = 6.0
	c.visibility_mult = 0.9
	c.noise_mult = 0.8
	c.camo_tags = PackedStringArray(["grass", "leaves", "soil", "dark_wood"])
	c.gap_crawler = true
	c.ability_cooldown = 5.0
	c.ability_radius = 24.0
	c.guide = PackedStringArray([
		"move|Push into a wall, cupboard or table leg to climb it; walk over the top onto it",
		"jump|Hold to crouch and charge, let go to leap (aim with the stick)",
		"primary|Chirp: throw your voice ahead - threats go to look there",
		"secondary|Squeeze into gaps",
		"dodge|Tap to dash; hold to run faster",
		"sense|Antennae: point to the nearest crumb",
		"tip|A full charge lands you on a chair seat. Steer a little in the air.",
	])
	save(c, "res://resources/bugs/cricket.tres", force)

	var l := BugStats.new()
	l.id = &"ladybug"
	l.display_name = "Ladybug"
	l.tagline = "Lucky, armoured, and too cute to swat."
	l.description = "Tuck into your shell and nothing can hurt you. Flutter down from counters and tables. People won't swat a ladybug - unless the alarm is full."
	l.scene_path = "res://scenes/bugs/ladybug.tscn"
	l.color = Color(0.85, 0.1, 0.08)
	l.unlock_hint = "escape a room as the Cricket"
	l.unlock_after_bug = &"cricket"
	l.rating_speed = 0.5
	l.rating_stealth = 0.4
	l.rating_toughness = 0.85
	l.max_hits = 2
	l.knockdown_time = 0.6
	l.move_speed = 5.5
	l.climb_speed_mult = 0.7
	l.sprint_speed = 5.5
	l.jump_velocity = 7.0
	l.visibility_mult = 1.15
	l.noise_mult = 0.7
	l.camo_tags = PackedStringArray(["leaves"])
	l.gap_crawler = true
	l.ability_meter_max = 4.0
	l.ability_duration = 3.0
	l.guide = PackedStringArray([
		"move|Push into a wall, cupboard or table leg to climb it; walk over the top onto it",
		"primary|Shell up (hold): nothing can hurt you, but you can't move",
		"jump|Hop - hold it in the air to flutter down gently",
		"secondary|Squeeze into gaps",
		"dodge|Tap to dash; hold to run faster",
		"sense|Antennae: point to the nearest crumb",
		"tip|Lucky: people won't swat a ladybug until the alarm is full. Pets don't care.",
	])
	save(l, "res://resources/bugs/ladybug.tres", force)

	var f := BugStats.new()
	f.id = &"firefly"
	f.display_name = "Firefly"
	f.fly_routes = true
	f.fp_fov = 100.0
	f.tagline = "Lights up the night - and dazzles anyone close."
	f.description = "Flies like the fly, but glows while it flies (easy to see in the dark). Flash to dazzle every person and pet nearby: they can't see you for a few seconds."
	f.scene_path = "res://scenes/bugs/firefly.tscn"
	f.color = Color(0.85, 1.0, 0.3)
	f.unlock_hint = "escape a room as the Ladybug"
	f.unlock_after_bug = &"ladybug"
	f.rating_speed = 0.9
	f.rating_stealth = 0.4
	f.rating_toughness = 0.2
	f.max_hits = 1
	f.move_speed = 4.0
	f.climb_speed_mult = 0.85
	f.acceleration = 50.0
	f.flight_speed = 12.5
	f.boost_speed = 20.0
	f.flight_accel = 5.0
	f.drift = 1.0
	f.stamina_max = 9.0
	f.stamina_regen = 2.5
	f.visibility_mult = 1.0
	f.camo_tags = PackedStringArray(["dark_wood", "wall"])
	f.sense_max = 6.0
	f.sense_regen = 0.6
	f.bullet_time_cost = 3.0
	f.ability_radius = 18.0
	f.ability_duration = 3.5
	f.dodge_speed = 22.0
	f.dodge_duration = 0.15
	f.dodge_cooldown = 0.7
	f.guide = PackedStringArray([
		"move|Push into a wall, cupboard or table leg to climb it; walk over the top onto it",
		"jump|Take off, and fly up",
		"secondary|Fly down, land, or cling to a wall or ceiling",
		"primary|Boost",
		"sense|Flash: dazzle every person and pet nearby - they can't see for a few seconds",
		"interact|Pester a person or pet by their head",
		"tip|You glow while flying (easy to spot in the dark). Land or cling to go dark.",
	])
	save(f, "res://resources/bugs/firefly.tres", force)

	var k := BugStats.new()
	k.id = &"stink_bug"
	k.display_name = "Stink Bug"
	k.tagline = "Slow, tough, and impossible to ignore."
	k.description = "Takes three hits. Release a stink cloud: pets bolt from it, people cough and can't see. Your smell lingers, though - dogs track you easily."
	k.scene_path = "res://scenes/bugs/stink_bug.tscn"
	k.color = Color(0.42, 0.38, 0.3)
	k.unlock_hint = "escape a room as the Firefly"
	k.unlock_after_bug = &"firefly"
	k.rating_speed = 0.35
	k.rating_stealth = 0.45
	k.rating_toughness = 1.0
	k.max_hits = 3
	k.knockdown_time = 0.8
	k.move_speed = 4.5
	k.climb_speed_mult = 0.65
	k.sprint_speed = 4.5
	k.jump_velocity = 6.0
	k.visibility_mult = 0.95
	k.noise_mult = 0.9
	k.camo_tags = PackedStringArray(["leaves", "soil", "dark_wood"])
	k.gap_crawler = true
	k.ability_cooldown = 10.0
	k.ability_duration = 6.0
	k.ability_radius = 9.0
	k.guide = PackedStringArray([
		"move|Push into a wall, cupboard or table leg to climb it; walk over the top onto it",
		"primary|Stink cloud: pets bolt, people cough and can't see",
		"secondary|Squeeze into gaps",
		"jump|Hop",
		"dodge|Tap to dash; hold to run faster",
		"sense|Antennae: point to the nearest crumb",
		"tip|Slow but takes three hits. Your smell lingers - dogs track you easily.",
	])
	save(k, "res://resources/bugs/stink_bug.tres", force)


static func threats(force: bool) -> void:
	var h := ThreatConfig.new()
	h.sight_range = 58.0
	h.sight_angle_deg = 70.0
	h.near_sense_radius = 4.0
	h.eye_height = 62.0
	h.gaze_pitch_deg = 38.0
	h.min_visibility = 0.18
	h.hearing_radius = 18.0
	h.hearing_gain = 0.5
	h.suspicion_gain = 1.2
	h.lose_sight_time = 2.0
	h.search_duration = 9.0
	h.turn_speed = 2.4
	h.attack_range = 30.0
	h.attack_windup = 1.05
	h.attack_cooldown = 2.8
	h.stun_duration = 4.5
	save(h, "res://resources/threats/human.tres", force)

	var x: ThreatConfig = h.duplicate()
	x.sight_range = 65.0
	x.hearing_radius = 22.0
	x.attack_cooldown = 2.2
	x.attack_windup = 0.95
	x.search_duration = 12.0
	save(x, "res://resources/threats/exterminator.tres", force)

	var c := ThreatConfig.new()
	c.sight_range = 36.0
	c.sight_angle_deg = 115.0
	c.near_sense_radius = 3.0
	c.eye_height = 5.0
	c.gaze_pitch_deg = 10.0
	c.min_visibility = 0.12
	c.hearing_radius = 20.0
	c.hearing_gain = 0.7
	c.suspicion_gain = 1.3
	c.suspicion_decay = 0.3
	c.search_duration = 10.0
	c.patrol_speed = 5.0
	c.search_speed = 8.0
	c.chase_speed = 12.5
	c.turn_speed = 5.0
	c.attack_range = 8.0
	c.attack_windup = 0.8
	c.attack_cooldown = 2.4
	c.attack_radius = 2.8
	c.stun_duration = 4.0
	save(c, "res://resources/threats/cat.tres", force)

	var d := ThreatConfig.new()
	d.sight_range = 28.0
	d.sight_angle_deg = 100.0
	d.eye_height = 6.0
	d.gaze_pitch_deg = 5.0
	d.min_visibility = 0.12
	d.hearing_radius = 26.0
	d.hearing_gain = 0.8
	d.scent_tracking = true
	d.scent_radius = 13.0
	d.suspicion_gain = 1.0
	d.search_duration = 14.0
	d.patrol_speed = 5.0
	d.search_speed = 7.0
	d.chase_speed = 11.5
	d.attack_range = 7.0
	d.attack_windup = 0.9
	d.attack_cooldown = 2.6
	d.attack_radius = 3.2
	d.stun_duration = 3.5
	save(d, "res://resources/threats/dog.tres", force)

	# Puppy (kitchen): curious and playful, short-sighted, easily distracted.
	var pp := ThreatConfig.new()
	pp.sight_range = 22.0
	pp.sight_angle_deg = 110.0
	pp.eye_height = 4.5
	pp.gaze_pitch_deg = 8.0
	pp.min_visibility = 0.14
	pp.hearing_radius = 20.0
	pp.hearing_gain = 0.7
	pp.scent_tracking = true
	pp.scent_radius = 10.0
	pp.suspicion_gain = 0.9
	pp.search_duration = 8.0
	pp.patrol_speed = 5.5
	pp.search_speed = 7.5
	pp.chase_speed = 10.5
	pp.attack_range = 6.0
	pp.attack_windup = 1.0
	pp.attack_cooldown = 2.8
	pp.attack_radius = 2.6
	pp.stun_duration = 4.0
	save(pp, "res://resources/threats/puppy.tres", force)

	var v := ThreatConfig.new()
	v.sight_range = 0.0
	v.hearing_radius = 30.0
	v.hearing_gain = 0.9
	v.search_duration = 12.0
	v.stun_duration = 4.0
	save(v, "res://resources/threats/vacuum.tres", force)


static func upgrades(force: bool) -> void:
	var defs := [
		["swift_legs", "Swift Legs", "+12% running, crawling and flying speed.", 15, 1, [],
			{"move_speed": 1.12, "sprint_speed": 1.12, "wall_speed": 1.12, "flight_speed": 1.08}],
		["hushed_steps", "Hushed Steps", "20% quieter footsteps.", 20, 2, ["cockroach", "spider"],
			{"noise_mult": 0.8}],
		["deep_camo", "Deep Camo", "Blending in hides you 35% better.", 25, 2, [],
			{"camo_mult": 1.35}],
		["tough_shell", "Tough Shell", "Recover from a knockdown 40% faster.", 20, 2, ["cockroach"],
			{"knockdown_time": 0.6, "invuln_time": 1.3}],
		["long_silk", "Long Silk", "30% longer web lines; bridges last 50% longer.", 25, 3, ["spider"],
			{"web_range": 1.3, "bridge_duration": 1.5}],
		["hushed_wings", "Hushed Wings", "25% quieter buzz and 15% less tiring flight.", 25, 3, ["fly"],
			{"noise_mult": 0.75, "stamina_drain": 0.85}],
		["keen_senses", "Keen Senses", "Bigger, faster-charging sense meter with more range.", 30, 4, [],
			{"sense_max": 1.4, "sense_regen": 1.3, "sense_range": 1.25}],
		["strong_wings", "Strong Wings", "35% more flight stamina.", 30, 4, ["fly"],
			{"stamina_max": 1.35}],
	]
	for d: Array in defs:
		var u := UpgradeDef.new()
		u.id = StringName(d[0])
		u.display_name = d[1]
		u.description = d[2]
		u.cost = d[3]
		u.required_colony = d[4]
		u.applies_to = PackedStringArray(d[5])
		u.modifiers = d[6]
		save(u, "res://resources/upgrades/%s.tres" % d[0], force)


static func _routine(events: Array, rate: float = 0.6) -> RoutineSchedule:
	var r := RoutineSchedule.new()
	r.hours_per_minute = rate
	var arr: Array[RoutineEvent] = []
	for e: Array in events:
		var ev := RoutineEvent.new()
		ev.id = StringName(e[0])
		ev.label = e[1]
		ev.start_hour = e[2]
		ev.end_hour = e[3]
		arr.append(ev)
	r.events = arr
	return r


static func routines(force: bool) -> Dictionary:
	var out := {}
	out["kitchen"] = save(_routine([
		["breakfast", "Breakfast rush", 7.0, 7.75],
		["fridge_open", "Fridge open", 7.15, 7.3],
		["fridge_open", "Fridge open", 7.5, 7.6],
		["sunbeam", "", 7.0, 11.0],
		["lights_on", "", 7.0, 8.25],
		["quiet", "Kitchen empty", 7.75, 8.25],
		["dishes", "Doing the dishes", 8.25, 8.9],
		["cleaning", "Cleaning day", 8.9, 9.8],
		["lunch", "Lunch", 13.0, 13.6],
		["fridge_open", "Fridge open", 13.2, 13.3],
		["lights_on", "", 13.0, 13.6],
		["nap", "Afternoon nap", 13.6, 14.3],
		["cleaning", "Cleaning day", 14.3, 15.2],
		["dishes", "Doing the dishes", 15.2, 15.8],
		["late_snack", "Late snack", 21.5, 22.0],
		["fridge_open", "Fridge open", 21.7, 21.85],
		["lights_on", "", 21.5, 22.0],
		["lights_out", "Lights out", 22.0, 5.0],
		["midnight_snack", "Midnight snack", 23.0, 23.4],
		["fridge_open", "Fridge open", 23.1, 23.2],
	]), "res://resources/routines/kitchen.tres", force)
	out["living_room"] = save(_routine([
		["tv_on", "TV on", 7.0, 8.0],
		["curtains_open", "", 7.5, 12.0],
		["fan_on", "Fan on", 7.0, 12.0],
		["reading", "Reading the paper", 8.0, 8.8],
		["cat_nap", "Cat napping", 8.0, 9.0],
		["tv_on", "TV on", 13.0, 14.0],
		["cat_nap", "Cat napping", 13.0, 13.8],
		["reading", "Reading the paper", 13.8, 14.6],
		["fan_on", "Fan on", 13.0, 17.0],
		["curtains_open", "", 13.0, 17.0],
		["lamp_on", "Lamp on", 21.5, 23.0],
		["tv_on", "Late-night TV", 21.5, 22.5],
		["reading", "Reading the paper", 22.5, 23.0],
		["lights_out", "Lights out", 23.0, 6.0],
	]), "res://resources/routines/living_room.tres", force)
	out["backyard"] = save(_routine([
		["watering", "Sprinklers on", 7.0, 7.6],
		["gardening", "Gardening", 7.6, 8.6],
		["dog_nap", "Dog napping", 8.6, 9.4],
		["bbq", "Barbecue", 13.0, 14.0],
		["dog_nap", "Dog napping", 14.0, 14.7],
		["watering", "Sprinklers on", 14.7, 15.3],
		["porch_light", "Porch light on", 21.5, 24.0],
		["gardening", "Night watering", 21.5, 22.2],
		["watering", "Sprinklers on", 21.5, 22.2],
		["lights_out", "", 22.2, 6.0],
	]), "res://resources/routines/backyard.tres", force)
	return out


static func levels(force: bool, routines_by_id: Dictionary) -> void:
	var k := LevelConfig.new()
	k.id = &"kitchen"
	k.display_name = "Kitchen"
	k.description = "Breakfast rush, a swatter by the sink, a playful puppy and a robot vacuum on cleaning day. Learn to hide in the shadows."
	k.scene_path = "res://scenes/levels/kitchen.tscn"
	k.order = 0
	k.crumbs_required = 10
	k.par_time = 240.0
	k.animal_awareness = 1.0
	k.unlocks_bug = &""
	k.boss_name = "Cleaning Day"
	k.routine = routines_by_id["kitchen"]
	k.ambient_noise = 0.1
	save(k, "res://resources/levels/kitchen.tres", force)

	var l := LevelConfig.new()
	l.id = &"living_room"
	l.display_name = "Living Room"
	l.description = "The TV hides your noise, the rug muffles your steps - and now the cat and the dog are both home, playing chase."
	l.scene_path = "res://scenes/levels/living_room.tscn"
	l.order = 1
	l.crumbs_required = 11
	l.par_time = 290.0
	l.animal_awareness = 1.3
	l.unlock_after = &"kitchen"
	l.unlocks_bug = &""
	l.boss_name = "The Cat"
	l.routine = routines_by_id["living_room"]
	l.ambient_light_by_period = {&"morning": 0.6, &"afternoon": 0.65, &"evening": 0.45, &"night": 0.25}
	l.ambient_noise = 0.05
	save(l, "res://resources/levels/living_room.tres", force)

	var b := LevelConfig.new()
	b.id = &"backyard"
	b.display_name = "Backyard"
	b.description = "Open sky, a dog with a nose for bugs and a cat on the prowl, sprinklers and the exterminator's fog."
	b.scene_path = "res://scenes/levels/backyard.tscn"
	b.order = 2
	b.crumbs_required = 12
	b.par_time = 340.0
	b.animal_awareness = 1.6
	b.unlock_after = &"living_room"
	b.boss_name = "The Exterminator"
	b.routine = routines_by_id["backyard"]
	b.ambient_light_by_period = {&"morning": 0.85, &"afternoon": 0.9, &"evening": 0.6, &"night": 0.22}
	b.ambient_noise = 0.15
	b.intensity_ramp_seconds = 300.0
	save(b, "res://resources/levels/backyard.tres", force)


static func sound_library(force: bool) -> void:
	var lib := SoundLibrary.new()
	var dir := DirAccess.open("res://assets/sfx")
	var sounds := {}
	for f in dir.get_files():
		if f.ends_with(".wav"):
			sounds[StringName(f.get_basename())] = load("res://assets/sfx/" + f)
	lib.sounds = sounds
	save(lib, "res://resources/audio/sound_library.tres", force)
