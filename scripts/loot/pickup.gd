extends Area2D
class_name LootPickup

var kind: String = "wood"
var amount: int = 1
var _magnetized: bool = false
var _visual: Polygon2D


func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 8
	collision_mask = 1
	body_entered.connect(_on_body)


func setup(p_kind: String, p_amount: int) -> void:
	kind = p_kind
	amount = p_amount
	_build()


func _build() -> void:
	_visual = Polygon2D.new()
	match kind:
		"berry":
			_visual.polygon = PackedVector2Array([Vector2(0, -6), Vector2(6, 2), Vector2(0, 7), Vector2(-6, 2)])
			_visual.color = Color(0.85, 0.15, 0.35)
		"stone":
			_visual.polygon = PackedVector2Array([Vector2(-6, -4), Vector2(6, -5), Vector2(7, 5), Vector2(-7, 4)])
			_visual.color = Color(0.55, 0.55, 0.6)
		_:
			_visual.polygon = PackedVector2Array([Vector2(-7, -4), Vector2(7, -4), Vector2(5, 6), Vector2(-5, 6)])
			_visual.color = Color(0.6, 0.38, 0.18)
	add_child(_visual)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	if GameState.soft_paused:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var d: float = global_position.distance_to(player.global_position)
	if d <= GameState.pixels(GameState.pickup_radius) * 2.2:
		if not _magnetized:
			Juice.spawn_vacuum_arc(global_position, player.global_position, Color(0.85, 0.65, 0.3, 0.5))
		_magnetized = true
	if _magnetized:
		global_position = global_position.move_toward(player.global_position, 260.0 * delta)
		if d < 14.0:
			_collect()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	match kind:
		"wood":
			GameState.add_wood(amount)
		"stone":
			GameState.add_stone(amount)
		"berry":
			GameState.add_berries(amount)
	queue_free()
