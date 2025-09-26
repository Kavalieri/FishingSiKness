class_name UpgradesScreen
extends Control

# Pantalla de mejoras que reutiliza UpgradesPanel

signal upgrade_screen_closed
signal upgrade_purchased(upgrade_id: String)

const UPGRADES_PANEL_SCENE = preload("res://scenes/ui_new/components/UpgradesPanel.tscn")

@onready var upgrades_panel_container: Control = $UpgradesPanelContainer

var upgrades_panel: UpgradesPanel

func _ready() -> void:
	_setup_upgrades_panel()

func _setup_upgrades_panel() -> void:
	"""Configurar panel de mejoras reutilizable"""
	upgrades_panel = UPGRADES_PANEL_SCENE.instantiate() as UpgradesPanel
	if upgrades_panel:
		upgrades_panel.upgrade_panel_closed.connect(_on_upgrade_panel_closed)
		upgrades_panel.upgrade_purchased.connect(_on_upgrade_purchased)
		upgrades_panel_container.add_child(upgrades_panel)
	else:
		Logger.error("No se pudo instanciar UpgradesPanel")

func setup_screen() -> void:
	"""Configurar pantalla con datos del UpgradeSystem"""
	print("[UPGRADESSCREEN] setup_screen() llamado")
	print("[UPGRADESSCREEN] upgrades_panel existe: %s" % (upgrades_panel != null))
	print("[UPGRADESSCREEN] UpgradeSystem existe: %s" % (UpgradeSystem != null))

	if upgrades_panel and UpgradeSystem:
		print("[UPGRADESSCREEN] Obteniendo datos de upgrades...")
		var upgrades_data = _get_upgrades_data()
		print("[UPGRADESSCREEN] Upgrades obtenidos: %d" % upgrades_data.size())

		var money = Save.get_coins()
		var gems = Save.get_gems()
		var stats = _get_player_stats()

		print("[UPGRADESSCREEN] Money: %d, Gems: %d" % [money, gems])
		print("[UPGRADESSCREEN] Llamando setup_upgrades...")
		upgrades_panel.setup_upgrades(upgrades_data, money, gems, stats)
		print("[UPGRADESSCREEN] setup_screen completado")
	else:
		print("[UPGRADESSCREEN] ERROR: componentes no disponibles")

func _get_upgrades_data() -> Array[Dictionary]:
	"""Obtener datos de upgrades del sistema con precios balanceados"""
	var upgrades: Array[Dictionary] = []

	# Orden específico para cada categoría con precios balanceados
	var upgrade_order = {
		"rod": ["rod_handle", "rod_blank", "rod_guides"],
		"hook": ["hook_point", "hook_barb", "hook_bend"],
		"line": ["line_strength", "line_diameter", "line_coating"],
		"boat": ["boat_hull", "boat_engine", "boat_sonar", "boat_storage"]
	}

	for category in upgrade_order.keys():
		for upgrade_id in upgrade_order[category]:
			if UpgradeSystem.available_upgrades.has(upgrade_id):
				var upgrade_info = UpgradeSystem.get_upgrade_info(upgrade_id)
				var upgrade_data = {
					"id": upgrade_id,
					"name": upgrade_info.name,
					"description": upgrade_info.description,
					"category": category,
					"cost_money": upgrade_info.next_level_cost,
					"cost_gems": 0,
					"owned": upgrade_info.current_level > 0,
					"level": upgrade_info.current_level,
					"max_level": upgrade_info.max_level
				}
				upgrades.append(upgrade_data)

	return upgrades

func _get_upgrade_category(upgrade_id: String) -> String:
	"""Mapear upgrade_id a categoría - sistema realista por componentes"""
	match upgrade_id:
		# Rod Components
		"rod_handle", "rod_blank", "rod_guides":
			return "rod"
		# Hook Components
		"hook_point", "hook_barb", "hook_bend":
			return "hook"
		# Line Components
		"line_strength", "line_diameter", "line_coating":
			return "line"
		# Boat Components
		"boat_hull", "boat_engine", "boat_sonar", "boat_storage":
			return "boat"
		_:
			return "rod"

func _get_player_stats() -> Dictionary:
	"""Calcular estadísticas del jugador con upgrades aplicados"""
	var stats = {
		"fishing_power": 100, # Base power
		"luck": 0
	}

	# Aplicar efectos de upgrades
	for upgrade_id in UpgradeSystem.available_upgrades.keys():
		var level = Save.game_data.get("upgrades", {}).get(upgrade_id, 0)
		if level > 0:
			var upgrade_def = UpgradeSystem.available_upgrades[upgrade_id]
			match upgrade_id:
				"rod":
					stats.fishing_power += level * 10
				"hook":
					stats.luck += level * 5

	return stats

func _on_upgrade_panel_closed() -> void:
	upgrade_screen_closed.emit()

func _on_upgrade_purchased(upgrade_id: String) -> void:
	"""Manejar compra de upgrade"""
	var success = UpgradeSystem.purchase_upgrade(upgrade_id)

	if success:
		Logger.info("Upgrade comprado: " + upgrade_id)
		# Actualizar pantalla con nuevos datos
		setup_screen()
		upgrade_purchased.emit(upgrade_id)
	else:
		Logger.warn("No se pudo comprar upgrade: " + upgrade_id)
