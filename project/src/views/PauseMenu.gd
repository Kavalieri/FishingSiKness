class_name PauseMenu
extends BaseWindow

# Señales que este menú puede emitir.
signal resume_requested()
signal settings_requested()
signal exit_to_desktop_requested()

# --- NODOS DE LA ESCENA (se asignarán en el editor) ---
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var save_and_exit_button: Button = %SaveAndExitButton # Para ocultar
@onready var exit_to_desktop_button: Button = %ExitToDesktopButton
@onready var save_manager_button: Button = %SaveManagerButton

func _setup_content() -> void:
	# Conectar las señales de los botones a las funciones de este script.
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_to_desktop_button.pressed.connect(_on_exit_to_desktop_pressed)
	save_manager_button.pressed.connect(_on_save_manager_pressed)

	# Ocultar el botón "Salir al Menú" ya que no lo queremos
	save_and_exit_button.visible = false

	# Cambiar el texto de los botones para mayor claridad
	resume_button.text = "Reanudar"
	settings_button.text = "Opciones"
	exit_to_desktop_button.text = "Guardar y Salir"
	save_manager_button.text = "Gestor de Partidas"

func _on_save_manager_pressed() -> void:
	# Instanciar SaveManagerView y conectar señales
	var save_manager = SaveManagerView.new()
	get_tree().root.add_child(save_manager)
	save_manager.setup_menu()

	# Conectar señales del SaveManager
	save_manager.save_loaded.connect(_on_save_loaded)
	save_manager.save_created.connect(_on_save_created)

	# Conectar señal para cuando se cierre el gestor
	save_manager.tree_exiting.connect(_on_save_manager_closed)

	# Cerrar el menú de pausa temporalmente
	hide()

func _on_save_manager_closed():
	"""Callback cuando se cierra el SaveManager"""
	# Mostrar el menú de pausa de nuevo si aún existe
	if is_inside_tree():
		show()

func _on_save_loaded(slot: int):
	"""Callback cuando se carga una partida"""
	print("Partida cargada desde slot %d" % slot)
	# Cerrar menú de pausa y continuar juego
	close()

func _on_save_created(slot: int):
	"""Callback cuando se crea una nueva partida"""
	print("Nueva partida creada en slot %d" % slot)
	# Cerrar menú de pausa y continuar juego
	close()

func show_message(text: String):
	"""Mostrar mensaje temporal"""
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(label.queue_free)

func _on_save_manager_back():
	show()


func _input(event: InputEvent) -> void:
	# Permitir cerrar el menú de pausa con la tecla ESC.
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_resume_pressed() -> void:
	resume_requested.emit()
	close()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_exit_to_desktop_pressed() -> void:
	# Auto-guardar en el slot actual antes de salir del juego
	print("💾 Auto-guardando partida en slot %d antes de salir..." % Save.current_save_slot)
	if Save and Save.has_valid_game_data():
		Save.save_to_slot(Save.current_save_slot)
		Save.save_last_used_slot()
		print("✅ Partida guardada automáticamente en slot %d" % Save.current_save_slot)
	else:
		print("⚠️ No hay datos válidos para guardar")

	exit_to_desktop_requested.emit()

# Sobrescribir la función close para emitir la señal de reanudar.
# Esto asegura que si se cierra con ESC, el juego también se reanude.
func close():
	resume_requested.emit()
	super.close()
