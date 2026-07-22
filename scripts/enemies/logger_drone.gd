extends EnemyBase
class_name LoggerDroneEnemy

var _shoot_cd: float = 2.2
var preferred_range: float = 4.5


func _init() -> void:
	enemy_id = "drone"
	max_hp = 32.0
	move_speed = 2.2
	contact_damage = 5.0
	spawn_cost = 4
	xp_on_death = 5.0


func _draw_silhouette(host: Node2D) -> void:
	Silhouettes.build_drone(host, is_elite)


func _physics_process(delta: float) -> void:
	if not GameState.run_active or GameState.soft_paused or GameState.in_breather:
		velocity = Vector2.ZERO
		return
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var to_p: Vector2 = player.global_position - global_position
	var dist: float = to_p.length()
	var ideal: float = GameState.pixels(preferred_range)
	var dir: Vector2 = Vector2.ZERO
	if dist < ideal * 0.85:
		dir = -to_p.normalized()
	elif dist > ideal * 1.15:
		dir = to_p.normalized()
	else:
		dir = to_p.normalized().orthogonal()
	var spd: float = GameState.pixels(move_speed) * slow_factor
	velocity = dir * spd + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 200.0 * delta)
	move_and_slide()

	_shoot_cd -= delta
	if _shoot_cd <= 0.0:
		_shoot_cd = 2.2
		_fire_at(player.global_position)


func _fire_at(target: Vector2) -> void:
	var bolt := Area2D.new()
	bolt.collision_layer = 0
	bolt.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	bolt.add_child(shape)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)])
	poly.color = Color(0.9, 0.2, 0.2)
	bolt.add_child(poly)
	var world := get_tree().current_scene.get_node("World")
	world.add_child(bolt)
	bolt.global_position = global_position
	var dir: Vector2 = (target - global_position).normalized()
	var speed: float = GameState.pixels(5.0)
	var dmg: float = 8.0 * _dmg_mult * DebugBalance.dmg_mult
	var life: float = 2.0
	# Brief telegraph diamond so shots aren't color-only
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([Vector2(0, -5), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0)])
	tip.color = Color(1.0, 0.85, 0.2)
	bolt.add_child(tip)
	bolt.body_entered.connect(func(body: Node):
		if body.is_in_group("player"):
			GameState.take_damage(dmg)
			if is_instance_valid(bolt):
				bolt.queue_free()
	)
	var tw := bolt.create_tween()
	tw.tween_property(bolt, "global_position", global_position + dir * speed * life, life)
	tw.tween_callback(bolt.queue_free)
