class_name OptionsWindow
extends Control

# Ventana de opciones según especificación

signal options_saved
signal window_closed

@onready var close_button: Button = $CenterContainer/OptionsPanel/VBoxContainer/Header/CloseButton
@onready var master_volume_slider: HSlider = $CenterContainer/OptionsPanel/VBoxContainer / \
	Content / OptionsVBox / AudioGroup / MasterVolumeContainer / MasterVolumeSlider
@onready var master_volume_value: Label = $CenterContainer/OptionsPanel/VBoxContainer / \
	Content / OptionsVBox / AudioGroup / MasterVolumeContainer / MasterVolumeValue
@onready var sfx_volume_slider: HSlider = $CenterContainer/OptionsPanel/VBoxContainer / \
	Content / OptionsVBox / AudioGroup / SFXVolumeContainer / SFXVolumeSlider
@onready var sfx_volume_value: Label = $CenterContainer/OptionsPanel/VBoxContainer / \
	Content / OptionsVBox / AudioGroup / SFXVolumeContainer / SFXVolumeValue
@onready var music_volume_slider: HSlider = $CenterContainer/OptionsPanel/VBoxContainer / \
	Content / OptionsVBox / AudioGroup / MusicVolumeContainer / MusicVolumeSlider
@onready var music_volume_value: Label = $CenterContainer/OptionsPanel/VBoxContainer / \
	Content / OptionsVBox / AudioGroup / MusicVolumeContainer / MusicVolumeValue
@onready var vibration_checkbox: CheckBox = $CenterContainer/OptionsPanel/VBoxContainer / \
	Content / OptionsVBox / GameplayGroup / VibrationContainer / VibrationCheckBox
@onready var autosave_checkbox: CheckBox = $CenterContainer/OptionsPanel/VBoxContainer / \
	Content / OptionsVBox / GameplayGroup / AutoSaveContainer / AutoSaveCheckBox
@onready var reset_button: Button = $CenterContainer/OptionsPanel/VBoxContainer/Footer/ResetButton
@onready var save_button: Button = $CenterContainer/OptionsPanel/VBoxContainer/Footer/SaveButton
@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	_connect_signals()
	_load_current_settings()
	_setup_initial_state()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	save_button.pressed.connect(_on_save_pressed)
	overlay.gui_input.connect(_on_overlay_input)

	# Conectar sliders para actualizar valores
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)

func _setup_initial_state() -> void:
	modulate.a = 0.0
	show_animated()

func show_animated() -> void:
	"""Mostrar ventana con animación"""
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

func hide_animated() -> void:
	"""Ocultar ventana con animación"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _load_current_settings() -> void:
	"""Cargar configuraciones actuales desde Save"""
	# TODO: Integrar con sistema Save cuando esté disponible
	_update_volume_labels()

func _save_settings() -> void:
	"""Guardar configuraciones actuales"""
	var settings = {
		"master_volume": master_volume_slider.value,
		"sfx_volume": sfx_volume_slider.value,
		"music_volume": music_volume_slider.value,
		"vibration": vibration_checkbox.button_pressed,
		"autosave": autosave_checkbox.button_pressed
	}
	# TODO: Integrar con sistema Save cuando esté disponible
	print("Configuraciones guardadas: ", settings)

func _reset_to_defaults() -> void:
	"""Resetear a valores por defecto"""
	master_volume_slider.value = 80.0
	sfx_volume_slider.value = 80.0
	music_volume_slider.value = 80.0
	vibration_checkbox.button_pressed = true
	autosave_checkbox.button_pressed = true

	_update_volume_labels()

func _update_volume_labels() -> void:
	"""Actualizar etiquetas de volumen"""
	master_volume_value.text = "%d%%" % master_volume_slider.value
	sfx_volume_value.text = "%d%%" % sfx_volume_slider.value
	music_volume_value.text = "%d%%" % music_volume_slider.value

func _on_close_pressed() -> void:
	window_closed.emit()
	hide_animated()

func _on_save_pressed() -> void:
	_save_settings()
	options_saved.emit()
	hide_animated()

func _on_reset_pressed() -> void:
	_reset_to_defaults()

func _on_master_volume_changed(value: float) -> void:
	master_volume_value.text = "%d%%" % value

func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume_value.text = "%d%%" % value

func _on_music_volume_changed(value: float) -> void:
	music_volume_value.text = "%d%%" % value

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_close_pressed()
