class_name MainUI
extends Control

# UI Principal con fondo único global según especificación

const TOP_MIN := 64
const TOP_MAX := 96
const BOT_MIN := 72
const BOT_MAX := 104

@onready var background: TextureRect = $Background
@onready var vbox := $VBoxContainer
@onready var topbar: Control = vbox.get_node("TopBar")
@onready var central_host: Control = vbox.get_node("CentralHost")
@onready var bottombar: Control = vbox.get_node("BottomBar")

func _ready() -> void:
	print("=== MAIN READY START ===")

	# Esperar hasta que los nodos estén listos
	await get_tree().process_frame

	_apply_clamps()
	_connect_signals()

	print("=== MAIN READY COMPLETE ===")

func _delayed_initialization() -> void:
	print("=== DELAYED INIT START ===")
	_apply_clamps()
	_connect_signals()

	# Test directo de botones
	if bottombar:
		print("[Main] BottomBar encontrado, probando conexión directa...")
		if bottombar.has_method("_select_tab"):
			print("[Main] Método _select_tab existe en BottomBar")
		else:
			print("[Main] ERROR: Método _select_tab NO existe en BottomBar")
	print("=== DELAYED INIT END ===") func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_apply_clamps()

func _apply_clamps() -> void:
	"""Aplicar clamps para mantener dimensiones dentro de rangos óptimos"""
	if not is_inside_tree():
		return

	var h := size.y

	if topbar:
		topbar.custom_minimum_size.y = clamp(h * 0.11, TOP_MIN, TOP_MAX)

	if bottombar:
		bottombar.custom_minimum_size.y = clamp(h * 0.12, BOT_MIN, BOT_MAX)

func set_background(tex_path: String, modulate_color: Color = Color(1, 1, 1, 1)) -> void:
	"""Cambiar fondo en tiempo real según especificación UI-BG-GLOBAL"""
	var tex: Texture2D = load(tex_path)
	if tex and background:
		background.texture = tex
		background.modulate = modulate_color

	# Central se auto-ajusta por los contenedores VBox

func _connect_signals() -> void:
	"""Conectar señales de los componentes UI"""
	print("[Main] === CONECTANDO SEÑALES ===")
	print("[Main] TopBar existe: ", topbar != null)
	print("[Main] BottomBar existe: ", bottombar != null)

	# TopBar signals
	if topbar and topbar.has_signal("button_pressed"):
		topbar.button_pressed.connect(_on_topbar_button_pressed)
		print("[Main] ✓ Señal TopBar conectada")
	else:
		print("[Main] ❌ ERROR: TopBar no tiene señal button_pressed")
		if topbar:
			print("[Main] Señales disponibles en TopBar: ", topbar.get_signal_list())

	# BottomBar signals
	if bottombar and bottombar.has_signal("tab_selected"):
		bottombar.tab_selected.connect(_on_bottombar_tab_selected)
		print("[Main] ✓ Señal BottomBar conectada")
	else:
		print("[Main] ❌ ERROR: BottomBar no tiene señal tab_selected")
		if bottombar:
			print("[Main] Señales disponibles en BottomBar: ", bottombar.get_signal_list())

	print("[Main] === FIN CONEXIÓN SEÑALES ===")

func _on_topbar_button_pressed(button_type: String) -> void:
	"""Manejar pulsaciones de botones en TopBar"""
	print("[Main] Recibida señal TopBar: ", button_type)

	match button_type:
		"money":
			print("[Main] Botón money presionado")
			_show_economy_screen()
		"gems":
			print("[Main] Botón gems presionado")
			_show_store_screen()
		"zone":
			print("[Main] Botón zone presionado")
			_show_zone_select_screen()
		"social":
			print("[Main] Botón social presionado")
			_show_social_menu()
		"pause":
			print("[Main] Botón pause presionado")
			_show_pause_menu()
		"xp":
			print("[Main] Botón xp presionado")
			_show_experience_screen()
		_:
			print("[Main] ERROR: Botón desconocido: ", button_type)

