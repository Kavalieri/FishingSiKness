class_name SaveManagerView
extends Control

signal save_loaded(slot: int)
signal save_created(slot: int)

var save_slots_container: VBoxContainer
var back_button: Button

func setup_menu():
	"""Configurar interfaz del gestor de guardado - MENÚ ESTANDARIZADO"""
	name = "SaveManagerView"

	setup_save_manager_ui()
	# Diferir refresh_save_slots hasta que la UI esté completamente configurada
	call_deferred("refresh_save_slots")

func setup_save_manager_ui():
	"""Configurar interfaz del gestor de guardado con estilo unificado"""
	# FONDO COMPLETAMENTE OPACO - MÉTODO DIRECTO
	var opaque_bg = ColorRect.new()
	opaque_bg.color = Color.BLACK # Negro puro 100% opaco
	opaque_bg.anchor_right = 1.0
	opaque_bg.anchor_bottom = 1.0
	opaque_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	opaque_bg.z_index = -1
	add_child(opaque_bg)

	# Evento para cerrar al hacer click en fondo
	opaque_bg.gui_input.connect(_on_background_clicked)

	# Panel principal centrado dinámicamente
	var main_panel = PanelContainer.new()
	main_panel.z_index = 1
	add_child(main_panel)

	# Centrar usando el mismo sistema que UnifiedMenu
	call_deferred("_center_panel", main_panel)
	call_deferred("_setup_panel_content", main_panel)

func _center_panel(panel: PanelContainer):
	"""Centrar panel dinámicamente en pantalla - mismo sistema que UnifiedMenu"""
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = Vector2(
		viewport_size.x * 0.7, # Más ancho para mostrar información de slots
		viewport_size.y * 0.8 # Alto suficiente para 5 slots
	)

	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.position = (viewport_size - panel_size) / 2
	panel.modulate = Color(1, 1, 1, 1.0) # 100% opaco
	panel.show()

func _setup_panel_content(panel: PanelContainer):
	"""Configurar contenido del panel"""
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	panel.add_child(main_vbox)

	# Título con indicador de slot actual - mismo estilo que UnifiedMenu
	var title_hbox = HBoxContainer.new()
	main_vbox.add_child(title_hbox)

	var title_label = Label.new()
	title_label.text = "💾 GESTOR DE PARTIDAS"
	title_label.add_theme_font_size_override("font_size", 28) # Mismo tamaño que UnifiedMenu
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_hbox.add_child(title_label)

	# Botón cerrar - mismo estilo que UnifiedMenu
	var close_btn = Button.new()
	close_btn.text = "❌"
	close_btn.custom_minimum_size = Vector2(48, 48)
	close_btn.pressed.connect(_on_back_pressed)
	title_hbox.add_child(close_btn)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 10
	main_vbox.add_child(separator)

	# ELIMINADO: Indicador de slot actual (ya se ve visualmente en cada slot)

	# Scroll para slots de guardado
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	save_slots_container = VBoxContainer.new()
	save_slots_container.add_theme_constant_override("separation", 10)
	scroll.add_child(save_slots_container)

	print("SaveManagerView: save_slots_container configurado correctamente")

func refresh_save_slots():
	"""Refrescar la lista de slots de guardado"""
	# Verificar que save_slots_container existe antes de usarlo
	if not save_slots_container:
		print("Warning: save_slots_container is null, cannot refresh save slots")
		return

	# Limpiar slots existentes
	for child in save_slots_container.get_children():
		child.queue_free()

	# Crear 5 slots de guardado
	for slot in range(1, 6):
		create_save_slot(slot)

func create_save_slot(slot: int):
	"""Crear interfaz para un slot de guardado individual"""
	var slot_info = Save.get_save_slot_info(slot)
	var is_current_slot = (slot == Save.current_save_slot)

	# Panel principal del slot con indicador visual para slot actual
	var slot_panel = PanelContainer.new()
	slot_panel.custom_minimum_size = Vector2(420, 100)

	# Destacar slot actual
	if is_current_slot:
		slot_panel.add_theme_color_override("background_color", Color(0.2, 0.4, 0.2, 0.8))

	save_slots_container.add_child(slot_panel)

	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	slot_panel.add_child(content)

	# Información del slot
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(info_container)

	var slot_title = Label.new()
	var slot_title_text = "🎮 Slot %d" % slot
	if slot == Save.current_save_slot:
		slot_title_text += " ⭐ (Actual)"
	slot_title.text = slot_title_text
	slot_title.add_theme_font_size_override("font_size", 18)
	if slot == Save.current_save_slot:
		slot_title.add_theme_color_override("font_color", Color.YELLOW)
	info_container.add_child(slot_title)

	if slot_info.empty:
		var empty_label = Label.new()
		empty_label.text = "💭 Partida nueva"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		info_container.add_child(empty_label)
	else:
		var details_label = Label.new()
		# Primera línea: monedas, gemas, nivel
		var line1 = "💰 %d monedas | 💎 %d gemas | 📈 Nivel %d" % [
			slot_info.coins, slot_info.gems, slot_info.level
		]
		# Segunda línea: zona y tiempo
		var line2 = "🗺️ Zona: %s | 📅 %s" % [
			slot_info.zone.capitalize(), slot_info.playtime
		]
		# Tercera línea: inventario de peces (solo si hay peces)
		var line3 = ""
		if slot_info.fish_count > 0:
			line3 = "🐟 %d peces (valor: %d monedas)" % [
				slot_info.fish_count, slot_info.fish_value
			]

		details_label.text = line1 + "\n" + line2 + ("\n" + line3 if line3 != "" else "")
		details_label.add_theme_font_size_override("font_size", 12)
		info_container.add_child(details_label)

	# Botones de acción mejorados
	var buttons_container = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 5)
	content.add_child(buttons_container)

	if slot_info.empty:
		var new_game_btn = Button.new()
		new_game_btn.text = "🆕 Nueva Partida"
		new_game_btn.custom_minimum_size = Vector2(100, 40)
		new_game_btn.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		new_game_btn.pressed.connect(_on_new_game_pressed.bind(slot))
		buttons_container.add_child(new_game_btn)
	else:
		var load_btn = Button.new()
		load_btn.text = "📂 Cargar"
		load_btn.custom_minimum_size = Vector2(100, 35)
		load_btn.add_theme_color_override("font_color", Color.CYAN)
		load_btn.pressed.connect(_on_load_pressed.bind(slot))
		buttons_container.add_child(load_btn)

		var save_btn = Button.new()
		save_btn.text = "💾 Sobrescribir"
		save_btn.custom_minimum_size = Vector2(100, 35)
		save_btn.add_theme_color_override("font_color", Color.ORANGE)
		save_btn.pressed.connect(_on_save_pressed.bind(slot))
		buttons_container.add_child(save_btn)

		var delete_btn = Button.new()
		delete_btn.text = "🗑️ Eliminar"
		delete_btn.custom_minimum_size = Vector2(100, 35)
		delete_btn.add_theme_color_override("font_color", Color.RED)
		delete_btn.pressed.connect(_on_delete_pressed.bind(slot))
		buttons_container.add_child(delete_btn)

