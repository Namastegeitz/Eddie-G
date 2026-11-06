extends Node3D
## Title screen with a slowly turning bug-scale diorama behind the menu,
## and a trophy shelf showing off the rarest treasures you've found.

const SHELF_SLOTS := 7

var _pivot: Node3D
var _ui: Control
## The treasures on the trophy shelf (they turn slowly).
var shelf_items: Array[Node3D] = []


func _ready() -> void:
	_build_backdrop()
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	UIKit.setup_root(_ui)
	layer.add_child(_ui)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(shade)
	var col := UIKit.column(_ui, 520.0)
	col.add_child(UIKit.title("BUG'S-EYE VIEW", 58))
	col.add_child(UIKit.label("Sneak. Scavenge. Survive the house.", 22, UIKit.DIM))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	col.add_child(spacer)
	var play := UIKit.button("Play", func() -> void: GameManager.goto("level_select"), 76)
	col.add_child(play)
	col.add_child(UIKit.button("Showcase", func() -> void: GameManager.goto("showcase")))
	col.add_child(UIKit.button("Colony", func() -> void: GameManager.goto("colony")))
	col.add_child(UIKit.button("Settings", func() -> void: GameManager.goto("settings")))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		col.add_child(UIKit.button("Quit", func() -> void: GameManager.quit_game()))
	var c := SaveSystem.colony()
	col.add_child(UIKit.label("Colony size %d  -  %d crumbs banked" % [SaveSystem.colony_size(), int(c["banked"])], 18, UIKit.DIM))
	col.add_child(UIKit.label(Collection.summary(), 18, ItemDef.RARITY_COLORS[3] if Collection.by_rarity()[3][0] > 0 else UIKit.DIM))
	play.grab_focus.call_deferred()
	AudioManager.play_music(&"music_ambient")


func _build_backdrop() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.06, 0.05, 0.04)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.8, 0.6)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, 0.6, 0)
	sun.light_color = Color(1.0, 0.85, 0.6)
	add_child(sun)
	_pivot = Node3D.new()
	add_child(_pivot)
	var floor_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(60, 0.5, 60)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.25
	floor_mesh.material_override = _mat(Color(0.32, 0.27, 0.2))
	_pivot.add_child(floor_mesh)
	# A giant crumb and a fork for scale, plus each unlocked bug.
	var crumb := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 1.2
	cm.height = 1.8
	crumb.mesh = cm
	crumb.position = Vector3(2.5, 0.6, -1.0)
	crumb.material_override = _mat(Color(0.85, 0.65, 0.3))
	_pivot.add_child(crumb)
	var fork := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(1.2, 0.3, 18)
	fork.mesh = fm
	fork.position = Vector3(-4, 0.15, 0)
	fork.rotation.y = 0.4
	fork.material_override = _mat(Color(0.75, 0.75, 0.78))
	_pivot.add_child(fork)
	var x := -1.5
	for id in GameManager.BUG_IDS:
		var stats := GameManager.get_bug_stats(id)
		if stats == null or not SaveSystem.is_bug_unlocked(id):
			continue
		var bug := (load(stats.scene_path) as PackedScene).instantiate() as Node3D
		bug.process_mode = Node.PROCESS_MODE_DISABLED
		bug.position = Vector3(x, 0.4, 1.5)
		bug.rotation.y = 0.6
		_pivot.add_child(bug)
		x += 2.0
	_build_shelf()
	var cam := Camera3D.new()
	cam.position = Vector3(0, 3.2, 8.5)
	cam.rotation.x = -0.32
	cam.fov = 55
	add_child(cam)
	cam.current = true


## A wooden shelf behind the bugs with your rarest finds standing on it,
## each over a ring in its rarity's colour; empty spots wait for more.
func _build_shelf() -> void:
	var shelf := Node3D.new()
	shelf.name = "TrophyShelf"
	shelf.position = Vector3(0, 0, -3.2)
	_pivot.add_child(shelf)
	var plank := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(SHELF_SLOTS * 1.6 + 0.6, 0.25, 1.6)
	plank.mesh = pm
	plank.position.y = 1.2
	plank.material_override = _mat(Color(0.45, 0.3, 0.17))
	shelf.add_child(plank)
	for x in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.25, 1.2, 1.4)
		leg.mesh = lm
		leg.position = Vector3(x * (SHELF_SLOTS * 0.8 + 0.1), 0.6, 0)
		leg.material_override = plank.material_override
		shelf.add_child(leg)
	var best := Collection.best_found(SHELF_SLOTS)
	for i in SHELF_SLOTS:
		var x := (i - (SHELF_SLOTS - 1) * 0.5) * 1.6
		if i < best.size():
			var item := (load("res://scenes/items/%s.tscn" % best[i]) as PackedScene).instantiate() as Node3D
			item.process_mode = Node.PROCESS_MODE_DISABLED
			item.scale = Vector3.ONE * 0.5
			item.position = Vector3(x, 1.33, 0)
			var beam := item.get_node_or_null("Beam") as Node3D
			if beam:
				beam.visible = false
			shelf.add_child(item)
			shelf_items.append(item)
		else:
			var stand := MeshInstance3D.new()
			var sm := CylinderMesh.new()
			sm.top_radius = 0.35
			sm.bottom_radius = 0.42
			sm.height = 0.12
			stand.mesh = sm
			stand.position = Vector3(x, 1.38, 0)
			stand.material_override = _mat(Color(0.22, 0.17, 0.12))
			shelf.add_child(stand)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


func _process(delta: float) -> void:
	if _pivot:
		_pivot.rotate_y(delta * 0.12)
	for it in shelf_items:
		var v := it.get_node_or_null("Visual") as Node3D
		if v:
			v.rotate_y(delta * 0.9)
