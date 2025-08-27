extends Node


# Sistema básico de efectos de sonido y vibración
var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var vibration_enabled := true

var sfx_map := {
	"click": preload("res://art/sfx/UIClick_UI Click 33_CB Sounddesign_ACTIVATION2.wav"),
	"success": preload("res://art/sfx/UIMisc_Feedback 36 up_CB Sounddesign_ACTIVATION2.wav"),
	"error": preload("res://art/sfx/Bluezone_BC0303_futuristic_user_interface_alert_003.wav"),
	"qte": preload("res://art/sfx/Bluezone_BC0303_futuristic_user_interface_high_tech_beep_038.wav"),
	"capture": preload("res://art/sfx/UIData_Counter mid 54_CB Sounddesign_ACTIVATION2.wav"),
	"sell": preload("res://art/sfx/Bluezone_BC0303_futuristic_user_interface_transition_006.wav"),
	"upgrade": preload("res://art/sfx/Bluezone_BC0303_futuristic_user_interface_data_glitch_003.wav")
}

func _ready():
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	music_player = AudioStreamPlayer.new()
	# music_player.stream = preload("res://art/music/background_music.mp3") # Archivo vacío, reemplaza por uno válido
	# music_player.autoplay = true
	# music_player.volume_db = -8
	add_child(music_player)

func play_sfx(stream: AudioStream):
	sfx_player.stream = stream
	sfx_player.play()
	if vibration_enabled:
		vibrate()

func play_event(event: String):
	if sfx_map.has(event):
		play_sfx(sfx_map[event])

func vibrate():
	# Vibración multiplataforma
	# Para gamepad:
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, 0.5, 0.5, 0.2)
	# Para Android, requiere plugin nativo (no disponible por defecto en Godot 4)
	# if OS.has_feature("Android"):
	#     # Requiere implementación nativa o plugin

func set_sfx_volume(volume_linear: float):
	if sfx_player:
		sfx_player.volume_db = linear_to_db(clamp(volume_linear, 0.0, 1.0))
