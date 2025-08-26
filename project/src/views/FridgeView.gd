# FridgeView - Gestión de inventario como menú flotante estandarizado
extends BaseFloatingMenu

func setup_menu():
	"""Configurar interfaz de la nevera/inventario"""
	name = "FridgeView"

	setup_ui()
	refresh_display()

func refresh_display():
	"""Actualizar info del inventario"""
	var inventory = Save.get_inventory()
	var max_inventory = Save.game_data.get("max_inventory", 12)

	var info_label = get_node_or_null("MainVBox/InfoLabel")
	if info_label:
		info_label.text = "📦 %d/%d peces almacenados" % [inventory.size(), max_inventory]

func setup_background():
	"""Ya no necesario - BaseFloatingMenu maneja el fondo automáticamente"""
	return

func setup_ui():
	# Limpiar hijos existentes
	for child in get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	add_child(main_vbox)
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 20
	main_vbox.offset_right = -20
	main_vbox.offset_top = 20
	main_vbox.offset_bottom = -20
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Icono grande
	var icon_label = Label.new()
	icon_label.text = "🧊"
	icon_label.add_theme_font_size_override("font_size", 80)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(icon_label)

	# Título
	var title = Label.new()
	title.text = "NEVERA"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	# Descripción
	var desc_label = Label.new()
	desc_label.text = "Gestiona tu inventario de peces"
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	main_vbox.add_child(desc_label)

	# Separador
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 30
	main_vbox.add_child(spacer)

	# Botón para abrir inventario
	var open_inventory_btn = Button.new()
	open_inventory_btn.text = "🧊 ABRIR NEVERA"
	open_inventory_btn.custom_minimum_size = Vector2(250, 80)
	open_inventory_btn.add_theme_font_size_override("font_size", 20)
	open_inventory_btn.pressed.connect(_on_open_inventory_pressed)
	main_vbox.add_child(open_inventory_btn)

	# Info rápida del inventario
	var inventory = Save.get_inventory()
	var max_inventory = Save.game_data.get("max_inventory", 12)

	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "📦 %d/%d peces almacenados" % [inventory.size(), max_inventory]
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.modulate = Color(0.7, 0.7, 0.7)
	main_vbox.add_child(info_label)

func _on_open_inventory_pressed():
	var screen_manager = get_tree().current_scene
	if screen_manager and screen_manager.has_method("show_inventory"):
		screen_manager.show_inventory(true, "🧊 NEVERA - GESTIÓN")
		if SFX:
			SFX.play_event("click")
