extends Node

## Custom WindowManager for handling UI panels and menus.
## This manager maps aliases to specific scene paths and opens them using FloatingWindowManager.

# Define a mapping from aliases to scene paths - adapted to existing project scenes
const WINDOW_SCENE_PATHS = {
	"money": "res://scenes/views/Market.tscn",
	"diamonds": "res://scenes/views/StoreView.tscn",
	"zone": "res://scenes/views/Map.tscn",
	"level": "res://scenes/views/MilestonesPanel.tscn",
	"xp": "res://scenes/views/MilestonesPanel.tscn",
	"options": "res://scenes/views/SettingsMenu.tscn",
}

@onready var floating_window_manager = get_node_or_null("/root/FloatingWindowManager")

func open(alias: String) -> void:
	if not floating_window_manager:
		printerr("WindowManager: FloatingWindowManager not available for alias: " + alias)
		return

	if WINDOW_SCENE_PATHS.has(alias):
		var scene_path = WINDOW_SCENE_PATHS[alias]
		print("WindowManager: Opening window for alias: %s (Path: %s)" % [alias, scene_path])

		# Manejo especial para ciertas ventanas que no son BaseWindow
		match alias:
			"zone", "money":
				# Estas ventanas son vistas principales, cambiar a tab correspondiente
				var screen_manager = get_tree().get_first_node_in_group("ScreenManager")
				if screen_manager:
					if alias == "zone":
						screen_manager.show_tab(3) # MAP tab
					elif alias == "money":
						screen_manager.show_tab(1) # MARKET tab
			"options":
				# Usar PauseMenu que tiene SettingsMenu integrado
				floating_window_manager.open_window("res://scenes/views/PauseMenu.tscn", {"title": "Opciones"})
			_:
				# Para el resto, intentar abrir normalmente
				floating_window_manager.open_window(scene_path)
	else:
		printerr("WindowManager: Unknown alias received: " + alias)
