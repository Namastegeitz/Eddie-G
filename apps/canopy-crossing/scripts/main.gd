extends Control
## Root: background, the screen host, and a modal layer above it.

var screens: Control
var modals: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeDB.fallback_font = UI.font(false)
	theme = UI.theme()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	screens = Control.new()
	screens.name = "Screens"
	screens.set_anchors_preset(Control.PRESET_FULL_RECT)
	screens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screens)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	modals = Control.new()
	modals.name = "Modals"
	modals.set_anchors_preset(Control.PRESET_FULL_RECT)
	modals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modals.theme = UI.theme()
	layer.add_child(modals)
	Game.register_host(screens, modals)
	Gfx.apply(get_tree())
	Store.confirm_requested.connect(func(p): Game.modal(SandboxSheet.make(p)))
	var args := OS.get_cmdline_user_args()
	if args.has("--no-boot"):
		return
	# Developer / capture hooks: --fresh, --skip-tutorial, --screen=<name>,
	# --play=<mode>,<map>,<stage>,<animal>, --autoplay, --give=<berries>
	if args.has("--fresh"):
		Save.wipe()
	if args.has("--skip-tutorial"):
		Save.data.tutorial_done = true
		Save.mark()
	for a in args:
		if a.begins_with("--give="):
			Economy.add("berries", int(a.substr(7)), "dev")
		if a.begins_with("--day="):
			Progress.day_override = int(a.substr(6))
	for a in args:
		if a.begins_with("--screen="):
			Game.goto(a.substr(9))
			return
		if a.begins_with("--play="):
			var p := a.substr(7).split(",")
			var cfg := {"mode": p[0], "map": p[1] if p.size() > 1 else "amazon", "stage": int(p[2]) if p.size() > 2 else 0,
				"autoplay": args.has("--autoplay"), "view": "fpv" if args.has("--fpv") else ""}
			if p.size() > 3:
				cfg.animal = p[3]
			cfg.seed = absi(hash([cfg.map, cfg.stage, "journey"])) % 1000000 if cfg.mode == "journey" else 4242
			if cfg.mode == "tutorial":
				cfg.seed = 1
			Game.start_run(cfg)
			return
	Game.boot()
