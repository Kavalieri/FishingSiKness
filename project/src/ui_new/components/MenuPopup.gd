class_name MenuPopup
extends Control

# Menú contextual reutilizable según especificación

signal menu_closed
signal option_selected(option_id: String)

var menu_options: Array[Dictionary] = []

@onready var overlay: ColorRect = $Overlay
@onready var menu_panel: PanelContainer = $MenuPanel
@onready var menu_vbox: VBoxContainer = $MenuPanel/MarginContainer/MenuVBox

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	overlay.gui_input.connect(_on_overlay_input)

func show_menu(position: Vector2, options: Array[Dictionary]) -> void:
	"""
	Mostrar menú en posición específica con opciones
	options: Array of {id: String, text: String, icon: Texture2D, enabled: bool}
	"""
	menu_options = options
	_create_menu_buttons()
	_position_menu(position)

	visible = true
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)

	# Animación de escala
	menu_panel.scale = Vector2(0.9, 0.9)
	tween.parallel().tween_property(menu_panel, "scale", Vector2.ONE, 0.2)

func hide_menu() -> void:
	"""Ocultar menú con animación"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		visible = false
		menu_closed.emit()
	)

func _create_menu_buttons() -> void:
	"""Crear botones del menú basados en las opciones"""
	# Limpiar botones existentes
	for child in menu_vbox.get_children():
		child.queue_free()

	# Crear nuevos botones
	for option in menu_options:
		var button = Button.new()
		button.text = option.get("text", "")
		button.disabled = not option.get("enabled", true)

		# Configurar icono si existe
		if option.has("icon") and option.icon is Texture2D:
			button.icon = option.icon
			button.expand_icon = false

		# Conectar señal
		var option_id = option.get("id", "")
		button.pressed.connect(_on_option_pressed.bind(option_id))

		menu_vbox.add_child(button)

func _position_menu(position: Vector2) -> void:
	"""Posicionar menú ajustándose a los límites de pantalla"""
	# Esperar un frame para que se calculen los tamaños
	await get_tree().process_frame

	var screen_size = get_viewport().get_visible_rect().size
	var menu_size = menu_panel.get_combined_minimum_size()

	# Ajustar posición X
	var final_x = position.x
	if position.x + menu_size.x > screen_size.x:
		final_x = screen_size.x - menu_size.x - 10
	if final_x < 10:
		final_x = 10

	# Ajustar posición Y
	var final_y = position.y
	if position.y + menu_size.y > screen_size.y:
		final_y = position.y - menu_size.y
	if final_y < 10:
		final_y = 10

	menu_panel.position = Vector2(final_x, final_y)

func _on_option_pressed(option_id: String) -> void:
	"""Manejar selección de opción"""
	option_selected.emit(option_id)
	hide_menu()

func _on_overlay_input(event: InputEvent) -> void:
	"""Cerrar menú al hacer clic fuera"""
	if event is InputEventMouseButton and event.pressed:
		hide_menu()
