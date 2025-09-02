class_name EquipmentDef
extends ItemDef

# Clase para equipos de pesca (cañas, carretes, anzuelos, etc.)

# Tipos de equipos (basado en ToolDef existente)
enum EquipmentType {
	ROD = 0, # Cañas de pescar
	REEL = 1, # Carretes
	HOOK = 2, # Anzuelos
	LINE = 3, # Sedales
	NET = 4, # Redes (futuro)
	TACKLE = 5 # Aparejos diversos
}

# Slots donde se puede equipar
enum EquipmentSlot {
	PRIMARY_ROD = 0, # Caña principal
	REEL_SLOT = 1, # Carrete
	HOOK_SLOT = 2, # Anzuelo
	LINE_SLOT = 3, # Sedal
	ACCESSORY_1 = 4, # Accesorio 1
	ACCESSORY_2 = 5 # Accesorio 2
}

@export var equipment_type: EquipmentType = EquipmentType.ROD
@export var equipment_slot: EquipmentSlot = EquipmentSlot.PRIMARY_ROD
@export var tier: int = 1 # Nivel del equipo (1-10)
@export var effects: Dictionary = {} # Efectos que otorga cuando está equipado
@export var durability_max: int = 100 # Durabilidad máxima
@export var repair_cost: int = 0 # Costo de reparación
@export var upgrade_materials: Array[String] = [] # Materiales para mejorar (futuro)
@export var compatibility: Array[EquipmentType] = [] # Compatibilidad con otros equipos

func _init():
	# Los equipos son del tipo EQUIPMENT por defecto
	item_type = ItemType.EQUIPMENT
	# Los equipos no son apilables
	max_stack = 1
	# Los equipos se pueden vender
	is_sellable = true
	# Configurar slot por defecto según tipo
	_set_default_slot()

func _set_default_slot():
	"""Configurar slot por defecto según el tipo de equipo"""
	match equipment_type:
		EquipmentType.ROD: equipment_slot = EquipmentSlot.PRIMARY_ROD
		EquipmentType.REEL: equipment_slot = EquipmentSlot.REEL_SLOT
		EquipmentType.HOOK: equipment_slot = EquipmentSlot.HOOK_SLOT
		EquipmentType.LINE: equipment_slot = EquipmentSlot.LINE_SLOT
		_: equipment_slot = EquipmentSlot.ACCESSORY_1

func get_equipment_type_name() -> String:
	"""Obtener nombre del tipo de equipo"""
	match equipment_type:
		EquipmentType.ROD: return "Caña de Pescar"
		EquipmentType.REEL: return "Carrete"
		EquipmentType.HOOK: return "Anzuelo"
		EquipmentType.LINE: return "Sedal"
		EquipmentType.NET: return "Red"
		EquipmentType.TACKLE: return "Aparejo"
		_: return "Equipo"

func get_slot_name() -> String:
	"""Obtener nombre del slot"""
	match equipment_slot:
		EquipmentSlot.PRIMARY_ROD: return "Caña Principal"
		EquipmentSlot.REEL_SLOT: return "Carrete"
		EquipmentSlot.HOOK_SLOT: return "Anzuelo"
		EquipmentSlot.LINE_SLOT: return "Sedal"
		EquipmentSlot.ACCESSORY_1: return "Accesorio 1"
		EquipmentSlot.ACCESSORY_2: return "Accesorio 2"
		_: return "Desconocido"

func get_tier_name() -> String:
	"""Obtener nombre del tier"""
	match tier:
		1, 2: return "Básico"
		3, 4: return "Intermedio"
		5, 6: return "Avanzado"
		7, 8: return "Experto"
		9, 10: return "Maestro"
		_: return "Especial"

func get_tooltip_text() -> String:
	"""Tooltip extendido con información de equipo"""
	var tooltip = super.get_tooltip_text()

	tooltip += "\n⚔️ " + get_equipment_type_name()
	tooltip += "\n📍 Slot: " + get_slot_name()
	tooltip += "\n⭐ Tier: %d (%s)" % [tier, get_tier_name()]

	if durability_max > 0:
		tooltip += "\n🔧 Durabilidad: %d" % durability_max

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
		"catch_speed": return "Velocidad de captura"
		"fish_value": return "Valor de peces"
		"durability": return "Durabilidad"
		"luck_bonus": return "Bonus de suerte"
		"green_width": return "Zona verde"
		_: return effect_key.capitalize()

func _format_effect_value(value) -> String:
	"""Formatear valor de efecto para mostrar"""
	if value is float or value is int:
		var format_str = "%.1f%%" if abs(value) < 1.0 else "%.0f%%"
		if value > 0:
			return "+" + format_str % (value * 100)
		else:
			return format_str % (value * 100)
	return str(value)

func get_effect_value(effect_key: String) -> float:
	"""Obtener valor de un efecto específico"""
	return effects.get(effect_key, 0.0)

func is_compatible_with(other_equipment: EquipmentDef) -> bool:
	"""Verificar compatibilidad con otro equipo"""
	if compatibility.is_empty():
		return true # Sin restricciones
	return compatibility.has(other_equipment.equipment_type)

func get_sell_value() -> int:
	"""Los equipos de mayor tier valen más"""
	var tier_multiplier = 1.0 + (tier - 1) * 0.3 # +30% por tier
	var rarity_multiplier = 1.0 + (rarity * 0.5) # +50% por rareza
	return int(base_value * tier_multiplier * rarity_multiplier)

# Compatibilidad con ToolDef existente
func get_tool_type() -> String:
	"""Compatibilidad con ToolDef - obtener tool_type como string"""
	match equipment_type:
		EquipmentType.ROD: return "rod"
		EquipmentType.REEL: return "reel"
		EquipmentType.HOOK: return "hook"
		EquipmentType.LINE: return "line"
		_: return "misc"
