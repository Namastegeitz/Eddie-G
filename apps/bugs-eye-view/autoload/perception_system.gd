extends Node
## Single source of truth for how detectable the player is right now:
##   visibility (light x motion x camo), noise events, and the scent trail.
## Threats read the player only through this system plus their own senses.

signal noise_emitted(position: Vector3, loudness: float, from_player: bool)
signal strike_incoming(position: Vector3, time_to_impact: float, radius: float)
signal alert_level_changed(level: int)
signal escalation_changed(stage: int)
signal threat_stunned(threat: Node)
## The house-wide alarm gauge filled: every threat is alerted.
signal alarm_raised
## The gauge drained back down: the alarm is called off.
signal alarm_cleared

const CONFIG_PATH := "res://resources/config/stealth_config.tres"

var config: StealthConfig
var player: BugBase = null
var threats: Array[Threat] = []
var scent: ScentTrail
var visibility: float = 0.0
var light_level: float = 0.7
var player_loudness: float = 0.0
var ambient_light: float = 0.7
var ambient_noise_floor: float = 0.0
var max_alert: int = 0
var escalation_stage: int = 0
## 0..1 house-wide alarm. Fills while threats see or hear you; full = alarm.
var alarm: float = 0.0
var alarm_active: bool = false
var _since_noticed := 99.0

var _light_zones: Array[LightZone] = []
var _noise_sources: Array[AmbientNoise] = []
var _alert_timer := 0.0
var _loud_decay := 0.0


func _ready() -> void:
	config = load(CONFIG_PATH) if ResourceLoader.exists(CONFIG_PATH) else StealthConfig.new()
	scent = ScentTrail.new(config)


func begin_level(p: BugBase, amb_light: float, amb_noise: float) -> void:
	player = p
	ambient_light = amb_light
	ambient_noise_floor = amb_noise
	scent.clear()
	visibility = 0.0
	max_alert = 0
	escalation_stage = 0
	_reset_alarm()


func end_level() -> void:
	player = null
	threats.clear()
	_light_zones.clear()
	_noise_sources.clear()
	scent.clear()
	max_alert = 0
	escalation_stage = 0
	_reset_alarm()
	AudioManager.set_tension(0.0)


# --- Registration ---------------------------------------------------------

func register_threat(t: Threat) -> void:
	if not threats.has(t):
		threats.append(t)


func unregister_threat(t: Threat) -> void:
	threats.erase(t)


func player_entered_light(z: LightZone) -> void:
	if not _light_zones.has(z):
		_light_zones.append(z)


func player_exited_light(z: LightZone) -> void:
	_light_zones.erase(z)


func register_noise_source(s: AmbientNoise) -> void:
	if not _noise_sources.has(s):
		_noise_sources.append(s)


func unregister_noise_source(s: AmbientNoise) -> void:
	_noise_sources.erase(s)


# --- Queries --------------------------------------------------------------

## Highest-priority active zone wins (a shadow under the table beats the room
## light); ties take the brighter zone. No zone = the level's ambient light.
func get_light_level() -> float:
	var best: LightZone = null
	for z in _light_zones:
		if not z.is_active():
			continue
		if best == null or z.zone_priority > best.zone_priority \
				or (z.zone_priority == best.zone_priority and z.light_level > best.light_level):
			best = z
	if best == null:
		return ambient_light
	return config.light_value(best.light_level)


func get_ambient_noise_at(pos: Vector3) -> float:
	var n := ambient_noise_floor
	for s in _noise_sources:
		if s.is_active() and s.global_position.distance_to(pos) <= s.radius:
			n = maxf(n, s.level)
	return n


func is_player_hidden() -> bool:
	return player != null and player.is_hidden_safe()


# --- Per frame ------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	light_level = get_light_level()
	visibility = player.compute_visibility(light_level, config)
	scent.update(player.global_position, delta, player.is_scent_active(), player.scent_strength())
	_loud_decay -= delta
	if _loud_decay <= 0.0:
		player_loudness = 0.0
	_tick_alarm(delta)
	_alert_timer -= delta
	if _alert_timer <= 0.0:
		_alert_timer = 0.2
		_update_max_alert()


