class_name Tooltip
extends Control

# Tooltip básico según especificación

var is_visible: bool = false

@onready var title_label: Label = $TooltipPanel/MarginContainer/VBoxContainer/Title
@onready var description_label: Label = $TooltipPanel/MarginContainer/VBoxContainer/Description
@onready var tooltip_panel: PanelContainer = $TooltipPanel

func _ready() -> void:
	_setup_initial_state()

func _setup_initial_state() -> void:
	modulate.a = 0.0
	visible = false

func show_tooltip(title: String, description: String, position: Vector2) -> void:
	"""Mostrar tooltip en posición específica"""
	title_label.text = title
	description_label.text = description

	# Posicionar el tooltip
	global_position = position
	_adjust_position()

	visible = true
	is_visible = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_tooltip() -> void:
	"""Ocultar tooltip"""
	if not is_visible:
		return

	is_visible = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): visible = false)

func _adjust_position() -> void:
	"""Ajustar posición para que no se salga de pantalla"""
	var screen_size = get_viewport().get_visible_rect().size
	var tooltip_size = tooltip_panel.get_combined_minimum_size()

	# Ajustar posición X
	if global_position.x + tooltip_size.x > screen_size.x:
		global_position.x = screen_size.x - tooltip_size.x - 10

	# Ajustar posición Y
	if global_position.y + tooltip_size.y > screen_size.y:
		global_position.y = global_position.y - tooltip_size.y - 10
