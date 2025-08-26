extends Node

# Gemas, IAP y ads recompensados
class_name StoreSystem

signal purchase_requested(sku: String)
signal ad_reward_requested(placement: String)
signal purchase_completed(sku: String)
signal reward_granted(id: String)
signal store_error(msg: String)

var ads_shown_today := 0
var last_ad_time := 0
const MAX_ADS_PER_DAY := 10
const AD_COOLDOWN := 600 # segundos (10 min)

func _ready():
	# Inicialización de la tienda
	pass

# Comprar ítem
func purchase(sku: String):
	emit_signal("purchase_requested", sku)

# Procesar recompensa de anuncio
func ad_reward(placement: String):
	if can_show_ad():
		ads_shown_today += 1
		last_ad_time = Time.get_unix_time()
		emit_signal("ad_reward_requested", placement)
		# Simular recompensa
		emit_signal("reward_granted", placement)
	else:
		emit_signal("store_error", "Límite de anuncios o cooldown activo")

func can_show_ad() -> bool:
	if ads_shown_today >= MAX_ADS_PER_DAY:
		return false
	if Time.get_unix_time() - last_ad_time < AD_COOLDOWN:
		return false
	return true
