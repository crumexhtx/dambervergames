extends Control
class_name VirtualJoystick
## Left-side virtual stick for mobile; also works with mouse.

signal move_vector(vec: Vector2)
signal dash_requested

@onready var base: Panel = $Base
@onready var knob: Panel = $Base/Knob

var _touch_index: int = -1
var _active: bool = false
var _center: Vector2 = Vector2.ZERO
var max_radius: float = 70.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_size()
	base.gui_input.connect(_on_base_gui)


func _apply_size() -> void:
	var size_px := 200.0 if MetaProgression.large_joystick else 160.0
	base.custom_minimum_size = Vector2(size_px, size_px)
	base.size = Vector2(size_px, size_px)
	max_radius = size_px * 0.35
	knob.position = Vector2(size_px, size_px) * 0.5 - knob.size * 0.5


func _on_base_gui(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and _touch_index == -1:
			_touch_index = st.index
			_begin(st.position)
		elif not st.pressed and st.index == _touch_index:
			_end()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _touch_index:
			_update(sd.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_touch_index = 0
				_begin(mb.position)
			elif _active:
				_end()
	elif event is InputEventMouseMotion and _active and _touch_index == 0:
		_update((event as InputEventMouseMotion).position)


func _gui_input(event: InputEvent) -> void:
	# Dash on tap outside stick area of this control's empty region
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and not _point_in_base(st.position) and st.position.x > size.x * 0.45:
			dash_requested.emit()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.position.x > size.x * 0.55:
			# Only if not on UI buttons — parent run HUD handles dedicated dash button
			pass


func _point_in_base(local_pos: Vector2) -> bool:
	return base.get_rect().has_point(local_pos)


func _begin(local_pos: Vector2) -> void:
	_active = true
	_center = base.size * 0.5
	_update(local_pos)


func _update(local_pos: Vector2) -> void:
	if not _active:
		return
	var offset := local_pos - _center
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	knob.position = _center + offset - knob.size * 0.5
	var v := offset / max_radius
	move_vector.emit(v)


func _end() -> void:
	_active = false
	_touch_index = -1
	knob.position = base.size * 0.5 - knob.size * 0.5
	move_vector.emit(Vector2.ZERO)
