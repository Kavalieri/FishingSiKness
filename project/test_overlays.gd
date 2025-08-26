extends SceneTree

func _init():
	print("=== Testing Overlay Positioning ===")

	var screen_manager = preload("res://src/ui/ScreenManager.gd").new()
	screen_manager.name = "ScreenManager"
	current_scene = screen_manager

	print("Testing StoreView positioning...")
	var store_view = preload("res://src/views/StoreView.gd").new()
	print("StoreView anchor_left: ", store_view.anchor_left)
	print("StoreView anchor_right: ", store_view.anchor_right)
	print("StoreView anchor_top: ", store_view.anchor_top)
	print("StoreView anchor_bottom: ", store_view.anchor_bottom)

	print("Testing MilestonesPanel positioning...")
	var milestones = preload("res://src/views/MilestonesPanel.gd").new()
	print("MilestonesPanel anchor_left: ", milestones.anchor_left)
	print("MilestonesPanel anchor_right: ", milestones.anchor_right)
	print("MilestonesPanel anchor_top: ", milestones.anchor_top)
	print("MilestonesPanel anchor_bottom: ", milestones.anchor_bottom)

	print("=== Test completed ===")
	quit()
