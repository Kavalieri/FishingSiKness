class_name CentralHostUI
extends Control

# Contenedor central para pantallas dinámicas
# Se encarga de cargar/descargar pantallas según navegación

@onready var screen_root := $MarginContainer/ScreenRoot
var current_screen: Node = null

func _ready() -> void:
	# Pantalla inicial por defecto
	show_screen("res://scenes/screens_new/FishingScreen.tscn")

func show_screen(scene_path: String) -> void:
	"""Mostrar nueva pantalla, eliminando la anterior"""
	_clear_current_screen()
	_load_new_screen(scene_path)

func _clear_current_screen() -> void:
	"""Limpiar pantalla actual"""
	if current_screen:
		current_screen.queue_free()
		current_screen = null

func _load_new_screen(scene_path: String) -> void:
	"""Cargar nueva pantalla desde archivo"""
	var scene_resource = load(scene_path)
	if scene_resource:
		current_screen = scene_resource.instantiate()
		if current_screen:
			screen_root.add_child(current_screen)
			# Asegurar que ocupe todo el espacio disponible
			if current_screen is Control:
				current_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		push_error("No se pudo cargar la pantalla: " + scene_path)

func get_current_screen() -> Node:
	"""Obtener referencia a la pantalla actual"""
	return current_screen
