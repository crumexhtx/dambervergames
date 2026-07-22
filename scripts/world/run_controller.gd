extends Node2D
## Main run scene controller.

@onready var world: Node2D = $World
@onready var enemies: Node2D = $World/Enemies
@onready var player: Player = $World/Player
@onready var camera: FollowCamera = $World/Camera
@onready var fx: Node2D = $World/FX
@onready var hud: HUD = $UI/HUD
@onready var level_up_ui: LevelUpUI = $UI/LevelUpUI
@onready var pause_menu: PauseMenu = $UI/PauseMenu
@onready var summary: Control = $UI/Summary
@onready var joystick: VirtualJoystick = $UI/Joystick
@onready var dash_btn: Button = $UI/DashButton
@onready var pause_btn: Button = $UI/PauseButton

var wave_director: WaveDirector
var _pending_levelups: int = 0


func _ready() -> void:
	summary.visible = false
	Juice.register_fx_layer(fx)
	Juice.set_perf_lite(MetaProgression.perf_lite_mode)
	camera.target = player
	_apply_safe_area()
	ArenaBuilder.build(world)
	GameState.start_run()
	player.weapon_manager.ensure_weapons()

	wave_director = WaveDirector.new()
	wave_director.name = "WaveDirector"
	add_child(wave_director)
	wave_director.setup(world, enemies)
	wave_director.banner.connect(hud.show_banner)
	wave_director.boss_phase_started.connect(func(): hud.show_banner("BOSS", 2.5))
	wave_director.extract_opened.connect(func(reduced: bool):
		hud.show_banner("Extract open!" + (" (reduced)" if reduced else ""), 3.0)
	)
	wave_director.start()
	hud.bind_wave_director(wave_director)

	GameState.level_up.connect(_on_level_up)
	GameState.run_ended.connect(_on_run_ended)

	joystick.move_vector.connect(player.set_move_input)
	joystick.dash_requested.connect(player.try_dash)
	dash_btn.pressed.connect(player.try_dash)
	pause_btn.pressed.connect(pause_menu.open_menu)
	pause_menu.quit_pressed.connect(_quit_to_menu)
	level_up_ui.card_chosen.connect(_on_card_chosen)

	var extract := world.get_node_or_null("ExtractZone")
	if extract:
		extract.extract_progress.connect(hud.set_extract_progress)


func _apply_safe_area() -> void:
	# Inset HUD / controls away from notches and home indicators
	var safe: Rect2 = DisplayServer.get_display_safe_area()
	var win: Vector2i = DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return
	var left := float(safe.position.x)
	var top := float(safe.position.y)
	var right := float(win.x) - (safe.position.x + safe.size.x)
	var bottom := float(win.y) - (safe.position.y + safe.size.y)
	# Clamp nonsense on desktop (full window = zero insets)
	left = maxf(0.0, left)
	top = maxf(0.0, top)
	right = maxf(0.0, right)
	bottom = maxf(0.0, bottom)
	var top_box := hud.get_node("Top") as Control
	if top_box:
		top_box.offset_top = 12.0 + top
		top_box.offset_left = 16.0 + left
		top_box.offset_right = -16.0 - right
	var bottom_box := hud.get_node("Bottom") as Control
	if bottom_box:
		bottom_box.offset_bottom = -16.0 - bottom
		bottom_box.offset_top = -80.0 - bottom
		bottom_box.offset_left = 16.0 + left
		bottom_box.offset_right = -16.0 - right
	pause_btn.offset_top = 16.0 + top
	pause_btn.offset_bottom = 72.0 + top  # ~56px tall touch target
	pause_btn.offset_left = -112.0 - right
	pause_btn.offset_right = -20.0 - right
	dash_btn.offset_bottom = -24.0 - bottom
	dash_btn.offset_top = -120.0 - bottom
	dash_btn.offset_right = -20.0 - right
	dash_btn.offset_left = -160.0 - right
	var joy_base := joystick.get_node_or_null("Base") as Control
	if joy_base:
		joy_base.offset_bottom = -24.0 - bottom
		joy_base.offset_top = -184.0 - bottom
		joy_base.offset_left = 24.0 + left


func _quit_to_menu() -> void:
	GameState.abandon_run()
	get_tree().paused = false
	GameState.set_soft_paused(false)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.open_menu()


func _on_level_up(_level: int) -> void:
	_pending_levelups += 1
	_try_show_levelup()


func _try_show_levelup() -> void:
	if _pending_levelups <= 0 or level_up_ui.visible:
		return
	_pending_levelups -= 1
	var offers := UpgradePool.roll_offers(3)
	level_up_ui.show_offers(offers)
	hud.show_banner("LEVEL UP!", 1.2)


func _on_card_chosen(card: Dictionary) -> void:
	UpgradePool.apply(card, player)
	# Weapon slot unlocks at 3 and 6 are handled by offers containing new weapons
	_try_show_levelup()


func _on_run_ended(success: bool, summary_data: Dictionary) -> void:
	get_tree().paused = false
	GameState.set_soft_paused(false)
	summary.visible = true
	if summary.has_method("show_summary"):
		summary.show_summary(success, summary_data)
	hud.show_banner("Victory!" if success else "Defeat...", 3.0)
