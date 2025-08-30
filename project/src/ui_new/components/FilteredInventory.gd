class_name FilteredInventory
extends Control

# Inventario filtrado reutilizable según especificación

signal inventory_closed
signal item_used(item_data: Dictionary)
signal item_sold(item_data: Dictionary)

enum FilterType {
	ALL,
	FISH,
	EQUIPMENT,
	ITEMS
}

enum SortType {
	NAME,
	RARITY,
	VALUE,
	QUANTITY
}

var inventory_items: Array[Dictionary] = []
var filtered_items: Array[Dictionary] = []
var selected_item: Dictionary = {}
var current_filter: FilterType = FilterType.ALL
var current_sort: SortType = SortType.NAME

@onready var title_label: Label = $VBoxContainer/Header/Title
@onready var close_button: Button = $VBoxContainer/Header/CloseButton
@onready var search_line: LineEdit = $VBoxContainer/FiltersContainer/SearchContainer/SearchLine
@onready var all_button: Button = $VBoxContainer/FiltersContainer/FilterButtons/AllButton
@onready var fish_button: Button = $VBoxContainer/FiltersContainer/FilterButtons/FishButton
@onready var equipment_button: Button = $VBoxContainer/FiltersContainer/FilterButtons / \
	EquipmentButton
@onready var items_button: Button = $VBoxContainer/FiltersContainer/FilterButtons/ItemsButton
@onready var sort_option: OptionButton = $VBoxContainer/SortContainer/SortOption
@onready var item_count: Label = $VBoxContainer/SortContainer/ItemCount
@onready var inventory_grid: GridContainer = $VBoxContainer/InventoryScroll/InventoryGrid
@onready var selected_icon: TextureRect = $VBoxContainer/Footer/SelectedInfo/SelectedContainer / \
	SelectedIcon
@onready var selected_name: Label = $VBoxContainer/Footer/SelectedInfo/SelectedContainer / \
	SelectedDetails / SelectedName
@onready var selected_description: Label = $VBoxContainer/Footer/SelectedInfo/SelectedContainer / \
	SelectedDetails / SelectedDescription
@onready var use_button: Button = $VBoxContainer/Footer/ActionButtons/UseButton
@onready var sell_button: Button = $VBoxContainer/Footer/ActionButtons/SellButton

func _ready() -> void:
	_connect_signals()
	_setup_initial_state()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	search_line.text_changed.connect(_on_search_text_changed)
	all_button.toggled.connect(_on_filter_toggled.bind(FilterType.ALL))
	fish_button.toggled.connect(_on_filter_toggled.bind(FilterType.FISH))
	equipment_button.toggled.connect(_on_filter_toggled.bind(FilterType.EQUIPMENT))
	items_button.toggled.connect(_on_filter_toggled.bind(FilterType.ITEMS))
	sort_option.item_selected.connect(_on_sort_changed)
	use_button.pressed.connect(_on_use_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

func _setup_initial_state() -> void:
	_clear_selection()
	_update_item_count()

func setup_inventory(items: Array[Dictionary], title: String = "Inventario") -> void:
	"""Configurar inventario con datos específicos"""
	title_label.text = title
	inventory_items = items
	_apply_filters()

func _apply_filters() -> void:
	"""Aplicar filtros y ordenamiento actual"""
	filtered_items.clear()

	var search_text = search_line.text.to_lower()

	for item in inventory_items:
		# Filtro por tipo
		if not _item_matches_filter(item):
			continue

		# Filtro por búsqueda
		if search_text != "" and not item.get("name", "").to_lower().contains(search_text):
			continue

		filtered_items.append(item)

	_sort_items()
	_refresh_grid()
	_update_item_count()

func _item_matches_filter(item: Dictionary) -> bool:
	"""Verificar si un objeto coincide con el filtro actual"""
	match current_filter:
		FilterType.ALL:
			return true
		FilterType.FISH:
			return item.get("type", "") == "fish"
		FilterType.EQUIPMENT:
			return item.get("type", "") == "equipment"
		FilterType.ITEMS:
			return item.get("type", "") == "item"
		_:
			return true

func _sort_items() -> void:
	"""Ordenar objetos según criterio actual"""
	match current_sort:
		SortType.NAME:
			filtered_items.sort_custom(func(a, b): return a.get("name", "") < b.get("name", ""))
		SortType.RARITY:
			filtered_items.sort_custom(func(a, b): return a.get("rarity", 0) > b.get("rarity", 0))
		SortType.VALUE:
			filtered_items.sort_custom(func(a, b): return a.get("value", 0) > b.get("value", 0))
		SortType.QUANTITY:
			filtered_items.sort_custom(func(a, b):
				return a.get("quantity", 0) > b.get("quantity", 0))

func _refresh_grid() -> void:
	"""Actualizar grilla de objetos"""
	# Limpiar objetos existentes
	for child in inventory_grid.get_children():
		child.queue_free()

	# Crear botones para objetos filtrados
	for item in filtered_items:
		var item_card = _create_item_card(item)
		inventory_grid.add_child(item_card)

const CARD_SCENE = preload("res://scenes/ui_new/components/Card.tscn")

func _create_item_card(item_data: Dictionary) -> Control:
	"""Crear tarjeta de objeto reutilizando Card"""
	var card = CARD_SCENE.instantiate()

	# Configurar tarjeta
	card.setup_card(
		item_data.get("name", ""),
		item_data.get("description", ""),
		item_data.get("icon", null),
		"x%d" % item_data.get("quantity", 1)
	)

	# Conectar selección
	card.action_pressed.connect(_on_item_selected.bind(item_data))

	return card

func _update_item_count() -> void:
	"""Actualizar contador de objetos"""
	var total_items = inventory_items.size()
	var filtered_count = filtered_items.size()
	item_count.text = "%d/%d objetos" % [filtered_count, total_items]

func _clear_selection() -> void:
	"""Limpiar selección actual"""
	selected_item.clear()
	selected_icon.texture = null
	selected_name.text = "Ningún objeto seleccionado"
	selected_description.text = "Selecciona un objeto para ver detalles"
	use_button.disabled = true
	sell_button.disabled = true

func _on_close_pressed() -> void:
	inventory_closed.emit()

func _on_search_text_changed(_text: String) -> void:
	_apply_filters()

func _on_filter_toggled(filter_type: FilterType, pressed: bool) -> void:
	if not pressed:
		return

	current_filter = filter_type

	# Asegurar que solo un filtro esté activo
	all_button.button_pressed = (filter_type == FilterType.ALL)
	fish_button.button_pressed = (filter_type == FilterType.FISH)
	equipment_button.button_pressed = (filter_type == FilterType.EQUIPMENT)
	items_button.button_pressed = (filter_type == FilterType.ITEMS)

	_apply_filters()

func _on_sort_changed(index: int) -> void:
	current_sort = index as SortType
	_apply_filters()

func _on_item_selected(item_data: Dictionary) -> void:
	"""Manejar selección de objeto"""
	selected_item = item_data

	# Actualizar información de selección
	selected_icon.texture = item_data.get("icon", null)
	selected_name.text = item_data.get("name", "")
	selected_description.text = item_data.get("description", "")

	# Habilitar botones según tipo de objeto
	var can_use = item_data.get("usable", false)
	var can_sell = item_data.get("sellable", true)

	use_button.disabled = not can_use
	sell_button.disabled = not can_sell

func _on_use_pressed() -> void:
	if selected_item.is_empty():
		return
	item_used.emit(selected_item)

func _on_sell_pressed() -> void:
	if selected_item.is_empty():
		return
	item_sold.emit(selected_item)
