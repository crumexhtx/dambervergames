extends WeaponBase
class_name ToothChompWeapon
## Dash-melee burst toward nearest enemy in range (separate from player dash).


func _ready() -> void:
	weapon_id = "chomp"
	policy = Policy.NEAREST
	base_cooldown = 2.2
	base_damage = 28.0
	base_range = 2.0
	prioritize_elites = true


func fire() -> void:
	var target := find_target()
	if target == null:
		return
	var dmg := damage()
	var from := player.global_position
	# Lunge visual
	var bite := Polygon2D.new()
	bite.polygon = PackedVector2Array([
		Vector2(-6, -10), Vector2(14, 0), Vector2(-6, 10), Vector2(-2, 0)
	])
	bite.color = Color(0.95, 0.9, 0.7, 0.85)
	bite.z_index = 8
	var dir: Vector2 = (target.global_position - from).normalized()
	bite.rotation = dir.angle()
	player.add_child(bite)
	bite.position = dir * 18.0
	var tw := bite.create_tween()
	tw.tween_property(bite, "modulate:a", 0.0, 0.2)
	tw.tween_callback(bite.queue_free)
	if target.has_method("take_damage"):
		target.take_damage(dmg, from)
		if target.has_method("apply_knockback"):
			target.apply_knockback(dir * 120.0)
	Juice.play_sfx("chomp")
	Juice.shake(4.0, 0.08)
