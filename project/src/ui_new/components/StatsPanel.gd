extends Control

@onready var stats_container: VBoxContainer = $VBoxContainer

var stats_labels: Dictionary = {}

func _ready() -> void:
	_setup_stats_display()
	if StatsTracker:
		StatsTracker.stats_updated.connect(_update_display)
	_update_display()

func _setup_stats_display() -> void:
	var stats_to_show = [
		{"key": "fish_today", "label": "Hoy:", "format": "%d peces"},
		{"key": "value_today", "label": "Valor:", "format": "%d monedas"},
		{"key": "streak", "label": "Racha:", "format": "%d"},
		{"key": "success_rate", "label": "Éxito:", "format": "%s"}
	]
	
	for stat in stats_to_show:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(label)
		stats_labels[stat.key] = {"label": label, "format": stat.format, "text": stat.label}

func _update_display() -> void:
	if not StatsTracker:
		return
	
	var formatted_stats = StatsTracker.get_formatted_stats()
	var today = formatted_stats.today
	
	if "fish_today" in stats_labels:
		stats_labels.fish_today.label.text = stats_labels.fish_today.text + " " + (stats_labels.fish_today.format % today.fish_caught)
	
	if "value_today" in stats_labels:
		stats_labels.value_today.label.text = stats_labels.value_today.text + " " + (stats_labels.value_today.format % today.value_earned)
	
	if "streak" in stats_labels:
		stats_labels.streak.label.text = stats_labels.streak.text + " " + (stats_labels.streak.format % today.current_streak)
	
	if "success_rate" in stats_labels:
		stats_labels.success_rate.label.text = stats_labels.success_rate.text + " " + (stats_labels.success_rate.format % today.success_rate)