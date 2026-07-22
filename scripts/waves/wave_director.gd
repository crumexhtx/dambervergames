extends Node
class_name WaveDirector
## Drives waves 1–10 then boss finale.

signal wave_cleared(wave: int)
signal breather_started(duration: float)
signal boss_phase_started
signal extract_opened(reduced: bool)
signal banner(text: String)

enum Phase { IDLE, SPAWNING, BREATHER, BOSS, DONE }

var phase: Phase = Phase.IDLE
var current_wave: int = 0
var budget_remaining: float = 0.0
var budget_total: float = 0.0
var spawned_value: float = 0.0
var killed_value: float = 0.0
var duration_left: float = 0.0
var spawn_timer: float = 0.0
var breather_left: float = 0.0
var pattern: String = "trickle"
var burst_done: bool = false
var queue: Array = []  # pending spawn descriptors
var enemies_root: Node2D
var world: Node2D
var _boss: BulldozerBoss
var _tracked_costs: Dictionary = {}  # instance_id -> cost
var _ambush_pending: bool = false
var _ambush_timer: float = 0.0
var _ambush_desc: Dictionary = {}

const ALIVE_CAP := 80

# Wave budgets — tuned for early fairness (balance pass).
# Targets: W1–3 Tail-Slap-only clearable; W5 reachable; W10+boss practiced.
const WAVE_DATA := [
	{}, # index 0 unused
	{"budget": 10, "duration": 32, "pattern": "trickle", "bias": ["rat", "rat", "rat", "hornet"], "elite": 0, "mult": 0.9, "breather": 2.8},
	{"budget": 16, "duration": 36, "pattern": "trickle", "bias": ["rat", "hornet", "hornet"], "elite": 0, "mult": 0.95, "breather": 2.7},
	{"budget": 24, "duration": 40, "pattern": "burst", "bias": ["rat", "rat", "rat", "hornet"], "elite": 0, "mult": 1.0, "breather": 2.6},
	{"budget": 30, "duration": 44, "pattern": "trickle", "bias": ["hornet", "rat", "fox"], "elite": 1, "elite_type": "hornet", "mult": 1.08, "breather": 2.4},
	{"budget": 36, "duration": 46, "pattern": "trickle", "bias": ["fox", "hornet", "rat"], "elite": 0, "mult": 1.12, "breather": 2.3},
	{"budget": 44, "duration": 50, "pattern": "burst", "bias": ["drone", "hornet", "fox", "rat"], "elite": 1, "elite_type": "hornet", "mult": 1.18, "breather": 2.1},
	{"budget": 52, "duration": 52, "pattern": "burst", "bias": ["hornet", "hornet", "fox", "rat"], "elite": 2, "elite_type": "hornet", "mult": 1.25, "breather": 1.9},
	{"budget": 60, "duration": 55, "pattern": "ambush", "bias": ["rat", "hornet", "fox", "drone"], "elite": 1, "elite_type": "fox", "mult": 1.32, "breather": 1.7},
	{"budget": 68, "duration": 58, "pattern": "ambush", "bias": ["drone", "fox", "hornet", "rat"], "elite": 1, "elite_type": "fox", "mult": 1.38, "breather": 1.6},
	{"budget": 76, "duration": 60, "pattern": "burst", "bias": ["hornet", "fox", "drone", "rat"], "elite": 3, "elite_type": "hornet", "mult": 1.45, "breather": 1.5},
]


func setup(p_world: Node2D, p_enemies: Node2D) -> void:
	world = p_world
	enemies_root = p_enemies


func start() -> void:
	phase = Phase.IDLE
	current_wave = 0
	_begin_next_wave()


func _process(delta: float) -> void:
	if not GameState.run_active or GameState.soft_paused:
		return
	if _ambush_pending:
		_ambush_timer -= delta
		if _ambush_timer <= 0.0:
			_ambush_pending = false
			if phase == Phase.SPAWNING and not _ambush_desc.is_empty():
				var player := get_tree().get_first_node_in_group("player") as Node2D
				var base: Vector2 = player.global_position if player else Vector2.ZERO
				var pos: Vector2 = base + Vector2.RIGHT.rotated(randf() * TAU) * GameState.pixels(3.0)
				_spawn_enemy(str(_ambush_desc.type), bool(_ambush_desc.elite), float(_ambush_desc.mult), pos, int(_ambush_desc.cost))
				_ambush_desc = {}
	match phase:
		Phase.SPAWNING:
			_process_spawning(delta)
		Phase.BREATHER:
			breather_left -= delta
			if breather_left <= 0.0:
				_begin_next_wave()
		Phase.BOSS:
			pass
		_:
			pass


func _begin_next_wave() -> void:
	GameState.in_breather = false
	current_wave += 1
	if current_wave > 10:
		_start_boss()
		return
	var data: Dictionary = WAVE_DATA[current_wave]
	budget_total = float(data.budget) * DebugBalance.wave_budget_mult
	budget_remaining = budget_total
	spawned_value = 0.0
	killed_value = 0.0
	duration_left = float(data.duration)
	pattern = str(data.pattern)
	burst_done = false
	queue.clear()
	phase = Phase.SPAWNING
	GameState.set_wave(current_wave, 0.0)
	banner.emit("Wave %d" % current_wave)
	# Guaranteed elites
	var elites: int = int(data.get("elite", 0))
	var etype: String = str(data.get("elite_type", "hornet"))
	for i in elites:
		_enqueue(etype, true, float(data.mult))
	# Fill rest of budget with bias
	var bias: Array = data.bias
	while budget_remaining > 0.0:
		var t: String = bias[randi() % bias.size()]
		var cost := _cost_of(t)
		if cost > budget_remaining and budget_remaining < 2.0:
			break
		if cost > budget_remaining:
			t = "rat"
			cost = 1
		_enqueue(t, false, float(data.mult))
		budget_remaining -= cost
	if pattern == "burst":
		var burst_count := int(queue.size() * 0.4)
		for i in burst_count:
			_spawn_one()


