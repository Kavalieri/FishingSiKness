class_name UpgradesPanel
extends Control

# Panel de mejoras reutilizable según especificación

signal upgrade_panel_closed
signal upgrade_purchased(upgrade_id: String)

enum UpgradeCategory {
	ROD,
	HOOK,
	LINE,
	BOAT
}

var current_category: UpgradeCategory = UpgradeCategory.ROD
var available_upgrades: Array[Dictionary] = []
var player_money: int = 0
var player_gems: int = 0
var player_stats: Dictionary = {}

const UPGRADE_CARD_SCENE = preload("res://scenes/ui_new/components/Card.tscn")

@onready var title_label: Label = $VBoxContainer/Header/Title
@onready var close_button: Button = $VBoxContainer/Header/CloseButton
@onready var rod_button: Button = $VBoxContainer/CategoryTabs/RodButton
@onready var hook_button: Button = $VBoxContainer/CategoryTabs/HookButton
@onready var line_button: Button = $VBoxContainer/CategoryTabs/LineButton
@onready var boat_button: Button = $VBoxContainer/CategoryTabs/BoatButton
@onready var money_label: Label = $VBoxContainer/PlayerStats/StatsContainer/ResourcesInfo / \
	MoneyContainer / MoneyLabel
@onready var gems_label: Label = $VBoxContainer/PlayerStats/StatsContainer/ResourcesInfo / \
	GemsContainer / GemsLabel
@onready var power_label: Label = $VBoxContainer/PlayerStats/StatsContainer/CurrentStats / \
	PowerLabel
@onready var luck_label: Label = $VBoxContainer/PlayerStats/StatsContainer/CurrentStats/LuckLabel
@onready var upgrades_grid: VBoxContainer = $VBoxContainer/UpgradesScroll/UpgradesGrid

func _ready() -> void:
	_connect_signals()
	_setup_initial_state()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	rod_button.toggled.connect(_on_category_toggled.bind(UpgradeCategory.ROD))
	hook_button.toggled.connect(_on_category_toggled.bind(UpgradeCategory.HOOK))
	line_button.toggled.connect(_on_category_toggled.bind(UpgradeCategory.LINE))
	boat_button.toggled.connect(_on_category_toggled.bind(UpgradeCategory.BOAT))

func _setup_initial_state() -> void:
	_update_category_display()

func setup_upgrades(upgrades: Array[Dictionary], money: int, gems: int, stats: Dictionary) -> void:
	"""Configurar panel con datos de mejoras"""
	available_upgrades = upgrades
	player_money = money
	player_gems = gems
	player_stats = stats

	_update_resources_display()
	_update_stats_display()
	_refresh_upgrades_list()

func _update_resources_display() -> void:
	"""Actualizar visualización de recursos"""
	money_label.text = _format_number(player_money)
	gems_label.text = _format_number(player_gems)

func _update_stats_display() -> void:
	"""Actualizar visualización de estadísticas"""
	var power = player_stats.get("fishing_power", 0)
	var luck = player_stats.get("luck", 0)

	power_label.text = "Poder de Pesca: %d" % power
	luck_label.text = "Suerte: %d%%" % luck

func _format_number(number: int) -> String:
	"""Formatear números grandes"""
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	elif number >= 1000:
		return "%.1fK" % (number / 1000.0)
	else:
		return str(number)

func _update_category_display() -> void:
	"""Actualizar visualización de categoría activa"""
	rod_button.button_pressed = (current_category == UpgradeCategory.ROD)
	hook_button.button_pressed = (current_category == UpgradeCategory.HOOK)
	line_button.button_pressed = (current_category == UpgradeCategory.LINE)
	boat_button.button_pressed = (current_category == UpgradeCategory.BOAT)

func _refresh_upgrades_list() -> void:
	"""Actualizar lista de mejoras para la categoría actual"""
	# Limpiar mejoras existentes
	for child in upgrades_grid.get_children():
		child.queue_free()

	# Filtrar mejoras por categoría
	var category_name = _get_category_name(current_category)
	var filtered_upgrades = available_upgrades.filter(
		func(upgrade): return upgrade.get("category", "") == category_name
	)

	# Crear tarjetas para cada mejora
	for upgrade in filtered_upgrades:
		var upgrade_card = _create_upgrade_card(upgrade)
		upgrades_grid.add_child(upgrade_card)

func _get_category_name(category: UpgradeCategory) -> String:
	"""Obtener nombre de categoría"""
	match category:
		UpgradeCategory.ROD:
			return "rod"
		UpgradeCategory.HOOK:
			return "hook"
		UpgradeCategory.LINE:
			return "line"
		UpgradeCategory.BOAT:
			return "boat"
		_:
			return ""

func _create_upgrade_card(upgrade_data: Dictionary) -> Control:
	"""Crear tarjeta de mejora reutilizando Card"""
	var card = UPGRADE_CARD_SCENE.instantiate()

	# Información básica
	var name = upgrade_data.get("name", "")
	var description = upgrade_data.get("description", "")
	var icon = upgrade_data.get("icon", null)

	# Costo y disponibilidad
	var cost_money = upgrade_data.get("cost_money", 0)
	var cost_gems = upgrade_data.get("cost_gems", 0)
	var is_owned = upgrade_data.get("owned", false)
	var can_afford = _can_afford_upgrade(upgrade_data)

	# Texto del botón de acción
	var action_text = ""
	if is_owned:
		action_text = "Poseído"
	elif cost_gems > 0:
		action_text = "%d 💎" % cost_gems
	else:
		action_text = "%s 💰" % _format_number(cost_money)

	# Configurar tarjeta
	card.setup_card(name, description, icon, action_text)

	# Configurar estado del botón
	var action_button = card.get_node("MarginContainer/VBoxContainer/ActionButton")
	if is_owned:
		action_button.disabled = true
	elif not can_afford:
		action_button.disabled = true
		action_button.modulate = Color.GRAY

	# Conectar señal
	if not is_owned and can_afford:
		card.action_pressed.connect(_on_upgrade_selected.bind(upgrade_data))

	return card

func _can_afford_upgrade(upgrade_data: Dictionary) -> bool:
	"""Verificar si el jugador puede costear la mejora"""
	var cost_money = upgrade_data.get("cost_money", 0)
	var cost_gems = upgrade_data.get("cost_gems", 0)

	return player_money >= cost_money and player_gems >= cost_gems

func _on_close_pressed() -> void:
	upgrade_panel_closed.emit()

func _on_category_toggled(category: UpgradeCategory, pressed: bool) -> void:
	if not pressed:
		return

	current_category = category
	_update_category_display()
	_refresh_upgrades_list()

func _on_upgrade_selected(upgrade_data: Dictionary) -> void:
	"""Manejar selección de mejora"""
	var upgrade_id = upgrade_data.get("id", "")
	upgrade_purchased.emit(upgrade_id)
