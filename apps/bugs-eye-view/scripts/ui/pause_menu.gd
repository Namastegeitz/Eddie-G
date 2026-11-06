extends CanvasLayer
## Pause overlay: resume, restart, settings, controls help, quit.

const SETTINGS_SCENE := "res://scenes/ui/settings_menu.tscn"

var _root: Control
var _help: VBoxContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	UIKit.setup_root(_root)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var col := UIKit.column(_root, 520.0)
	col.add_child(UIKit.title("PAUSED", 48))
	col.add_child(UIKit.button("Resume", GameManager.toggle_pause))
	col.add_child(UIKit.button("Restart", GameManager.restart_level))
	col.add_child(UIKit.button("Settings", _open_settings))
	col.add_child(UIKit.button("Controls", _toggle_help))
	_help = UIKit.vbox(10)
	_help.name = "Help"
	_help.visible = false
	col.add_child(_help)
	col.add_child(UIKit.button("Quit to menu", func() -> void: GameManager.goto("main_menu")))
	_root.visible = false
	GameManager.state_changed.connect(_on_state)


func _on_state(s: int) -> void:
	_root.visible = s == GameManager.State.PAUSED


func bind(_lvl: Level) -> void:
	pass


## How to play the bug you're playing, plus the general controls.
func _toggle_help() -> void:
	if _help.visible:
		_help.visible = false
		return
	for c in _help.get_children():
		c.queue_free()
	var lvl := Level.current
	if lvl and lvl.player:
		_help.add_child(BugGuide.build_panel(lvl.player.stats, lvl.player.action_labels(), false))
	_help.add_child(UIKit.label(_controls_text(), 16, UIKit.DIM))
	_help.visible = true


func _controls_text() -> String:
	var lines := [
		"Move: WASD / left stick / joystick",
		"Look: mouse / right stick / drag",
		"Creep: hold C (or push the stick gently)",
		"Primary: %s   Secondary: %s" % [InputRouter.binding_text("primary"), InputRouter.binding_text("secondary")],
		"Jump: %s   Dodge: %s" % [InputRouter.binding_text("jump"), InputRouter.binding_text("dodge")],
		"Use: %s   Sense: %s" % [InputRouter.binding_text("interact"), InputRouter.binding_text("sense")],
		"Stand still to blend in. Shadows hide you; noisy floors give you away.",
	]
	return "\n".join(lines)


func _open_settings() -> void:
	var s: Node = (load(SETTINGS_SCENE) as PackedScene).instantiate()
	s.set("overlay", true)
	add_child(s)
