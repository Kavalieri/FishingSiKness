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
	upgrades_panel = UPGRADES_PANEL_SCENE.instantiate()
	upgrades_panel.upgrade_panel_closed.connect(_on_upgrade_panel_closed)
	upgrades_panel.upgrade_purchased.connect(_on_upgrade_purchased)
	upgrades_panel_container.add_child(upgrades_panel)

func setup_upgrades_screen(upgrades: Array[Dictionary], money: int, gems: int,
	stats: Dictionary) -> void:
	"""Configurar pantalla con datos de mejoras"""
	if upgrades_panel:
		upgrades_panel.setup_upgrades(upgrades, money, gems, stats)

func _on_upgrade_panel_closed() -> void:
	upgrade_screen_closed.emit()

func _on_upgrade_purchased(upgrade_id: String) -> void:
	upgrade_purchased.emit(upgrade_id)