func _enqueue(type: String, elite: bool, mult: float) -> void:
	var cost := _cost_of(type) * (3 if elite else 1)
	queue.append({"type": type, "elite": elite, "mult": mult, "cost": cost})
	spawned_value += cost


func _cost_of(type: String) -> int:
	match type:
		"rat":
			return 1
		"hornet":
			return 2
		"fox":
			return 5
		"drone":
			return 4
	return 2


func _process_spawning(delta: float) -> void:
	duration_left -= delta
	spawn_timer -= delta
	_update_progress()
	if _alive_count() < ALIVE_CAP and not queue.is_empty() and spawn_timer <= 0.0:
		var interval := 1.25 if pattern == "trickle" else 0.9
		if pattern == "ambush":
			interval = 0.8
		spawn_timer = interval
		if pattern == "ambush" and randf() < 0.25:
			_spawn_ambush()
		else:
			_spawn_one()
	# Clear conditions
	var quota := spawned_value * 0.7
	if killed_value >= quota or duration_left <= 0.0:
		_clear_wave()


func _spawn_one() -> void:
	if queue.is_empty():
		return
	if _alive_count() >= ALIVE_CAP:
		return
	var desc: Dictionary = queue.pop_front()
	var pos := _ring_spawn_pos()
	_spawn_enemy(str(desc.type), bool(desc.elite), float(desc.mult), pos, int(desc.cost))


func _spawn_ambush() -> void:
	if queue.is_empty() or _ambush_pending:
		return
	banner.emit("Rustle…!")
	_ambush_desc = queue.pop_front()
	_ambush_pending = true
	_ambush_timer = 0.6


func _ring_spawn_pos() -> Vector2:
	var half := GameState.pixels(GameState.ARENA_HALF - 1.0)
	var ang := randf() * TAU
	return Vector2(cos(ang), sin(ang)) * half


func _spawn_enemy(type: String, elite: bool, mult: float, pos: Vector2, cost: int) -> void:
	var e: EnemyBase
	match type:
		"rat":
			e = FloodRatEnemy.new()
		"fox":
			e = FoxEnemy.new()
		"drone":
			e = LoggerDroneEnemy.new()
		_:
			e = HornetEnemy.new()
	enemies_root.add_child(e)
	e.global_position = pos
	e.configure(elite, mult)
	_tracked_costs[e.get_instance_id()] = cost
	e.tree_exiting.connect(_on_enemy_exit.bind(e.get_instance_id(), cost))


func _on_enemy_exit(id: int, cost: int) -> void:
	if _tracked_costs.has(id):
		_tracked_costs.erase(id)
		if phase == Phase.SPAWNING:
			killed_value += cost


func _alive_count() -> int:
	return enemies_root.get_child_count() if enemies_root else 0


func _update_progress() -> void:
	var quota := maxf(1.0, spawned_value * 0.7)
	var p := clampf(killed_value / quota, 0.0, 1.0)
	GameState.set_wave(current_wave, p)


func _clear_wave() -> void:
	phase = Phase.BREATHER
	GameState.in_breather = true
	wave_cleared.emit(current_wave)
	_spawn_wave_rewards(current_wave)
	var data: Dictionary = WAVE_DATA[current_wave]
	breather_left = float(data.get("breather", 2.8))
	if absf(DebugBalance.breather_duration - 2.8) > 0.01:
		breather_left *= DebugBalance.breather_duration / 2.8
	breather_started.emit(breather_left)
	banner.emit("Wave %d Cleared — chew free!" % current_wave)
	GameState.set_wave(current_wave, 1.0)


func _spawn_wave_rewards(wave: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var origin: Vector2 = player.global_position if player else Vector2.ZERO
	# Slightly richer clear XP so combat stays rewarding vs chew
	var total_xp := 6 + wave * 2
	var gems := maxi(1, total_xp)
	for i in mini(gems, 10):
		var gem := Area2D.new()
		gem.set_script(preload("res://scripts/loot/xp_gem.gd"))
		world.add_child(gem)
		gem.global_position = origin + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		gem.setup(1 if total_xp < 15 else (5 if i == 0 else 1))
	# Guaranteed wood pile — chewing stays optional, not mandatory for extract seed
	var wood_pile := Area2D.new()
	wood_pile.set_script(preload("res://scripts/loot/pickup.gd"))
	world.add_child(wood_pile)
	wood_pile.global_position = origin + Vector2(0, -30)
	wood_pile.setup("wood", maxi(2, wave))


func _start_boss() -> void:
	GameState.in_breather = false
	phase = Phase.BOSS
	GameState.set_wave(10, 1.0)
	banner.emit("BOSS — Bulldozer!")
	boss_phase_started.emit()
	_boss = BulldozerBoss.new()
	enemies_root.add_child(_boss)
	_boss.global_position = Vector2(0, -GameState.pixels(18))
	_boss.boss_defeated.connect(_on_boss_defeated)
	_boss.boss_escaped.connect(_on_boss_escaped)


func _on_boss_defeated() -> void:
	phase = Phase.DONE
	banner.emit("Bulldozer down! Extract at the Dam!")
	extract_opened.emit(false)
	GameState.set_extract_available(true, false)


func _on_boss_escaped() -> void:
	phase = Phase.DONE
	banner.emit("It fled… Extract still open (reduced bonus)")
	extract_opened.emit(true)
	GameState.set_extract_available(true, true)
