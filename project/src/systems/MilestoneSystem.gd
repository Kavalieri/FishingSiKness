extends Node

# Sistema de milestones para upgrades
# Maneja bonos especiales cada X niveles

# Definición de milestones por upgrade
const MILESTONES := {
	"rod_new": {
		10: {"type": "multiplier", "value": 2.0, "description": "x2 valor de peces"},
		25: {"type": "multiplier", "value": 5.0, "description": "x5 valor de peces"},
		50: {"type": "special", "value": "auto_sell", "description": "Venta automática"},
		100: {"type": "multiplier", "value": 10.0, "description": "x10 valor de peces"}
	},
	"hook_new": {
		10: {"type": "bonus", "value": 0.1, "description": "+10% peces raros"},
		25: {"type": "bonus", "value": 0.25, "description": "+25% peces raros"},
		50: {"type": "special", "value": "golden_fish", "description": "Peces dorados ocasionales"},
		100: {"type": "bonus", "value": 0.5, "description": "+50% peces raros"}
	},
	"line_new": {
		10: {"type": "bonus", "value": 0.2, "description": "+20% tiempo QTE"},
		25: {"type": "special", "value": "auto_qte", "description": "QTE automático 10%"},
		50: {"type": "bonus", "value": 0.5, "description": "+50% tiempo QTE"},
		100: {"type": "special", "value": "perfect_qte", "description": "QTE perfecto 25%"}
	},
	"boat_new": {
		10: {"type": "bonus", "value": 0.3, "description": "+30% velocidad pesca"},
		25: {"type": "special", "value": "multi_catch", "description": "Captura múltiple 15%"},
		50: {"type": "bonus", "value": 0.75, "description": "+75% velocidad pesca"},
		100: {"type": "special", "value": "zone_bonus", "description": "Bono todas las zonas"}
	}
}

func get_milestones_for_upgrade(upgrade_id: String) -> Dictionary:
	"""Obtener milestones disponibles para un upgrade"""
	return MILESTONES.get(upgrade_id, {})

func get_next_milestone(upgrade_id: String, current_level: int) -> Dictionary:
	"""Obtener el próximo milestone para un upgrade"""
	var milestones = get_milestones_for_upgrade(upgrade_id)
	
	for level in milestones.keys():
		if current_level < level:
			return {
				"level": level,
				"milestone": milestones[level]
			}
	
	return {}

func get_achieved_milestones(upgrade_id: String, current_level: int) -> Array:
	"""Obtener milestones ya alcanzados"""
	var milestones = get_milestones_for_upgrade(upgrade_id)
	var achieved = []
	
	for level in milestones.keys():
		if current_level >= level:
			achieved.append({
				"level": level,
				"milestone": milestones[level]
			})
	
	return achieved

func apply_milestone_effects(upgrade_id: String, level: int) -> void:
	"""Aplicar efectos de milestone cuando se alcanza"""
	var milestones = get_milestones_for_upgrade(upgrade_id)
	
	if milestones.has(level):
		var milestone = milestones[level]
		Logger.info("Milestone alcanzado: %s nivel %d - %s" % [upgrade_id, level, milestone.description])
		
		# Aquí se aplicarían los efectos especiales
		match milestone.type:
			"multiplier":
				_apply_multiplier_milestone(upgrade_id, milestone.value)
			"bonus":
				_apply_bonus_milestone(upgrade_id, milestone.value)
			"special":
				_apply_special_milestone(upgrade_id, milestone.value)

func _apply_multiplier_milestone(upgrade_id: String, value: float) -> void:
	"""Aplicar milestone de multiplicador"""
	# TODO: Implementar aplicación real de multiplicadores
	pass

func _apply_bonus_milestone(upgrade_id: String, value: float) -> void:
	"""Aplicar milestone de bonus"""
	# TODO: Implementar aplicación real de bonos
	pass

func _apply_special_milestone(upgrade_id: String, value: String) -> void:
	"""Aplicar milestone especial"""
	# TODO: Implementar efectos especiales
	pass