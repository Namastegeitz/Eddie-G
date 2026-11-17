extends Ability
## Passive: collect things up to `radius` lanes and columns away.


func reach() -> int:
	return int(p.get("radius", 1))
