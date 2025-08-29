extends Node
# Sistema de árbol de habilidades (Skill Tree)
# Un skill point cada 5 niveles

signal skill_unlocked(skill_id: String)
signal skill_points_changed(points: int)

# Definición de habilidades
var skill_definitions = {
	# Rama de Pesca
	"fishing_basic": {
		"name": "Pescador Básico",
		"description": "Aumenta la velocidad de pesca en un 10%",
		"icon": "🎣",
		"cost": 1,
		"type": "fishing_speed",
		"value": 1.1,
		"prerequisites": [],
		"tier": 1
	},
	"fishing_advanced": {
		"name": "Pescador Experimentado",
		"description": "Aumenta la velocidad de pesca en un 25%",
		"icon": "🎣",
		"cost": 1,
		"type": "fishing_speed",
		"value": 1.25,
		"prerequisites": ["fishing_basic"],
		"tier": 2
	},
	"fishing_master": {
		"name": "Maestro Pescador",
		"description": "Aumenta la velocidad de pesca en un 50%",
		"icon": "🎣",
		"cost": 2,
		"type": "fishing_speed",
		"value": 1.5,
		"prerequisites": ["fishing_advanced"],
		"tier": 3
	},

	# Rama de Fortuna
	"luck_basic": {
		"name": "Suerte Principiante",
		"description": "Aumenta la probabilidad de peces raros en un 5%",
		"icon": "🍀",
		"cost": 1,
		"type": "rare_chance",
		"value": 1.05,
		"prerequisites": [],
		"tier": 1
	},
	"luck_advanced": {
		"name": "Suerte Mejorada",
		"description": "Aumenta la probabilidad de peces raros en un 15%",
		"icon": "🍀",
		"cost": 1,
		"type": "rare_chance",
		"value": 1.15,
		"prerequisites": ["luck_basic"],
		"tier": 2
	},
	"luck_master": {
		"name": "Suerte Extraordinaria",
		"description": "Aumenta la probabilidad de peces raros en un 30%",
		"icon": "🍀",
		"cost": 2,
		"type": "rare_chance",
		"value": 1.30,
		"prerequisites": ["luck_advanced"],
		"tier": 3
	},

	# Rama de Economía
	"economy_basic": {
		"name": "Comerciante Novato",
		"description": "Aumenta el valor de venta de peces en un 10%",
		"icon": "COINS",
		"cost": 1,
		"type": "sell_bonus",
		"value": 1.1,
		"prerequisites": [],
		"tier": 1
	},
	"economy_advanced": {
		"name": "Comerciante Experto",
		"description": "Aumenta el valor de venta de peces en un 25%",
		"icon": "COINS",
		"cost": 1,
		"type": "sell_bonus",
		"value": 1.25,
		"prerequisites": ["economy_basic"],
		"tier": 2
	},
	"economy_master": {
		"name": "Magnate Pesquero",
		"description": "Aumenta el valor de venta de peces en un 50%",
		"icon": "COINS",
		"cost": 2,
		"type": "sell_bonus",
		"value": 1.5,
		"prerequisites": ["economy_advanced"],
		"tier": 3
	},

	# Rama de Capacidad
	"capacity_basic": {
		"name": "Mochila Mejorada",
		"description": "Aumenta el inventario máximo en 5 espacios",
		"icon": "🎒",
		"cost": 1,
		"type": "max_inventory",
		"value": 5,
		"prerequisites": [],
		"tier": 1
	},
	"capacity_advanced": {
		"name": "Mochila Grande",
		"description": "Aumenta el inventario máximo en 10 espacios adicionales",
		"icon": "🎒",
		"cost": 2,
		"type": "max_inventory",
		"value": 10,
		"prerequisites": ["capacity_basic"],
		"tier": 2
	}
}

func _ready():
	# Cargar skills desbloqueadas desde el save
	pass

# Obtener puntos de skill disponibles (1 cada 5 niveles)
func get_available_skill_points() -> int:
	var current_level = Save.game_data.get("level", 1)
	var earned_points = current_level / 5
	var spent_points = get_spent_skill_points()
	return earned_points - spent_points

# Obtener puntos de skill gastados
func get_spent_skill_points() -> int:
	var spent = 0
	var unlocked_skills = Save.game_data.get("unlocked_skills", {})

	for skill_id in unlocked_skills:
		if unlocked_skills[skill_id] and skill_definitions.has(skill_id):
			spent += skill_definitions[skill_id].cost

	return spent

# Verificar si una skill está desbloqueada
func is_skill_unlocked(skill_id: String) -> bool:
	var unlocked_skills = Save.game_data.get("unlocked_skills", {})
	return unlocked_skills.get(skill_id, false)

# Verificar si una skill se puede desbloquear
func can_unlock_skill(skill_id: String) -> bool:
	if not skill_definitions.has(skill_id):
		return false

	var skill = skill_definitions[skill_id]

	# Verificar si ya está desbloqueada
	if is_skill_unlocked(skill_id):
		return false

	# Verificar puntos disponibles
	if get_available_skill_points() < skill.cost:
		return false

	# Verificar prerequisitos
	for prereq in skill.prerequisites:
		if not is_skill_unlocked(prereq):
			return false

	return true

# Desbloquear una skill
func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false

	var unlocked_skills = Save.game_data.get("unlocked_skills", {})
	unlocked_skills[skill_id] = true
	Save.game_data["unlocked_skills"] = unlocked_skills
	Save.save_game()

	emit_signal("skill_unlocked", skill_id)
	emit_signal("skill_points_changed", get_available_skill_points())

	print("Skill unlocked: ", skill_id)
	return true

# Obtener bonificaciones activas por tipo
func get_active_bonus(bonus_type: String) -> float:
	var total_bonus = 1.0
	var unlocked_skills = Save.game_data.get("unlocked_skills", {})

	for skill_id in unlocked_skills:
		if unlocked_skills[skill_id] and skill_definitions.has(skill_id):
			var skill = skill_definitions[skill_id]
			if skill.type == bonus_type:
				if bonus_type == "max_inventory":
					# Para inventario se suma
					total_bonus += skill.value - 1.0
				else:
					# Para multiplicadores se multiplica
					total_bonus *= skill.value

	return total_bonus

# Obtener inventario máximo con bonificaciones
func get_max_inventory_with_bonus() -> int:
	var base_inventory = Save.game_data.get("base_max_inventory", 12)
	var inventory_bonus = 0
	var unlocked_skills = Save.game_data.get("unlocked_skills", {})

	for skill_id in unlocked_skills:
		if unlocked_skills[skill_id] and skill_definitions.has(skill_id):
			var skill = skill_definitions[skill_id]
			if skill.type == "max_inventory":
				inventory_bonus += skill.value

	return base_inventory + inventory_bonus

# Obtener información de skill por ID
func get_skill_info(skill_id: String) -> Dictionary:
	return skill_definitions.get(skill_id, {})

# Obtener todas las skills agrupadas por tier
func get_skills_by_tier() -> Dictionary:
	var skills_by_tier = {}

	for skill_id in skill_definitions:
		var skill = skill_definitions[skill_id]
		var tier = skill.tier

		if not skills_by_tier.has(tier):
			skills_by_tier[tier] = []

		skills_by_tier[tier].append({
			"id": skill_id,
			"data": skill
		})

	return skills_by_tier

# Resetear todos los skills (para testing)
func reset_all_skills():
	Save.game_data["unlocked_skills"] = {}
	Save.save_game()
	emit_signal("skill_points_changed", get_available_skill_points())
	print("All skills reset")
