extends StaticBody2D
class_name LootNode
## Chewable world node: sapling, tree, rock, berry bush, crate.

@export var node_type: String = "tree"
@export var max_hp: float = 60.0

var hp: float = 60.0
var _visual_root: Node2D
var _destroyed: bool = false


func _ready() -> void:
	add_to_group("loot_nodes")
	collision_layer = 4
	collision_mask = 0
	_apply_type()
	hp = max_hp * DebugBalance.node_hp_mult
	_build()


func setup(type: String) -> void:
	node_type = type
	_apply_type()
	hp = max_hp * DebugBalance.node_hp_mult
	if is_inside_tree():
		_build()


func _apply_type() -> void:
	match node_type:
		"sapling":
			max_hp = 20.0
		"tree":
			max_hp = 60.0
		"rock":
			max_hp = 80.0
		"berry":
			max_hp = 15.0
		"crate":
			max_hp = 40.0
		_:
			max_hp = 60.0


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_visual_root = Node2D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)
	match node_type:
		"sapling":
			Silhouettes.build_tree(_visual_root, true)
		"rock":
			Silhouettes.build_rock(_visual_root)
		"berry":
			Silhouettes.build_berry_bush(_visual_root)
		"crate":
			Silhouettes.build_crate(_visual_root)
		_:
			Silhouettes.build_tree(_visual_root, false)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)


func receive_chew(amount: float) -> void:
	if _destroyed:
		return
	hp -= amount
	if _visual_root:
		_visual_root.modulate = Color(1.2, 1.1, 1.0)
		var tw := create_tween()
		tw.tween_property(_visual_root, "modulate", Color.WHITE, 0.08)
	if hp <= 0.0:
		_destroy()


func _destroy() -> void:
	_destroyed = true
	var world := get_tree().current_scene.get_node_or_null("World")
	if world:
		match node_type:
			"sapling":
				_spawn_pickup(world, "wood", randi_range(1, 2))
			"tree":
				_spawn_pickup(world, "wood", randi_range(3, 5))
				if randf() < 0.1:
					_spawn_pickup(world, "berry", 1)
				if randf() < 0.15:
					GameState.heal(10.0)
					Juice.spawn_damage_number(global_position, 10, false)
			"rock":
				_spawn_pickup(world, "stone", randi_range(2, 4))
			"berry":
				_spawn_pickup(world, "berry", randi_range(1, 2))
			"crate":
				_spawn_pickup(world, "wood", randi_range(1, 3))
				_spawn_pickup(world, "stone", randi_range(0, 2))
				var gem := Area2D.new()
				gem.set_script(preload("res://scripts/loot/xp_gem.gd"))
				world.add_child(gem)
				gem.global_position = global_position
				gem.setup(5)
	var burst_col := Color(0.4, 0.6, 0.3)
	Juice.spawn_leaf_burst(global_position, burst_col)
	queue_free()


func _spawn_pickup(world: Node, kind: String, amount: int) -> void:
	if amount <= 0:
		return
	var p := Area2D.new()
	p.set_script(preload("res://scripts/loot/pickup.gd"))
	world.add_child(p)
	p.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
	p.setup(kind, amount)
