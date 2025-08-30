class_name FishCard
extends Control

signal selection_changed(fish_card: Control, is_selected: bool)
signal details_requested(fish_card: Control)

# --- Variables ---
var fish_data: FishDef
var is_selected: bool = false
var individual_fish_data: Dictionary = {}

# --- Referencias a Nodos ---
@onready var fish_sprite: TextureRect = $MainContainer/FishSprite
@onready var fish_name_label: Label = $MainContainer/InfoContainer/FishName
@onready var fish_price_label: Label = %FishPrice
@onready var select_checkbox: CheckBox = %SelectCheckBox
@onready var selection_overlay: ColorRect = %SelectionOverlay

func _ready():
	select_checkbox.toggled.connect(_on_checkbox_toggled)
	gui_input.connect(_on_card_clicked)

func _on_card_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Permitir "hacer clic a través" del overlay de selección
		var checkbox_rect = select_checkbox.get_global_rect()
		if not checkbox_rect.has_point(event.global_position):
			details_requested.emit(self)

func setup_individual_card(fish_def: FishDef, capture_data: Dictionary, index: int):
	fish_data = fish_def
	individual_fish_data = capture_data
	_update_individual_display()

func get_fish_details() -> String:
	var details = ""
	details += "FISH %s\n\n" % fish_data.name
	details += "COINS Precio: %dc\n" % individual_fish_data.get("value", 0)
	details += "SIZE Tamaño: %.1fcm\n" % individual_fish_data.get("size", 0.0)
	details += "WEIGHT Peso: %.2fkg\n" % individual_fish_data.get("weight", 0.0)
	details += "PIN Zona: %s\n" % individual_fish_data.get("capture_zone_id", "Desconocida").capitalize()
	return details

func _update_individual_display():
	if not fish_data: return

	fish_name_label.text = fish_data.name
	fish_price_label.text = "%d c" % individual_fish_data.get("value", 0)
	if fish_sprite and fish_data.sprite:
		fish_sprite.texture = fish_data.sprite

func _on_checkbox_toggled(button_pressed: bool):
	is_selected = button_pressed
	selection_changed.emit(self, is_selected)
	_update_selection_visual()

func _update_selection_visual():
	# Mostrar u ocultar la capa de selección
	selection_overlay.visible = is_selected

func set_selected(selected: bool):
	# Prevenir bucles de señales
	if is_selected == selected: return

	is_selected = selected
	select_checkbox.button_pressed = selected
	_update_selection_visual()
