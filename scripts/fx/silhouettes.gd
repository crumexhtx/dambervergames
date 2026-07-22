extends RefCounted
class_name Silhouettes
## Readable stylized silhouettes (polygon kits) for beaver, enemies, and props.
## Articulated builds name child nodes (body, head, tail, …) for CharacterAnimator.


static func clear_children(node: Node) -> void:
	while node.get_child_count() > 0:
		var c := node.get_child(0)
		node.remove_child(c)
		c.free()


static func make_poly(pts: PackedVector2Array, color: Color, z: int = 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = color
	p.z_index = z
	return p


static func make_part(part_name: String, pts: PackedVector2Array, color: Color, z: int = 0, pos: Vector2 = Vector2.ZERO) -> Node2D:
	var root := Node2D.new()
	root.name = part_name
	root.position = pos
	var poly := make_poly(pts, color, z)
	# Store polygons in local space around origin for cleaner pivots
	root.add_child(poly)
	return root


static func build_articulated(host: Node2D, key: String, elite: bool = false) -> void:
	match key:
		"beaver":
			build_beaver(host)
		"hornet":
			build_hornet(host, elite)
		"rat":
			build_rat(host, elite)
		"fox":
			build_fox(host, elite)
		"drone":
			build_drone(host, elite)
		"bulldozer":
			build_bulldozer(host)
		_:
			build_hornet(host, elite)


static func build_beaver(host: Node2D) -> void:
	clear_children(host)
	var body := make_part("body", PackedVector2Array([
		Vector2(-16, -6), Vector2(14, -10), Vector2(18, 8), Vector2(8, 16), Vector2(-14, 14), Vector2(-20, 2)
	]), Color(0.62, 0.4, 0.22))
	host.add_child(body)

	var head := make_part("head", PackedVector2Array([
		Vector2(-6, -8), Vector2(8, -6), Vector2(6, 6), Vector2(-8, 4)
	]), Color(0.7, 0.48, 0.28), 1, Vector2(16, -6))
	host.add_child(head)

	var snout := make_part("snout", PackedVector2Array([
		Vector2(0, -2), Vector2(8, 0), Vector2(0, 4)
	]), Color(0.95, 0.85, 0.35), 2, Vector2(8, 2))
	head.add_child(snout)

	var eye := make_part("eye", PackedVector2Array([
		Vector2(0, 0), Vector2(3, 0), Vector2(3, 3), Vector2(0, 3)
	]), Color(0.1, 0.08, 0.05), 3, Vector2(-2, -4))
	head.add_child(eye)

	var tail := make_part("tail", PackedVector2Array([
		Vector2(-4, -6), Vector2(4, -4), Vector2(0, 12), Vector2(-12, 8), Vector2(-14, -2)
	]), Color(0.28, 0.16, 0.1), -1, Vector2(-16, 10))
	host.add_child(tail)

	var foot_l := make_part("foot_l", PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(3, 5), Vector2(-3, 5)
	]), Color(0.45, 0.28, 0.14), 0, Vector2(-6, 14))
	host.add_child(foot_l)
	var foot_r := make_part("foot_r", PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(3, 5), Vector2(-3, 5)
	]), Color(0.45, 0.28, 0.14), 0, Vector2(6, 14))
	host.add_child(foot_r)


static func build_hornet(host: Node2D, elite: bool = false) -> void:
	clear_children(host)
	var body_c := Color(0.95, 0.78, 0.12) if not elite else Color(1.0, 0.45, 0.12)
	var body := make_part("body", PackedVector2Array([
		Vector2(-6, -4), Vector2(10, -2), Vector2(8, 8), Vector2(-8, 6)
	]), body_c)
	host.add_child(body)
	body.add_child(make_poly(PackedVector2Array([
		Vector2(-2, -2), Vector2(2, -2), Vector2(1, 6), Vector2(-3, 5)
	]), Color(0.12, 0.1, 0.08), 1))

	var wing_l := make_part("wing_l", PackedVector2Array([
		Vector2(-4, 0), Vector2(4, -8), Vector2(8, 2)
	]), Color(0.75, 0.9, 1.0, 0.55), -1, Vector2(0, -4))
	host.add_child(wing_l)
	var wing_r := make_part("wing_r", PackedVector2Array([
		Vector2(-2, 0), Vector2(8, -8), Vector2(8, 2)
	]), Color(0.75, 0.9, 1.0, 0.45), -1, Vector2(6, -2))
	host.add_child(wing_r)

	var stinger := make_part("stinger", PackedVector2Array([
		Vector2(0, 0), Vector2(-6, 4), Vector2(2, 4)
	]), Color(0.2, 0.15, 0.1), 1, Vector2(-8, 4))
	host.add_child(stinger)


