class_name EscalationDirector
extends Node
## The escalation chain. A human who spots you escalates in stages:
##   1 Shout (nearby threats get suspicious) -> 2 Swatter -> 3 Calls the pet
##   -> 4 Bug spray. Staying hidden calms things down one stage at a time.

signal stage_changed(stage: int)

const MAX_STAGE := 4

var stage := 0
var _calm := 0.0
var _since_escalate := 99.0
var _forced_min := 0
var cfg: StealthConfig


func _ready() -> void:
	cfg = PerceptionSystem.config
	_hook.call_deferred()


func _hook() -> void:
	for h in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
		var human := h as Human
		if human:
			human.alert.changed.connect(_on_human_alert.bind(human))


func _on_human_alert(state: int, human: Human) -> void:
	if state == AlertState.ALERT:
		escalate(human)


func escalate(human: Human) -> void:
	if stage >= MAX_STAGE or _since_escalate < cfg.escalation_min_interval:
		return
	_since_escalate = 0.0
	_calm = 0.0
	_set_stage(stage + 1, human)


## Bosses can pin a minimum stage (e.g. the exterminator always sprays).
func force_min_stage(s: int) -> void:
	_forced_min = s
	if stage < s:
		_set_stage(s, null)


func _set_stage(s: int, by: Human) -> void:
	stage = clampi(s, 0, MAX_STAGE)
	PerceptionSystem.set_escalation(stage)
	stage_changed.emit(stage)
	for h in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
		(h as Human).escalation_stage = stage
	if by == null:
		return
	var target := by.alert.last_known
	match stage:
		1:
			by.shout()
			PerceptionSystem.alert_threats_near(by.global_position, cfg.shout_radius, AlertState.SUSPICIOUS, target)
		3:
			by.call_pet()
			for p in get_tree().get_nodes_in_group(Phys.GROUP_PET):
				(p as Threat).force_alert(AlertState.SEARCHING, target)


func _physics_process(delta: float) -> void:
	_since_escalate += delta
	# Staying in plain sight of a human keeps escalating.
	if stage < MAX_STAGE and _since_escalate >= cfg.escalation_min_interval * 2.0:
		for h in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
			var human := h as Human
			if human and human.present and human.alert.state == AlertState.ALERT:
				escalate(human)
				break
	if stage <= _forced_min:
		_calm = 0.0
		return
	if PerceptionSystem.max_alert >= AlertState.SEARCHING:
		_calm = 0.0
	else:
		_calm += delta
		if _calm >= cfg.escalation_calm_time:
			_calm = 0.0
			_set_stage(stage - 1, null)
