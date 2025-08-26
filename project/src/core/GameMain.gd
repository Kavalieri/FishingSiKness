extends Control

const SPLASH_SCENE = preload("res://scenes/views/SplashScreen.tscn")
const MAIN_GAME_SCENE = preload("res://scenes/core/Main.tscn")

func _ready():
	print("🎮 GameMain: Inicializando sistema limpio...")

	# Cargar autoloads si no están disponibles
	await ensure_autoloads_ready()

	# Cargar y mostrar splash screen desde .tscn
	show_splash_screen()

func ensure_autoloads_ready():
	"""Asegurar que los autoloads estén listos"""
	var max_wait = 60
	var wait_count = 0

	while (not Save or not Content or not SFX) and wait_count < max_wait:
		await get_tree().process_frame
		wait_count += 1

	if wait_count >= max_wait:
		print("⚠️ Warning: Some autoloads may not be ready")

func show_splash_screen():
	"""Mostrar splash screen desde .tscn"""
	var splash_instance = SPLASH_SCENE.instantiate()

	# Conectar señal de finalización
	splash_instance.splash_finished.connect(_on_splash_finished)

	# Agregar a la escena
	add_child(splash_instance)
	print("✅ Splash Screen cargado desde .tscn limpio")

func _on_splash_finished():
	"""Manejar finalización de splash screen"""
	print("🎯 Splash finalizado - cargando juego principal...")

	# Eliminar solo el splash screen, no todos los hijos
	var splash_screen = null
	for child in get_children():
		if child.has_signal("splash_finished"):
			splash_screen = child
			break

	if splash_screen:
		splash_screen.queue_free()
		# Esperar a que se elimine completamente antes de cargar Main
		await splash_screen.tree_exited

	# Cargar juego principal
	load_main_game()

func load_main_game():
	"""Cargar la interfaz principal del juego"""
	var main_instance = MAIN_GAME_SCENE.instantiate()
	add_child(main_instance)
	print("🎮 Juego principal cargado")
