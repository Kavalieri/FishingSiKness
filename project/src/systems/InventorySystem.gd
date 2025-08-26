extends Node

# Inventario y gestión de capturas
class_name InventorySystem

func _ready():
	# Inicialización del inventario
	pass

# Añadir captura al inventario
func add_fish(fish_data: Dictionary):
	SFX.play_event("capture")
	# ...existing code...
	pass

# Vender captura(s)
func sell_fish(fish_ids: Array):
	SFX.play_event("sell")
	# ...existing code...
	pass

# Obtener inventario actual
func get_inventory():
	return []
