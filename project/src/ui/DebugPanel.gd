extends Control
class_name DebugPanel

# Panel debug accesible con F1 en PC
var info_label: Label

func _ready():
	info_label = $InfoLabel
	update_info()

func update_info():
	var coins = App.get_coins()
	var gems = App.get_gems()
	var zone = App.get_zone()
	var rng_seed = App.get_rng_seed()
	info_label.text = "Monedas: %s\nGemas: %s\nZona: %s\nRNG Seed: %s" % [coins, gems, zone, rng_seed]

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		visible = !visible
