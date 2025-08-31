extends Node
## Sistema de mejoras que maneja la compra y aplicación de efectos

signal upgrade_purchased(upgrade_id: String, new_level: int)
signal upgrade_maxed_out(upgrade_id: String)

var current_upgrades: Dictionary = {} # upgrade_id -> level

func _ready():
	"""Inicializar sistema de mejoras"""
	print("[UpgradeSystem] Inicializando sistema de mejoras...")
	load_upgrades()

func load_upgrades():
	"""Cargar niveles de mejoras del sistema de guardado"""
	if Save and Save.game_data.has("upgrades"):
		current_upgrades = Save.game_data.upgrades.duplicate()
		print("[UpgradeSystem] Mejoras cargadas: %s" % current_upgrades)
	else:
		current_upgrades = {}
		print("[UpgradeSystem] No hay mejoras guardadas, iniciando desde cero")

func save_upgrades():
	"""Guardar niveles actuales de mejoras"""
	if Save:
		Save.game_data.upgrades = current_upgrades.duplicate()
		Save.save_game()

func get_upgrade_level(upgrade_id: String) -> int:
	"""Obtener nivel actual de una mejora"""
	return current_upgrades.get(upgrade_id, 0)

func can_afford_upgrade(upgrade_id: String) -> bool:
	"""Verificar si se puede costear la siguiente mejora"""
	if not Content:
		return false

	var upgrade_data = Content.get_upgrade_data(upgrade_id)
	if not upgrade_data:
		return false

	var current_level = get_upgrade_level(upgrade_id)
	if current_level >= upgrade_data.max_level:
		return false # Ya está al máximo

	var next_level = current_level + 1
	var cost = upgrade_data.get_level_cost(next_level)

	return Save and Save.get_coins() >= cost

func purchase_upgrade(upgrade_id: String) -> bool:
	"""Comprar siguiente nivel de mejora"""
	if not Content or not Save:
		return false

	var upgrade_data = Content.get_upgrade_data(upgrade_id)
	if not upgrade_data:
		print("[UpgradeSystem] Upgrade no encontrada: %s" % upgrade_id)
		return false

	var current_level = get_upgrade_level(upgrade_id)
	if current_level >= upgrade_data.max_level:
		print("[UpgradeSystem] Upgrade ya está al máximo: %s" % upgrade_id)
		upgrade_maxed_out.emit(upgrade_id)
		return false

	var next_level = current_level + 1
	var cost = upgrade_data.get_level_cost(next_level)

	if Save.get_coins() < cost:
		print("[UpgradeSystem] Fondos insuficientes para %s (costo: %d)" % [upgrade_id, cost])
		return false

	# Procesar compra
	if Save.spend_coins(cost):
		current_upgrades[upgrade_id] = next_level
		save_upgrades()

		# Aplicar efectos inmediatamente
		apply_upgrade_effects(upgrade_id, next_level)

		print("[UpgradeSystem] Upgrade comprada: %s nivel %d por %d monedas" % [upgrade_id, next_level, cost])
		upgrade_purchased.emit(upgrade_id, next_level)
		return true

	return false

func apply_upgrade_effects(upgrade_id: String, level: int):
	"""Aplicar efectos de mejora al sistema de juego"""
	if not Content:
		return

	var upgrade_data = Content.get_upgrade_data(upgrade_id)
	if not upgrade_data:
		return

	# Aplicar efectos según el tipo de mejora
	match upgrade_id:
		"fridge":
			# Aumentar capacidad de inventario
			var base_capacity = 12
			var bonus_capacity = upgrade_data.get_effect_at_level("inventory_capacity", level)
			Save.game_data.max_inventory = base_capacity + int(bonus_capacity)
			print("[UpgradeSystem] Capacidad de inventario: %d" % Save.game_data.max_inventory)

		"hook":
			# Mejorar probabilidad de peces raros
			var bonus = upgrade_data.get_effect_at_level("rare_fish_chance", level)
			Save.game_data.rarity_bonus = bonus
			print("[UpgradeSystem] Bonus de rareza: +%.1f%%" % (bonus * 100))

		"bait":
			# Aumentar valor de peces
			var bonus = upgrade_data.get_effect_at_level("fish_value_bonus", level)
			Save.game_data.value_bonus = bonus
			print("[UpgradeSystem] Bonus de valor: +%.1f%%" % (bonus * 100))

		"reel":
			# Reducir tiempo de pesca
			var bonus = upgrade_data.get_effect_at_level("fishing_speed", level)
			Save.game_data.speed_bonus = bonus
			print("[UpgradeSystem] Bonus de velocidad: -%.1fs" % bonus)

		"zone_multiplier":
			# Aumentar multiplicadores de zona
			var bonus = upgrade_data.get_effect_at_level("zone_multiplier_bonus", level)
			Save.game_data.zone_multiplier_bonus = bonus
			print("[UpgradeSystem] Bonus de multiplicador: +%.2fx" % bonus)

		"line":
			# Mejorar tiempo de QTE
			var bonus = upgrade_data.get_effect_at_level("qte_time_bonus", level)
			Save.game_data.qte_time_bonus = bonus
			print("[UpgradeSystem] Bonus de tiempo QTE: +%.1fs" % bonus)

		"rod":
			# Multiplicador general de valor de peces
			var bonus = upgrade_data.get_effect_at_level("fish_value_multiplier", level)
			Save.game_data.fish_value_multiplier = bonus
			print("[UpgradeSystem] Multiplicador de valor: +%.1f%%" % (bonus * 100))

func apply_all_upgrades():
	"""Aplicar todos los efectos de mejoras actuales (al cargar juego)"""
	for upgrade_id in current_upgrades:
		var level = current_upgrades[upgrade_id]
		apply_upgrade_effects(upgrade_id, level)

	print("[UpgradeSystem] Todos los efectos de mejoras aplicados")

func get_upgrade_info(upgrade_id: String) -> Dictionary:
	"""Obtener información completa de una mejora"""
	if not Content:
		return {}

	var upgrade_data = Content.get_upgrade_data(upgrade_id)
	if not upgrade_data:
		return {}

	var current_level = get_upgrade_level(upgrade_id)
	var is_maxed = current_level >= upgrade_data.max_level
	var next_cost = 0

	if not is_maxed:
		next_cost = upgrade_data.get_level_cost(current_level + 1)

	return {
		"id": upgrade_id,
		"name": upgrade_data.name,
		"description": upgrade_data.description,
		"current_level": current_level,
		"max_level": upgrade_data.max_level,
		"next_cost": next_cost,
		"is_maxed": is_maxed,
		"can_afford": can_afford_upgrade(upgrade_id),
		"effects": upgrade_data.effects
	}

func get_all_upgrade_info() -> Array[Dictionary]:
	"""Obtener información de todas las mejoras disponibles"""
	var upgrades_info: Array[Dictionary] = []

	if not Content:
		return upgrades_info

	var all_upgrades = Content.get_all_upgrades()
	for upgrade_data in all_upgrades:
		if upgrade_data and upgrade_data.has("id"):
			var info = get_upgrade_info(upgrade_data.id)
			if not info.is_empty():
				upgrades_info.append(info)

	return upgrades_info
