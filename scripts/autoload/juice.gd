extends Node
## Screen shake, damage numbers, death pops.

var camera: Camera2D
var fx_layer: Node2D
var _shake_time: float = 0.0
var _shake_mag: float = 0.0


func register_camera(cam: Camera2D) -> void:
	camera = cam


func register_fx_layer(layer: Node2D) -> void:
	fx_layer = layer


func _process(delta: float) -> void:
	if camera == null:
		return
	if _shake_time > 0.0:
		_shake_time -= delta
		var m := _shake_mag * (0.35 if MetaProgression.reduce_shake else 1.0)
		camera.offset = Vector2(randf_range(-m, m), randf_range(-m, m))
		if _shake_time <= 0.0:
			camera.offset = Vector2.ZERO


func shake(magnitude: float = 6.0, duration: float = 0.15) -> void:
	_shake_mag = magnitude
	_shake_time = maxf(_shake_time, duration)


func spawn_damage_number(world_pos: Vector2, amount: float, crit: bool = false) -> void:
	if not MetaProgression.show_damage_numbers:
		return
	if fx_layer == null:
		return
	var label := Label.new()
	label.text = str(int(round(amount)))
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 22 if crit else 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if crit else Color(1, 1, 1))
	label.position = world_pos + Vector2(-10, -20)
	fx_layer.add_child(label)
	var tw := label.create_tween()
	tw.tween_property(label, "position", label.position + Vector2(0, -28), 0.45)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tw.tween_callback(label.queue_free)


func spawn_leaf_burst(world_pos: Vector2, color: Color = Color(0.45, 0.7, 0.3)) -> void:
	if fx_layer == null:
		return
	for i in 8:
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(0, 4)])
		p.color = color
		p.position = world_pos
		fx_layer.add_child(p)
		var dir := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(20, 50)
		var tw := p.create_tween()
		tw.tween_property(p, "position", world_pos + dir, 0.35)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.35)
		tw.tween_callback(p.queue_free)
