extends EnemyBase
class_name FloodRatEnemy


func _init() -> void:
	enemy_id = "rat"
	max_hp = 9.0
	move_speed = 4.0
	contact_damage = 4.0
	spawn_cost = 1
	xp_on_death = 1.0


func _draw_silhouette(host: Node2D) -> void:
	Silhouettes.build_rat(host, is_elite)
