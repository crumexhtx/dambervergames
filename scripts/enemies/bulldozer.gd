extends EnemyBase
class_name BulldozerBoss
## Wave FINALE boss with 3 phases.

signal boss_defeated
signal boss_escaped

var phase: int = 1
var _push_cd: float = 2.5
var _pack_cd: float = 8.0
var _charge_cd: float = 5.0
var _charging: bool = false
var _charge_telegraph: float = 0.0
var _charge_dir: Vector2 = Vector2.RIGHT
var _timeout: float = 90.0
var _telegraph: Line2D
var _alive: bool = true


func _init() -> void:
	enemy_id = "bulldozer"
	max_hp = 1200.0
	move_speed = 2.0
	contact_damage = 20.0
	spawn_cost = 0
	xp_on_death = 25.0
	wood_on_death = 8


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	remove_from_group("elite")
	is_elite = false
	scale = Vector2(2.2, 2.2)
	hp = max_hp * DebugBalance.hp_mult
	GameState.boss_hp_changed.emit(hp, max_hp)
	_telegraph = Line2D.new()
	_telegraph.width = 8.0
	_telegraph.default_color = Color(1.0, 0.3, 0.1, 0.0)
	_telegraph.z_index = 20
	add_child(_telegraph)


func _build_visual() -> void:
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(-18, -14), Vector2(18, -14), Vector2(22, 16), Vector2(-22, 16)
	])
	_visual.color = Color(0.35, 0.38, 0.42)
	add_child(_visual)
	# Blade
	var blade := Polygon2D.new()
	blade.polygon = PackedVector2Array([Vector2(-24, 8), Vector2(24, 8), Vector2(20, 18), Vector2(-20, 18)])
	blade.color = Color(0.7, 0.7, 0.75)
	add_child(blade)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	add_child(shape)


func take_damage(amount: float, from_pos: Vector2 = Vector2.ZERO) -> void:
	if not _alive:
		return
	hp -= amount
	GameState.record_damage(amount)
	Juice.spawn_damage_number(global_position, amount, true)
	GameState.boss_hp_changed.emit(hp, max_hp)
	var pct := hp / max_hp
	if pct <= 0.3:
		phase = 3
	elif pct <= 0.6:
		phase = 2
	if hp <= 0.0:
		_alive = false
		GameState.boss_killed = true
		_drop_boss_xp()
		Juice.shake(14.0, 0.35)
		Juice.spawn_leaf_burst(global_position, Color(0.5, 0.5, 0.55))
		boss_defeated.emit()
		queue_free()


func _drop_boss_xp() -> void:
	var world := get_tree().current_scene.get_node_or_null("World")
	if world == null:
		return
	for i in 5:
		var gem := Area2D.new()
		gem.set_script(preload("res://scripts/loot/xp_gem.gd"))
		world.add_child(gem)
		gem.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		gem.setup(25)
	var pickup := Area2D.new()
	pickup.set_script(preload("res://scripts/loot/pickup.gd"))
	world.add_child(pickup)
	pickup.global_position = global_position
	pickup.setup("wood", wood_on_death)


func _physics_process(delta: float) -> void:
	if not _alive or not GameState.run_active or GameState.soft_paused:
		velocity = Vector2.ZERO
		return
	_timeout -= delta
	if _timeout <= 0.0:
		_alive = false
		boss_escaped.emit()
		Juice.shake(8.0, 0.2)
		queue_free()
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	if _charging:
		_charge_telegraph -= delta
		if _charge_telegraph > 0.0:
			velocity = Vector2.ZERO
			_telegraph.default_color.a = 0.7
			_telegraph.points = PackedVector2Array([Vector2.ZERO, _charge_dir * GameState.pixels(8.0)])
			return
		_telegraph.default_color.a = 0.0
		velocity = _charge_dir * GameState.pixels(7.0)
		_charge_telegraph -= delta
		if _charge_telegraph < -0.45:
			_charging = false
		move_and_slide()
		return

	# Normal chase
	var dir: Vector2 = (player.global_position - global_position).normalized()
	velocity = dir * GameState.pixels(move_speed) + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 200.0 * delta)
	move_and_slide()

	_push_cd -= delta
	if _push_cd <= 0.0:
		_push_cd = 2.5
		Juice.shake(7.0, 0.12)
		if player.global_position.distance_to(global_position) < GameState.pixels(2.5):
			GameState.take_damage(contact_damage * 0.6 * DebugBalance.dmg_mult)
			player.global_position += dir * 40.0

	if phase >= 2:
		_pack_cd -= delta
		if _pack_cd <= 0.0:
			_pack_cd = 8.0
			_spawn_hornet_pack()

	if phase >= 3:
		_charge_cd -= delta
		if _charge_cd <= 0.0:
			_charge_cd = 5.0
			_charging = true
			_charge_telegraph = 1.0
			_charge_dir = dir
			Juice.shake(4.0, 0.1)


func _spawn_hornet_pack() -> void:
	var world := get_tree().current_scene.get_node_or_null("World/Enemies")
	if world == null:
		world = get_tree().current_scene.get_node_or_null("World")
	if world == null:
		return
	for i in 4:
		var h := HornetEnemy.new()
		world.add_child(h)
		h.global_position = global_position + Vector2.RIGHT.rotated(i * TAU / 4.0) * 60.0
		h.configure(false, 1.4)
