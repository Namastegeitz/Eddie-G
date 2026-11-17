class_name Gfx
extends RefCounted
## Graphics quality tiers and shared materials/textures.
##
## Tiers: low (older phones), medium (most phones), high (strong phones,
## web on desktop), ultra (PC). "Auto" picks one from the device and the
## race steps down live if frames drop.

const TIERS := ["low", "medium", "high", "ultra"]

const Q := {
	"low": {"msaa": 0, "scale": 0.7, "shadows": 0, "glow": false, "fog": false, "decor": 0.5,
		"seg": 18, "detail": 0, "face": false, "particles": 0.4, "reflect": false, "speedlines": false,
		"road_detail": 0.0, "sky_detail": 0.0, "lod": 40.0, "fx_dist": 30.0},
	"medium": {"msaa": 0, "scale": 0.85, "shadows": 0, "glow": true, "fog": true, "decor": 1.0,
		"seg": 28, "detail": 1, "face": true, "particles": 0.7, "reflect": false, "speedlines": true,
		"road_detail": 0.5, "sky_detail": 0.5, "lod": 55.0, "fx_dist": 45.0},
	"high": {"msaa": 2, "scale": 1.0, "shadows": 1, "glow": true, "fog": true, "decor": 1.0,
		"seg": 40, "detail": 2, "face": true, "particles": 1.0, "reflect": true, "speedlines": true,
		"road_detail": 1.0, "sky_detail": 1.0, "lod": 80.0, "fx_dist": 80.0},
	"ultra": {"msaa": 4, "scale": 1.0, "shadows": 2, "glow": true, "fog": true, "decor": 1.0,
		"seg": 56, "detail": 2, "face": true, "particles": 1.0, "reflect": true, "speedlines": true,
		"road_detail": 1.0, "sky_detail": 1.0, "lod": 120.0, "fx_dist": 130.0},
}


## Settings for the current tier (Game.quality()).
static func q() -> Dictionary:
	return Q.get(Game.quality(), Q.medium)


static func tier_index(t: String) -> int:
	return maxi(0, TIERS.find(t))


## Best guess for this device; the race lowers it live if it struggles.
static func detect() -> String:
	if OS.has_feature("mobile"):
		var mem: int = int(OS.get_memory_info().get("physical", 0))
		var cores := OS.get_processor_count()
		if mem >= 7_500_000_000 and cores >= 8:
			return "high"
		if mem > 0 and mem < 3_200_000_000:
			return "low"
		return "medium"
	if OS.has_feature("web"):
		# A phone browser runs the game as WebAssembly on WebGL: start light.
		return "low" if DisplayServer.is_touchscreen_available() else "high"
	return "ultra"


## Apply anti-aliasing and render scale to a viewport.
static func apply_viewport(vp: Viewport, qs: Dictionary) -> void:
	if vp == null:
		return
	match int(qs.msaa):
		4:
			vp.msaa_3d = Viewport.MSAA_4X
		2:
			vp.msaa_3d = Viewport.MSAA_2X
		_:
			vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = float(qs.scale)


## Sun shadows per tier.
static func apply_sun(sun: DirectionalLight3D, qs: Dictionary) -> void:
	var s := int(qs.shadows)
	sun.shadow_enabled = s > 0
	if s <= 0:
		return
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if s >= 2 else DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 90.0 if s >= 2 else 55.0
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.2
	sun.shadow_blur = 1.5
	RenderingServer.directional_shadow_atlas_set_size(2048, true)


# ---------------------------------------------------------------- shared materials
static var _hull_shader: Shader = preload("res://shaders/hull.gdshader")
static var _glass_shader: Shader = preload("res://shaders/glass.gdshader")
static var _flame_shader: Shader = preload("res://shaders/flame.gdshader")
static var _shield_shader: Shader = preload("res://shaders/shield.gdshader")
static var _soft: ImageTexture = null
static var _ring: ImageTexture = null


static func hull(paint: Color, under: Color, accent: Color, opts := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _hull_shader
	m.set_shader_parameter("paint", paint)
	m.set_shader_parameter("under", under)
	m.set_shader_parameter("accent", accent)
	m.set_shader_parameter("detail", 0.0 if int(q().detail) == 0 else 1.0)
	m.set_shader_parameter("coat", 0.0 if int(q().detail) == 0 else 1.0)
	for k: String in opts:
		m.set_shader_parameter(k, opts[k])
	return m


static func glass(tint: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _glass_shader
	m.set_shader_parameter("tint", Color(tint.r, tint.g, tint.b))
	m.render_priority = 1
	return m


static func flame(c: Color, core := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _flame_shader
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("core", 1.0 if core else 0.0)
	m.render_priority = 2
	return m


static func shield(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shield_shader
	m.set_shader_parameter("color", c)
	m.render_priority = 3
	return m


## Soft round dot (particles, glows, blob shadows).
static func soft_dot() -> ImageTexture:
	if _soft:
		return _soft
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for x in n:
		for y in n:
			var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	img.generate_mipmaps()
	_soft = ImageTexture.create_from_image(img)
	return _soft


## Thin bright ring (shockwaves).
static func ring_tex() -> ImageTexture:
	if _ring:
		return _ring
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for x in n:
		for y in n:
			var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var a := clampf(1.0 - absf(d - 0.82) / 0.16, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - d) * 12.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	_ring = ImageTexture.create_from_image(img)
	return _ring


## Additive unshaded sprite material.
static func additive(c: Color, tex: Texture2D = null, billboard := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.albedo_color = c
	m.albedo_texture = tex if tex else soft_dot()
	m.disable_receive_shadows = true
	m.disable_fog = true
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return m


## Soft dark disc under a craft when real shadows are off.
static func blob_shadow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0, 0, 0, 0.55)
	m.albedo_texture = soft_dot()
	m.disable_receive_shadows = true
	m.render_priority = -1
	return m
