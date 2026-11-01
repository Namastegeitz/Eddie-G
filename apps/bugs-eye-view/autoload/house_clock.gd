extends Node
## Runs the compressed in-game day and tells the level which routine events
## (breakfast, nap, cleaning, lights-out...) are active right now.

signal hour_changed(hour: float)
signal routine_changed

const SLOT_HOURS := {&"morning": 7.0, &"afternoon": 13.0, &"night": 21.5}

var hour: float = 7.0
var running: bool = false
var schedule: RoutineSchedule
var _active: Dictionary = {}
var _last_minute := -1


func start(s: RoutineSchedule, start_hour: float) -> void:
	schedule = s
	hour = start_hour
	running = s != null
	_refresh(true)


func stop() -> void:
	running = false
	schedule = null
	_active.clear()
	routine_changed.emit()


static func slot_hour(slot: StringName) -> float:
	return float(SLOT_HOURS.get(slot, 7.0))


func _process(delta: float) -> void:
	if not running:
		return
	hour = fposmod(hour + delta * schedule.hours_per_minute / 60.0, 24.0)
	var minute := int(hour * 60.0)
	if minute != _last_minute:
		_last_minute = minute
		hour_changed.emit(hour)
		_refresh(false)


## Jumps the clock (used by tests and debug).
func set_hour(h: float) -> void:
	hour = fposmod(h, 24.0)
	_refresh(true)


func _refresh(force: bool) -> void:
	var changed := force
	if schedule:
		# An id can appear in several windows (the fridge opens more than once).
		var now := {}
		for e: RoutineEvent in schedule.events:
			if e.contains(hour):
				now[e.id] = true
		for e: RoutineEvent in schedule.events:
			var on := now.has(e.id)
			if on != bool(_active.get(e.id, false)):
				_active[e.id] = on
				changed = true
	if changed:
		routine_changed.emit()


func is_active(id: StringName) -> bool:
	return bool(_active.get(id, false))


func any_active(ids: PackedStringArray) -> bool:
	for id in ids:
		if bool(_active.get(StringName(id), false)):
			return true
	return false


func active_labels() -> PackedStringArray:
	var out: PackedStringArray = []
	if schedule:
		for e: RoutineEvent in schedule.events:
			if e.label != "" and e.contains(hour) and not out.has(e.label):
				out.append(e.label)
	return out


func period() -> StringName:
	if hour >= 6.0 and hour < 11.0:
		return &"morning"
	if hour >= 11.0 and hour < 17.0:
		return &"afternoon"
	if hour >= 17.0 and hour < 21.0:
		return &"evening"
	return &"night"


func clock_text() -> String:
	var h := int(hour)
	var m := int((hour - h) * 60.0)
	var suffix := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, suffix]
