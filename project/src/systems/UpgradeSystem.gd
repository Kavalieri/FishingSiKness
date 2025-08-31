extends Node

# Sistema de mejoras unificado
# Maneja compra, aplicación de efectos y persistencia de upgrades

# Referencia a los upgrades disponibles
var available_upgrades: Dictionary = {}

func _ready() -> void:
	"""Inicializar sistema de upgrades"""
	_load_upgrade_definitions()
	Logger.info("UpgradeSystem inicializado con %d upgrades" % available_upgrades.size())

func _load_upgrade_definitions() -> void:
	"""Cargar definiciones de upgrades desde Content"""
	if not Content:
		Logger.warn("Content no disponible al cargar upgrades")
		return

	# Lista de upgrades esperados
	var upgrade_ids = ["rod", "hook", "reel", "bait", "line", "zone_multiplier", "fridge"]

	for upgrade_id in upgrade_ids:
		var upgrade_def = Content.get_upgrade_by_id(upgrade_id)
		if upgrade_def:
			available_upgrades[upgrade_id] = upgrade_def
			Logger.debug("Upgrade cargado: " + upgrade_id)
		else:
			Logger.warn("Upgrade no encontrado: " + upgrade_id)

func purchase_upgrade(upgrade_id: String) -> bool:
	"""Comprar un upgrade"""
	if not available_upgrades.has(upgrade_id):
		Logger.warn("Upgrade no existe: " + upgrade_id)
		return false

	var upgrade_def = available_upgrades[upgrade_id]
	var current_level = Save.get_data("upgrades/" + upgrade_id, 0)

	# Verificar si puede mejorar más
	if current_level >= upgrade_def.max_level:
		Logger.info("Upgrade ya está al máximo: " + upgrade_id)
		return false

	# Calcular costo del siguiente nivel
	var cost = upgrade_def.get_level_cost(current_level + 1)
	var current_coins = Save.get_data("coins", 0)

	# Verificar fondos
	if current_coins < cost:
		Logger.warn("Fondos insuficientes para upgrade: " + upgrade_id)
		return false

	# Realizar compra
	if Save.spend_coins(cost):
		var new_level = current_level + 1
		Save.set_data("upgrades/" + upgrade_id, new_level)

		# Aplicar efectos del upgrade
		apply_upgrade_effects(upgrade_id, new_level)

		Logger.info("Upgrade comprado: %s nivel %d por %d monedas" % [upgrade_id, new_level, cost])
		return true

	return false

func apply_upgrade_effects(upgrade_id: String, level: int) -> void:
	"""Aplicar efectos de un upgrade específico"""
	if not available_upgrades.has(upgrade_id):
		return

	var upgrade_def = available_upgrades[upgrade_id]
	var effect_value = upgrade_def.get_effect_at_level(level)

	match upgrade_id:
		"rod":
			# Aumentar valor de peces pescados
			var current_multiplier = Save.get_data("fishing_multipliers/value", 1.0)
			var new_multiplier = 1.0 + (level * 0.15) # 15% por nivel
			Save.set_data("fishing_multipliers/value", new_multiplier)
			Logger.debug("Rod upgrade: valor de peces +%d%%" % int((new_multiplier - 1.0) * 100))

		"hook":
			# Aumentar probabilidad de peces raros
			var current_rare_bonus = Save.get_data("fishing_multipliers/rare_chance", 0.0)
			var new_rare_bonus = level * 0.05 # 5% por nivel
			Save.set_data("fishing_multipliers/rare_chance", new_rare_bonus)
			Logger.debug("Hook upgrade: probabilidad raros +%d%%" % int(new_rare_bonus * 100))

		"reel":
			# Reducir tiempo de pesca
			var base_time = 3.0
			var time_reduction = level * 0.3 # 0.3s menos por nivel
			var new_time = max(base_time - time_reduction, 1.0) # mínimo 1 segundo
			Save.set_data("fishing_times/reel_speed", new_time)
			Logger.debug("Reel upgrade: tiempo de pesca %.1fs" % new_time)

		"bait":
			# Bonus de valor temporal o permanente
			var value_bonus = level * 0.25 # 25% por nivel
			Save.set_data("fishing_multipliers/bait_bonus", value_bonus)
			Logger.debug("Bait upgrade: bonus valor +%d%%" % int(value_bonus * 100))

		"line":
			# Facilitar QTE o reducir su tiempo
			var qte_reduction = level * 0.5 # 0.5s menos por nivel
			Save.set_data("fishing_times/qte_duration", max(3.0 - qte_reduction, 1.5))
			Logger.debug("Line upgrade: QTE duration reduced")

		"zone_multiplier":
			# Multiplicador general para la zona actual
			var zone_bonus = level * 0.20 # 20% por nivel
			Save.set_data("fishing_multipliers/zone_bonus", zone_bonus)
			Logger.debug("Zone multiplier: +%d%%" % int(zone_bonus * 100))

		"fridge":
			# Aumentar capacidad de inventario
			var base_capacity = 10
			var new_capacity = base_capacity + (level * 5) # 5 slots por nivel
			Save.set_data("inventory/max_capacity", new_capacity)
			Logger.debug("Fridge upgrade: capacidad %d slots" % new_capacity)

func get_upgrade_info(upgrade_id: String) -> Dictionary:
	"""Obtener información completa de un upgrade"""
	if not available_upgrades.has(upgrade_id):
		return {}

	var upgrade_def = available_upgrades[upgrade_id]
	var current_level = Save.get_data("upgrades/" + upgrade_id, 0)

	return {
		"id": upgrade_id,
		"name": upgrade_def.name,
		"description": upgrade_def.description,
		"current_level": current_level,
		"max_level": upgrade_def.max_level,
		"next_level_cost": upgrade_def.get_level_cost(current_level + 1) if current_level < upgrade_def.max_level else 0,
		"total_cost_to_max": upgrade_def.get_total_cost_to_level(upgrade_def.max_level),
		"current_effect": upgrade_def.get_effect_at_level(current_level),
		"next_effect": upgrade_def.get_effect_at_level(current_level + 1) if current_level < upgrade_def.max_level else 0
	}

func get_all_upgrades_info() -> Array[Dictionary]:
	"""Obtener información de todos los upgrades"""
	var info_list: Array[Dictionary] = []

	for upgrade_id in available_upgrades.keys():
		info_list.append(get_upgrade_info(upgrade_id))

	return info_list

func apply_all_upgrade_effects() -> void:
	"""Aplicar todos los efectos de upgrades al cargar partida"""
	for upgrade_id in available_upgrades.keys():
		var level = Save.get_data("upgrades/" + upgrade_id, 0)
		if level > 0:
			apply_upgrade_effects(upgrade_id, level)
