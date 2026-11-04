extends Ability
## Passive: water lanes are swimmable. "current" scales how fast the river
## carries you, "max_streak" limits how many water lanes in a row you can
## swim (the capybara floats on one), "idle_limit" drowns you if you sit
## still that long (the anaconda), "water_hop_time" speeds hops in water.


func swim() -> Dictionary:
	return p


func hop_time_scale(in_water: bool) -> float:
	if in_water and p.has("water_hop_time"):
		return float(p.water_hop_time) / maxf(0.05, float(run.base_hop))
	return 1.0
