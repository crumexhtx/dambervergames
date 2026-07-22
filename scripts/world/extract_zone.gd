extends Area2D
class_name ExtractZone
## Dam extract platform — hold 3s with ≥1 wood when extract is available.

signal extract_progress(t: float)
signal extract_complete

var channeling: bool = false
var channel: float = 0.0
const CHANNEL_TIME := 3.0
var _player_inside: bool = false
var _visual: Polygon2D
var _label: Label


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


func _build() -> void:
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(-70, -40), Vector2(70, -40), Vector2(90, 30), Vector2(-90, 30)
	])
	_visual.color = Color(0.45, 0.28, 0.12, 0.85)
	add_child(_visual)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-80, -40), Vector2(0, -70), Vector2(80, -40)])
	roof.color = Color(0.35, 0.2, 0.08)
	add_child(roof)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(160, 70)
	shape.shape = rect
	add_child(shape)
	_label = Label.new()
	_label.text = "DAM"
	_label.position = Vector2(-20, -10)
	_label.add_theme_font_size_override("font_size", 18)
	add_child(_label)


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
	# Highlight when available
	if GameState.extract_available:
		_visual.modulate = Color(1.2, 1.1, 0.8)
		_label.text = "EXTRACT"
	else:
		_visual.modulate = Color.WHITE
		_label.text = "DAM"
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
		extract_complete.emit()
		GameState.succeed_extract()
		channel = 0.0
		channeling = false
