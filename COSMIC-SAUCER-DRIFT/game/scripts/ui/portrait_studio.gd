class_name PortraitStudio
extends SubViewport
## Paints a head-and-shoulders portrait of each pilot once, off screen, and
## caches the textures for the Racers page and the Pilots screen. One pilot
## per frame, so opening a page full of cards never stalls.

signal portrait_ready(pid: String, tex: Texture2D)

const SIZE := 192
static var cache := {}            # pilot id -> Texture2D (lives all session)

var _queue: PackedStringArray = []
var _busy := false
var _cam: Camera3D
var _holder: Node3D


func _init() -> void:
	size = Vector2i(SIZE, SIZE)
	own_world_3d = true
	transparent_bg = true
	msaa_3d = Viewport.MSAA_2X
	render_target_update_mode = SubViewport.UPDATE_DISABLED


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.5, 0.7)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, 160, 0)
	key.light_energy = 1.4
	add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.2, 1.0, 1.4)
	rim.light_color = Color(0.4, 0.85, 1.0)
	rim.light_energy = 2.0
	rim.omni_range = 5.0
	add_child(rim)
	_holder = Node3D.new()
	add_child(_holder)
	_cam = Camera3D.new()
	_cam.fov = 30.0
	_cam.position = Vector3(0.28, 0.12, -2.55)
	add_child(_cam)
	_cam.look_at(Vector3(0, -0.12, 0))
	_cam.current = true


static func texture(pid: String) -> Texture2D:
	return cache.get(pid)


## Ask for a portrait; portrait_ready fires when it exists (next frame if cached).
func request(pid: String) -> void:
	if cache.has(pid):
		portrait_ready.emit.call_deferred(pid, cache[pid])
		return
	if not (pid in _queue):
		_queue.append(pid)
	if not _busy:
		_pump()


func _pump() -> void:
	_busy = true
	while not _queue.is_empty():
		var pid := _queue[0]
		_queue.remove_at(0)
		if cache.has(pid):
			portrait_ready.emit(pid, cache[pid])
			continue
		var tex := await _paint(pid)
		if not is_inside_tree():
			return
		if tex != null:
			cache[pid] = tex
			portrait_ready.emit(pid, tex)
	_busy = false


func _paint(pid: String) -> Texture2D:
	var pm := PilotModel.new()
	_holder.add_child(pm)
	pm.build(Catalog.pilot(pid), 0.5, true, 1000.0)
	# Settle the eyelids open (they ease toward the mood's pose).
	for i in 4:
		pm.animate(0.15, PilotModel.Mood.NEUTRAL, 0.0, 0.0)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return null
	var tex: Texture2D = null
	var img := get_texture().get_image()
	if img != null and not img.is_empty():
		tex = ImageTexture.create_from_image(img)
	pm.queue_free()
	await get_tree().process_frame
	return tex
