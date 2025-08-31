class_name Card
extends PanelContainer

# Componente tarjeta reutilizable según especificación

signal action_pressed(card_data: Dictionary)

var card_data: Dictionary = {}

@onready var icon: TextureRect = $MarginContainer/HBoxContainer/Icon
@onready var title_label: Label = $MarginContainer/HBoxContainer/ZoneInfo/Title
@onready var description_label: Label = $MarginContainer/HBoxContainer/ZoneInfo/Description
@onready var difficulty_label: Label = $MarginContainer/HBoxContainer/ZoneInfo/Stats/DifficultyLabel
@onready var fish_count_label: Label = $MarginContainer/HBoxContainer/ZoneInfo/Stats/FishCountLabel
@onready var action_button: Button = $MarginContainer/HBoxContainer/ActionButton

func _ready() -> void:
	# Conectar señal del botón si no está conectada ya
	if action_button and not action_button.pressed.is_connected(_on_action_pressed):
		action_button.pressed.connect(_on_action_pressed)

func setup_card(data: Dictionary) -> void:
	"""Configurar tarjeta con datos"""
	card_data = data

	# Si no estamos en el árbol aún, diferir la configuración
	if not is_inside_tree():
		call_deferred("_setup_card_deferred", data)
		return

	_setup_card_deferred(data)

func _setup_card_deferred(data: Dictionary) -> void:
	"""Configurar tarjeta con datos (método diferido)"""
	# Asegurar que los nodos estén disponibles
	if not title_label:
		title_label = $MarginContainer/HBoxContainer/ZoneInfo/Title
	if not description_label:
		description_label = $MarginContainer/HBoxContainer/ZoneInfo/Description
	if not difficulty_label:
		difficulty_label = $MarginContainer/HBoxContainer/ZoneInfo/Stats/DifficultyLabel
	if not fish_count_label:
		fish_count_label = $MarginContainer/HBoxContainer/ZoneInfo/Stats/FishCountLabel
	if not action_button:
		action_button = $MarginContainer/HBoxContainer/ActionButton
	if not icon:
		icon = $MarginContainer/HBoxContainer/Icon

	if data.has("title"):
		title_label.text = str(data.title)

	if data.has("description"):
		description_label.text = str(data.description)

	if data.has("action_text"):
		action_button.text = str(data.action_text)

	# Información adicional para tarjetas de zona
	if data.has("difficulty"):
		difficulty_label.text = str(data.difficulty)

	if data.has("fish_count"):
		fish_count_label.text = str(data.fish_count)

	if data.has("icon_path"):
		var texture = load(str(data.icon_path))
		if texture and icon:
			icon.texture = texture

	if data.has("tooltip"):
		tooltip_text = str(data.tooltip)

func _on_action_pressed() -> void:
	action_pressed.emit(card_data)
