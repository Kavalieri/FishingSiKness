extends Node

# Test de integración para sistema de guardado
func test_save_and_load():
	var save = preload("res://src/autoload/Save.gd").new()
	var data = {
		"schema": 1,
		"coins": 100,
		"gems": 10,
		"zone": "orilla"
	}
	save.save(data)
	var loaded = save.load()
	assert(loaded.schema == 1)
	assert(loaded.coins == 100)
	assert(loaded.zone == "orilla")
