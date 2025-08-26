extends Node

# Lógica de pesca y QTE
class_name FishingSystem

func _ready():
	# Inicialización del sistema de pesca
	pass

# Iniciar minijuego de pesca
var is_fishing = false
var qte_score = 0

func start_fishing():
	is_fishing = true
	qte_score = 0
	SFX.play_event("qte")
	# Inicializar QTE, animar aguja, mostrar barra
	pass

func update_qte(delta):
	if is_fishing:
		# Actualizar posición de aguja y lógica de QTE
		pass

func finish_fishing():
	is_fishing = false
	if qte_score > 0:
		SFX.play_event("capture")
	else:
		SFX.play_event("error")
	# Calcular resultado según qte_score
	return {"score": qte_score"}
