class_name ScreenManager
extends Control

# Recursos precargados
# Precargar escenas en lugar de clases
const UnifiedMenuScene = preload("res://scenes/views/UnifiedMenu.tscn")
const StoreViewScene = preload("res://scenes/views/StoreView.tscn")
const InventoryPanelScene = preload("res://scenes/ui/InventoryPanel.tscn")
const FishInfoPanelClass = preload("res://src/ui/FishInfoPanel.gd")
const SpeciesLegendPanelClass = preload("res://src/ui/SpeciesLegendPanel.gd")

# Enums para las pestañas (orden: Pescar, Mercado, Mejoras, Mapa, Prestigio)
enum Tab {
	FISHING = 0,
	MARKET = 1,
	UPGRADES = 2,
	MAP = 3,
	PRESTIGE = 4
}

var views = {}
var current_tab = Tab.FISHING

# Overlays
var store_view: StoreView
var pause_menu: Control # Cambiado de PauseMenu a Control para aceptar UnifiedMenu
var inventory_panel: Control # Cambiado de InventoryPanel a Control para aceptar la escena
var fish_info_panel: FishInfoPanel
var species_legend_panel: SpeciesLegendPanel
var milestones_panel: Control
var settings_menu: Control
var save_manager: Control
var debug_panel: Control

func _ready():
	# Añadir al grupo para fácil acceso
	add_to_group("ScreenManager")

	# Registrar las vistas desde ScreenContainer (sin Fridge)
	var screen_container = $ScreenContainer
	if screen_container:
		register_view(Tab.FISHING, screen_container.get_node("FishingView"))
		register_view(Tab.MARKET, screen_container.get_node("MarketView"))
		register_view(Tab.UPGRADES, screen_container.get_node("UpgradesView"))
		register_view(Tab.MAP, screen_container.get_node("MapView"))
		register_view(Tab.PRESTIGE, screen_container.get_node("PrestigeView"))

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
		if top_bar.has_signal("level_button_clicked"):
			top_bar.level_button_clicked.connect(_on_level_button_clicked)

	# Conectar con FishingView
	var fishing_view = screen_container.get_node("FishingView")
	if fishing_view and fishing_view.has_signal("fish_caught"):
		fishing_view.fish_caught.connect(_on_fish_caught)

	# Conectar con MapView para cambios de zona
	var map_view = screen_container.get_node("MapView")
	if map_view and map_view.has_signal("zone_changed"):
		map_view.zone_changed.connect(_on_zone_changed)

	# Mostrar la pestaña inicial
	show_tab(Tab.FISHING)

	# Crear debug panel (accesible con F2)
	create_debug_panel()

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

func _on_level_button_clicked():
	print("ScreenManager: Level button clicked")
	show_milestones_panel()

func show_store():
	if store_view:
		store_view.queue_free()

	# Instanciar escena con fondo negro configurado
	store_view = StoreViewScene.instantiate()
	store_view.close_requested.connect(_on_store_closed)
	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(store_view)

func show_pause_menu():
	"""Mostrar menú de pausa unificado"""
	# Cerrar menú anterior si existe
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null

	# Instanciar escena con fondo negro configurado
	pause_menu = UnifiedMenuScene.instantiate()

	# Conectar señales
	pause_menu.resume_requested.connect(_on_pause_menu_closed)
	pause_menu.save_and_exit_requested.connect(_on_save_and_exit)
	pause_menu.save_manager_requested.connect(_on_save_manager_requested_from_pause)
	pause_menu.menu_closed.connect(_on_pause_menu_closed)

	# Asegurar que el overlay esté en el nivel superior
	pause_menu.z_index = 100
	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(pause_menu)

func show_settings_menu():
	"""Mostrar menú de opciones unificado"""
	# Evitar crear múltiples instancias
	if settings_menu:
		settings_menu.queue_free()
		settings_menu = null

	# Cerrar menú de pausa si existe
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null

	# Crear menú de opciones unificado
	var UnifiedMenuClass = preload("res://src/views/UnifiedMenu.gd")
	settings_menu = UnifiedMenuClass.create_options_menu()

	# Conectar señales
	settings_menu.menu_closed.connect(_on_settings_closed)
	settings_menu.save_manager_requested.connect(_on_save_manager_requested_from_settings)

	# Asegurar que esté en el nivel superior
	settings_menu.z_index = 100
	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(settings_menu)

func show_milestones_panel():
	# Evitar crear múltiples instancias
	if milestones_panel:
		return

	var MilestonesClass = preload("res://src/views/MilestonesPanel.gd")
	milestones_panel = MilestonesClass.new()
	milestones_panel.close_requested.connect(_on_milestones_closed)
	milestones_panel.tree_exiting.connect(_on_milestones_closed)
	# Asegurar que el overlay esté en el nivel superior
	milestones_panel.z_index = 100
	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(milestones_panel)

func show_inventory(allow_selling: bool = true, title: String = "🧊 INVENTARIO"):
	if inventory_panel:
		inventory_panel.queue_free()

	# Instanciar escena con fondo negro configurado
	inventory_panel = InventoryPanelScene.instantiate()

	# Verificar que se instanció correctamente
	if not inventory_panel:
		push_error("Error: No se pudo instanciar InventoryPanelScene")
		return

	# Conectar señales con deferred para asegurar inicialización
	call_deferred("_connect_inventory_signals", inventory_panel, allow_selling)

	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(inventory_panel)

