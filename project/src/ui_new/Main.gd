extends Control
class_name MainUI
## Controlador principal de la interfaz de usuario
##
## Implementa la arquitectura UI-BG-GLOBAL donde:
## - Un solo fondo visual se cambia dinámicamente
## - Todos los elementos UI son transparentes y van encima
## - Responsive design con Safe Area y escalado por porcentajes
##
## Componentes principales:
## - TopBar: barra superior con botones funcionales
## - CentralHost: área central que carga pantallas dinámicas
## - BottomBar: navegación principal con 5 tabs

# Referencias a nodos UI principales
@onready var background: TextureRect = $Background
@onready var topbar: Control = $VBoxContainer/TopBar
@onready var central_host: Control = $VBoxContainer/CentralHost
@onready var bottombar: Control = $VBoxContainer/BottomBar

func _ready() -> void:
	"""Inicialización principal del UI"""
	print("[Main] === INICIANDO MAIN UI ===")
	print("[Main] Resolución: ", get_viewport().get_visible_rect().size)

	# Setup diferido para asegurar que todos los nodos estén listos
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	"""Setup diferido ejecutado después de _ready"""
	print("[MAIN] === SETUP DIFERIDO ===")

	# Verificar referencias críticas
	_verify_node_references()

	# Configurar fondo inicial
	_setup_background()

	# Conectar señales de navegación
	_connect_navigation_signals()

	# Cargar pantalla inicial
	_load_initial_screen()

	print("[MAIN] === MAIN UI INICIALIZADO ===")

func _verify_node_references() -> void:
	"""Verificar que todas las referencias de nodo son válidas"""
	var components = {
		"Background": background,
		"TopBar": topbar,
		"CentralHost": central_host,
		"BottomBar": bottombar
	}

	print("[MAIN] === VERIFICANDO COMPONENTES ===")
	for name in components.keys():
		var node = components[name]
		if node:
			print("[MAIN] OK %s: (%s)" % [name, node.get_class()])
		else:
			print("[MAIN] ERROR %s: FALTA - PATH INCORRECTO" % name)

func _setup_background() -> void:
	"""Configurar fondo inicial del juego"""
	if background:
		print("[Main] Configurando fondo inicial...")
		# Cargar fondo basado en zona actual guardada
		var current_zone_id = ""
		if Save and Save.game_data.has("current_zone"):
			current_zone_id = Save.game_data.current_zone

		if current_zone_id != "" and Content:
			# Usar el sistema de zonas nuevo
			var zone_def = Content.get_zone_by_id(current_zone_id)
			if zone_def and zone_def.background != "":
				var bg_name = zone_def.background.get_file().get_basename()
				print("[Main] Fondo inicial basado en zona guardada: %s → %s" % [current_zone_id, bg_name])
				set_background(bg_name)
				return

		# Fallback: usar fondo por defecto
		print("[Main] Usando fondo por defecto: main")
		set_background("main")
	else:
		print("[Main] ❌ No se pudo configurar fondo - nodo Background no encontrado")

func _connect_navigation_signals() -> void:
	"""Conectar señales de navegación principales"""
	print("[MAIN] === CONECTANDO SEÑALES ===")

	# Señal crítica: BottomBar → Main
	print("[MAIN] Verificando conexión BottomBar...")
	print("[MAIN] BottomBar existe: %s" % (bottombar != null))
	if bottombar:
		print("[MAIN] BottomBar clase: %s" % bottombar.get_class())
		print("[MAIN] Tiene señal tab_selected: %s" % bottombar.has_signal("tab_selected"))
		if bottombar.has_signal("tab_selected"):
			if not bottombar.tab_selected.is_connected(_on_tab_selected):
				bottombar.tab_selected.connect(_on_tab_selected)
				print("[MAIN] OK BottomBar.tab_selected -> Main._on_tab_selected CONECTADA")
			else:
				print("[MAIN] WARNING: Señal BottomBar ya conectada")
		else:
			print("[MAIN] ERROR: BottomBar no tiene señal 'tab_selected'")
			var signals = bottombar.get_signal_list()
			print("[MAIN] Señales disponibles: ", signals)
	else:
		print("[MAIN] ERROR: BottomBar es null")

	# Señal TopBar → Main
	if topbar and topbar.has_signal("button_pressed"):
		if not topbar.button_pressed.is_connected(_on_topbar_button_pressed):
			topbar.button_pressed.connect(_on_topbar_button_pressed)
			print("[Main] ✓ TopBar.button_pressed → Main._on_topbar_button_pressed")
	else:
		print("[Main] ⚠️ TopBar sin señal 'button_pressed' o no existe")

	print("[MAIN] === FIN CONEXIÓN SEÑALES ===")

