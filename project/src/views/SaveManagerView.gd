class_name SaveManagerView
extends Control

signal save_loaded(slot: int)
signal save_created(slot: int)

var save_slots_container: VBoxContainer
var back_button: Button

func _ready():
	setup_save_manager_ui()
	refresh_save_slots()

func setup_save_manager_ui():
	# Fondo semi-transparente
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.gui_input.connect(_on_background_clicked)
	add_child(background)

	# Panel principal centrado
	var main_panel = PanelContainer.new()
	main_panel.anchor_left = 0.05
	main_panel.anchor_right = 0.95
	main_panel.anchor_top = 0.1
	main_panel.anchor_bottom = 0.9
	add_child(main_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(main_vbox)

	# Título
	var title_label = Label.new()
	title_label.text = "💾 GESTOR DE PARTIDAS"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)

	# Scroll para slots de guardado
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	save_slots_container = VBoxContainer.new()
	save_slots_container.add_theme_constant_override("separation", 10)
	scroll.add_child(save_slots_container)

	# Botón volver
	back_button = Button.new()
	back_button.text = "⬅️ Volver"
	back_button.custom_minimum_size = Vector2(200, 48)
	back_button.pressed.connect(_on_back_pressed)
	main_vbox.add_child(back_button)

func refresh_save_slots():
	# Limpiar slots existentes
	for child in save_slots_container.get_children():
		child.queue_free()

	# Crear 5 slots de guardado
	for slot in range(1, 6):
		create_save_slot(slot)

func create_save_slot(slot: int):
	var slot_info = Save.get_save_slot_info(slot)

	# Panel principal del slot
	var slot_panel = PanelContainer.new()
	slot_panel.custom_minimum_size = Vector2(380, 100)
	save_slots_container.add_child(slot_panel)

	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	slot_panel.add_child(content)

	# Información del slot
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(info_container)

	var slot_title = Label.new()
	slot_title.text = "🎮 Slot %d" % slot
	slot_title.add_theme_font_size_override("font_size", 18)
	info_container.add_child(slot_title)

	if slot_info.empty:
		var empty_label = Label.new()
		empty_label.text = "💭 Partida nueva"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		info_container.add_child(empty_label)
	else:
		var details_label = Label.new()
		details_label.text = "💰 %d monedas | 💎 %d gemas | 📈 Nivel %d\n🗺️ Zona: %s | 📅 %s" % [
			slot_info.coins, slot_info.gems, slot_info.level,
			slot_info.zone.capitalize(), slot_info.playtime
		]
		details_label.add_theme_font_size_override("font_size", 12)
		info_container.add_child(details_label)

	# Botones de acción
	var buttons_container = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 5)
	content.add_child(buttons_container)

	if slot_info.empty:
		var new_game_btn = Button.new()
		new_game_btn.text = "🆕 Nueva"
		new_game_btn.custom_minimum_size = Vector2(80, 40)
		new_game_btn.pressed.connect(_on_new_game_pressed.bind(slot))
		buttons_container.add_child(new_game_btn)
	else:
		var load_btn = Button.new()
		load_btn.text = "📂 Cargar"
		load_btn.custom_minimum_size = Vector2(80, 35)
		load_btn.pressed.connect(_on_load_pressed.bind(slot))
		buttons_container.add_child(load_btn)

		var save_btn = Button.new()
		save_btn.text = "💾 Guardar"
		save_btn.custom_minimum_size = Vector2(80, 35)
		save_btn.pressed.connect(_on_save_pressed.bind(slot))
		buttons_container.add_child(save_btn)

		var delete_btn = Button.new()
		delete_btn.text = "🗑️ Borrar"
		delete_btn.custom_minimum_size = Vector2(80, 35)
		delete_btn.add_theme_color_override("font_color", Color.RED)
		delete_btn.pressed.connect(_on_delete_pressed.bind(slot))
		buttons_container.add_child(delete_btn)

func _on_new_game_pressed(slot: int):
	Save.reset_to_default()
	Save.save_to_slot(slot)
	emit_signal("save_created", slot)
	show_message("🎉 Nueva partida creada en Slot %d" % slot)
	refresh_save_slots()

func _on_load_pressed(slot: int):
	Save.load_from_slot(slot)
	emit_signal("save_loaded", slot)
	show_message("📂 Partida cargada desde Slot %d" % slot)

func _on_save_pressed(slot: int):
	Save.save_to_slot(slot)
	show_message("💾 Partida guardada en Slot %d" % slot)
	refresh_save_slots()

func _on_delete_pressed(slot: int):
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "⚠️ Confirmar borrado"
	confirm_dialog.dialog_text = "¿Seguro que quieres borrar la partida del Slot %d?\n\n" + \
		"Esta acción no se puede deshacer." % slot

	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(_perform_delete.bind(slot))
	confirm_dialog.popup_centered()

func _perform_delete(slot: int):
	Save.delete_save_slot(slot)
	show_message("🗑️ Partida del Slot %d eliminada" % slot)
	refresh_save_slots()

func _on_back_pressed():
	# Cerrar la vista del gestor de guardado
	queue_free()

func show_message(text: String):
	var message_label = Label.new()
	message_label.text = text
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color.LIME_GREEN)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(50, 50)

	add_child(message_label)

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(message_label.queue_free)

func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()

func _input(event):
	# Permitir cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		queue_free()
