class_name Gfx
extends RefCounted
## Graphics quality. "auto" picks High on desktop and Medium on phones and in
## the web player. High: fine details (fur, feathers, glints), 3D at up to
## 2x resolution with 4x anti-aliasing and shadows (2D is drawn at the
## screen's own resolution; the GL Compatibility renderer has no 2D MSAA,
## outlines and anti-aliased lines smooth the edges instead). Medium:
## outlines and shading, 3D at up to 1.5x resolution (no MSAA, lighter on
## phone GPUs). Low: flat shapes, no outlines, smaller 3D buffer.
## Ultra (computers): High plus ambient occlusion, softer and larger shadows
## and at least 1.5x 3D resolution. level() reports Ultra as "high", so every
## High feature applies; ultra() adds the extras.
##
## Also: frame rate (Settings "fps_cap": max = the screen's rate, as before;
## 60; 30 to save battery) and 3D resolution ("res_3d": auto as before, or
## 100 / 75 / 50 % of it).

const LEVELS := ["auto", "ultra", "high", "medium", "low"]
const FPS_CAPS := {"max": 0, "60": 60, "30": 30}
const RES_3D := {"auto": 1.0, "100": 1.0, "75": 0.75, "50": 0.5}


## Set by the --graphics=<level> capture hook (scripts/main.gd); not saved.
static var forced := ""


static func choice() -> String:
	var q := forced if forced != "" else String(Save.setting("graphics", "auto"))
	return q if q in LEVELS else "auto"


static func ultra() -> bool:
	return choice() == "ultra"


static func level() -> String:
	var q := choice()
	if q == "ultra":
		return "high"
	if q == "auto":
		var small := OS.has_feature("mobile") or OS.has_feature("web")
		q = "medium" if small else "high"
	return q


static func apply(tree: SceneTree) -> void:
	var q := level()
	Draw.detail = 2 if q == "high" else (1 if q == "medium" else 0)
	Engine.max_fps = int(FPS_CAPS.get(String(Save.setting("fps_cap", "max")), 0))
	if ultra():
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
		RenderingServer.directional_shadow_atlas_set_size(4096, true)
	else:
		# the project's own defaults (they differ on phones and computers)
		RenderingServer.directional_soft_shadow_filter_set_quality(int(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality")))
		RenderingServer.directional_shadow_atlas_set_size(int(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/directional_shadow/size")), true)


static func msaa_3d() -> Viewport.MSAA:
	match level():
		"high":
			return Viewport.MSAA_4X
	return Viewport.MSAA_DISABLED


static func shadows() -> bool:
	return level() == "high"


## How many screen pixels the 3D view renders per game pixel.
static func scale_3d(screen_scale: float) -> float:
	var k := float(RES_3D.get(String(Save.setting("res_3d", "auto")), 1.0))
	if ultra():
		return clampf(screen_scale, 1.5, 2.0) * k
	match level():
		"high":
			return clampf(screen_scale, 1.0, 2.0) * k
		"medium":
			return clampf(screen_scale, 1.0, 1.5) * k
	return 0.75 * k
