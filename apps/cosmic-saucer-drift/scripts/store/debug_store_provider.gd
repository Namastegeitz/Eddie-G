class_name DebugStoreProvider
extends StoreProvider
## Fake purchases for testing the flow without a billing library: shows a
## "TEST PURCHASE" card, then succeeds. Only works in debug builds.

var host: Node
var owned: Array = []


func provider_name() -> String:
	return "debug"


func ready() -> bool:
	return OS.is_debug_build()


func purchase(product_id: String, done: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var l := UiKit.label("TEST PURCHASE\n%s" % product_id, 44, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(l)
	host.get_tree().root.add_child(layer)
	host.get_tree().create_timer(1.2, true, false, true).timeout.connect(func() -> void:
		layer.queue_free()
		owned.append(product_id)
		done.call(true))


func owned_products(done: Callable) -> void:
	done.call(owned.duplicate())