static func build_rat(host: Node2D, elite: bool = false) -> void:
	clear_children(host)
	var fur := Color(0.55, 0.4, 0.35) if not elite else Color(0.85, 0.25, 0.22)
	var body := make_part("body", PackedVector2Array([
		Vector2(-10, -4), Vector2(8, -6), Vector2(14, 2), Vector2(6, 10), Vector2(-8, 8)
	]), fur)
	host.add_child(body)

	var head := make_part("head", PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -2), Vector2(0, 4)
	]), fur.darkened(0.1), 1, Vector2(12, -2))
	host.add_child(head)

	var ear := make_part("ear", PackedVector2Array([
		Vector2(-2, 0), Vector2(4, -4), Vector2(4, 4)
	]), Color(0.75, 0.45, 0.45), 1, Vector2(2, -6))
	head.add_child(ear)

	var tail := make_part("tail", PackedVector2Array([
		Vector2(0, 0), Vector2(-12, -6), Vector2(-8, 2)
	]), Color(0.7, 0.45, 0.4), -1, Vector2(-10, 2))
	host.add_child(tail)


static func build_fox(host: Node2D, elite: bool = false) -> void:
	clear_children(host)
	var fur := Color(0.88, 0.48, 0.18) if not elite else Color(1.0, 0.25, 0.15)
	var body := make_part("body", PackedVector2Array([
		Vector2(-14, -4), Vector2(12, -8), Vector2(18, 4), Vector2(4, 12), Vector2(-12, 10)
	]), fur)
	host.add_child(body)

	var head := make_part("head", PackedVector2Array([
		Vector2(-6, -4), Vector2(8, -2), Vector2(4, 6), Vector2(-6, 4)
	]), fur, 1, Vector2(14, -4))
	host.add_child(head)
	head.add_child(make_poly(PackedVector2Array([Vector2(-2, -6), Vector2(2, -14), Vector2(6, -4)]), fur, 1))
	head.add_child(make_poly(PackedVector2Array([Vector2(-8, -4), Vector2(-4, -12), Vector2(0, -2)]), fur, 1))

	body.add_child(make_poly(PackedVector2Array([
		Vector2(-2, 2), Vector2(8, 0), Vector2(6, 10), Vector2(-2, 8)
	]), Color(0.95, 0.9, 0.8), 1))

	var tail := make_part("tail", PackedVector2Array([
		Vector2(0, 0), Vector2(-14, -8), Vector2(-10, 8), Vector2(2, 8)
	]), fur.lightened(0.1), -1, Vector2(-14, 2))
	host.add_child(tail)


static func build_drone(host: Node2D, elite: bool = false) -> void:
	clear_children(host)
	var metal := Color(0.42, 0.48, 0.55) if not elite else Color(0.75, 0.3, 0.4)
	var body := make_part("body", PackedVector2Array([
		Vector2(-12, -8), Vector2(12, -8), Vector2(12, 8), Vector2(-12, 8)
	]), metal)
	host.add_child(body)
	body.add_child(make_poly(PackedVector2Array([
		Vector2(-6, -4), Vector2(6, -4), Vector2(6, 4), Vector2(-6, 4)
	]), Color(0.2, 0.75, 0.85), 1))

	var rotor_l := make_part("rotor_l", PackedVector2Array([
		Vector2(-6, 0), Vector2(6, -4), Vector2(6, 4)
	]), Color(0.2, 0.2, 0.25, 0.7), -1, Vector2(-10, -10))
	host.add_child(rotor_l)
	var rotor_r := make_part("rotor_r", PackedVector2Array([
		Vector2(-6, -4), Vector2(6, 0), Vector2(-6, 4)
	]), Color(0.2, 0.2, 0.25, 0.7), -1, Vector2(10, -10))
	host.add_child(rotor_r)


