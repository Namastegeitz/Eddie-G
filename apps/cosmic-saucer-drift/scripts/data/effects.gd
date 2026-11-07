class_name Effects
extends RefCounted
## Data-driven modifiers. Pilots, craft, Super Upgrade mods, set bonuses,
## global perks and Wonder tiers all carry an "effects" dictionary made of
## the keys below. A racer adds them up once when the race starts
## (Effects.sum) and the driving code reads the totals, so new content only
## needs data: pick keys from KEYS, no code changes.
##
## kind "pct": percentages that add up (25 + 15 = +40%), clamped to min/max.
## kind "add": plain numbers that add up, clamped to min/max.
## kind "item": an item id (the last source wins).

const KEYS := {
	"top_speed_pct": {"kind": "pct", "min": -30, "max": 15, "text": "Top speed %+d%%"},
	"accel_pct": {"kind": "pct", "min": -30, "max": 25, "text": "Acceleration %+d%%"},
	"handling_pct": {"kind": "pct", "min": -30, "max": 25, "text": "Handling %+d%%"},
	"drain_pct": {"kind": "pct", "min": -60, "max": 100, "text": "Core drain %+d%%"},
	"regen": {"kind": "add", "min": 0.0, "max": 1.2, "text": "Core regenerates %.1f a second"},
	"boost_energy": {"kind": "add", "min": 0.0, "max": 5.0, "text": "Boosting recharges the core %.1f a second"},
	"drift_charge_pct": {"kind": "pct", "min": -50, "max": 80, "text": "Drift charge %+d%%"},
	"drift_boost_pct": {"kind": "pct", "min": -50, "max": 80, "text": "Drift boosts last %+d%%"},
	"boost_time_pct": {"kind": "pct", "min": -50, "max": 60, "text": "Every boost lasts %+d%%"},
	"trick_pct": {"kind": "pct", "min": 0, "max": 150, "text": "Trick rewards %+d%%"},
	"slip_charge_pct": {"kind": "pct", "min": 0, "max": 150, "text": "Slipstream charges %+d%% faster"},
	"slip_range_pct": {"kind": "pct", "min": 0, "max": 150, "text": "Slipstream reaches %+d%% farther"},
	"pod_pct": {"kind": "pct", "min": 0, "max": 100, "text": "Energy Pods give %+d%%"},
	"pod_magnet_pct": {"kind": "pct", "min": 0, "max": 300, "text": "Pod pickup range %+d%%"},
	"near_energy_pct": {"kind": "pct", "min": 0, "max": 300, "text": "Near-miss energy %+d%%"},
	"spin_time_pct": {"kind": "pct", "min": -60, "max": 50, "text": "Spin-outs last %+d%%"},
	"wall_keep_pct": {"kind": "pct", "min": 0, "max": 80, "text": "Wall hits cost %d%% less speed"},
	"weight_add": {"kind": "add", "min": -3.0, "max": 6.0, "text": "Weight %+.0f"},
	"bump_pct": {"kind": "pct", "min": 0, "max": 100, "text": "Bumps shove %+d%% harder"},
	"low_grip_pct": {"kind": "pct", "min": 0, "max": 60, "text": "Grip on ice and dust %+d%%"},
	"rough_pct": {"kind": "pct", "min": -100, "max": 0, "text": "Slowdown on dust, moss and lava %+d%%"},
	"glide_sink_pct": {"kind": "pct", "min": -50, "max": 0, "text": "Glides sink %+d%%"},
	"shield_time_pct": {"kind": "pct", "min": 0, "max": 80, "text": "Ion Shield lasts %+d%%"},
	"crate_luck": {"kind": "add", "min": 0.0, "max": 3.0, "text": "Crates roll %.0f places further back"},
	"start_item": {"kind": "item", "text": "Starts every race holding: %s"},
	"stardust_pct": {"kind": "pct", "min": 0, "max": 100, "text": "Stardust from drifts %+d%%"},
	"wonder_charge_pct": {"kind": "pct", "min": -50, "max": 100, "text": "Wonder charge %+d%%"},
	"wonder_power_pct": {"kind": "pct", "min": -50, "max": 100, "text": "Wonder power %+d%%"},
	"heat_pct": {"kind": "pct", "min": -60, "max": 100, "text": "Overclock heat %+d%%"},
}


## Adds up effect dictionaries. Unknown keys are kept as plain numbers so a
## content pack can't crash a race, but they do nothing until code reads them.
static func sum(sources: Array) -> Dictionary:
	var out := {}
	for src: Variant in sources:
		if not (src is Dictionary):
			continue
		for k: String in src:
			var v: Variant = src[k]
			var spec: Dictionary = KEYS.get(k, {})
			if spec.get("kind", "") == "item" or v is String:
				out[k] = v
			else:
				out[k] = float(out.get(k, 0.0)) + float(v)
	for k: String in out.keys():
		var spec: Dictionary = KEYS.get(k, {})
		if spec.has("min") and not (out[k] is String):
			out[k] = clampf(float(out[k]), float(spec.min), float(spec.max))
	return out


## 1 + pct/100 for a "pct" key (1.0 when missing).
static func mult(fx: Dictionary, key: String) -> float:
	return 1.0 + float(fx.get(key, 0.0)) / 100.0


static func val(fx: Dictionary, key: String) -> float:
	var v: Variant = fx.get(key, 0.0)
	return float(v) if not (v is String) else 0.0


## Human-readable lines for menus ("Top speed +5%", ...).
static func describe(fx: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for k: String in fx:
		var spec: Dictionary = KEYS.get(k, {})
		if spec.is_empty():
			continue
		var v: Variant = fx[k]
		match String(spec.kind):
			"item":
				out.append(String(spec.text) % Catalog.ITEMS.get(String(v), {"name": String(v)}).name)
			"pct":
				out.append(String(spec.text) % int(round(float(v))))
			_:
				out.append(String(spec.text) % float(v))
	return out


## Keys a content pack used that the game doesn't know (for validation).
static func unknown_keys(fx: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for k: String in fx:
		if not KEYS.has(k):
			out.append(k)
	return out
