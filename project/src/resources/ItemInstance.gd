class_name ItemInstance
extends Resource

@export var item_def_path: String = ""
@export var stack_count: int = 1
@export var instance_data: Dictionary = {}
@export var creation_timestamp: float = 0.0
@export var last_modified: float = 0.0

func _init():
	creation_timestamp = Time.get_unix_time_from_system()
	last_modified = creation_timestamp

func get_item_def() -> Resource:
	if item_def_path == "":
		return null
	return load(item_def_path)

func set_item_def(item_def: Resource):
	if item_def:
		item_def_path = item_def.resource_path
	else:
		item_def_path = ""
	_mark_modified()

func get_item_type() -> String:
	var item_def = get_item_def()
	if not item_def:
		return ""

	# Verificar si es FishDef
	if item_def.get_script() and item_def.get_script().get_global_name() == "FishDef":
		return "fish"

	# Por defecto, devolver material
	return "material"

func can_stack() -> bool:
	var item_def = get_item_def()
	if not item_def:
		return false

	if item_def.has_method("get_max_stack"):
		return item_def.get_max_stack() > 1
	return false

func is_fish() -> bool:
	var item_def = get_item_def()
	if not item_def:
		return false
	if item_def.get_script() and item_def.get_script().get_global_name() == "FishDef":
		return true
	return false

func to_fish_data() -> Dictionary:
	var item_def = get_item_def()
	if not item_def:
		return {}

	if item_def.get_script() and item_def.get_script().get_global_name() == "FishDef":
		var fish_data = {
			"id": item_def.id,
			"name": item_def.name,
			"description": item_def.description,
			"rarity": item_def.rarity,
			"value": item_def.base_market_value,
			"min_size": item_def.size_min,
			"max_size": item_def.size_max,
			"sprite_path": item_def.sprite.resource_path if item_def.sprite else ""
		}

		for key in instance_data:
			fish_data[key] = instance_data[key]

		return fish_data

	return {}

func setup_from_fish_def(fish_def: FishDef) -> void:
	"""Configurar ItemInstance desde una definición de pez"""
	if not fish_def:
		return

	set_item_def(fish_def)

	# Generar datos aleatorios para el pez
	var size = randf_range(fish_def.size_min, fish_def.size_max)
	var quality = randf_range(0.6, 1.0)
	var value = int(fish_def.base_market_value * quality)

	instance_data = {
		"size": size,
		"value": value,
		"quality": quality,
		"capture_timestamp": Time.get_unix_time_from_system(),
		"rarity_bonus": fish_def.rarity
	}

func from_fish_data(fish_data: Dictionary) -> void:
	var fish_id = fish_data.get("id", "")
	if fish_id == "":
		return

	var fish_def = Content.get_fish_by_id(fish_id)
	if not fish_def:
		return

	set_item_def(fish_def)

	for key in ["size", "value", "capture_zone_id", "zone_multiplier", "capture_timestamp", "rarity_bonus"]:
		if key in fish_data:
			instance_data[key] = fish_data[key]

func get_display_name() -> String:
	var item_def = get_item_def()
	if not item_def:
		return "Item Desconocido"

	var name = "Item"
	if item_def.has_method("get"):
		name = item_def.name

	if stack_count > 1:
		return "%s x%d" % [name, stack_count]

	return name

func _mark_modified():
	last_modified = Time.get_unix_time_from_system()

func to_market_dict() -> Dictionary:
	"""Convertir a formato Dictionary para compatibilidad con MarketView"""
	var fish_def = get_item_def()
	if not fish_def:
		return {}

	var result = {
		"name": fish_def.name,
		"size": instance_data.get("size", 0.0),
		"value": instance_data.get("value", 0),
		"rarity": instance_data.get("rarity_bonus", "común"),
		"weight": fish_def.base_weight,
		"capture_zone_id": instance_data.get("capture_zone_id", "Desconocida"),
		"timestamp": instance_data.get("capture_timestamp", 0),
		"description": fish_def.description if fish_def.has_method("get") and fish_def.has("description") else "Sin descripción"
	}

	return result

func get_market_value() -> int:
	"""Obtener el valor de mercado del item"""
	var item_def = get_item_def()
	if not item_def:
		return 0

	# Si es un pez, usar el valor calculado en instance_data
	if is_fish():
		return instance_data.get("value", item_def.base_market_value if item_def.has_method("get") else 0)

	# Para otros items, usar valor base
	if item_def.has_method("get") and "base_market_value" in item_def:
		return item_def.base_market_value

	return 0

func _to_string() -> String:
	return "ItemInstance(path=%s, count=%d)" % [item_def_path, stack_count]
