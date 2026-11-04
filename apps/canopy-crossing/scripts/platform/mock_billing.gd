extends BillingBackend
## Sandbox billing: no money moves. A purchase raises `confirm_requested`
## so the UI can show a sandbox sheet; `confirm()` finishes it. Receipts are
## kept in user://sandbox_receipts.json, standing in for the platform
## account, so "Restore purchases" works after a reinstall or a save wipe.

signal confirm_requested(product: Dictionary)

var RECEIPTS := "user://sandbox_receipts.json"

var auto_confirm := false     # tests
var fail_next := false        # tests: simulate a declined card
var _pending := {}


func _init() -> void:
	name_label = "sandbox"


func available() -> bool:
	return true


func purchase(product: Dictionary) -> void:
	var id := String(product.id)
	_pending[id] = product
	if auto_confirm:
		confirm(id, true)
	else:
		confirm_requested.emit(product)


func confirm(product_id: String, ok: bool) -> void:
	var product: Dictionary = _pending.get(product_id, {})
	_pending.erase(product_id)
	if product.is_empty():
		return
	if not ok:
		failed.emit(product_id, "Purchase cancelled.")
		return
	if fail_next:
		fail_next = false
		failed.emit(product_id, "The sandbox card was declined.")
		return
	var token := "sandbox-%s-%d" % [product_id, Time.get_ticks_usec()]
	if String(product.get("type", "")) != "consumable":
		var r := _receipts()
		if not product_id in r:
			r.append(product_id)
		_write(r)
	purchased.emit(product_id, token)


func restore() -> void:
	restored.emit(_receipts())


func clear_receipts() -> void:
	_write([])


func _receipts() -> Array:
	if not FileAccess.file_exists(RECEIPTS):
		return []
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(RECEIPTS)) != OK or typeof(json.data) != TYPE_ARRAY:
		return []
	return json.data


func _write(list: Array) -> void:
	var f := FileAccess.open(RECEIPTS, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(list))
		f.close()
