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
## How sharp the animals are here (1 = relaxed). Later rooms are higher:
## faster to notice, see and hear a bit further, play less.
@export var animal_awareness: float = 1.0
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

@export_group("Mini map")
## A mini map behind one of the rooms (see MiniMaps).
@export var is_mini: bool = false
@export var parent_room: StringName = &""
## sink, walls, basement, attic, crawl
@export var theme: String = ""
## shards, timed, key, summit
@export var task: String = "shards"
## Seconds for a timed task (0 = no clock).
@export var time_limit: float = 0.0
@export var mini_index: int = 0
## The crawl space: only open now and then.
@export var hidden_map: bool = false
## What the HUD calls the things you collect.
@export var pickup_noun: String = "crumbs"
## Credits for finishing the task.
@export var credit_reward: int = 0

