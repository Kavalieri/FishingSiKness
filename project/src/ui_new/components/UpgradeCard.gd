class_name UpgradeCard
extends PanelContainer

# Tarjeta específica para mejoras con barra de progreso y milestones

signal upgrade_purchased(upgrade_id: String)
signal upgrade_info_requested(upgrade_id: String)

var upgrade_data: Dictionary = {}

@onready var icon: TextureRect = $MarginContainer/HBoxContainer/Icon
@onready var title_label: Label = $MarginContainer/HBoxContainer/UpgradeInfo/Title
@onready var description_label: Label = $MarginContainer/HBoxContainer/UpgradeInfo/Description
@onready var progress_bar: ProgressBar = $MarginContainer/HBoxContainer/UpgradeInfo/ProgressContainer/ProgressBar
@onready var level_label: Label = $MarginContainer/HBoxContainer/UpgradeInfo/ProgressContainer/LevelLabel
@onready var effect_label: Label = $MarginContainer/HBoxContainer/UpgradeInfo/EffectLabel
@onready var buy_button: Button = $MarginContainer/HBoxContainer/ButtonsContainer/BuyButton
@onready var info_button: Button = $MarginContainer/HBoxContainer/ButtonsContainer/InfoButton

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	info_button.pressed.connect(_on_info_pressed)

func setup_upgrade(data: Dictionary) -> void:
	"""Configurar tarjeta con datos de upgrade"""
	upgrade_data = data
	
	if not is_inside_tree():
		call_deferred("_setup_upgrade_deferred", data)
		return
	
	_setup_upgrade_deferred(data)

func _setup_upgrade_deferred(data: Dictionary) -> void:
	"""Configurar tarjeta (método diferido)"""
	var upgrade_id = data.get("id", "")
	var upgrade_info = UpgradeSystem.get_upgrade_info(upgrade_id)
	
	# Información básica
	title_label.text = upgrade_info.get("name", "")
	description_label.text = upgrade_info.get("description", "")
	
	# Progreso y nivel
	var current_level = upgrade_info.get("current_level", 0)
	var max_level = upgrade_info.get("max_level", 1)
	var next_cost = upgrade_info.get("next_level_cost", 0)
	
	level_label.text = "%d/%d" % [current_level, max_level]
	progress_bar.max_value = max_level
	progress_bar.value = current_level
	
	# Efecto actual y siguiente
	var current_effect = upgrade_info.get("current_effect", 0)
	var next_effect = upgrade_info.get("next_effect", 0)
	
	if current_level >= max_level:
		effect_label.text = "✨ Máximo: %s" % _format_effect(current_effect)
		buy_button.text = "MÁXIMO"
		buy_button.disabled = true
		buy_button.modulate = Color.GREEN * 0.8
	elif current_level == 0:
		effect_label.text = "Siguiente: %s" % _format_effect(next_effect)
		buy_button.text = "%s 💰" % _format_number(next_cost)
		_update_buy_button_state(next_cost)
	else:
		effect_label.text = "Actual: %s → %s" % [_format_effect(current_effect), _format_effect(next_effect)]
		buy_button.text = "%s 💰" % _format_number(next_cost)
		_update_buy_button_state(next_cost)
	
	# Verificar si está desbloqueado
	if not _is_upgrade_unlocked(upgrade_id):
		buy_button.text = "BLOQUEADO"
		buy_button.disabled = true
		buy_button.modulate = Color.GRAY
		effect_label.text = "Requiere milestone anterior"

func _is_upgrade_unlocked(upgrade_id: String) -> bool:
	"""Verificar si el upgrade está desbloqueado según milestones"""
	var unlock_requirements = _get_unlock_requirements(upgrade_id)
	
	for req_id in unlock_requirements.keys():
		var required_level = unlock_requirements[req_id]
		var current_level = Save.game_data.get("upgrades", {}).get(req_id, 0)
		if current_level < required_level:
			return false
	
	return true

func _get_unlock_requirements(upgrade_id: String) -> Dictionary:
	"""Obtener requisitos de desbloqueo para cada upgrade"""
	var requirements = {
		# Rod upgrades - secuencial
		"rod_blank": {"rod_handle": 3},
		"rod_guides": {"rod_blank": 5},
		
		# Hook upgrades - secuencial
		"hook_barb": {"hook_point": 3},
		"hook_bend": {"hook_barb": 5},
		
		# Line upgrades - secuencial
		"line_diameter": {"line_strength": 3},
		"line_coating": {"line_diameter": 5},
		
		# Boat upgrades - secuencial
		"boat_engine": {"boat_hull": 3},
		"boat_sonar": {"boat_engine": 5},
		"boat_storage": {"boat_sonar": 3}
	}
	
	return requirements.get(upgrade_id, {})

func _update_buy_button_state(cost: int) -> void:
	"""Actualizar estado del botón de compra"""
	var can_afford = Save.get_coins() >= cost
	buy_button.disabled = not can_afford
	buy_button.modulate = Color.WHITE if can_afford else Color.GRAY

func _format_effect(value: float) -> String:
	"""Formatear valor de efecto"""
	if value == 0:
		return "Sin efecto"
	elif value >= 1.0:
		return "x%.2f" % value if value != int(value) else "x%d" % int(value)
	else:
		return "%.1f%%" % (value * 100)

func _format_number(number: int) -> String:
	"""Formatear números grandes"""
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	elif number >= 1000:
		return "%.1fK" % (number / 1000.0)
	return str(number)

func _on_buy_pressed() -> void:
	upgrade_purchased.emit(upgrade_data.get("id", ""))

func _on_info_pressed() -> void:
	upgrade_info_requested.emit(upgrade_data.get("id", ""))