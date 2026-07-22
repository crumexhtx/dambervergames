extends WeaponBase
class_name StickThrowWeapon


func _ready() -> void:
	weapon_id = "stick"
	policy = Policy.NEAREST
	base_cooldown = 0.85
	base_damage = 18.0
	base_range = 6.0
	prioritize_elites = true


func fire() -> void:
	var target := find_target()
	if target == null:
		return
	var stick := Area2D.new()
	stick.set_script(preload("res://scripts/weapons/projectile_mover.gd"))
	stick.collision_layer = 16
	stick.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	stick.add_child(shape)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-8, -2), Vector2(10, 0), Vector2(-8, 2)])
	poly.color = Color(0.55, 0.32, 0.12)
	stick.add_child(poly)
	var world := get_tree().current_scene.get_node("World")
	world.add_child(stick)
	stick.global_position = player.global_position
	var dir := (target.global_position - player.global_position).normalized()
	stick.rotation = dir.angle()
	var speed := GameState.pixels(8.0)
	var life := GameState.pixels(6.0) / speed
	stick.setup(dir * speed, life, damage(), player)
	Juice.play_sfx("stick")
