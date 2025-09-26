class_name PrestigeScreen
extends Control

# Pantalla de prestigio

signal prestige_confirmed
signal prestige_screen_closed

@onready var prestige_level_value: Label = $VBoxContainer/CurrentStatus/StatusContainer/PrestigeLevel/PrestigeLevelValue
@onready var prestige_points_value: Label = $VBoxContainer/CurrentStatus/StatusContainer/PrestigePoints/PrestigePointsValue
@onready var next_reset_value: Label = $VBoxContainer/CurrentStatus/StatusContainer/NextReset/NextResetValue
@onready var warning_details: Label = $VBoxContainer/PrestigeActions/WarningContainer/WarningDetails
@onready var prestige_button: Button = $VBoxContainer/PrestigeActions/ButtonsContainer/PrestigeButton
@onready var cancel_button: Button = $VBoxContainer/PrestigeActions/ButtonsContainer/CancelButton
@onready var bonuses_grid: VBoxContainer = $VBoxContainer/BonusesSection/BonusesScroll/BonusesGrid

const PRESTIGE_BONUS_CARD = preload("res://scenes/ui_new/components/PrestigeBonusCard.tscn")

func _ready() -> void:
	_connect_signals()
	_setup_prestige_screen()

func _connect_signals() -> void:
	if prestige_button:
		prestige_button.pressed.connect(_on_prestige_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_close_pressed)

func _setup_prestige_screen() -> void:
	"""Configurar pantalla de prestigio con datos actuales"""
	if not PrestigeSystem:
		_show_error("Sistema de prestigio no disponible")
		return
	
	var prestige_info = PrestigeSystem.get_prestige_info()
	_update_display(prestige_info)
	_setup_bonuses()

func _update_display(info: Dictionary) -> void:
	"""Actualizar visualización con información de prestigio"""
	
	# Valores actuales
	prestige_level_value.text = "⭐ %d" % info.current_level
	prestige_points_value.text = "✨ %d" % info.current_points
	
	if info.can_prestige:
		next_reset_value.text = "+%d ✨" % info.points_to_gain
	else:
		next_reset_value.text = "No disponible"
	
	# Detalles de advertencia con requisitos
	var warning_text = "El prestigio reiniciará tu dinero, upgrades y progreso, pero ganarás multiplicadores permanentes.\n\n"
	warning_text += "📋 REQUISITOS:\n"
	warning_text += "• Niveles upgrades: %d / %d %s\n" % [
		info.total_upgrades, 
		info.requirements.min_total_upgrades,
		"✅" if info.total_upgrades >= info.requirements.min_total_upgrades else "❌"
	]
	warning_text += "• Monedas ganadas: %s / %s %s" % [
		_format_number(info.total_coins_earned),
		_format_number(info.requirements.min_coins_earned),
		"✅" if info.total_coins_earned >= info.requirements.min_coins_earned else "❌"
	]
	
	warning_details.text = warning_text
	
	# Estado del botón
	prestige_button.disabled = not info.can_prestige
	prestige_button.text = "🌟 PRESTIGIAR 🌟" if info.can_prestige else "REQUISITOS NO CUMPLIDOS"

func _format_number(number: int) -> String:
	"""Formatear números grandes"""
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	if number >= 1000:
		return "%.1fK" % (number / 1000.0)
	return str(number)

func _show_error(message: String) -> void:
	"""Mostrar mensaje de error"""
	warning_details.text = "❌ ERROR: " + message
	prestige_button.disabled = true

func _on_prestige_pressed() -> void:
	"""Manejar confirmación de prestigio"""
	if not PrestigeSystem:
		return
	
	# Mostrar confirmación
	var confirm_text = "⚠️ CONFIRMACIÓN DE PRESTIGIO ⚠️\n\n"
	confirm_text += "Esto reseteará TODO tu progreso:\n"
	confirm_text += "• Todos los upgrades a nivel 0\n"
	confirm_text += "• Todas las monedas perdidas\n"
	confirm_text += "• Inventario vaciado\n"
	confirm_text += "• Vuelta a la zona inicial\n\n"
	confirm_text += "A cambio ganarás:\n"
	confirm_text += "• +%d puntos de prestigio\n" % PrestigeSystem.calculate_prestige_points()
	confirm_text += "• Multiplicador permanente mejorado\n\n"
	confirm_text += "¿Estás seguro?"
	
	# TODO: Implementar diálogo de confirmación real
	# Por ahora, realizar prestigio directamente
	if PrestigeSystem.perform_prestige():
		prestige_confirmed.emit()
		_setup_prestige_screen()  # Actualizar display

func _on_close_pressed() -> void:
	"""Cerrar pantalla de prestigio"""
	prestige_screen_closed.emit()

func _setup_bonuses() -> void:
	"""Configurar bonificaciones de prestigio"""
	# Limpiar bonificaciones existentes
	for child in bonuses_grid.get_children():
		child.queue_free()
	
	if not PrestigeSystem:
		return
	
	# Crear bonificaciones de ejemplo hasta que PrestigeSystem esté completo
	var example_bonuses = [
		{"id": "fishing_multiplier", "name": "Multiplicador de Pesca", "description": "Aumenta el valor de todos los peces", "cost": 5, "max_level": 10},
		{"id": "upgrade_discount", "name": "Descuento en Mejoras", "description": "Reduce el costo de todas las mejoras", "cost": 8, "max_level": 5},
		{"id": "zone_unlock_discount", "name": "Descuento en Zonas", "description": "Reduce el costo de desbloquear zonas", "cost": 12, "max_level": 3}
	]
	
	for bonus_data in example_bonuses:
		var card = PRESTIGE_BONUS_CARD.instantiate()
		bonus_data["current_level"] = 0
		bonus_data["can_afford"] = false  # Por ahora no se pueden comprar
		
		card.setup_bonus(bonus_data)
		card.bonus_purchased.connect(_on_bonus_purchased)
		bonuses_grid.add_child(card)

func _on_bonus_purchased(bonus_id: String) -> void:
	"""Manejar compra de bonificación"""
	print("Bonus purchase requested: %s (not implemented yet)" % bonus_id)