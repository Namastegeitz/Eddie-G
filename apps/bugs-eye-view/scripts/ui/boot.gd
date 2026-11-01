extends Node
## Entry scene: lets autoloads settle, then opens the main menu.


func _ready() -> void:
	await get_tree().process_frame
	GameManager.goto("main_menu")
