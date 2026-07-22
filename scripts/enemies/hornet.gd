extends EnemyBase
class_name HornetEnemy


func _init() -> void:
	enemy_id = "hornet"
	max_hp = 16.0
	move_speed = 3.5
	contact_damage = 7.0
	spawn_cost = 2
	xp_on_death = 1.0


func _draw_silhouette(host: Node2D) -> void:
	Silhouettes.build_hornet(host, is_elite)
