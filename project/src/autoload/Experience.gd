extends Node

# Sistema de experiencia y niveles
signal level_up(new_level: int)
signal milestone_reached(milestone_level: int)

var current_xp: int = 0
var current_level: int = 1

# Milestones y recompensas
var milestones = {
	5: {"type": "inventory_capacity", "value": 2, "desc": "Capacidad +2 espacios"},
	10: {"type": "coins_multiplier", "value": 0.1, "desc": "Monedas +10%"},
	15: {"type": "qte_time", "value": 0.5, "desc": "QTE +0.5s más tiempo"},
	20: {"type": "inventory_capacity", "value": 3, "desc": "Capacidad +3 espacios"},
	25: {"type": "coins_multiplier", "value": 0.15, "desc": "Monedas +15%"},
	30: {"type": "rare_fish_chance", "value": 0.05, "desc": "Peces raros +5%"},
	40: {"type": "inventory_capacity", "value": 5, "desc": "Capacidad +5 espacios"},
	50: {"type": "coins_multiplier", "value": 0.25, "desc": "Monedas +25%"},
	75: {"type": "prestige_unlock", "value": 1, "desc": "Desbloquea Prestigio"},
	100: {"type": "coins_multiplier", "value": 0.5, "desc": "Monedas +50%"}
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

func calculate_level_from_xp(xp: int) -> int:
	"""Fórmula: nivel = sqrt(xp / 100)"""
	return max(1, int(sqrt(xp / 100.0)) + 1)

func get_xp_for_level(level: int) -> int:
	"""XP necesaria para alcanzar un nivel específico"""
	return (level - 1) * (level - 1) * 100

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

	print("Milestone alcanzado nivel ", milestone_level, ": ", milestone.desc)

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
	current_level = calculate_level_from_xp(current_xp)

func save_experience():
	"""Guardar experiencia en el sistema de guardado"""
	Save.set_experience(current_xp, current_level)
