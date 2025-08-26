class_name ScreenManager
extends Control

# Recursos precargados
const InventoryClass = preload("res://src/ui/InventoryPanel.gd")

# Enums para las pestañas (diseño vertical 5 tabs con prestigio)
enum Tab {
	FISHING = 0,
	PRESTIGE = 1,
	MARKET = 2,
	UPGRADES = 3,
	MAP = 4
}

var views = {}
var current_tab = Tab.FISHING

# Overlays
var store_view: StoreView
var pause_menu: PauseMenu
var inventory_panel: InventoryPanel

func _ready():
	# Registrar las vistas desde ScreenContainer (con prestigio)
	var screen_container = $ScreenContainer
	if screen_container:
		register_view(Tab.FISHING, screen_container.get_node("FishingView"))
		register_view(Tab.PRESTIGE, screen_container.get_node("PrestigeView"))
		register_view(Tab.MARKET, screen_container.get_node("MarketView"))
		register_view(Tab.UPGRADES, screen_container.get_node("UpgradesView"))
		register_view(Tab.MAP, screen_container.get_node("MapView"))

	# Conectar con BottomTabs
	var bottom_tabs = $BottomTabs
	if bottom_tabs and bottom_tabs.has_signal("tab_selected"):
		bottom_tabs.tab_selected.connect(show_tab)

	# Conectar con TopBar
	var top_bar = $TopBar
	if top_bar:
		if top_bar.has_signal("gems_button_clicked"):
			top_bar.gems_button_clicked.connect(_on_gems_button_clicked)
		if top_bar.has_signal("settings_button_clicked"):
			top_bar.settings_button_clicked.connect(_on_settings_button_clicked)

	# Conectar con FishingView
	var fishing_view = screen_container.get_node("FishingView")
	if fishing_view and fishing_view.has_signal("fish_caught"):
		fishing_view.fish_caught.connect(_on_fish_caught)

	# Mostrar la pestaña inicial
	show_tab(Tab.FISHING)

func register_view(index: int, view_node: Node):
	if view_node:
		views[index] = view_node
		print("Registered view ", index, ": ", view_node.name)

func show_tab(tab: int):
	print("ScreenManager: Showing tab ", tab)

	# Ocultar todas las vistas
	for view in views.values():
		if view:
			view.visible = false
			view.process_mode = Node.PROCESS_MODE_DISABLED

	# Mostrar la vista seleccionada
	if views.has(tab) and views[tab]:
		views[tab].visible = true
		views[tab].process_mode = Node.PROCESS_MODE_INHERIT
		current_tab = tab

		# Actualizar datos de la vista si tiene el método
		if views[tab].has_method("refresh_display"):
			views[tab].refresh_display()

		# Reproducir sonido
		if SFX:
			SFX.play_event("click")
	else:
		print("Warning: View not found for tab ", tab)

func preload_core():
	# Precargar las vistas más importantes
	pass

func _on_gems_button_clicked():
	print("ScreenManager: Gems button clicked")
	show_store()

func _on_settings_button_clicked():
	print("ScreenManager: Settings button clicked")
	show_pause_menu()

func show_store():
	if store_view:
		store_view.queue_free()

	store_view = preload("res://src/views/StoreView.gd").new()
	store_view.close_requested.connect(_on_store_closed)
	add_child(store_view)

func show_pause_menu():
	if pause_menu:
		pause_menu.queue_free()

	pause_menu = preload("res://src/views/PauseMenu.gd").new()
	pause_menu.resume_requested.connect(_on_pause_menu_closed)
	pause_menu.save_and_exit_requested.connect(_on_save_and_exit)
	pause_menu.settings_requested.connect(_on_settings_requested)
	add_child(pause_menu)

func show_inventory(allow_selling: bool = true, title: String = "🧊 INVENTARIO"):
	if inventory_panel:
		inventory_panel.queue_free()

	inventory_panel = InventoryClass.new(allow_selling, title)
	inventory_panel.close_requested.connect(_on_inventory_closed)

	if allow_selling:
		inventory_panel.sell_selected_requested.connect(_on_sell_selected_fish)
		inventory_panel.sell_all_requested.connect(_on_sell_all_fish)

	add_child(inventory_panel)

func show_inventory_discard_mode():
	"""Mostrar inventario en modo descarte para liberar espacio durante la pesca"""
	if inventory_panel:
		inventory_panel.queue_free()

	inventory_panel = InventoryClass.new(false, "🗑️ LIBERAR ESPACIO")
	inventory_panel.close_requested.connect(_on_inventory_closed)
	inventory_panel.sell_selected_requested.connect(_on_discard_selected_fish)
	inventory_panel.sell_all_requested.connect(_on_discard_all_fish)

	add_child(inventory_panel)

func _on_store_closed():
	if store_view:
		store_view.queue_free()
		store_view = null

	# Actualizar TopBar después de posibles compras
	var top_bar = $TopBar
	if top_bar and top_bar.has_method("update_display"):
		top_bar.update_display()

func _on_pause_menu_closed():
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null

func _on_save_and_exit():
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
	get_tree().quit()

func _on_settings_requested():
	# Por ahora cerrar menú de pausa, en futuro abrir configuración
	_on_pause_menu_closed()
	print("Settings requested - to be implemented")

func _on_inventory_closed():
	if inventory_panel:
		inventory_panel.queue_free()
		inventory_panel = null

func _on_sell_selected_fish():
	if not inventory_panel:
		return

	var selected_indices = inventory_panel.get_selected_fish_indices()
	var total_value = 0

	# Vender peces seleccionados (en orden inverso para no alterar índices)
	selected_indices.sort()
	for i in range(selected_indices.size() - 1, -1, -1):
		var fish_value = Save.sell_fish_by_index(selected_indices[i])
		total_value += fish_value

	print("Sold selected fish for: ", total_value, " coins")

	# Actualizar displays
	inventory_panel.refresh_display()
	var top_bar = $TopBar
	if top_bar and top_bar.has_method("update_display"):
		top_bar.update_display()

func _on_sell_all_fish():
	var total_value = Save.sell_all_fish()
	print("Sold all fish for: ", total_value, " coins")

	# Actualizar displays
	if inventory_panel:
		inventory_panel.refresh_display()
	var top_bar = $TopBar
	if top_bar and top_bar.has_method("update_display"):
		top_bar.update_display()

func _on_fish_caught(fish_name: String, value: int):
	print("ScreenManager: Fish caught - ", fish_name, " worth ", value)
	# Actualizar TopBar
	var top_bar = $TopBar
	if top_bar and top_bar.has_method("update_display"):
		top_bar.update_display()

# Funciones para modo descarte (liberar espacio sin ganar dinero)
func _on_discard_selected_fish():
	"""Descartar peces seleccionados sin ganar dinero"""
	if not inventory_panel:
		return

	var selected_indices = inventory_panel.get_selected_fish_indices()
	var discarded_count = 0

	# Descartar peces seleccionados (en orden inverso para no alterar índices)
	selected_indices.sort()
	for i in range(selected_indices.size() - 1, -1, -1):
		Save.discard_fish_by_index(selected_indices[i])
		discarded_count += 1

	print("Discarded ", discarded_count, " fish to free inventory space")

	# Actualizar display del inventario solamente
	inventory_panel.refresh_display()

func _on_discard_all_fish():
	"""Descartar todos los peces sin ganar dinero"""
	var discarded_count = Save.discard_all_fish()
	print("Discarded all fish (", discarded_count, " total) to free inventory space")

	# Actualizar display del inventario solamente
	if inventory_panel:
		inventory_panel.refresh_display()
