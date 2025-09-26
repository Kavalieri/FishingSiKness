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

const UPGRADE_CARD_SCENE = preload("res://scenes/ui_new/components/UpgradeCard.tscn")

@onready var title_label: Label = $VBoxContainer/Header/Title
# Removed close button - not needed in upgrades panel
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
	rod_button.pressed.connect(_on_category_pressed.bind(UpgradeCategory.ROD))
	hook_button.pressed.connect(_on_category_pressed.bind(UpgradeCategory.HOOK))
	line_button.pressed.connect(_on_category_pressed.bind(UpgradeCategory.LINE))
	boat_button.pressed.connect(_on_category_pressed.bind(UpgradeCategory.BOAT))

func _setup_initial_state() -> void:
	_update_category_display()

func setup_upgrades(upgrades: Array[Dictionary], money: int, gems: int, stats: Dictionary) -> void:
	"""Configurar panel con datos de mejoras"""
	print("[UPGRADESPANEL] setup_upgrades llamado")
	print("[UPGRADESPANEL] Upgrades recibidos: %d" % upgrades.size())
	print("[UPGRADESPANEL] Money: %d, Gems: %d" % [money, gems])

	available_upgrades = upgrades
	player_money = money
	player_gems = gems
	player_stats = stats

	print("[UPGRADESPANEL] Actualizando displays...")
	_update_resources_display()
	_update_stats_display()
	_refresh_upgrades_list()
	print("[UPGRADESPANEL] Setup completado")

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
	if number >= 1000:
		return "%.1fK" % (number / 1000.0)
	return str(number)

func _format_effect_value(effect: float) -> String:
	"""Formatear valor de efecto para mostrar en UI"""
	if effect == 0:
		return "Sin efecto"

	# Para multiplicadores (valores > 1.0)
	if effect >= 1.0:
		if effect == int(effect):
			return "x%.0f" % effect
		return "x%.2f" % effect

	# Para porcentajes (valores < 1.0 pero > 0)
	return "%.1f%%" % (effect * 100)

func _update_category_display() -> void:
	"""Actualizar visualización de categoría activa"""
	# Visual feedback for active category
	rod_button.modulate = Color.WHITE if current_category == UpgradeCategory.ROD else Color.GRAY
	hook_button.modulate = Color.WHITE if current_category == UpgradeCategory.HOOK else Color.GRAY
	line_button.modulate = Color.WHITE if current_category == UpgradeCategory.LINE else Color.GRAY
	boat_button.modulate = Color.WHITE if current_category == UpgradeCategory.BOAT else Color.GRAY

func _refresh_upgrades_list() -> void:
	"""Actualizar lista de mejoras para la categoría actual"""
	# Limpiar mejoras existentes
	for child in upgrades_grid.get_children():
		child.queue_free()

	# Filtrar mejoras por categoría
	var category_name = _get_category_name(current_category)
	print("[UPGRADESPANEL] Filtrando por categoría: %s" % category_name)
	print("[UPGRADESPANEL] Total upgrades disponibles: %d" % available_upgrades.size())
	
	var filtered_upgrades = available_upgrades.filter(
		func(upgrade): return upgrade.get("category", "") == category_name
	)
	
	print("[UPGRADESPANEL] Upgrades filtrados: %d" % filtered_upgrades.size())
	for upgrade in filtered_upgrades:
		print("[UPGRADESPANEL] - %s (categoría: %s)" % [upgrade.get("name", "?"), upgrade.get("category", "?")])

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
	"""Crear tarjeta de mejora especializada"""
	var card = UPGRADE_CARD_SCENE.instantiate() as UpgradeCard

	# Configurar tarjeta con datos
	card.setup_upgrade(upgrade_data)

	# Conectar señales
	card.upgrade_purchased.connect(_on_upgrade_selected)
	card.upgrade_info_requested.connect(_on_upgrade_info_requested)

	return card

func _can_afford_upgrade(upgrade_data: Dictionary) -> bool:
	"""Verificar si el jugador puede costear la mejora"""
	var cost_money = upgrade_data.get("cost_money", 0)
	var cost_gems = upgrade_data.get("cost_gems", 0)

	return player_money >= cost_money and player_gems >= cost_gems

func _on_upgrade_info_requested(upgrade_id: String) -> void:
	"""Mostrar información detallada del upgrade"""
	# Crear y mostrar popup de información
	var popup_scene = preload("res://scenes/ui_new/components/UpgradeInfoPopup.tscn")
	var popup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show_upgrade_info(upgrade_id)
	popup.popup_closed.connect(func(): popup.queue_free())

func _on_category_pressed(category: UpgradeCategory) -> void:
	print("[UPGRADESPANEL] Cambiando a categoría: %s" % category)
	current_category = category
	_update_category_display()
	_refresh_upgrades_list()

func _on_upgrade_selected(upgrade_id: String) -> void:
	"""Manejar selección de mejora"""
	upgrade_purchased.emit(upgrade_id)

func _get_milestone_info(upgrade_id: String) -> Dictionary:
	"""Obtener información de milestones para un upgrade"""
	var upgrade_def = UpgradeSystem.available_upgrades.get(upgrade_id)
	if not upgrade_def:
		return {}
	
	var milestones = {}
	for level in range(1, upgrade_def.max_level + 1):
		var cost = upgrade_def.get_level_cost(level)
		var effect_key = UpgradeSystem.PRIMARY_EFFECT_KEY_BY_ID.get(upgrade_id, "")
		var effect_value = upgrade_def.get_effect_at_level(effect_key, level) if effect_key else 0
		
		milestones[level] = {
			"cost": cost,
			"effect": effect_value,
			"description": "Nivel %d: %s" % [level, _format_effect_value(effect_value)]
		}
	
	return milestones
