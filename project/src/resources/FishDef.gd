class_name FishDef
extends Resource

# TEMPORAL: Volviendo a Resource mientras resolvemos dependencias
# TODO: Migrar a ItemDef una vez que esté todo funcionando

# Propiedades existentes (mantener compatibilidad)
@export var id: String
@export var name: String
@export var description: String = ""
@export var species_category: String = "" # "common", "uncommon", "rare", "epic", "legendary"
@export var rarity: int = 0 # 0..4 (0=common, 1=uncommon, 2=rare, 3=epic, 4=legendary)
@export var base_market_value: int = 10 # Precio base por especie independiente del tamaño
@export var size_min: float = 10.0
@export var size_max: float = 30.0
@export var sprite: Texture2D
@export var habitat_zones: Array[String] = [] # Zonas donde se puede encontrar
@export var difficulty: int = 1 # 1-5, para futuras mecánicas de captura

# Métodos de compatibilidad con ItemDef (sin herencia por ahora)
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

# Métodos específicos para peces
func get_random_size() -> float:
	"""Obtener un tamaño aleatorio dentro del rango"""
	return randf_range(size_min, size_max)

func is_found_in_zone(zone_id: String) -> bool:
	"""Verificar si el pez se encuentra en una zona específica"""
	return habitat_zones.has(zone_id)

func get_species_category_name() -> String:
	"""Obtener nombre de la categoría de especie"""
	if species_category != "":
		return species_category.capitalize()
	else:
		return get_rarity_name()

# Compatibilidad con FishInstance y sistema existente
func create_instance(capture_data: Dictionary = {}) -> Dictionary:
	"""Crear instancia de pez capturado (compatible con sistema actual)"""
	var size = capture_data.get("size", get_random_size())
	var final_value = capture_data.get("value", base_market_value)
	var zone_id = capture_data.get("zone_id", "")

	return {
		"id": id,
		"name": name,
		"size": size,
		"value": final_value,
		"capture_zone_id": zone_id,
		"zone_multiplier": capture_data.get("zone_multiplier", 1.0),
		"capture_timestamp": capture_data.get("timestamp", Time.get_unix_time_from_system()),
		"weight": capture_data.get("weight", size * 0.1), # Estimación peso
		"rarity": rarity,
		"rarity_color": get_rarity_color(),
		"species_category": species_category,
		"description": description,
		"fish_def": self # Referencia para compatibilidad
	}
