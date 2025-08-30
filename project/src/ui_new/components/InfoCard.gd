class_name InfoCard
extends PanelContainer

# Tarjeta informativa emergente según especificación

@onready var title_label: Label = $MarginContainer/VBoxContainer/Title
@onready var image_rect: TextureRect = $MarginContainer/VBoxContainer/Image
@onready var description_label: Label = $MarginContainer/VBoxContainer/Description

func show_info(title: String, description: String, image_path: String = "") -> void:
	"""Mostrar información en la tarjeta"""
	title_label.text = title
	description_label.text = description

	if image_path != "":
		var texture = load(image_path)
		if texture:
			image_rect.texture = texture
			image_rect.visible = true
		else:
			image_rect.visible = false
	else:
		image_rect.visible = false

	# Animación de entrada
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_info() -> void:
	"""Ocultar tarjeta con animación"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
