extends Control
class_name HUD
## In-run HUD + optional dev overlay (F3 / Settings).

@onready var hp_bar: ProgressBar = $Top/HPBar
@onready var xp_bar: ProgressBar = $Top/XPBar
@onready var level_label: Label = $Top/LevelLabel
@onready var wave_label: Label = $Top/WaveLabel
@onready var resources: Label = $Top/Resources
@onready var weapons_label: Label = $Top/Weapons
@onready var dash_label: Label = $Bottom/DashLabel
@onready var boss_bar: ProgressBar = $Top/BossBar
@onready var boss_label: Label = $Top/BossLabel
@onready var extract_label: Label = $Center/ExtractLabel
@onready var banner_label: Label = $Center/Banner
@onready var extract_bar: ProgressBar = $Center/ExtractBar

var _banner_time: float = 0.0
var _dev_label: Label
var wave_director: Node = null
var _wood_at_start: int = 0
var _time_mark: float = 0.0


func _ready() -> void:
	GameState.hp_changed.connect(_on_hp)
	GameState.xp_changed.connect(_on_xp)
	GameState.inventory_changed.connect(_on_inv)
	GameState.wave_changed.connect(_on_wave)
	GameState.boss_hp_changed.connect(_on_boss)
	GameState.extract_available_changed.connect(_on_extract)
	GameState.dash_changed.connect(_on_dash)
	GameState.upgrades_changed.connect(_on_upgrades)
	boss_bar.visible = false
	boss_label.visible = false
	extract_label.visible = false
	extract_bar.visible = false
	banner_label.visible = false
	_on_hp(GameState.hp, GameState.max_hp)
	_on_xp(GameState.xp, GameState.xp_to_next(), GameState.level)
	_on_inv(GameState.wood, GameState.stone, GameState.berries)
	_on_dash(GameState.dash_charges, GameState.dash_max_charges, GameState.dash_cooldown)
	_refresh_weapons()
	_wood_at_start = GameState.wood
	_time_mark = Time.get_ticks_msec() / 1000.0
	_dev_label = Label.new()
	_dev_label.name = "DevOverlay"
	_dev_label.visible = DebugBalance.show_dev_overlay
	_dev_label.position = Vector2(16, 210)
	_dev_label.add_theme_font_size_override("font_size", 13)
	_dev_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.75, 0.9))
	_dev_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dev_label)


func bind_wave_director(director: Node) -> void:
	wave_director = director


func _process(delta: float) -> void:
	if _banner_time > 0.0:
		_banner_time -= delta
		if _banner_time <= 0.0:
			banner_label.visible = false
	_update_dev_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		DebugBalance.show_dev_overlay = not DebugBalance.show_dev_overlay
		_dev_label.visible = DebugBalance.show_dev_overlay
		get_viewport().set_input_as_handled()


func _update_dev_overlay() -> void:
	if _dev_label == null or not _dev_label.visible:
		return
	var enemies := get_tree().get_nodes_in_group("enemies").size()
	var elapsed: float = maxf(0.01, GameState.time_alive)
	var wood_rate: float = GameState.wood / elapsed * 60.0
	var killed := 0.0
	var spawned := 0.0
	var budget := 0.0
	var phase_name := "?"
	if wave_director:
		killed = float(wave_director.get("killed_value"))
		spawned = float(wave_director.get("spawned_value"))
		budget = float(wave_director.get("budget_total"))
		var ph = wave_director.get("phase")
		phase_name = str(ph)
	_dev_label.text = "DEV  FPS %.0f | enemies %d | wave %d | phase %s\nbudget %.0f  killed/spawned %.0f/%.0f (%.0f%%)\nwood/min %.1f  dmg %.0f  lvl %d  breather %s" % [
		Engine.get_frames_per_second(),
		enemies,
		GameState.wave,
		phase_name,
		budget,
		killed,
		spawned,
		(100.0 * killed / maxf(1.0, spawned * 0.7)),
		wood_rate,
		GameState.damage_dealt,
		GameState.level,
		"Y" if GameState.in_breather else "N",
	]


func show_banner(text: String, duration: float = 2.0) -> void:
	banner_label.text = text
	banner_label.visible = true
	_banner_time = duration


func set_extract_progress(t: float) -> void:
	extract_bar.visible = t > 0.0 and GameState.extract_available
	extract_bar.value = t * 100.0


func _on_hp(cur: float, mx: float) -> void:
	hp_bar.max_value = mx
	hp_bar.value = cur


func _on_xp(cur: float, needed: float, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = cur
	level_label.text = "Lv %d" % level


func _on_inv(wood: int, stone: int, berries: int) -> void:
	resources.text = "Wood %d  Stone %d  Berries %d" % [wood, stone, berries]


func _on_wave(wave: int, progress: float) -> void:
	if wave <= 10:
		wave_label.text = "Wave %d / 10  (%d%%)" % [wave, int(progress * 100)]
	else:
		wave_label.text = "FINALE"


func _on_boss(cur: float, mx: float) -> void:
	boss_bar.visible = true
	boss_label.visible = true
	boss_bar.max_value = mx
	boss_bar.value = cur
	boss_label.text = "Bulldozer"


func _on_extract(available: bool) -> void:
	extract_label.visible = available
	extract_label.text = "→ Hold at DAM to extract" if available else ""


func _on_dash(charges: int, max_c: int, cd: float) -> void:
	if charges >= max_c:
		dash_label.text = "Dash ready (%d/%d)" % [charges, max_c]
	else:
		dash_label.text = "Dash %d/%d  CD %.1fs" % [charges, max_c, cd]


func _on_upgrades(_owned: Array) -> void:
	_refresh_weapons()


func _refresh_weapons() -> void:
	var parts: PackedStringArray = []
	for w in GameState.owned_weapons:
		parts.append("%s r%d" % [w.capitalize(), int(GameState.weapon_ranks.get(w, 0))])
	weapons_label.text = "  ".join(parts)
