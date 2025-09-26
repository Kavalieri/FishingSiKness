class_name PrestigeBonusCard
extends PanelContainer

# Tarjeta para bonificaciones de prestigio

signal bonus_purchased(bonus_id: String)

var bonus_data: Dictionary = {}

@onready var title_label: Label = $VBox/Title
@onready var description_label: Label = $VBox/Description
@onready var cost_label: Label = $VBox/CostContainer/CostLabel
@onready var level_label: Label = $VBox/CostContainer/LevelLabel
@onready var buy_button: Button = $VBox/BuyButton

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)

func setup_bonus(data: Dictionary) -> void:
	"""Configurar tarjeta con datos de bonificación"""
	bonus_data = data
	
	title_label.text = data.get("name", "")
	description_label.text = data.get("description", "")
	
	var current_level = data.get("current_level", 0)
	var max_level = data.get("max_level", 1)
	var cost = data.get("cost", 0)
	var can_afford = data.get("can_afford", false)
	
	level_label.text = "Nivel %d/%d" % [current_level, max_level]
	cost_label.text = "%d ✨" % cost
	
	if current_level >= max_level:
		buy_button.text = "MÁXIMO"
		buy_button.disabled = true
		buy_button.modulate = Color.GREEN * 0.8
	elif can_afford:
		buy_button.text = "COMPRAR"
		buy_button.disabled = false
		buy_button.modulate = Color.WHITE
	else:
		buy_button.text = "SIN PUNTOS"
		buy_button.disabled = true
		buy_button.modulate = Color.GRAY

func _on_buy_pressed() -> void:
	bonus_purchased.emit(bonus_data.get("id", ""))