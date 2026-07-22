extends CharacterBody2D
class_name EnemyBase
## Shared enemy: chase, contact damage, elite flag, XP/wood drops.

@export var enemy_id: String = "hornet"
@export var max_hp: float = 18.0
@export var move_speed: float = 3.6
@export var contact_damage: float = 8.0
@export var spawn_cost: int = 2
@export var xp_on_death: float = 1.0
@export var wood_on_death: int = 0

var hp: float = 18.0
var is_elite: bool = false
var slow_factor: float = 1.0
var slow_timer: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var _visual_root: Node2D
var _anim: CharacterAnimator
var _hp_mult: float = 1.0
var _dmg_mult: float = 1.0
var _dying: bool = false


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp * DebugBalance.hp_mult * _hp_mult
	_build_visual()
	collision_layer = 2
	collision_mask = 1 | 64


func configure(elite: bool = false, wave_mult: float = 1.0) -> void:
	is_elite = elite
	_hp_mult = wave_mult * (2.0 if elite else 1.0)
	_dmg_mult = (1.25 if elite else 1.0)
	if elite:
		add_to_group("elite")
		scale = Vector2(1.3, 1.3)
		xp_on_death = 15.0
		wood_on_death = maxi(1, wood_on_death + 2)
	hp = max_hp * DebugBalance.hp_mult * _hp_mult
	if is_inside_tree():
		_build_visual()


func _build_visual() -> void:
	if _visual_root and is_instance_valid(_visual_root):
		remove_child(_visual_root)
		_visual_root.free()
	_anim = null
	_visual_root = Node2D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)
	_anim = CharacterAnimator.new()
	_anim.name = "Anim"
	_visual_root.add_child(_anim)
	_anim.setup(enemy_id, is_elite)
	var shape := get_node_or_null("CollisionShape2D")
	if shape == null:
		shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		shape.shape = circle
		add_child(shape)


func _draw_silhouette(host: Node2D) -> void:
	## Kept for subclasses that still call it; prefer CharacterAnimator via enemy_id.
	Silhouettes.build_articulated(host, enemy_id, is_elite)


func get_contact_damage() -> float:
	return contact_damage * _dmg_mult


func take_damage(amount: float, from_pos: Vector2 = Vector2.ZERO) -> void:
	if _dying:
		return
	hp -= amount
	GameState.record_damage(amount)
	var big := is_elite or is_in_group("boss")
	Juice.spawn_damage_number(global_position, amount, big)
	if big:
		Juice.hit_impact(global_position, true)
	if _anim:
		_anim.play_oneshot("hit", 0.16)
	if from_pos != Vector2.ZERO:
		apply_knockback((global_position - from_pos).normalized() * (55.0 if big else 40.0))
	if hp <= 0.0:
		die()


func apply_knockback(force: Vector2) -> void:
	knockback = force


func apply_slow(amount: float, duration: float) -> void:
	slow_factor = 1.0 - amount
	slow_timer = maxf(slow_timer, duration)


func die() -> void:
	if _dying:
		return
	_dying = true
	GameState.record_kill()
	var col := Color(0.5, 0.7, 0.3)
	Juice.spawn_leaf_burst(global_position, col)
	_drop_loot()
	if _anim:
		_anim.play("death")
		var t := get_tree().create_timer(0.35)
		t.timeout.connect(queue_free)
	else:
		queue_free()


func _drop_loot() -> void:
	var world := get_tree().current_scene.get_node_or_null("World")
	if world == null:
		return
	var gem := Area2D.new()
	gem.set_script(preload("res://scripts/loot/xp_gem.gd"))
	world.add_child(gem)
	gem.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	var xp_val := xp_on_death
	if xp_val >= 15.0:
		gem.setup(15)
	elif xp_val >= 5.0:
		gem.setup(5)
	else:
		gem.setup(1)
	if wood_on_death > 0:
		var pickup := Area2D.new()
		pickup.set_script(preload("res://scripts/loot/pickup.gd"))
		world.add_child(pickup)
		pickup.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))
		pickup.setup("wood", wood_on_death)


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return
	if not GameState.run_active or GameState.soft_paused or GameState.in_breather:
		velocity = Vector2.ZERO
		if _anim:
			_anim.set_speed_factor(0.0)
		return
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0
	var target_pos: Vector2 = _chase_target()
	var dir: Vector2 = (target_pos - global_position).normalized()
	var spd: float = GameState.pixels(move_speed) * slow_factor
	velocity = dir * spd + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 200.0 * delta)
	move_and_slide()
	if _anim:
		_anim.set_facing_dir(velocity if velocity.length() > 8.0 else dir)
		_anim.set_speed_factor(clampf(velocity.length() / maxf(1.0, GameState.pixels(move_speed)), 0.0, 1.2))


func _chase_target() -> Vector2:
	for d in get_tree().get_nodes_in_group("decoy"):
		if is_instance_valid(d) and d is Node2D and d.visible:
			return (d as Node2D).global_position
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		return player.global_position
	return global_position
