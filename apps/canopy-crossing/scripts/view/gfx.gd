class_name Gfx
extends RefCounted
## Graphics quality. "auto" picks High on desktop and Medium on phones and in
## the web player. High: 4x anti-aliasing (2D and 3D), fine details (fur,
## feathers, glints), 3D at full screen resolution with shadows. Medium:
## outlines and shading, 3D at game resolution. Low: flat shapes, no
## outlines, smaller 3D buffer.

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
	if tree != null and tree.root != null:
		tree.root.msaa_2d = Viewport.MSAA_4X if q == "high" else Viewport.MSAA_DISABLED


static func msaa_3d() -> Viewport.MSAA:
	match level():
		"high":
			return Viewport.MSAA_4X
		"medium":
			return Viewport.MSAA_2X
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
