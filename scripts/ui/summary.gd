extends Control
class_name SummaryScreen

@onready var title: Label = $Panel/VBox/Title
@onready var body: Label = $Panel/VBox/Body
@onready var continue_btn: Button = $Panel/VBox/Continue


func _ready() -> void:
	continue_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)


func show_summary(success: bool, summary: Dictionary) -> void:
	if success:
		title.text = "Dam Secure!"
	elif summary.get("partial_bank", false):
		title.text = "Bonk! (salvaged some wood)"
	else:
		title.text = "Bonk! Flattened!"
	body.text = "\n".join([
		"Wave reached: %s" % str(summary.get("wave", 0)),
		"Time alive: %.0fs" % float(summary.get("time_alive", 0)),
		"Wood banked: %s" % str(summary.get("wood_banked", 0)),
		"Wood carried: %s" % str(summary.get("wood_carried", 0)),
		"Kills: %s" % str(summary.get("kills", 0)),
		"Damage dealt: %s" % str(summary.get("damage_dealt", 0)),
		"Level: %s" % str(summary.get("level", 1)),
		"Boss killed: %s" % ("Yes" if summary.get("boss_killed", false) else "No"),
		"Upgrades: %s" % ", ".join(summary.get("upgrades", [])),
	])
