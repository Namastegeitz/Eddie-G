class_name Gfx
extends RefCounted
## Graphics quality. "auto" picks High on desktop and Medium on phones and in
## the web player. High: fine details (fur, feathers, glints), 3D at up to
## 2x resolution with 4x anti-aliasing and shadows (2D is drawn at the
## screen's own resolution; the GL Compatibility renderer has no 2D MSAA,
## outlines and anti-aliased lines smooth the edges instead). Medium:
## outlines and shading, 3D at up to 1.5x resolution (no MSAA, lighter on
## phone GPUs). Low: flat shapes, no outlines, smaller 3D buffer.

const LEVELS := ["auto", "high", "medium", "low"]


static func choice() -> String:
	var q := String(Save.setting("graphics", "auto"))
	return q if q in LEVELS else "auto"


static func level() -> String:
	var q := choice()
	if q == "auto":
		var small := OS.has_feature("mobile") or OS.has_feature("web")
		q = "medium" if small else "high"
	return q


static func apply(tree: SceneTree) -> void:
	var q := level()
	Draw.detail = 2 if q == "high" else (1 if q == "medium" else 0)


static func msaa_3d() -> Viewport.MSAA:
	match level():
		"high":
			return Viewport.MSAA_4X
	return Viewport.MSAA_DISABLED


static func shadows() -> bool:
	return level() == "high"


## How many screen pixels the 3D view renders per game pixel.
static func scale_3d(screen_scale: float) -> float:
	match level():
		"high":
			return clampf(screen_scale, 1.0, 2.0)
		"medium":
			return clampf(screen_scale, 1.0, 1.5)
	return 0.75
