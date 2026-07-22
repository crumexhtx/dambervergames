extends WeaponBase
class_name SapSprayWeapon


func _ready() -> void:
	weapon_id = "sap"
	policy = Policy.FACING
	base_cooldown = 0.4
	base_damage = 6.0
	base_range = 2.2


func fire() -> void:
	var facing := player.last_move_dir.normalized()
	var cone_half := deg_to_rad(25.0)
	var r := range_px()
	# Visual cone
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		facing.rotated(-cone_half) * r,
		facing.rotated(cone_half) * r,
	])
	poly.color = Color(0.95, 0.75, 0.2, 0.35)
	poly.z_index = 4
	player.add_child(poly)
	var tw := poly.create_tween()
	tw.tween_property(poly, "modulate:a", 0.0, 0.15)
	tw.tween_callback(poly.queue_free)

	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - player.global_position
		var d := to_e.length()
		if d > r or d < 0.01:
			continue
		var ang := facing.angle_to(to_e.normalized())
		if absf(ang) <= cone_half and e.has_method("take_damage"):
			e.take_damage(damage(), player.global_position)
			if e.has_method("apply_slow"):
				e.apply_slow(0.2, 1.0)
