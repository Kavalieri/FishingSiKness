extends Node

# Autoload que envuelve a ContentIndex
# class_name Content

signal content_loaded

var catalogs = {}

func _ready():
	print("[Content] 🚀 Iniciando sistema de contenido...")
	var content_index = ContentIndex.new()
	print("[Content] 📋 ContentIndex creado, iniciando carga...")
	catalogs = content_index.load_all()
	print("[Content] 📊 Resumen de carga:")
	for key in catalogs.keys():
		print("[Content]   - %s: %d recursos" % [key, catalogs[key].size()])
	print("[Content] ✅ Sistema de contenido listo")
	emit_signal("content_loaded")

func _exit_tree():
	# Limpiar referencias para evitar ObjectDB leaks
	if catalogs:
		catalogs.clear()
	print("[Content] 🧹 Recursos liberados")

# API de acceso
func all_fish():
	return catalogs["fish"] if catalogs.has("fish") else []

func all_zones():
	return catalogs["zones"] if catalogs.has("zones") else []

func equipment(equip_type: String = ""):
	var eqs = catalogs["equipment"] if catalogs.has("equipment") else []
	if equip_type == "":
		return eqs
	var filtered := []
	for e in eqs:
		if e.has("tool_type") and e.tool_type == equip_type:
			filtered.append(e)
	return filtered

func upgrade_defs():
	return catalogs["upgrades"] if catalogs.has("upgrades") else []

func store_items():
	return catalogs["store"] if catalogs.has("store") else []

func get_all_fish_definitions() -> Array:
	"""Obtener todas las definiciones de peces disponibles"""
	return all_fish()

func get_fish_by_id(fish_id: String) -> FishDef:
	"""Obtener definición de un pez específico por ID"""
	var fish_list = all_fish()
	for fish in fish_list:
		if fish.id == fish_id:
			return fish
	return null

func get_zone_by_id(zone_id: String):
	"""Obtener definición de una zona específica por ID"""
	print("[Content] Buscando zona: %s" % zone_id)
	var zone_list = all_zones()
	print("[Content] Zonas disponibles: %d" % zone_list.size())

	for i in range(zone_list.size()):
		var zone = zone_list[i]
		if zone and zone.get("id"):
			print("[Content] - Zona %d: %s" % [i, zone.id])
			if zone.id == zone_id:
				print("[Content] ✅ Zona encontrada: %s" % zone_id)
				return zone
		else:
			print("[Content] - Zona %d: INVÁLIDA" % i)

	print("[Content] ❌ Zona NO encontrada: %s" % zone_id)
	return null
