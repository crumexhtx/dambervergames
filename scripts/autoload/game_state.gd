extends Node
## Run-time state for a single play session.

signal hp_changed(current: float, maximum: float)
signal xp_changed(current: float, needed: float, level: int)
signal inventory_changed(wood: int, stone: int, berries: int)
signal level_up(new_level: int)
signal wave_changed(wave: int, progress: float)
signal boss_hp_changed(current: float, maximum: float)
signal extract_available_changed(available: bool)
signal run_ended(success: bool, summary: Dictionary)
signal soft_paused_changed(paused: bool)
signal upgrades_changed(owned: Array)
signal dash_changed(charges: int, max_charges: int, cooldown: float)

var soft_paused: bool = false
var run_active: bool = false

# Player combat stats
var max_hp: float = 100.0
var hp: float = 100.0
var move_speed: float = 3.2
var base_move_speed: float = 3.2
var pickup_radius: float = 1.2
var armor: float = 0.0
var global_damage: float = 1.0
var xp_gain: float = 1.0
var chew_dps: float = 15.0

var level: int = 1
var xp: float = 0.0
var wood: int = 0
var stone: int = 0
var berries: int = 0

var dash_charges: int = 1
var dash_max_charges: int = 1
var dash_cooldown: float = 0.0
var dash_cooldown_max: float = 4.0
var dash_distance: float = 2.5
var dash_iframes: float = 0.25

var wave: int = 0
var wave_progress: float = 0.0
var kills: int = 0
var damage_dealt: float = 0.0
var time_alive: float = 0.0
var upgrades_taken: Array[String] = []
var boss_killed: bool = false
var extract_available: bool = false
var extract_reduced_bonus: bool = false
var in_breather: bool = false

var weapon_ranks: Dictionary = {"tail": 0}
var owned_weapons: Array[String] = ["tail"]
var max_weapons: int = 3

var thorns_dps: float = 0.0
var decoy_enabled: bool = false
var overbite_enabled: bool = false

const ARENA_HALF: float = 25.0  # 50x50 arena
const UNIT: float = 32.0  # pixels per design unit


func pixels(u: float) -> float:
	return u * UNIT


func start_run() -> void:
	run_active = true
	soft_paused = false
	max_hp = 100.0 + MetaProgression.bonus_starting_hp
	hp = max_hp
	move_speed = base_move_speed
	pickup_radius = 1.2
	armor = 0.0
	global_damage = 1.0
	xp_gain = 1.0
	chew_dps = 15.0
	level = 1
	xp = 0.0
	wood = 0
	stone = 0
	berries = 1 if MetaProgression.unlock_start_berry else 0
	dash_max_charges = 2 if MetaProgression.unlock_second_dash else 1
	dash_charges = dash_max_charges
	dash_cooldown = 0.0
	wave = 0
	wave_progress = 0.0
	kills = 0
	damage_dealt = 0.0
	time_alive = 0.0
	upgrades_taken.clear()
	boss_killed = false
	extract_available = false
	extract_reduced_bonus = false
	in_breather = false
	weapon_ranks = {"tail": 0}
	owned_weapons = ["tail"]
	thorns_dps = 0.0
	decoy_enabled = MetaProgression.unlock_decoy_in_pool and false
	overbite_enabled = false
	_emit_all()


func set_soft_paused(value: bool) -> void:
	soft_paused = value
	soft_paused_changed.emit(value)


func xp_to_next(lvl: int = level) -> float:
	# Levels 1→15 common; soft ceiling 20
	return 10.0 + (lvl - 1) * 6.0 + pow(max(0, lvl - 10), 1.6) * 4.0


func add_xp(amount: float) -> void:
	if not run_active:
		return
	xp += amount * xp_gain * DebugBalance.xp_mult
	while xp >= xp_to_next() and level < 20:
		xp -= xp_to_next()
		level += 1
		level_up.emit(level)
	xp_changed.emit(xp, xp_to_next(), level)


func heal(amount: float) -> void:
	hp = mini(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)


func take_damage(amount: float) -> void:
	if not run_active or soft_paused:
		return
	var reduced := amount * (1.0 - mini(0.4, armor))
	hp -= reduced
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		hp = 0.0
		_end_run(false)


func add_wood(n: int) -> void:
	wood = mini(999, wood + n)
	inventory_changed.emit(wood, stone, berries)


func add_stone(n: int) -> void:
	stone = mini(999, stone + n)
	inventory_changed.emit(wood, stone, berries)


func add_berries(n: int) -> void:
	berries = mini(99, berries + n)
	inventory_changed.emit(wood, stone, berries)


func try_auto_berry() -> void:
	if berries > 0 and hp < max_hp * 0.4:
		berries -= 1
		heal(20.0)
		inventory_changed.emit(wood, stone, berries)


func record_damage(amount: float) -> void:
	damage_dealt += amount


func record_kill() -> void:
	kills += 1


func set_wave(w: int, progress: float = 0.0) -> void:
	wave = w
	wave_progress = progress
	wave_changed.emit(wave, wave_progress)


func set_extract_available(value: bool, reduced: bool = false) -> void:
	extract_available = value
	extract_reduced_bonus = reduced
	extract_available_changed.emit(value)


func succeed_extract() -> void:
	_end_run(true)


func _end_run(success: bool) -> void:
	if not run_active:
		return
	run_active = false
	var banked := 0
	if success:
		banked = wood
		if extract_reduced_bonus:
			banked = int(wood * 0.6)
		MetaProgression.bank_wood(banked)
	else:
		# v1.1 partial success: die on Wave 6+ banks 25% carried wood
		if wave >= 6 and wood > 0:
			banked = int(wood * 0.25)
			MetaProgression.bank_wood(banked)
	var summary := {
		"success": success,
		"wave": wave,
		"time_alive": time_alive,
		"wood_banked": banked,
		"wood_carried": wood,
		"kills": kills,
		"damage_dealt": int(damage_dealt),
		"upgrades": upgrades_taken.duplicate(),
		"boss_killed": boss_killed,
		"level": level,
		"partial_bank": (not success and banked > 0),
	}
	run_ended.emit(success, summary)


func _emit_all() -> void:
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_to_next(), level)
	inventory_changed.emit(wood, stone, berries)
	wave_changed.emit(wave, wave_progress)
	dash_changed.emit(dash_charges, dash_max_charges, dash_cooldown)
	upgrades_changed.emit(upgrades_taken)
