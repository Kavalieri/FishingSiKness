extends Node

# Mejoras y upgrades
class_name UpgradeSystem

func _ready():
	# Inicialización de upgrades
	pass

# Mejorar herramienta
func upgrade(tool_type: String):
	SFX.play_event("upgrade")
	pass

# Obtener nivel actual
func get_level(tool_type: String):
	return 1
