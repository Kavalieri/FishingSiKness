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
	print("[Content] OK Sistema de contenido listo")
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
				print("[Content] OK Zona encontrada: %s" % zone_id)
				return zone
		else:
			print("[Content] - Zona %d: INVÁLIDA" % i)

	print("[Content] ERROR Zona NO encontrada: %s" % zone_id)
	return null

# Métodos adicionales para compatibilidad con UI
func get_zone_data(zone_id: String):
	"""Alias para get_zone_by_id para compatibilidad"""
	return get_zone_by_id(zone_id)

func get_default_zone():
	"""Obtener zona por defecto (la primera disponible)"""
	var zones = all_zones()
	if zones.size() > 0:
		return zones[0]
	return null

func get_all_zones():
	"""Alias para all_zones() para compatibilidad"""
	return all_zones()

func get_all_upgrades():
	"""Obtener todas las mejoras disponibles"""
	return upgrade_defs()

func get_upgrade_by_id(upgrade_id: String):
	"""Obtener definición de una mejora específica por ID"""
	var upgrades = upgrade_defs()
	for upgrade in upgrades:
		if upgrade and upgrade.get("id") == upgrade_id:
			return upgrade
	return null

func get_upgrade_data(upgrade_id: String):
	"""Obtener datos de una mejora específica"""
	var upgrades = upgrade_defs()
	for upgrade in upgrades:
		if upgrade.get("id") == upgrade_id:
			return upgrade
	return null

func get_prestige_bonuses():
	"""Obtener bonos de prestigio disponibles"""
	# TODO: Implementar sistema de bonos de prestigio
	return []

func get_next_prestige_requirement(current_level: int):
	"""Obtener puntos necesarios para el siguiente nivel de prestigio"""
	# TODO: Implementar cálculo de requisitos de prestigio
	return (current_level + 1) * 1000

func get_random_fish_for_zone(zone_id: String) -> Dictionary:
	"""Obtener un pez aleatorio de una zona específica usando loot tables"""
	var zone_def = get_zone_by_id(zone_id)
	if not zone_def:
		print("[Content] ERROR: Zona no encontrada: %s" % zone_id)
		return {}

	if not zone_def.entries or zone_def.entries.size() == 0:
		print("[Content] ERROR: Zona sin loot entries: %s" % zone_id)
		return {}

	# Calcular peso total
	var total_weight = 0
	for entry in zone_def.entries:
		if entry and entry.fish:
			total_weight += entry.weight

	if total_weight == 0:
		print("[Content] ERROR: Total weight es 0 en zona: %s" % zone_id)
		return {}

	# Seleccionar pez por peso
	var random_roll = randi() % total_weight
	var current_weight = 0

	for entry in zone_def.entries:
		if entry and entry.fish:
			current_weight += entry.weight
			if random_roll < current_weight:
				var fish_def = entry.fish
				# Solo devolver datos base, FishingScreen calculará el resto
				var random_size = randf_range(fish_def.size_min, fish_def.size_max)

				return {
					"id": fish_def.id,
					"name": fish_def.name,
					"size": random_size,
					"base_market_value": fish_def.base_market_value,
					"rarity": fish_def.rarity,
					"zone_caught": zone_id,
					"zone_multiplier": zone_def.price_multiplier,
					"size_min": fish_def.size_min,
					"size_max": fish_def.size_max,
					"timestamp": Time.get_datetime_dict_from_system(),
					"icon": fish_def.sprite
				}

	print("[Content] ERROR: No se pudo seleccionar pez en zona: %s" % zone_id)
	return {}

func get_fish_for_zone(zone_id: String) -> Array:
	"""Obtener lista de todos los peces disponibles en una zona específica"""
	var zone_def = get_zone_by_id(zone_id)
	if not zone_def:
		print("[Content] ERROR: Zona no encontrada: %s" % zone_id)
		return []

	if not zone_def.entries or zone_def.entries.size() == 0:
		print("[Content] ERROR: Zona sin loot entries: %s" % zone_id)
		return []

	var fish_list = []
	for entry in zone_def.entries:
		if entry and entry.fish:
			fish_list.append(entry.fish)

	print("[Content] DEBUG: Zona %s tiene %d especies de peces" % [zone_id, fish_list.size()])
	return fish_list