static func build_bulldozer(host: Node2D) -> void:
	clear_children(host)
	var body := make_part("body", PackedVector2Array([
		Vector2(-20, -12), Vector2(16, -12), Vector2(20, 12), Vector2(-20, 14)
	]), Color(0.35, 0.38, 0.42))
	host.add_child(body)
	body.add_child(make_poly(PackedVector2Array([
		Vector2(-8, -18), Vector2(8, -18), Vector2(10, -10), Vector2(-10, -10)
	]), Color(0.45, 0.5, 0.55), 1))

	var blade := make_part("blade", PackedVector2Array([
		Vector2(-26, 6), Vector2(24, 4), Vector2(22, 16), Vector2(-24, 16)
	]), Color(0.7, 0.72, 0.78), 2)
	host.add_child(blade)

	var tracks := make_part("tracks", PackedVector2Array([
		Vector2(-18, 10), Vector2(18, 10), Vector2(16, 20), Vector2(-16, 20)
	]), Color(0.15, 0.15, 0.18), -1)
	host.add_child(tracks)


static func build_tree(host: Node2D, sapling: bool = false) -> void:
	clear_children(host)
	var trunk_h := 14 if sapling else 22
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-4, 6), Vector2(4, 6), Vector2(4, 6 + trunk_h * 0.5), Vector2(-4, 6 + trunk_h * 0.5)
	]), Color(0.42, 0.26, 0.12), -1))
	if sapling:
		host.add_child(make_poly(PackedVector2Array([
			Vector2(0, -16), Vector2(12, 8), Vector2(-12, 8)
		]), Color(0.4, 0.7, 0.32)))
	else:
		host.add_child(make_poly(PackedVector2Array([
			Vector2(0, -30), Vector2(18, 4), Vector2(-18, 4)
		]), Color(0.22, 0.52, 0.24)))
		host.add_child(make_poly(PackedVector2Array([
			Vector2(0, -18), Vector2(14, 10), Vector2(-14, 10)
		]), Color(0.3, 0.62, 0.28), 1))


static func build_rock(host: Node2D) -> void:
	clear_children(host)
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-16, -6), Vector2(-4, -14), Vector2(14, -10), Vector2(18, 6), Vector2(-12, 12)
	]), Color(0.52, 0.54, 0.58)))
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-6, -8), Vector2(4, -10), Vector2(2, -2)
	]), Color(0.65, 0.66, 0.7), 1))


static func build_berry_bush(host: Node2D) -> void:
	clear_children(host)
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-12, -4), Vector2(0, -14), Vector2(12, -4), Vector2(10, 10), Vector2(-10, 10)
	]), Color(0.28, 0.55, 0.28)))
	for pt in [Vector2(-6, 0), Vector2(4, -4), Vector2(0, 4), Vector2(8, 2)]:
		host.add_child(make_poly(PackedVector2Array([
			pt + Vector2(-3, 0), pt + Vector2(0, -3), pt + Vector2(3, 0), pt + Vector2(0, 3)
		]), Color(0.85, 0.15, 0.35), 2))


static func build_crate(host: Node2D) -> void:
	clear_children(host)
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)
	]), Color(0.68, 0.48, 0.22)))
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-12, -2), Vector2(12, -2), Vector2(12, 2), Vector2(-12, 2)
	]), Color(0.45, 0.3, 0.12), 1))
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-2, -12), Vector2(2, -12), Vector2(2, 12), Vector2(-2, 12)
	]), Color(0.45, 0.3, 0.12), 1))


static func build_dam(host: Node2D) -> void:
	clear_children(host)
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-70, -20), Vector2(70, -20), Vector2(90, 30), Vector2(-90, 30)
	]), Color(0.48, 0.3, 0.14)))
	host.add_child(make_poly(PackedVector2Array([
		Vector2(-80, -20), Vector2(0, -55), Vector2(80, -20)
	]), Color(0.38, 0.22, 0.1), 1))
	for x in [-40, -10, 20, 50]:
		host.add_child(make_poly(PackedVector2Array([
			Vector2(x, 8), Vector2(x + 24, 8), Vector2(x + 24, 16), Vector2(x, 16)
		]), Color(0.55, 0.35, 0.18), 2))
