class_name Level
extends Node3D
## Root of every level scene. Spawns the chosen bug and camera, starts the
## household clock, counts crumbs, opens the goal, triggers the boss chase,
## tracks the run, and hands the result to GameManager.

signal crumbs_changed(got: int, needed: int)
signal objective_changed(text: String)
signal hint_changed(text: String)
signal boss_announced(title: String, subtitle: String)
signal close_call
## Bug food or a crumb gem was picked up (the HUD shows what it does).
signal item_picked(def: ItemDef)

static var current: Level = null

const HUD_SCENE := "res://scenes/ui/hud.tscn"
const PAUSE_SCENE := "res://scenes/ui/pause_menu.tscn"
const RESULT_SCENE := "res://scenes/ui/result_screen.tscn"
const CAMERA_SCENE := "res://scenes/camera/follow_camera.tscn"
const SWATTER_SCENE := "res://scenes/hazards/swatter.tscn"
const SPRAY_SCENE := "res://scenes/hazards/spray_cloud.tscn"
const RIPPLE_SCENE := "res://scenes/fx/ripple.tscn"
const PROP_AWAKE_CAP := 8
const PROP_WAKE_RADIUS := 14.0

@export var level_id: StringName = &"kitchen"

var config: LevelConfig
var player: BugBase
var camera: FollowCamera
var run: RunStats
var crumbs_got := 0
var crumbs_needed := 0
var goal: Goal
var boss: BossDirector
var escalation: EscalationDirector
var intensity := 0.0
var swatter_pool: NodePool
var spray_pool: NodePool
var ripple_pool: NodePool
var finished := false
## {merged, batches} from the static mesh batcher (draw-call reduction).
var batch_stats: Dictionary = {}
var _elapsed := 0.0
var _sun: DirectionalLight3D
var _env: WorldEnvironment
var _bg_base := Color(0.1, 0.1, 0.1)
var _prop_timer := 0.0
var _props: Array[PhysicsProp] = []


func _ready() -> void:
	current = self
	GameManager.level_node = self
	if GameManager.current_level != level_id:
		GameManager.current_level = level_id
	config = GameManager.get_level(level_id)
	if config == null:
		config = LevelConfig.new()
	var pools := Node3D.new()
	pools.name = "Pools"
	add_child(pools)
	swatter_pool = NodePool.from_scene(load(SWATTER_SCENE), pools, 2)
	spray_pool = NodePool.from_scene(load(SPRAY_SCENE), pools, 3)
	ripple_pool = NodePool.from_scene(load(RIPPLE_SCENE), pools, 8)
	batch_stats = StaticBatcher.batch(self)
	_spawn_player()
	_spawn_camera()
	PerceptionSystem.begin_level(player, 0.7, config.ambient_noise)
	HouseClock.start(config.routine, HouseClock.slot_hour(GameManager.current_time_slot))
	HouseClock.routine_changed.connect(_update_ambient)
	HouseClock.hour_changed.connect(_on_hour)
	var normal := 0
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		var crumb := c as Crumb
		if crumb and is_ancestor_of(crumb):
			crumb.collected.connect(_on_crumb_collected)
			if not crumb.golden:
				normal += 1
	crumbs_needed = mini(config.crumbs_required, normal)
	for t in get_tree().get_nodes_in_group(Phys.GROUP_PET):
		if is_ancestor_of(t):
			(t as Threat).awareness = config.animal_awareness
	for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		var item := it as PickupItem
		if item and is_ancestor_of(item):
			item.collected.connect(_on_item_collected)
	goal = find_child("Goal", true, false) as Goal
	if goal:
		goal.reached.connect(_on_goal_reached)
	boss = find_child("BossDirector", true, false) as BossDirector
	escalation = find_child("EscalationDirector", true, false) as EscalationDirector
	if escalation == null:
		escalation = EscalationDirector.new()
		escalation.name = "EscalationDirector"
		add_child(escalation)
	_sun = find_child("Sun", true, false) as DirectionalLight3D
	_env = find_child("Environment", true, false) as WorldEnvironment
	if _env and _env.environment:
		_bg_base = _env.environment.background_color
	refresh_quality()
	for p in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		if p is PhysicsProp:
			_props.append(p)
	run = RunStats.new()
	run.level_id = level_id
	run.bug_id = player.stats.id
	run.crumbs_required = crumbs_needed
	GameManager.begin_run(run)
	player.died.connect(_on_player_died)
	player.hit_taken.connect(func(_left: int) -> void: run.hits_taken += 1)
	PerceptionSystem.alert_level_changed.connect(_on_alert_changed)
	PerceptionSystem.threat_stunned.connect(_on_threat_stunned)
	_spawn_ui()
	GameManager.set_state(GameManager.State.PLAYING)
	InputRouter.set_enabled(true)
	AudioManager.play_music(&"music_ambient")
	_update_ambient()
	crumbs_changed.emit(crumbs_got, crumbs_needed)
	objective_changed.emit("Collect %d crumbs" % crumbs_needed)
	_maybe_show_guide()


