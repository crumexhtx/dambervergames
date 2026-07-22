extends CharacterBody2D
class_name Player
## Beaver player: move, dash, chew, vacuum, take contact damage.

signal died

@onready var body_visual: Node2D = $Body
@onready var hitbox: Area2D = $Hitbox
@onready var chew_area: Area2D = $ChewArea
@onready var pickup_area: Area2D = $PickupArea
@onready var weapon_manager: Node = $WeaponManager

var move_input: Vector2 = Vector2.ZERO
var last_move_dir: Vector2 = Vector2.RIGHT
var _iframe_timer: float = 0.0
var _dashing: bool = false
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _contact_tick: float = 0.0
var _thorns_tick: float = 0.0
var _decoy_timer: float = 0.0
var _anim: CharacterAnimator
var _chewing: bool = false
var _prev_hp: float = 100.0

const DASH_DURATION := 0.12


func _ready() -> void:
	add_to_group("player")
	if body_visual is Polygon2D:
		(body_visual as Polygon2D).polygon = PackedVector2Array()
		(body_visual as Polygon2D).color = Color(0, 0, 0, 0)
	if body_visual:
		for c in body_visual.get_children():
			c.queue_free()
		_anim = CharacterAnimator.new()
		_anim.name = "Anim"
		body_visual.add_child(_anim)
		_anim.setup("beaver")
	if has_node("Tail"):
		$Tail.visible = false
	_prev_hp = GameState.hp
	GameState.hp_changed.connect(_on_hp_changed)
	_update_pickup_radius()
	hitbox.body_entered.connect(_on_hitbox_body)
	hitbox.area_entered.connect(_on_hitbox_area)


func _physics_process(delta: float) -> void:
	if not GameState.run_active:
		return
	if GameState.soft_paused:
		velocity = Vector2.ZERO
		return

	GameState.time_alive += delta
	GameState.try_auto_berry()

	if GameState.dash_cooldown > 0.0 and GameState.dash_charges < GameState.dash_max_charges:
		GameState.dash_cooldown = maxf(0.0, GameState.dash_cooldown - delta)
		if GameState.dash_cooldown <= 0.0:
			GameState.dash_charges = mini(GameState.dash_max_charges, GameState.dash_charges + 1)
			if GameState.dash_charges < GameState.dash_max_charges:
				GameState.dash_cooldown = GameState.dash_cooldown_max
		GameState.dash_changed.emit(GameState.dash_charges, GameState.dash_max_charges, GameState.dash_cooldown)

	if _iframe_timer > 0.0:
		_iframe_timer -= delta
		body_visual.modulate.a = 0.5 if int(_iframe_timer * 20) % 2 == 0 else 1.0
	else:
		body_visual.modulate.a = 1.0

	if _dashing:
		_dash_timer -= delta
		velocity = _dash_dir * GameState.pixels(GameState.dash_distance) / DASH_DURATION
		if _dash_timer <= 0.0:
			_dashing = false
			if GameState.overbite_enabled:
				_overbite_strike()
	else:
		var dir := move_input
		if dir.length() < 0.05:
			dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir.length() > 1.0:
			dir = dir.normalized()
		if dir.length() > 0.05:
			last_move_dir = dir.normalized()
		var spd := GameState.pixels(GameState.move_speed)
		spd = minf(spd, GameState.pixels(GameState.base_move_speed * 1.6))
		velocity = dir * spd

	_clamp_to_arena()
	move_and_slide()
	_chew_nearest(delta)
	_apply_thorns(delta)
	_tick_decoy(delta)
	_contact_enemies(delta)
	_update_anim()


func set_move_input(v: Vector2) -> void:
	move_input = v


func try_dash() -> void:
	if GameState.soft_paused or not GameState.run_active:
		return
	if _dashing or GameState.dash_charges <= 0:
		return
	GameState.dash_charges -= 1
	if GameState.dash_charges < GameState.dash_max_charges and GameState.dash_cooldown <= 0.0:
		GameState.dash_cooldown = GameState.dash_cooldown_max
	GameState.dash_changed.emit(GameState.dash_charges, GameState.dash_max_charges, GameState.dash_cooldown)
	_dashing = true
	_dash_timer = DASH_DURATION
	_dash_dir = last_move_dir if last_move_dir.length() > 0.1 else Vector2.RIGHT
	_iframe_timer = GameState.dash_iframes
	if _anim:
		_anim.play_oneshot("dash", DASH_DURATION + 0.05)
	Juice.shake(4.0, 0.08)