func _update_max_alert() -> void:
	var m := 0
	for t in threats:
		if t.present:
			m = maxi(m, t.alert.state)
	if m != max_alert:
		max_alert = m
		alert_level_changed.emit(m)
	var tension := 0.0
	match max_alert:
		AlertState.SUSPICIOUS:
			tension = 0.25
		AlertState.SEARCHING:
			tension = 0.55
		AlertState.ALERT:
			tension = 1.0
	AudioManager.set_tension(maxf(maxf(tension, escalation_stage * 0.15), alarm * 0.7))


# --- Events -----------------------------------------------------------------

## Player footsteps/buzz. Ambient noise near the player masks it.
func emit_player_noise(pos: Vector3, raw_loudness: float) -> void:
	var masked := maxf(0.0, raw_loudness - get_ambient_noise_at(pos) * config.mask_strength)
	player_loudness = masked
	_loud_decay = config.noise_interval * 1.5
	if masked <= 0.01:
		return
	noise_emitted.emit(pos, masked, true)
	for t in threats:
		t.hear(pos, masked, true)


## Lures, falling props, clatter: threats investigate these instead of you.
func emit_world_noise(pos: Vector3, loudness: float) -> void:
	noise_emitted.emit(pos, loudness, false)
	for t in threats:
		t.hear(pos, loudness, false)


func warn_strike(pos: Vector3, time_to_impact: float, radius: float) -> void:
	strike_incoming.emit(pos, time_to_impact, radius)


func alert_threats_near(pos: Vector3, radius: float, state: int, target: Vector3) -> void:
	for t in threats:
		if t.present and t.global_position.distance_to(pos) <= radius:
			t.force_alert(state, target)


func set_escalation(stage: int) -> void:
	if stage != escalation_stage:
		escalation_stage = stage
		escalation_changed.emit(stage)


func notify_stunned(t: Node) -> void:
	threat_stunned.emit(t)


# --- Alarm gauge ------------------------------------------------------------------

func _reset_alarm() -> void:
	alarm = 0.0
	alarm_active = false
	_since_noticed = 99.0


func add_alarm_from_sight(amount: float) -> void:
	_add_alarm(amount * config.alarm_sight_gain)


func add_alarm_from_sound(amount: float) -> void:
	_add_alarm(amount * config.alarm_sound_gain)


func _add_alarm(amount: float) -> void:
	if player == null or player.dead or amount <= 0.0 or player.has_effect(&"calm"):
		return
	alarm = minf(alarm + amount, 1.0)
	_since_noticed = 0.0
	if alarm >= 1.0 and not alarm_active:
		raise_alarm()


## Full alarm: every threat in the house drops what it's doing and comes for you.
func raise_alarm() -> void:
	alarm = 1.0
	alarm_active = true
	_since_noticed = 0.0
	var target := player.global_position if player else Vector3.ZERO
	for t in threats:
		if t.present:
			t.force_alert(AlertState.ALERT, target)
	AudioManager.play(&"boss_sting", -6.0, 1.4)
	Feedback.rumble(0.5, 0.3)
	alarm_raised.emit()


## Emerald gem: the alarm empties and everyone stops looking for you.
func calm_down() -> void:
	alarm = 0.0
	_since_noticed = 99.0
	for t in threats:
		if t.present and t.alert.state > AlertState.UNAWARE:
			t.alert.reset()
	if alarm_active:
		alarm_active = false
		alarm_cleared.emit()


func _tick_alarm(delta: float) -> void:
	_since_noticed += delta
	if _since_noticed < config.alarm_grace or alarm <= 0.0:
		return
	var rate := config.alarm_decay
	if player and player.is_hidden_safe():
		rate *= config.alarm_hidden_decay_mult
	alarm = maxf(alarm - rate * delta, 0.0)
	if alarm_active and alarm <= config.alarm_clear_level:
		alarm_active = false
		alarm_cleared.emit()
