extends Node
## Script de prueba para validar TODOS los menús flotantes estandarizados

func _ready():
	print("=== PRUEBA SISTEMA MENÚS FLOTANTES COMPLETO ===")

	# Esperar un poco antes de las pruebas
	await get_tree().create_timer(1.0).timeout

	test_all_floating_menus()

func test_all_floating_menus():
	"""Probar todos los menús flotantes estandarizados"""
	print("🧪 Probando TODOS los menús flotantes...")

	# Buscar ScreenManager
	var screen_manager = get_tree().get_first_node_in_group("ScreenManager")
	if not screen_manager:
		print("❌ ERROR: No se encontró ScreenManager")
		return

	print("✅ ScreenManager encontrado")

	# Test 1: Tarjeta de captura (FishCardMenu)
	test_fish_card_menu(screen_manager)
	await get_tree().create_timer(2.0).timeout

	# Test 2: Tienda de gemas (StoreView)
	test_store_menu(screen_manager)
	await get_tree().create_timer(2.0).timeout

	# Test 3: Panel de hitos (MilestonesPanel)
	test_milestones_menu(screen_manager)
	await get_tree().create_timer(2.0).timeout

	# Test 4: Menú de pausa (PauseMenu)
	test_pause_menu(screen_manager)
	await get_tree().create_timer(2.0).timeout

	# Test 5: Menú de configuración (SettingsMenu)
	test_settings_menu(screen_manager)
	await get_tree().create_timer(2.0).timeout

	print("🎉 TODAS LAS PRUEBAS COMPLETADAS")

func test_fish_card_menu(screen_manager: ScreenManager):
	"""Probar tarjeta de captura de pez"""
	print("🐟 Probando FishCardMenu...")
	var test_fish_data = {
		"name": "Trucha Arcoíris",
		"value": 150,
		"rarity": "poco común",
		"zone": "Río Montañoso"
	}
	screen_manager.show_fish_card(test_fish_data)
	print("✅ FishCardMenu mostrado")

func test_store_menu(screen_manager: ScreenManager):
	"""Probar tienda de gemas"""
	print("💎 Probando StoreView...")
	screen_manager.show_store()
	print("✅ StoreView mostrado")

func test_milestones_menu(screen_manager: ScreenManager):
	"""Probar panel de hitos"""
	print("🏆 Probando MilestonesPanel...")
	screen_manager.show_milestones_panel()
	print("✅ MilestonesPanel mostrado")

func test_pause_menu(screen_manager: ScreenManager):
	"""Probar menú de pausa"""
	print("⏸️ Probando PauseMenu...")
	screen_manager.show_pause_menu()
	print("✅ PauseMenu mostrado")

func test_settings_menu(screen_manager: ScreenManager):
	"""Probar menú de configuración"""
	print("⚙️ Probando SettingsMenu...")
	screen_manager.show_settings_menu()
	print("✅ SettingsMenu mostrado")

func close_all_menus():
	"""Cerrar todos los menús flotantes"""
	print("🧹 Cerrando todos los menús...")
	var root = get_tree().root
	for child in root.get_children():
		if child.has_method("_on_close_pressed") or child.has_method("close_requested"):
			child.queue_free()
			print("✅ Menú cerrado:", child.name)

func _input(event):
	"""Atajos de teclado para pruebas"""
	if event.is_action_pressed("ui_accept"):
		test_all_floating_menus()
	elif event.is_action_pressed("ui_cancel"):
		close_all_menus()
