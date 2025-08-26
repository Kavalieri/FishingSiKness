class_name InventoryPanelMain
extends ColorRect

signal fish_selected(fish_index: int)
signal fish_deselected(fish_index: int)
signal sell_selected_requested()
signal sell_all_requested()
signal discard_selected_requested()
signal discard_all_requested()
signal close_requested()

# Preload de la escena FishCard
const FishCardScene = preload("res://scenes/ui/FishCard.tscn")
const FishDetailsPopupScene = preload("res://scenes/ui/FishDetailsPopup.tscn")

# Array para guardar referencia a las tarjetas de pescado
var fish_cards: Array = []
var selected_fish_indices: Array[int] = []

# Instancia del popup para mostrar detalles
var details_popup: AcceptDialog = null

# Referencias a UI (se conectan automáticamente desde la escena)
@onready var fish_grid_container: GridContainer = \
	$MainContainer/FishScrollContainer/FishGridContainer
@onready var sell_selected_button: Button = \
	$MainContainer/ActionsContainer/SellSelectedButton
@onready var sell_all_button: Button = \
	$MainContainer/ActionsContainer/SellAllButton
@onready var discard_selected_button: Button = \
	$MainContainer/ActionsContainer/DiscardSelectedButton
@onready var discard_all_button: Button = \
	$MainContainer/ActionsContainer/DiscardAllButton
@onready var close_button: Button = \
	$MainContainer/HeaderContainer/CloseButton

func _ready():
	# Crear el popup de detalles
	details_popup = FishDetailsPopupScene.instantiate()
	add_child(details_popup)

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

	# Añadir algunos peces de prueba para ver el sistema de tarjetas
	_add_test_fish()

	# Conectar señal de cambio de tamaño para recalcular layout
	resized.connect(_on_panel_resized)

	# Cargar el inventario
	call_deferred("refresh_display") # Diferir para asegurar que el layout esté listo

func _on_panel_resized():
	# Recalcular tamaños cuando cambie el tamaño del panel
	call_deferred("refresh_display")

func _add_test_fish():
	# Solo añadir peces de prueba si el inventario está vacío
	if Save.get_inventory().size() == 0:
		print("InventoryPanel: Añadiendo peces de prueba...")

		# Crear instancias de peces para prueba
		var sardina_def = load("res://data/fish/fish_sardina.tres") as FishDef
		var salmon_def = load("res://data/fish/fish_salmon.tres") as FishDef
		var trucha_def = load("res://data/fish/fish_trucha.tres") as FishDef

		if sardina_def:
			var sardina_instance = FishInstance.new(sardina_def, 20.0, "orilla", 1.0)
			Save.add_fish(sardina_instance)

			# Añadir otra sardina para ver el contador
			var sardina_instance2 = FishInstance.new(sardina_def, 18.0, "orilla", 1.0)
			Save.add_fish(sardina_instance2)

		if salmon_def:
			var salmon_instance = FishInstance.new(salmon_def, 45.0, "costa", 1.2)
			Save.add_fish(salmon_instance)

		if trucha_def:
			var trucha_instance = FishInstance.new(trucha_def, 35.0, "lago", 1.1)
			Save.add_fish(trucha_instance)

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
	print("InventoryPanel: Cargando inventario...")
	_clear_cards()
	_calculate_optimal_card_size()
	_load_fish_cards()

func _calculate_optimal_card_size():
	# Calcular el tamaño óptimo de las tarjetas según el espacio disponible
	if not fish_grid_container:
		return

	# Obtener el tamaño del contenedor
	var container_size = fish_grid_container.get_parent().size
	var available_width = container_size.x - 20 # Márgenes

	# 4 columnas con separación de 10px entre ellas
	var separation = 10 * 3 # 3 separaciones entre 4 columnas
	var card_width = (available_width - separation) / 4

	# Ajustar altura proporcionalmente (ratio 1:1.2 aproximadamente)
	var card_height = card_width * 1.2

	# Mínimo y máximo para evitar extremos
	card_width = max(160, min(card_width, 250))
	card_height = max(190, min(card_height, 300))

	# Guardar el tamaño para usar al crear las tarjetas
	set_meta("card_size", Vector2(card_width, card_height))

func _clear_cards():
	# Limpiar tarjetas existentes
	for card in fish_cards:
		if is_instance_valid(card):
			card.queue_free()
	fish_cards.clear()
	selected_fish_indices.clear()

	# Limpiar el contenedor
	for child in fish_grid_container.get_children():
		child.queue_free()

func _load_fish_cards():
	var inventory = Save.get_inventory()

	# Crear una tarjeta para cada pescado individual
	for i in range(inventory.size()):
		var fish_data = inventory[i]
		_create_individual_fish_card(fish_data, i)

func _create_individual_fish_card(fish_data: Dictionary, fish_index: int):
	var card = FishCardScene.instantiate()

	# Aplicar el tamaño calculado dinámicamente
	var card_size = get_meta("card_size", Vector2(180, 200)) as Vector2
	card.custom_minimum_size = card_size

	fish_grid_container.add_child(card)

	# Crear un FishDef temporal desde los datos guardados
	var fish_def = _create_fish_def_from_data(fish_data)

	# Configurar la tarjeta con datos individuales del pescado
	card.setup_individual_card(fish_def, fish_data, fish_index)

	# Guardar el índice para poder identificar qué pez seleccionar
	card.set_meta("fish_index", fish_index)

	# Conectar señales
	card.selection_changed.connect(_on_individual_fish_card_selection_changed)
	card.details_requested.connect(_on_fish_details_requested)

	fish_cards.append(card)

func _create_fish_def_from_data(fish_data: Dictionary) -> FishDef:
	var fish_def = FishDef.new()
	fish_def.id = fish_data.get("id", "unknown")
	fish_def.name = fish_data.get("name", "Pescado")
	fish_def.description = fish_data.get("description", "")
	fish_def.rarity = fish_data.get("rarity", 0)
	fish_def.base_market_value = fish_data.get("value", 10)
	fish_def.species_category = fish_data.get("species_category", "")

	# Cargar sprite del pescado
	var sprite_path = "res://art/fish/%s.png" % fish_def.id
	if ResourceLoader.exists(sprite_path):
		fish_def.sprite = load(sprite_path)

	return fish_def

func _on_individual_fish_card_selection_changed(card: Control, is_selected: bool):
	var fish_index = card.get_meta("fish_index") as int

	if is_selected:
		# Añadir este pescado individual a la selección
		if not selected_fish_indices.has(fish_index):
			selected_fish_indices.append(fish_index)
			fish_selected.emit(fish_index)
	else:
		# Quitar este pescado individual de la selección
		var idx_pos = selected_fish_indices.find(fish_index)
		if idx_pos >= 0:
			selected_fish_indices.remove_at(idx_pos)
			fish_deselected.emit(fish_index)

	_update_buttons_state()

func _on_fish_details_requested(card: Control):
	"""Mostrar detalles completos del pescado en un popup"""
	if details_popup:
		# Obtener tanto el FishDef como los datos de captura
		var fish_def = card.fish_data
		var capture_data = card.individual_fish_data
		details_popup.show_fish_details(fish_def, capture_data)
	else:
		# Fallback a consola si no hay popup disponible
		var details = card.get_fish_details()
		print("=== DETALLES DEL PESCADO ===")
		print(details)
		print("============================")

func _update_buttons_state():
	var has_selection = selected_fish_indices.size() > 0
	if sell_selected_button:
		sell_selected_button.disabled = not has_selection
	if discard_selected_button:
		discard_selected_button.disabled = not has_selection
