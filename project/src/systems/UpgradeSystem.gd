extends Node

# Sistema de mejoras unificado
# Maneja compra, aplicación de efectos y persistencia de upgrades

# Sistema realista por componentes de pesca
const PRIMARY_EFFECT_KEY_BY_ID := {
	# Rod Components
	"rod_handle": "qte_success_bonus",
	"rod_blank": "fish_value_multiplier",
	"rod_guides": "fishing_speed",
	"rod_energy": "max_energy_bonus",
	# Hook Components
	"hook_point": "escape_reduction",
	"hook_barb": "rare_fish_chance",
	"hook_bend": "fish_value_multiplier",
	# Line Components
	"line_strength": "escape_reduction",
	"line_diameter": "rare_fish_chance",
	"line_coating": "qte_time_bonus",
	# Boat Components
	"boat_hull": "zone_multiplier_bonus",
	"boat_engine": "fishing_speed",
	"boat_sonar": "rare_fish_chance",
	"boat_storage": "inventory_capacity",
}

# Referencia a los upgrades disponibles
var available_upgrades: Dictionary = {}

func _ready() -> void:
	"""Inicializar sistema de upgrades"""
	_load_upgrade_definitions()
	_migrate_legacy_upgrades()
	# Aplicar efectos existentes tras migración para garantizar coherencia al arrancar
	call_deferred("apply_all_upgrade_effects")
	Logger.info("UpgradeSystem inicializado con %d upgrades" % available_upgrades.size())

func _load_upgrade_definitions() -> void:
	"""Cargar definiciones de upgrades desde Content"""
	if not Content:
		Logger.warn("Content no disponible al cargar upgrades")
		return

	# Obtener todos los upgrades disponibles desde Content
	var all_upgrades = Content.get_all_upgrades()
	print("[UPGRADESYSTEM] Content.get_all_upgrades() devolvió: %d upgrades" % all_upgrades.size())

	for upgrade_def in all_upgrades:
		if upgrade_def and upgrade_def.id:
			var upgrade_id = upgrade_def.id
			available_upgrades[upgrade_id] = upgrade_def
			print("[UPGRADESYSTEM] Upgrade cargado: %s (%s)" % [upgrade_id, upgrade_def.name])
		else:
			Logger.warn("Upgrade inválido encontrado: " + str(upgrade_def))

	print("[UPGRADESYSTEM] Total upgrades cargados: %d" % available_upgrades.size())

func purchase_upgrade(upgrade_id: String, quantity: int = 1) -> bool:
	"""Comprar upgrade(s) - soporta compra múltiple"""
	if not available_upgrades.has(upgrade_id):
		Logger.warn("Upgrade no existe: " + upgrade_id)
		return false

	var upgrade_def = available_upgrades[upgrade_id]

	if not Save or not Save.game_data.has("upgrades"):
		Save.game_data.upgrades = {}

	var current_level = Save.game_data.upgrades.get(upgrade_id, 0)

	# Calcular costo total para la cantidad solicitada
	var total_cost = 0
	for i in range(quantity):
		var level_cost = upgrade_def.get_level_cost(current_level + i + 1)
		total_cost += level_cost
		
		# Verificar límite máximo
		if current_level + i + 1 > upgrade_def.max_level:
			quantity = i  # Ajustar cantidad al máximo posible
			break

	if quantity == 0:
		Logger.info("Upgrade ya está al máximo: " + upgrade_id)
		return false

	# Verificar fondos
	var current_coins = Save.get_coins()
	if current_coins < total_cost:
		Logger.warn("Fondos insuficientes para upgrade: " + upgrade_id)
		return false

	# Realizar compra
	if Save.spend_coins(total_cost):
		var new_level = current_level + quantity
		Save.game_data.upgrades[upgrade_id] = new_level

		# Aplicar efectos del upgrade
		apply_upgrade_effects(upgrade_id, new_level)
		
		# Verificar milestones
		for i in range(current_level + 1, new_level + 1):
			if MilestoneSystem:
				MilestoneSystem.apply_milestone_effects(upgrade_id, i)

		# Dar experiencia por comprar upgrades
		if Experience:
			var xp_reward = quantity * 10  # 10 XP por nivel de upgrade
			Experience.add_experience(xp_reward)
			Logger.info("XP ganada por upgrade: %d" % xp_reward)

		Logger.info("Upgrade comprado: %s +%d niveles (total: %d) por %d monedas" % [upgrade_id, quantity, new_level, total_cost])
		return true

	return false

