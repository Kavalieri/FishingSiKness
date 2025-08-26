extends Node

# Autoload que envuelve a ContentIndex
# class_name Content

signal content_loaded

var catalogs = {}

func _ready():
	var content_index = ContentIndex.new()
	catalogs = content_index.load_all()
	emit_signal("content_loaded")

# API de acceso
func all_fish():
	return catalogs["fish"] if catalogs.has("fish") else []

func all_zones():
	return catalogs["zones"] if catalogs.has("zones") else []

func equipment(equip_type: String = ""):
	var eqs = catalogs["equipment"] if catalogs.has("equipment") else []
	if equip_type == "":
		return eqs
	var filtered := []
	for e in eqs:
		if e.has("tool_type") and e.tool_type == equip_type:
			filtered.append(e)
	return filtered

func upgrade_defs():
	return catalogs["upgrades"] if catalogs.has("upgrades") else []

func store_items():
	return catalogs["store"] if catalogs.has("store") else []
