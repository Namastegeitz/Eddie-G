extends Node3D
## The nest under the floorboards. Deliver crumbs, watch the colony grow, and
## buy upgrades that carry into every run.

const MAX_VISIBLE_BUGS := 30

var _list: VBoxContainer
var _status: Label
var _bugs: Array[Node3D] = []
var _t := 0.0


func _ready() -> void:
	_build_world()
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	UIKit.setup_root(ui)
	layer.add_child(ui)
	var col := UIKit.column(ui, 600.0, 10)
	col.add_child(UIKit.title("THE COLONY", 44))
	_status = UIKit.label("", 22, UIKit.TEXT)
	col.add_child(_status)
	col.add_child(UIKit.label("Every 10 crumbs delivered grows the colony. Upgrades apply to every run.", 17, UIKit.DIM))
	_list = UIKit.vbox(10)
	col.add_child(_list)
	col.add_child(UIKit.button("Play", func() -> void: GameManager.goto("level_select"), 70))
	col.add_child(UIKit.button("Main menu", func() -> void: GameManager.goto("main_menu")))
	_refresh()


func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.035, 0.025)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.75, 0.45)
	e.ambient_light_energy = 0.5
	env.environment = e
	add_child(env)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 6, 2)
	lamp.light_color = Color(1.0, 0.7, 0.35)
	lamp.light_energy = 2.0
	lamp.omni_range = 30
	add_child(lamp)
	var mound := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 4.0
	sm.height = 3.5
	mound.mesh = sm
	mound.position = Vector3(0, -0.4, 0)
	mound.material_override = _mat(Color(0.35, 0.24, 0.14))
	add_child(mound)
	var ground := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(40, 0.5, 40)
	ground.mesh = gm
	ground.position.y = -1.2
	ground.material_override = _mat(Color(0.22, 0.15, 0.09))
	add_child(ground)
	var n := mini(SaveSystem.colony_size() + 2, MAX_VISIBLE_BUGS)
	var body := CapsuleMesh.new()
	body.radius = 0.18
	body.height = 0.8
	for i in n:
		var b := MeshInstance3D.new()
		b.mesh = body
		b.rotation.x = PI * 0.5
		b.material_override = _mat(Color(0.4, 0.24, 0.1).lerp(Color(0.55, 0.35, 0.15), randf()))
		var holder := Node3D.new()
		holder.add_child(b)
		holder.set_meta(&"phase", randf() * TAU)
		holder.set_meta(&"r", randf_range(4.5, 9.0))
		add_child(holder)
		_bugs.append(holder)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 7, 13)
	cam.rotation.x = -0.5
	add_child(cam)
	cam.current = true


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


func _process(delta: float) -> void:
	_t += delta
	for b in _bugs:
		var ph := float(b.get_meta(&"phase"))
		var r := float(b.get_meta(&"r"))
		var a := ph + _t * (2.5 / r)
		b.position = Vector3(cos(a) * r, -0.85, sin(a) * r)
		b.rotation.y = -a


func _refresh() -> void:
	var c := SaveSystem.colony()
	_status.text = "Colony size %d   -   %d crumbs banked" % [SaveSystem.colony_size(), int(c["banked"])]
	for ch in _list.get_children():
		ch.queue_free()
	for u in GameManager.get_upgrades():
		_list.add_child(_upgrade_card(u))


func _upgrade_card(u: UpgradeDef) -> Control:
	var p := UIKit.panel()
	var v := UIKit.vbox(4)
	p.add_child(v)
	var owned := SaveSystem.has_upgrade(u.id)
	v.add_child(UIKit.label(u.display_name.to_upper(), 24, UIKit.GOLD if owned else UIKit.TEXT))
	var who := "All bugs" if u.applies_to.is_empty() else ", ".join(u.applies_to).capitalize()
	v.add_child(UIKit.label("%s  (%s)" % [u.description, who], 17, UIKit.DIM))
	if owned:
		v.add_child(UIKit.label("Owned", 18, UIKit.GREEN))
		return p
	var size_ok := SaveSystem.colony_size() >= u.required_colony
	var afford := int(SaveSystem.colony()["banked"]) >= u.cost
	var b := UIKit.button("Buy - %d crumbs" % u.cost, func() -> void:
		if SaveSystem.spend_crumbs(u.cost):
			SaveSystem.add_upgrade(u.id)
			SaveSystem.save_game()
			AudioManager.play(&"golden")
			_refresh(), 56)
	b.disabled = not (size_ok and afford)
	v.add_child(b)
	if not size_ok:
		v.add_child(UIKit.label("Needs colony size %d" % u.required_colony, 16, UIKit.RED))
	return p
