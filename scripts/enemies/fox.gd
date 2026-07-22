extends EnemyBase
class_name FoxEnemy

var _lunge_cd: float = 3.2
var _lunge_timer: float = 0.0
var _telegraph: float = 0.0
var _windup_line: Line2D
var _lunge_dir: Vector2 = Vector2.RIGHT
var _dir_locked: bool = false


func _init() -> void:
	enemy_id = "fox"
	max_hp = 50.0
	move_speed = 2.7
	contact_damage = 12.0
	spawn_cost = 5
	xp_on_death = 5.0
	wood_on_death = 1


func _ready() -> void:
	super._ready()
	_windup_line = Line2D.new()
	_windup_line.width = 5.0
	_windup_line.default_color = Color(1.0, 0.45, 0.1, 0.0)
	_windup_line.z_index = 25
	add_child(_windup_line)


func _draw_silhouette(host: Node2D) -> void:
	Silhouettes.build_fox(host, is_elite)


func _physics_process(delta: float) -> void:
	if not GameState.run_active or GameState.soft_paused or GameState.in_breather:
		velocity = Vector2.ZERO
		if _windup_line:
			_windup_line.default_color.a = 0.0
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	_lunge_cd -= delta

	# Telegraph: lock aim once, keep line fixed (fair telegraph)
	if _telegraph > 0.0:
		_telegraph -= delta
		velocity = Vector2.ZERO
		if not _dir_locked and player:
			_lunge_dir = (player.global_position - global_position).normalized()
			if _lunge_dir.length() < 0.1:
				_lunge_dir = Vector2.RIGHT
			_dir_locked = true
		if _windup_line:
			_windup_line.points = PackedVector2Array([Vector2.ZERO, _lunge_dir * 48.0])
			_windup_line.default_color = Color(1.0, 0.4, 0.1, 0.85)
		if _anim:
			_anim.set_facing_dir(_lunge_dir)
			_anim.force_state("telegraph")
		else:
			modulate = Color(1.3, 1.1, 0.9)
		if _telegraph <= 0.0:
			_lunge_timer = 0.35
			_windup_line.default_color.a = 0.0
			modulate = Color.WHITE
			if _anim:
				_anim.force_state("lunge")
		return

	# Lunge: commit to locked direction (no redirect mid-lunge)
	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		velocity = _lunge_dir * GameState.pixels(2.7 * 1.35) + knockback
		knockback = knockback.move_toward(Vector2.ZERO, 200.0 * delta)
		move_and_slide()
		if _anim:
			_anim.set_facing_dir(_lunge_dir)
			_anim.set_speed_factor(1.2)
		if _lunge_timer <= 0.0:
			_dir_locked = false
			if _anim:
				_anim.clear_force()
		return

	_dir_locked = false
	if _anim:
		_anim.clear_force()
	move_speed = 2.7
	if _lunge_cd <= 0.0:
		_lunge_cd = 3.2
		_telegraph = 0.45
		_dir_locked = false
	super._physics_process(delta)
