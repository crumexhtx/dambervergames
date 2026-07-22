extends Area2D
class_name ExtractZone
## Dam extract platform — hold 3s with ≥1 wood when extract is available.

signal extract_progress(t: float)
signal extract_complete

var channeling: bool = false
var channel: float = 0.0
const CHANNEL_TIME := 3.0
var _player_inside: bool = false
var _visual_root: Node2D
var _label: Label
var _pulse_ring: Polygon2D
var _pulse_t: float = 0.0
var _opened_fx_done: bool = false


func _ready() -> void:
	add_to_group("extract_zone")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_build()
	visible = true
	GameState.extract_available_changed.connect(_on_extract_flag)


func _build() -> void:
	_visual_root = Node2D.new()
	add_child(_visual_root)
	Silhouettes.build_dam(_visual_root)
	_pulse_ring = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		pts.append(Vector2.RIGHT.rotated(i * TAU / 24.0) * 95.0)
	_pulse_ring.polygon = pts
	_pulse_ring.color = Color(1.0, 0.85, 0.35, 0.0)
	_pulse_ring.z_index = -1
	add_child(_pulse_ring)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(160, 70)
	shape.shape = rect
	add_child(shape)
	_label = Label.new()
	_label.text = "DAM"
	_label.position = Vector2(-24, -8)
	_label.add_theme_font_size_override("font_size", 18)
	add_child(_label)


func _on_extract_flag(available: bool) -> void:
	if available and not _opened_fx_done:
		_opened_fx_done = true
		Juice.shake(6.0, 0.2)
		Juice.play_sfx("extract")
		# Directional cue: bright arrow triangle above dam
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(0, -90), Vector2(16, -60), Vector2(-16, -60)])
		arrow.color = Color(1.0, 0.9, 0.3, 0.95)
		arrow.z_index = 30
		add_child(arrow)
		var tw := arrow.create_tween()
		tw.set_loops(4)
		tw.tween_property(arrow, "position:y", -12.0, 0.35)
		tw.tween_property(arrow, "position:y", 0.0, 0.35)
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(arrow):
				arrow.queue_free()
		)


func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true


func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		channeling = false
		channel = 0.0
		extract_progress.emit(0.0)


func _process(delta: float) -> void:
	if not GameState.run_active or GameState.soft_paused:
		return
	if GameState.extract_available:
		_pulse_t += delta
		var a := 0.25 + 0.2 * sin(_pulse_t * 4.0)
		_pulse_ring.color = Color(1.0, 0.85, 0.35, a)
		_pulse_ring.scale = Vector2.ONE * (1.0 + 0.08 * sin(_pulse_t * 3.0))
		_visual_root.modulate = Color(1.35, 1.2, 0.9)
		_label.text = "EXTRACT"
		_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	else:
		_pulse_ring.color.a = 0.0
		_visual_root.modulate = Color.WHITE
		_label.text = "DAM"
		_label.remove_theme_color_override("font_color")
	if not _player_inside or not GameState.extract_available:
		return
	if GameState.wood < 1:
		_label.text = "Need wood!"
		return
	channeling = true
	channel += delta
	extract_progress.emit(channel / CHANNEL_TIME)
	_label.text = "Extracting… %d%%" % int(channel / CHANNEL_TIME * 100.0)
	if channel >= CHANNEL_TIME:
		Juice.play_sfx("extract")
		extract_complete.emit()
		GameState.succeed_extract()
		channel = 0.0
		channeling = false
