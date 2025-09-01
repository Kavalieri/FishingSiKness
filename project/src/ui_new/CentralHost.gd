class_name CentralHostUI
extends Control

# Contenedor central para pantallas dinámicas
# Se encarga de cargar/descargar pantallas según navegación

var current_screen: Node = null

@onready var screen_root := $MarginContainer/ScreenRoot

func _ready() -> void:
	# Esperar a que los autoloads estén listos antes de cargar la pantalla inicial
	await get_tree().process_frame
	await get_tree().process_frame # Esperar 2 frames para asegurar inicialización

	# Pantalla inicial por defecto (usar la nueva FishingScreen migrada)
	show_screen("res://scenes/ui_new/screens/FishingScreen.tscn")

func show_screen(scene_path: String, setup_data: Dictionary = {}) -> void:
	"""Mostrar nueva pantalla, eliminando la anterior"""
	print("[CentralHost] Cargando pantalla: ", scene_path)
	_clear_current_screen()
	_load_new_screen(scene_path, setup_data)

func _clear_current_screen() -> void:
	"""Limpiar pantalla actual"""
	if current_screen:
		current_screen.queue_free()
		current_screen = null

func _load_new_screen(scene_path: String, setup_data: Dictionary = {}) -> void:
	"""Cargar nueva pantalla desde archivo"""
	var scene_resource = load(scene_path)
	if scene_resource:
		current_screen = scene_resource.instantiate()
		if current_screen:
			screen_root.add_child(current_screen)
			# Asegurar que ocupe todo el espacio disponible
			if current_screen is Control:
				current_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

			# Configurar pantalla con datos si tiene método setup
			_setup_screen_with_data(current_screen, scene_path, setup_data)
	else:
		push_error("No se pudo cargar la pantalla: " + scene_path)

func _setup_screen_with_data(screen: Node, scene_path: String, _setup_data: Dictionary) -> void:
	"""Configurar pantalla con datos apropiados según su tipo"""
	var screen_name = scene_path.get_file().get_basename()
	print("[CentralHost] DEBUG: Configurando screen_name: '%s'" % screen_name)

	match screen_name:
		"FishingScreen":
			_setup_fishing_screen(screen)
		"MapScreen":
			print("[CentralHost] DEBUG: Llamando _setup_map_screen")
			_setup_map_screen(screen)
		"MarketScreen":
			_setup_market_screen(screen)
		"UpgradesScreen":
			_setup_upgrades_screen(screen)
		"StoreScreen":
			_setup_store_screen(screen)
		"PrestigeScreen":
			_setup_prestige_screen(screen)

	# Conectar señales de la pantalla con Main
	_connect_screen_signals(screen, screen_name)

func _setup_fishing_screen(screen: Control) -> void:
	"""Configurar pantalla de pesca con datos actuales"""
	if Content and screen.has_method("setup_fishing_screen"):
		# Obtener zona actual del Save o usar zona por defecto
		var current_zone_id = ""
		if Save and Save.game_data.has("current_zone"):
			current_zone_id = Save.game_data.current_zone

		var zone_def = Content.get_zone_data(current_zone_id) \
			if current_zone_id else Content.get_default_zone()

		var stats = {} # TODO: Obtener estadísticas de pesca

		# Pasar ZoneDef directamente, sin conversión
		screen.setup_fishing_screen(zone_def, stats)

func _setup_map_screen(screen: Control) -> void:
	"""Configurar pantalla de mapa con zonas disponibles"""
	print("[CentralHost] DEBUG: Configurando MapScreen")
	print("[CentralHost] DEBUG: Content disponible: %s" % (Content != null))
	print("[CentralHost] DEBUG: Screen tiene setup_map: %s" % screen.has_method("setup_map"))

	if Content and screen.has_method("setup_map"):
		var zone_defs = Content.get_all_zones()

		var current_zone_id = ""
		if Save and Save.game_data.has("current_zone"):
			current_zone_id = Save.game_data.current_zone

		print("[CentralHost] Setup mapa con %d zonas ZoneDef" % zone_defs.size())
		for zone_def in zone_defs:
			print("[CentralHost] - Zona: %s (%s)" % [zone_def.id, zone_def.name])

		# Pasar ZoneDef directamente, sin conversión
		screen.setup_map(zone_defs, current_zone_id)
	else:
		print("[CentralHost] ERROR: No se puede configurar mapa - Content: %s, has_method: %s" % [Content != null, screen.has_method("setup_map")])

