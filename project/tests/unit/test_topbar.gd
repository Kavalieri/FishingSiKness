extends Node

# Test unitario para TopBar
func test_set_data():
	var topbar = preload("res://src/ui/TopBar.gd").new()
	topbar.set_data(12345, 120, "Orilla")
	assert(topbar.coins_label.text == "12345")
	assert(topbar.gems_label.text == "120")
	assert(topbar.zone_label.text == "Orilla")
