extends Node2D
class_name ArenaBuilder
## Hand-placed-ish forest clearing with random prop scatter.


static func build(world: Node2D) -> void:
	# Ground tint
	var ground := Polygon2D.new()
	var half := GameState.pixels(GameState.ARENA_HALF + 2.0)
	ground.polygon = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)
	])
	ground.color = Color(0.22, 0.45, 0.28)
	ground.z_index = -10
	world.add_child(ground)

	# Soft border ring
	var border := Line2D.new()
	border.width = 6.0
	border.default_color = Color(0.15, 0.3, 0.18, 0.8)
	var pts := PackedVector2Array()
	var bh := GameState.pixels(GameState.ARENA_HALF)
	for i in 65:
		var a := i * TAU / 64.0
		pts.append(Vector2(cos(a), sin(a)) * bh)
	border.points = pts
	border.z_index = -5
	world.add_child(border)

	# Ponds (slow zones as Area2D markers — visual only for v1 feel)
	for i in 2:
		var pond := Polygon2D.new()
		pond.polygon = PackedVector2Array([
			Vector2(-40, -20), Vector2(50, -15), Vector2(35, 30), Vector2(-45, 25)
		])
		pond.color = Color(0.25, 0.45, 0.7, 0.55)
		pond.position = Vector2(randf_range(-300, 300), randf_range(-200, 280))
		pond.z_index = -8
		world.add_child(pond)

	var props := Node2D.new()
	props.name = "LootNodes"
	world.add_child(props)

	_scatter(props, "tree", 14)
	_scatter(props, "sapling", 10)
	_scatter(props, "rock", 8)
	_scatter(props, "berry", 6)
	_scatter(props, "crate", 2)

	# Dam extract on north edge
	var dam := Area2D.new()
	dam.set_script(preload("res://scripts/world/extract_zone.gd"))
	dam.name = "ExtractZone"
	world.add_child(dam)
	dam.global_position = Vector2(0, -GameState.pixels(GameState.ARENA_HALF) + 50.0)


static func _scatter(parent: Node2D, type: String, count: int) -> void:
	var half := GameState.pixels(GameState.ARENA_HALF - 4.0)
	for i in count:
		var node := StaticBody2D.new()
		node.set_script(preload("res://scripts/loot/loot_node.gd"))
		parent.add_child(node)
		var pos := Vector2(randf_range(-half, half), randf_range(-half, half))
		# Keep dam north clear
		if pos.y < -half * 0.75 and absf(pos.x) < 120:
			pos.y += 180
		node.global_position = pos
		node.setup(type)