func _setup_market_screen(screen: Control) -> void:
	"""Configurar pantalla de mercado con inventario real del jugador"""
	if screen.has_method("setup_market"):
		var money = 0
		var gems = 0
		var sell_items = []
		var buy_items = []

		if Save:
			money = Save.get_coins()
			gems = Save.get_gems()

		# Obtener inventario real de peces desde InventorySystem
		if InventorySystem:
			var fish_inventory = InventorySystem.get_inventory()
			print("[CentralHost] Cargando inventario con %d peces" % fish_inventory.size())
		else:
			print("[CentralHost] InventorySystem no disponible")

		# Obtener items disponibles para compra desde Content
		if Content:
			# TODO: Implementar sistema de items comprables
			buy_items = _get_buyable_items()

		screen.setup_market(money, gems, sell_items, buy_items)

func _get_buyable_items() -> Array[Dictionary]:
	"""Obtener items comprables del Content system"""
	var items: Array[Dictionary] = []

	# Por ahora, items de ejemplo basados en el store
	if Content:
		# Paquetes de gemas
		items.append({
			"id": "gems_120",
			"name": "Paquete Pequeño de Gemas",
			"description": "💎 120 gemas\nPerfecto para empezar",
			"category": "gems",
			"price": 100, # Precio en dinero real (ficticio)
			"currency": "real_money",
			"value": 120,
			"icon": "res://art/ui/assets/diamonds.png"
		})

		# Items de mejora básicos
		items.append({
			"id": "bait_basic",
			"name": "Cebo Básico",
			"description": "🎣 Mejora las posibilidades de captura\n+10% probabilidad de pez raro",
			"category": "consumable",
			"price": 50,
			"currency": "coins",
			"value": 50,
			"icon": "res://art/ui/assets/coins.png"
		})

	return items

func _setup_upgrades_screen(screen: Control) -> void:
	"""Configurar pantalla de mejoras con datos del UpgradeSystem"""
	if screen.has_method("setup_screen"):
		screen.setup_screen()
	elif screen.has_method("setup_upgrades_screen"):
		# Fallback para compatibilidad
		var upgrades = []
		var money = 0
		var gems = 0
		var stats = {}

		if Content:
			upgrades = Content.get_all_upgrades()

		if Save:
			money = Save.game_data.get("coins", 0)
			gems = Save.game_data.get("gems", 0)
			stats = Save.game_data.get("stats", {})

		screen.setup_upgrades_screen(upgrades, money, gems, stats)

func _connect_screen_signals(screen: Node, screen_name: String) -> void:
	"""Conectar señales de la pantalla con el sistema principal"""
	print("[CentralHost] DEBUG: Conectando señales para screen: %s" % screen_name)

	# Obtener referencia a Main para conectar señales
	var main = get_parent().get_parent() # Main -> VBoxContainer -> CentralHost
	print("[CentralHost] DEBUG: Main obtenido: %s" % (main != null))

	# Remover verificación errónea de _on_screen_signal que no existe
	print("[CentralHost] DEBUG: ✅ Procediendo a conectar señales...")
	match screen_name:
		"FishingScreen":
			if screen.has_signal("fish_caught"):
				screen.fish_caught.connect(main._on_fish_caught)
		"MapScreen":
			print("[CentralHost] DEBUG: Procesando MapScreen...")
			if screen.has_signal("zone_selected"):
				screen.zone_selected.connect(main._on_zone_changed)
				print("[CentralHost] DEBUG: ✅ Conectada señal zone_selected")
			else:
				print("[CentralHost] DEBUG: ❌ MapScreen NO tiene señal zone_selected")

			if screen.has_signal("fishing_requested"):
				screen.fishing_requested.connect(_on_fishing_requested)
				print("[CentralHost] DEBUG: ✅ Conectada señal fishing_requested")
			else:
				print("[CentralHost] DEBUG: ❌ MapScreen NO tiene señal fishing_requested")

			if screen.has_signal("zone_preview_requested"):
				screen.zone_preview_requested.connect(_on_zone_preview_requested)
				print("[CentralHost] DEBUG: ✅ Conectada señal zone_preview_requested")
			else:
				print("[CentralHost] DEBUG: ❌ MapScreen NO tiene señal zone_preview_requested")

			if screen.has_signal("zone_unlock_requested"):
				screen.zone_unlock_requested.connect(_on_zone_unlock_requested)
				print("[CentralHost] DEBUG: ✅ Conectada señal zone_unlock_requested → _on_zone_unlock_requested")
			else:
				print("[CentralHost] DEBUG: ❌ MapScreen NO tiene señal zone_unlock_requested")
			print("[CentralHost] DEBUG: MapScreen procesado completamente")
		"MarketScreen":
			if screen.has_signal("item_bought"):
				screen.item_bought.connect(main._on_item_bought)
			if screen.has_signal("item_sold"):
				screen.item_sold.connect(main._on_item_sold)
		"UpgradesScreen":
			if screen.has_signal("upgrade_purchased"):
				screen.upgrade_purchased.connect(main._on_upgrade_purchased)
		"StoreScreen":
			if screen.has_signal("store_screen_closed"):
				screen.store_screen_closed.connect(_on_store_screen_closed)
			if screen.has_signal("gem_pack_purchased"):
				screen.gem_pack_purchased.connect(main._on_gem_pack_purchased)
			if screen.has_signal("item_purchased"):
				screen.item_purchased.connect(main._on_store_item_purchased)
		"PrestigeScreen":
			if screen.has_signal("prestige_confirmed"):
				screen.prestige_confirmed.connect(main._on_prestige_confirmed)

