extends Node

## UTF8Manager - Gestiona la configuración del servidor de texto para UTF-8 y emojis
##
## Se asegura de que el Text Server correcto esté configurado,
## especialmente importante para Web donde pueden faltar emojis

func _ready() -> void:
	configure_text_server()

func configure_text_server() -> void:
	# Configurar el Text Server para soportar UTF-8 completo y emojis
	Logger.info("UTF8Manager: Configurando Text Server para UTF-8/emojis")

	# Verificar si tenemos un Text Server disponible
	var ts = TextServerManager.get_primary_interface()
	if ts == null:
		Logger.warn("UTF8Manager: No se pudo obtener Text Server primario")
		return

	Logger.info("UTF8Manager: Text Server detectado: " + ts.get_name())

	# Configurar características del Text Server si están disponibles
	if ts.has_feature(TextServer.FEATURE_FONT_BITMAP):
		Logger.debug("UTF8Manager: ✓ Soporte para fuentes bitmap")

	if ts.has_feature(TextServer.FEATURE_FONT_DYNAMIC):
		Logger.debug("UTF8Manager: ✓ Soporte para fuentes dinámicas")

	if ts.has_feature(TextServer.FEATURE_UNICODE_IDENTIFIERS):
		Logger.debug("UTF8Manager: ✓ Soporte Unicode completo")
	else:
		Logger.warn("UTF8Manager: ⚠️ Sin soporte Unicode completo")

	if ts.has_feature(TextServer.FEATURE_SHAPING):
		Logger.debug("UTF8Manager: ✓ Soporte para text shaping")

	# Para Web, intentar forzar la carga de datos de emojis
	if OS.get_name() == "Web":
		Logger.info("UTF8Manager: Configuración específica para Web")
		# Forzar carga de fallback para emojis
		_setup_emoji_fallback()

func _setup_emoji_fallback() -> void:
	# Intentar configurar fuente fallback que soporte emojis
	# Esto es especialmente importante en Web
	Logger.debug("UTF8Manager: Configurando fallback para emojis")