func _on_new_game_pressed(slot: int):
	"""Crear nueva partida con confirmación"""
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "🆕 Nueva Partida"
	confirm_dialog.dialog_text = ("¿Crear nueva partida en el Slot %d?\n\n" + \
		"Se iniciará una partida completamente nueva con valores por defecto.") % slot

	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(_perform_new_game.bind(slot))
	confirm_dialog.popup_centered()

func _perform_new_game(slot: int):
	"""Ejecutar creación de nueva partida"""
	Save.reset_to_default()
	Save.save_to_slot(slot)
	Save.current_save_slot = slot

	# CORRECCIÓN: Cargar inmediatamente los datos nuevos en memoria
	Save.load_from_slot(slot)

	emit_signal("save_created", slot)
	if SFX:
		SFX.play_event("success")
	show_message("🎉 Nueva partida creada en Slot %d" % slot)
	refresh_save_slots()

func _on_load_pressed(slot: int):
	"""Cargar partida existente"""
	Save.load_from_slot(slot)
	emit_signal("save_loaded", slot)
	if SFX:
		SFX.play_event("success")
	show_message("📂 Partida cargada desde Slot %d" % slot)
	# Refrescar para mostrar el nuevo slot actual
	refresh_save_slots()

func _on_save_pressed(slot: int):
	"""Sobrescribir partida existente con confirmación"""
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "💾 Sobrescribir Partida"
	confirm_dialog.dialog_text = "¿Sobrescribir la partida del Slot %d?\n\n" + \
		"Se perderá el progreso guardado anteriormente en este slot." % slot

	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(_perform_save.bind(slot))
	confirm_dialog.popup_centered()

func _perform_save(slot: int):
	"""Ejecutar sobrescritura de partida"""
	Save.save_to_slot(slot)
	if SFX:
		SFX.play_event("success")
	show_message("💾 Partida sobrescrita en Slot %d" % slot)
	refresh_save_slots()

func _on_delete_pressed(slot: int):
	"""Confirmar eliminación de partida"""
	var slot_info = Save.get_save_slot_info(slot)
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "🗑️ Eliminar Partida"
	confirm_dialog.dialog_text = "¿ELIMINAR la partida del Slot %d?\n\n" + \
		"📊 Progreso: %d monedas, %d gemas, Nivel %d\n" + \
		"🕒 Tiempo de juego: %s\n\n" + \
		"⚠️ ESTA ACCIÓN NO SE PUEDE DESHACER ⚠️" % [
			slot, slot_info.coins, slot_info.gems, slot_info.level, slot_info.playtime
		]

	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(_perform_delete.bind(slot))
	confirm_dialog.popup_centered()

func _perform_delete(slot: int):
	"""Ejecutar eliminación de partida"""
	Save.delete_save_slot(slot)
	if SFX:
		SFX.play_event("error") # Sonido distintivo para eliminación
	show_message("🗑️ Partida del Slot %d eliminada permanentemente" % slot)
	refresh_save_slots()

func _on_back_pressed():
	# Cerrar la vista del gestor de guardado
	queue_free()

func show_message(text: String):
	"""Mostrar mensaje de feedback mejorado"""
	var message_panel = PanelContainer.new()
	message_panel.anchor_left = 0.2
	message_panel.anchor_right = 0.8
	message_panel.anchor_top = 0.4
	message_panel.anchor_bottom = 0.6
	add_child(message_panel)

	var message_label = Label.new()
	message_label.text = text
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color.YELLOW)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_panel.add_child(message_label)

	# Animación de aparición y desaparición
	message_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(message_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(message_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(message_panel.queue_free)

func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()

func _input(event):
	# Permitir cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		queue_free()
