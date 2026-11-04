extends Ability
## Passive night vision: hidden ambushers show, and mist thins by `strength`.


func reveal() -> float:
	return float(p.get("strength", 1.0))
