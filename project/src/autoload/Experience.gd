extends Node

# Sistema de experiencia y niveles
signal level_up(new_level: int)
signal milestone_reached(milestone_level: int)
signal experience_changed(current_xp: int, current_level: int)

var current_xp: int = 0
var current_level: int = 1

# Milestones y recompensas - Cada nivel aumenta energía
var milestones = {
	2: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima"},
	3: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima"},
	4: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima"},
	5: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima"},
	6: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima"},
	7: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima"},
	8: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima"},
	9: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima"},
	10: {"type": "energy_increase", "value": 1, "desc": "+1 Energía Máxima + Auto-Pesca"},
	15: {"type": "energy_increase", "value": 2, "desc": "+2 Energía Máxima"},
	20: {"type": "energy_increase", "value": 2, "desc": "+2 Energía Máxima"},
	25: {"type": "energy_increase", "value": 3, "desc": "+3 Energía Máxima"},
	30: {"type": "energy_increase", "value": 3, "desc": "+3 Energía Máxima"}
}

func _ready():
	# Cargar experiencia del guardado
	load_experience()

func add_experience(amount: int):
	"""Añadir experiencia por captura exitosa"""
	current_xp += amount
	var old_level = current_level

	# Calcular nuevo nivel
	var new_level = calculate_level_from_xp(current_xp)

	if new_level > old_level:
		current_level = new_level
		emit_signal("level_up", new_level)

		# Verificar milestones
		for milestone_level in milestones.keys():
			if milestone_level <= new_level and milestone_level > old_level:
				apply_milestone(milestone_level)
				emit_signal("milestone_reached", milestone_level)

	save_experience()

	# Emitir señal de cambio de experiencia para actualizaciones en tiempo real
	print("[Experience] Emitiendo experience_changed: XP=%d, Nivel=%d" % [current_xp, current_level])
	experience_changed.emit(current_xp, current_level)

func calculate_level_from_xp(xp: int) -> int:
	"""Fórmula ajustada para progresión más rápida inicial"""
	return max(1, int(sqrt(xp / 50.0)) + 1)  # Divido por 50 en lugar de 100

func get_xp_for_level(level: int) -> int:
	"""XP necesaria para alcanzar un nivel específico"""
	return (level - 1) * (level - 1) * 50  # Ajustado para progresión más rápida

func get_xp_progress() -> Dictionary:
	"""Progreso actual hacia el siguiente nivel"""
	var next_level = current_level + 1
	var current_level_xp = get_xp_for_level(current_level)
	var next_level_xp = get_xp_for_level(next_level)
	var progress_xp = current_xp - current_level_xp
	var required_xp = next_level_xp - current_level_xp

	return {
		"current_xp": progress_xp,
		"required_xp": required_xp,
		"percentage": float(progress_xp) / float(required_xp)
	}

func apply_milestone(milestone_level: int):
	"""Aplicar beneficios del milestone alcanzado"""
	if not milestones.has(milestone_level):
		return

	var milestone = milestones[milestone_level]
	match milestone.type:
		"energy_increase":
			if EnergySystem:
				EnergySystem.increase_max_energy(milestone.value)
				EnergySystem.refill_energy()  # Rellenar al 100%
				print("[Experience] Milestone %d: +%d energía máxima, recargada al 100%%" % [milestone_level, milestone.value])
		"inventory_capacity":
			Save.add_milestone_inventory(milestone.value)
		"coins_multiplier":
			Save.add_milestone_coins_multiplier(milestone.value)
		"qte_time":
			Save.add_milestone_qte_time(milestone.value)
		"rare_fish_chance":
			Save.add_milestone_rare_chance(milestone.value)
		"prestige_unlock":
			Save.unlock_prestige()

	print("[Experience] Milestone alcanzado nivel %d: %s" % [milestone_level, milestone.desc])

func get_milestone_info(level: int) -> Dictionary:
	"""Obtener información de un milestone específico"""
	if milestones.has(level):
		return milestones[level]
	return {}

func get_next_milestones(count: int = 3) -> Array:
	"""Obtener los próximos milestones"""
	var next_milestones = []
	for milestone_level in milestones.keys():
		if milestone_level > current_level:
			next_milestones.append({
				"level": milestone_level,
				"info": milestones[milestone_level]
			})

	next_milestones.sort_custom(func(a, b): return a.level < b.level)
	return next_milestones.slice(0, count)

func load_experience():
	"""Cargar experiencia del sistema de guardado"""
	current_xp = Save.get_experience()
	
	# Si no hay XP pero hay upgrades, calcular XP retroactiva
	if current_xp == 0 and Save.game_data.has("upgrades"):
		var total_upgrade_levels = 0
		for upgrade_id in Save.game_data.upgrades:
			total_upgrade_levels += Save.game_data.upgrades[upgrade_id]
		
		if total_upgrade_levels > 0:
			current_xp = total_upgrade_levels * 10  # 10 XP por nivel de upgrade
			print("[Experience] XP retroactiva calculada: %d upgrades = %d XP" % [total_upgrade_levels, current_xp])
	
	current_level = calculate_level_from_xp(current_xp)
	Save.set_experience(current_xp, current_level)
	print("[Experience] Cargado: XP=%d, Nivel=%d" % [current_xp, current_level])

func save_experience():
	"""Guardar experiencia en el sistema de guardado"""
	Save.set_experience(current_xp, current_level)
	print("[Experience] Guardado: XP=%d, Nivel=%d" % [current_xp, current_level])

func get_experience_for_level(level: int) -> int:
	"""Calcular experiencia requerida para un nivel específico"""
	if level <= 1:
		return 0
	# Progresión exponencial: level^1.5 * 100
	return int(pow(level - 1, 1.5) * 100)
