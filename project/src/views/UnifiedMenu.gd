class_name UnifiedMenuMain
extends ColorRect

# Señales para comunicación con el sistema principal
signal resume_requested()
signal save_and_exit_requested()
signal save_manager_requested()
signal menu_closed()

# Referencias a UI (se conectan automáticamente desde la escena)
@onready var resume_button: Button = $MenuContainer/ResumeButton
@onready var save_button: Button = $MenuContainer/SaveButton
@onready var save_and_exit_button: Button = $MenuContainer/SaveAndExitButton
@onready var close_button: Button = $MenuContainer/CloseButton

func _ready():
	# Conectar señales de los botones de la escena
	if resume_button:
		resume_button.pressed.connect(_on_pause_button_pressed.bind("resume"))
	if save_button:
		save_button.pressed.connect(_on_save_manager_pressed)
	if save_and_exit_button:
		save_and_exit_button.pressed.connect(_on_pause_button_pressed.bind("save_exit"))
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

# Callbacks básicos
func _on_pause_button_pressed(action: String):
	"""Manejar botones del menú"""
	if SFX:
		SFX.play_event("click")

	match action:
		"resume":
			resume_requested.emit()
			queue_free()
		"save_exit":
			save_and_exit_requested.emit()
			queue_free()

func _on_save_manager_pressed():
	"""Abrir gestor de guardado"""
	save_manager_requested.emit()
	if SFX:
		SFX.play_event("click")
	queue_free()

func _on_close_pressed():
	"""Cerrar menú"""
	if SFX:
		SFX.play_event("click")
	menu_closed.emit()
	queue_free()

func _input(event):
	"""Cerrar con ESC"""
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
