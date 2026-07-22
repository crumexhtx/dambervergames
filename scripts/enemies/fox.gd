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


func _draw_silhouette(host: Node2D) -> void:
	Silhouettes.build_fox(host, is_elite)


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