func play_attack_anim() -> void:
	if _anim:
		_anim.play_oneshot("attack", 0.28)


func _update_anim() -> void:
	if _anim == null:
		return
	_anim.set_facing_dir(last_move_dir)
	var max_spd := maxf(1.0, GameState.pixels(GameState.move_speed))
	_anim.set_speed_factor(0.0 if _dashing else velocity.length() / max_spd)
	_anim.set_chewing(_chewing)


func _on_hp_changed(hp: float, _max_hp: float) -> void:
	if hp < _prev_hp - 0.5 and _anim:
		_anim.play_oneshot("hit", 0.18)
	_prev_hp = hp


func _overbite_strike() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) <= GameState.pixels(1.2):
			if e.has_method("take_damage"):
				e.take_damage(25.0 * GameState.global_damage * DebugBalance.player_damage_mult, global_position)


func _clamp_to_arena() -> void:
	var half := GameState.pixels(GameState.ARENA_HALF)
	global_position.x = clampf(global_position.x, -half, half)
	global_position.y = clampf(global_position.y, -half, half)


func _update_pickup_radius() -> void:
	var r := GameState.pixels(GameState.pickup_radius)
	var shape := pickup_area.get_node("CollisionShape2D") as CollisionShape2D
	if shape and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = r


func refresh_pickup_radius() -> void:
	_update_pickup_radius()


func _chew_nearest(delta: float) -> void:
	var best: Node2D = null
	var best_d := GameState.pixels(1.5)
	for n in get_tree().get_nodes_in_group("loot_nodes"):
		if not is_instance_valid(n):
			continue
		var d := global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	_chewing = best != null
	if best and best.has_method("receive_chew"):
		best.receive_chew(GameState.chew_dps * delta)


func _apply_thorns(delta: float) -> void:
	if GameState.thorns_dps <= 0.0:
		return
	_thorns_tick += delta
	if _thorns_tick < 0.5:
		return
	_thorns_tick = 0.0
	var r := GameState.pixels(1.0)
	# thorns_dps stores damage-per-tick (8 every 0.5s), not DPS
	var tick_dmg := GameState.thorns_dps * GameState.global_damage * DebugBalance.player_damage_mult
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) <= r and e.has_method("take_damage"):
			e.take_damage(tick_dmg, global_position)


func _tick_decoy(delta: float) -> void:
	if not GameState.decoy_enabled:
		return
	_decoy_timer -= delta
	if _decoy_timer > 0.0:
		return
	_decoy_timer = 12.0
	var decoy := get_tree().current_scene.get_node_or_null("World/Decoy")
	if decoy == null:
		decoy = Node2D.new()
		decoy.name = "Decoy"
		decoy.add_to_group("decoy")
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(10, 12), Vector2(-10, 12)])
		poly.color = Color(0.55, 0.35, 0.15, 0.85)
		decoy.add_child(poly)
		var world := get_tree().current_scene.get_node_or_null("World")
		if world:
			world.add_child(decoy)
	decoy.global_position = global_position + last_move_dir * 40.0
	decoy.visible = true
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(decoy):
			decoy.visible = false
	)


func _contact_enemies(delta: float) -> void:
	if _iframe_timer > 0.0:
		return
	_contact_tick += delta
	if _contact_tick < 0.5:
		return
	var hit := false
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("get_contact_damage"):
			GameState.take_damage(body.get_contact_damage() * DebugBalance.dmg_mult)
			hit = true
	for area in hitbox.get_overlapping_areas():
		if area.is_in_group("enemy_hurt") and area.get_parent().has_method("get_contact_damage"):
			GameState.take_damage(area.get_parent().get_contact_damage() * DebugBalance.dmg_mult)
			hit = true
	if hit:
		_contact_tick = 0.0
		Juice.shake(5.0, 0.1)
		Juice.play_sfx("hurt")


func _on_hitbox_body(_body: Node) -> void:
	pass


func _on_hitbox_area(_area: Area2D) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		try_dash()
		get_viewport().set_input_as_handled()
