class_name SettingsMenu
extends BaseWindow

# Referencias a los nodos de la escena
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var vibration_checkbox: CheckBox = %VibrationCheckBox


func _setup_content() -> void:
	# Conectar las señales de los controles a sus funciones
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	vibration_checkbox.toggled.connect(_on_vibration_toggled)

	# Cargar los valores guardados y aplicarlos a la UI
	load_settings()


func load_settings() -> void:
	# Cargar valores desde el archivo de guardado o usar valores por defecto
	master_slider.value = Save.game_data.get("master_volume", 0.8)
	music_slider.value = Save.game_data.get("music_volume", 0.7)
	sfx_slider.value = Save.game_data.get("sfx_volume", 0.9)
	vibration_checkbox.button_pressed = Save.game_data.get("vibration_enabled", true)


func _on_master_volume_changed(value: float) -> void:
	Save.game_data["master_volume"] = value
	# Aquí se podría llamar a un AudioBusManager para cambiar el volumen en tiempo real
	print("Master Volume set to: ", value)


func _on_music_volume_changed(value: float) -> void:
	Save.game_data["music_volume"] = value
	print("Music Volume set to: ", value)


func _on_sfx_volume_changed(value: float) -> void:
	Save.game_data["sfx_volume"] = value
	if SFX:
		SFX.set_sfx_volume(value)
		SFX.play_event("click") # Reproducir un sonido para probar el nuevo volumen
	print("SFX Volume set to: ", value)


func _on_vibration_toggled(is_pressed: bool) -> void:
	Save.game_data["vibration_enabled"] = is_pressed
	print("Vibration set to: ", is_pressed)

func _notification(what: int) -> void:
	# Guardar los cambios cuando la ventana se cierra
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if Save:
			Save.save_game()
			print("Settings saved.")
