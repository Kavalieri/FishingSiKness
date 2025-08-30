extends Control

signal fish_kept(fish_data: Dictionary)
signal fish_sold(fish_data: Dictionary, value: int)
signal fish_released(fish_data: Dictionary)
signal window_closed

@onready var fish_name_label: Label = $CenterContainer/CapturePanel/VBoxContainer/FishInfo/FishName
@onready var fish_sprite: TextureRect = $CenterContainer/CapturePanel/VBoxContainer/FishInfo/FishSprite
@onready var weight_label: Label = $CenterContainer/CapturePanel/VBoxContainer/FishInfo/FishStats/WeightLabel
@onready var value_label: Label = $CenterContainer/CapturePanel/VBoxContainer/FishInfo/FishStats/ValueLabel
@onready var keep_button: Button = $CenterContainer/CapturePanel/VBoxContainer/ButtonsContainer/KeepButton
@onready var sell_button: Button = $CenterContainer/CapturePanel/VBoxContainer/ButtonsContainer/SellButton
@onready var release_button: Button = $CenterContainer/CapturePanel/VBoxContainer/ButtonsContainer/ReleaseButton
@onready var close_button: Button = $CenterContainer/CapturePanel/VBoxContainer/CloseButton

var current_fish_data: Dictionary = {}

func _ready() -> void:
	keep_button.connect("pressed", Callable(self, "_on_keep_pressed"))
	sell_button.connect("pressed", Callable(self, "_on_sell_pressed"))
	release_button.connect("pressed", Callable(self, "_on_release_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_pressed"))

func show_capture(fish_data: Dictionary) -> void:
	current_fish_data = fish_data

	# Actualizar información del pez
	fish_name_label.text = fish_data.get("name", "Pez Desconocido")

	# Cargar sprite del pez
	var fish_texture_path = fish_data.get("sprite_path", "")
	if fish_texture_path and ResourceLoader.exists(fish_texture_path):
		fish_sprite.texture = load(fish_texture_path)
	else:
		fish_sprite.texture = null

	# Mostrar estadísticas
	var weight = fish_data.get("weight", 0.0)
	var value = fish_data.get("value", 0)

	weight_label.text = "Peso: %.1f kg" % weight
	value_label.text = "Valor: %d monedas" % value

	# Mostrar la ventana
	visible = true

func _on_keep_pressed() -> void:
	fish_kept.emit(current_fish_data)
	_close_window()

func _on_sell_pressed() -> void:
	var value = current_fish_data.get("value", 0)
	fish_sold.emit(current_fish_data, value)
	_close_window()

func _on_release_pressed() -> void:
	fish_released.emit(current_fish_data)
	_close_window()

func _on_close_pressed() -> void:
	window_closed.emit()
	_close_window()

func _close_window() -> void:
	visible = false
	current_fish_data = {}
