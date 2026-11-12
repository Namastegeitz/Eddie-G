class_name ModelView
extends SubViewportContainer
## A detailed 3D model of an animal (content/models.json "animals"), turning
## slowly on the home and animal screens: it breathes, looks about and now
## and then gives a little hop. Used instead of the drawn portrait when the
## animal has a model.

var _pivot: Node3D
var _model: Node3D
var _cam: Camera3D
var _t := 0.0
# now and then it looks right at you and pulls a silly face (Settings > Silly faces)
var _silly: SillyFaces
var _face: Node3D
var _anchor: Node3D
var _face_size := 0.25


static func has_for(animal_id: String) -> bool:
	return Models3D.has_model(String(Content.models.get("animals", {}).get(animal_id, "")))


static func make(animal_id: String, px: Vector2) -> ModelView:
	var v := ModelView.new()
	v._build(animal_id, px)
	return v


func _build(animal_id: String, px: Vector2) -> void:
	custom_minimum_size = px
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X if Gfx.level() == "high" else Viewport.MSAA_2X
	vp.size = Vector2i(px)
	add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.95, 0.88)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, 35, 0)
	key.light_energy = 1.25
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 200, 0)
	rim.light_energy = 0.55
	rim.light_color = Color(0.85, 0.95, 1.0)
	vp.add_child(rim)
	_pivot = Node3D.new()
	vp.add_child(_pivot)
	var id := String(Content.models.get("animals", {}).get(animal_id, ""))
	_model = Models3D.creature({"model": id, "yaw": 0.0}, 1.0)
	_pivot.add_child(_model)
	# frame it: the camera backs off to fit the model's height and width
	var h := float(_model.get_meta("height", 1.0))
	var r := maxf(h, 1.0) * 0.5
	var cam := Camera3D.new()
	cam.fov = 32.0
	cam.position = Vector3(0, h * 0.55 + r * 0.25, r * 4.6 + 0.6)
	cam.look_at_from_position(cam.position, Vector3(0, h * 0.42, 0))
	vp.add_child(cam)
	cam.current = true
	_cam = cam
	if SillyFaces.choice() != "off":
		_silly = SillyFaces.new()
		_silly.wait = _silly.rng.randf_range(3.0, 6.0)
		# its head: towards the front (+Z here) and near the top
		var ab := Models3D._bounds(_model, Transform3D.IDENTITY)
		var hd: Array = Content.models.get("faces", {}).get(id, [0.9, 0.78])
		_anchor = Node3D.new()
		_anchor.position = Vector3(ab.get_center().x, lerpf(ab.position.y, ab.end.y, float(hd[1])), lerpf(ab.position.z, ab.end.z, float(hd[0])))
		_model.add_child(_anchor)
		_face_size = clampf(ab.size.y * 0.34, 0.12, 0.42)


func _process(dt: float) -> void:
	if _pivot == null or not is_visible_in_tree():
		return
	_t += dt
	_pivot.rotation.y = sin(_t * 0.35) * 0.9 + 0.35
	if _silly != null:
		_silly.step(dt, ["me"])
		var a := _silly.amount("me")
		if a > 0.0:
			# turn to face you, then the face pops on
			_pivot.rotation.y = lerpf(_pivot.rotation.y, 0.0, a * a * (3.0 - 2.0 * a))
			if _face == null:
				_face = Critters3D.silly_face(_silly.kind)
				_anchor.add_child(_face)
			var to_cam := (_cam.global_position - _anchor.global_position).normalized()
			_face.global_position = _anchor.global_position + to_cam * _face_size * 0.3
			_face.look_at(_cam.global_position, Vector3.UP)
			Critters3D.silly_animate(_face, _silly.kind, a, _t, _face_size)
		elif _face != null:
			_face.queue_free()
			_face = null
	var breathe := 1.0 + sin(_t * 2.4) * 0.012
	_model.scale = Vector3(1.0, breathe, 1.0)
	var hop := fposmod(_t, 4.5)
	_model.position.y = sin(hop / 0.45 * PI) * 0.08 if hop < 0.45 else 0.0
