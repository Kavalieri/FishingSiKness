class_name PopupWindow
extends Control

# Ventana emergente base según especificación

signal accepted
signal cancelled
signal closed

@onready var title_label: Label = $CenterContainer/WindowPanel/VBoxContainer/Header/Title
@onready var close_button: Button = $CenterContainer/WindowPanel/VBoxContainer/Header/CloseButton
@onready var content_area: Control = $CenterContainer/WindowPanel/VBoxContainer/Content
@onready var accept_button: Button = $CenterContainer/WindowPanel/VBoxContainer/Footer/AcceptButton
@onready var cancel_button: Button = $CenterContainer/WindowPanel/VBoxContainer/Footer/CancelButton
@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	_connect_signals()
	_setup_initial_state()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	accept_button.pressed.connect(_on_accept_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	overlay.gui_input.connect(_on_overlay_input)

func _setup_initial_state() -> void:
	modulate.a = 0.0
	show_animated()

func show_animated() -> void:
	"""Mostrar ventana con animación"""
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

func hide_animated() -> void:
	"""Ocultar ventana con animación"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func set_title(new_title: String) -> void:
	title_label.text = new_title

func set_content(content_node: Node) -> void:
	"""Establecer contenido de la ventana"""
	for child in content_area.get_children():
		child.queue_free()
	content_area.add_child(content_node)

func set_buttons(accept_text: String = "Aceptar", cancel_text: String = "Cancelar") -> void:
	accept_button.text = accept_text
	cancel_button.text = cancel_text

func hide_cancel_button() -> void:
	cancel_button.visible = false

func _on_close_pressed() -> void:
	closed.emit()
	hide_animated()

func _on_accept_pressed() -> void:
	accepted.emit()
	hide_animated()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide_animated()

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_close_pressed()
