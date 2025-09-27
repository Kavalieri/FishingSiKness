extends Node

# Sistema de nivel y experiencia del jugador

signal level_up(new_level: int)
signal experience_gained(amount: int)

const BASE_XP_REQUIRED = 100
const XP_MULTIPLIER = 1.5

func _ready() -> void:
	Logger.info("PlayerLevelSystem inicializado")

func get_current_level() -> int:
	"""Obtener nivel actual del jugador"""
	return Save.game_data.get("player_level", 1)

func get_current_xp() -> int:
	"""Obtener experiencia actual"""
	return Save.game_data.get("player_xp", 0)

func get_xp_for_level(level: int) -> int:
	"""Calcular XP requerida para un nivel específico"""
	if level <= 1:
		return 0
	return int(BASE_XP_REQUIRED * pow(XP_MULTIPLIER, level - 2))

func get_xp_to_next_level() -> int:
	"""Obtener XP necesaria para el siguiente nivel"""
	var current_level = get_current_level()
	var current_xp = get_current_xp()
	var next_level_xp = get_xp_for_level(current_level + 1)
	return max(0, next_level_xp - current_xp)

func get_level_progress() -> float:
	"""Obtener progreso del nivel actual (0.0 - 1.0)"""
	var current_level = get_current_level()
	var current_xp = get_current_xp()
	var current_level_xp = get_xp_for_level(current_level)
	var next_level_xp = get_xp_for_level(current_level + 1)
	
	if next_level_xp <= current_level_xp:
		return 1.0
	
	var progress_xp = current_xp - current_level_xp
	var level_xp_range = next_level_xp - current_level_xp
	
	return clamp(float(progress_xp) / float(level_xp_range), 0.0, 1.0)

func add_experience(amount: int) -> void:
	"""Añadir experiencia y verificar subida de nivel"""
	if amount <= 0:
		return
	
	var old_level = get_current_level()
	var old_xp = get_current_xp()
	var new_xp = old_xp + amount
	
	Save.game_data.player_xp = new_xp
	experience_gained.emit(amount)
	
	# Verificar subida de nivel
	var new_level = _calculate_level_from_xp(new_xp)
	if new_level > old_level:
		Save.game_data.player_level = new_level
		level_up.emit(new_level)
		Logger.info("¡Subida de nivel! Nivel %d alcanzado" % new_level)

func _calculate_level_from_xp(total_xp: int) -> int:
	"""Calcular nivel basado en XP total"""
	var level = 1
	var xp_needed = 0
	
	while total_xp >= xp_needed:
		level += 1
		xp_needed = get_xp_for_level(level)
		if xp_needed > total_xp:
			return level - 1
	
	return level

func get_level_milestones(level: int) -> Array:
	"""Obtener milestones desbloqueados en un nivel específico"""
	var milestones = []
	
	# Milestones cada 5 niveles
	if level % 5 == 0:
		milestones.append({
			"type": "inventory_slot",
			"description": "Slot de inventario adicional",
			"value": 1
		})
	
	# Milestones cada 10 niveles
	if level % 10 == 0:
		milestones.append({
			"type": "fishing_speed",
			"description": "Velocidad de pesca mejorada",
			"value": 0.1
		})
	
	# Milestones especiales
	match level:
		5:
			milestones.append({
				"type": "zone_unlock",
				"description": "Desbloquear nueva zona",
				"value": "grandes_lagos_norteamerica"
			})
		15:
			milestones.append({
				"type": "prestige_unlock",
				"description": "Sistema de prestigio desbloqueado",
				"value": true
			})
		25:
			milestones.append({
				"type": "auto_fishing",
				"description": "Pesca automática desbloqueada",
				"value": true
			})
	
	return milestones