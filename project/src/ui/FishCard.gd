class_name FishCard
extends Control

signal selection_changed(fish_card: Control, is_selected: bool)
signal details_requested(fish_card: Control)

# Datos del pescado
var fish_data: FishDef
var fish_count: int = 1
var is_selected: bool = false
var individual_fish_data: Dictionary = {} # Datos específicos de captura

# Referencias a los nodos de la tarjeta
@onready var fish_sprite: TextureRect = $MainContainer/FishSprite
@onready var fish_name_label: Label = $MainContainer/InfoContainer/FishName
@onready var fish_price_label: Label = $MainContainer/InfoContainer/FishCount # Cambiar para precio
@onready var select_checkbox: CheckBox = $MainContainer/SelectCheckBox

func _ready():
	if select_checkbox:
		select_checkbox.toggled.connect(_on_checkbox_toggled)

	# Hacer que la tarjeta sea clickeable para mostrar detalles
	gui_input.connect(_on_card_clicked)

func _on_card_clicked(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Solo emitir si el clic no fue en el checkbox
			var checkbox_rect = select_checkbox.get_global_rect()
			if not checkbox_rect.has_point(event.global_position):
				details_requested.emit(self)

func setup_card(fish: FishDef, count: int = 1):
	fish_data = fish
	fish_count = count
	_update_display()

func setup_individual_card(fish_def: FishDef, capture_data: Dictionary, index: int):
	"""Configurar tarjeta para un pescado individual con datos de captura únicos"""
	fish_data = fish_def
	individual_fish_data = capture_data
	_update_individual_display()

func get_fish_details() -> String:
	"""Obtener detalles completos del pescado para mostrar en popup"""
	if individual_fish_data.is_empty():
		return "Sin datos de captura disponibles"

	var details = ""
	details += "🐟 %s\n\n" % fish_data.name
	details += "💰 Precio: %dc\n" % individual_fish_data.get("value", 0)
	details += "📏 Tamaño: %.1fcm\n" % individual_fish_data.get("size", 0.0)
	details += "📍 Zona: %s\n" % individual_fish_data.get("capture_zone_id", "Desconocida")
	details += "⏰ Capturado: %s\n" % individual_fish_data.get("capture_timestamp", "Desconocido")
	if individual_fish_data.has("zone_multiplier"):
		details += "✨ Bonus zona: x%.1f\n" % individual_fish_data.get("zone_multiplier", 1.0)
	details += "\n📋 %s" % fish_data.description

	return details

func _update_individual_display():
	"""Actualizar display con información específica del pescado capturado"""
	if not fish_data:
		return

	# Actualizar nombre del pescado
	if fish_name_label:
		fish_name_label.text = fish_data.name

	# Mostrar precio en lugar de contador
	if fish_price_label:
		var price = individual_fish_data.get("value", 0)
		fish_price_label.text = "%dc" % price

	# Cargar sprite del pescado
	if fish_sprite and fish_data.sprite:
		fish_sprite.texture = fish_data.sprite

func _update_display():
	if not fish_data:
		return

	# Actualizar nombre del pescado
	if fish_name_label:
		fish_name_label.text = fish_data.name

	# Actualizar contador (para compatibilidad con función antigua)
	if fish_price_label:
		fish_price_label.text = "x%d" % fish_count

	# Cargar sprite del pescado
	if fish_sprite and fish_data.sprite:
		fish_sprite.texture = fish_data.sprite

func _on_checkbox_toggled(button_pressed: bool):
	is_selected = button_pressed
	selection_changed.emit(self, is_selected)
	_update_selection_visual()

func _update_selection_visual():
	# Cambiar el color de fondo según selección
	var card_background = $CardBackground
	if card_background:
		if is_selected:
			card_background.color = Color(0.3, 0.4, 0.3, 1) # Verde oscuro cuando está seleccionado
		else:
			card_background.color = Color(0.2, 0.2, 0.2, 1) # Color normal

func set_selected(selected: bool):
	is_selected = selected
	if select_checkbox:
		select_checkbox.button_pressed = selected
	_update_selection_visual()

func get_fish_resource() -> FishDef:
	return fish_data

func get_count() -> int:
	return fish_count

func set_count(new_count: int):
	fish_count = new_count
	if fish_price_label:
		fish_price_label.text = "x%d" % fish_count
