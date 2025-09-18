extends Node

# EmojiReplacer desactivado: stub no-op para evitar dependencias y assets faltantes.
# Todas las funciones devuelven valores neutrales y no realizan reemplazos.

func unicode_to_keyword(_emoji_unicode: String) -> String:
	return ""

func get_image_path_for_unicode_emoji(_emoji_unicode: String) -> String:
	return ""

func replace_unicode_emojis_with_keywords(text: String) -> String:
	return text

func get_image_path_for_emoji(_emoji: String) -> String:
	return ""

func create_icon_for_emoji(_emoji: String, _size: Vector2 = Vector2(24, 24)) -> TextureRect:
	return TextureRect.new()

func remove_emoji_from_text(text: String) -> String:
	return text

func has_emojis(_text: String) -> bool:
	return false

func get_emojis_in_text(_text: String) -> Array:
	return []
