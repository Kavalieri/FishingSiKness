extends Node

# Sistema de mejoras unificado
# Maneja compra, aplicación de efectos y persistencia de upgrades

# Claves primarias de efecto por upgrade_id para consultar valores en UpgradeDef.effects
const PRIMARY_EFFECT_KEY_BY_ID := {
	"rod": "fish_value_multiplier",
	"hook": "rare_fish_chance",
	"reel": "fishing_speed",
	"line": "qte_time_bonus",
	"bait": "fish_value_bonus",
	"zone_multiplier": "zone_multiplier_bonus",
	"fridge": "inventory_capacity",
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

func purchase_upgrade(upgrade_id: String) -> bool:
	"""Comprar un upgrade"""
	if not available_upgrades.has(upgrade_id):
		Logger.warn("Upgrade no existe: " + upgrade_id)
		return false

	var upgrade_def = available_upgrades[upgrade_id]

	if not Save or not Save.game_data.has("upgrades"):
		Save.game_data.upgrades = {}

	var current_level = Save.game_data.upgrades.get(upgrade_id, 0)

	# Verificar si puede mejorar más
	if current_level >= upgrade_def.max_level:
		Logger.info("Upgrade ya está al máximo: " + upgrade_id)
		return false

	# Calcular costo del siguiente nivel
	var cost = upgrade_def.get_level_cost(current_level + 1)
	var current_coins = Save.get_coins()

	# Verificar fondos
	if current_coins < cost:
		Logger.warn("Fondos insuficientes para upgrade: " + upgrade_id)
		return false

	# Realizar compra
	if Save.spend_coins(cost):
		var new_level = current_level + 1
		Save.game_data.upgrades[upgrade_id] = new_level

		# Aplicar efectos del upgrade
		apply_upgrade_effects(upgrade_id, new_level)

		Logger.info("Upgrade comprado: %s nivel %d por %d monedas" % [upgrade_id, new_level, cost])
		return true

	return false

func apply_upgrade_effects(upgrade_id: String, level: int) -> void:
	"""Aplicar efectos de un upgrade específico"""
	# TODO: Implementar efectos reales cuando Save tenga la estructura correcta
	Logger.debug("Upgrade %s aplicado en nivel %d (efectos pendientes)" % [upgrade_id, level])

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
