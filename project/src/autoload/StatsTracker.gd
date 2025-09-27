extends Node

signal stats_updated

var daily_stats: Dictionary = {}
var total_stats: Dictionary = {}
var session_stats: Dictionary = {}
var recent_catches: Array = []

func _ready() -> void:
	_load_stats()
	_reset_daily_stats_if_needed()

func _load_stats() -> void:
	if not Save:
		return
	
	daily_stats = Save.game_data.get("daily_stats", _get_empty_stats())
	total_stats = Save.game_data.get("total_stats", _get_empty_stats())
	session_stats = _get_empty_stats()

func _get_empty_stats() -> Dictionary:
	return {
		"fish_caught": 0,
		"total_value": 0,
		"best_fish_value": 0,
		"best_fish_name": "",
		"current_streak": 0,
		"best_streak": 0,
		"casts_made": 0,
		"success_rate": 0.0,
		"zones_fished": {},
		"rarity_counts": {"común": 0, "rara": 0, "épica": 0, "legendaria": 0}
	}

func _reset_daily_stats_if_needed() -> void:
	var current_date = Time.get_date_string_from_system()
	var last_date = Save.game_data.get("last_stats_date", "")
	
	if current_date != last_date:
		daily_stats = _get_empty_stats()
		Save.game_data.last_stats_date = current_date
		_save_stats()

func record_cast() -> void:
	daily_stats.casts_made += 1
	total_stats.casts_made += 1
	session_stats.casts_made += 1
	_update_success_rates()
	_save_stats()
	stats_updated.emit()

func record_fish_caught(fish_data: Dictionary) -> void:
	var value = fish_data.get("value", 0)
	var name = fish_data.get("name", "Pez")
	var rarity = fish_data.get("rarity", "común")
	var zone = fish_data.get("zone_caught", "unknown")
	
	# Contadores básicos
	for stats in [daily_stats, total_stats, session_stats]:
		stats.fish_caught += 1
		stats.total_value += value
		stats.current_streak += 1
		stats.best_streak = max(stats.best_streak, stats.current_streak)
		
		if value > stats.best_fish_value:
			stats.best_fish_value = value
			stats.best_fish_name = name
		
		# Contar por rareza
		if rarity in stats.rarity_counts:
			stats.rarity_counts[rarity] += 1
		
		# Contar por zona
		if not stats.zones_fished.has(zone):
			stats.zones_fished[zone] = 0
		stats.zones_fished[zone] += 1
	
	# Añadir al historial reciente (máximo 10)
	var catch_entry = {
		"name": name,
		"value": value,
		"rarity": rarity,
		"zone": zone,
		"time": Time.get_datetime_string_from_system()
	}
	recent_catches.push_front(catch_entry)
	if recent_catches.size() > 10:
		recent_catches.pop_back()
	
	_update_success_rates()
	_save_stats()
	stats_updated.emit()

func record_fish_escaped() -> void:
	for stats in [daily_stats, total_stats, session_stats]:
		stats.current_streak = 0
	
	_update_success_rates()
	_save_stats()
	stats_updated.emit()

func _update_success_rates() -> void:
	for stats in [daily_stats, total_stats, session_stats]:
		if stats.casts_made > 0:
			stats.success_rate = float(stats.fish_caught) / float(stats.casts_made) * 100.0

func get_daily_stats() -> Dictionary:
	return daily_stats.duplicate()

func get_total_stats() -> Dictionary:
	return total_stats.duplicate()

func get_session_stats() -> Dictionary:
	return session_stats.duplicate()

func get_formatted_stats() -> Dictionary:
	return {
		"today": {
			"fish_caught": daily_stats.fish_caught,
			"value_earned": daily_stats.total_value,
			"success_rate": "%.1f%%" % daily_stats.success_rate,
			"current_streak": daily_stats.current_streak,
			"best_fish": daily_stats.best_fish_name if daily_stats.best_fish_name != "" else "Ninguno"
		},
		"total": {
			"fish_caught": total_stats.fish_caught,
			"value_earned": total_stats.total_value,
			"success_rate": "%.1f%%" % total_stats.success_rate,
			"best_streak": total_stats.best_streak,
			"best_fish": total_stats.best_fish_name if total_stats.best_fish_name != "" else "Ninguno"
		},
		"session": {
			"fish_caught": session_stats.fish_caught,
			"value_earned": session_stats.total_value,
			"success_rate": "%.1f%%" % session_stats.success_rate,
			"current_streak": session_stats.current_streak
		},
		"recent_catches": recent_catches
	}

func get_recent_catches() -> Array:
	return recent_catches.duplicate()

func _save_stats() -> void:
	if not Save:
		return
	
	Save.game_data.daily_stats = daily_stats
	Save.game_data.total_stats = total_stats