extends Ability
## Button: a low, very fast burst `tiles` rows forward, untouchable on the way.
## "invincible" adds that many seconds of protection after (the pangolin's roll).


func has_button() -> bool:
	return true


func _activate() -> bool:
	var n := int(p.get("tiles", 3))
	if not run.leap(n, 0.07 * n + 0.08, "roll" if style == "roll" else "dash"):
		return false
	if p.has("invincible"):
		run.invuln = maxf(run.invuln, float(p.invincible) + 0.07 * n)
	return true
