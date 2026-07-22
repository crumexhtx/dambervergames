extends Control

@onready var list: VBoxContainer = $Panel/VBox/List
@onready var wood_label: Label = $Panel/VBox/Wood
@onready var back_btn: Button = $Panel/VBox/Back


func _ready() -> void:
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	_refresh()


func _refresh() -> void:
	wood_label.text = "Banked Wood: %d" % MetaProgression.banked_wood
	for c in list.get_children():
		c.queue_free()
	for u in MetaProgression.UNLOCKS:
		var row := HBoxContainer.new()
		var lab := Label.new()
		var owned := MetaProgression.is_unlocked(str(u.id))
		lab.text = "%s — %s (%d wood)%s" % [u.name, u.desc, int(u.cost), " ✓" if owned else ""]
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lab)
		var btn := Button.new()
		btn.text = "Owned" if owned else "Buy"
		btn.disabled = owned or not MetaProgression.can_buy(str(u.id))
		btn.pressed.connect(_buy.bind(str(u.id)))
		row.add_child(btn)
		list.add_child(row)


func _buy(id: String) -> void:
	if MetaProgression.buy(id):
		_refresh()