func _exit_tree() -> void:
	if current == self:
		current = null
	PerceptionSystem.end_level()
	HouseClock.stop()
	InputRouter.set_enabled(false)
	Engine.time_scale = 1.0
	AudioServer.playback_speed_scale = 1.0
	if GameManager.level_node == self:
		GameManager.level_node = null


func _on_hour(_h: float) -> void:
	_update_ambient()


func _spawn_player() -> void:
	var stats := GameManager.build_bug_stats(GameManager.current_bug)
	var scene := load(stats.scene_path) as PackedScene
	player = scene.instantiate() as BugBase
	player.stats = stats
	add_child(player)
	var spawn := find_child("PlayerSpawn", true, false) as Node3D
	if spawn:
		player.global_transform = spawn.global_transform


func _spawn_camera() -> void:
	camera = (load(CAMERA_SCENE) as PackedScene).instantiate() as FollowCamera
	add_child(camera)
	camera.set_target(player)


## After a quality change (Settings or auto quality).
func refresh_quality() -> void:
	var q := GameManager.quality()
	if _sun:
		_sun.shadow_enabled = GameManager.shadows_enabled()
		# High: two shadow cascades (crisp up close) and softer edges.
		_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if q == "high" else DirectionalLight3D.SHADOW_ORTHOGONAL
		_sun.shadow_blur = 1.5 if q == "high" else 1.0
	if _env and _env.environment:
		var e := _env.environment
		# A soft glow around bright things (gems, lamps, the firefly) on high.
		e.glow_enabled = q == "high"
		e.glow_intensity = 0.55
		e.glow_strength = 0.9
		e.glow_bloom = 0.04
		e.glow_hdr_threshold = 0.95
		e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		# A faint haze gives the giant rooms depth (cheap on every setting).
		e.fog_enabled = true
		e.fog_light_color = Color(_bg_base.r, _bg_base.g, _bg_base.b).lerp(Color(0.8, 0.78, 0.74), 0.5)
		e.fog_light_energy = 0.6
		e.fog_density = 0.0016
		e.fog_sky_affect = 0.0


## First time with this bug: show how to play it (the game waits).
func _maybe_show_guide() -> void:
	if GameManager.guides_enabled and player and not SaveSystem.has_seen_guide(player.stats.id):
		show_bug_guide()


func show_bug_guide() -> BugGuide:
	var g := BugGuide.new()
	g.name = "BugGuide"
	g.stats = player.stats
	g.labels = player.action_labels()
	add_child(g)
	get_tree().paused = true
	var id := player.stats.id
	g.closed.connect(func() -> void:
		SaveSystem.mark_guide_seen(id)
		SaveSystem.save_game()
		if GameManager.state == GameManager.State.PLAYING:
			get_tree().paused = false)
	return g


func _spawn_ui() -> void:
	for path in [HUD_SCENE, PAUSE_SCENE, RESULT_SCENE]:
		var ui: Node = (load(path) as PackedScene).instantiate()
		add_child(ui)
		if ui.has_method("bind"):
			ui.call("bind", self)


func _physics_process(delta: float) -> void:
	if finished:
		return
	_elapsed += delta
	run.time = _elapsed
	intensity = clampf(_elapsed / config.intensity_ramp_seconds, 0.0, 1.0)
	_prop_timer -= delta
	if _prop_timer <= 0.0:
		_prop_timer = 0.5
		_prop_budget()


## Hazards get faster as the run goes on (the slow time-based floor).
func hazard_speed() -> float:
	return 1.0 + intensity * PerceptionSystem.config.intensity_speedup


# --- Objectives -----------------------------------------------------------

func _on_crumb_collected(c: Crumb) -> void:
	if c.golden:
		run.golden = true
		set_hint("Golden Crumb!")
	else:
		# Double Crumbs: each one counts twice.
		crumbs_got += 2 if player and player.has_effect(&"double") else 1
		run.crumbs = crumbs_got
	crumbs_changed.emit(crumbs_got, crumbs_needed)
	_check_goal()


## Power-ups left to find in this room.
func powerups_left() -> int:
	var n := 0
	for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		var pi := it as PickupItem
		if pi and is_ancestor_of(pi) and pi.is_power() and not pi.taken:
			n += 1
	return n


## Bug food and crumb gems.
func _on_item_collected(item: PickupItem) -> void:
	if item.def == null or player == null:
		return
	PowerUps.apply(item.def, player)
	if run:
		if item.is_power():
			run.powerups += 1
			run.power_points += item.def.points
		elif item.is_gem():
			if not SaveSystem.has_collectible(item.def.id):
				run.new_treasures.append(item.def.id)
			run.gems.append(item.def.id)
			run.gem_points += item.def.points
			SaveSystem.record_gem(item.def.id)
		elif item.is_treasure():
			run.treasures.append(item.def.id)
			run.treasure_points += item.def.points
			run.best_rarity = maxi(run.best_rarity, item.def.rarity)
			if SaveSystem.record_treasure(item.def.id):
				run.new_treasures.append(item.def.id)
		else:
			run.foods_eaten += 1
			run.food_points += item.def.points
	item_picked.emit(item.def)


