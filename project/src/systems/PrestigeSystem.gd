extends Node

# Sistema de prestigio
# Permite resetear progreso a cambio de multiplicadores permanentes

signal prestige_available_changed(available: bool)
signal prestige_completed(points_gained: int)

# Configuración del sistema de prestigio
const PRESTIGE_REQUIREMENTS := {
	"min_total_upgrades": 100,  # Mínimo 100 niveles totales
	"min_coins_earned": 50000   # Mínimo 50K monedas ganadas en total
}

const PRESTIGE_FORMULA := {
	"base_points": 1,
	"upgrade_factor": 0.01,     # 1 punto por cada 100 niveles
	"coins_factor": 0.00002     # 1 punto por cada 50K monedas
}

func _ready() -> void:
	# El sistema se inicializa correctamente sin necesidad de señales
	pass

func can_prestige() -> bool:
	"""Verificar si el jugador puede hacer prestigio"""
	if not Save:
		return false
	
	var total_upgrades = _get_total_upgrade_levels()
	var total_coins_earned = Save.game_data.get("total_coins_earned", 0)
	
	return (total_upgrades >= PRESTIGE_REQUIREMENTS.min_total_upgrades and 
			total_coins_earned >= PRESTIGE_REQUIREMENTS.min_coins_earned)

func calculate_prestige_points() -> int:
	"""Calcular puntos de prestigio que se ganarían"""
	if not can_prestige():
		return 0
	
	var total_upgrades = _get_total_upgrade_levels()
	var total_coins_earned = Save.game_data.get("total_coins_earned", 0)
	
	var points_from_upgrades = int(total_upgrades * PRESTIGE_FORMULA.upgrade_factor)
	var points_from_coins = int(total_coins_earned * PRESTIGE_FORMULA.coins_factor)
	
	return max(PRESTIGE_FORMULA.base_points, points_from_upgrades + points_from_coins)

func get_prestige_multiplier() -> float:
	"""Obtener multiplicador actual de prestigio"""
	var prestige_points = Save.game_data.get("prestige_points", 0)
	return 1.0 + (prestige_points * 0.1)  # +10% por punto de prestigio

func perform_prestige() -> bool:
	"""Realizar prestigio"""
	if not can_prestige():
		return false
	
	var points_gained = calculate_prestige_points()
	
	# Resetear progreso
	Save.game_data.upgrades = {}
	Save.game_data.coins = 0
	Save.game_data.current_zone = "lago_montana_alpes"  # Zona inicial
	
	# Limpiar inventario
	if UnifiedInventorySystem:
		UnifiedInventorySystem.clear_all_containers()
	
	# Añadir puntos de prestigio
	var current_points = Save.game_data.get("prestige_points", 0)
	Save.game_data.prestige_points = current_points + points_gained
	Save.game_data.prestige_level = Save.game_data.get("prestige_level", 0) + 1
	
	# Guardar cambios
	Save.save_game()
	
	Logger.info("Prestigio completado: +%d puntos (total: %d)" % [points_gained, Save.game_data.prestige_points])
	prestige_completed.emit(points_gained)
	
	return true

func get_prestige_info() -> Dictionary:
	"""Obtener información completa del prestigio"""
	return {
		"can_prestige": can_prestige(),
		"points_to_gain": calculate_prestige_points(),
		"current_points": Save.game_data.get("prestige_points", 0),
		"current_level": Save.game_data.get("prestige_level", 0),
		"current_multiplier": get_prestige_multiplier(),
		"total_upgrades": _get_total_upgrade_levels(),
		"total_coins_earned": Save.game_data.get("total_coins_earned", 0),
		"requirements": PRESTIGE_REQUIREMENTS
	}

func _get_total_upgrade_levels() -> int:
	"""Obtener total de niveles de upgrades"""
	var total = 0
	var upgrades = Save.game_data.get("upgrades", {})
	
	for level in upgrades.values():
		total += int(level)
	
	return total

func _check_prestige_availability() -> void:
	"""Verificar disponibilidad de prestigio y emitir señal si cambió"""
	var available = can_prestige()
	prestige_available_changed.emit(available)