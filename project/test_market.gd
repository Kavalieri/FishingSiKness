extends SceneTree

func _init():
	print("=== Testing MarketView ===")

	# Test zone display names
	var market = preload("res://src/views/MarketView.gd").new()
	print("lake -> ", market.get_zone_display_name("lake"))
	print("mar -> ", market.get_zone_display_name("mar"))
	print("ocean -> ", market.get_zone_display_name("ocean"))

	# Test zone multipliers
	print("lake multiplier: ", market.get_zone_multiplier("lake"))
	print("mar multiplier: ", market.get_zone_multiplier("mar"))
	print("ocean multiplier: ", market.get_zone_multiplier("ocean"))

	print("=== MarketView test complete ===")
	quit()