func _load_initial_screen() -> void:
	"""Cargar pantalla inicial del juego"""
	if central_host and central_host.has_method("show_screen"):
			print("[MAIN] Cargando pantalla inicial: FishingScreen")
		central_host.show_screen("res://scenes/ui_new/screens/FishingScreen.tscn")
	else:
		print("[MAIN] ERROR: No se pudo cargar pantalla inicial - CentralHost no válido")

## API pública para manejo de fondos
func set_background(zone_id: String) -> void:
	"""
	Cambiar el fondo visual basado en la zona
	Esta es la API principal de UI-BG-GLOBAL
	"""
	if not background:
		print("[Main] ❌ set_background: TextureRect Background no existe")
		return

	var bg_path = "res://art/env/%s.png" % zone_id
	var bg_texture = load(bg_path) as Texture2D

	if bg_texture:
		background.texture = bg_texture
		print("[Main] ✓ Fondo cambiado a: %s" % zone_id)
	else:
		print("[Main] ❌ No se pudo cargar fondo: %s" % bg_path)
		# Fallback al fondo principal
		var main_bg = load("res://art/env/main.png") as Texture2D
		if main_bg:
			background.texture = main_bg
			print("[Main] ✓ Fondo fallback aplicado: main")

# Handlers de señales
func _on_tab_selected(tab_name: String) -> void:
	"""Manejar selección de tabs desde BottomBar"""
	print("[MAIN] ========== SEÑAL RECIBIDA ===========")
	print("[MAIN] Tab seleccionado: %s" % tab_name)

	if not central_host or not central_host.has_method("show_screen"):
		print("[Main] ❌ CentralHost no disponible")
		return

	# Mapping tab → screen
	var screen_paths = {
		"fishing": "res://scenes/ui_new/screens/FishingScreen.tscn",
		"map": "res://scenes/ui_new/screens/MapScreen.tscn",
		"market": "res://scenes/ui_new/screens/MarketScreen.tscn",
		"upgrades": "res://scenes/ui_new/screens/UpgradesScreen.tscn",
		"prestige": "res://scenes/ui_new/screens/PrestigeScreen.tscn"
	}

	if tab_name in screen_paths:
		var screen_path = screen_paths[tab_name]
		print("[MAIN] -> Cambiando a pantalla: %s" % screen_path)
		central_host.show_screen(screen_path)
		print("[MAIN] Pantalla cargada exitosamente")

		# Conectar señal de selección de zona si es MapScreen
		if tab_name == "map":
			_connect_map_screen_signals()

		# Cambiar fondo si es necesario
		_update_background_for_screen(tab_name)
	else:
		print("[MAIN] ERROR: Tab desconocido: %s" % tab_name)

