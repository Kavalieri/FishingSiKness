class_name Card
extends PanelContainer

# Componente tarjeta reutilizable según especificación

signal action_pressed(card_data: Dictionary)

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Icon
@onready var title_label: Label = $MarginContainer/VBoxContainer/Title
@onready var description_label: Label = $MarginContainer/VBoxContainer/Description
@onready var action_button: Button = $MarginContainer/VBoxContainer/ActionButton

var card_data: Dictionary = {}

func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)

func setup_card(data: Dictionary) -> void:
	"""Configurar tarjeta con datos"""
	card_data = data

	if data.has("title"):
		title_label.text = str(data.title)

	if data.has("description"):
		description_label.text = str(data.description)

	if data.has("action_text"):
		action_button.text = str(data.action_text)

	if data.has("icon_path"):
		var texture = load(str(data.icon_path))
		if texture:
			icon.texture = texture

	if data.has("tooltip"):
		tooltip_text = str(data.tooltip)

func _on_action_pressed() -> void:
	action_pressed.emit(card_data)
