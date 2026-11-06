class_name BugStats
extends Resource
## Tunable stats for one bug class. Colony upgrades multiply these at spawn.

@export var id: StringName = &"cockroach"
@export var display_name: String = "Cockroach"
@export_multiline var description: String = ""
@export var scene_path: String = ""
@export var color: Color = Color(0.45, 0.27, 0.12)
@export var unlock_hint: String = ""
## Escape any room as this bug to bring this one out of the shade.
@export var unlock_after_bug: StringName = &""
## One line for the bug select card.
@export var tagline: String = ""
## How to play it, one line per button: "action|what it does"
## (action = primary, secondary, jump, dodge, sense, interact or move).
@export var guide: PackedStringArray = []
## 0-1 ratings shown on the bug select cards.
@export var rating_speed: float = 0.5
@export var rating_stealth: float = 0.5
@export var rating_toughness: float = 0.5

@export_group("Survival")
@export var max_hits: int = 1
@export var knockdown_time: float = 0.0
@export var invuln_time: float = 1.2

@export_group("Ground")
@export var move_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var acceleration: float = 40.0
@export var turn_speed: float = 12.0
@export var gravity: float = 30.0
@export var jump_velocity: float = 7.0
@export var push_force: float = 0.5
@export var floor_max_angle_deg: float = 50.0

@export_group("Dodge")
@export var dodge_speed: float = 16.0
@export var dodge_duration: float = 0.18
@export var dodge_cooldown: float = 0.9

@export_group("Stealth")
@export var visibility_mult: float = 1.0
@export var noise_mult: float = 1.0
@export var camo_tags: PackedStringArray = []
@export var camo_mult: float = 1.0

@export_group("Sense")
## Seconds of sense the meter holds, and how fast it refills.
@export var sense_max: float = 4.0
@export var sense_regen: float = 0.5
## Range for smell / vibration sense.
@export var sense_range: float = 40.0

@export_group("Flight")
@export var flight_speed: float = 14.0
@export var boost_speed: float = 22.0
@export var ascend_speed: float = 9.0
@export var flight_accel: float = 3.5
@export var drift: float = 1.6
@export var stamina_max: float = 8.0
@export var stamina_drain: float = 1.0
@export var stamina_regen: float = 2.0
@export var takeoff_stamina: float = 1.0
@export var bullet_time_scale: float = 0.3
@export var bullet_time_duration: float = 1.2
@export var bullet_time_cost: float = 2.0

@export_group("Climb")
## Every bug can climb walls and furniture (the spider crawls its own way).
@export var can_climb: bool = true
## Climbing speed as a share of the bug's ground speed.
@export var climb_speed_mult: float = 0.75
@export var wall_speed: float = 7.0
@export var floor_speed_mult: float = 0.6
@export var web_range: float = 30.0
@export var zip_speed: float = 30.0
@export var web_cooldown: float = 0.6
@export var web_trap_duration: float = 6.0
@export var bridge_duration: float = 8.0

@export_group("Bug's-eye view")
## Field of view (degrees, vertical) through this bug's eyes.
@export var fp_fov: float = 86.0

@export_group("Small bugs")
## Fits the gaps cockroaches use (under appliances, cracks).
@export var gap_crawler: bool = false
## So small it's hidden in a gap without squeezing.
@export var tiny: bool = false
## Takes the routes and perches made for the fly (open vents, window gaps).
@export var fly_routes: bool = false

@export_group("Special ability")
## Generic tuning for the newer bugs' special moves (decoys, chirps, shell,
## stink, flash, flutter): see each bug's script for what they mean.
@export var ability_cooldown: float = 8.0
@export var ability_duration: float = 6.0
@export var ability_radius: float = 8.0
@export var ability_meter_max: float = 4.0

@export_group("Squeeze")
@export var squeeze_speed_mult: float = 0.4
@export var dark_speed_bonus: float = 0.25
@export var scatter_boost: float = 0.6
@export var scatter_duration: float = 1.2


## Whether this bug fits a passage or shelter meant for the listed bugs
## (empty = everyone). Small ground bugs use the cockroach's gaps; the
## firefly uses the fly's routes.
func fits(bug_ids: PackedStringArray) -> bool:
	if bug_ids.is_empty() or bug_ids.has(String(id)):
		return true
	if gap_crawler and bug_ids.has("cockroach"):
		return true
	return fly_routes and bug_ids.has("fly")
