extends Node
class_name WeaponManager

const TailSlapScript = preload("res://scripts/weapons/tail_slap.gd")
const StickThrowScript = preload("res://scripts/weapons/stick_throw.gd")
const SapSprayScript = preload("res://scripts/weapons/sap_spray.gd")
const ToothChompScript = preload("res://scripts/weapons/tooth_chomp.gd")

var player: Player
var weapons: Dictionary = {}


func _ready() -> void:
	player = get_parent() as Player
	call_deferred("_boot")


func _boot() -> void:
	ensure_weapons()


func ensure_weapons() -> void:
	for id in GameState.owned_weapons:
		if not weapons.has(id):
			_add_weapon(id)


func _add_weapon(id: String) -> void:
	var w: WeaponBase
	match id:
		"tail":
			w = TailSlapScript.new()
		"stick":
			w = StickThrowScript.new()
		"sap":
			w = SapSprayScript.new()
		"chomp":
			w = ToothChompScript.new()
		_:
			return
	add_child(w)
	w.setup(player)
	weapons[id] = w


func unlock_weapon(id: String) -> void:
	if id in GameState.owned_weapons:
		rank_up(id)
		return
	if GameState.owned_weapons.size() >= GameState.max_weapons:
		return
	GameState.owned_weapons.append(id)
	GameState.weapon_ranks[id] = 0
	_add_weapon(id)


func rank_up(id: String) -> void:
	if not GameState.weapon_ranks.has(id):
		unlock_weapon(id)
		return
	var r: int = int(GameState.weapon_ranks[id])
	GameState.weapon_ranks[id] = mini(5, r + 1)
