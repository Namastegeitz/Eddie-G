extends Ability
## Button: swing ahead to the nearest landing lane within `max_rows`.
## target "safe" lands on the next bank; "non_water" leaps a whole river.
## "swings" lets you chain that many before the cooldown starts.


func _init_state() -> void:
	charges = int(p.get("swings", 1))


func has_button() -> bool:
	return true


func _ready_extra() -> bool:
	return target_row() > 0


func can_use() -> bool:
	return has_button() and charges > 0 and uses_left != 0 and _ready_extra() and not run.hopping


func use() -> bool:
	if not can_use():
		return false
	var tr := target_row()
	if not run.leap(tr - run.row, 0.38 + 0.05 * (tr - run.row), "leap" if style == "leap" else "swing"):
		return false
	charges -= 1
	if charges <= 0:
		cd_left = cooldown
	elif not extra.has("window"):
		extra["window"] = 2.5
	return true


func tick(dt: float) -> void:
	super.tick(dt)
	if extra.has("window"):
		extra.window = float(extra.window) - dt
		if float(extra.window) <= 0.0:
			extra.erase("window")
			if charges < int(p.get("swings", 1)):
				charges = 0
				cd_left = cooldown
	if charges <= 0 and cd_left <= 0.0:
		charges = int(p.get("swings", 1))


func progress() -> float:
	if charges > 0:
		return 1.0
	return super.progress()


func badge() -> String:
	return str(charges) if int(p.get("swings", 1)) > 1 and charges > 0 else ""


func target_row() -> int:
	var max_rows := int(p.get("max_rows", 3))
	var want := String(p.get("target", "safe"))
	var seen_water := false
	for k in range(1, max_rows + 1):
		var r: int = run.row + k
		if run.world.goal_row >= 0 and r > run.world.goal_row:
			break
		var l: Lane = run.world.lane(r)
		if want == "non_water":
			if l.type == "water":
				seen_water = true
			elif seen_water:
				return r
		elif l.type == "safe" and l.layout == "" and l.effect.get("kind", "") != "tide" and k >= 2:
			return r
	return -1
