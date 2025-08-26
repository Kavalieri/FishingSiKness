class_name FishInfoPanel
extends PanelContainer

signal closed()

var fish_instance: FishInstance
var close_button: Button
var content_container: VBoxContainer

func _ready():
	# Configurar estilo del panel
	modulate = Color(1, 1, 1, 0.95)
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(400, 500)

	setup_ui()

func setup_ui():
	content_container = VBoxContainer.new()
	add_child(content_container)

	# Título y botón cerrar
	var header = HBoxContainer.new()
	content_container.add_child(header)

	var title_label = Label.new()
	title_label.text = "Información del Pez"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 20)
	header.add_child(title_label)

	close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	content_container.add_child(HSeparator.new())

func show_fish_info(fish_inst: FishInstance):
	if not fish_inst or not fish_inst.fish_def:
		return

	fish_instance = fish_inst
	var info = fish_instance.get_display_info()

	# Limpiar contenido anterior
	clear_content()

	# Imagen del pez
	if fish_instance.fish_def.sprite:
		var fish_image = TextureRect.new()
		fish_image.texture = fish_instance.fish_def.sprite
		fish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fish_image.custom_minimum_size = Vector2(120, 80)
		fish_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content_container.add_child(fish_image)

	content_container.add_child(HSeparator.new())

	# Información básica
	add_info_row("Nombre", info.name, fish_instance.get_rarity_color())
	add_info_row("Especie", info.species)
	add_info_row("Rareza", info.rarity, fish_instance.get_rarity_color())

	content_container.add_child(HSeparator.new())

	# Detalles de captura
	add_info_row("Tamaño", info.size)
	add_info_row("Peso", info.weight)
	add_info_row("Zona de captura", info.zone)
	add_info_row("Multiplicador", info.multiplier)
	add_info_row("Precio final", info.price, Color.GOLD)

	if info.capture_time != "":
		content_container.add_child(HSeparator.new())
		add_info_row("Capturado", info.capture_time)

	# Descripción
	if info.description != "":
		content_container.add_child(HSeparator.new())

		var desc_label = Label.new()
		desc_label.text = "Descripción:"
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.modulate = Color.CYAN
		content_container.add_child(desc_label)

		var desc_text = Label.new()
		desc_text.text = info.description
		desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_text.custom_minimum_size.x = 360
		content_container.add_child(desc_text)

	# Mostrar panel
	show()

func add_info_row(label_text: String, value_text: String, color: Color = Color.WHITE):
	var row = HBoxContainer.new()
	content_container.add_child(row)

	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 120
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.modulate = color
	value.add_theme_font_size_override("font_size", 12)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)

func clear_content():
	# Mantener header y separador, limpiar el resto
	var children_to_remove = []
	for i in range(2, content_container.get_child_count()):
		children_to_remove.append(content_container.get_child(i))

	for child in children_to_remove:
		child.queue_free()

func _on_close_pressed():
	hide()
	emit_signal("closed")

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		accept_event()
