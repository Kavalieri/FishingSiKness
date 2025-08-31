extends Control
class_name OptionsWindow
## Ventana de opciones completa
##
## Permite configurar audio, gameplay y otras opciones del juego
## Usa la arquitectura UI-BG-GLOBAL con estilos translúcidos

signal window_closed()
signal settings_changed(setting_name: String, value)

# Referencias a controles UI
@onready var overlay: ColorRect = $Overlay
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer

# Audio controls
@onready var master_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OptionsContainer/AudioSection/MasterVolumeContainer/MasterSlider
@onready var master_value: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OptionsContainer/AudioSection/MasterVolumeContainer/MasterValue
@onready var music_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OptionsContainer/AudioSection/MusicVolumeContainer/MusicSlider
@onready var music_value: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OptionsContainer/AudioSection/MusicVolumeContainer/MusicValue
@onready var sfx_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OptionsContainer/AudioSection/SFXVolumeContainer/SFXSlider
@onready var sfx_value: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OptionsContainer/AudioSection/SFXVolumeContainer/SFXValue

# Gameplay controls
@onready var auto_save_check: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OptionsContainer/GameplaySection/AutoSaveContainer/AutoSaveCheck
@onready var notifications_check: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OptionsContainer/GameplaySection/NotificationsContainer/NotificationsCheck

# Buttons
@onready var reset_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/ResetButton
@onready var accept_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/AcceptButton
@onready var cancel_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/CancelButton

# Estado original para cancelar cambios
var original_settings: Dictionary = {}

func _ready() -> void:
	print("[OptionsWindow] Inicializando ventana de opciones...")

	# Configurar estilo translúcido
	_setup_translucent_style()

	# Cargar configuración actual
	_load_current_settings()

	# Conectar señales
	_connect_signals()

	# Configurar tooltips
	_setup_tooltips()

	# Animar entrada
	_animate_show()

	print("[OptionsWindow] ✓ Ventana de opciones lista")

func _setup_translucent_style() -> void:
	"""Configurar estilo translúcido"""
	# Configurar overlay para recibir input
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.15, 0.9) # Más opaco que el menú de pausa
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.4, 0.4, 0.4, 0.7)

	panel_container.add_theme_stylebox_override("panel", style_box)

func _load_current_settings() -> void:
	"""Cargar configuración actual del juego"""
	# Cargar desde Save o configuración global
	if Save and Save.game_data.has("settings"):
		var settings = Save.game_data.settings

		# Audio settings
		master_slider.value = settings.get("master_volume", 100)
		music_slider.value = settings.get("music_volume", 80)
		sfx_slider.value = settings.get("sfx_volume", 100)

		# Gameplay settings
		auto_save_check.button_pressed = settings.get("auto_save", true)
		notifications_check.button_pressed = settings.get("notifications", true)
	else:
		# Valores por defecto
		master_slider.value = 100
		music_slider.value = 80
		sfx_slider.value = 100
		auto_save_check.button_pressed = true
		notifications_check.button_pressed = true

	# Guardar estado original
	_save_original_settings()

	# Actualizar labels de volumen
	_update_volume_labels()

func _save_original_settings() -> void:
	"""Guardar configuración original para poder cancelar"""
	original_settings = {
		"master_volume": master_slider.value,
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value,
		"auto_save": auto_save_check.button_pressed,
		"notifications": notifications_check.button_pressed
	}

func _connect_signals() -> void:
	"""Conectar señales de controles"""
	# Sliders de volumen
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	# Checkboxes
	auto_save_check.toggled.connect(_on_auto_save_toggled)
	notifications_check.toggled.connect(_on_notifications_toggled)

	# Botones
	reset_button.pressed.connect(_on_reset_pressed)
	accept_button.pressed.connect(_on_accept_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	# Cerrar con overlay
	overlay.gui_input.connect(_on_overlay_input)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.z_index = 0
	panel_container.z_index = 1

	# CRÍTICO: Hacer que el CenterContainer no bloquee el input del overlay
	var center_container = $CenterContainer
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_tooltips() -> void:
	"""Configurar tooltips"""
	master_slider.tooltip_text = "Controla el volumen general del juego"
	music_slider.tooltip_text = "Volumen de la música de fondo"
	sfx_slider.tooltip_text = "Volumen de efectos de sonido"
	auto_save_check.tooltip_text = "Guardar automáticamente el progreso"
	notifications_check.tooltip_text = "Mostrar notificaciones del juego"
	reset_button.tooltip_text = "Restablecer a configuración por defecto"
	accept_button.tooltip_text = "Guardar cambios y cerrar"
	cancel_button.tooltip_text = "Descartar cambios y cerrar"

func _animate_show() -> void:
	"""Animar entrada de la ventana"""
	modulate.a = 0.0
	panel_container.scale = Vector2(0.9, 0.9)

	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.25)

	var scale_tween = create_tween()
	scale_tween.tween_property(panel_container, "scale", Vector2(1.0, 1.0), 0.25)

