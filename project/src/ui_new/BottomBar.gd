class_name BottomBarUI
extends Control

# BottomBar profesional: 5 botones cuadrados 1:1 (solo imagen + tooltip)
# Pesca | Mapa | Mercado | Mejoras | Prestigio

signal tab_selected(tab_name: String)

@onready var btn_fishing: TextureButton = $HBoxContainer/FishingBtn/TextureButton
@onready var btn_map: TextureButton = $HBoxContainer/MapBtn/TextureButton
@onready var btn_market: TextureButton = $HBoxContainer/MarketBtn/TextureButton
@onready var btn_upgrades: TextureButton = $HBoxContainer/UpgradesBtn/TextureButton
@onready var btn_prestige: TextureButton = $HBoxContainer/PrestigeBtn/TextureButton

var current_tab := "fishing"

func _ready() -> void:
	print("[BottomBar] _ready() called")
	_connect_buttons()
	_set_dynamic_tooltips()
	_set_initial_tab()
	print("[BottomBar] Initialization completed")

func _set_dynamic_tooltips() -> void:
	"""Configurar tooltips dinámicos con i18n"""
	btn_fishing.tooltip_text = tr("ui.tab.fish")
	btn_map.tooltip_text = tr("ui.tab.map")
	btn_market.tooltip_text = tr("ui.tab.market")
	btn_upgrades.tooltip_text = tr("ui.tab.upgrades")
	btn_prestige.tooltip_text = tr("ui.tab.prestige")

func _connect_buttons() -> void:
	"""Conectar señales de botones"""
	btn_fishing.pressed.connect(func(): _select_tab("fishing"))
	btn_map.pressed.connect(func(): _select_tab("map"))
	btn_market.pressed.connect(func(): _select_tab("market"))
	btn_upgrades.pressed.connect(func(): _select_tab("upgrades"))
	btn_prestige.pressed.connect(func(): _select_tab("prestige"))

func _select_tab(tab_name: String) -> void:
	"""Seleccionar tab y actualizar estado visual"""
	if current_tab == tab_name:
		return # Ya está seleccionado

	current_tab = tab_name
	_update_visual_state()
	print("[BottomBar] Emitiendo señal tab_selected: ", tab_name)
	tab_selected.emit(tab_name)

func _set_initial_tab() -> void:
	"""Establecer tab inicial"""
	_select_tab("fishing")

func _update_visual_state() -> void:
	"""Actualizar estado visual de botones (activo/inactivo)"""
	var buttons = [
		{"button": btn_fishing, "tab": "fishing"},
		{"button": btn_map, "tab": "map"},
		{"button": btn_market, "tab": "market"},
		{"button": btn_upgrades, "tab": "upgrades"},
		{"button": btn_prestige, "tab": "prestige"}
	]

	for btn_data in buttons:
		var is_active = btn_data.tab == current_tab
		_set_button_active_state(btn_data.button, is_active)

func _set_button_active_state(button: TextureButton, is_active: bool) -> void:
	"""Establecer estado visual activo/inactivo del botón"""
	# TODO: Aplicar theme/estilo para estado activo
	# Por ahora usamos modulate como placeholder
	if is_active:
		button.modulate = Color.WHITE
	else:
		button.modulate = Color(0.7, 0.7, 0.7)
