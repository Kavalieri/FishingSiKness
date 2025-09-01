class_name ZoneInfoDialog
extends Window

# Referencias a los nodos del dialog
@onready var zone_icon: TextureRect = $VBoxContainer/HeaderContainer/ZoneIcon
@onready var zone_name_label: Label = $VBoxContainer/HeaderContainer/TitleContainer/ZoneNameLabel
@onready var difficulty_value: Label = $VBoxContainer/HeaderContainer/TitleContainer/DifficultyContainer/DifficultyValue
@onready var multiplier_value: Label = $VBoxContainer/HeaderContainer/TitleContainer/MultiplierContainer/MultiplierValue
@onready var description_text: Label = $VBoxContainer/DescriptionContainer/DescriptionText
# @onready var species_list: VBoxContainer = $VBoxContainer/SpeciesContainer/SpeciesScroll/SpeciesList

func _ready():
	# Configurar el diálogo como movible y centrado
	# Conectar señal de cierre
	close_requested.connect(_on_close_requested)
	# Configurar propiedades de la ventana
	min_size = Vector2(600, 400)
	max_size = Vector2(800, 1000)
	# Asegurar que tenga botón de cerrar
	unresizable = false

func show_zone_info(zone_data: Dictionary) -> void:
	"""Mostrar información completa de una zona"""
	if not zone_data:
		return

	# Información básica de la zona
	zone_name_label.text = zone_data.get("name", "Zona Desconocida")
	difficulty_value.text = "%d/5" % zone_data.get("difficulty", 1)
	multiplier_value.text = "x%.1f" % zone_data.get("price_multiplier", 1.0)

	# Descripción de la zona (limpiar formato si es necesario)
	var description = zone_data.get("description", "No hay descripción disponible.")
	# Limpiar formato "Rarezas: X Y" si está presente
	var clean_description = _clean_zone_description(description)
	description_text.text = clean_description

	# Icono de fondo de la zona (opcional)
	var background_path = zone_data.get("background", "")
	if background_path != "" and ResourceLoader.exists(background_path):
		var texture = ResourceLoader.load(background_path, "Texture2D")
		if texture:
			zone_icon.texture = texture

	# Limpiar lista anterior
	_clear_species_list()

	# Obtener y mostrar especies de la zona
	var zone_id = zone_data.get("id", "")
	if zone_id != "" and Content:
		var fish_list = Content.get_fish_for_zone(zone_id)
		print("[ZoneInfoDialog] DEBUG: Zone ID: ", zone_id)
		print("[ZoneInfoDialog] DEBUG: Fish list size: ", fish_list.size())
		if fish_list.size() > 0:
			print("[ZoneInfoDialog] DEBUG: First fish: ", fish_list[0])
		_populate_species_list(fish_list)

	# Mostrar el diálogo
	popup_centered()
	# Traer al frente
	move_to_foreground()

func _clean_zone_description(description: String) -> String:
	"""Limpiar descripción de zona removiendo formato de rarezas"""
	# Remover líneas que empiecen con "Rarezas:"
	var lines = description.split("\n")
	var clean_lines = []

	for line in lines:
		var trimmed = line.strip_edges()
		if not trimmed.begins_with("Rarezas:") and not trimmed.begins_with("✨"):
			clean_lines.append(line)

	var result = "\n".join(clean_lines).strip_edges()

	# Si está vacío después de limpiar, poner descripción por defecto
	if result == "":
		result = "Una zona de pesca con diversas especies acuáticas."

	return result

func _clear_species_list() -> void:
	"""Limpiar lista de especies anterior"""
	var species_list = $VBoxContainer/SpeciesContainer/SpeciesScroll/SpeciesList
	for child in species_list.get_children():
		child.queue_free()

func _populate_species_list(fish_list: Array) -> void:
	"""Poblar lista de especies con información detallada"""
	print("[ZoneInfoDialog] DEBUG: _populate_species_list called with ", fish_list.size(), " fish")

	# Obtener el nodo dinámicamente
	var species_list = $VBoxContainer/SpeciesContainer/SpeciesScroll/SpeciesList
	print("[ZoneInfoDialog] DEBUG: species_list is null: ", species_list == null)

	if species_list == null:
		print("[ZoneInfoDialog] ERROR: species_list node is null!")
		return

	if fish_list.size() == 0:
		print("[ZoneInfoDialog] DEBUG: No fish found, showing empty message")
		var no_fish_label = Label.new()
		no_fish_label.text = "No hay especies disponibles en esta zona."
		no_fish_label.modulate = Color.GRAY
		species_list.add_child(no_fish_label)
		return

	# Agrupar por rareza para mejor organización
	var species_by_rarity = {}
	print("[ZoneInfoDialog] DEBUG: Starting fish processing...")

	for i in range(fish_list.size()):
		var fish = fish_list[i]
		print("[ZoneInfoDialog] DEBUG: Fish ", i, ": ", fish)
		if fish:
			print("[ZoneInfoDialog] DEBUG: Fish properties: name=", fish.name, " rarity=", fish.rarity)
			var rarity_string = _get_rarity_string(fish.rarity)
			if rarity_string != "":
				if not species_by_rarity.has(rarity_string):
					species_by_rarity[rarity_string] = []
				species_by_rarity[rarity_string].append(fish)
				print("[ZoneInfoDialog] DEBUG: Added fish to rarity group: ", rarity_string)
			else:
				print("[ZoneInfoDialog] DEBUG: Fish has invalid rarity: ", fish.rarity)
		else:
			print("[ZoneInfoDialog] DEBUG: Null fish at index ", i)

	print("[ZoneInfoDialog] DEBUG: Species by rarity: ", species_by_rarity.keys())

	# Orden de rareza para mostrar
	var rarity_order = ["común", "poco común", "raro", "épico", "legendario"]

	for rarity in rarity_order:
		if species_by_rarity.has(rarity):
			print("[ZoneInfoDialog] DEBUG: Adding rarity section: ", rarity, " with ", species_by_rarity[rarity].size(), " fish")
			_add_rarity_section(rarity, species_by_rarity[rarity])
		else:
			print("[ZoneInfoDialog] DEBUG: No fish found for rarity: ", rarity)

	print("[ZoneInfoDialog] DEBUG: Finished populating species list")

