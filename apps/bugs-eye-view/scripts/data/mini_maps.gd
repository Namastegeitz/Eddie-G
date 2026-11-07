class_name MiniMaps
## The mini maps behind each room: ten small levels per room - inside the
## walls, under the sink, the basement, the attic - each with a small task,
## gem shards that turn into credits for add-ons, and (now and then) a hidden
## crawl space packed with shards.
##
## Tasks: "shards" (collect N, then escape), "timed" (collect N before the
## clock runs out), "key" (find the key that opens the way out; shards are a
## bonus) and "summit" (the way out is at the very top).

const ROOMS: Array[StringName] = [&"kitchen", &"living_room", &"backyard"]
## Credits per gem shard (crawl spaces pay double).
const SHARD_CREDIT := 1
## Chance the crawl space opens up after finishing one of the room's mini maps.
const CRAWL_CHANCE := 0.3

## [index, theme, name, task, shards needed, time limit, threat]
const PLAN := {
	&"kitchen": [
		[1, "sink", "Drip Tray", "shards", 5, 0.0, ""],
		[2, "walls", "Wire Run", "shards", 6, 0.0, ""],
		[3, "basement", "Laundry Corner", "key", 0, 0.0, ""],
		[4, "sink", "Bottle Maze", "timed", 7, 100.0, ""],
		[5, "walls", "Pipe Chase", "summit", 0, 0.0, ""],
		[6, "basement", "Box Fort", "shards", 8, 0.0, "vacuum"],
		[7, "sink", "The Leak", "key", 0, 0.0, ""],
		[8, "walls", "Mouse Highway", "timed", 9, 90.0, ""],
		[9, "basement", "The Boiler", "summit", 0, 0.0, "cat"],
	],
	&"living_room": [
		[1, "attic", "Dusty Boxes", "shards", 5, 0.0, ""],
		[2, "walls", "Behind the TV", "shards", 6, 0.0, ""],
		[3, "basement", "Old Toys", "key", 0, 0.0, ""],
		[4, "attic", "Rafter Run", "timed", 7, 100.0, ""],
		[5, "walls", "Chimney Breast", "summit", 0, 0.0, ""],
		[6, "attic", "The Trunk", "shards", 8, 0.0, "cat"],
		[7, "basement", "Workbench", "key", 0, 0.0, "vacuum"],
		[8, "walls", "Cable Jungle", "timed", 9, 90.0, ""],
		[9, "attic", "Cat's Hideout", "summit", 0, 0.0, "cat"],
	],
	&"backyard": [
		[1, "walls", "Garage Wall", "shards", 5, 0.0, ""],
		[2, "attic", "Shed Loft", "shards", 6, 0.0, ""],
		[3, "basement", "Window Well", "key", 0, 0.0, ""],
		[4, "sink", "Potting Sink", "timed", 7, 100.0, ""],
		[5, "attic", "Hornet Rafters", "summit", 0, 0.0, ""],
		[6, "basement", "Root Cellar", "shards", 8, 0.0, "cat"],
		[7, "walls", "Insulation Maze", "key", 0, 0.0, ""],
		[8, "sink", "Rusty Pipes", "timed", 9, 90.0, ""],
		[9, "basement", "Furnace Room", "summit", 0, 0.0, "vacuum"],
	],
}

const THEME_NAMES := {
	"sink": "Under the Sink", "walls": "Inside the Walls", "basement": "Basement",
	"attic": "Attic", "crawl": "Crawl Space",
}
const THEME_BLURBS := {
	"sink": "Pipes, bottles and a slow drip in the dark cabinet.",
	"walls": "Studs, wires and drafts in the narrow space between the walls.",
	"basement": "Shelves, boxes and the rumbling furnace under the house.",
	"attic": "Dusty boxes under the sloping roof.",
	"crawl": "A rare draught from under the floor: a crawl space glittering with shards.",
}


static func ids_for(room: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for row: Array in PLAN.get(room, []):
		out.append(StringName("%s_m%d" % [room, int(row[0])]))
	out.append(crawl_id(room))
	return out


static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for r in ROOMS:
		out.append_array(ids_for(r))
	return out


static func crawl_id(room: StringName) -> StringName:
	return StringName("%s_crawl" % room)


static func is_mini(id: StringName) -> bool:
	return String(id).contains("_m") or String(id).ends_with("_crawl")


## Everything about one mini map as a dictionary.
static func entry(id: StringName) -> Dictionary:
	for r in ROOMS:
		if id == crawl_id(r):
			return {"id": id, "room": r, "index": 10, "theme": "crawl", "name": "Crawl Space",
				"task": "shards", "need": 12, "time": 0.0, "threat": "", "hidden": true}
		for row: Array in PLAN[r]:
			if StringName("%s_m%d" % [r, int(row[0])]) == id:
				return {"id": id, "room": r, "index": int(row[0]), "theme": String(row[1]), "name": String(row[2]),
					"task": String(row[3]), "need": int(row[4]), "time": float(row[5]), "threat": String(row[6]),
					"hidden": false}
	return {}


## Credits for finishing the task (shards are paid on top).
static func reward(index: int) -> int:
	return 40 if index >= 10 else 10 + index * 3


static func task_text(task: String, need: int, time_limit: float) -> String:
	match task:
		"timed":
			return "Collect %d gem shards within %d seconds" % [need, int(time_limit)]
		"key":
			return "Find the key that opens the way out"
		"summit":
			return "Climb to the way out at the very top"
	return "Collect %d gem shards, then get out" % need


static func level_config(id: StringName) -> LevelConfig:
	var e := entry(id)
	if e.is_empty():
		return null
	var c := LevelConfig.new()
	c.id = id
	c.is_mini = true
	c.parent_room = e["room"]
	c.theme = e["theme"]
	c.task = e["task"]
	c.time_limit = e["time"]
	c.mini_index = e["index"]
	c.hidden_map = e["hidden"]
	c.display_name = "%s: %s" % [THEME_NAMES[e["theme"]], e["name"]] if not e["hidden"] else "Crawl Space"
	c.description = "%s %s." % [THEME_BLURBS[e["theme"]], task_text(e["task"], e["need"], e["time"])]
	c.scene_path = "res://scenes/levels/minis/%s.tscn" % id
	c.crumbs_required = e["need"]
	c.pickup_noun = "gem shards"
	c.par_time = 90.0
	c.credit_reward = reward(e["index"])
	c.animal_awareness = 1.0 + 0.05 * e["index"]
	var amb: float = {"sink": 0.3, "walls": 0.35, "basement": 0.45, "attic": 0.5, "crawl": 0.25}[e["theme"]]
	c.ambient_light_by_period = {&"morning": amb, &"afternoon": amb, &"evening": amb, &"night": amb}
	c.time_slots = PackedStringArray(["morning"])
	c.intensity_ramp_seconds = 180.0
	return c
