extends CanvasLayer
class_name PauseMenu

signal resume_pressed
signal quit_pressed

@onready var panel: PanelContainer = $Panel


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/VBox/Resume.pressed.connect(func():
		visible = false
		get_tree().paused = false
		GameState.set_soft_paused(false)
		resume_pressed.emit()
	)
	$Panel/VBox/Quit.pressed.connect(func():
		get_tree().paused = false
		GameState.set_soft_paused(false)
		quit_pressed.emit()
	)


func open_menu() -> void:
	visible = true
	get_tree().paused = true
	GameState.set_soft_paused(true)