func _add_rarity_section(rarity: String, fish_list: Array) -> void:
	"""Añadir sección de rareza con sus peces"""
	print("[ZoneInfoDialog] DEBUG: _add_rarity_section called for: ", rarity, " with ", fish_list.size(), " fish")
	var species_list = $VBoxContainer/SpeciesContainer/SpeciesScroll/SpeciesList

	# Título de rareza
	var rarity_header = Label.new()
	var rarity_color = _get_rarity_color(rarity)
	var rarity_emoji = _get_rarity_emoji(rarity)

	rarity_header.text = "%s %s (%d especies)" % [rarity_emoji, rarity.capitalize(), fish_list.size()]
	rarity_header.add_theme_font_size_override("font_size", 20)
	rarity_header.modulate = rarity_color
	species_list.add_child(rarity_header)
	print("[ZoneInfoDialog] DEBUG: Added rarity header for: ", rarity)

	# Lista de peces de esta rareza
	for fish in fish_list:
		print("[ZoneInfoDialog] DEBUG: Adding fish entry: ", fish.name)
		_add_species_entry(fish)

	# Espaciado entre secciones
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	species_list.add_child(spacer)
	print("[ZoneInfoDialog] DEBUG: Finished rarity section: ", rarity)

func _add_species_entry(fish) -> void:
	"""Añadir entrada individual de especie"""
	var species_list = $VBoxContainer/SpeciesContainer/SpeciesScroll/SpeciesList

	var entry_container = HBoxContainer.new()
	entry_container.custom_minimum_size.y = 90
	species_list.add_child(entry_container)

	# Sprite del pez (si está disponible) - tamaño grande para móviles 80x80
	var fish_icon = TextureRect.new()
	fish_icon.custom_minimum_size = Vector2(80, 80)
	fish_icon.size = Vector2(80, 80)
	fish_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fish_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	fish_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fish_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if fish.sprite:
		fish_icon.texture = fish.sprite

	entry_container.add_child(fish_icon)

	# Espaciador entre icono y texto
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 20
	entry_container.add_child(spacer)

	# Información del pez
	var fish_info = VBoxContainer.new()
	fish_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_container.add_child(fish_info)

	# Nombre del pez
	var name_label = Label.new()
	name_label.text = fish.name if fish.name else "Especie desconocida"
	name_label.add_theme_font_size_override("font_size", 24)
	fish_info.add_child(name_label)

	# Características adicionales
	var details = []

	if fish.get("base_market_value"):
		details.append("💰 %d monedas" % fish.get("base_market_value"))

	var min_size = fish.get("min_size")
	var max_size = fish.get("max_size")
	if min_size and max_size:
		details.append("📏 %.1f-%.1f cm" % [min_size, max_size])

	if details.size() > 0:
		var details_label = Label.new()
		details_label.text = " • ".join(details)
		details_label.add_theme_font_size_override("font_size", 18)
		details_label.modulate = Color.LIGHT_GRAY
		fish_info.add_child(details_label)

func _get_rarity_string(rarity_int: int) -> String:
	"""Convertir rareza numérica a string"""
	match rarity_int:
		0:
			return "común"
		1:
			return "poco común"
		2:
			return "raro"
		3:
			return "épico"
		4:
			return "legendario"
		_:
			return ""

func _get_rarity_color(rarity: String) -> Color:
	"""Obtener color según rareza"""
	match rarity.to_lower():
		"común":
			return Color.WHITE
		"poco común":
			return Color.LIME_GREEN
		"raro":
			return Color.DODGER_BLUE
		"épico":
			return Color.PURPLE
		"legendario":
			return Color.GOLD
		_:
			return Color.WHITE

func _get_rarity_emoji(rarity: String) -> String:
	"""Obtener emoji según rareza"""
	match rarity.to_lower():
		"común":
			return "⚪"
		"poco común":
			return "🟢"
		"raro":
			return "🔵"
		"épico":
			return "🟣"
		"legendario":
			return "🟡"
		_:
			return "⚪"

func _on_close_requested() -> void:
	"""Manejar cierre del diálogo"""
	hide()

func _adjust_size_to_content() -> void:
	"""Ajustar el tamaño del diálogo al contenido"""
	# Para Window, simplemente asegurar que esté centrado
	popup_centered()
