class_name BaseWindow
extends Control

## BaseWindow - La clase base para TODAS las ventanas flotantes del juego.
##
## RESPONSABILIDADES:
## - Gobernar una escena pre-hecha (`BaseWindow.tscn` o una que herede de ella).
## - Comunicarse con FloatingWindowManager para abrirse y cerrarse.
## - Proveer a sus clases hijas con referencias a nodos clave (ej. ContentContainer).
## - Manejar las señales básicas como el botón de cerrar.
##
## NO HACE:
## - No crea nodos programáticamente. El diseño visual se hace en el editor.

# Señal emitida cuando la ventana está a punto de cerrarse.
signal window_closing()

# Referencias a los nodos que DEBEN existir en la escena que usa este script.
# Se conectan en el editor o mediante %NodosUnicos en _ready().
@onready var window_panel: PanelContainer = %WindowPanel
@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton
@onready var content_container: VBoxContainer = %ContentContainer
@onready var dim_background: ColorRect = $DimBackground

# Configuración que será pasada por el FloatingWindowManager al abrirse.
var config: Dictionary = {
	"title": "Default Title"
}


func _ready() -> void:
	# Asegurarse de que los nodos requeridos existen para evitar errores.
	assert(window_panel != null, "BaseWindow requiere un nodo PanelContainer llamado WindowPanel.")
	assert(title_label != null, "BaseWindow requiere un nodo Label llamado TitleLabel.")
	assert(close_button != null, "BaseWindow requiere un nodo Button llamado CloseButton.")
	assert(content_container != null, "BaseWindow requiere un nodo VBoxContainer llamado ContentContainer.")

	# Conectar la señal del botón de cerrar a nuestra función de cierre.
	close_button.pressed.connect(close)
	dim_background.gui_input.connect(_on_DimBackground_gui_input)


## Abre la ventana. Esta función debe ser llamada por el FloatingWindowManager.
func open(win_config: Dictionary) -> void:
	self.config = win_config
	
	# Aplicar configuración inicial.
	title_label.text = config.get("title", "Error: No Title")
	dim_background.visible = true
	dim_background.mouse_filter = Control.MOUSE_FILTER_STOP

	
	# Lógica adicional de apertura (ej. animaciones) puede ir aquí.
	# Las animaciones se manejarán principalmente en FloatingWindowManager.
	
	# Llamar a un método virtual para que las clases hijas configuren su contenido.
	if has_method("_setup_content"):
		_setup_content()


## Cierra la ventana.
func close() -> void:
	window_closing.emit()
	
	# Le pide al gestor global que nos cierre y elimine.
	if FloatingWindowManager:
		FloatingWindowManager.close_window(self)
	else:
		# Fallback por si el gestor no existe, aunque no debería pasar.
		queue_free()


## METODO VIRTUAL: A ser implementado por las clases que hereden de BaseWindow.
## Aquí es donde cada ventana (Tienda, Inventario, etc.) crea sus propios
## botones, etiquetas y lógica específica y los añade al content_container.
func _setup_content() -> void:
	# Por defecto, no hace nada. Las clases hijas lo sobreescriben.
	pass

func _on_DimBackground_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()