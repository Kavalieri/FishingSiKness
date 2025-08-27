extends Node

## Custom WindowManager for handling UI panels and menus.
## This manager maps aliases to specific scene paths and opens them using FloatingWindowManager.

@onready var floating_window_manager = get_node_or_null("/root/FloatingWindowManager")

# Define a mapping from aliases to scene paths
const WINDOW_SCENE_PATHS = {
	"money": "res://scenes/ui/MoneyWindow.tscn",
	"diamonds": "res://scenes/ui/ShopWindow.tscn", # Assuming diamonds are related to a shop
	"zone": "res://scenes/ui/ZoneSelectWindow.tscn",
	"level": "res://scenes/ui/PlayerStatsWindow.tscn",
	"xp": "res://scenes/ui/PlayerStatsWindow.tscn", # Can open the same window as level
	"options": "res://scenes/ui/OptionsWindow.tscn",
}

func open(alias: String) -> void:
	if not floating_window_manager:
		printerr("WindowManager: FloatingWindowManager is not available. Cannot open window for alias: " + alias)
		return

	if WINDOW_SCENE_PATHS.has(alias):
		var scene_path = WINDOW_SCENE_PATHS[alias]
		print("WindowManager: Opening window for alias: %s (Path: %s)" % [alias, scene_path])
		floating_window_manager.open_window(scene_path)
	else:
		printerr("WindowManager: Unknown alias received: " + alias)
