# BaseFloatingWindow.gd - Clase base para todas las ventanas flotantes
# Proporciona estructura consistente, fondos automáticos y gestión de vida

extends Control

class_name BaseFloatingWindow

@onready var background: NinePatchRect
@onready var content_container: Control
@onready var close_button: Button

# Configuración de la ventana
var window_config: Dictionary = {}

func _ready():
	"""Inicialización base de la ventana flotante"""
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_window_structure()

	# Conectar señales de cierre
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Llamar al setup de contenido de las clases hijas después de que la estructura esté lista
	call_deferred("setup_content")

func setup_window_structure():
	"""Configurar la estructura básica de la ventana según su tipo"""
	var window_type = get_window_type()

	# Obtener configuración del tipo de ventana
	if FloatingWindowManager:
		window_config = FloatingWindowManager.get_window_config(window_type)

	match window_type:
		FloatingWindowManager.WindowType.MODAL:
			create_modal_structure()
		FloatingWindowManager.WindowType.CARD:
			create_card_structure()
		FloatingWindowManager.WindowType.MENU:
			create_menu_structure()
		FloatingWindowManager.WindowType.OPTIONS:
			create_options_structure()
		FloatingWindowManager.WindowType.INVENTORY:
			create_inventory_structure()
		_:
			create_modal_structure() # Fallback por defecto

func create_modal_structure():
	"""Crear estructura para ventana modal"""
	# Panel de fondo semi-transparente
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7) # Fondo oscuro semi-transparente
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Contenedor centrado
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	# Fondo decorativo con TextureRect
	var fondo = TextureRect.new()
	fondo.expand = true
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Seleccionar textura según tipo de ventana (cuadrado, vertical, horizontal)
	var fondo_path = ""
	var window_type = get_window_type()
	match window_type:
		FloatingWindowManager.WindowType.CARD:
			fondo_path = "res://art/ui/fishcard.png" # cuadrado
		FloatingWindowManager.WindowType.MODAL, FloatingWindowManager.WindowType.MENU:
			fondo_path = "res://art/ui/menux.png" # cuadrado
		FloatingWindowManager.WindowType.INVENTORY:
			fondo_path = "res://art/ui/menu_horizontal.png" # horizontal
		FloatingWindowManager.WindowType.OPTIONS:
			fondo_path = "res://art/ui/menu_vertical.png" # vertical
		_:
			fondo_path = "res://art/ui/menux.png"

	var tex = load(fondo_path)
	if tex:
		fondo.texture = tex
	else:
		print("⚠️ No se pudo cargar la textura de fondo: %s" % fondo_path)

	# Tamaño mínimo del fondo
	fondo.custom_minimum_size = Vector2(window_config.get("min_width", 400), window_config.get("min_height", 300))
	center_container.add_child(fondo)

	# Contenedor de contenido centrado sobre el fondo
	var contenido = MarginContainer.new()
	contenido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contenido.add_theme_constant_override("margin_left", 40)
	contenido.add_theme_constant_override("margin_right", 40)
	contenido.add_theme_constant_override("margin_top", 40)
	contenido.add_theme_constant_override("margin_bottom", 40)
	fondo.add_child(contenido)

	# Botón de cerrar (esquina superior derecha, sobre el fondo)
	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_button.position = Vector2(-35, 5)
	fondo.add_child(close_button)

	# VBox para organizar contenido
	var vbox = VBoxContainer.new()
	contenido.add_child(vbox)
	content_container = vbox # Reasignar para que las clases hijas usen el VBox

func create_card_structure():
	"""Crear estructura para tarjeta flotante (esquina)"""
	# Sin overlay, aparece sobre el contenido
	var card_panel = Panel.new()
	var min_width = window_config.get("min_width", 250)
	var min_height = window_config.get("min_height", 150)
	card_panel.custom_minimum_size = Vector2(min_width, min_height)
	card_panel.size = Vector2(min_width, min_height)

	# Posicionar en esquina según configuración - USANDO ANCHORS CORRECTOS
	var corner = window_config.get("corner", "top_right")
	var offset_x = window_config.get("offset_x", 20)
	var offset_y = window_config.get("offset_y", 60) # Más abajo para evitar el TopBar

	match corner:
		"top_left":
			card_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			card_panel.position = Vector2(offset_x, offset_y)
		"top_right":
			card_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			card_panel.position = Vector2(-min_width - offset_x, offset_y)
		"bottom_left":
			card_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
			card_panel.position = Vector2(offset_x, -min_height - offset_y)
		"bottom_right":
			card_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			card_panel.position = Vector2(-min_width - offset_x, -min_height - offset_y)

	add_child(card_panel)

	# Aplicar fondo automático
	apply_background_to_panel(card_panel)

	# Contenedor de contenido
	content_container = MarginContainer.new()
	content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_container.add_theme_constant_override("margin_left", 15)
	content_container.add_theme_constant_override("margin_right", 15)
	content_container.add_theme_constant_override("margin_top", 15)
	content_container.add_theme_constant_override("margin_bottom", 15)
	card_panel.add_child(content_container)

