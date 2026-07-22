extends Control

@onready var wood_label: Label = $VBox/Wood
@onready var play_btn: Button = $VBox/Play
@onready var unlocks_btn: Button = $VBox/Unlocks
@onready var settings_btn: Button = $VBox/Settings


func _ready() -> void:
	wood_label.text = "Banked Wood: %d" % MetaProgression.banked_wood
	play_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/run.tscn")
	)
	unlocks_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/unlocks.tscn")
	)
	settings_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")
	)
