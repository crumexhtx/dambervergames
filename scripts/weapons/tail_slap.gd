extends WeaponBase
class_name TailSlapWeapon


func _ready() -> void:
	weapon_id = "tail"
	policy = Policy.AURA
	base_cooldown = 0.9
	base_damage = 14.0
	base_range = 1.5


func fire() -> void:
	var r := range_px()
	var pulse := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(Vector2.RIGHT.rotated(i * TAU / 16.0) * r)
	pulse.polygon = pts
	pulse.color = Color(0.85, 0.55, 0.25, 0.4)
	pulse.z_index = 5
	player.add_child(pulse)
	var tw := pulse.create_tween()
	tw.tween_property(pulse, "modulate:a", 0.0, 0.2)
	tw.tween_callback(pulse.queue_free)

	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if player.global_position.distance_to(e.global_position) <= r and e.has_method("take_damage"):
			e.take_damage(damage(), player.global_position)
			hit_any = true
			if e.has_method("apply_knockback"):
				e.apply_knockback((e.global_position - player.global_position).normalized() * 110.0)
	if hit_any:
		Juice.play_sfx("tail")