func _connect_inventory_signals(panel: Control, allow_selling: bool):
	"""Conectar señales del panel de inventario de forma segura"""
	if not panel or not is_instance_valid(panel):
		return

	if panel.has_signal("close_requested"):
		panel.close_requested.connect(_on_inventory_closed)

	if allow_selling:
		if panel.has_signal("sell_selected_requested"):
			panel.sell_selected_requested.connect(_on_sell_selected_fish)
		if panel.has_signal("sell_all_requested"):
			panel.sell_all_requested.connect(_on_sell_all_fish)
		if panel.has_signal("discard_selected_requested"):
			panel.discard_selected_requested.connect(_on_discard_selected_fish)
		if panel.has_signal("discard_all_requested"):
			panel.discard_all_requested.connect(_on_discard_all_fish)

func show_inventory_discard_mode():
	"""Mostrar inventario en modo descarte para liberar espacio durante la pesca"""
	if inventory_panel:
		inventory_panel.queue_free()

	# Instanciar escena con fondo negro configurado
	inventory_panel = InventoryPanelScene.instantiate()
	inventory_panel.close_requested.connect(_on_inventory_closed)
	# inventory_panel.fish_info_requested.connect(_on_fish_info_requested)
	inventory_panel.sell_selected_requested.connect(_on_discard_selected_fish)
	inventory_panel.sell_all_requested.connect(_on_discard_all_fish)

	# Asegurar que el overlay esté en el nivel superior
	inventory_panel.z_index = 100
	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(inventory_panel)

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

func show_save_manager():
	# Evitar crear múltiples instancias
	if save_manager:
		return

	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null

	var SaveManagerClass = preload("res://src/views/SaveManagerView.gd")
	save_manager = SaveManagerClass.new()
	save_manager.save_loaded.connect(_on_save_loaded)
	save_manager.save_created.connect(_on_save_created)
	save_manager.tree_exiting.connect(_on_save_manager_closed)
	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(save_manager)

func _on_save_loaded(slot: int):
	print("Save loaded from slot: ", slot)
	# Actualizar toda la UI después de cargar
	var top_bar = $TopBar
	if top_bar and top_bar.has_method("update_display"):
		top_bar.update_display()

func _on_save_created(slot: int):
	print("New save created in slot: ", slot)
	# Actualizar toda la UI después de crear nueva partida
	var top_bar = $TopBar
	if top_bar and top_bar.has_method("update_display"):
		top_bar.update_display()

func _on_milestones_closed():
	if milestones_panel:
		milestones_panel.queue_free()
		milestones_panel = null

func _on_settings_closed():
	if settings_menu:
		settings_menu.queue_free()
		settings_menu = null

func _on_save_manager_requested_from_settings():
	"""Gestor de guardado solicitado desde opciones"""
	_on_settings_closed()
	show_save_manager()

func _on_save_manager_requested_from_pause():
	"""Gestor de guardado solicitado desde pausa"""
	_on_pause_menu_closed()
	show_save_manager()

func _on_save_manager_closed():
	save_manager = null

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

func _on_zone_changed(zone_id: String):
	"""Manejar cambio de zona - actualizar TopBar y fondos"""
	print("Zone changed to: ", zone_id)

	# Actualizar TopBar para mostrar nueva zona y multiplicador
	var top_bar = $TopBar
	if top_bar and top_bar.has_method("update_display"):
		top_bar.update_display()

	# Actualizar fondo del FishingView
	var fishing_view = views.get(Tab.FISHING)
	if fishing_view and fishing_view.has_method("update_zone_background"):
		fishing_view.update_zone_background()

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

func create_debug_panel():
	"""Crear panel de debug para testing del skill tree"""
	var DebugPanelClass = preload("res://src/ui/SkillTreeDebugPanel.gd")
	debug_panel = DebugPanelClass.new()
	add_child(debug_panel)

func _on_fish_info_requested(fish_index: int):
	"""Manejar solicitud de mostrar información detallada de un pez"""
	var fish_instance = Save.get_fish_from_inventory(fish_index)
	if fish_instance:
		show_fish_info_panel(fish_instance)

func show_fish_info_panel(fish_instance: FishInstance):
	"""Mostrar panel de información detallada del pez"""
	if fish_info_panel:
		fish_info_panel.queue_free()

	fish_info_panel = FishInfoPanelClass.new()
	fish_info_panel.closed.connect(_on_fish_info_closed)
	fish_info_panel.z_index = 150 # Por encima del inventario
	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(fish_info_panel)

	fish_info_panel.show_fish_info(fish_instance)

func _on_fish_info_closed():
	"""Manejar cierre del panel de información de peces"""
	if fish_info_panel:
		fish_info_panel.queue_free()
		fish_info_panel = null

func show_species_legend():
	"""Mostrar panel de leyenda de especies"""
	if species_legend_panel:
		species_legend_panel.queue_free()

	species_legend_panel = SpeciesLegendPanelClass.new()
	species_legend_panel.closed.connect(_on_species_legend_closed)
	species_legend_panel.z_index = 120 # Por encima de otros paneles
	# AGREGAR AL ROOT DEL SCENE TREE PARA MÁXIMA VISIBILIDAD
	get_tree().root.add_child(species_legend_panel)

func _on_species_legend_closed():
	"""Manejar cierre del panel de leyenda de especies"""
	if species_legend_panel:
		species_legend_panel.queue_free()
		species_legend_panel = null
