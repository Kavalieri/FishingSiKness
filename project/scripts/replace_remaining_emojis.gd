@tool
extends EditorScript

# Script para reemplazar emojis Unicode restantes con palabras clave
# Ejecutar desde Editor > Run Script

const TARGET_FILES = [
	"res://src/views/FishingView.gd",
	"res://src/views/SaveManagerView.gd",
	"res://src/windows/CaptureCard.gd",
	"res://src/views/MarketView.gd",
	"res://src/views/MapView.gd",
	"res://src/views/MilestonesPanel.gd",
	"res://src/views/PrestigeView.gd",
	"res://src/views/UpgradesView.gd"
]

# Mapeo completo de emojis Unicode a palabras clave descriptivas
const EMOJI_REPLACEMENTS = {
	# Recursos y monedas
	"💰": "COINS",
	"🪙": "COIN",
	"💎": "GEMS",
	"💵": "MONEY",
	"🏪": "SHOP",

	# Pesca y agua
	"🎣": "FISHING",
	"🐟": "FISH",
	"🌊": "WAVE",
	"🏖️": "BEACH",

	# UI e interacción
	"⚙️": "SETTINGS",
	"🔧": "WRENCH",
	"❌": "CLOSE",
	"✅": "CHECK",
	"🔒": "LOCKED",
	"🔓": "UNLOCKED",
	"📊": "STATS",
	"🎯": "TARGET",
	"⭐": "STAR",
	"🌟": "SPARKLE",
	"💫": "SPARKLES",

	# Acciones y estados
	"🚀": "ROCKET",
	"⏰": "CLOCK",
	"⏱️": "TIMER",
	"⌛": "HOURGLASS",
	"🎉": "CELEBRATION",
	"🎊": "PARTY",
	"✨": "GLITTER",
	"💥": "EXPLOSION",

	# Navegación
	"🏠": "HOME",
	"🗺️": "MAP",
	"📍": "PIN",
	"🧭": "COMPASS",

	# Información
	"ℹ️": "INFO",
	"❗": "EXCLAMATION",
	"⚠️": "WARNING",
	"📝": "NOTE",
	"📋": "CLIPBOARD",

	# Zonas y entornos
	"🏞️": "FOREST",
	"🌅": "SUNSET",
	"🏔️": "MOUNTAIN",
	"🏭": "INDUSTRIAL",
	"🌌": "SPACE",
	"❄️": "SNOW",
	"🏜️": "DESERT",
	"🏰": "DUNGEON",
	"🏙️": "CITY",

	# Gestión de archivos y datos
	"💾": "SAVE",
	"🆕": "NEW",
	"🗑️": "DELETE",
	"📄": "FILE",
	"📁": "FOLDER",

	# Inventario y almacenamiento
	"🧊": "STORAGE",
	"📦": "BOX",
	"🎁": "GIFT",
	"🧳": "CONTAINER",

	# Experiencia y progreso
	"🎖️": "MEDAL",
	"🏆": "TROPHY",
	"📈": "CHART_UP",
	"📉": "CHART_DOWN",
	"🔄": "REFRESH",
	"⚡": "ENERGY",
	"🔋": "BATTERY",

	# Tiempo y progreso
	"⏳": "WAITING",
	"🕐": "TIME",

	# Calidad y rareza
	"🌈": "RAINBOW",
	"💖": "HEART",
	"🔥": "FIRE",

	# Notificaciones y alertas
	"🔔": "BELL",
	"📢": "ANNOUNCE",
	"📣": "MEGAPHONE"
}

func _run():
	print("🔄 Iniciando reemplazo masivo de emojis Unicode...")

	var total_replacements = 0

	for file_path in TARGET_FILES:
		print("📝 Procesando: ", file_path)
		var replacements = process_file(file_path)
		total_replacements += replacements
		if replacements > 0:
			print("  ✅ ", replacements, " emojis reemplazados")
		else:
			print("  ⚪ Sin emojis encontrados")

	print("🎉 COMPLETADO: ", total_replacements, " emojis totales reemplazados")
	print("📋 Archivos procesados: ", TARGET_FILES.size())

func process_file(file_path: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("❌ Error: No se pudo abrir ", file_path)
		return 0

	var content = file.get_as_text()
	file.close()

	var original_content = content
	var replacements_count = 0

	# Reemplazar cada emoji Unicode con su palabra clave
	for emoji in EMOJI_REPLACEMENTS.keys():
		var keyword = EMOJI_REPLACEMENTS[emoji]
		var occurrences = content.count(emoji)
		if occurrences > 0:
			content = content.replace(emoji, keyword)
			replacements_count += occurrences
			print("    ", emoji, " -> ", keyword, " (", occurrences, " veces)")

	# Guardar solo si hubo cambios
	if replacements_count > 0:
		var write_file = FileAccess.open(file_path, FileAccess.WRITE)
		if write_file:
			write_file.store_string(content)
			write_file.close()
		else:
			print("❌ Error: No se pudo escribir ", file_path)

	return replacements_count
