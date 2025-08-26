class_name SettingsMenu
extends BaseFloatingMenu

signal resume_requested()
signal save_manager_requested()
signal settings_closed()

var main_panel: PanelContainer

func setup_menu():
	"""Configurar interfaz del menú de configuración"""
	name = "SettingsMenu"

	setup_ui()

func setup_ui():
	# Panel principal
	main_panel = PanelContainer.new()
	main_panel.anchor_left = 0.2
	main_panel.anchor_right = 0.8
	main_panel.anchor_top = 0.15
	main_panel.anchor_bottom = 0.85
	add_child(main_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(main_vbox)

	# Título con botón cerrar
	var title_hbox = HBoxContainer.new()
	main_vbox.add_child(title_hbox)

	var title = Label.new()
	title.text = "⚙️ OPCIONES"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_hbox.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "❌"
	close_btn.custom_minimum_size = Vector2(48, 48)
	close_btn.pressed.connect(_on_close_pressed)
	title_hbox.add_child(close_btn)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 10
	main_vbox.add_child(separator)

	# Secciones de opciones
	create_audio_section(main_vbox)
	create_gameplay_section(main_vbox)
	create_data_section(main_vbox)

	# Espaciador
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(spacer)

	# Información del juego
	create_info_section(main_vbox)

func create_audio_section(parent: VBoxContainer):
	var section_title = Label.new()
	section_title.text = "🔊 AUDIO"
	section_title.add_theme_font_size_override("font_size", 20)
	parent.add_child(section_title)

	var audio_container = VBoxContainer.new()
	audio_container.add_theme_constant_override("separation", 10)
	parent.add_child(audio_container)

	# Volumen general
	create_volume_control(audio_container, "Volumen General", "master_volume", 0.8)

	# Volumen música
	create_volume_control(audio_container, "Música", "music_volume", 0.7)

	# Volumen efectos
	create_volume_control(audio_container, "Efectos de Sonido", "sfx_volume", 0.9)

	# Vibración
	var vibration_hbox = HBoxContainer.new()
	audio_container.add_child(vibration_hbox)

	var vibration_label = Label.new()
	vibration_label.text = "Vibración:"
	vibration_label.custom_minimum_size.x = 150
	vibration_hbox.add_child(vibration_label)

	var vibration_check = CheckBox.new()
	vibration_check.button_pressed = Save.game_data.get("vibration_enabled", true)
	vibration_check.toggled.connect(_on_vibration_toggled)
	vibration_hbox.add_child(vibration_check)

func create_volume_control(
	parent: VBoxContainer,
	label_text: String,
	setting_key: String,
	default_value: float
):
	var volume_hbox = HBoxContainer.new()
	parent.add_child(volume_hbox)

	var volume_label = Label.new()
	volume_label.text = label_text + ":"
	volume_label.custom_minimum_size.x = 150
	volume_hbox.add_child(volume_label)

	var volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.1
	volume_slider.value = Save.game_data.get(setting_key, default_value)
	volume_slider.custom_minimum_size.x = 200
	volume_slider.value_changed.connect(_on_volume_changed.bind(setting_key))
	volume_hbox.add_child(volume_slider)

	var volume_value = Label.new()
	volume_value.text = str(int(volume_slider.value * 100)) + "%"
	volume_value.custom_minimum_size.x = 50
	volume_hbox.add_child(volume_value)

	# Conectar para actualizar el label
	volume_slider.value_changed.connect(_on_volume_label_update.bind(volume_value))

func create_gameplay_section(parent: VBoxContainer):
	var section_title = Label.new()
	section_title.text = "🎮 GAMEPLAY"
	section_title.add_theme_font_size_override("font_size", 20)
	parent.add_child(section_title)

	var gameplay_container = VBoxContainer.new()
	gameplay_container.add_theme_constant_override("separation", 10)
	parent.add_child(gameplay_container)

	# Modo zurdo
	var lefty_hbox = HBoxContainer.new()
	gameplay_container.add_child(lefty_hbox)

	var lefty_label = Label.new()
	lefty_label.text = "Modo Zurdo:"
	lefty_label.custom_minimum_size.x = 150
	lefty_hbox.add_child(lefty_label)

	var lefty_check = CheckBox.new()
	lefty_check.button_pressed = Save.game_data.get("left_handed", false)
	lefty_check.toggled.connect(_on_lefty_toggled)
	lefty_hbox.add_child(lefty_check)

	# Animaciones reducidas
	var reduced_anim_hbox = HBoxContainer.new()
	gameplay_container.add_child(reduced_anim_hbox)

	var reduced_anim_label = Label.new()
	reduced_anim_label.text = "Animaciones Reducidas:"
	reduced_anim_label.custom_minimum_size.x = 150
	reduced_anim_hbox.add_child(reduced_anim_label)

	var reduced_anim_check = CheckBox.new()
	reduced_anim_check.button_pressed = Save.game_data.get("reduced_animations", false)
	reduced_anim_check.toggled.connect(_on_reduced_animations_toggled)
	reduced_anim_hbox.add_child(reduced_anim_check)

func create_data_section(parent: VBoxContainer):
	var section_title = Label.new()
	section_title.text = "💾 DATOS DE JUEGO"
	section_title.add_theme_font_size_override("font_size", 20)
	parent.add_child(section_title)

	var data_container = VBoxContainer.new()
	data_container.add_theme_constant_override("separation", 10)
	parent.add_child(data_container)

	# Botón de gestor de guardado
	var save_manager_btn = Button.new()
	save_manager_btn.text = "💾 Gestor de Partidas"
	save_manager_btn.custom_minimum_size.y = 50
	save_manager_btn.pressed.connect(_on_save_manager_pressed)
	data_container.add_child(save_manager_btn)

	# Información de guardado actual
	var save_info_label = Label.new()
	var slot = Save.current_save_slot
	var last_saved = Time.get_datetime_string_from_system()
	save_info_label.text = "Slot actual: %d | Guardado: %s" % [slot, last_saved]
	save_info_label.add_theme_font_size_override("font_size", 12)
	save_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	data_container.add_child(save_info_label)

func create_info_section(parent: VBoxContainer):
	var info_container = VBoxContainer.new()
	info_container.add_theme_constant_override("separation", 8)
	parent.add_child(info_container)

	# Información del juego
	var game_info = Label.new()
	game_info.text = "Fishing SiKness v0.1.0"
	game_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_info.add_theme_font_size_override("font_size", 16)
	info_container.add_child(game_info)

	var stats_info = Label.new()
	stats_info.text = "🪙 %d monedas | 💎 %d gemas | 📈 Nivel %d" % [
		Save.get_coins(), Save.get_gems(), Save.game_data.get("level", 1)
	]
	stats_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_info.add_theme_font_size_override("font_size", 14)
	stats_info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	info_container.add_child(stats_info)

# Callbacks de eventos
func _on_volume_changed(setting_key: String, value: float):
	Save.game_data[setting_key] = value
	Save.save_game()

	# Aplicar cambios de audio inmediatamente si es necesario
	if SFX and setting_key == "sfx_volume":
		SFX.set_master_volume(value)

	if SFX:
		SFX.play_event("click")

func _on_volume_label_update(volume_label: Label, value: float):
	volume_label.text = str(int(value * 100)) + "%"

func _on_vibration_toggled(pressed: bool):
	Save.game_data.vibration_enabled = pressed
	Save.save_game()
	if SFX:
		SFX.play_event("click")

func _on_lefty_toggled(pressed: bool):
	Save.game_data.left_handed = pressed
	Save.save_game()
	if SFX:
		SFX.play_event("click")
	# Aquí se podría notificar a los BottomTabs para reordenar

func _on_reduced_animations_toggled(pressed: bool):
	Save.game_data.reduced_animations = pressed
	Save.save_game()
	if SFX:
		SFX.play_event("click")

func _on_save_manager_pressed():
	emit_signal("save_manager_requested")
	if SFX:
		SFX.play_event("click")

func _on_close_pressed():
	emit_signal("settings_closed")
	if SFX:
		SFX.play_event("click")
	queue_free()

func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("settings_closed")
		queue_free()

func _input(event):
	# Permitir cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		emit_signal("settings_closed")
		queue_free()
