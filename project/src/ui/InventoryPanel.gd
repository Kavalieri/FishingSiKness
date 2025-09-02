class_name InventoryPanelMain
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
var sell_all_button: Button
var discard_selected_button: Button
var discard_all_button: Button
var filter_container: HBoxContainer
var select_all_button: Button
var deselect_all_button: Button

func _ready():
	super._ready()

	# Buscar nodos usando find_child para evitar problemas de rutas
	fish_flow_container = find_child("FishFlowContainer", true, false)
	sell_selected_button = find_child("SellSelectedButton", true, false)
	sell_all_button = find_child("SellAllButton", true, false)
	discard_selected_button = find_child("DiscardSelectedButton", true, false)
	discard_all_button = find_child("DiscardAllButton", true, false)
	filter_container = find_child("FilterContainer", true, false)
	select_all_button = find_child("SelectAllButton", true, false)
	deselect_all_button = find_child("DeselectAllButton", true, false)

	# Verificar que todos los nodos necesarios existan
	if not fish_flow_container:
		print("ERROR ERROR: FishFlowContainer no encontrado en InventoryPanel")
		return
	if not sell_selected_button:
		print("ERROR ERROR: SellSelectedButton no encontrado en InventoryPanel")
		return
	if not filter_container:
		print("ERROR ERROR: FilterContainer no encontrado en InventoryPanel")
		return

	print("OK InventoryPanel: Todos los nodos encontrados correctamente")

	# Popups
	details_popup = FishDetailsPopupScene.instantiate()
	add_child(details_popup)
	_create_confirmation_dialog()

	# Conexiones
	_connect_buttons()

	# Conectar al botón de cierre de la BaseWindow
	var base_close_button = get_node_or_null("%CloseButton")
	if base_close_button:
		base_close_button.pressed.connect(_on_close_pressed)

	call_deferred("refresh_display")

func _connect_buttons():
	if sell_selected_button:
		sell_selected_button.pressed.connect(_on_sell_selected_pressed)
	if sell_all_button:
		sell_all_button.pressed.connect(_on_sell_all_pressed)
	if discard_selected_button:
		discard_selected_button.pressed.connect(_on_discard_selected_pressed)
	if discard_all_button:
		discard_all_button.pressed.connect(_on_discard_all_pressed)
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
	UnifiedInventorySystem.sell_items_by_indices(selected_fish_indices)
	refresh_display()

func _on_sell_all_pressed():
	_show_confirmation_dialog(
		"sell_all",
		"¿Vender todo?",
		"¿Estás seguro de que quieres vender TODO el pescado de tu inventario?"
	)

func _on_discard_selected_pressed():
	if selected_fish_indices.is_empty(): return
	UnifiedInventorySystem.remove_items_by_indices(selected_fish_indices)
	refresh_display()

func _on_discard_all_pressed():
	_show_confirmation_dialog(
		"discard_all",
		"¿Descartar todo?",
		"¿Estás seguro de que quieres descartar TODO el pescado? Esta acción no se puede deshacer."
	)

func _on_close_pressed():
	Save.save_game()
	hide()

# --- Diálogo de Confirmación ---

func _create_confirmation_dialog():
	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_autowrap = true
	confirmation_dialog.confirmed.connect(_on_confirmation_confirmed)
	add_child(confirmation_dialog)

func _show_confirmation_dialog(action: String, title: String, text: String):
	_pending_confirmation_action = action
	confirmation_dialog.title = title
	confirmation_dialog.dialog_text = text
	confirmation_dialog.popup_centered()

func _on_confirmation_confirmed():
	match _pending_confirmation_action:
		"sell_all":
			# Obtener todos los índices del inventario de pesca
			var fishing_container = UnifiedInventorySystem.get_fishing_container()
			if fishing_container:
				var all_indices: Array[int] = []
				for i in range(fishing_container.items.size()):
					all_indices.append(i)
				UnifiedInventorySystem.sell_items_by_indices(all_indices)
			refresh_display()
		"discard_all":
			UnifiedInventorySystem.clear_fishing_container()
			refresh_display()
	_pending_confirmation_action = ""

# --- Lógica de Renderizado y Selección ---

func refresh_display():
	_clear_cards()
	_load_fish_cards()
	_update_buttons_state()

func _clear_cards():
	for card in fish_cards:
		if is_instance_valid(card):
			card.queue_free()
	fish_cards.clear()
	selected_fish_indices.clear()

func _load_fish_cards():
	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	if not fishing_container:
		return

	for i in range(fishing_container.items.size()):
		var item_instance = fishing_container.items[i]
		var fish_data = item_instance.to_fish_data()
		if _current_rarity_filter == "All" or fish_data.get("rarity") == _current_rarity_filter:
			_create_individual_fish_card(fish_data, i)

func _create_individual_fish_card(fish_data: Dictionary, fish_index: int):
	if not fish_flow_container:
		print("ERROR ERROR: fish_flow_container is null in _create_individual_fish_card")
		return

	var card = FishCardScene.instantiate()
	card.custom_minimum_size = Vector2(180, 220)
	fish_flow_container.add_child(card)
	var fish_def = FishDataManager.get_fish_def(fish_data.get("id"))
	if not fish_def:
		print("ERROR ERROR: No se pudo obtener fish_def para ID: ", fish_data.get("id"))
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
	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	var has_inventory = fishing_container != null and not fishing_container.items.is_empty()

	if sell_selected_button:
		sell_selected_button.disabled = not has_selection
	if discard_selected_button:
		discard_selected_button.disabled = not has_selection
	if sell_all_button:
		sell_all_button.disabled = not has_inventory
	if discard_all_button:
		discard_all_button.disabled = not has_inventory
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
