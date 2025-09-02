class_name ConsumableDef
extends ItemDef

# Clase para items consumibles como carnadas especiales, boosters de pesca, etc.

# Tipos de consumibles
enum ConsumableType {
	BAIT = 0, # Carnadas especiales
	BOOSTER = 1, # Boosters temporales (mejor suerte, más XP, etc.)
	TOOL = 2, # Herramientas de un uso
	MISC = 3 # Otros consumibles
}

@export var consumable_type: ConsumableType = ConsumableType.MISC
@export var duration: float = 0.0 # Duración del efecto en segundos (0 = instantáneo)
@export var effects: Dictionary = {} # Efectos que otorga cuando se usa
@export var cooldown: float = 0.0 # Tiempo de reutilización en segundos
@export var auto_use: bool = false # Se usa automáticamente cuando se obtiene
@export var use_conditions: Array[String] = [] # Condiciones para poder usar
@export var sound_effect: String = "" # Sonido al usar

func _init():
	# Los consumibles son del tipo CONSUMABLE por defecto
	item_type = ItemType.CONSUMABLE
	# Los consumibles suelen ser apilables
	max_stack = 99
	# Los consumibles se pueden vender por defecto
	is_sellable = true

func get_consumable_type_name() -> String:
	"""Obtener nombre del tipo de consumible"""
	match consumable_type:
		ConsumableType.BAIT: return "Carnada"
		ConsumableType.BOOSTER: return "Booster"
		ConsumableType.TOOL: return "Herramienta"
		ConsumableType.MISC: return "Consumible"
		_: return "Desconocido"

func get_duration_text() -> String:
	"""Obtener texto de duración para mostrar en UI"""
	if duration <= 0:
		return "Instantáneo"
	elif duration < 60:
		return "%.0f segundos" % duration
	elif duration < 3600:
		return "%.1f minutos" % (duration / 60.0)
	else:
		return "%.1f horas" % (duration / 3600.0)

func get_tooltip_text() -> String:
	"""Tooltip extendido con información de consumible"""
	var tooltip = super.get_tooltip_text()

	tooltip += "\n📦 " + get_consumable_type_name()

	if duration > 0:
		tooltip += "\n⏰ Duración: " + get_duration_text()

	if cooldown > 0:
		tooltip += "\n🔄 Reutilización: %.0f seg" % cooldown

	# Mostrar efectos
	if not effects.is_empty():
		tooltip += "\n✨ Efectos:"
		for effect_key in effects.keys():
			var effect_value = effects[effect_key]
			tooltip += "\n  • %s: %s" % [_format_effect_name(effect_key), _format_effect_value(effect_value)]

	return tooltip

func _format_effect_name(effect_key: String) -> String:
	"""Formatear nombre de efecto para mostrar"""
	match effect_key:
		"bite_chance": return "Probabilidad de pique"
		"fish_value": return "Valor de peces"
		"xp_multiplier": return "Multiplicador XP"
		"luck_bonus": return "Bonus de suerte"
		"catch_speed": return "Velocidad de captura"
		_: return effect_key.capitalize()

func _format_effect_value(value) -> String:
	"""Formatear valor de efecto para mostrar"""
	if value is float or value is int:
		if value > 0:
			return "+%.1f" % value if value is float else "+%d" % value
		else:
			return "%.1f" % value if value is float else "%d" % value
	return str(value)

func can_be_used() -> bool:
	"""Verificar si el consumible puede ser usado actualmente"""
	# TODO: Implementar lógica de condiciones cuando sea necesario
	return true

func get_effect_value(effect_key: String) -> float:
	"""Obtener valor de un efecto específico"""
	return effects.get(effect_key, 0.0)

# Sobrescribir métodos base si es necesario
func get_sell_value() -> int:
	"""Los consumibles raros valen más"""
	var multiplier = 1.0 + (rarity * 0.5) # +50% por nivel de rareza
	return int(base_value * multiplier)
