class_name UnifiedMenu
extends ColorRect

# Señales para comunicación con el sistema principal
signal resume_requested()
signal save_and_exit_requested()
signal save_manager_requested()
signal menu_closed()

# Referencias a UI (se conectan automáticamente desde la escena)
@onready var resume_button: Button = $MenuContainer/ResumeButton
@onready var save_button: Button = $MenuContainer/SaveButton
@onready var save_and_exit_button: Button = $MenuContainer/SaveAndExitButton
@onready var close_button: Button = $MenuContainer/CloseButton

func _ready():
	# Conectar señales de los botones de la escena
	if resume_button:
		resume_button.pressed.connect(_on_pause_button_pressed.bind("resume"))
	if save_button:
		save_button.pressed.connect(_on_save_manager_pressed)
	if save_and_exit_button:
		save_and_exit_button.pressed.connect(_on_pause_button_pressed.bind("save_exit"))
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

# Callbacks básicos
func _on_pause_button_pressed(action: String):
	"""Manejar botones del menú"""
	if SFX:
		SFX.play_event("click")

	match action:
		"resume":
			resume_requested.emit()
			queue_free()
		"save_exit":
			save_and_exit_requested.emit()
			queue_free()

func _on_save_manager_pressed():
	"""Abrir gestor de guardado"""
	save_manager_requested.emit()
	if SFX:
		SFX.play_event("click")
	queue_free()

func _on_close_pressed():
	"""Cerrar menú"""
	if SFX:
		SFX.play_event("click")
	menu_closed.emit()
	queue_free()

func _input(event):
	"""Cerrar con ESC"""
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
	"""Configurar interfaz del menú unificado"""
	# MÉTODO ULTRA SIMPLE: ColorRect NEGRO DIRECTO
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 9999 # Z_INDEX MÁXIMO
	color = Color.BLACK # NEGRO DIRECTO
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Conectar evento de clic directamente
	gui_input.connect(_on_background_clicked)

	# Panel principal centrado
	main_panel = PanelContainer.new()
	add_child(main_panel)

	# Centrar panel dinámicamente
	call_deferred("_center_panel", main_panel)
	call_deferred("_setup_panel_content", main_panel)

func _center_panel(panel: PanelContainer):
	"""Centrar panel dinámicamente en pantalla"""
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = Vector2(
		viewport_size.x * (0.6 if menu_type == MenuType.SPLASH_OPTIONS else 0.5),
		viewport_size.y * 0.7
	)

	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.position = (viewport_size - panel_size) / 2
	panel.modulate = Color(1, 1, 1, 1.0) # 100% opaco
	panel.show()

func _setup_panel_content(panel: PanelContainer):
	"""Configurar contenido según tipo de menú"""
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	panel.add_child(main_vbox)

	# Título según contexto
	var title_hbox = HBoxContainer.new()
	main_vbox.add_child(title_hbox)

	var title = Label.new()
	title.text = "⚙️ OPCIONES" if menu_type == MenuType.SPLASH_OPTIONS else "⏸️ MENÚ"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_hbox.add_child(title)

	# Botón cerrar
	var close_btn = Button.new()
	close_btn.text = "❌"
	close_btn.custom_minimum_size = Vector2(48, 48)
	close_btn.pressed.connect(_on_close_pressed)
	title_hbox.add_child(close_btn)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 10
	main_vbox.add_child(separator)

	# Contenido dinámico según tipo
	if menu_type == MenuType.PAUSE:
		create_pause_menu_content(main_vbox)
	else:
		create_options_menu_content(main_vbox)

func create_pause_menu_content(parent: VBoxContainer):
	"""Crear contenido del menú de pausa"""
	# Botones principales (sin gestión de partidas - está en configuraciones)
	var buttons_data = [
		{"text": "▶️ CONTINUAR", "action": "resume"},
		{"text": "⚙️ CONFIGURACIONES", "action": "settings"},
		{"text": "💾 GUARDAR Y SALIR", "action": "save_exit"}
	]

	for button_data in buttons_data:
		var button = Button.new()
		button.text = button_data.text
		button.custom_minimum_size.y = 50
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_on_pause_button_pressed.bind(button_data.action))
		parent.add_child(button)

	# Espaciador
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

	# Información del juego
	create_game_info_section(parent)

