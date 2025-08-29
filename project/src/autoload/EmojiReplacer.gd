extends Node

# Singleton para manejar el reemplazo sistemático de emojis por imágenes PNG
# Proporciona mapeo consistente y funciones de ayuda para toda la aplicación

# Mapeo de emojis a rutas de imágenes
const EMOJI_MAP = {
	# TopBar y UI principal
	"💰": "res://art/ui/assets/diamond.png", # Temporal, luego cambiar por moneda
	"💎": "res://art/ui/assets/diamond.png",
	"🌊": "res://art/ui/assets/world.png", # Temporal para zona
	"⚙️": "res://art/ui/assets/placeholder.png",
	"⭐": "res://art/ui/assets/star.png",

	# Pestañas del menú inferior
	"🐟": "res://art/ui/tabs/tab_fishing.png",
	"🛒": "res://art/ui/tabs/tab_market.png",
	"⬆": "res://art/ui/tabs/tab_upgrades.png",
	"🗺": "res://art/ui/tabs/tab_zones.png",
	"⭐": "res://art/ui/tabs/tab_prestige.png", # Conflicto con star general

	# Elementos de juego
	"🎯": "res://art/ui/assets/placeholder.png",
	"🔥": "res://art/ui/assets/fire.png",
	"💡": "res://art/ui/assets/placeholder.png",
	"👤": "res://art/ui/assets/man.png",
	"❌": "res://art/ui/assets/placeholder.png",
	"✅": "res://art/ui/assets/placeholder.png",
	"🎮": "res://art/ui/assets/placeholder.png",
	"📈": "res://art/ui/assets/update.png",
	"📅": "res://art/ui/assets/placeholder.png",
	"📏": "res://art/ui/assets/placeholder.png",
	"🗺️": "res://art/ui/assets/map-zones.png",
	"🚨": "res://art/ui/assets/placeholder.png",
	"🛠": "res://art/ui/assets/placeholder.png",
	"🔄": "res://art/ui/assets/placeholder.png",
	"🔧": "res://art/ui/assets/placeholder.png",

	# Emojis específicos de splash/tips
	"✨": "res://art/ui/assets/star.png", # Para el mensaje de continuar
	"🎉": "res://art/ui/assets/explosion.png",
	"💡": "res://art/ui/assets/think.png",
	"👑": "res://art/ui/assets/crown.png",
	"❤️": "res://art/ui/assets/heart.png",
	"💋": "res://art/ui/assets/heart2.png",
	"🏃": "res://art/ui/assets/speed.png",
	"👕": "res://art/ui/assets/shirt.png",
	"💬": "res://art/ui/assets/talk.png",
	"😢": "res://art/ui/assets/tear.png"
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
