@tool
class_name MarketView
extends BaseWindow

# --- Preloads ---
const FishCardScene = preload("res://scenes/ui/FishCard.tscn")
const FishDetailsPopupScene = preload("res://scenes/ui/FishDetailsPopup.tscn")

# --- Variables ---
var fish_cards: Array = []
var selected_fish_indices: Array[int] = []
var details_popup: AcceptDialog = null
var confirmation_dialog: ConfirmationDialog = null
var _current_rarity_filter: String = "All"
var _pending_confirmation_action: String = ""

# --- Referencias a UI ---
var fish_flow_container: HFlowContainer
var sell_selected_button: Button
var filter_container: HBoxContainer
var select_all_button: Button
var deselect_all_button: Button

func _ready():
	super._ready()

	print("🔍 MarketView: Iniciando búsqueda de nodos...")

	# Buscar nodos usando find_child para evitar problemas de rutas
	fish_flow_container = find_child("FishFlowContainer", true, false)
	print("🔍 FishFlowContainer found: ", fish_flow_container != null)

	sell_selected_button = find_child("SellSelectedButton", true, false)
	print("🔍 SellSelectedButton found: ", sell_selected_button != null)

	filter_container = find_child("FilterContainer", true, false)
	print("🔍 FilterContainer found: ", filter_container != null)

	select_all_button = find_child("SelectAllButton", true, false)
	print("🔍 SelectAllButton found: ", select_all_button != null)

	deselect_all_button = find_child("DeselectAllButton", true, false)
	print("🔍 DeselectAllButton found: ", deselect_all_button != null)

	# Verificar que todos los nodos necesarios existan
	if not fish_flow_container:
		print("❌ ERROR: FishFlowContainer no encontrado en MarketView")
		return
	if not sell_selected_button:
		print("❌ ERROR: SellSelectedButton no encontrado en MarketView")
		return
	if not filter_container:
		print("❌ ERROR: FilterContainer no encontrado en MarketView")
		return
	if not select_all_button:
		print("❌ ERROR: SelectAllButton no encontrado en MarketView")
		return
	if not deselect_all_button:
		print("❌ ERROR: DeselectAllButton no encontrado en MarketView")
		return

	print("✅ MarketView: Todos los nodos encontrados correctamente")

	# Popups
	details_popup = FishDetailsPopupScene.instantiate()
	add_child(details_popup)

	# Conexiones
	_connect_buttons()

	# Conectar al botón de cierre de la BaseWindow
	var base_close_button = get_node_or_null("%CloseButton")
	if base_close_button:
		base_close_button.pressed.connect(_on_close_pressed)

	call_deferred("refresh_display") func _connect_buttons():
	if sell_selected_button:
		sell_selected_button.pressed.connect(_on_sell_selected_pressed)
	if select_all_button:
		select_all_button.pressed.connect(_on_select_all_pressed)
	if deselect_all_button:
		deselect_all_button.pressed.connect(_on_deselect_all_pressed)

	if filter_container:
		for button in filter_container.get_children():
			var rarity_filter = button.text.to_lower().capitalize()
			if button.name == "FilterAll": rarity_filter = "All"
			button.pressed.connect(_on_filter_changed.bind(rarity_filter))

# --- Lógica de Botones y Acciones ---

func _on_filter_changed(new_filter: String):
	_current_rarity_filter = new_filter
	refresh_display()

func _on_select_all_pressed():
	for card in fish_cards:
		card.set_selected(true)
	selected_fish_indices.clear()
	for card in fish_cards:
		selected_fish_indices.append(card.get_meta("fish_index"))
	_update_buttons_state()

func _on_deselect_all_pressed():
	for card in fish_cards:
		card.set_selected(false)
	selected_fish_indices.clear()
	_update_buttons_state()

func _on_sell_selected_pressed():
	if selected_fish_indices.is_empty(): return
	InventorySystem.sell_fishes(selected_fish_indices)
	refresh_display()

func _on_close_pressed():
	Save.save_game()
	hide()

# --- Lógica de Renderizado y Selección ---

func refresh_display():
	print("🔄 MarketView: Refreshing display...")
	_clear_cards()
	_load_fish_cards()
	_update_buttons_state()

func _clear_cards():
	print("🧹 MarketView: Clearing ", fish_cards.size(), " cards")
	for card in fish_cards:
		if is_instance_valid(card):
			card.queue_free()
	fish_cards.clear()
	selected_fish_indices.clear()

func _load_fish_cards():
	var inventory = InventorySystem.get_inventory()
	print("🐟 MarketView: Loading fish cards. Inventory size: ", inventory.size())
	for i in range(inventory.size()):
		var fish_data = inventory[i]
		print("🐟 Processing fish ", i, ": ", fish_data.get("name", "Unknown"))
		if _current_rarity_filter == "All" or fish_data.get("rarity") == _current_rarity_filter:
			_create_individual_fish_card(fish_data, i)

func _create_individual_fish_card(fish_data: Dictionary, fish_index: int):
	if not fish_flow_container:
		print("❌ ERROR: fish_flow_container is null in _create_individual_fish_card")
		return

	var card = FishCardScene.instantiate()
	card.custom_minimum_size = Vector2(180, 220)
	fish_flow_container.add_child(card)
	var fish_def = FishDataManager.get_fish_def(fish_data.get("id"))
	if not fish_def:
		print("❌ ERROR: No se pudo obtener fish_def para ID: ", fish_data.get("id"))
		return
	card.setup_individual_card(fish_def, fish_data, fish_index)
	card.set_meta("fish_index", fish_index)
	card.selection_changed.connect(_on_individual_fish_card_selection_changed)
	card.details_requested.connect(_on_fish_details_requested)
	fish_cards.append(card)

func _on_individual_fish_card_selection_changed(card: Control, is_selected: bool):
	var fish_index = card.get_meta("fish_index") as int
	if is_selected:
		if not selected_fish_indices.has(fish_index):
			selected_fish_indices.append(fish_index)
	else:
		var idx_pos = selected_fish_indices.find(fish_index)
		if idx_pos != -1:
			selected_fish_indices.remove_at(idx_pos)
	_update_buttons_state()

func _update_buttons_state():
	var has_selection = not selected_fish_indices.is_empty()
	var has_inventory = not InventorySystem.get_inventory().is_empty()

	if sell_selected_button:
		sell_selected_button.disabled = not has_selection
	if select_all_button:
		select_all_button.disabled = not has_inventory
	if deselect_all_button:
		deselect_all_button.disabled = not has_inventory or not has_selection

func _on_fish_details_requested(card: Control):
	if details_popup:
		details_popup.show_fish_details(card.fish_data, card.individual_fish_data)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
