class_name UpgradeInfoPopup
extends Control

# Popup de información detallada de upgrades con milestones

signal popup_closed

@onready var background: ColorRect = $Background
@onready var popup_panel: PanelContainer = $PopupPanel
@onready var title_label: Label = $PopupPanel/VBox/Header/Title
@onready var close_button: Button = $PopupPanel/VBox/Header/CloseButton
@onready var description_label: Label = $PopupPanel/VBox/Description
@onready var milestones_container: VBoxContainer = $PopupPanel/VBox/ScrollContainer/MilestonesContainer

func _ready() -> void:
	background.color = Color(0, 0, 0, 0.7)
	background.gui_input.connect(_on_background_clicked)
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func show_upgrade_info(upgrade_id: String) -> void:
	"""Mostrar información detallada del upgrade"""
	var upgrade_info = UpgradeSystem.get_upgrade_info(upgrade_id)
	if upgrade_info.is_empty():
		return
	
	title_label.text = upgrade_info.get("name", "")
	description_label.text = upgrade_info.get("description", "")
	
	_populate_milestones(upgrade_id, upgrade_info)
	
	visible = true

func _populate_milestones(upgrade_id: String, upgrade_info: Dictionary) -> void:
	"""Poblar información de milestones"""
	# Limpiar contenido anterior
	for child in milestones_container.get_children():
		child.queue_free()
	
	var current_level = upgrade_info.get("current_level", 0)
	var max_level = upgrade_info.get("max_level", 1)
	var upgrade_def = UpgradeSystem.available_upgrades.get(upgrade_id)
	
	if not upgrade_def:
		return
	
	var effect_key = UpgradeSystem.PRIMARY_EFFECT_KEY_BY_ID.get(upgrade_id, "")
	
	# Crear milestone para cada nivel
	for level in range(1, max_level + 1):
		var milestone_panel = PanelContainer.new()
		var milestone_hbox = HBoxContainer.new()
		milestone_panel.add_child(milestone_hbox)
		
		# Indicador de estado
		var status_label = Label.new()
		if level <= current_level:
			status_label.text = "✅"
			status_label.modulate = Color.GREEN
		elif level == current_level + 1:
			status_label.text = "🎯"
			status_label.modulate = Color.YELLOW
		else:
			status_label.text = "⭕"
			status_label.modulate = Color.GRAY
		
		milestone_hbox.add_child(status_label)
		
		# Información del nivel
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		milestone_hbox.add_child(info_vbox)
		
		var level_label = Label.new()
		level_label.text = "Nivel %d" % level
		level_label.add_theme_font_size_override("font_size", 16)
		info_vbox.add_child(level_label)
		
		var cost_label = Label.new()
		var cost = upgrade_def.get_level_cost(level)
		cost_label.text = "Costo: %s 💰" % _format_number(cost)
		cost_label.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(cost_label)
		
		if effect_key:
			var effect_value = upgrade_def.get_effect_at_level(effect_key, level)
			var effect_label = Label.new()
			effect_label.text = "Efecto: %s" % _format_effect(effect_value)
			effect_label.add_theme_font_size_override("font_size", 12)
			effect_label.modulate = Color.LIGHT_GREEN
			info_vbox.add_child(effect_label)
		
		milestones_container.add_child(milestone_panel)

func _format_number(number: int) -> String:
	"""Formatear números grandes"""
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	elif number >= 1000:
		return "%.1fK" % (number / 1000.0)
	return str(number)

func _format_effect(value: float) -> String:
	"""Formatear valor de efecto"""
	if value == 0:
		return "Sin efecto"
	elif value >= 1.0:
		return "x%.2f" % value if value != int(value) else "x%d" % int(value)
	else:
		return "%.1f%%" % (value * 100)

func _on_background_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_popup()

func _on_close_pressed() -> void:
	_close_popup()

func _close_popup() -> void:
	visible = false
	popup_closed.emit()