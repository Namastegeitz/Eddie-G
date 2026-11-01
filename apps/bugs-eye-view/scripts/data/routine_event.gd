class_name RoutineEvent
extends Resource
## One timed window in the household routine (e.g. "breakfast" 7:00-7:45).

@export var id: StringName = &""
@export var label: String = ""
@export var start_hour: float = 7.0
@export var end_hour: float = 8.0


func contains(hour: float) -> bool:
	if start_hour <= end_hour:
		return hour >= start_hour and hour < end_hour
	return hour >= start_hour or hour < end_hour