func _on_bottombar_tab_selected(tab_name: String) -> void:
	"""Manejar selección de tabs en BottomBar"""
	print("[Main] Recibida señal BottomBar: ", tab_name)

	# Verificar que CentralHost existe y tiene el método
	if central_host and central_host.has_method("show_screen"):
		print("[Main] CentralHost tiene método show_screen")

		match tab_name:
			"fishing":
				print("[Main] Cargando pantalla de pesca")
				central_host.show_screen("res://scenes/ui_new/screens/FishingScreen.tscn")
			"map":
				print("[Main] Cargando pantalla de mapa")
				central_host.show_screen("res://scenes/ui_new/screens/MapScreen.tscn")
			"market":
				print("[Main] Cargando pantalla de mercado")
				central_host.show_screen("res://scenes/ui_new/screens/MarketScreen.tscn")
			"upgrades":
				print("[Main] Cargando pantalla de mejoras")
				central_host.show_screen("res://scenes/ui_new/screens/UpgradesScreen.tscn")
			"prestige":
				print("[Main] Cargando pantalla de prestigio")
				central_host.show_screen("res://scenes/ui_new/screens/PrestigeScreen.tscn")
			_:
				print("[Main] ERROR: Tab desconocido: ", tab_name)
	else:
		print("[Main] ERROR: CentralHost no disponible o no tiene método show_screen")

# Métodos auxiliares para mostrar pantallas/menús
func _show_economy_screen() -> void:
	"""Mostrar pantalla de economía/monedas"""
	# Por ahora mostrar el mercado en modo venta
	central_host.show_screen("res://scenes/ui_new/screens/MarketScreen.tscn")

func _show_store_screen() -> void:
	"""Mostrar tienda de gemas"""
	# Por ahora mostrar el mercado en modo compra
	central_host.show_screen("res://scenes/ui_new/screens/MarketScreen.tscn")

func _show_zone_select_screen() -> void:
	"""Mostrar selector de zona actual"""
	central_host.show_screen("res://scenes/ui_new/screens/MapScreen.tscn")

func _show_social_menu() -> void:
	"""Mostrar menú social"""
	# TODO: Implementar menú social con logros, amigos, etc.
	print("Social menu - TODO: Implementar")

func _show_pause_menu() -> void:
	"""Mostrar menú de pausa/opciones"""
	var options_scene = load("res://scenes/ui_new/components/OptionsWindow.tscn")
	if options_scene:
		var options_window = options_scene.instantiate()
		add_child(options_window)
		# Centrar la ventana
		if options_window is Window:
			options_window.popup_centered()

func _show_experience_screen() -> void:
	"""Mostrar detalles de experiencia"""
	# TODO: Implementar pantalla detallada de XP
	print("Experience screen - TODO: Implementar")

# Métodos para manejar señales de las pantallas
func _on_fish_caught(fish_data: Dictionary) -> void:
	"""Manejar cuando se captura un pez"""
	# Actualizar estadísticas, experiencia, etc.
	if Experience:
		Experience.add_experience(fish_data.get("xp_reward", 10))

	# Reproducir sonido de captura
	if SFX:
		SFX.play_event("fish_caught")

func _on_zone_selected(zone_id: String) -> void:
	"""Manejar selección de zona"""
	if Save:
		Save.game_data.current_zone = zone_id
		Save.save_game()

	# Cambiar a pantalla de pesca con la nueva zona
	central_host.show_screen("res://scenes/ui_new/screens/FishingScreen.tscn")

func _on_item_bought(item_data: Dictionary, quantity: int) -> void:
	"""Manejar compra de item"""
	var cost = item_data.get("cost", 0) * quantity

	if Save and Save.spend_coins(cost):
		# TODO: Añadir item al inventario cuando esté implementado
		print("Item comprado: %s x%d por %d monedas" % [item_data.get("name", "Item"), quantity, cost])

		if SFX:
			SFX.play_event("purchase")

func _on_item_sold(item_data: Dictionary, quantity: int) -> void:
	"""Manejar venta de item"""
	var value = item_data.get("sell_value", 0) * quantity

	if Save:
		Save.add_coins(value)
		# TODO: Remover item del inventario cuando esté implementado
		print("Item vendido: %s x%d por %d monedas" % [item_data.get("name", "Item"), quantity, value])

		if SFX:
			SFX.play_event("sell")

func _on_upgrade_purchased(upgrade_id: String) -> void:
	"""Manejar compra de mejora"""
	# TODO: Implementar lógica de compra de mejoras
	if Content:
		var upgrade_data = Content.get_upgrade_data(upgrade_id)
		if upgrade_data:
			var cost = upgrade_data.get("cost", 0)

			if Save and Save.spend_coins(cost):
				# TODO: Añadir upgrade cuando esté implementado
				print("Upgrade comprado: %s por %d monedas" % [upgrade_id, cost])

				if SFX:
					SFX.play_event("upgrade")

func _on_prestige_confirmed() -> void:
	"""Manejar confirmación de prestigio"""
	# TODO: Implementar lógica de prestigio
	print("Prestige confirmed - TODO: Implementar")
