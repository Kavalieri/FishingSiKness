extends Control

func _ready():
	print("MainDebug: Escena principal cargada correctamente.")
	var label = Label.new()
	label.text = "MainDebug: ¡La escena principal está activa!"
	label.add_theme_font_size_override("font_size", 32)
	label.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	add_child(label)
