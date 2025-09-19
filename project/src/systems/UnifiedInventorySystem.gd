# Sistema de Inventario Unificado - Reemplazo completo del sistema fragmentado
extends Node

## Sistema unificado que maneja todos los items del juego con contenedores especializados
## Reemplaza completamente a InventorySystem.gd

signal inventory_updated(container_name: String)

# Contenedores de inventario organizados por categoría
var containers := {}

# Configuración de contenedores por defecto
const CONTAINER_CONFIG := {
	"fishing": {
		"name": "Pesca",
		"capacity": 100,
		"item_types": ["fish"],
		"allow_overflow": false
	},
	"equipment": {
		"name": "Equipamiento",
		"capacity": 30,
		"item_types": ["equipment"],
		"allow_overflow": false
	},
	"consumables": {
		"name": "Consumibles",
		"capacity": 50,
		"item_types": ["consumable"],
		"allow_overflow": false
	},
	"materials": {
		"name": "Materiales",
		"capacity": 200,
		"item_types": ["material", "resource"],
		"allow_overflow": false
	},
	"special": {
		"name": "Items Especiales",
		"capacity": 20,
		"item_types": [], # Sin restricciones
		"allow_overflow": true
	}
}

# Variable para trackear si ya se inicializó
var _initialized := false

func _ready():
	_initialize_system()

func _ensure_initialized():
	"""Garantizar que el sistema esté inicializado antes de usarlo"""
	if not _initialized:
		_initialize_system()

func _initialize_system():
	"""Inicializar el sistema de inventario"""
	if _initialized:
		return

	print("[UnifiedInventorySystem] INICIALIZANDO SISTEMA COMPLETO v3.0")
	print("[UnifiedInventorySystem] Reemplazando sistema anterior...")

	# Inicializar todos los contenedores
	for container_name in CONTAINER_CONFIG:
		_create_container(container_name, CONTAINER_CONFIG[container_name])

	# Migrar datos del sistema anterior si existen
	_migrate_from_legacy()

	_initialized = true
	print("[UnifiedInventorySystem] OK: Sistema unificado activo con %d contenedores" % containers.size())
	print("[UnifiedInventorySystem] Migración completada exitosamente")
	print("[UnifiedInventorySystem] MODO PRODUCCIÓN: Sin peces de prueba automáticos")

func _create_container(container_id: String, config: Dictionary):
	"""Crear un nuevo contenedor de inventario"""
	containers[container_id] = {
		"display_name": config.get("name", container_id.capitalize()),
		"items": [],
		"capacity": config.get("capacity", 100),
		"item_types": config.get("item_types", []),
		"allow_overflow": config.get("allow_overflow", false)
	}

	var capacity = config.get("capacity", 100)
	Logger.info("[UnifiedInventorySystem] OK: Contenedor %s creado (capacidad: %d)" % [container_id, capacity])

# ============================================================================
# API PÚBLICA - Interfaz principal
# ============================================================================

func add_item(item_instance: ItemInstance, container_name: String = "") -> bool:
	"""Añadir un item al inventario"""
	_ensure_initialized()

	if not item_instance:
		Logger.log_error("[UnifiedInventorySystem] Item inválido para añadir")
		return false

	# Determinar contenedor automáticamente si no se especifica
	if container_name.is_empty():
		container_name = _determine_best_container(item_instance)

	if not containers.has(container_name):
		Logger.log_error("[UnifiedInventorySystem] Contenedor inexistente: %s" % container_name)
		return false

	var container = containers[container_name]

	# Verificar restricciones de tipo
	if not _can_store_item_type(item_instance, container):
		Logger.log_error("[UnifiedInventorySystem] Item tipo incompatible con contenedor %s" % container_name)
		return false

	# Intentar apilar con items existentes
	for existing_item in container.items:
		if _can_stack_items(existing_item, item_instance):
			existing_item.stack_count += item_instance.stack_count
			Logger.log("[UnifiedInventorySystem] Item apilado: %s (stack: %d)" % [existing_item.get_display_name(), existing_item.stack_count])
			return true

	# Verificar capacidad
	if not container.allow_overflow and container.items.size() >= container.capacity:
		print("[UnifiedInventorySystem] ERROR: Contenedor %s lleno" % container_name)
		return false

	# Añadir como nuevo item
	# Añadir como nuevo item
	container.items.append(item_instance)
	print("[UnifiedInventorySystem] Nuevo item añadido a %s: %s" % [container_name, item_instance.get_display_name()])
	inventory_updated.emit(container_name)
	return true