func create_options_menu_content(parent: VBoxContainer):
	"""Crear contenido del menú de opciones completo"""
	# Scroll container para opciones
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(scroll_vbox)

	# Secciones de opciones
	create_audio_section(scroll_vbox)
	create_gameplay_section(scroll_vbox)
	create_data_section(scroll_vbox)
	create_game_info_section(scroll_vbox)

func create_audio_section(parent: VBoxContainer):
	"""Crear sección de audio"""
	var section_title = Label.new()
	section_title.text = "🔊 AUDIO"
	section_title.add_theme_font_size_override("font_size", 20)
	parent.add_child(section_title)

	var audio_container = VBoxContainer.new()
	audio_container.add_theme_constant_override("separation", 10)
	parent.add_child(audio_container)

	# Controles de volumen
	create_volume_control(audio_container, "Volumen General", "master_volume", 0.8)
	create_volume_control(audio_container, "Música", "music_volume", 0.7)
	create_volume_control(audio_container, "Efectos", "sfx_volume", 0.9)

	# Vibración
	var vibration_hbox = HBoxContainer.new()
	audio_container.add_child(vibration_hbox)

	var vibration_label = Label.new()
	vibration_label.text = "Vibración:"
	vibration_label.custom_minimum_size.x = 120
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
	"""Crear control deslizante de volumen"""
	var volume_hbox = HBoxContainer.new()
	parent.add_child(volume_hbox)

	var volume_label = Label.new()
	volume_label.text = label_text + ":"
	volume_label.custom_minimum_size.x = 120
	volume_hbox.add_child(volume_label)

	var volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.1
	volume_slider.value = Save.game_data.get(setting_key, default_value)
	volume_slider.custom_minimum_size.x = 150
	volume_slider.value_changed.connect(_on_volume_changed.bind(setting_key))
	volume_hbox.add_child(volume_slider)

	var volume_value = Label.new()
	volume_value.text = str(int(volume_slider.value * 100)) + "%"
	volume_value.custom_minimum_size.x = 50
	volume_hbox.add_child(volume_value)

	# Conectar para actualizar el label
	volume_slider.value_changed.connect(_on_volume_label_update.bind(volume_value))

func create_gameplay_section(parent: VBoxContainer):
	"""Crear sección de jugabilidad"""
	var section_title = Label.new()
	section_title.text = "🎮 JUGABILIDAD"
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
	lefty_label.custom_minimum_size.x = 120
	lefty_hbox.add_child(lefty_label)

	var lefty_check = CheckBox.new()
	lefty_check.button_pressed = Save.game_data.get("left_handed", false)
	lefty_check.toggled.connect(_on_lefty_toggled)
	lefty_hbox.add_child(lefty_check)

	# Animaciones reducidas
	var anim_hbox = HBoxContainer.new()
	gameplay_container.add_child(anim_hbox)

	var anim_label = Label.new()
	anim_label.text = "Animaciones Reducidas:"
	anim_label.custom_minimum_size.x = 120
	anim_hbox.add_child(anim_label)

	var anim_check = CheckBox.new()
	anim_check.button_pressed = Save.game_data.get("reduced_animations", false)
	anim_check.toggled.connect(_on_reduced_animations_toggled)
	anim_hbox.add_child(anim_check)

func create_data_section(parent: VBoxContainer):
	"""Crear sección de datos de juego"""
	var section_title = Label.new()
	section_title.text = "💾 DATOS DE JUEGO"
	section_title.add_theme_font_size_override("font_size", 20)
	parent.add_child(section_title)

	var data_container = VBoxContainer.new()
	data_container.add_theme_constant_override("separation", 10)
	parent.add_child(data_container)

	# Botón gestor de guardado
	var save_manager_btn = Button.new()
	save_manager_btn.text = "💾 Gestor de Partidas"
	save_manager_btn.custom_minimum_size.y = 40
	save_manager_btn.pressed.connect(_on_save_manager_pressed)
	data_container.add_child(save_manager_btn)

	# Información de guardado actual
	var save_info_label = Label.new()
	var slot = Save.current_save_slot
	save_info_label.text = "Slot actual: %d | Última partida guardada" % [slot]
	save_info_label.add_theme_font_size_override("font_size", 12)
	save_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	data_container.add_child(save_info_label)

