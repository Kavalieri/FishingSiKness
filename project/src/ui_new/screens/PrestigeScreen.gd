class_name PrestigeScreen
extends Control

# Pantalla de prestigio según especificación

signal prestige_screen_closed
signal prestige_confirmed
signal prestige_bonus_purchased(bonus_id: String)

var current_prestige_level: int = 0
var available_prestige_points: int = 0
var next_reset_points: int = 0
var prestige_bonuses: Array[Dictionary] = []
var can_prestige: bool = false

const PRESTIGE_CARD_SCENE = preload("res://scenes/ui_new/components/Card.tscn")

@onready var prestige_level_value: Label = $VBoxContainer/CurrentStatus/StatusContainer / \
	PrestigeLevel / PrestigeLevelValue
@onready var prestige_points_value: Label = $VBoxContainer/CurrentStatus/StatusContainer / \
	PrestigePoints / PrestigePointsValue
@onready var next_reset_value: Label = $VBoxContainer/CurrentStatus/StatusContainer / \
	NextReset / NextResetValue
@onready var bonuses_grid: VBoxContainer = $VBoxContainer/BonusesSection/BonusesScroll / \
	BonusesGrid
@onready var prestige_button: Button = $VBoxContainer/PrestigeActions/ButtonsContainer / \
	PrestigeButton
@onready var cancel_button: Button = $VBoxContainer/PrestigeActions/ButtonsContainer/CancelButton

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)

func setup_prestige_screen(prestige_level: int, prestige_points: int, next_points: int,
	bonuses: Array[Dictionary], can_do_prestige: bool) -> void:
	"""Configurar pantalla de prestigio con datos actuales"""
	current_prestige_level = prestige_level
	available_prestige_points = prestige_points
	next_reset_points = next_points
	prestige_bonuses = bonuses
	can_prestige = can_do_prestige

	_update_status_display()
	_refresh_bonuses_list()
	_update_prestige_button()

func _update_status_display() -> void:
	"""Actualizar información de estado"""
	prestige_level_value.text = "⭐ %d" % current_prestige_level
	prestige_points_value.text = "✨ %d" % available_prestige_points
	next_reset_value.text = "+%d ✨" % next_reset_points

func _refresh_bonuses_list() -> void:
	"""Actualizar lista de bonificaciones disponibles"""
	# Limpiar bonificaciones existentes
	for child in bonuses_grid.get_children():
		child.queue_free()

	# Crear tarjetas para cada bonificación
	for bonus in prestige_bonuses:
		var bonus_card = _create_bonus_card(bonus)
		bonuses_grid.add_child(bonus_card)

func _create_bonus_card(bonus_data: Dictionary) -> Control:
	"""Crear tarjeta de bonificación reutilizando Card"""
	var card = PRESTIGE_CARD_SCENE.instantiate()

	# Información básica
	var name = bonus_data.get("name", "")
	var description = _get_bonus_description(bonus_data)
	var icon = bonus_data.get("icon", null)
	var cost = bonus_data.get("cost", 0)
	var is_owned = bonus_data.get("owned", false)
	var max_level = bonus_data.get("max_level", 1)
	var current_level = bonus_data.get("current_level", 0)

	# Texto de acción
	var action_text = ""
	if is_owned and current_level >= max_level:
		action_text = "MÁXIMO"
	elif is_owned:
		action_text = "Nv. %d → %d\n%d ✨" % [current_level, current_level + 1, cost]
	elif available_prestige_points >= cost:
		action_text = "Comprar\n%d ✨" % cost
	else:
		action_text = "Sin puntos\n%d ✨" % cost

	# Configurar tarjeta
	card.setup_card(name, description, icon, action_text)

	# Configurar estado del botón
	var action_button = card.get_node("MarginContainer/VBoxContainer/ActionButton")
	var can_afford = available_prestige_points >= cost
	var at_max = is_owned and current_level >= max_level

	if at_max:
		action_button.disabled = true
		action_button.modulate = Color.GOLD
	elif not can_afford:
		action_button.disabled = true
		action_button.modulate = Color.GRAY

	# Conectar señal
	if can_afford and not at_max:
		card.action_pressed.connect(_on_bonus_selected.bind(bonus_data))

	return card