func remove_item(item_instance: ItemInstance, container_name: String = "") -> bool:
	"""Remover un item del inventario"""
	if not item_instance:
		return false

	# Buscar en contenedor específico o en todos
	var containers_to_search = [container_name] if not container_name.is_empty() else containers.keys()

	for container_key in containers_to_search:
		if not containers.has(container_key):
			continue

		var container = containers[container_key]
		var index = container.items.find(item_instance)
		if index >= 0:
			container.items.remove_at(index)
			print("[UnifiedInventorySystem] Item removido de %s: %s" % [container_key, item_instance.get_display_name()])
			inventory_updated.emit(container_key)
			return true

	return false

# === ACCESO A CONTENEDORES ===

func get_fishing_container():
	"""Obtener el contenedor de pesca"""
	_ensure_initialized()
	return containers.get("fishing", null)

func get_equipment_container():
	"""Obtener el contenedor de equipamiento"""
	_ensure_initialized()
	return containers.get("equipment", null)

func get_consumables_container():
	"""Obtener el contenedor de consumibles"""
	_ensure_initialized()
	return containers.get("consumables", null)

func get_materials_container():
	"""Obtener el contenedor de materiales"""
	_ensure_initialized()
	return containers.get("materials", null)

func get_special_container():
	"""Obtener el contenedor especial"""
	_ensure_initialized()
	return containers.get("special", null)

func get_items_in_container(container_name: String) -> Array[ItemInstance]:
	"""Obtener todos los items de un contenedor específico"""
	_ensure_initialized()
	if not containers.has(container_name):
		print("[UnifiedInventorySystem] ERROR: Contenedor inexistente: %s" % container_name)
		return []

	return containers[container_name].items.duplicate()

func get_all_items() -> Array[ItemInstance]:
	"""Obtener todos los items del inventario"""
	var all_items: Array[ItemInstance] = []

	for container in containers.values():
		all_items.append_array(container.items)

	return all_items

func get_fish_count() -> int:
	"""Obtener cantidad total de peces (compatibilidad con sistema anterior)"""
	if not containers.has("fishing"):
		return 0

	var total = 0
	for item in containers["fishing"].items:
		total += item.stack_count

	return total

func get_container_info(container_name: String) -> Dictionary:
	"""Obtener información completa de un contenedor"""
	if not containers.has(container_name):
		return {}

	var container = containers[container_name]
	return {
		"name": container.display_name,
		"items": container.items,
		"item_count": container.items.size(),
		"capacity": container.capacity,
		"is_full": container.items.size() >= container.capacity,
		"allow_overflow": container.allow_overflow
	}

# ============================================================================
# MIGRACIÓN Y COMPATIBILIDAD
# ============================================================================

func _migrate_from_legacy():
	"""Migrar datos del sistema InventorySystem anterior"""
	# Verificar si hay datos para migrar del sistema Save
	var save_data = Save.game_data.get("inventory", [])

	if save_data.has("fish"):
		print("[UnifiedInventorySystem] Migrando %d peces del sistema anterior..." % save_data.fish.size())

		for fish_data in save_data.fish:
			var fish_def = _get_fish_def_from_data(fish_data)
			if fish_def:
				var fish_instance = ItemInstance.new()
				fish_instance.setup_from_fish_def(fish_def)

				# Migrar datos específicos del pez si existen
				if fish_data.has("weight"):
					fish_instance.instance_data["weight"] = fish_data.weight
				if fish_data.has("length"):
					fish_instance.instance_data["length"] = fish_data.length

				add_item(fish_instance, "fishing")

		print("[UnifiedInventorySystem] OK: Migración completada: %d peces migrados" % get_fish_count())

func _get_fish_def_from_data(fish_data: Dictionary) -> FishDef:
	"""Obtener definición de pez desde datos de guardado"""
	if not fish_data.has("fish_id"):
		return null

	# Usar sistema Content si está disponible
	if Content and Content.has_category("fish"):
		return Content.get_resource("fish", fish_data.fish_id)

	return null

# ============================================================================
# MÉTODOS DE APOYO INTERNOS
# ============================================================================

func _determine_best_container(item_instance: ItemInstance) -> String:
	"""Determinar el mejor contenedor para un item automáticamente"""
	var item_type = item_instance.get_item_type()

	# Mapeo directo de tipos conocidos
	match item_type:
		"fish":
			return "fishing"
		"equipment", "tool":
			return "equipment"
		"consumable", "potion":
			return "consumables"
		"material", "resource", "crafting":
			return "materials"
		_:
			return "special" # Contenedor por defecto

