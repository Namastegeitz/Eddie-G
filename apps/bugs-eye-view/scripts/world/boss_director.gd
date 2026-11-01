class_name BossDirector
extends Node
## Set-piece chase that starts when the goal opens.
##   CLEANING_DAY  - the robot vacuum hunts your noise, then the human sprays.
##   THE_CAT       - stalk, hunt, then a pounce barrage near the exit.
##   EXTERMINATOR  - a fog front sweeps the yard while boots stomp after you.

enum Kind { CLEANING_DAY, THE_CAT, EXTERMINATOR }

@export var kind: Kind = Kind.CLEANING_DAY
@export var boss_name: String = "Cleaning Day"
@export var subtitle: String = ""
@export var vacuum_path: NodePath
@export var cat_path: NodePath
@export var human_path: NodePath
@export var fog_path: NodePath

var active := false
var phase := 0
var _t := 0.0


func start() -> void:
	if active:
		return
	active = true
	phase = 1
	_t = 0.0
	var lvl := Level.current
	if lvl:
		lvl.announce_boss(boss_name, subtitle)
	AudioManager.play(&"boss_sting")
	var p := PerceptionSystem.player
	var ppos := p.global_position if p else Vector3.ZERO
	match kind:
		Kind.CLEANING_DAY:
			var vac := get_node_or_null(vacuum_path) as RobotVacuum
			if vac:
				vac.boss_mode = true
				vac.force_present(true)
				vac.force_alert(AlertState.SEARCHING, ppos)
		Kind.THE_CAT:
			var cat := get_node_or_null(cat_path) as Pet
			if cat:
				cat.force_present(true)
				cat.wake_up()
				cat.force_alert(AlertState.SEARCHING, ppos)
		Kind.EXTERMINATOR:
			var fog := get_node_or_null(fog_path) as FogFront
			if fog:
				fog.start()
			var h := get_node_or_null(human_path) as Human
			if h:
				h.force_present(true)
				h.force_alert(AlertState.SEARCHING, ppos)
			if lvl and lvl.escalation:
				lvl.escalation.force_min_stage(4)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_t += delta
	var p := PerceptionSystem.player
	if p == null:
		return
	var lvl := Level.current
	match kind:
		Kind.CLEANING_DAY:
			if phase == 1 and _t > 10.0:
				phase = 2
				var h := get_node_or_null(human_path) as Human
				if h:
					h.force_present(true)
					h.force_alert(AlertState.SEARCHING, p.global_position)
				if lvl:
					lvl.set_hint("The human is back with the bug spray!")
					if lvl.escalation:
						lvl.escalation.force_min_stage(4)
		Kind.THE_CAT:
			var cat := get_node_or_null(cat_path) as Pet
			if cat == null:
				return
			if phase == 1 and _t > 8.0:
				phase = 2
				cat.boss_speed_mult = 1.25
				cat.force_alert(AlertState.ALERT, p.global_position)
				if lvl:
					lvl.set_hint("The cat is hunting you!")
			elif phase == 2 and lvl and lvl.goal and p.global_position.distance_to(lvl.goal.global_position) < 25.0:
				phase = 3
				cat.attack_cooldown_mult = 0.5
				lvl.set_hint("Final pounce!")
			elif phase >= 2 and _t > 8.0 and cat.alert.state < AlertState.SEARCHING and fmod(_t, 6.0) < delta:
				cat.force_alert(AlertState.SEARCHING, p.global_position)
		Kind.EXTERMINATOR:
			pass
