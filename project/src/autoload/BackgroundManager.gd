extends Node
## Sistema centralizado de gestión de fondos
## Maneja todos los fondos del juego manteniendo aspect ratio y cobertura completa

enum BackgroundType {
	SPLASH,
	ZONE,
	MENU,
	FISHCARD,
	MAIN_FALLBACK
}

# Mapeo de fondos por tipo
const BACKGROUND_PATHS = {
	BackgroundType.SPLASH: "res://art/env/splash.png",
	BackgroundType.MAIN_FALLBACK: "res://art/env/main.png",
	BackgroundType.FISHCARD: "res://art/ui/fishcard-square.png"
}

# Cache de texturas cargadas
var texture_cache: Dictionary = {}

func _ready():
	print("🖼️ BackgroundManager inicializado")
	preload_essential_textures()

func preload_essential_textures():
	"""Precargar texturas esenciales"""
	load_texture(BACKGROUND_PATHS[BackgroundType.SPLASH])
	load_texture(BACKGROUND_PATHS[BackgroundType.MAIN_FALLBACK])
	load_texture(BACKGROUND_PATHS[BackgroundType.FISHCARD])

func load_texture(path: String) -> Texture2D:
	"""Cargar textura con cache"""
	if not path or path == "":
		return null

	if texture_cache.has(path):
		return texture_cache[path]

	var texture = load(path) as Texture2D
	if texture:
		texture_cache[path] = texture
		print("OK Textura cargada:", path)
	else:
		print("⚠️ No se pudo cargar textura:", path)

	return texture

func setup_background(node: Control, bg_type: BackgroundType, zone_id: String = ""):
	"""Configurar fondo en un nodo con escalado perfecto"""
	if not node:
		print("⚠️ BackgroundManager: Nodo inválido")
		return false

	var texture_path = get_background_path(bg_type, zone_id)
	var texture = load_texture(texture_path)

	if not texture:
		print("⚠️ BackgroundManager: Usando fallback para tipo:", bg_type)
		texture = load_texture(BACKGROUND_PATHS[BackgroundType.MAIN_FALLBACK])

	return apply_background_texture(node, texture)

func get_background_path(bg_type: BackgroundType, zone_id: String = "") -> String:
	"""Obtener ruta de fondo según tipo y contexto"""
	match bg_type:
		BackgroundType.SPLASH:
			return BACKGROUND_PATHS[BackgroundType.SPLASH]
		BackgroundType.ZONE:
			return get_zone_background_path(zone_id)
		BackgroundType.MENU:
			return get_menu_background_path()
		BackgroundType.FISHCARD:
			return BACKGROUND_PATHS[BackgroundType.FISHCARD]
		BackgroundType.MAIN_FALLBACK:
			return BACKGROUND_PATHS[BackgroundType.MAIN_FALLBACK]
		_:
			return BACKGROUND_PATHS[BackgroundType.MAIN_FALLBACK]

func get_zone_background_path(zone_id: String) -> String:
	"""Obtener fondo de zona desde Content system"""
	if not Content or zone_id == "":
		return BACKGROUND_PATHS[BackgroundType.MAIN_FALLBACK]

	var zone_def = Content.get_zone_by_id(zone_id)
	if zone_def and zone_def.background and zone_def.background != "":
		return str(zone_def.background).replace("res://", "res://")

	return BACKGROUND_PATHS[BackgroundType.MAIN_FALLBACK]

func get_menu_background_path() -> String:
	"""Obtener mejor fondo de menú según resolución"""
	var viewport_size = Engine.get_main_loop().current_scene.get_viewport().get_visible_rect().size
	var is_landscape = viewport_size.x > viewport_size.y
	var is_large = max(viewport_size.x, viewport_size.y) >= 1200

	# Determinar el mejor menú según tamaño y orientación
	if is_landscape:
		if is_large:
			return "res://art/ui/menu1536x1024grande.png"
		else:
			return "res://art/ui/menu1536x1024pequeño.png"
	else:
		if is_large:
			return "res://art/ui/menu1024x1536ancho.png"
		else:
			return "res://art/ui/menu1024x1536estrecho.png"

func apply_background_texture(node: Control, texture: Texture2D) -> bool:
	"""Aplicar textura a un nodo con escalado perfecto"""
	if not texture or not node:
		return false

	# Buscar nodo de fondo existente o crear uno nuevo
	var background_node = find_background_node(node)
	if not background_node:
		background_node = create_background_node(node)

	# Configurar textura con escalado perfecto
	if background_node is TextureRect:
		background_node.texture = texture
		background_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background_node.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	elif background_node is NinePatchRect:
		background_node.texture = texture
		background_node.patch_margin_left = 0
		background_node.patch_margin_right = 0
		background_node.patch_margin_top = 0
		background_node.patch_margin_bottom = 0

	print("OK Fondo aplicado:", texture.resource_path if texture.resource_path else "texture")
	return true

func find_background_node(parent: Control) -> Control:
	"""Buscar nodo de fondo existente"""
	for child in parent.get_children():
		var is_background_node = (child is TextureRect or child is ColorRect or child is NinePatchRect)
		if child.name.to_lower().contains("background") and is_background_node:
			return child
	return null

func create_background_node(parent: Control) -> TextureRect:
	"""Crear nuevo nodo de fondo"""
	var background = TextureRect.new()
	background.name = "Background"
	background.layout_mode = 1
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	# Insertar al principio para que esté detrás
	parent.add_child(background)
	parent.move_child(background, 0)

	return background

func setup_zone_background(node: Control, zone_id: String):
	"""Configurar fondo de zona específica"""
	setup_background(node, BackgroundType.ZONE, zone_id)

func setup_splash_background(node: Control):
	"""Configurar fondo de splash screen"""
	setup_background(node, BackgroundType.SPLASH)

func setup_menu_background(node: Control):
	"""Configurar fondo de menú flotante"""
	setup_background(node, BackgroundType.MENU)

func setup_fishcard_background(node: Control):
	"""Configurar fondo de tarjeta de pez"""
	setup_background(node, BackgroundType.FISHCARD)

func setup_main_background(node: Control):
	"""Configurar fondo principal/fallback"""
	setup_background(node, BackgroundType.MAIN_FALLBACK)

func convert_to_texture_background(color_rect: ColorRect, texture: Texture2D) -> TextureRect:
	"""Convertir ColorRect a TextureRect manteniendo posición"""
	if not color_rect or not texture:
		return null

	var parent = color_rect.get_parent()
	if not parent:
		return null

	var old_index = color_rect.get_index()
	var old_layout = color_rect.layout_mode
	var old_anchors = {
		"left": color_rect.anchor_left,
		"top": color_rect.anchor_top,
		"right": color_rect.anchor_right,
		"bottom": color_rect.anchor_bottom
	}

	# Crear nuevo TextureRect
	var texture_rect = TextureRect.new()
	texture_rect.name = color_rect.name
	texture_rect.layout_mode = old_layout
	texture_rect.anchor_left = old_anchors.left
	texture_rect.anchor_top = old_anchors.top
	texture_rect.anchor_right = old_anchors.right
	texture_rect.anchor_bottom = old_anchors.bottom
	texture_rect.texture = texture
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	# Reemplazar
	color_rect.queue_free()
	parent.add_child(texture_rect)
	parent.move_child(texture_rect, old_index)

	return texture_rect

func clear_texture_cache():
	"""Limpiar cache de texturas"""
	texture_cache.clear()
	print("🗑️ Cache de texturas limpiado")
