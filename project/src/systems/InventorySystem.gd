extends Node

# Sistema de gestión de inventario en memoria (implementado con funciones estáticas como workaround)

# Variable estática para el inventario. No es ideal, pero es necesario para el workaround.
static var _inventory: Array = []

# No se pueden usar señales con métodos estáticos, la UI deberá llamar a refrescar manualmente.

static func load_from_save(inventory_data: Array):
	_inventory = inventory_data
	print("InventorySystem: Inventario cargado con %d peces." % _inventory.size())

static func get_inventory_for_saving() -> Array:
	return _inventory

static func get_inventory() -> Array:
	return _inventory

static func get_inventory_count() -> int:
	return _inventory.size()

static func get_fish_by_index(index: int) -> Dictionary:
	if index >= 0 and index < _inventory.size():
		return _inventory[index]
	return {}

static func add_fish(fish_instance: FishInstance):
	_inventory.append({
		"id": fish_instance.fish_def.id,
		"name": fish_instance.fish_def.name,
		"size": fish_instance.size,
		"value": fish_instance.final_price,
		"capture_zone_id": fish_instance.capture_zone_id,
		"zone_multiplier": fish_instance.zone_multiplier,
		"capture_timestamp": fish_instance.capture_timestamp,
		"weight": fish_instance.weight,
		"rarity": fish_instance.fish_def.rarity,
		"rarity_color": fish_instance.get_rarity_color(),
		"species_category": fish_instance.fish_def.species_category,
		"description": fish_instance.fish_def.description,
		"timestamp": Time.get_unix_time_from_system()
	})

static func sell_fishes(indices: Array) -> int:
	var total_value = 0
	var fishes_to_remove = []
	for index in indices:
		if index >= 0 and index < _inventory.size():
			var fish_data = _inventory[index]
			total_value += fish_data.get("value", 0)
			fishes_to_remove.append(fish_data)

	if total_value > 0:
		var new_inventory = []
		for fish in _inventory:
			if not fish in fishes_to_remove:
				new_inventory.append(fish)
		_inventory = new_inventory

		Save.add_coins(total_value, false)
		SFX.play_event("sell")

	return total_value

static func discard_fishes(indices: Array) -> int:
	var discarded_count = 0
	var fishes_to_remove = []
	for index in indices:
		if index >= 0 and index < _inventory.size():
			fishes_to_remove.append(_inventory[index])

	if not fishes_to_remove.is_empty():
		var new_inventory = []
		for fish in _inventory:
			if not fish in fishes_to_remove:
				new_inventory.append(fish)
		_inventory = new_inventory
		discarded_count = fishes_to_remove.size()
		SFX.play_event("discard")

	return discarded_count

static func sell_all_fish() -> int:
	var all_indices = range(_inventory.size())
	return sell_fishes(all_indices)

static func discard_all_fish() -> int:
	var all_indices = range(_inventory.size())
	return discard_fishes(all_indices)