func _can_store_item_type(item_instance: ItemInstance, container: Dictionary) -> bool:
	"""Verificar si un item puede almacenarse en un contenedor específico"""
	var allowed_types = container.item_types

	# Si no hay restricciones, permitir cualquier tipo
	if allowed_types.is_empty():
		return true

	var item_type = item_instance.get_item_type()
	return item_type in allowed_types

func _can_stack_items(item1: ItemInstance, item2: ItemInstance) -> bool:
	"""Verificar si dos items pueden apilarse"""
	if not item1 or not item2:
		return false

	# Deben tener el mismo item_def_path para poder apilarse
	return item1.item_def_path == item2.item_def_path

# ============================================================================
# API DE COMPATIBILIDAD CON SISTEMA ANTERIOR
# ============================================================================

# Métodos para mantener compatibilidad con el código existente que espera InventorySystem
func add_fish(fish_def: FishDef) -> bool:
	"""Añadir un pez (compatibilidad con sistema anterior)"""
	if not fish_def:
		return false

	var fish_instance = ItemInstance.new()
	fish_instance.setup_from_fish_def(fish_def)

	return add_item(fish_instance, "fishing")

func get_fish() -> Array:
	"""Obtener lista de peces (compatibilidad)"""
	return get_items_in_container("fishing")

func clear_fish():
	"""Limpiar inventario de peces (compatibilidad)"""
	if containers.has("fishing"):
		containers["fishing"].items.clear()
		Logger.log("[UnifiedInventorySystem] Inventario de peces limpiado")

# ============================================================================
# ESTADÍSTICAS Y INFORMACIÓN
# ============================================================================

func get_inventory_stats() -> Dictionary:
	"""Obtener estadísticas completas del inventario"""
	var stats = {}

	for container_name in containers:
		var container = containers[container_name]
		stats[container_name] = {
			"display_name": container.display_name,
			"item_count": container.items.size(),
			"capacity": container.capacity,
			"utilization": float(container.items.size()) / float(container.capacity) * 100.0,
			"is_full": container.items.size() >= container.capacity
		}

	return stats

func print_inventory_debug():
	"""Imprimir información de debug del inventario"""
	print("\n=== UNIFIED INVENTORY DEBUG ===")
	for container_name in containers:
		var container = containers[container_name]
		print("Contenedor [%s]: %d/%d items" % [container.display_name, container.items.size(), container.capacity])
		for item in container.items:
			print("  - %s (x%d)" % [item.get_display_name(), item.stack_count])
	print("================================\n")

# === MÉTODOS DE GUARDADO Y CARGA ===

func get_inventory_for_saving() -> Array:
	"""Obtener inventario en formato compatible para guardado"""
	var save_data = []
	var fishing_container = get_fishing_container()

	if not fishing_container:
		print("[UnifiedInventorySystem] ADVERTENCIA: Contenedor de pesca no disponible para guardado")
		return save_data

	for item_instance in fishing_container["items"]:
		var fish_data = item_instance.to_fish_data()
		if not fish_data.is_empty():
			save_data.append(fish_data)

	print("[UnifiedInventorySystem] Inventario preparado para guardado: %d items" % save_data.size())
	return save_data

func load_from_save(inventory_data: Array):
	"""Cargar inventario desde datos guardados"""
	# Asegurar inicialización con debug mejorado
	_ensure_initialized()

	print("[UnifiedInventorySystem] Cargando desde save: %d items" % inventory_data.size())
	print("[UnifiedInventorySystem] Contenedores disponibles: %s" % str(containers.keys()))

	var fishing_container = get_fishing_container()
	if not fishing_container:
		print("[UnifiedInventorySystem] ERROR: No se pudo cargar - contenedor de pesca no disponible")
		print("[UnifiedInventorySystem] DEBUG: containers = %s" % str(containers))
		print("[UnifiedInventorySystem] DEBUG: _initialized = %s" % str(_initialized))
		# Reintentar inicialización si falló
		_initialize_system()
		fishing_container = get_fishing_container()
		if not fishing_container:
			print("[UnifiedInventorySystem] FATAL: Falló reinicialización - omitiendo carga")
			return

	# Limpiar contenedor actual
	fishing_container["items"].clear()

	# Cargar items
	var loaded_count = 0
	for fish_data in inventory_data:
		var item_instance = ItemInstance.new()
		item_instance.from_fish_data(fish_data)

		if add_item(item_instance, "fishing"):
			loaded_count += 1

	print("[UnifiedInventorySystem] Cargados %d items del save" % loaded_count)
	inventory_updated.emit("fishing")

	# MODO PRODUCCIÓN: No generar peces automáticamente
	if loaded_count == 0:
		print("[UnifiedInventorySystem] Inventario vacío - listo para capturar peces reales")

