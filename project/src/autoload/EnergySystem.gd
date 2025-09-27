extends Node

signal energy_changed(current: int, max: int)
signal energy_depleted
signal energy_recharged

const BASE_MAX_ENERGY = 10
const RECHARGE_TIME_MINUTES = 5.0
const RECHARGE_TIME_SECONDS = RECHARGE_TIME_MINUTES * 60.0

var current_energy: int = BASE_MAX_ENERGY
var max_energy: int = BASE_MAX_ENERGY
var last_recharge_time: float = 0.0
var recharge_timer: Timer

func _ready() -> void:
	_setup_recharge_timer()
	_load_energy_data()
	_process_offline_recharge()

func _setup_recharge_timer() -> void:
	recharge_timer = Timer.new()
	recharge_timer.wait_time = RECHARGE_TIME_SECONDS
	recharge_timer.timeout.connect(_recharge_energy)
	add_child(recharge_timer)

func _load_energy_data() -> void:
	if not Save:
		return
	
	current_energy = Save.game_data.get("current_energy", BASE_MAX_ENERGY)
	max_energy = Save.game_data.get("max_energy", BASE_MAX_ENERGY)
	last_recharge_time = Save.game_data.get("last_recharge_time", Time.get_unix_time_from_system())

func _process_offline_recharge() -> void:
	var current_time = Time.get_unix_time_from_system()
	var time_passed = current_time - last_recharge_time
	
	if time_passed >= RECHARGE_TIME_SECONDS and current_energy < max_energy:
		var recharges = int(time_passed / RECHARGE_TIME_SECONDS)
		var energy_to_add = min(recharges, max_energy - current_energy)
		
		if energy_to_add > 0:
			current_energy += energy_to_add
			last_recharge_time = current_time - (time_passed % RECHARGE_TIME_SECONDS)
			_save_energy_data()
			energy_changed.emit(current_energy, max_energy)
	
	_start_recharge_timer()

func _start_recharge_timer() -> void:
	if current_energy < max_energy:
		var time_since_last = Time.get_unix_time_from_system() - last_recharge_time
		var remaining_time = RECHARGE_TIME_SECONDS - time_since_last
		recharge_timer.start(max(1.0, remaining_time))

func can_cast() -> bool:
	return current_energy > 0

func consume_energy() -> bool:
	if not can_cast():
		energy_depleted.emit()
		return false
	
	current_energy -= 1
	last_recharge_time = Time.get_unix_time_from_system()
	_save_energy_data()
	energy_changed.emit(current_energy, max_energy)
	
	# Guardar juego inmediatamente
	if Save:
		Save.save_game()
	
	if current_energy == max_energy - 1:
		_start_recharge_timer()
	
	return true

func _recharge_energy() -> void:
	if current_energy < max_energy:
		current_energy += 1
		last_recharge_time = Time.get_unix_time_from_system()
		_save_energy_data()
		energy_changed.emit(current_energy, max_energy)
		energy_recharged.emit()
		
		if current_energy < max_energy:
			recharge_timer.start(RECHARGE_TIME_SECONDS)

func refill_energy_with_gems(gem_cost: int = 5) -> bool:
	if not Save or Save.get_gems() < gem_cost:
		return false
	
	if Save.spend_gems(gem_cost):
		current_energy = max_energy
		last_recharge_time = Time.get_unix_time_from_system()
		recharge_timer.stop()
		_save_energy_data()
		energy_changed.emit(current_energy, max_energy)
		return true
	
	return false

func increase_max_energy(amount: int) -> void:
	max_energy += amount
	_save_energy_data()
	energy_changed.emit(current_energy, max_energy)
	print("[EnergySystem] Energía máxima aumentada a %d" % max_energy)

func refill_energy() -> void:
	"""Rellenar energía al 100%"""
	current_energy = max_energy
	last_recharge_time = Time.get_unix_time_from_system()
	recharge_timer.stop()
	_save_energy_data()
	energy_changed.emit(current_energy, max_energy)
	print("[EnergySystem] Energía recargada al 100%% (%d/%d)" % [current_energy, max_energy])

func get_time_to_next_recharge() -> float:
	if current_energy >= max_energy:
		return 0.0
	
	var time_since_last = Time.get_unix_time_from_system() - last_recharge_time
	return max(0.0, RECHARGE_TIME_SECONDS - time_since_last)

func get_time_to_full() -> float:
	if current_energy >= max_energy:
		return 0.0
	
	var missing_energy = max_energy - current_energy
	var time_to_next = get_time_to_next_recharge()
	return time_to_next + ((missing_energy - 1) * RECHARGE_TIME_SECONDS)

func _save_energy_data() -> void:
	if not Save:
		return
	
	Save.game_data.current_energy = current_energy
	Save.game_data.max_energy = max_energy
	Save.game_data.last_recharge_time = last_recharge_time