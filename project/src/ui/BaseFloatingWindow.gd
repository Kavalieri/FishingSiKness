class_name BaseFloatingWindow
extends Control
## Clase base para todas las ventanas flotantes
##
## Proporciona:
## - Gestión automática de fondos según tipo
## - Estructura UI estándar
## - Integración con FloatingWindowManager
## - Responsividad automática

signal window_closed()

@export var window_type: FloatingWindowManager.WindowType = FloatingWindowManager.WindowType.MODAL
@export var window_title: String = ""
@export var show_close_button: bool = true
@export var auto_center: bool = true

var background_container: Control
var content_container: Control
var header_container: HBoxContainer
var close_button: Button

func _ready():
	name = get_window_class_name()
	setup_window_structure()
	setup_window_background()
	call_deferred("setup_content")

func get_window_class_name() -> String:
	"""Override en clases hijas para definir el nombre de la ventana"""
	return "BaseFloatingWindow"

func get_window_type() -> FloatingWindowManager.WindowType:
	"""Obtener el tipo de ventana"""
	return window_type

func setup_window_structure():
	"""Crear la estructura básica de la ventana"""
	# Ocupar toda la pantalla
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Contenedor de fondo (será manejado por BackgroundManager)
	background_container = Control.new()
	background_container.name = "BackgroundContainer"
	background_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_container)

	# Contenedor principal del contenido
	create_content_structure()

func create_content_structure():
	"""Crear estructura de contenido según tipo de ventana"""
	match window_type:
		FloatingWindowManager.WindowType.CARD:
			create_card_structure()
		FloatingWindowManager.WindowType.MODAL, \
		FloatingWindowManager.WindowType.MENU, \
		FloatingWindowManager.WindowType.OPTIONS:
			create_modal_structure()
		FloatingWindowManager.WindowType.INVENTORY:
			create_inventory_structure()
		_:
			create_modal_structure() # Fallback

func create_modal_structure():
	"""Estructura para ventanas modales centradas"""
	# Panel principal centrado
	var main_panel = PanelContainer.new()
	main_panel.name = "MainPanel"
	add_child(main_panel)

	# Centrar el panel
	if auto_center:
		center_panel(main_panel)

	# VBox principal
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_panel.add_child(main_vbox)

	# Header con título y botón cerrar
	if window_title != "" or show_close_button:
		create_header(main_vbox)

	# Contenedor de contenido
	content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_container)

func create_card_structure():
	"""Estructura para tarjetas de información"""
	# Panel flotante sin centrar automáticamente
	var card_panel = PanelContainer.new()
	card_panel.name = "CardPanel"
	add_child(card_panel)

	# Contenedor de contenido directo
	content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	card_panel.add_child(content_container)

func create_inventory_structure():
	"""Estructura para ventana de inventario (desde la derecha)"""
	# Panel que ocupa parte de la pantalla
	var inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.anchor_left = 0.3
	inventory_panel.anchor_right = 1.0
	inventory_panel.anchor_top = 0.0
	inventory_panel.anchor_bottom = 1.0
	add_child(inventory_panel)

	# VBox principal
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	inventory_panel.add_child(main_vbox)

	# Header
	if window_title != "" or show_close_button:
		create_header(main_vbox)

	# Contenedor de contenido
	content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_container)

func create_header(parent: VBoxContainer):
	"""Crear header con título y botón cerrar"""
	header_container = HBoxContainer.new()
	header_container.name = "HeaderContainer"
	parent.add_child(header_container)

	# Título
	if window_title != "":
		var title_label = Label.new()
		title_label.text = window_title
		title_label.add_theme_font_size_override("font_size", 24)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_container.add_child(title_label)

	# Botón cerrar
	if show_close_button:
		close_button = Button.new()
		close_button.text = "✕"
		close_button.custom_minimum_size = Vector2(40, 40)
		close_button.pressed.connect(_on_close_pressed)
		header_container.add_child(close_button)

func center_panel(panel: Control):
	"""Centrar un panel en la pantalla con tamaño automático"""
	# Configurar anclas para centrado
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5

	# El tamaño se ajustará automáticamente al contenido
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

func setup_window_background():
	"""Configurar fondo de la ventana según su tipo"""
	if not BackgroundManager:
		return

	match window_type:
		FloatingWindowManager.WindowType.CARD:
			BackgroundManager.setup_fishcard_background(background_container)
		FloatingWindowManager.WindowType.MODAL, \
		FloatingWindowManager.WindowType.MENU, \
		FloatingWindowManager.WindowType.OPTIONS, \
		FloatingWindowManager.WindowType.INVENTORY:
			BackgroundManager.setup_menu_background(background_container)

func setup_content():
	"""Override en clases hijas para configurar contenido específico"""
	print("⚠️ BaseFloatingWindow: setup_content() no implementado en %s" % get_window_class_name())

func open():
	"""Abrir esta ventana usando FloatingWindowManager"""
	if FloatingWindowManager:
		return FloatingWindowManager.open_window(self, window_type)
	else:
		print("⚠️ FloatingWindowManager no disponible")
		return false

func close():
	"""Cerrar esta ventana"""
	if FloatingWindowManager:
		FloatingWindowManager.close_window(self)
	else:
		queue_free()

func _on_close_pressed():
	"""Manejar clic en botón cerrar"""
	window_closed.emit()
	close()

func _input(event):
	"""Manejar input específico de la ventana (opcional)"""
	pass

# Funciones de utilidad para clases hijas

func add_content_child(node: Node):
	"""Añadir un nodo al contenedor de contenido"""
	if content_container:
		content_container.add_child(node)

func create_separator() -> HSeparator:
	"""Crear separador horizontal"""
	var separator = HSeparator.new()
	add_content_child(separator)
	return separator

func create_label(text: String, font_size: int = 16) -> Label:
	"""Crear etiqueta estilizada"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	add_content_child(label)
	return label

func create_button(text: String, callback: Callable) -> Button:
	"""Crear botón estilizado"""
	var button = Button.new()
	button.text = text
	button.pressed.connect(callback)
	add_content_child(button)
	return button

func create_scroll_container() -> ScrollContainer:
	"""Crear contenedor con scroll"""
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_content_child(scroll)
	return scroll
