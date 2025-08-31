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
	print("[Main] === SETUP DIFERIDO ===")

	# Verificar referencias críticas
	_verify_node_references()

	# Configurar fondo inicial
	_setup_background()

	# Conectar señales de navegación
	_connect_navigation_signals()

	# Cargar pantalla inicial
	_load_initial_screen()

	print("[Main] === MAIN UI INICIALIZADO ===")

func _verify_node_references() -> void:
	"""Verificar que todas las referencias de nodo son válidas"""
	var components = {
		"Background": background,
		"TopBar": topbar,
		"CentralHost": central_host,
		"BottomBar": bottombar
	}

	print("[Main] === VERIFICANDO COMPONENTES ===")
	for name in components.keys():
		var node = components[name]
		if node:
			print("[Main] ✓ %s: OK (%s)" % [name, node.get_class()])
		else:
			print("[Main] ❌ %s: FALTA - PATH INCORRECTO" % name)

func _setup_background() -> void:
	"""Configurar fondo inicial del juego"""
	if background:
		print("[Main] Configurando fondo inicial...")
		# Cargar fondo por defecto basado en zona actual
		var current_zone = "main" # Por defecto
		if Save and Save.game_data.has("current_zone"):
			current_zone = Save.game_data.current_zone

		# Si la zona es una de las nuevas, usar el fondo correcto
		if current_zone == "lago_montana_alpes":
			current_zone = "snow" # Usar fondo de nieve para los Alpes
		elif current_zone == "grandes_lagos_norteamerica":
			current_zone = "forest" # Usar fondo de bosque para los grandes lagos
		elif current_zone == "costas_atlanticas":
			current_zone = "beach" # Usar fondo de playa para las costas
		elif current_zone == "rios_amazonicos":
			current_zone = "forest" # Usar fondo de bosque para el Amazonas
		elif current_zone == "oceanos_profundos":
			current_zone = "nether" # Usar fondo profundo para océanos

		set_background(current_zone)
	else:
		print("[Main] ❌ No se pudo configurar fondo - nodo Background no encontrado")

func _connect_navigation_signals() -> void:
	"""Conectar señales de navegación principales"""
	print("[Main] === CONECTANDO SEÑALES ===")

	# Señal crítica: BottomBar → Main
	if bottombar and bottombar.has_signal("tab_selected"):
		if not bottombar.tab_selected.is_connected(_on_tab_selected):
			bottombar.tab_selected.connect(_on_tab_selected)
			print("[Main] ✓ BottomBar.tab_selected → Main._on_tab_selected")
		else:
			print("[Main] ⚠️ Señal BottomBar ya conectada")
	else:
		print("[Main] ❌ ERROR: BottomBar no tiene señal 'tab_selected'")
		if bottombar:
			var signals = bottombar.get_signal_list()
			print("[Main] Señales disponibles: ", signals)

	# Señal TopBar → Main
	if topbar and topbar.has_signal("button_pressed"):
		if not topbar.button_pressed.is_connected(_on_topbar_button_pressed):
			topbar.button_pressed.connect(_on_topbar_button_pressed)
			print("[Main] ✓ TopBar.button_pressed → Main._on_topbar_button_pressed")
	else:
		print("[Main] ⚠️ TopBar sin señal 'button_pressed' o no existe")

	print("[Main] === FIN CONEXIÓN SEÑALES ===")

func _load_initial_screen() -> void:
	"""Cargar pantalla inicial del juego"""
	if central_host and central_host.has_method("show_screen"):
		print("[Main] Cargando pantalla inicial: FishingScreen")
		central_host.show_screen("res://scenes/ui_new/screens/FishingScreen.tscn")
	else:
		print("[Main] ❌ No se pudo cargar pantalla inicial - CentralHost no válido")

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
	print("[Main] ¡SEÑAL RECIBIDA! Tab seleccionado: %s" % tab_name)

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
		print("[Main] → Cambiando a pantalla: %s" % screen_path)
		central_host.show_screen(screen_path)

		# Cambiar fondo si es necesario
		_update_background_for_screen(tab_name)
	else:
		print("[Main] ❌ Tab desconocido: %s" % tab_name)

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
			# Mantener fondo de zona actual
			pass
		"map":
			set_background("main") # Vista general del mapa
		"market":
			set_background("city") # Mercado en la ciudad
		"upgrades":
			set_background("industrial") # Taller de mejoras
		"prestige":
			set_background("space") # Prestige cósmico

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
	set_background(new_zone_id)

	if Save:
		Save.game_data.current_zone = new_zone_id
		Save.save_game()

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
