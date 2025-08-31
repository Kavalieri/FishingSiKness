extends GdUnitTestSuite

# Test de sistema QTE con sprites de peces

var qte_container: QTEContainer
var test_fish_data: Dictionary

func before():
	# Cargar escena QTE
	var qte_scene = load("res://scenes/ui_new/components/QTEContainer.tscn")
	qte_container = qte_scene.instantiate()
	add_child(qte_container)

	# Datos de pez de prueba
	test_fish_data = {
		"name": "sardina",
		"id": "sardina",
		"value": 50,
		"rarity": "común"
	}

func after():
	if qte_container:
		qte_container.queue_free()
		qte_container = null

func test_qte_container_exists():
	assert_that(qte_container).is_not_null()
	assert_that(qte_container.has_signal("qte_success")).is_true()
	assert_that(qte_container.has_signal("qte_failed")).is_true()

func test_fish_sprite_loading():
	# Verificar que los sprites de peces se pueden cargar
	var fish_sprite = ResourceLoader.load("res://art/fish/sardina.png", "Texture2D")
	assert_that(fish_sprite).is_not_null()
	assert_that(fish_sprite is Texture2D).is_true()

func test_qte_with_fish_sprite():
	# Test del QTE con sprite de pez
	var fish_sprite = ResourceLoader.load("res://art/fish/sardina.png", "Texture2D")
	assert_that(fish_sprite).is_not_null()

	# Iniciar QTE con el sprite
	qte_container.start_qte(
		QTEContainer.QTEType.PRESS_BUTTON,
		3.0,
		1,
		fish_sprite,
		"¡Presiona para capturar la sardina!"
	)

	# Verificar que el QTE está activo y visible
	assert_that(qte_container.is_active).is_true()
	assert_that(qte_container.visible).is_true()

	# Verificar que el sprite está configurado
	var qte_icon = qte_container.get_node("AspectRatioContainer/QTEPanel/MarginContainer/VBoxContainer/QTEIcon")
	assert_that(qte_icon.texture).is_not_null()
	assert_that(qte_icon.texture).is_equal(fish_sprite)

func test_all_fish_sprites_exist():
	# Verificar que todos los sprites de peces existen
	var fish_names = ["sardina", "trucha", "salmon", "lubina", "calamar", "cangrejo", "langosta", "mantaraya", "pezglobo", "pulpo"]

	for fish_name in fish_names:
		var sprite_path = "res://art/fish/%s.png" % fish_name
		var sprite = ResourceLoader.load(sprite_path, "Texture2D")
		assert_that(sprite).is_not_null().override_failure_message(
			"El sprite para %s no se pudo cargar desde %s" % [fish_name, sprite_path]
		)

func test_content_system_includes_sprites():
	# Verificar que el sistema Content incluye sprites
	if not Content:
		skip_test("Content system no está disponible")
		return

	# Esperar a que Content termine de cargar
	if not Content.catalogs.has("fish"):
		await Content.content_loaded

	var fish_data = Content.get_random_fish_for_zone("orilla")
	if fish_data.is_empty():
		skip_test("No se pudo obtener datos de pez")
		return

	# Verificar que incluye el icono
	assert_that(fish_data.has("icon")).is_true()
	if fish_data.has("icon"):
		assert_that(fish_data["icon"]).is_not_null()

func test_qte_timing_mechanics():
	# Test de mecánicas de timing del QTE
	var fish_sprite = ResourceLoader.load("res://art/fish/sardina.png", "Texture2D")

	qte_container.start_qte(
		QTEContainer.QTEType.PRESS_BUTTON,
		2.0, # 2 segundos
		1,
		fish_sprite,
		"Test timing"
	)

	# Simular tiempo transcurrido
	await get_tree().create_timer(0.5).timeout

	# El QTE debe seguir activo
	assert_that(qte_container.is_active).is_true()

	# Verificar progreso
	var progress_bar = qte_container.get_node("AspectRatioContainer/QTEPanel/MarginContainer/VBoxContainer/QTEProgress")
	assert_that(progress_bar.value).is_greater(0.0)

func test_qte_success_animation():
	# Test de animación de éxito
	var fish_sprite = ResourceLoader.load("res://art/fish/sardina.png", "Texture2D")
	var success_signaled = false

	qte_container.qte_success.connect(func(): success_signaled = true)

	qte_container.start_qte(
		QTEContainer.QTEType.PRESS_BUTTON,
		3.0,
		1,
		fish_sprite,
		"Test success"
	)

	# Simular entrada exitosa
	var input_event = InputEventKey.new()
	input_event.keycode = KEY_ENTER
	input_event.pressed = true

	# Simular timing correcto (70% del tiempo)
	await get_tree().create_timer(2.1).timeout # 70% de 3 segundos
	qte_container._input(input_event)

	# Esperar un poco para la animación
	await get_tree().create_timer(0.1).timeout

	# Verificar que se emitió la señal de éxito
	assert_that(success_signaled).is_true()