func _connect_map_screen_signals() -> void:
	"""Conectar señales específicas del MapScreen cuando se carga"""
	print("[Main] DEBUG: Conectando señales de MapScreen...")

	# Esperar un frame para que la pantalla se haya cargado completamente
	await get_tree().process_frame

	# Buscar el MapScreen en el CentralHost
	var map_screen = central_host.get_current_screen()
	print("[Main] DEBUG: MapScreen obtenido: %s" % (map_screen != null))

	if map_screen:
		print("[Main] DEBUG: MapScreen clase: %s" % map_screen.get_class())
		print("[Main] DEBUG: MapScreen tiene zone_selected: %s" % map_screen.has_signal("zone_selected"))

		if map_screen.has_signal("zone_selected"):
			# Desconectar señal previa si existe
			if map_screen.zone_selected.is_connected(_on_zone_changed):
				map_screen.zone_selected.disconnect(_on_zone_changed)
				print("[Main] DEBUG: Señal previa desconectada")

			# Conectar señal de zona seleccionada
			map_screen.zone_selected.connect(_on_zone_changed)
			print("[Main] ✅ MapScreen.zone_selected conectado → Main._on_zone_changed")
		else:
			print("[Main] ❌ MapScreen sin señal zone_selected")
	else:
		print("[Main] ❌ MapScreen no encontrado")

func _on_topbar_button_pressed(button_type: String) -> void:
	"""Manejar botones de TopBar"""
	print("[Main] Botón TopBar presionado: %s" % button_type)

	match button_type:
		"money":
			_show_economy_popup()
		"gems":
			_show_gems_store()
		"zone":
			_show_zone_selector()
		"social":
			_show_social_menu()
		"pause":
			_show_pause_menu()
		"xp":
			_show_xp_details()
		_:
			print("[Main] ❌ Botón TopBar desconocido: %s" % button_type)

func _update_background_for_screen(screen_name: String) -> void:
	"""Actualizar fondo según la pantalla activa"""
	match screen_name:
		"fishing":
			# Mantener fondo de zona actual (no cambiar)
			print("[Main] Pantalla fishing: manteniendo fondo de zona actual")
			pass
		"map":
			# Mantener fondo de zona actual (el usuario seleccionará zona aquí)
			print("[Main] Pantalla map: manteniendo fondo de zona actual")
			pass
		"market":
			# NO cambiar fondo - mantener el de la zona actual
			print("[Main] Pantalla market: manteniendo fondo de zona actual")
			pass
		"upgrades":
			# NO cambiar fondo - mantener el de la zona actual
			print("[Main] Pantalla upgrades: manteniendo fondo de zona actual")
			pass
		"prestige":
			# NO cambiar fondo - mantener el de la zona actual
			print("[Main] Pantalla prestige: manteniendo fondo de zona actual")
			pass

# Métodos auxiliares para TopBar
func _show_economy_popup() -> void:
	"""Mostrar popup detallado de economía"""
	print("[Main] TODO: Implementar popup de economía")

func _show_gems_store() -> void:
	"""Mostrar tienda de gemas premium"""
	print("[Main] Abriendo tienda de gemas")
	central_host.show_screen("res://scenes/ui_new/screens/StoreScreen.tscn")

func _show_zone_selector() -> void:
	"""Mostrar selector rápido de zona"""
	# Por ahora llevar al mapa
	if central_host:
		central_host.show_screen("res://scenes/ui_new/screens/MapScreen.tscn")

func _show_social_menu() -> void:
	"""Mostrar menú social"""
	print("[Main] TODO: Implementar menú social")

func _show_pause_menu() -> void:
	"""Mostrar menú de pausa/opciones"""
	print("[Main] TODO: Implementar menú de pausa")

func _show_xp_details() -> void:
	"""Mostrar detalles de experiencia"""
	print("[Main] TODO: Implementar detalles de XP")

