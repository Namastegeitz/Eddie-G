class_name DebugAdProvider
extends AdProvider
## Fake ads for testing the flows end to end without any SDK: shows a
## full-screen "TEST AD" card for a few seconds. Only usable in debug builds.

var host: Node


func provider_name() -> String:
	return "debug"


func request_consent(done: Callable) -> void:
	done.call(true)


func is_rewarded_ready(_placement: String) -> bool:
	return OS.is_debug_build()


func is_interstitial_ready() -> bool:
	return OS.is_debug_build()


func show_rewarded(placement: String, done: Callable) -> void:
	_card("TEST REWARDED AD\n%s" % placement, 2.5, func() -> void: done.call(true))


func show_interstitial(done: Callable) -> void:
	_card("TEST INTERSTITIAL", 1.5, done)


func _card(text: String, secs: float, after: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var l := UiKit.label(text, 48, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(l)
	host.get_tree().root.add_child(layer)
	host.get_tree().create_timer(secs, true, false, true).timeout.connect(func() -> void:
		layer.queue_free()
		after.call())
