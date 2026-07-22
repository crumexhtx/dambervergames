extends Node
## Between-run progression: banked wood and permanent unlocks.

const SAVE_PATH := "user://beaver_survivor_meta.cfg"

var banked_wood: int = 0

var unlock_bonus_hp: bool = false
var unlock_stick_in_pool: bool = false
var unlock_start_berry: bool = false
var unlock_sap_in_pool: bool = false
var unlock_decoy_in_pool: bool = false
var unlock_second_dash: bool = false

# Settings
var reduce_shake: bool = false
var show_damage_numbers: bool = true
var large_joystick: bool = false

var bonus_starting_hp: int:
	get:
		return 10 if unlock_bonus_hp else 0

const UNLOCKS := [
	{"id": "bonus_hp", "cost": 50, "name": "Thick Starter Fur", "desc": "+10 starting HP"},
	{"id": "stick", "cost": 100, "name": "Stick Bundle", "desc": "Stick Throw in offer pool"},
	{"id": "berry", "cost": 150, "name": "Trail Snack", "desc": "Start with +1 berry"},
	{"id": "sap", "cost": 200, "name": "Sap Glands", "desc": "Sap Spray in offer pool"},
	{"id": "decoy", "cost": 300, "name": "Decoy Plans", "desc": "Decoy Dam in upgrade pool"},
	{"id": "dash2", "cost": 400, "name": "Double Dash", "desc": "Second dash charge"},
]


func _ready() -> void:
	load_save()


func bank_wood(amount: int) -> void:
	banked_wood += maxi(0, amount)
	save()


func is_unlocked(id: String) -> bool:
	match id:
		"bonus_hp":
			return unlock_bonus_hp
		"stick":
			return unlock_stick_in_pool
		"berry":
			return unlock_start_berry
		"sap":
			return unlock_sap_in_pool
		"decoy":
			return unlock_decoy_in_pool
		"dash2":
			return unlock_second_dash
	return false


func can_buy(id: String) -> bool:
	if is_unlocked(id):
		return false
	for u in UNLOCKS:
		if u.id == id:
			return banked_wood >= int(u.cost)
	return false


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	for u in UNLOCKS:
		if u.id == id:
			banked_wood -= int(u.cost)
			_apply_unlock(id)
			save()
			return true
	return false


func _apply_unlock(id: String) -> void:
	match id:
		"bonus_hp":
			unlock_bonus_hp = true
		"stick":
			unlock_stick_in_pool = true
		"berry":
			unlock_start_berry = true
		"sap":
			unlock_sap_in_pool = true
		"decoy":
			unlock_decoy_in_pool = true
		"dash2":
			unlock_second_dash = true


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "banked_wood", banked_wood)
	cfg.set_value("meta", "unlock_bonus_hp", unlock_bonus_hp)
	cfg.set_value("meta", "unlock_stick_in_pool", unlock_stick_in_pool)
	cfg.set_value("meta", "unlock_start_berry", unlock_start_berry)
	cfg.set_value("meta", "unlock_sap_in_pool", unlock_sap_in_pool)
	cfg.set_value("meta", "unlock_decoy_in_pool", unlock_decoy_in_pool)
	cfg.set_value("meta", "unlock_second_dash", unlock_second_dash)
	cfg.set_value("settings", "reduce_shake", reduce_shake)
	cfg.set_value("settings", "show_damage_numbers", show_damage_numbers)
	cfg.set_value("settings", "large_joystick", large_joystick)
	cfg.save(SAVE_PATH)


func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	banked_wood = int(cfg.get_value("meta", "banked_wood", 0))
	unlock_bonus_hp = bool(cfg.get_value("meta", "unlock_bonus_hp", false))
	unlock_stick_in_pool = bool(cfg.get_value("meta", "unlock_stick_in_pool", false))
	unlock_start_berry = bool(cfg.get_value("meta", "unlock_start_berry", false))
	unlock_sap_in_pool = bool(cfg.get_value("meta", "unlock_sap_in_pool", false))
	unlock_decoy_in_pool = bool(cfg.get_value("meta", "unlock_decoy_in_pool", false))
	unlock_second_dash = bool(cfg.get_value("meta", "unlock_second_dash", false))
	reduce_shake = bool(cfg.get_value("settings", "reduce_shake", false))
	show_damage_numbers = bool(cfg.get_value("settings", "show_damage_numbers", true))
	large_joystick = bool(cfg.get_value("settings", "large_joystick", false))