func _setup_prestige_screen(screen: Control) -> void:
	"""Configurar pantalla de prestigio con datos actuales"""
	if screen.has_method("setup_prestige_screen"):
		# TODO: Obtener datos reales del sistema de prestigio cuando esté implementado
		var prestige_level = 0 # Nivel actual de prestigio
		var prestige_points = 0 # Puntos de prestigio disponibles
		var next_points = 100 # Puntos necesarios para el siguiente prestigio
		var bonuses: Array[Dictionary] = [] # Bonuses disponibles (vacío por ahora)
		var can_do_prestige = false # Si el jugador puede hacer prestigio

		# Si hay sistema de Save, obtener datos reales
		if Save and Save.game_data.has("prestige"):
			var prestige_data = Save.game_data.prestige
			prestige_level = prestige_data.get("level", 0)
			prestige_points = prestige_data.get("points", 0)
			next_points = prestige_data.get("next_points", 100)
			# can_do_prestige = (current_progress >= next_points)

		screen.setup_prestige_screen(
			prestige_level, prestige_points, next_points, bonuses, can_do_prestige
		)

func _setup_store_screen(screen: Control) -> void:
	"""Configurar pantalla de tienda"""
	# StoreScreen se configura automáticamente en _ready()
	# Solo necesitamos conectar señales aquí si es necesario
	pass

func get_current_screen() -> Node:
	"""Obtener referencia a la pantalla actual"""
	return current_screen

func _on_fishing_requested(zone_id: String) -> void:
	"""Manejar solicitud de ir a pescar en zona específica"""
	# Cambiar a zona y abrir pantalla de pesca
	var main = get_parent().get_parent()
	if main and main.has_method("_on_zone_changed"):
		main._on_zone_changed(zone_id)

	show_screen("res://scenes/ui_new/screens/FishingScreen.tscn")

func _on_zone_preview_requested(zone_id: String) -> void:
	"""Manejar solicitud de vista previa de zona"""
	print("Vista previa de zona solicitada: %s" % zone_id)
	# TODO: Implementar panel de vista previa de zona

func _on_zone_unlock_requested(zone_id: String, cost: int) -> void:
	"""Manejar solicitud de desbloqueo de zona"""
	print("[CentralHost] 🔓 DESBLOQUEO SOLICITADO: zona=%s, costo=%d" % [zone_id, cost])

	if not Save:
		print("[CentralHost] ❌ Sistema de guardado no disponible")
		return

	if Save.get_coins() < cost:
		print("[CentralHost] ❌ Fondos insuficientes para desbloquear zona: %s (necesario: %d, actual: %d)" % [zone_id, cost, Save.get_coins()])
		if SFX and SFX.has_method("play_event"):
			SFX.play_event("ui_error")
		return

	print("[CentralHost] 💰 Procesando desbloqueo...")
	# Procesar desbloqueo
	if Save.spend_coins(cost):
		print("[CentralHost] ✅ Monedas gastadas exitosamente")
		# Añadir zona a las desbloqueadas
		var unlocked_zones = Save.game_data.get("unlocked_zones", ["lago_montana_alpes"])
		if not unlocked_zones.has(zone_id):
			unlocked_zones.append(zone_id)
			Save.game_data.unlocked_zones = unlocked_zones
			Save.save_game()
			print("[CentralHost] 📝 Zona añadida a lista de desbloqueadas: %s" % str(unlocked_zones))

		# Notificar al MapScreen del éxito
		if current_screen and current_screen.has_method("unlock_zone_success"):
			print("[CentralHost] 📤 Notificando éxito al MapScreen...")
			current_screen.unlock_zone_success(zone_id)
		else:
			print("[CentralHost] ⚠️ No se puede notificar al MapScreen (no encontrado o sin método unlock_zone_success)")

		# Actualizar TopBar si es necesario
		var main = get_parent().get_parent()
		if main and main.has_method("update_topbar"):
			main.update_topbar()

		print("[CentralHost] 🎉 Zona %s desbloqueada exitosamente por %d monedas" % [zone_id, cost])
	else:
		print("[CentralHost] ❌ Error al gastar monedas")

func _on_store_screen_closed() -> void:
	"""Cerrar pantalla de tienda y volver al juego"""
	show_screen("res://scenes/ui_new/screens/FishingScreen.tscn")
