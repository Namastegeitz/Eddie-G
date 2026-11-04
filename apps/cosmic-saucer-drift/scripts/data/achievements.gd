class_name Achievements
extends RefCounted
## In-game achievements. Most track career stats; a few check the race that
## just ended. Each pays Race Credits once.

# id -> [name, description, kind, key, target, reward]
#   kind "stat": career stat >= target; "race": checked on the race just run
const LIST := {
	"first_win": ["First Contact", "Win a race.", "stat", "wins", 1, 200],
	"wins_25": ["Galactic Champ", "Win 25 races.", "stat", "wins", 25, 1000],
	"podiums_10": ["Podium Regular", "Finish top 3 ten times.", "stat", "podiums", 10, 300],
	"drift_10k": ["Drift King", "Drift a total of 10 km.", "stat", "drift_dist", 10000, 600],
	"purple_50": ["Ultraviolet", "Fire 50 purple drift boosts.", "stat", "purple", 50, 600],
	"tricks_100": ["Zero-G Gymnast", "Land 100 tricks.", "stat", "tricks", 100, 600],
	"pods_500": ["Pod Collector", "Collect 500 Energy Pods.", "stat", "pods", 500, 500],
	"hits_100": ["Sharpshooter", "Hit rivals 100 times with items.", "stat", "hits", 100, 600],
	"near_50": ["Close Shave", "Get 50 near misses.", "stat", "near", 50, 400],
	"slip_50": ["Draft Dodger", "Slipstream 50 times.", "stat", "slips", 50, 400],
	"shortcuts_10": ["Off the Map", "Take secret shortcuts 10 times.", "stat", "shortcuts", 10, 400],
	"dist_500k": ["Light Year Club", "Fly 500 km in races.", "stat", "distance", 500000, 1000],
	"cup_gold": ["Cup Winner", "Win a Galactic Cup.", "stat", "cups_won", 1, 500],
	"cups_all": ["Master of the Cups", "Win all 5 Galactic Cups.", "stat", "cups_won", 5, 2500],
	"boss_3": ["Crew Builder", "Beat 3 boss pilots.", "stat", "bosses", 3, 600],
	"boss_all": ["Full Crew", "Beat all 6 boss pilots.", "stat", "bosses", 6, 2000],
	"mirror_win": ["Through the Looking Glass", "Win a Mirror race.", "stat", "mirror_wins", 1, 400],
	"daily_7": ["Weekly Regular", "Finish 7 daily challenges.", "stat", "dailies", 7, 700],
	"shards_9": ["Shard Seeker", "Find 15 Star Shards.", "shards", "", 15, 500],
	"shards_all": ["Constellation", "Find all 42 Star Shards.", "shards", "", 42, 3000],
	"gold_medal": ["Golden Lap", "Earn a gold medal in Time Trial.", "medals", "", 1, 400],
	"running_on_empty": ["Running on Fumes", "Win a race after hitting Emergency Hover.", "race", "fumes", 1, 400],
	"clean_sweep": ["Untouchable", "Win a race without being hit.", "race", "untouched", 1, 400],
	"versus": ["Couch Rivals", "Finish a 2-player race.", "race", "versus", 1, 200],
	"maxed": ["Fully Tuned", "Max out every stat on a saucer.", "maxed", "", 1, 500],
	"fashion": ["Space Fashion", "Own 8 cosmetic items.", "cosmetics", "", 8, 300],
}


static func unlocked(id: String) -> bool:
	return Save.data.achievements.get(id, false)


static func progress(id: String) -> Vector2:
	var a: Array = LIST[id]
	var target := float(a[4])
	var have := 0.0
	match a[2]:
		"stat":
			have = Save.stat(a[3])
		"shards":
			have = float(Save.shard_total())
		"medals":
			for k in Save.data.medals:
				if int(Save.data.medals[k]) >= 3:
					have += 1.0
		"maxed":
			have = 1.0 if _any_maxed() else 0.0
		"cosmetics":
			var n := 0
			for kind in Save.data.owned:
				n += Save.data.owned[kind].size() - 1
			have = float(n)
		"race":
			have = 1.0 if unlocked(id) else 0.0
	return Vector2(minf(have, target), target)


static func _any_maxed() -> bool:
	for s in Save.data.upgrades:
		var full := true
		for st in Catalog.STAT_KEYS:
			if int(Save.data.upgrades[s].get(st, 0)) < 5:
				full = false
		if full:
			return true
	return false


## Check everything after a race; returns the names of new achievements.
static func check(race_stats: Dictionary, place: int, req: Dictionary) -> Array:
	var got: Array = []
	for id in LIST:
		if unlocked(id):
			continue
		var a: Array = LIST[id]
		var ok := false
		if a[2] == "race":
			match a[3]:
				"fumes":
					ok = place == 1 and int(race_stats.hover_count) > 0
				"untouched":
					ok = place == 1 and int(race_stats.hits_taken) == 0 and req.mode != "tt"
				"versus":
					ok = req.mode == "versus"
		else:
			var p := progress(id)
			ok = p.x >= p.y
		if ok:
			Save.data.achievements[id] = true
			Save.add_credits(int(a[5]))
			got.append("%s  (+%d)" % [a[0], a[5]])
			Events.log_event("achievement", {"id": id})
	if not got.is_empty():
		Save.mark()
	return got


## Run outside races too (garage purchases).
static func check_menu() -> Array:
	return check({"hover_count": 0, "hits_taken": 1}, 9, {"mode": "menu"})
