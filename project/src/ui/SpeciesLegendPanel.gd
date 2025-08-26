class_name SpeciesLegendPanel
extends PanelContainer

signal closed()

var close_button: Button
var content_container: VBoxContainer
var species_grid: GridContainer

func _ready():
	# Configurar estilo del panel
	modulate = Color(1, 1, 1, 0.95)
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(600, 700)

	setup_ui()
	populate_species_data()

func setup_ui():
	content_container = VBoxContainer.new()
	add_child(content_container)

	# Título y botón cerrar
	var header = HBoxContainer.new()
	content_container.add_child(header)

	var title_label = Label.new()
	title_label.text = "📚 LEYENDA DE ESPECIES"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title_label)

	close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	content_container.add_child(HSeparator.new())

	# Grid para especies
	species_grid = GridContainer.new()
	species_grid.columns = 2 # 2 columnas para mostrar más especies
	content_container.add_child(species_grid)

func populate_species_data():
	if not Content:
		return

	var all_fish = Content.get_all_fish_definitions()
	if not all_fish:
		add_no_data_message()
		return

	# Ordenar por rareza y luego por nombre
	all_fish.sort_custom(func(a, b):
		if a.rarity == b.rarity:
			return a.name < b.name
		return a.rarity < b.rarity
	)

	var current_rarity = -1

	for fish_def in all_fish:
		# Añadir separador de rareza si es necesario
		if fish_def.rarity != current_rarity:
			add_rarity_header(fish_def.rarity)
			current_rarity = fish_def.rarity

		add_species_entry(fish_def)

func add_rarity_header(rarity: int):
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 2
	species_grid.add_child(separator)

	var empty_cell = Control.new()
	species_grid.add_child(empty_cell)

	var rarity_label = Label.new()
	rarity_label.text = get_rarity_text(rarity).to_upper()
	rarity_label.add_theme_font_size_override("font_size", 16)
	rarity_label.add_theme_color_override("font_color", get_rarity_color(rarity))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	species_grid.add_child(rarity_label)

	var empty_cell2 = Control.new()
	species_grid.add_child(empty_cell2)

func add_species_entry(fish_def: FishDef):
	# Panel para la entrada de la especie
	var entry_panel = PanelContainer.new()
	entry_panel.custom_minimum_size = Vector2(280, 120)
	entry_panel.add_theme_color_override("bg_color", Color(0.1, 0.1, 0.2, 0.3))
	species_grid.add_child(entry_panel)

	var entry_container = HBoxContainer.new()
	entry_panel.add_child(entry_container)

	# Imagen del pez
	if fish_def.sprite:
		var fish_image = TextureRect.new()
		fish_image.texture = fish_def.sprite
		fish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fish_image.custom_minimum_size = Vector2(80, 80)
		entry_container.add_child(fish_image)

	# Información del pez
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_container.add_child(info_container)

	# Nombre
	var name_label = Label.new()
	name_label.text = fish_def.name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", get_rarity_color(fish_def.rarity))
	info_container.add_child(name_label)

	# Categoría de especie
	if fish_def.species_category != "":
		var category_label = Label.new()
		category_label.text = fish_def.species_category
		category_label.add_theme_font_size_override("font_size", 10)
		category_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		info_container.add_child(category_label)

	# Tamaño
	var size_label = Label.new()
	size_label.text = "Tamaño: %.0f-%.0f cm" % [fish_def.size_min, fish_def.size_max]
	size_label.add_theme_font_size_override("font_size", 10)
	info_container.add_child(size_label)

	# Valor base
	var value_label = Label.new()
	value_label.text = "Valor: %d monedas" % fish_def.base_market_value
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", Color.GOLD)
	info_container.add_child(value_label)

	# Hábitats
	if fish_def.habitat_zones.size() > 0:
		var habitat_label = Label.new()
		var habitat_names = []
		for zone_id in fish_def.habitat_zones:
			habitat_names.append(get_zone_display_name(zone_id))
		habitat_label.text = "Hábitat: " + ", ".join(habitat_names)
		habitat_label.add_theme_font_size_override("font_size", 9)
		habitat_label.add_theme_color_override("font_color", Color.CYAN)
		habitat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_container.add_child(habitat_label)

func add_no_data_message():
	var no_data_label = Label.new()
	no_data_label.text = "No hay especies disponibles en el sistema de contenido."
	no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_data_label.add_theme_font_size_override("font_size", 16)
	species_grid.add_child(no_data_label)

func get_rarity_text(rarity: int) -> String:
	var rarities = ["Común", "Poco común", "Raro", "Épico", "Legendario"]
	return rarities[rarity] if rarity < rarities.size() else "Común"

func get_rarity_color(rarity: int) -> Color:
	var colors = [Color.WHITE, Color.GREEN, Color.BLUE, Color.PURPLE, Color.GOLD]
	return colors[rarity] if rarity < colors.size() else Color.WHITE

func get_zone_display_name(zone_id: String) -> String:
	var zone_names = {
		"orilla": "Orilla",
		"lago": "Lago",
		"rio": "Río",
		"costa": "Costa",
		"mar": "Mar Abierto"
	}
	return zone_names.get(zone_id, zone_id.capitalize())

func _on_close_pressed():
	hide()
	emit_signal("closed")

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		accept_event()
