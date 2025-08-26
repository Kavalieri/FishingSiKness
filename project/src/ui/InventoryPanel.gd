class_name InventoryPanel
extends ColorRect

signal fish_selected(fish_index: int)
signal fish_deselected(fish_index: int)
signal sell_selected_requested()
signal sell_all_requested()
signal discard_selected_requested()
signal discard_all_requested()
signal close_requested()

# Referencias a UI (se conectan automáticamente desde la escena)
@onready var fish_grid_container: GridContainer = $MainContainer/FishScrollContainer/FishGridContainer
@onready var sell_selected_button: Button = $MainContainer/ActionsContainer/SellSelectedButton
@onready var sell_all_button: Button = $MainContainer/ActionsContainer/SellAllButton
@onready var discard_selected_button: Button = $MainContainer/ActionsContainer/DiscardSelectedButton
@onready var discard_all_button: Button = $MainContainer/ActionsContainer/DiscardAllButton
@onready var close_button: Button = $MainContainer/HeaderContainer/CloseButton

func _ready():
	# Conectar señales de los botones
	if sell_selected_button:
		sell_selected_button.pressed.connect(_on_sell_selected_pressed)
	if sell_all_button:
		sell_all_button.pressed.connect(_on_sell_all_pressed)
	if discard_selected_button:
		discard_selected_button.pressed.connect(_on_discard_selected_pressed)
	if discard_all_button:
		discard_all_button.pressed.connect(_on_discard_all_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

# Callbacks básicos
func _on_sell_selected_pressed():
	sell_selected_requested.emit()

func _on_sell_all_pressed():
	sell_all_requested.emit()

func _on_discard_selected_pressed():
	discard_selected_requested.emit()

func _on_discard_all_pressed():
	discard_all_requested.emit()

func _on_close_pressed():
	close_requested.emit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()

# TODO: Implementar refresh_display() y lógica de inventario
func refresh_display():
	print("InventoryPanel: refresh_display() - TODO implementar")
