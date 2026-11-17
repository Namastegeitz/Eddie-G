class_name SillyFaces
extends RefCounted
## Now and then one animal near you turns, looks right at you, pulls a silly
## face for a moment (crossed eyes and a tongue out, puffed cheeks, a wink,
## spinning googly eyes) and goes back to normal. Purely for show: nothing
## about where an animal goes or when changes. One at a time, a few seconds
## apart. On in every jungle unless its file says "silly_faces": false; never
## in the tutorial.
##
## Settings > Silly faces: "fpv" (the default: seen from your animal's own
## eyes, in first person, the animal turns and looks straight at you and a
## face pops onto its head, WorldView3D + Critters3D.silly_face), "both"
## (also in bird's-eye, a face drawn over its head looking up at you,
## WorldView + HazardPainter.draw_silly) or "off". Your animal on the home
## screen does it too unless it's off (ModelView).

const KINDS := ["crossed", "puff", "wink", "googly"]
const DUR := 1.7
## Painters that are animals (vehicles, logs and boats never pull faces)
const ANIMALS := ["herd", "runner", "elephant", "kangaroo", "giraffe", "lizard", "crab", "soldier_ant", "ants"]

var key := ""                  # who is pulling a face ("" = nobody)
var kind := ""
var t := 0.0                   # how far into it
var wait := 0.0                # until the next one
var count := 0                 # how many so far (tests)
var rng := RandomNumberGenerator.new()


func _init(seed_value := 0) -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	wait = rng.randf_range(2.5, 6.0)


## The player's choice: "fpv", "both" or "off" (older saves stored true/false).
static func choice() -> String:
	var v = Save.setting("silly_faces", "fpv")
	if v is bool:
		return "fpv" if v else "off"
	return String(v) if String(v) in ["fpv", "both", "off"] else "fpv"


## Whether animals pull faces in this run, in `view` ("fpv" or "bird").
static func enabled(map: Dictionary, mode: String, view := "fpv") -> bool:
	var c := choice()
	if c == "off" or (view == "bird" and c != "both"):
		return false
	return bool(map.get("silly_faces", true)) and mode != "tutorial"


static func is_animal(painter: String) -> bool:
	return painter in ANIMALS


## Moves on by `dt`. `candidates` are the animals in view right now; the one
## pulling a face stops early if it leaves the view.
func step(dt: float, candidates: Array) -> void:
	if key != "":
		t += dt
		if t >= DUR or not candidates.has(key):
			key = ""
			wait = rng.randf_range(4.0, 9.0)
		return
	wait -= dt
	if wait <= 0.0 and not candidates.is_empty():
		key = String(candidates[rng.randi() % candidates.size()])
		kind = KINDS[rng.randi() % KINDS.size()]
		t = 0.0
		count += 1


## 0 (its normal face) .. 1 (full silly face) for animal `k`.
func amount(k: String) -> float:
	if key == "" or k != key:
		return 0.0
	return envelope(t)


## Quick turn and pop in, hold, quick return.
static func envelope(tt: float) -> float:
	if tt < 0.25:
		return tt / 0.25
	if tt > DUR - 0.3:
		return clampf((DUR - tt) / 0.3, 0.0, 1.0)
	return 1.0


## A bounce as the face pops in.
static func pop(a: float) -> float:
	return a * (1.0 + 0.25 * sin(clampf(a, 0.0, 1.0) * PI))
