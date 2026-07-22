extends EnemyBase
class_name FoxEnemy

var _lunge_cd: float = 3.2
var _lunge_timer: float = 0.0
var _telegraph: float = 0.0
var _windup_line: Line2D


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

	# Telegraph then lunge (shape + color for a11y)
	if _telegraph > 0.0:
		_telegraph -= delta
		velocity = Vector2.ZERO
		if player and _windup_line:
			var dir: Vector2 = (player.global_position - global_position).normalized()
			_windup_line.points = PackedVector2Array([Vector2.ZERO, dir * 48.0])
			_windup_line.default_color = Color(1.0, 0.4, 0.1, 0.85)
			# Diamond tip marker (shape cue, not color-only)
			modulate = Color(1.3, 1.1, 0.9)
		if _telegraph <= 0.0:
			_lunge_timer = 0.35
			_windup_line.default_color.a = 0.0
			modulate = Color.WHITE
		return

	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		move_speed = 2.7 * 1.35
	else:
		move_speed = 2.7
		if _lunge_cd <= 0.0:
			_lunge_cd = 3.2
			_telegraph = 0.45
	super._physics_process(delta)
