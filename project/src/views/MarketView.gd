class_name MarketView
extends Control

var info_label: Label

func _ready():
	setup_ui()
	refresh_display()

func setup_ui():
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 10
	main_vbox.offset_right = -10
	main_vbox.offset_top = 10
	main_vbox.offset_bottom = -10

	# Título
	var title = Label.new()
	title.text = "MERCADO (Orilla)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	main_vbox.add_child(title)

	# Información general
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	main_vbox.add_child(info_label)

	# Botón para ir a la nevera
	var goto_fridge_btn = Button.new()
	goto_fridge_btn.text = "IR A NEVERA PARA VENDER"
	goto_fridge_btn.custom_minimum_size.y = 48
	goto_fridge_btn.pressed.connect(_on_goto_fridge_pressed)
	main_vbox.add_child(goto_fridge_btn)

func refresh_display():
	if not info_label:
		return

	var inventory = Save.get_inventory()
	var total_value = 0
	var fish_summary = {}

	# Calcular estadísticas
	for fish_data in inventory:
		var name = fish_data.get("name", "Pez")
		var value = fish_data.get("value", 0)
		total_value += value

		if fish_summary.has(name):
			fish_summary[name].count += 1
			fish_summary[name].value += value
		else:
			fish_summary[name] = {"count": 1, "value": value}

	# Crear texto informativo
	var info_text = ""

	if inventory.size() == 0:
		info_text = "No tienes peces para vender.\n\n¡Ve a pescar para llenar tu nevera!"
	else:
		info_text = "INVENTARIO ACTUAL:\n\n"

		for fish_name in fish_summary.keys():
			var data = fish_summary[fish_name]
			info_text += "• %s (%d) - %dc\n" % [fish_name, data.count, data.value]

		info_text += "\nVALOR TOTAL: %dc\n\n" % total_value
		info_text += "Multiplicador de zona: x1.0 (Orilla)\n"
		info_text += "Capacidad usada: %d/%d" % [inventory.size(), Save.get_max_inventory()]

	info_label.text = info_text

func _on_goto_fridge_pressed():
	# Abrir panel de inventario unificado con opción de venta
	var screen_manager = get_tree().current_scene
	if screen_manager and screen_manager.has_method("show_inventory"):
		screen_manager.show_inventory(true, "🧊 NEVERA - VENTA")
		if SFX:
			SFX.play_event("click")