func close_animated() -> void:
	"""Cerrar ventana con animación (API pública)"""
	_animate_close()

func _animate_close() -> void:
	"""Animar cierre de la ventana"""
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)

	var scale_tween = create_tween()
	scale_tween.tween_property(panel_container, "scale", Vector2(0.9, 0.9), 0.2)

	fade_tween.tween_callback(func():
		window_closed.emit()
		queue_free()
	)

func _update_volume_labels() -> void:
	"""Actualizar labels de porcentaje de volumen"""
	master_value.text = "%d%%" % int(master_slider.value)
	music_value.text = "%d%%" % int(music_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)

# Handlers de sliders de audio
func _on_master_volume_changed(value: float) -> void:
	master_value.text = "%d%%" % int(value)
	_apply_audio_setting("master_volume", value)

func _on_music_volume_changed(value: float) -> void:
	music_value.text = "%d%%" % int(value)
	_apply_audio_setting("music_volume", value)

func _on_sfx_volume_changed(value: float) -> void:
	sfx_value.text = "%d%%" % int(value)
	_apply_audio_setting("sfx_volume", value)

func _apply_audio_setting(setting: String, value: float) -> void:
	"""Aplicar configuración de audio inmediatamente"""
	var db_value = linear_to_db(value / 100.0)

	match setting:
		"master_volume":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_value)
		"music_volume":
			var music_bus = AudioServer.get_bus_index("Music")
			if music_bus != -1:
				AudioServer.set_bus_volume_db(music_bus, db_value)
		"sfx_volume":
			var sfx_bus = AudioServer.get_bus_index("SFX")
			if sfx_bus != -1:
				AudioServer.set_bus_volume_db(sfx_bus, db_value)

	settings_changed.emit(setting, value)

# Handlers de gameplay settings
func _on_auto_save_toggled(pressed: bool) -> void:
	settings_changed.emit("auto_save", pressed)

func _on_notifications_toggled(pressed: bool) -> void:
	settings_changed.emit("notifications", pressed)

# Handlers de botones
func _on_reset_pressed() -> void:
	"""Restablecer a valores por defecto"""
	print("[OptionsWindow] Restableciendo configuración por defecto...")

	master_slider.value = 100
	music_slider.value = 80
	sfx_slider.value = 100
	auto_save_check.button_pressed = true
	notifications_check.button_pressed = true

func _on_accept_pressed() -> void:
	"""Guardar cambios y cerrar"""
	print("[OptionsWindow] Guardando configuración...")
	_save_settings()
	_animate_close()

func _on_cancel_pressed() -> void:
	"""Cancelar cambios y cerrar"""
	print("[OptionsWindow] Cancelando cambios...")
	_restore_original_settings()
	_animate_close()

func _save_settings() -> void:
	"""Guardar configuración en Save"""
	if not Save:
		return

	if not Save.game_data.has("settings"):
		Save.game_data.settings = {}

	var settings = Save.game_data.settings
	settings.master_volume = master_slider.value
	settings.music_volume = music_slider.value
	settings.sfx_volume = sfx_slider.value
	settings.auto_save = auto_save_check.button_pressed
	settings.notifications = notifications_check.button_pressed

	Save.save_game()
	print("[OptionsWindow] ✓ Configuración guardada")

func _restore_original_settings() -> void:
	"""Restaurar configuración original"""
	master_slider.value = original_settings.master_volume
	music_slider.value = original_settings.music_volume
	sfx_slider.value = original_settings.sfx_volume
	auto_save_check.button_pressed = original_settings.auto_save
	notifications_check.button_pressed = original_settings.notifications

func _on_overlay_input(event: InputEvent) -> void:
	"""Cerrar al hacer clic en overlay"""
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_cancel_pressed()

func _unhandled_input(event: InputEvent) -> void:
	"""Cerrar con ESC"""
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
