class_name ScoringConfig
extends Resource
## Points for everything the score screen counts.

@export var crumb_points: int = 100
@export var golden_points: int = 500
@export var close_call_points: int = 50
@export var lure_points: int = 75
@export var stun_points: int = 150
@export var ghost_bonus: int = 1000
@export var speed_bonus_per_second: float = 10.0
@export var hit_penalty: int = 100
## Share of collected crumbs banked to the colony when caught.
@export var caught_bank_ratio: float = 0.5