func apply_upgrade_effects(upgrade_id: String, level: int) -> void:
	"""Aplicar efectos de un upgrade específico"""
	var upgrade_def = available_upgrades.get(upgrade_id)
	if not upgrade_def:
		return
	
	var effect_key = PRIMARY_EFFECT_KEY_BY_ID.get(upgrade_id, "")
	if effect_key == "":
		return
	
	var effect_value = upgrade_def.get_effect_at_level(effect_key, level)
	
	# Aplicar efectos reales al sistema de juego
	match effect_key:
		"qte_success_bonus":
			Save.game_data.qte_success_bonus = effect_value
		"fish_value_multiplier":
			Save.game_data.fish_value_multiplier = 1.0 + effect_value
		"fishing_speed":
			Save.game_data.fishing_speed_bonus = effect_value
		"escape_reduction":
			Save.game_data.escape_reduction = effect_value
		"rare_fish_chance":
			Save.game_data.rare_fish_bonus = effect_value
		"qte_time_bonus":
			Save.game_data.qte_time_bonus = effect_value
		"zone_multiplier_bonus":
			Save.game_data.zone_multiplier_bonus = effect_value
		"inventory_capacity":
			if UnifiedInventorySystem:
				var fishing_container = UnifiedInventorySystem.get_fishing_container()
				if fishing_container:
					fishing_container.capacity += int(effect_value)
		"max_energy_bonus":
			if EnergySystem:
				EnergySystem.increase_max_energy(int(effect_value))
	
	Logger.info("Upgrade %s nivel %d aplicado: %s = %s" % [upgrade_id, level, effect_key, effect_value])

func get_upgrade_info(upgrade_id: String) -> Dictionary:
	"""Obtener información completa de un upgrade"""
	if not available_upgrades.has(upgrade_id):
		return {}

	var upgrade_def = available_upgrades[upgrade_id]

	if not Save or not Save.game_data.has("upgrades"):
		Save.game_data.upgrades = {}

	var current_level = Save.game_data.upgrades.get(upgrade_id, 0)
	var effect_key: String = PRIMARY_EFFECT_KEY_BY_ID.get(upgrade_id, "")

	var current_effect_value: float = 0.0
	var next_effect_value: float = 0.0
	if effect_key != "":
		if current_level > 0:
			current_effect_value = upgrade_def.get_effect_at_level(effect_key, current_level)
		if current_level < upgrade_def.max_level:
			next_effect_value = upgrade_def.get_effect_at_level(effect_key, current_level + 1)

	return {
		"id": upgrade_id,
		"name": upgrade_def.name,
		"description": upgrade_def.description,
		"current_level": current_level,
		"max_level": upgrade_def.max_level,
		"next_level_cost": (
			upgrade_def.get_level_cost(current_level + 1)
			if current_level < upgrade_def.max_level
			else 0
		),
		"total_cost_to_max": upgrade_def.get_total_cost_to_level(upgrade_def.max_level),
		"current_effect": current_effect_value,
		"next_effect": next_effect_value
	}

func get_all_upgrades_info() -> Array[Dictionary]:
	"""Obtener información de todos los upgrades"""
	var info_list: Array[Dictionary] = []

	for upgrade_id in available_upgrades.keys():
		info_list.append(get_upgrade_info(upgrade_id))

	return info_list

func apply_all_upgrade_effects() -> void:
	"""Aplicar todos los efectos de upgrades al cargar partida"""
	if not Save or not Save.game_data.has("upgrades"):
		return

	for upgrade_id in available_upgrades.keys():
		var level = Save.game_data.upgrades.get(upgrade_id, 0)
		if level > 0:
			apply_upgrade_effects(upgrade_id, level)

# --- Utilidades internas ---

func _migrate_legacy_upgrades() -> void:
	"""Migrar IDs legacy de upgrades a los nuevos.
	- bait_quality -> bait
	- fishing_speed -> reel
	Idempotente: se limita a copiar niveles si existen las claves legacy.
	"""
	if not Save or not Save.game_data.has("upgrades"):
		Save.game_data.upgrades = {}
		return

	var legacy_map := {
		"bait_quality": "bait",
		"fishing_speed": "reel",
	}

	for legacy_id in legacy_map.keys():
		var level = Save.game_data.upgrades.get(legacy_id, null)
		if level != null:
			var new_id = legacy_map[legacy_id]
			# Si ya existe nivel en el nuevo ID, conservar el mayor
			var current_new_level = Save.game_data.upgrades.get(new_id, 0)
			var final_level = max(int(level), int(current_new_level))
			Save.game_data.upgrades[new_id] = final_level
			var msg = "[UpgradeSystem] Migrado upgrade legacy '%s' -> '%s' (nivel %d)"
			Logger.info(msg % [legacy_id, new_id, final_level])
