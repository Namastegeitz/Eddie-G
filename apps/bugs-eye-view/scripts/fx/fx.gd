class_name Fx
## Small factory for placeholder visuals built in code (rings, labels, materials).
## Real art replaces the "Visual" nodes in scenes; gameplay never depends on these.

static var _cache: Dictionary = {}


static func unshaded(color: Color, no_depth: bool = false) -> StandardMaterial3D:
	var key := "%s|%s" % [color.to_html(), no_depth]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = no_depth
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[key] = m
	return m


## Flat ring of radius 1 lying on the XZ plane.
static func make_ring(color: Color = Color(1.0, 0.35, 0.1, 0.85), no_depth: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.82
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 6
	mi.mesh = torus
	mi.scale = Vector3(1, 0.15, 1)
	mi.material_override = unshaded(color, no_depth)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func make_disc(color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.05
	cyl.radial_segments = 20
	cyl.rings = 1
	mi.mesh = cyl
	mi.material_override = unshaded(color)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func make_icon_label() -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0025
	l.font_size = 48
	l.outline_size = 12
	l.text = ""
	return l
