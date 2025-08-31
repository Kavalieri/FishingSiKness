extends Control

const SPLASH_SCENE = preload("res://scenes/views/SplashScreen.tscn")
const MAIN_GAME_SCENE = preload("res://scenes/ui_new/Main.tscn")

var main_game_instance: Control

func _ready():
	print("🎮 GameMain: Initializing...")
	await get_tree().process_frame

	# 1. Instantiate the main game scene but keep it invisible and paused.
	main_game_instance = MAIN_GAME_SCENE.instantiate()
	main_game_instance.visible = false
	main_game_instance.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(main_game_instance)
	print("✅ Main game instance created and paused.")

	# 2. Show the splash screen.
	show_splash_screen()

func show_splash_screen():
	var splash_instance = SPLASH_SCENE.instantiate()

	# Connect signals
	splash_instance.splash_finished.connect(_on_splash_finished)

	# Connect pause to PauseManager (nueva arquitectura)
	if PauseManager:
		splash_instance.pause_requested.connect(PauseManager.request_pause_menu)
		print("✅ Connected splash screen's pause_requested to PauseManager")
	else:
		print("ERROR: PauseManager no disponible")

	add_child(splash_instance)
	print("✅ Splash Screen loaded.")

func _on_splash_finished():
	print("🎯 Splash finished - transitioning to main game...")

	# Free the splash screen
	var splash_screen = null
	for child in get_children():
		if child is Control and child.has_signal("splash_finished"):
			splash_screen = child
			break
	if splash_screen:
		splash_screen.queue_free()
		await splash_screen.tree_exited

	# 3. Make the main game visible and active.
	if main_game_instance:
		main_game_instance.visible = true
		main_game_instance.process_mode = Node.PROCESS_MODE_INHERIT
		print("🎮 Main game is now active.")
