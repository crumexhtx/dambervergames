extends EnemyBase
class_name FoxEnemy

var _lunge_cd: float = 3.0
var _lunge_timer: float = 0.0


func _init() -> void:
	enemy_id = "fox"
	max_hp = 55.0
	move_speed = 2.8
	contact_damage = 14.0
	spawn_cost = 5
	xp_on_death = 5.0
	wood_on_death = 1


func _build_visual() -> void:
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(-14, -8), Vector2(16, -4), Vector2(12, 10), Vector2(-12, 10)
	])
	_visual.color = Color(0.85, 0.45, 0.2) if not is_elite else Color(1.0, 0.2, 0.15)
	add_child(_visual)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	if not GameState.run_active or GameState.soft_paused:
		velocity = Vector2.ZERO
		return
	_lunge_cd -= delta
	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		move_speed = 2.8 * 1.5
	else:
		move_speed = 2.8
		if _lunge_cd <= 0.0:
			_lunge_cd = 3.0
			_lunge_timer = 0.4
	super._physics_process(delta)
