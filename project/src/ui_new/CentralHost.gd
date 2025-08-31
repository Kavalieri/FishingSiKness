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

	match screen_name:
		"FishingScreen":
			_setup_fishing_screen(screen)
		"MapScreen":
			_setup_map_screen(screen)
		"MarketScreen":
			_setup_market_screen(screen)
		"UpgradesScreen":
			_setup_upgrades_screen(screen)
		"PrestigeScreen":
			_setup_prestige_screen(screen)

	# Conectar señales de la pantalla con Main
	_connect_screen_signals(screen, screen_name)

func _setup_fishing_screen(screen: FishingScreen) -> void:
	"""Configurar pantalla de pesca con datos actuales"""
	if Content and screen.has_method("setup_fishing_screen"):
		# Obtener zona actual del Save o usar zona por defecto
		var current_zone_id = ""
		if Save and Save.game_data.has("current_zone"):
			current_zone_id = Save.game_data.current_zone

		var zone_data = Content.get_zone_data(current_zone_id) \
			if current_zone_id else Content.get_default_zone()
		var stats = {} # TODO: Obtener estadísticas de pesca

		screen.setup_fishing_screen(zone_data, stats)

func _setup_map_screen(screen: MapScreen) -> void:
	"""Configurar pantalla de mapa con zonas disponibles"""
	if Content and screen.has_method("setup_map"):
		var zones = Content.get_all_zones()
		var current_zone_id = ""
		if Save and Save.game_data.has("current_zone"):
			current_zone_id = Save.game_data.current_zone

		screen.setup_map(zones, current_zone_id)

func _setup_market_screen(screen: MarketScreen) -> void:
	"""Configurar pantalla de mercado con inventario del jugador"""
	if screen.has_method("setup_market"):
		var money = 0
		var gems = 0
		var inventory = []

		if Save:
			money = Save.get_coins()
			gems = Save.get_gems()
			# TODO: Obtener inventario real cuando esté implementado
			inventory = []

		# TODO: Obtener items disponibles para compra desde Content
		var buyable_items = []

		screen.setup_market(money, gems, inventory, buyable_items)

func _setup_upgrades_screen(screen: UpgradesScreen) -> void:
	"""Configurar pantalla de mejoras con datos del jugador"""
	if screen.has_method("setup_upgrades_screen"):
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
	# Obtener referencia a Main para conectar señales
	var main = get_parent().get_parent() # Main -> VBoxContainer -> CentralHost

	if not main or not main.has_method("_on_screen_signal"):
		return

	match screen_name:
		"FishingScreen":
			if screen.has_signal("fish_caught"):
				screen.fish_caught.connect(main._on_fish_caught)
		"MapScreen":
			if screen.has_signal("zone_selected"):
				screen.zone_selected.connect(main._on_zone_selected)
		"MarketScreen":
			if screen.has_signal("item_bought"):
				screen.item_bought.connect(main._on_item_bought)
			if screen.has_signal("item_sold"):
				screen.item_sold.connect(main._on_item_sold)
		"UpgradesScreen":
			if screen.has_signal("upgrade_purchased"):
				screen.upgrade_purchased.connect(main._on_upgrade_purchased)
		"PrestigeScreen":
			if screen.has_signal("prestige_confirmed"):
				screen.prestige_confirmed.connect(main._on_prestige_confirmed)

func get_current_screen() -> Node:
	"""Obtener referencia a la pantalla actual"""
	return current_screen
