class_name PauseMenu
extends Control

signal resume_requested()
signal save_and_exit_requested()
signal settings_requested()
signal save_manager_requested()

var main_panel: PanelContainer

func _ready():
	setup_ui()

func setup_ui():
	# Fondo opaco
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.95) # Más opaco
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.gui_input.connect(_on_background_clicked)
	add_child(background)

	# Panel principal (centrado dinámicamente)
	main_panel = PanelContainer.new()
	add_child(main_panel)

	# Centrado dinámico en _ready
	call_deferred("_center_panel", main_panel)
	call_deferred("_setup_panel_content", main_panel)

func _setup_panel_content(main_panel: PanelContainer):
	"""Configurar el contenido del panel después del centrado"""
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(main_vbox)

	# Título
	var title = Label.new()
	title.text = "⏸️ PAUSA"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 20
	main_vbox.add_child(separator)

	# Botones del menú
	var buttons_data = [
		{"text": "▶️ CONTINUAR", "signal": "resume_requested"},
		{"text": "💾 GESTOR DE PARTIDAS", "signal": "save_manager_requested"},
		{"text": "💾 GUARDAR Y SALIR", "signal": "save_and_exit_requested"},
		{"text": "⚙️ OPCIONES", "signal": "settings_requested"}
	]

	for button_data in buttons_data:
		var button = Button.new()
		button.text = button_data.text
		button.custom_minimum_size.y = 60
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_on_button_pressed.bind(button_data.signal ))
		main_vbox.add_child(button)

	# Información del juego
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(spacer)

	var info_vbox = VBoxContainer.new()
	main_vbox.add_child(info_vbox)

	var coins_label = Label.new()
	coins_label.text = "🪙 Monedas: %d" % Save.get_coins()
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(coins_label)

	var gems_label = Label.new()
	gems_label.text = "💎 Gemas: %d" % Save.get_gems()
	gems_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gems_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(gems_label)

	var version_label = Label.new()
	version_label.text = "Fishing SiKness v0.1.0"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.modulate = Color(0.7, 0.7, 0.7)
	info_vbox.add_child(version_label)

func _on_button_pressed(signal_name: String):
	if SFX:
		SFX.play_event("click")

	match signal_name:
		"resume_requested":
			emit_signal("resume_requested")
		"save_manager_requested":
			emit_signal("save_manager_requested")
		"save_and_exit_requested":
			Save.save_game()
			emit_signal("save_and_exit_requested")
		"settings_requested":
			emit_signal("settings_requested")

func _input(event):
	# Permitir cerrar con ESC o botón de atrás
	if event.is_action_pressed("ui_cancel"):
		emit_signal("resume_requested")

func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("resume_requested")

func _center_panel(panel: PanelContainer):
	"""Centrar el panel dinámicamente en la pantalla"""
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.6) # PauseMenu más pequeño

	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.position = (viewport_size - panel_size) / 2

	# Hacer el panel semi-transparente para que se vea el fondo
	panel.modulate = Color(1, 1, 1, 0.95)

	# Asegurar que está visible
	panel.show()
