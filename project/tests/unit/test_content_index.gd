extends Node

# Test unitario para ContentIndex
func test_load_all():
	var content_index = preload("res://src/systems/ContentIndex.gd").new()
	var result = content_index.load_all()
	assert(result is Dictionary)
	assert(result.has("fish"))
	assert(result.has("zones"))
	assert(result.has("loot_tables"))
	assert(result.has("equipment"))
	assert(result.has("upgrades"))
	assert(result.has("store"))
