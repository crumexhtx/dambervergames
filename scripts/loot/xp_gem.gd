extends Area2D
class_name XPGem

var xp_value: int = 1
var _magnetized: bool = false
var _visual: Polygon2D


func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body)
	if _visual == null:
		_build()


func setup(value: int) -> void:
	xp_value = value
	_build()


func _build() -> void:
	if _visual:
		_visual.queue_free()
	_visual = Polygon2D.new()
	var s := 5.0 if xp_value <= 1 else (8.0 if xp_value < 15 else 12.0)
	_visual.polygon = PackedVector2Array([
		Vector2(0, -s), Vector2(s * 0.7, 0), Vector2(0, s), Vector2(-s * 0.7, 0)
	])
	_visual.color = Color(0.35, 0.75, 1.0) if xp_value <= 1 else (Color(0.4, 0.9, 0.5) if xp_value < 15 else Color(1.0, 0.85, 0.2))
	add_child(_visual)
	var shape := get_node_or_null("CollisionShape2D")
	if shape == null:
		shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = s + 4.0
		shape.shape = circle
		add_child(shape)


func _physics_process(delta: float) -> void:
	if GameState.soft_paused:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var d: float = global_position.distance_to(player.global_position)
	var magnet: float = GameState.pixels(GameState.pickup_radius)
	if d <= magnet * 2.5:
		if not _magnetized:
			Juice.spawn_vacuum_arc(global_position, player.global_position)
		_magnetized = true
	if _magnetized:
		global_position = global_position.move_toward(player.global_position, 280.0 * delta)
		if d < 14.0:
			_collect()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	GameState.add_xp(float(xp_value))
	Juice.play_sfx("pickup")
	queue_free()
