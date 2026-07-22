extends Control

@onready var shake_check: CheckButton = $Panel/VBox/ReduceShake
@onready var dmg_check: CheckButton = $Panel/VBox/DamageNumbers
@onready var joy_check: CheckButton = $Panel/VBox/LargeJoystick
@onready var perf_check: CheckButton = $Panel/VBox/PerfLite
@onready var debug_box: VBoxContainer = $Panel/VBox/Debug
@onready var back_btn: Button = $Panel/VBox/Back


func _ready() -> void:
	shake_check.button_pressed = MetaProgression.reduce_shake
	dmg_check.button_pressed = MetaProgression.show_damage_numbers
	joy_check.button_pressed = MetaProgression.large_joystick
	perf_check.button_pressed = MetaProgression.perf_lite_mode
	shake_check.toggled.connect(func(v):
		MetaProgression.reduce_shake = v
		MetaProgression.save()
	)
	dmg_check.toggled.connect(func(v):
		MetaProgression.show_damage_numbers = v
		MetaProgression.save()
	)
	joy_check.toggled.connect(func(v):
		MetaProgression.large_joystick = v
		MetaProgression.save()
	)
	perf_check.toggled.connect(func(v):
		MetaProgression.perf_lite_mode = v
		MetaProgression.save()
		Juice.set_perf_lite(v)
	)
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	_build_debug()


func _build_debug() -> void:
	_add_slider("Wave budget", DebugBalance.wave_budget_mult, 0.5, 2.0, func(v): DebugBalance.wave_budget_mult = v)
	_add_slider("Enemy HP mult", DebugBalance.hp_mult, 0.5, 2.0, func(v): DebugBalance.hp_mult = v)
	_add_slider("Enemy DMG mult", DebugBalance.dmg_mult, 0.5, 2.0, func(v): DebugBalance.dmg_mult = v)
	_add_slider("Player DMG mult", DebugBalance.player_damage_mult, 0.5, 2.5, func(v): DebugBalance.player_damage_mult = v)
	_add_slider("XP mult", DebugBalance.xp_mult, 0.5, 3.0, func(v): DebugBalance.xp_mult = v)
	_add_slider("Breather", DebugBalance.breather_duration, 1.0, 5.0, func(v): DebugBalance.breather_duration = v)
	_add_slider("Node HP mult", DebugBalance.node_hp_mult, 0.5, 2.0, func(v): DebugBalance.node_hp_mult = v)
	var reset := Button.new()
	reset.text = "Reset debug defaults"
	reset.pressed.connect(func():
		DebugBalance.reset_defaults()
		for c in debug_box.get_children():
			c.queue_free()
		_build_debug()
	)
	debug_box.add_child(reset)


func _add_slider(label: String, value: float, mn: float, mx: float, setter: Callable) -> void:
	var row := VBoxContainer.new()
	var lab := Label.new()
	lab.text = "%s: %.2f" % [label, value]
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = 0.05
	sl.value = value
	sl.value_changed.connect(func(v):
		setter.call(v)
		lab.text = "%s: %.2f" % [label, v]
	)
	row.add_child(lab)
	row.add_child(sl)
	debug_box.add_child(row)
