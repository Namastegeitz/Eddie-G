class_name Ability
extends RefCounted
## Base for every ability module. An animal's content file lists modules by
## id ("dash", "glide", ...) with parameters; this class loads the script
## res://scripts/abilities/<id>.gd and the run asks it questions through the
## hooks below. A new animal reuses modules by naming them in its file.

const DIR := "res://scripts/abilities/%s.gd"

var id := ""
var p: Dictionary = {}
var run = null              # RunSim
var cooldown := 0.0
var cd_left := 0.0
var active_left := 0.0
var charges := 0
var uses_left := -1         # power-ups bought in the store: limited uses
var extra: Dictionary = {}  # per-module state that must survive clone()
var style := ""


static func exists(module_id: String) -> bool:
	return ResourceLoader.exists(DIR % module_id)


static func create(module_id: String, params: Dictionary, sim) -> Ability:
	var script: Script = load(DIR % module_id)
	var a: Ability = script.new()
	a.id = module_id
	a.setup(params, sim)
	return a


func setup(params: Dictionary, sim) -> void:
	p = params
	run = sim
	cooldown = float(p.get("cooldown", 0.0))
	style = String(p.get("style", ""))
	_init_state()


func _init_state() -> void:
	pass


# ------------------------------------------------------------------ button

func has_button() -> bool:
	return false


func can_use() -> bool:
	return has_button() and cd_left <= 0.0 and active_left <= 0.0 and uses_left != 0 and _ready_extra()


func _ready_extra() -> bool:
	return true


func use() -> bool:
	if not can_use():
		return false
	if not _activate():
		return false
	if cd_left <= 0.0:
		cd_left = cooldown
	if uses_left > 0:
		uses_left -= 1
	return true


func _activate() -> bool:
	return false


func tick(dt: float) -> void:
	cd_left = maxf(0.0, cd_left - dt)
	active_left = maxf(0.0, active_left - dt)


## 0..1 for the button ring; 1 means ready.
func progress() -> float:
	if active_left > 0.0:
		return 1.0
	if cooldown <= 0.0:
		return 1.0
	return 1.0 - cd_left / cooldown


func is_active() -> bool:
	return active_left > 0.0


func badge() -> String:
	if uses_left > 0:
		return str(uses_left)
	return ""


# ------------------------------------------------------------------ hooks

func airborne() -> bool:
	return false


func immune(_source: String, _cause: String) -> bool:
	return false


func absorb(_source: String, _cause: String) -> bool:
	return false


func swim() -> Dictionary:
	return {}


func drift() -> float:
	return 1.0


func knockback_immune() -> bool:
	return false


func reach() -> int:
	return 0


func reveal() -> float:
	return 0.0


func plows() -> bool:
	return false


func forages() -> bool:
	return false


func rooted() -> bool:
	return false


## Hop time multiplier. Any module may carry "hop_scale" (skill upgrades
## shrink it for abilities that have nothing else to improve).
func hop_time_scale(_in_water: bool) -> float:
	return float(p.get("hop_scale", 1.0))


func clone() -> Ability:
	var a: Ability = get_script().new()
	a.id = id
	a.p = p
	a.run = run
	a.cooldown = cooldown
	a.cd_left = cd_left
	a.active_left = active_left
	a.charges = charges
	a.uses_left = uses_left
	a.extra = extra.duplicate(true)
	a.style = style
	return a