func _get_bonus_description(bonus_data: Dictionary) -> String:
	"""Generar descripción de bonificación"""
	var base_description = bonus_data.get("description", "")
	var bonus_type = bonus_data.get("type", "")
	var bonus_value = bonus_data.get("value", 0.0)
	var current_level = bonus_data.get("current_level", 0)

	var enhanced_description = base_description

	# Añadir información del efecto
	match bonus_type:
		"multiplier":
			var current_bonus = bonus_value * current_level
			var next_bonus = bonus_value * (current_level + 1)
			enhanced_description += "\n\nActual: +%d%%" % (current_bonus * 100)
			enhanced_description += "\nSiguiente: +%d%%" % (next_bonus * 100)
		"flat":
			var current_bonus = bonus_value * current_level
			var next_bonus = bonus_value * (current_level + 1)
			enhanced_description += "\n\nActual: +%d" % current_bonus
			enhanced_description += "\nSiguiente: +%d" % next_bonus
		"unlock":
			if current_level > 0:
				enhanced_description += "\n\n✅ Desbloqueado"
			else:
				enhanced_description += "\n\n🔒 Bloqueado"

	return enhanced_description

func _update_prestige_button() -> void:
	"""Actualizar estado del botón de prestigio"""
	prestige_button.disabled = not can_prestige

	if can_prestige:
		prestige_button.modulate = Color.WHITE
		prestige_button.text = "🌟 PRESTIGIAR 🌟"
	else:
		prestige_button.modulate = Color.GRAY
		prestige_button.text = "🌟 Requisitos no cumplidos 🌟"

func _show_prestige_confirmation() -> void:
	"""Mostrar confirmación de prestigio"""
	# Crear popup de confirmación usando PopupWindow
	var popup_scene = preload("res://scenes/ui_new/components/PopupWindow.tscn")
	var popup = popup_scene.instantiate()

	# Configurar popup
	popup.set_title("⚠️ CONFIRMAR PRESTIGIO ⚠️")
	popup.set_buttons("SÍ, PRESTIGIAR", "Cancelar")

	# Crear contenido de confirmación
	var content = VBoxContainer.new()

	var warning_label = Label.new()
	warning_label.text = "Esto reiniciará completamente tu progreso:"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(warning_label)

	var reset_list = VBoxContainer.new()
	var reset_items = [
		"• Todo el dinero y gemas",
		"• Equipamiento y mejoras de equipo",
		"• Progreso de zonas desbloqueadas",
		"• Inventario de peces y objetos"
	]

	for item in reset_items:
		var item_label = Label.new()
		item_label.text = item
		reset_list.add_child(item_label)

	content.add_child(reset_list)

	var gain_label = Label.new()
	gain_label.text = "\nGanarás: +%d ✨ Puntos de Prestigio" % next_reset_points
	gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(gain_label)

	popup.set_content(content)

	# Conectar señales
	popup.accepted.connect(_on_prestige_confirmed)
	popup.cancelled.connect(func(): popup.queue_free())
	popup.closed.connect(func(): popup.queue_free())

	# Añadir al árbol
	get_tree().current_scene.add_child(popup)

func _on_prestige_button_pressed() -> void:
	"""Manejar presión del botón de prestigio"""
	if can_prestige:
		_show_prestige_confirmation()

func _on_cancel_button_pressed() -> void:
	"""Manejar cancelación"""
	prestige_screen_closed.emit()

func _on_bonus_selected(bonus_data: Dictionary) -> void:
	"""Manejar selección de bonificación"""
	var bonus_id = bonus_data.get("id", "")
	prestige_bonus_purchased.emit(bonus_id)

func _on_prestige_confirmed() -> void:
	"""Manejar confirmación de prestigio"""
	prestige_confirmed.emit()
