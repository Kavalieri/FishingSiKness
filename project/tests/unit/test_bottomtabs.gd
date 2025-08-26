extends Node

# Test unitario para BottomTabs
func test_badge():
	var tabs = preload("res://src/ui/BottomTabs.gd").new()
	tabs.set_badge(0, true)
	assert(tabs.badges[0].visible == true)
	tabs.set_badge(0, false)
	assert(tabs.badges[0].visible == false)