func create_menu_structure():
	"""Crear estructura para menú (similar a modal pero con estilo específico)"""
	create_modal_structure() # Usar estructura modal como base

func create_options_structure():
	"""Crear estructura para ventana de opciones"""
	create_modal_structure() # Usar estructura modal como base

func create_inventory_structure():
	"""Crear estructura para inventario (pantalla completa o lateral)"""
	var layout = window_config.get("layout", "sidebar")

	if layout == "fullscreen":
		create_modal_structure()
	else:
		# Crear barra lateral
		var sidebar_panel = Panel.new()
		sidebar_panel.custom_minimum_size = Vector2(window_config.get("sidebar_width", 300), 0)

		var side = window_config.get("side", "right")
		if side == "left":
			sidebar_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		else:
			sidebar_panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)

		add_child(sidebar_panel)

		# Aplicar fondo automático
		apply_background_to_panel(sidebar_panel)

		# Contenedor de contenido
		content_container = MarginContainer.new()
		content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content_container.add_theme_constant_override("margin_left", 15)
		content_container.add_theme_constant_override("margin_right", 15)
		content_container.add_theme_constant_override("margin_top", 15)
		content_container.add_theme_constant_override("margin_bottom", 15)
		sidebar_panel.add_child(content_container)

func apply_background_to_panel(panel: Panel):
	"""Aplicar fondo decorativo completo usando la textura como marco"""
	if not BackgroundManager:
		print("⚠️ BackgroundManager no disponible para aplicar fondo automático")
		return

	# Determinar qué fondo usar según el tipo de ventana
	var background_key = get_background_key_for_window_type()

	# Cargar textura del marco decorativo
	var texture = BackgroundManager.load_texture("res://art/ui/" + background_key)
	if texture:
		# Crear StyleBoxTexture con configuración específica según el tipo de marco
		var style_box = StyleBoxTexture.new()
		style_box.texture = texture
		style_box.region_rect = Rect2(0, 0, texture.get_width(), texture.get_height())

		# Configurar márgenes específicos según el tipo de ventana/marco
		var window_type = get_window_type()
		match window_type:
			FloatingWindowManager.WindowType.CARD:
				# Para fishcard.png - marco en esquinas, centro azul
				style_box.texture_margin_left = 80
				style_box.texture_margin_right = 80
				style_box.texture_margin_top = 80
				style_box.texture_margin_bottom = 80
			_:
				# Para menu1024x1536ancho.png - marco dorado superior, resto transparente
				style_box.texture_margin_left = 100
				style_box.texture_margin_right = 100
				style_box.texture_margin_top = 120 # Más espacio arriba para el marco dorado
				style_box.texture_margin_bottom = 60 # Menos abajo

		# Aplicar el marco decorativo al panel
		panel.add_theme_stylebox_override("panel", style_box)
		print("✅ Marco decorativo aplicado: %s (tipo: %s)" % [background_key, window_type])
	else:
		print("⚠️ No se pudo cargar la textura del marco: %s" % background_key)

func get_background_key_for_window_type() -> String:
	"""Obtener la clave de fondo apropiada según el tipo de ventana"""
	var window_type = get_window_type()

	match window_type:
		FloatingWindowManager.WindowType.MODAL, FloatingWindowManager.WindowType.MENU:
			return "menu1024x1536ancho.png"
		FloatingWindowManager.WindowType.CARD:
			return "fishcard.png"
		FloatingWindowManager.WindowType.INVENTORY:
			return "menu1024x1536ancho.png"
		FloatingWindowManager.WindowType.OPTIONS:
			return "menu1024x1536ancho.png"
		_:
			return "menu1024x1536ancho.png"

func get_window_type() -> FloatingWindowManager.WindowType:
	"""Método virtual - debe ser implementado por las clases hijas"""
	return FloatingWindowManager.WindowType.MODAL

func _on_close_pressed():
	"""Manejar cierre de ventana"""
	FloatingWindowManager.close_window(self)

func _input(event):
	"""Manejar input global para cerrar con ESC"""
	if event.is_action_pressed("ui_cancel"):
		if FloatingWindowManager and FloatingWindowManager.get_top_window() == self:
			_on_close_pressed()
			get_viewport().set_input_as_handled()

# Métodos virtuales que pueden ser sobreescritos por las clases hijas
func setup_content():
	"""Método virtual para configurar el contenido específico de cada ventana - llamado después de _ready"""
	pass

func on_window_opened():
	"""Llamado cuando la ventana se abre"""
	pass

func on_window_closed():
	"""Llamado cuando la ventana se cierra"""
	pass

func on_window_focus_gained():
	"""Llamado cuando la ventana gana foco"""
	pass

func on_window_focus_lost():
	"""Llamado cuando la ventana pierde foco"""
	pass
