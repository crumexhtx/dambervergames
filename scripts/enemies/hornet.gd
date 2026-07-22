extends EnemyBase
class_name HornetEnemy


func _init() -> void:
	enemy_id = "hornet"
	max_hp = 18.0
	move_speed = 3.6
	contact_damage = 8.0
	spawn_cost = 2
	xp_on_death = 1.0


func _build_visual() -> void:
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(10, 0), Vector2(4, 10), Vector2(-4, 10), Vector2(-10, 0)
	])
	_visual.color = Color(0.95, 0.8, 0.1) if not is_elite else Color(1.0, 0.4, 0.1)
	add_child(_visual)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	shape.shape = circle
	add_child(shape)
