extends Node

# Singleton para manejar el reemplazo sistemático de emojis por imágenes PNG
# Proporciona mapeo consistente y funciones de ayuda para toda la aplicación

# Mapeo de emojis a rutas de imágenes
const EMOJI_MAP = {
	# TopBar y UI principal
	"COINS": "res://art/ui/assets/diamond.png", # Temporal, luego cambiar por moneda
	"GEMS": "res://art/ui/assets/diamond.png",
	"ZONE": "res://art/ui/assets/world.png", # Temporal para zona
	"OPTIONS": "res://art/ui/assets/placeholder.png",
	"STAR": "res://art/ui/assets/star.png",

	# Pestañas del menú inferior
	"FISH": "res://art/ui/tabs/tab_fishing.png",
	"SHOP": "res://art/ui/tabs/tab_market.png",
	"UP": "res://art/ui/tabs/tab_upgrades.png",
	"MAP": "res://art/ui/tabs/tab_zones.png",
	"STAR": "res://art/ui/tabs/tab_prestige.png", # Conflicto con star general

	# Elementos de juego
	"TARGET": "res://art/ui/assets/placeholder.png",
	"FIRE": "res://art/ui/assets/fire.png",
	"IDEA": "res://art/ui/assets/placeholder.png",
	"USER": "res://art/ui/assets/man.png",
	"ERROR": "res://art/ui/assets/placeholder.png",
	"OK": "res://art/ui/assets/placeholder.png",
	"GAME": "res://art/ui/assets/placeholder.png",
	"CHART": "res://art/ui/assets/update.png",
	"DATE": "res://art/ui/assets/placeholder.png",
	"SIZE": "res://art/ui/assets/placeholder.png",
	"MAP": "res://art/ui/assets/map-zones.png",
	"ALERT": "res://art/ui/assets/placeholder.png",
	"TOOLS": "res://art/ui/assets/placeholder.png",
	"REFRESH": "res://art/ui/assets/placeholder.png",
	"WRENCH": "res://art/ui/assets/placeholder.png",

	# Emojis específicos de splash/tips
	"SPARKLE": "res://art/ui/assets/star.png", # Para el mensaje de continuar
	"CELEBRATION": "res://art/ui/assets/explosion.png",
	"IDEA": "res://art/ui/assets/think.png",
	"CROWN": "res://art/ui/assets/crown.png",
	"HEART": "res://art/ui/assets/heart.png",
	"KISS": "res://art/ui/assets/heart2.png",
	"RUN": "res://art/ui/assets/speed.png",
	"SHIRT": "res://art/ui/assets/shirt.png",
	"TALK": "res://art/ui/assets/talk.png",
	"CRY": "res://art/ui/assets/tear.png"
}

# Función para obtener ruta de imagen para emoji
func get_image_path_for_emoji(emoji: String) -> String:
	return EMOJI_MAP.get(emoji, "res://art/ui/assets/placeholder.png")

# Función para crear un TextureRect con el emoji reemplazado
func create_icon_for_emoji(emoji: String, size: Vector2 = Vector2(24, 24)) -> TextureRect:
	var texture_rect = TextureRect.new()
	var image_path = get_image_path_for_emoji(emoji)

	var texture = load(image_path)
	if texture:
		texture_rect.texture = texture
		texture_rect.custom_minimum_size = size
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		push_warning("No se pudo cargar imagen para emoji: " + emoji + " en: " + image_path)

	return texture_rect

# Función para crear texto sin emojis (para casos donde no queremos íconos)
func remove_emoji_from_text(text: String) -> String:
	var clean_text = text
	for emoji in EMOJI_MAP.keys():
		clean_text = clean_text.replace(emoji, "")
	# Limpiar espacios extra
	clean_text = clean_text.strip_edges()
	clean_text = clean_text.replace("  ", " ")
	return clean_text

# Función para verificar si un texto contiene emojis
func has_emojis(text: String) -> bool:
	for emoji in EMOJI_MAP.keys():
		if text.contains(emoji):
			return true
	return false

# Función para listar todos los emojis encontrados en un texto
func get_emojis_in_text(text: String) -> Array:
	var found_emojis = []
	for emoji in EMOJI_MAP.keys():
		if text.contains(emoji):
			found_emojis.append(emoji)
	return found_emojis
