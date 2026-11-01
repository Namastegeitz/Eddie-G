class_name Hazard
extends Node3D
## Base for telegraphed strikes. A ring warns where the strike will land,
## then the impact is resolved by distance (cheap and deterministic): hit the
## player, count close calls, clang off rebounders, stun other threats.

signal impacted(hazard: Hazard, position: Vector3)

@export var impact_radius: float = 2.5
@export var hit_cause: StringName = &"swatted"
@export var impact_strength: float = 0.8
## Strikes that land on a hanging pan / metal pot bounce back and stun the owner.
@export var can_rebound: bool = true
## Hitting another threat (the cat under the swatter) stuns it.
@export var stuns_threats: bool = true

var owner_threat: Threat = null
var busy := false
var _ring: MeshInstance3D
var _disc: MeshInstance3D


func _ready() -> void:
	_ring = Fx.make_ring()
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)
	_disc = Fx.make_disc(Color(1.0, 0.2, 0.05, 0.35))
	_disc.top_level = true
	_disc.visible = false
	add_child(_disc)
	_setup()


func _setup() -> void:
	pass


## progress 0..1: the ring shrinks onto the target while the shadow darkens.
func show_telegraph(pos: Vector3, radius: float, progress: float) -> void:
	var p := pos + Vector3.UP * 0.08
	var r := radius * lerpf(2.2, 1.0, clampf(progress, 0.0, 1.0))
	_ring.visible = true
	_ring.global_transform = Transform3D(Basis.from_scale(Vector3(r, 0.15, r)), p)
	_disc.visible = true
	_disc.global_transform = Transform3D(Basis.from_scale(Vector3(radius, 1.0, radius)), p)
	_disc.transparency = 1.0 - clampf(progress, 0.0, 1.0) * 0.9


func hide_telegraph() -> void:
	_ring.visible = false
	_disc.visible = false


## Resolves this hazard's impact. Returns false if it rebounded.
func resolve_impact(pos: Vector3) -> bool:
	hide_telegraph()
	if can_rebound and Hazard.find_rebounder(pos) != null:
		AudioManager.play_at(&"clang", pos, 2.0)
		Feedback.impact_at(pos, impact_strength)
		if owner_threat:
			owner_threat.stun()
		impacted.emit(self, pos)
		return false
	Hazard.apply_strike(pos, impact_radius, hit_cause, owner_threat, stuns_threats, _player_in_zone)
	Feedback.impact_at(pos, impact_strength)
	impacted.emit(self, pos)
	return true


## Default zone test: a vertical cylinder around the impact point.
func _player_in_zone(p: BugBase, pos: Vector3, radius: float) -> bool:
	var flat := Vector2(p.global_position.x - pos.x, p.global_position.z - pos.z).length()
	var dy := p.global_position.y - pos.y
	return flat <= radius and dy > -1.5 and dy < 3.5


static func find_rebounder(pos: Vector3) -> Rebounder:
	var tree := Engine.get_main_loop() as SceneTree
	for n in tree.get_nodes_in_group(Phys.GROUP_REBOUNDER):
		var r := n as Rebounder
		if r and Vector2(r.global_position.x - pos.x, r.global_position.z - pos.z).length() <= r.radius \
				and absf(r.global_position.y - pos.y) < 12.0:
			return r
	return null


## Shared strike resolution (used by hazards and pet pounces).
static func apply_strike(pos: Vector3, radius: float, cause: StringName, owner: Threat,
		stun_others: bool, zone_test: Callable = Callable()) -> bool:
	var hit := false
	var p := PerceptionSystem.player
	if p and not p.dead:
		var inside: bool
		if zone_test.is_valid():
			inside = zone_test.call(p, pos, radius)
		else:
			var flat := Vector2(p.global_position.x - pos.x, p.global_position.z - pos.z).length()
			inside = flat <= radius and absf(p.global_position.y - pos.y) < 3.5
		if inside:
			hit = p.take_hit(cause, pos)
		if not hit and Level.current:
			var flat2 := Vector2(p.global_position.x - pos.x, p.global_position.z - pos.z).length()
			if flat2 <= radius + PerceptionSystem.config.close_call_margin and absf(p.global_position.y - pos.y) < 4.0:
				Level.current.note_close_call()
		if p is Spider:
			(p as Spider).on_vibration(pos)
	if stun_others:
		for t in PerceptionSystem.threats:
			if t != owner and t.present and t.stun_time <= 0.0 \
					and Vector2(t.global_position.x - pos.x, t.global_position.z - pos.z).length() <= radius + 1.5 \
					and absf(t.global_position.y - pos.y) < 6.0:
				t.stun()
	return hit