func clear_all_containers():
	"""Limpiar todos los contenedores"""
	for container_name in containers:
		containers[container_name]["items"].clear()
	print("[UnifiedInventorySystem] Todos los contenedores limpiados")

# === MÉTODOS DE COMPATIBILIDAD CON SISTEMA ANTERIOR ===

func sell_items_by_indices(indices: Array) -> int:
	"""Vender items específicos por sus índices en el contenedor de pesca"""
	var total_earned = 0
	var fishing_container = get_fishing_container()

	if not fishing_container:
		print("[UnifiedInventorySystem] ERROR: Contenedor de pesca no disponible")
		return 0

	# Ordenar índices en orden descendente para evitar problemas al remover
	var sorted_indices = indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()

	for index in sorted_indices:
		if index >= 0 and index < fishing_container.items.size():
			var item = fishing_container.items[index]
			var value = item.get_market_value()
			total_earned += value

			# Remover el item del contenedor
			fishing_container.items.remove_at(index)
			print("[UnifiedInventorySystem] Vendido: %s por %d monedas" % [item.get_display_name(), value])

	# Actualizar dinero del jugador
	if Save:
		Save.add_coins(total_earned)
		print("[UnifiedInventorySystem] Total ganado: %d monedas" % total_earned)

	inventory_updated.emit("fishing")
	return total_earned

func remove_items_by_indices(indices: Array) -> bool:
	"""Remover items por índices (para descarte)"""
	var fishing_container = get_fishing_container()
	if not fishing_container:
		print("[UnifiedInventorySystem] ERROR: Contenedor de pesca no disponible para remover items")
		return false

	# Ordenar índices en orden descendente para evitar problemas al remover
	var sorted_indices = indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()

	var removed_count = 0
	for index in sorted_indices:
		if index >= 0 and index < fishing_container.items.size():
			var item = fishing_container.items[index]
			fishing_container.items.remove_at(index)
			print("[UnifiedInventorySystem] Descartado: %s" % item.get_display_name())
			removed_count += 1

	print("[UnifiedInventorySystem] Total descartado: %d items" % removed_count)
	return removed_count > 0

func clear_fishing_container():
	"""Limpiar completamente el contenedor de pesca"""
	var fishing_container = get_fishing_container()
	if not fishing_container:
		print("[UnifiedInventorySystem] ERROR: Contenedor de pesca no disponible para limpiar")
		return

	var cleared_count = fishing_container.items.size()
	fishing_container.items.clear()
	print("[UnifiedInventorySystem] Contenedor de pesca limpiado: %d items eliminados" % cleared_count)
	inventory_updated.emit("fishing")

func _add_test_fish_if_empty():
	"""DESACTIVADO: Método de prueba deshabilitado en modo producción"""
	print("[UnifiedInventorySystem] MODO PRODUCCIÓN: Generación de peces de prueba desactivada")
	print("[UnifiedInventorySystem] Use el sistema de captura real para obtener peces")
	return

func _setup_test_fish_timer():
	"""DESACTIVADO: Timer de peces de prueba deshabilitado en modo producción"""
	print("[UnifiedInventorySystem] MODO PRODUCCIÓN: Timer de peces de prueba desactivado")
	return

# === MÉTODOS PARA MARKETSCREEN ===

func sell_item(item_instance: ItemInstance) -> bool:
	"""Vender un item específico"""
	if not item_instance:
		return false

	var value = item_instance.get_market_value()
	if remove_item(item_instance, "fishing"):
		if Save:
			Save.add_coins(value)
			print("[UnifiedInventorySystem] Vendido: %s por %d monedas" % [item_instance.get_display_name(), value])
		return true
	return false

func sell_all_fish() -> int:
	"""Vender todos los peces del inventario"""
	var fishing_container = get_fishing_container()
	if not fishing_container:
		return 0

	var total_earned = 0
	var items_to_sell = fishing_container.items.duplicate()

	for item in items_to_sell:
		var value = item.get_market_value()
		total_earned += value

	# Limpiar el contenedor
	fishing_container.items.clear()

	# Actualizar dinero
	if Save:
		Save.add_coins(total_earned)

	print("[UnifiedInventorySystem] Vendidos todos los peces por %d monedas" % total_earned)
	inventory_updated.emit("fishing")
	return total_earned
