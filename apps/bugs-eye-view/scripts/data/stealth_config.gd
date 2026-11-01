class_name StealthConfig
extends Resource
## Global stealth tuning: light, motion, camouflage, noise, scent, escalation.

@export_group("Light")
@export var light_shadow: float = 0.12
@export var light_dim: float = 0.35
@export var light_lit: float = 0.7
@export var light_bright: float = 1.0

@export_group("Motion & camo")
## Seconds of standing still before freeze/camo fully applies.
@export var freeze_delay: float = 0.6
@export var freeze_factor: float = 0.45
@export var camo_factor: float = 0.35
@export var play_dead_factor: float = 0.6
@export var play_dead_radius: float = 18.0
## Stick deflection below this counts as creeping.
@export var creep_threshold: float = 0.55
@export var creep_visibility: float = 0.7
@export var sprint_visibility: float = 1.25

@export_group("Noise")
@export var noise_interval: float = 0.25
@export var creep_noise: float = 0.35
@export var walk_noise: float = 1.0
@export var sprint_noise: float = 1.8
## How strongly ambient noise (TV, dishwasher) masks the player's noise.
@export var mask_strength: float = 1.0
## Loudness per surface id. Surfaces are tagged with meta "surface" on their body.
@export var surface_loudness: Dictionary = {
	&"default": 0.8, &"tile": 1.0, &"stone": 0.9, &"wood": 0.7, &"metal": 1.3,
	&"carpet": 0.3, &"cloth": 0.25, &"paper": 0.3, &"chip_bag": 2.2, &"foil": 2.0,
	&"dishes": 1.8, &"grass": 0.4, &"soil": 0.3, &"patio": 0.9, &"glass": 1.1,
	&"web": 0.1, &"leaves": 1.6,
}

@export_group("Scent")
@export var scent_drop_distance: float = 2.0
@export var scent_decay: float = 0.035
@export var scent_linger_gain: float = 0.3
@export var scent_max_strength: float = 3.0
@export var scent_max_points: int = 160
@export var scent_min_strength: float = 0.12

@export_group("Escalation")
@export var escalation_calm_time: float = 12.0
@export var escalation_min_interval: float = 4.0
@export var shout_radius: float = 70.0
@export var stage_names: PackedStringArray = ["Calm", "Shout", "Swatter", "Pet called", "Bug spray"]

@export_group("Hazards")
## Extra distance beyond a strike's radius that still counts as a close call.
@export var close_call_margin: float = 2.5
@export var spray_exposure_to_hit: float = 1.2
@export var spray_exposure_decay: float = 0.6
## Hazard speed-up at full intensity (time-based floor).
@export var intensity_speedup: float = 0.45


func light_value(level: int) -> float:
	match level:
		0:
			return light_shadow
		1:
			return light_dim
		2:
			return light_lit
		_:
			return light_bright


func loudness_of(surface: StringName) -> float:
	if surface_loudness.has(surface):
		return float(surface_loudness[surface])
	return float(surface_loudness.get(&"default", 0.8))
