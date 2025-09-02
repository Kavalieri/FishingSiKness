class_name MaterialDef
extends ItemDef

# Clase para materiales de crafting y recursos especiales

# Tipos de materiales
enum MaterialType {
	COMMON = 0, # Materiales comunes
	RARE = 1, # Materiales raros
	ESSENCE = 2, # Esencias mágicas
	COMPONENT = 3, # Componentes mecánicos
	ORGANIC = 4, # Materiales orgánicos
	MINERAL = 5 # Minerales y metales
}

@export var material_type: MaterialType = MaterialType.COMMON
@export var crafting_tier: int = 1 # Nivel de crafting requerido
@export var source_activities: Array[String] = [] # Actividades que lo otorgan
@export var used_in_recipes: Array[String] = [] # Recetas que lo usan (futuro)
@export var drop_rate: float = 1.0 # Probabilidad de obtenerlo
@export var seasonal: bool = false # Solo disponible en ciertas épocas

func _init():
	# Los materiales son del tipo MATERIAL por defecto
	item_type = ItemType.MATERIAL
	# Los materiales son muy apilables
	max_stack = 999
	# Los materiales se pueden vender
	is_sellable = true

func get_material_type_name() -> String:
	"""Obtener nombre del tipo de material"""
	match material_type:
		MaterialType.COMMON: return "Común"
		MaterialType.RARE: return "Raro"
		MaterialType.ESSENCE: return "Esencia"
		MaterialType.COMPONENT: return "Componente"
		MaterialType.ORGANIC: return "Orgánico"
		MaterialType.MINERAL: return "Mineral"
		_: return "Desconocido"

func get_crafting_tier_name() -> String:
	"""Obtener nombre del tier de crafting"""
	match crafting_tier:
		1: return "Principiante"
		2: return "Aprendiz"
		3: return "Experto"
		4: return "Maestro"
		5: return "Gran Maestro"
		_: return "Especial"

func get_tooltip_text() -> String:
	"""Tooltip extendido con información de material"""
	var tooltip = super.get_tooltip_text()

	tooltip += "\n🔧 " + get_material_type_name()
	tooltip += "\n⚒️ Crafting: Tier %d (%s)" % [crafting_tier, get_crafting_tier_name()]

	if drop_rate < 1.0:
		tooltip += "\n🎯 Rareza: %.1f%% drop" % (drop_rate * 100)

	if seasonal:
		tooltip += "\n🗓️ Estacional"

	if not source_activities.is_empty():
		tooltip += "\n📍 Fuentes:"
		for source in source_activities:
			tooltip += "\n  • " + _format_source_name(source)

	if not used_in_recipes.is_empty():
		tooltip += "\n🛠️ Usado en:"
		for recipe in used_in_recipes:
			tooltip += "\n  • " + recipe

	return tooltip

func _format_source_name(source: String) -> String:
	"""Formatear nombre de fuente para mostrar"""
	match source:
		"fishing": return "Pesca"
		"dismantling": return "Desmantelar equipos"
		"exploration": return "Exploración"
		"events": return "Eventos especiales"
		"daily_reward": return "Recompensas diarias"
		_: return source.capitalize()

func is_obtainable_from(activity: String) -> bool:
	"""Verificar si se puede obtener de una actividad específica"""
	return source_activities.has(activity)

func get_sell_value() -> int:
	"""Los materiales raros y de tier alto valen más"""
	var tier_multiplier = 1.0 + (crafting_tier - 1) * 0.2 # +20% por tier
	var rarity_multiplier = 1.0 + (rarity * 0.3) # +30% por rareza
	var type_multiplier = 1.0

	# Multiplicador por tipo de material
	match material_type:
		MaterialType.RARE: type_multiplier = 1.5
		MaterialType.ESSENCE: type_multiplier = 2.0
		MaterialType.COMPONENT: type_multiplier = 1.3
		MaterialType.MINERAL: type_multiplier = 1.2
		_: type_multiplier = 1.0

	return int(base_value * tier_multiplier * rarity_multiplier * type_multiplier)

func get_drop_chance() -> float:
	"""Obtener probabilidad de drop ajustada por rareza"""
	var rarity_modifier = 1.0 - (rarity * 0.15) # -15% por nivel de rareza
	return drop_rate * rarity_modifier
