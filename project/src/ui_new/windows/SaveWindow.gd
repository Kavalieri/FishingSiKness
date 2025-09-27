extends Control

signal window_closed()

func _ready() -> void:
	# Ocultar contenido hardcodeado del .tscn
	for child in get_children():
		child.visible = false
	
	# Crear SaveManagerView dinámicamente
	var save_manager = preload("res://src/views/SaveManagerView.gd").new()
	save_manager.setup_menu()
	add_child(save_manager)
	
	# Conectar señales
	save_manager.save_loaded.connect(_on_save_loaded)
	save_manager.save_created.connect(_on_save_created)

func _on_save_loaded(slot: int) -> void:
	print("[SaveWindow] Partida cargada desde slot %d" % slot)
	_close_window()

func _on_save_created(slot: int) -> void:
	print("[SaveWindow] Nueva partida creada en slot %d" % slot)
	_close_window()

func _close_window() -> void:
	window_closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_window()
		get_viewport().set_input_as_handled()