const MAX_DROPPED_CRUMBS := 12
var _dropped_crumbs := 0


## True if a crumb at `pos` would sit on open floor (not inside furniture).
func is_open_floor(pos: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.8
	q.shape = sphere
	q.transform = Transform3D(Basis.IDENTITY, pos + Vector3.UP * 0.4)
	q.collision_mask = Phys.WORLD
	if not space.intersect_shape(q, 1).is_empty():
		return false
	var ray := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.5, pos + Vector3.DOWN * 1.5, Phys.WORLD)
	return not space.intersect_ray(ray).is_empty()


## A crumb dropped during play (the cook's pan, a snacker's plate). Returns
## null if the spot isn't open floor or enough crumbs have been dropped.
func spawn_crumb(pos: Vector3) -> Crumb:
	if _dropped_crumbs >= MAX_DROPPED_CRUMBS or not is_open_floor(pos):
		return null
	_dropped_crumbs += 1
	var c := (load("res://scenes/world/crumb.tscn") as PackedScene).instantiate() as Crumb
	c.name = "DroppedCrumb%d" % _dropped_crumbs
	var parent := find_child("Pickups", false, false)
	(parent if parent else self).add_child(c)
	c.global_position = pos
	c.collected.connect(_on_crumb_collected)
	return c


## Kibble and other big meals count as several crumbs.
func add_bonus_crumbs(n: int) -> void:
	if n <= 0:
		return
	crumbs_got += n
	if run:
		run.crumbs = crumbs_got
	crumbs_changed.emit(crumbs_got, crumbs_needed)
	_check_goal()


func _check_goal() -> void:
	if goal and crumbs_got >= crumbs_needed and not goal.active:
		goal.set_active(true)
		AudioManager.play(&"goal_open")
		objective_changed.emit("Escape through the %s!" % goal.label)
		if boss:
			boss.start()


func _on_goal_reached() -> void:
	_finish(true, &"escaped")


func _on_player_died(cause: StringName) -> void:
	if finished:
		return
	InputRouter.set_enabled(false)
	await get_tree().create_timer(1.0).timeout
	_finish(false, cause)


func _finish(won: bool, cause: StringName) -> void:
	if finished:
		return
	finished = true
	InputRouter.set_enabled(false)
	HouseClock.running = false
	AudioManager.play(&"win" if won else &"lose")
	GameManager.finish_run(won, cause)


# --- Score hooks ------------------------------------------------------------

func note_lure_used() -> void:
	if run:
		run.lures_used += 1


func note_pester() -> void:
	if run and not finished:
		run.pesters += 1


func note_close_call() -> void:
	if run and not finished:
		run.close_calls += 1
		close_call.emit()
		AudioManager.play(&"whoosh", -4.0)


func _on_threat_stunned(_t: Node) -> void:
	if run and not finished:
		run.threats_stunned += 1
		set_hint("Threat stunned!")


func _on_alert_changed(level: int) -> void:
	if level == AlertState.ALERT and run:
		run.ever_alerted = true


func announce_boss(title: String, subtitle: String) -> void:
	boss_announced.emit(title, subtitle)


func set_hint(text: String) -> void:
	hint_changed.emit(text)


# --- Atmosphere -------------------------------------------------------------

func _update_ambient() -> void:
	var amb := float(config.ambient_light_by_period.get(HouseClock.period(), 0.7))
	if HouseClock.is_active(&"lights_out"):
		amb = minf(amb, 0.2)
	PerceptionSystem.ambient_light = amb
	if _env and _env.environment:
		_env.environment.ambient_light_energy = lerpf(0.15, 0.6, amb)
		_env.environment.background_color = Color(_bg_base.r, _bg_base.g, _bg_base.b) * lerpf(0.2, 1.0, amb)
	if _sun:
		_sun.light_energy = 0.1 + amb * 0.75


## Keeps at most PROP_AWAKE_CAP far-away props simulating; nearby props wake.
func _prop_budget() -> void:
	if player == null:
		return
	var awake: Array[PhysicsProp] = []
	for p in _props:
		if not is_instance_valid(p):
			continue
		var d := p.global_position.distance_to(player.global_position)
		if p.freeze and d < PROP_WAKE_RADIUS:
			p.freeze = false
		elif not p.freeze and not p.sleeping:
			awake.append(p)
	if awake.size() <= PROP_AWAKE_CAP:
		return
	var ppos := player.global_position
	awake.sort_custom(func(a: PhysicsProp, b: PhysicsProp) -> bool:
		return a.global_position.distance_squared_to(ppos) > b.global_position.distance_squared_to(ppos))
	for i in awake.size() - PROP_AWAKE_CAP:
		if awake[i].global_position.distance_to(ppos) > PROP_WAKE_RADIUS:
			awake[i].freeze = true
