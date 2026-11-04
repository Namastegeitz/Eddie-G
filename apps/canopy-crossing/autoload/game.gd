extends Node
## Screen navigation and run setup. Screens are scripts under
## res://scripts/ui/ that build their own Controls; the main scene hosts one
## at a time plus a modal layer for prompt cards and the sandbox sheet.

signal screen_changed(name: String)

const SCREENS := {
	"home": "res://scripts/ui/home_screen.gd",
	"animals": "res://scripts/ui/animal_select.gd",
	"world": "res://scripts/ui/world_map.gd",
	"store": "res://scripts/ui/store_screen.gd",
	"pass": "res://scripts/ui/pass_screen.gd",
	"settings": "res://scripts/ui/settings_screen.gd",
	"game": "res://scripts/ui/game_screen.gd",
}

var host: Control
var modal_host: Control
var current: Control
var current_name := ""
var history: Array[String] = []
var run_config: Dictionary = {}
var last_result: Dictionary = {}


func register_host(screen_host: Control, modals: Control) -> void:
	host = screen_host
	modal_host = modals


func boot() -> void:
	if not bool(Save.data.get("tutorial_done", false)):
		start_tutorial()
	else:
		goto("home")


func goto(name: String, args: Dictionary = {}, remember := true) -> void:
	if host == null:
		return
	if current:
		if remember and current_name != "" and current_name != "game" and current_name != name:
			history.append(current_name)
		current.queue_free()
	var script: Script = load(SCREENS[name])
	current = script.new()
	current.name = name.capitalize().replace(" ", "")
	current.set_anchors_preset(Control.PRESET_FULL_RECT)
	if current.has_method("setup"):
		current.setup(args)
	host.add_child(current)
	current_name = name
	screen_changed.emit(name)
	Analytics.event("screen", {"name": name})
	if name == "store":
		Analytics.funnel("first_store_view")


func back() -> void:
	var prev: String = history.pop_back() if not history.is_empty() else "home"
	goto(prev, {}, false)


func modal(node: Control) -> void:
	if modal_host:
		modal_host.add_child(node)


func has_modal() -> bool:
	return modal_host != null and modal_host.get_child_count() > 0


# ------------------------------------------------------------------ runs

func equipped_animal() -> String:
	return String(Save.data.equipped_animal)


func start_tutorial() -> void:
	var tut: Dictionary = Content.onboarding.get("tutorial", {})
	start_run({"mode": "tutorial", "map": String(tut.get("map", "amazon")), "stage": 0, "seed": 1,
		"animal": String(tut.get("animal", equipped_animal()))})


func start_journey(map_id: String, stage: int) -> void:
	start_run({"mode": "journey", "map": map_id, "stage": stage, "seed": absi(hash([map_id, stage, "journey"])) % 1000000})


func start_endless(map_id: String) -> void:
	start_run({"mode": "endless", "map": map_id, "stage": 0, "seed": randi() % 1000000})


func start_daily() -> void:
	var dc := Progress.daily_challenge()
	start_run({"mode": "daily", "map": String(dc.map), "stage": 0, "seed": int(dc.seed)})


func start_run(cfg: Dictionary) -> void:
	var c := cfg.duplicate()
	if not c.has("animal"):
		c.animal = equipped_animal()
	Save.data.selected_map = String(c.map) if c.mode != "daily" and c.mode != "tutorial" else Save.data.selected_map
	Save.mark()
	run_config = c
	goto("game", c)


func restart_run() -> void:
	var c := run_config.duplicate()
	if c.get("mode", "") == "endless":
		c.seed = randi() % 1000000
	start_run(c)
