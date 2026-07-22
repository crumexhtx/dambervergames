extends Node
## Screen shake, damage numbers, death pops, vacuum arcs, SFX.

var camera: Camera2D
var fx_layer: Node2D
var _shake_time: float = 0.0
var _shake_mag: float = 0.0
var _sfx_cooldown: Dictionary = {}
var _players: Dictionary = {}  # id -> AudioStreamPlayer
var _perf_lite: bool = false

const SFX_MAP := {
	"tail": "res://assets/sfx/tail.wav",
	"stick": "res://assets/sfx/stick.wav",
	"sap": "res://assets/sfx/sap.wav",
	"chomp": "res://assets/sfx/chomp.wav",
	"level_up": "res://assets/sfx/level_up.wav",
	"pickup": "res://assets/sfx/pickup.wav",
	"hurt": "res://assets/sfx/hurt.wav",
	"extract": "res://assets/sfx/extract.wav",
}


func _ready() -> void:
	_boot_sfx()


func _boot_sfx() -> void:
	for id in SFX_MAP.keys():
		var path: String = SFX_MAP[id]
		if not ResourceLoader.exists(path):
			continue
		var stream = load(path)
		if stream == null:
			continue
		var p := AudioStreamPlayer.new()
		p.name = "sfx_%s" % id
		p.stream = stream
		p.bus = "Master"
		p.max_polyphony = 4
		add_child(p)
		_players[id] = p


func register_camera(cam: Camera2D) -> void:
	camera = cam


func register_fx_layer(layer: Node2D) -> void:
	fx_layer = layer


func set_perf_lite(enabled: bool) -> void:
	_perf_lite = enabled


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
	if _perf_lite and Engine.get_frames_per_second() < 45:
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
	var count := 4 if _perf_lite else 8
	for i in count:
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(0, 4)])
		p.color = color
		p.position = world_pos
		fx_layer.add_child(p)
		var dir: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(20, 50)
		var tw := p.create_tween()
		tw.tween_property(p, "position", world_pos + dir, 0.35)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.35)
		tw.tween_callback(p.queue_free)


func spawn_vacuum_arc(from: Vector2, to: Vector2, color: Color = Color(0.55, 0.85, 1.0, 0.55)) -> void:
	if fx_layer == null or _perf_lite:
		return
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = color
	line.z_index = 40
	var mid: Vector2 = (from + to) * 0.5 + Vector2.RIGHT.rotated(randf() * TAU) * 12.0
	line.points = PackedVector2Array([from, mid, to])
	fx_layer.add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.18)
	tw.tween_callback(line.queue_free)


func level_up_stinger() -> void:
	shake(5.0, 0.18)
	if fx_layer == null:
		play_sfx("level_up")
		return
	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(-40, -8), Vector2(40, -8), Vector2(40, 8), Vector2(-40, 8)
	])
	flash.color = Color(1.0, 0.92, 0.45, 0.7)
	flash.z_index = 90
	var player := get_tree().get_first_node_in_group("player") as Node2D
	flash.position = player.global_position if player else Vector2.ZERO
	fx_layer.add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "scale", Vector2(2.5, 2.5), 0.25)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)
	play_sfx("level_up")


func play_sfx(id: String) -> void:
	var now := Time.get_ticks_msec()
	var last: int = int(_sfx_cooldown.get(id, 0))
	if now - last < 70:
		return
	_sfx_cooldown[id] = now
	var p: AudioStreamPlayer = _players.get(id) as AudioStreamPlayer
	if p and p.stream:
		p.play()
