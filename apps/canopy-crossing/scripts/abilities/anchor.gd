extends Ability
## Passive steadiness. "knockback": gusts and mudslides can't move you.
## "drift": rafts and logs carry you only this fraction as fast (you walk
## against the current), so you're swept off-screen far later.


func knockback_immune() -> bool:
	return bool(p.get("knockback", false))


func drift() -> float:
	return float(p.get("drift", 1.0))
