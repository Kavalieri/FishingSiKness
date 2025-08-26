class_name MapView
extends Control

var zones_container: VBoxContainer
var current_zone_label: Label

# Datos de zonas temporales
var available_zones = [
	{
		"id": "lake",
		"name": "Lago Tranquilo",
		"description": "Un lago pacífico perfecto para principiantes",
		"unlock_cost": 0,
		"fish_types": ["pez_común", "pez_raro"]
	},
	{
		"id": "river",
		"name": "Río Salvaje",
		"description": "Aguas rápidas con peces más desafiantes",
		"unlock_cost": 500,
		"fish_types": ["pez_raro", "pez_épico"]
	},
	{
		"id": "ocean",
		"name": "Océano Profundo",
		"description": "Las profundidades guardan los tesoros más valiosos",
		"unlock_cost": 2000,
		"fish_types": ["pez_épico", "pez_legendario"]
	}
]

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

	# Título y zona actual
	var header = VBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "MAPA DE ZONAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)

	current_zone_label = Label.new()
	current_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_zone_label.add_theme_font_size_override("font_size", 16)
	current_zone_label.add_theme_color_override("font_color", Color.GREEN)
	header.add_child(current_zone_label)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 20
	main_vbox.add_child(separator)

	# Scroll para las zonas
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	zones_container = VBoxContainer.new()
	zones_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(zones_container)

func refresh_display():
	if not zones_container or not current_zone_label:
		return

	# Mostrar zona actual
	var current_zone = Save.game_data.get("current_zone", "lake")
	var zone_name = get_zone_name(current_zone)
	current_zone_label.text = "Zona Actual: %s" % zone_name

	# Limpiar zonas anteriores
	for child in zones_container.get_children():
		child.queue_free()

	# Crear botones de zonas
	for zone_data in available_zones:
		create_zone_button(zone_data)

func create_zone_button(zone_data: Dictionary):
	var container = VBoxContainer.new()
	container.custom_minimum_size.y = 100
	zones_container.add_child(container)

	# Panel de la zona
	var panel = PanelContainer.new()
	container.add_child(panel)

	var zone_vbox = VBoxContainer.new()
	zone_vbox.add_theme_constant_override("separation", 5)
	panel.add_child(zone_vbox)

	# Header con nombre y estado
	var header_hbox = HBoxContainer.new()
	zone_vbox.add_child(header_hbox)

	var name_label = Label.new()
	name_label.text = zone_data.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	header_hbox.add_child(name_label)

	var status_label = Label.new()
	header_hbox.add_child(status_label)

	# Descripción
	var desc_label = Label.new()
	desc_label.text = zone_data.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zone_vbox.add_child(desc_label)

	# Botón de acción
	var action_button = Button.new()
	action_button.custom_minimum_size.y = 40
	zone_vbox.add_child(action_button)

	var is_unlocked = is_zone_unlocked(zone_data.id)
	var is_current = Save.game_data.get("current_zone", "lake") == zone_data.id

	if is_current:
		status_label.text = "ACTUAL"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		action_button.text = "Ya estás aquí"
		action_button.disabled = true
		panel.add_theme_color_override("bg_color", Color(0, 0.3, 0, 0.3))

	elif is_unlocked:
		status_label.text = "DESBLOQUEADA"
		status_label.add_theme_color_override("font_color", Color.BLUE)
		action_button.text = "VIAJAR"
		action_button.pressed.connect(_on_zone_selected.bind(zone_data.id))

	else:
		status_label.text = "BLOQUEADA"
		status_label.add_theme_color_override("font_color", Color.RED)
		var unlock_cost = zone_data.unlock_cost
		action_button.text = "DESBLOQUEAR (%dc)" % unlock_cost

		if Save.get_coins() >= unlock_cost:
			action_button.pressed.connect(_on_zone_unlock.bind(zone_data.id, unlock_cost))
		else:
			action_button.disabled = true
			action_button.modulate = Color.GRAY

func is_zone_unlocked(zone_id: String) -> bool:
	# Primera zona siempre desbloqueada
	if zone_id == "lake":
		return true

	var unlocked_zones = Save.game_data.get("unlocked_zones", ["lake"])
	return unlocked_zones.has(zone_id)

func get_zone_name(zone_id: String) -> String:
	for zone_data in available_zones:
		if zone_data.id == zone_id:
			return zone_data.name
	return "Desconocida"

func _on_zone_selected(zone_id: String):
	if zone_id != Save.game_data.get("current_zone", "lake"):
		Save.game_data.current_zone = zone_id

		if SFX:
			SFX.play_event("success")

		print("Traveled to zone: ", zone_id)
		refresh_display()

		# Actualizar background si existe sistema
		_update_zone_background(zone_id)

func _on_zone_unlock(zone_id: String, cost: int):
	if Save.spend_coins(cost):
		if not Save.game_data.has("unlocked_zones"):
			Save.game_data.unlocked_zones = ["lake"]
		Save.game_data.unlocked_zones.append(zone_id)

		if SFX:
			SFX.play_event("success")

		print("Zone unlocked: ", zone_id)
		refresh_display()
	else:
		if SFX:
			SFX.play_event("error")

func _update_zone_background(zone_id: String):
	# Placeholder para cambiar fondo según zona
	# En el futuro conectaría con sistema de fondos
	print("Zone background updated to: ", zone_id)
