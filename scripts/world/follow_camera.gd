extends Camera2D
class_name FollowCamera

@export var lead: float = 40.0
@export var smooth: float = 8.0
var target: Node2D


func _ready() -> void:
	make_current()
	Juice.register_camera(self)


func _process(delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player")
		return
	var desired := target.global_position
	if target is Player:
		desired += (target as Player).last_move_dir * lead
	global_position = global_position.lerp(desired, clampf(smooth * delta, 0.0, 1.0))
