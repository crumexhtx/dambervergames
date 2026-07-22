extends EnemyBase
class_name FloodRatEnemy


func _init() -> void:
	enemy_id = "rat"
	max_hp = 10.0
	move_speed = 4.2
	contact_damage = 5.0
	spawn_cost = 1
	xp_on_death = 1.0


func _build_visual() -> void:
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(-8, -6), Vector2(10, -4), Vector2(12, 4), Vector2(-6, 8), Vector2(-12, 0)
	])
	_visual.color = Color(0.55, 0.4, 0.35) if not is_elite else Color(0.85, 0.25, 0.2)
	add_child(_visual)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
