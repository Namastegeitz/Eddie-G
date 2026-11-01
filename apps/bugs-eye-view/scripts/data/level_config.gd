class_name LevelConfig
extends Resource
## Static description of one level: where it lives, goals, unlocks and atmosphere.

@export var id: StringName = &"kitchen"
@export var display_name: String = "Kitchen"
@export_multiline var description: String = ""
@export var scene_path: String = ""
@export var order: int = 0
@export var crumbs_required: int = 8
@export var par_time: float = 180.0
## Level that must be completed first ("" = unlocked from the start).
@export var unlock_after: StringName = &""
## Bug unlocked the first time this level is completed.
@export var unlocks_bug: StringName = &""
@export var boss_name: String = ""
@export var intensity_ramp_seconds: float = 240.0
@export var routine: RoutineSchedule
## Perceived ambient light per period of day when no LightZone applies.
@export var ambient_light_by_period: Dictionary = {
	&"morning": 0.7, &"afternoon": 0.75, &"evening": 0.55, &"night": 0.3,
}
@export var ambient_noise: float = 0.1
## Time slots available once the level has been completed.
@export var time_slots: PackedStringArray = ["morning", "afternoon", "night"]
