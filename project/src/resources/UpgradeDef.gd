class_name UpgradeDef
extends Resource

@export var id: String
@export var name: String
@export var description: String = ""
@export var max_level: int = 5
@export var cost_base: int
@export var cost_mult: float = 1.5
@export var effects: Dictionary = {}

func get_level_cost(level: int) -> int:
	"""Calcular costo para un nivel específico"""
	return int(cost_base * pow(cost_mult, level - 1))

func get_total_cost_to_level(target_level: int, current_level: int = 0) -> int:
	"""Calcular costo total desde nivel actual hasta nivel objetivo"""
	var total_cost = 0
	for level in range(current_level + 1, target_level + 1):
		total_cost += get_level_cost(level)
	return total_cost

func get_effect_at_level(effect_key: String, level: int) -> float:
	"""Obtener valor de efecto en un nivel específico"""
	if not effects.has(effect_key):
		return 0.0
	return effects[effect_key] * level
