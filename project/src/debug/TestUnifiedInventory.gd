# TestUnifiedInventory.gd
# Script de prueba para validar el sistema de inventario unificado

extends Node

func _ready():
	print("=== INICIANDO PRUEBAS DEL SISTEMA UNIFICADO ===")

	# Esperar a que todos los autoloads estén listos
	await get_tree().process_frame

	# Ejecutar pruebas
	test_item_definitions()
	test_item_instances()
	test_inventory_operations()
	test_compatibility()

	print("=== PRUEBAS COMPLETADAS ===")

func test_item_definitions():
	print("\n--- Probando Definiciones de Items ---")

	# Probar ItemDef base
	var base_item = ItemDef.new()
	base_item.id = "test_item"
	base_item.name = "Item de Prueba"
	base_item.rarity = 2
	print("✓ ItemDef creado: " + base_item.get_display_name())
	print("✓ Rareza: " + base_item.get_rarity_name())
	print("✓ Color: " + str(base_item.get_rarity_color()))

	# Probar ConsumableDef
	var consumable = ConsumableDef.new()
	consumable.id = "test_bait"
	consumable.name = "Carnada Especial"
	consumable.consumable_type = ConsumableDef.ConsumableType.BAIT
	consumable.duration = 300.0 # 5 minutos
	consumable.effects = {"bite_chance": 0.25, "fish_value": 0.1}
	print("✓ ConsumableDef creado: " + consumable.get_display_name())
	print("✓ Tipo: " + consumable.get_consumable_type_name())
	print("✓ Duración: " + consumable.get_duration_text())

	# Probar EquipmentDef
	var equipment = EquipmentDef.new()
	equipment.id = "test_rod"
	equipment.name = "Caña de Prueba"
	equipment.equipment_type = EquipmentDef.EquipmentType.ROD
	equipment.tier = 3
	equipment.effects = {"bite_chance": 0.15, "catch_speed": 0.2}
	print("✓ EquipmentDef creado: " + equipment.get_display_name())
	print("✓ Tipo: " + equipment.get_equipment_type_name())
	print("✓ Tier: " + equipment.get_tier_name())

	# Probar MaterialDef
	var material = MaterialDef.new()
	material.id = "test_wood"
	material.name = "Madera Especial"
	material.material_type = MaterialDef.MaterialType.ORGANIC
	material.crafting_tier = 2
	print("✓ MaterialDef creado: " + material.get_display_name())
	print("✓ Tipo: " + material.get_material_type_name())

func test_item_instances():
	print("\n--- Probando Instancias de Items ---")

	# Crear instancia de consumible
	var consumable_instance = ItemInstance.new("test_bait", 5)
	print("✓ ItemInstance creado: " + consumable_instance.get_display_name())
	print("✓ Cantidad: %d" % consumable_instance.quantity)
	print("✓ Valor total: %d" % consumable_instance.get_total_value())

	# Crear instancia de pez (único)
	var fish_instance = ItemInstance.new("test_fish", 1)
	fish_instance.instance_data = {
		"size": 25.5,
		"capture_zone_id": "test_zone",
		"capture_timestamp": Time.get_unix_time_from_system()
	}
	print("✓ Fish instance creado con datos únicos")
	print("✓ Tamaño: %.1f cm" % fish_instance.get_instance_data("size"))

func test_inventory_operations():
	print("\n--- Probando Operaciones de Inventario ---")

	if not UnifiedInventorySystem:
		print("❌ UnifiedInventorySystem no disponible")
		return

	# Probar agregar items
	var test_item = ItemInstance.new("test_consumable", 10)
	if UnifiedInventorySystem.add_item(test_item, "consumables"):
		print("✓ Item agregado al inventario")
	else:
		print("❌ Error agregando item")

	# Probar obtener items
	var items = UnifiedInventorySystem.get_items("consumables")
	print("✓ Items en consumibles: %d" % items.size())

	# Probar información de contenedores
	var container_info = UnifiedInventorySystem.get_container_info("consumables")
	if not container_info.is_empty():
		var slots_text = "%d/%d slots usados" % [container_info.used_slots, container_info.max_slots]
		print("✓ Contenedor 'consumables': " + slots_text)

func test_compatibility():
	print("\n--- Probando Compatibilidad con Sistema Existente ---")

	# Verificar que InventorySystem sigue funcionando
	if InventorySystem:
		var existing_fish = InventorySystem.get_inventory()
		print("✓ InventorySystem disponible con %d peces" % existing_fish.size())

		# Si hay peces, probar conversión
		if not existing_fish.is_empty():
			var first_fish = existing_fish[0]
			var fish_instance = ItemInstance.new()
			fish_instance.item_id = first_fish.get("id", "unknown")
			fish_instance.instance_data = first_fish.duplicate()

			var converted_data = fish_instance.to_fish_data()
			if not converted_data.is_empty():
				print("✓ Conversión de datos de pez exitosa")
			else:
				print("❌ Error en conversión de datos")

	# Verificar que Content puede cargar definiciones
	if Content:
		var fish_defs = Content.all_fish()
		print("✓ Content disponible con %d definiciones de peces" % fish_defs.size())

		# Probar compatibilidad con FishDef extendido
		if not fish_defs.is_empty():
			var first_fish_def = fish_defs[0]
			if first_fish_def is ItemDef:
				print("✓ FishDef extiende correctamente ItemDef")
				print("✓ Tipo de item: %s" % ItemDef.ItemType.keys()[first_fish_def.item_type])
			else:
				print("❌ FishDef no extiende ItemDef correctamente")

# Función para ejecutar desde consola
func run_full_test():
	"""Ejecutar todas las pruebas manualmente"""
	test_item_definitions()
	test_item_instances()
	test_inventory_operations()
	test_compatibility()
