class_name GameMain
extends Control

var splash_screen: SplashScreen
var main_game_ui: Control

func _ready():
	print("GameMain: Initializing...")

	# Cargar autoloads si no están disponibles
	await ensure_autoloads_ready()

	# Crear y mostrar splash screen
	create_splash_screen()

func ensure_autoloads_ready():
	"""Asegurar que los autoloads estén listos"""
	var max_wait = 60 # frames máximo
	var wait_count = 0

	while (not Save or not Content or not SFX) and wait_count < max_wait:
		await get_tree().process_frame
		wait_count += 1

	if wait_count >= max_wait:
		print("Warning: Some autoloads may not be ready")

func create_splash_screen():
	"""Crear y mostrar la splash screen"""
	splash_screen = preload("res://src/views/SplashScreen.gd").new()
	splash_screen.splash_finished.connect(_on_splash_finished)

	# Configurar splash screen para pantalla completa
	splash_screen.anchor_right = 1.0
	splash_screen.anchor_bottom = 1.0

	add_child(splash_screen)
	print("GameMain: Splash screen created")

func _on_splash_finished():
	"""Manejar finalización de splash screen"""
	print("GameMain: Splash finished, loading main game...")

	# Remover splash screen
	if splash_screen:
		splash_screen.queue_free()
		splash_screen = null

	# Cargar interfaz principal del juego
	load_main_game()

func load_main_game():
	"""Cargar la interfaz principal del juego"""
	# Cargar la escena del juego principal (Main.tscn contiene ScreenManager)
	var MainScene = preload("res://scenes/core/Main.tscn")
	main_game_ui = MainScene.instantiate()

	# Configurar para pantalla completa
	main_game_ui.anchor_right = 1.0
	main_game_ui.anchor_bottom = 1.0

	add_child(main_game_ui)

	print("GameMain: Main game UI loaded and ready")

func _input(event):
	"""Manejar entrada global si es necesario"""
	# Debug: Presionar F12 para volver a splash screen (solo desarrollo)
	if OS.is_debug_build() and event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_F12):
		restart_with_splash()

func restart_with_splash():
	"""Reiniciar con splash screen (solo para desarrollo)"""
	if main_game_ui:
		main_game_ui.queue_free()
		main_game_ui = null

	create_splash_screen()
