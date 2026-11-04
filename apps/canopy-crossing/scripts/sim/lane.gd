class_name Lane
extends RefCounted
## One row of the crossing. Everything in it is described by data and
## evaluated as a function of time.

const COLS := 9
const WRAP := 17.0          # entities loop over this many tiles
const MARGIN := 4.0         # ...starting this far left of column 0

var row := 0
var type := "safe"          # safe | ground | water
var band := ""
var layout := ""            # "" | ridge
var hazard_id := ""         # main mover/platform hazard
var speed := 0.0            # signed tiles/s for linear entities
var fast := false           # rapids: faster water visuals
var ents: Array[Ent] = []
var preds: Array[Dictionary] = []   # strikers, surfacers, fallers
var tiles := {}             # int col -> {kind, hazard, hidden, sink}
var effect := {}            # {kind, hazard, period, phase, warn, dur}
var items: Array[Dictionary] = []   # collectibles
var goal := false
var start := false
var covered := false          # under dense canopy: hidden from the bird's-eye view
var deco := 0               # seed for decoration


func pred_state(p: Dictionary, t: float) -> Array:
	if t < float(p.get("distracted_until", -1.0)):
		return ["distracted", 0.0]
	var period: float = p.period
	var u := fposmod(t + float(p.phase) + float(p.get("shift", 0.0)), period)
	var warn: float = p.warn
	var act: float = p.active
	if u < warn:
		return ["warn", u / warn]
	if u < warn + act:
		return ["active", (u - warn) / act]
	return ["idle", (u - warn - act) / maxf(0.001, period - warn - act)]


func effect_state(t: float) -> Array:
	if effect.is_empty():
		return ["none", 0.0]
	var period: float = effect.period
	var u := fposmod(t + float(effect.phase), period)
	var warn: float = effect.warn
	var dur: float = effect.dur
	if u < warn:
		return ["warn", u / warn]
	if u < warn + dur:
		return ["active", (u - warn) / dur]
	return ["idle", 0.0]


## World time at which the current effect cycle turns active (for mudslides).
func effect_crossed(t0: float, t1: float) -> bool:
	if effect.is_empty() or t1 <= t0:
		return false
	var period: float = effect.period
	var mark: float = effect.warn
	var a := t0 + float(effect.phase)
	var b := t1 + float(effect.phase)
	var k := floorf((b - mark) / period)
	var cross := k * period + mark
	return cross > a and cross <= b


func tile_at(col: int) -> Dictionary:
	return tiles.get(col, {})


func is_watery() -> bool:
	return type == "water"