# Métodos para eventos del juego (llamados por las pantallas)
func _on_zone_changed(new_zone_id: String) -> void:
	"""Llamado cuando se cambia de zona de pesca"""
	print("[Main] 🎯 ZONA CAMBIADA: %s" % new_zone_id)

	# Obtener la zona definición para obtener su background
	if Content:
		print("[Main] DEBUG: Buscando zona en Content...")
		var zone_def = Content.get_zone_by_id(new_zone_id)
		if zone_def and zone_def.background != "":
			# Extraer solo el nombre del archivo del path completo
			var bg_name = zone_def.background.get_file().get_basename()
			print("[Main] 🎨 Cambiando fondo basado en zona: %s → %s" % [new_zone_id, bg_name])
			set_background(bg_name)
		else:
			print("[Main] ⚠️ Zona sin fondo definido, usando main: %s" % new_zone_id)
			set_background("main")
	else:
		print("[Main] ❌ Content no disponible, usando fallback")
		# Fallback al sistema anterior si Content no está disponible
		set_background(new_zone_id)

	# Actualizar zona actual en el save
	if Save:
		Save.game_data.current_zone = new_zone_id
		Save.save_game()
		print("[Main] ✅ Zona guardada: %s" % new_zone_id)
	else:
		print("[Main] ⚠️ Save no disponible")

func _on_fish_caught(fish_data: Dictionary) -> void:
	"""Llamado cuando se captura un pez"""
	# Actualizar experiencia
	if Experience and fish_data.has("xp_reward"):
		Experience.add_experience(fish_data.xp_reward)

	# Reproducir sonido
	if SFX:
		SFX.play_event("fish_caught")

	# Actualizar monedas si el pez se vende automáticamente
	if Save and fish_data.has("coin_value"):
		Save.add_coins(fish_data.coin_value)

func _on_item_transaction(item_id: String, quantity: int, is_purchase: bool) -> void:
	"""Manejar compra/venta de items"""
	if not Content:
		return

	var item_data = Content.get_item_data(item_id)
	if not item_data:
		return

	if is_purchase:
		var cost = item_data.get("cost", 0) * quantity
		if Save and Save.spend_coins(cost):
			print("[Main] Comprado: %s x%d" % [item_id, quantity])
			if SFX:
				SFX.play_event("purchase")
			update_topbar() # Actualizar TopBar después de compra
	else:
		var value = item_data.get("sell_value", 0) * quantity
		if Save:
			Save.add_coins(value)
			print("[Main] Vendido: %s x%d" % [item_id, quantity])
			if SFX:
				SFX.play_event("sell")
			update_topbar() # Actualizar TopBar después de venta

func update_topbar() -> void:
	"""Actualizar TopBar con datos actuales"""
	if topbar and topbar.has_method("update_display"):
		topbar.update_display()
		print("[Main] TopBar actualizada")

# Callbacks para compras de upgrades y tienda

func _on_upgrade_purchased(upgrade_id: String) -> void:
	"""Callback para compra de upgrade"""
	print("[Main] Upgrade comprado: " + upgrade_id)
	update_topbar()
	if SFX:
		SFX.play_event("upgrade")

func _on_gem_pack_purchased(pack_id: String) -> void:
	"""Callback para compra de paquete de gemas (monetización)"""
	print("[Main] Paquete de gemas comprado: " + pack_id)
	# TODO: Implementar compra real con plataforma (Google Play, App Store, etc.)
	# Por ahora simular la compra otorgando gemas
	_simulate_gem_pack_purchase(pack_id)

func _on_store_item_purchased(item_id: String) -> void:
	"""Callback para compra de objeto premium con gemas"""
	print("[Main] Objeto premium comprado: " + item_id)
	update_topbar()
	if SFX:
		SFX.play_event("premium_purchase")

func _simulate_gem_pack_purchase(pack_id: String) -> void:
	"""Simular compra de gemas para desarrollo/testing"""
	var gem_amounts = {
		"small_gems": 100,
		"medium_gems": 550, # 500 + 50 bonus
		"large_gems": 1400, # 1200 + 200 bonus
		"mega_gems": 3000 # 2500 + 500 bonus
	}

	var gems_to_add = gem_amounts.get(pack_id, 0)
	if gems_to_add > 0 and Save:
		var current_gems = Save.get_data("gems", 0)
		Save.set_data("gems", current_gems + gems_to_add)
		print("[Main] Gemas añadidas: %d (pack: %s)" % [gems_to_add, pack_id])
		update_topbar()
