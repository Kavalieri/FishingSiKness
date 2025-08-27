class_name ScreenManager
extends Control

# Enums para las pestañas (orden: Pescar, Mercado, Mejoras, Mapa, Prestigio)
enum Tab {
	FISHING = 0,
	MARKET = 1,
	UPGRADES = 2,
	MAP = 3,
	PRESTIGE = 4
}

# Recursos precargados

const InventoryPanelScene = preload("res://scenes/ui/InventoryPanel.tscn")
const FishInfoPanelClass = preload("res://src/ui/FishInfoPanel.gd")
const SpeciesLegendPanelClass = preload("res://src/ui/SpeciesLegendPanel.gd")
const FishCardMenuClass = preload("res://src/ui/FishCardMenu.gd")

var views = {}
var current_tab = Tab.FISHING

# Overlays
var inventory_panel: Control
var fish_info_panel: FishInfoPanel
var species_legend_panel: SpeciesLegendPanel
var milestones_panel: Control
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

	# Conectar con el gestor de ventanas global
	if FloatingWindowManager:
		FloatingWindowManager.window_opened.connect(_on_any_window_opened)
		FloatingWindowManager.window_closed.connect(_on_any_window_closed)

	# Mostrar la pestaña inicial
	show_tab(Tab.FISHING)

	# Crear debug panel (accesible con F2)
	create_debug_panel()

	App.screen_manager = self

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
	FloatingWindowManager.open_window("res://scenes/views/StoreView.tscn", {"title": "Tienda"})

func show_pause_menu():
	print("--- PAUSE MENU REQUESTED ---")
	FloatingWindowManager.open_window("res://scenes/views/PauseMenu.tscn", {"title": "Pausa"})

func show_settings_menu():
	FloatingWindowManager.open_window("res://scenes/views/SettingsMenu.tscn", {"title": "Opciones"})

func show_milestones_panel():
	FloatingWindowManager.open_window("res://scenes/views/MilestonesPanel.tscn", {"title": "🌟 ÁRBOL DE HABILIDADES"})

func _on_any_window_opened(window: Control):
	# Conectar señales dinámicamente cuando se abre una ventana
	if window is PauseMenu:
		window.resume_requested.connect(_on_pause_menu_closed)
		window.save_and_exit_to_menu_requested.connect(_on_save_and_exit)
		window.settings_requested.connect(show_settings_menu)
		#window.save_manager_requested.connect(_on_save_manager_requested_from_pause)
	elif window is SettingsMenu:
		#window.save_manager_requested.connect(_on_save_manager_requested_from_settings)
		pass

func _on_any_window_closed(window: Control):
	# Si la ventana que se cerró es la tienda, actualizamos la TopBar.
	if window is StoreView:
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

func _on_pause_menu_closed():
	# La ventana se cierra sola a través de FloatingWindowManager, no necesitamos hacer nada aquí.
	pass

func _on_save_and_exit():
	print("Saving game before exit...")
	Save.save_game()
	get_tree().quit()

func _on_save_manager_requested_from_pause():
	# Primero cerramos el menú de pausa, luego abrimos el gestor de guardado.
	var pause_menu = FloatingWindowManager.get_top_window()
	if pause_menu is PauseMenu:
		pause_menu.close()

	# TODO: Refactorizar SaveManagerView
	print("TODO: Refactorizar SaveManagerView y abrirlo aquí")

func _on_save_manager_requested_from_settings():
	# Primero cerramos el menú de opciones, luego abrimos el gestor de guardado.
	var settings_menu = FloatingWindowManager.get_top_window()
	if settings_menu is SettingsMenu:
		settings_menu.close()

	# TODO: Refactorizar SaveManagerView
	print("TODO: Refactorizar SaveManagerView y abrirlo aquí")

# --- Resto de funciones sin cambios por ahora ---

func create_debug_panel():
	var DebugPanelClass = preload("res://src/ui/SkillTreeDebugPanel.gd")
	debug_panel = DebugPanelClass.new()
	add_child(debug_panel)

func show_inventory(show: bool, title: String = "Inventario"):
	if show:
		if not is_instance_valid(inventory_panel):
			inventory_panel = InventoryPanelScene.instantiate()
			add_child(inventory_panel)
			inventory_panel.close_requested.connect(hide_inventory)
		inventory_panel.visible = true
		inventory_panel.refresh_display()
	else:
		hide_inventory()

func hide_inventory():
	if is_instance_valid(inventory_panel):
		inventory_panel.visible = false
