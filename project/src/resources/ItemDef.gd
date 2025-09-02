class_name ItemDef
extends Resource

# Clase base para todos los items del sistema de inventario unificado
# Proporciona propiedades y funcionalidades comunes

# Enum para tipos de items
enum ItemType {
	FISH = 0,
	EQUIPMENT = 1,
	CONSUMABLE = 2,
	MATERIAL = 3,
	MISC = 4
}

# Propiedades básicas comunes a todos los items
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MISC
@export var rarity: int = 0 # 0=común, 1=poco común, 2=raro, 3=épico, 4=legendario
@export var base_value: int = 0 # Valor base en coins
@export var max_stack: int = 1 # Cantidad máxima por stack (1 = no apilable)
@export var tags: Array[String] = [] # Tags para filtrado y categorización
@export var is_sellable: bool = true # Se puede vender
@export var is_tradeable: bool = false # Se puede intercambiar (futuro)

# Métodos virtuales que pueden ser sobrescritos por clases hijas
func get_display_name() -> String:
	"""Obtener nombre para mostrar en UI"""
	return name if name != "" else id

func get_tooltip_text() -> String:
	"""Obtener texto para tooltip"""
	var tooltip = get_display_name()
	if description != "":
		tooltip += "\n" + description
	if base_value > 0:
		tooltip += "\n💰 Valor: %d coins" % base_value
	return tooltip

func get_rarity_name() -> String:
	"""Obtener nombre de rareza"""
	match rarity:
		0: return "Común"
		1: return "Poco Común"
		2: return "Raro"
		3: return "Épico"
		4: return "Legendario"
		_: return "Desconocido"

func get_rarity_color() -> Color:
	"""Obtener color asociado a la rareza"""
	match rarity:
		0: return Color.WHITE
		1: return Color.GREEN
		2: return Color.BLUE
		3: return Color.PURPLE
		4: return Color.GOLD
		_: return Color.GRAY

func has_tag(tag: String) -> bool:
	"""Verificar si el item tiene un tag específico"""
	return tags.has(tag)

func get_sell_value() -> int:
	"""Obtener valor de venta (puede ser sobrescrito por clases hijas)"""
	return base_value

func can_stack_with(other: ItemDef) -> bool:
	"""Verificar si se puede apilar con otro item"""
	if max_stack <= 1:
		return false
	return id == other.id

# Método de utilidad para debugging
func to_string() -> String:
	var type_name = ItemType.keys()[item_type]
	return "ItemDef(id=%s, name=%s, type=%s, rarity=%d)" % [id, name, type_name, rarity]