func create_game_info_section(parent: VBoxContainer):
	"""Crear sección de información del juego"""
	var info_container = VBoxContainer.new()
	info_container.add_theme_constant_override("separation", 8)
	parent.add_child(info_container)

	# Información del juego usando VersionInfo
	var game_info = Label.new()
	game_info.text = "%s v%s" % [VersionInfo.get_game_title(), VersionInfo.get_version()]
	game_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_info.add_theme_font_size_override("font_size", 16)
	info_container.add_child(game_info)

	# Estadísticas del jugador
	var stats_info = Label.new()
	stats_info.text = "🪙 %d monedas | 💎 %d gemas | 📈 Nivel %d" % [
		Save.get_coins(), Save.get_gems(), Save.game_data.get("level", 1)
	]
	stats_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_info.add_theme_font_size_override("font_size", 14)
	stats_info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	info_container.add_child(stats_info)

	# Copyright y empresa
	if menu_type == MenuType.SPLASH_OPTIONS:
		var copyright_info = Label.new()
		copyright_info.text = "© 2024 %s" % VersionInfo.get_company()
		copyright_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		copyright_info.add_theme_font_size_override("font_size", 12)
		copyright_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_container.add_child(copyright_info)

# === CALLBACKS DE EVENTOS ===

func _on_pause_button_pressed(action: String):
	"""Manejar botones del menú de pausa"""
	if SFX:
		SFX.play_event("click")

	match action:
		"resume":
			emit_signal("resume_requested")
			_close_menu()
		"settings":
			# Cambiar a modo opciones completas
			menu_type = MenuType.SPLASH_OPTIONS
			_refresh_content()
		"save_exit":
			Save.save_game()
			emit_signal("save_and_exit_requested")
			_close_menu()

func _on_volume_changed(setting_key: String, value: float):
	"""Cambio de volumen"""
	Save.game_data[setting_key] = value
	Save.save_game()

	# Aplicar cambios de audio inmediatamente
	if SFX and setting_key == "sfx_volume":
		SFX.set_master_volume(value)

	if SFX:
		SFX.play_event("click")

func _on_volume_label_update(volume_label: Label, value: float):
	"""Actualizar etiqueta de volumen"""
	volume_label.text = str(int(value * 100)) + "%"

func _on_vibration_toggled(pressed: bool):
	"""Toggle vibración"""
	Save.game_data.vibration_enabled = pressed
	Save.save_game()
	if SFX:
		SFX.play_event("click")

func _on_lefty_toggled(pressed: bool):
	"""Toggle modo zurdo"""
	Save.game_data.left_handed = pressed
	Save.save_game()
	if SFX:
		SFX.play_event("click")

func _on_reduced_animations_toggled(pressed: bool):
	"""Toggle animaciones reducidas"""
	Save.game_data.reduced_animations = pressed
	Save.save_game()
	if SFX:
		SFX.play_event("click")

func _on_save_manager_pressed():
	"""Abrir gestor de guardado"""
	emit_signal("save_manager_requested")
	if SFX:
		SFX.play_event("click")
	_close_menu()

func _on_close_pressed():
	"""Cerrar menú"""
	if SFX:
		SFX.play_event("click")
	_close_menu()

func _on_background_clicked(event):
	"""Cerrar menú al hacer clic en fondo"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_menu()

func _input(event):
	"""Cerrar con ESC"""
	if event.is_action_pressed("ui_cancel"):
		_close_menu()

# === MÉTODOS AUXILIARES ===

func _close_menu():
	"""Cerrar y liberar menú"""
	if menu_type == MenuType.PAUSE:
		emit_signal("resume_requested")
	else:
		emit_signal("menu_closed")
	queue_free()

func _refresh_content():
	"""Refrescar contenido del panel"""
	if main_panel:
		# Limpiar contenido actual
		for child in main_panel.get_children():
			child.queue_free()

		# Reconfigurar
		call_deferred("_setup_panel_content", main_panel)

# Ya no se necesitan métodos estáticos - usamos escenas .tscn
