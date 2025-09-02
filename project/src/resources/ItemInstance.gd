class_name ItemInstance
extends Resource

# Clase para instancias específicas de items en el inventario
# Maneja datos únicos de cada item individual y stacking

@export var item_def_path: String = "" # Ruta al ItemDef resource
@export var stack_count: int = 1 # Cantidad en este stack
@export var instance_data: Dictionary = {} # Datos específicos de la instancia
@export var creation_timestamp: float = 0.0 # Cuándo se creó/obtuvo
@export var last_modified: float = 0.0 # Última modificación

func _init():
	creation_timestamp = Time.get_unix_time_from_system()
	last_modified = creation_timestamp

# === Gestión de ItemDef ===
func get_item_def() -> Resource:
	"""Obtener el ItemDef asociado (con carga lazy)"""
	if item_def_path == "":
		return null

	var loaded_def = load(item_def_path)
	if not loaded_def:
		Logger.log_error("[ItemInstance] No se pudo cargar ItemDef: %s" % item_def_path)
		return null

	return loaded_def

func set_item_def(item_def: Resource):
	"""Establecer ItemDef y actualizar path"""
	if item_def:
		item_def_path = item_def.resource_path
	else:
		item_def_path = ""
	_mark_modified()

# === Stacking y Cantidad ===
func can_stack() -> bool:
	"""Verificar si este item puede apilarse"""
	var item_def = get_item_def()
	if not item_def:
		return false

	# Si tiene método max_stack, usarlo
	if item_def.has_method("get_max_stack"):
		return item_def.get_max_stack() > 1

	# Si tiene propiedad max_stack, usarla
	if item_def.has_method("get") and item_def.get("max_stack") != null:
		return item_def.max_stack > 1

	# Por defecto, items únicos no se apilan
	return not _has_unique_instance_data()

func can_stack_with(other_item: ItemInstance) -> bool:
	"""Verificar si se puede apilar con otro item"""
	if not other_item or not can_stack():
		return false

	# Deben ser el mismo tipo de item
	if item_def_path != other_item.item_def_path:
		return false

	# No pueden tener datos únicos diferentes
	if _has_unique_instance_data() or other_item._has_unique_instance_data():
		return false

	return true

func add_stack(amount: int) -> bool:
	"""Añadir al stack actual"""
	var item_def = get_item_def()
	if not item_def:
		return false

	var max_stack = 1
	if item_def.has_method("get_max_stack"):
		max_stack = item_def.get_max_stack()
	elif item_def.has_method("get") and item_def.get("max_stack") != null:
		max_stack = item_def.max_stack

	if stack_count + amount <= max_stack:
		stack_count += amount
		_mark_modified()
		return true

	return false

func remove_stack(amount: int) -> bool:
	"""Remover del stack actual"""
	if amount >= stack_count:
		stack_count = 0
		return true

	stack_count -= amount
	_mark_modified()
	return stack_count > 0

func split_stack(amount: int) -> ItemInstance:
	"""Dividir stack y retornar nuevo ItemInstance"""
	if amount >= stack_count:
		return null

	# Crear nueva instancia
	var new_instance = ItemInstance.new()
	new_instance.item_def_path = item_def_path
	new_instance.stack_count = amount
	new_instance.instance_data = instance_data.duplicate(true)

	# Reducir este stack
	stack_count -= amount
	_mark_modified()

	return new_instance

# === Datos de Instancia ===
func get_instance_value(key: String, default_value = null):
	"""Obtener valor de datos de instancia"""
	return instance_data.get(key, default_value)

func set_instance_value(key: String, value):
	"""Establecer valor de datos de instancia"""
	instance_data[key] = value
	_mark_modified()

func _has_unique_instance_data() -> bool:
	"""Verificar si tiene datos únicos que impiden el apilado"""
	# Peces siempre son únicos (por tamaño, zona de captura, etc.)
	var item_def = get_item_def()
	if item_def and item_def.get_script() and item_def.get_script().get_global_name() == "FishDef":
		return true

	# Items con tamaño, durabilidad, etc. son únicos
	var unique_keys = ["size", "durability", "enchantments", "capture_zone_id"]
	for key in unique_keys:
		if instance_data.has(key):
			return true

	return false

# === Compatibilidad ===
func to_fish_data() -> Dictionary:
	"""Convertir a formato compatible con sistema de peces anterior"""
	var item_def = get_item_def()
	if not item_def:
		return {}

	# Si es FishDef, usar sus datos + instance_data
	if item_def.get_script() and item_def.get_script().get_global_name() == "FishDef":
		var fish_data = {
			"id": item_def.id,
			"name": item_def.name,
			"rarity": item_def.rarity,
			"description": item_def.description,
			"species_category": item_def.species_category,
			"sprite": item_def.sprite
		}

		# Añadir datos de instancia
		for key in instance_data:
			fish_data[key] = instance_data[key]

		return fish_data

	return {}

func from_fish_data(fish_data: Dictionary):
	"""Crear desde datos de pez del sistema anterior"""
	# Buscar FishDef correspondiente
	var fish_id = fish_data.get("id", "")
	if fish_id == "":
		return

	# Buscar el recurso FishDef
	var fish_def = Content.get_fish_by_id(fish_id)
	if not fish_def:
		Logger.log_error("[ItemInstance] FishDef no encontrado: %s" % fish_id)
		return

	# Configurar instance
	item_def_path = fish_def.resource_path
	stack_count = 1 # Peces son únicos

	# Copiar datos específicos del pez
	var keys_to_copy = ["size", "value", "capture_zone_id", "zone_multiplier",
						"capture_timestamp", "weight"]
	for key in keys_to_copy:
		if fish_data.has(key):
			instance_data[key] = fish_data[key]

# === Utilidades ===
func get_display_name() -> String:
	"""Obtener nombre para mostrar"""
	var item_def = get_item_def()
	if not item_def:
		return "Item Desconocido"

	var name = item_def.name if item_def.has_method("get") else "Item"

	if stack_count > 1:
		return "%s x%d" % [name, stack_count]
	else:
		return name

func get_total_value() -> int:
	"""Obtener valor total (base × cantidad)"""
	var item_def = get_item_def()
	if not item_def:
		return 0

	var base_value = 0
	if item_def.has_method("get_sell_value"):
		base_value = item_def.get_sell_value()
	elif item_def.has_method("get") and item_def.get("base_market_value") != null:
		base_value = item_def.base_market_value

	return base_value * stack_count

func get_market_value() -> int:
	"""Alias para get_total_value() - compatibilidad con sistema anterior"""
	return get_total_value()

func _mark_modified():
	"""Marcar como modificado"""
	last_modified = Time.get_unix_time_from_system()
