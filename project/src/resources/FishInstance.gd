class_name FishInstance
extends Resource

@export var fish_def: FishDef
@export var size: float
@export var capture_zone_id: String = ""
@export var zone_multiplier: float = 1.0
@export var final_price: int = 0
@export var capture_timestamp: String = ""
@export var weight: float # Mantener por compatibilidad

var value: int:
	get:
		return final_price

func _init(def: FishDef = null, caught_size: float = 0.0, zone_id: String = "",
		multiplier: float = 1.0):
	if def:
		fish_def = def
		size = caught_size
		capture_zone_id = zone_id
		zone_multiplier = multiplier
		# Peso realista basado en tamaño con variación
		weight = size * randf_range(0.08, 0.12) # Peso más realista

		# Calcular precio final basado en la especie y multiplicador de zona
		final_price = calculate_final_price()

		# Registrar timestamp
		capture_timestamp = Time.get_datetime_string_from_system()

func calculate_final_price() -> int:
	if not fish_def:
		return 0

	# Precio base por especie * multiplicador de zona
	# El tamaño ya no afecta el precio, es solo visual/informativo
	return int(fish_def.base_market_value * zone_multiplier)

# Mantener compatibilidad con código existente
func calculate_value() -> int:
	return calculate_final_price()

func get_display_name() -> String:
	if not fish_def:
		return "Pez desconocido"
	return "%s (%.1fcm)" % [fish_def.name, size]

func get_display_info() -> Dictionary:
	if not fish_def:
		return {}

	return {
		"name": fish_def.name,
		"species": fish_def.species_category if fish_def.species_category else "Especie común",
		"size": "%.1f cm" % size,
		"weight": "%.1f g" % weight,
		"zone": get_zone_display_name(),
		"multiplier": "x%.1f" % zone_multiplier,
		"price": "%d monedas" % final_price,
		"rarity": get_rarity_text(),
		"capture_time": capture_timestamp,
		"description": fish_def.description if fish_def.description else "Un pez común de estas aguas."
	}

func get_zone_display_name() -> String:
	var zone_names = {
		"orilla": "Orilla",
		"lago": "Lago",
		"rio": "Río",
		"costa": "Costa",
		"mar": "Mar Abierto"
	}
	return zone_names.get(capture_zone_id, capture_zone_id.capitalize())

func get_rarity_text() -> String:
	if not fish_def:
		return "Común"

	var rarities = ["Común", "Poco común", "Raro", "Épico", "Legendario"]
	return rarities[fish_def.rarity] if fish_def.rarity < rarities.size() else "Común"

func get_rarity_color() -> Color:
	if not fish_def:
		return Color.WHITE

	var colors = [Color.WHITE, Color.GREEN, Color.BLUE, Color.PURPLE, Color.GOLD]
	return colors[fish_def.rarity] if fish_def.rarity < colors.size() else Color.WHITE
