extends Node2D
class_name CharacterAnimator
## Drives character visuals: articulated silhouettes by default, sprite sheets when present.
## States: idle, run, dash, chew, attack, hit, death, telegraph, lunge

signal oneshot_finished(state_name: String)

enum Mode { SILHOUETTE, SPRITE }

var def: CharacterDef
var mode: Mode = Mode.SILHOUETTE
var is_elite: bool = false

var _parts_root: Node2D
var _sprite: AnimatedSprite2D
var _state: String = "idle"
var _oneshot: String = ""
var _oneshot_t: float = 0.0
var _forced: String = ""
var _time: float = 0.0
var _facing: float = 1.0  # 1 = right, -1 = left
var _speed_factor: float = 0.0  # 0 idle .. 1 full run
var _chewing: bool = false
var _base_scales: Dictionary = {}
var _base_rots: Dictionary = {}
var _base_pos: Dictionary = {}


func setup(character_id: String, elite: bool = false) -> void:
	is_elite = elite
	def = CharacterCatalog.get_def(character_id)
	scale = Vector2.ONE * def.visual_scale
	_clear()
	if _try_load_sprites():
		mode = Mode.SPRITE
	else:
		mode = Mode.SILHOUETTE
		_build_silhouette()
	if is_elite:
		modulate = def.elite_tint
	else:
		modulate = Color.WHITE
	play("idle")


func _clear() -> void:
	while get_child_count() > 0:
		var c := get_child(0)
		remove_child(c)
		c.free()
	_parts_root = null
	_sprite = null
	_forced = ""
	_oneshot = ""
	_base_scales.clear()
	_base_rots.clear()
	_base_pos.clear()


func _build_silhouette() -> void:
	_parts_root = Node2D.new()
	_parts_root.name = "Parts"
	add_child(_parts_root)
	Silhouettes.build_articulated(_parts_root, def.silhouette_key, is_elite)
	_cache_part_bases(_parts_root)


func _cache_part_bases(node: Node) -> void:
	for c in node.get_children():
		if c is Node2D:
			var n := c as Node2D
			_base_scales[n.name] = n.scale
			_base_rots[n.name] = n.rotation
			_base_pos[n.name] = n.position
			_cache_part_bases(n)


func _try_load_sprites() -> bool:
	if def.sprite_dir.is_empty():
		return false
	var frames_path := def.sprite_dir.path_join("sprite_frames.tres")
	if ResourceLoader.exists(frames_path):
		var frames := load(frames_path) as SpriteFrames
		if frames:
			_sprite = AnimatedSprite2D.new()
			_sprite.sprite_frames = frames
			_sprite.name = "Sprite"
			add_child(_sprite)
			return true
	var sheet_path := def.sprite_dir.path_join("sheet.png")
	if not ResourceLoader.exists(sheet_path) and not FileAccess.file_exists(sheet_path):
		return false
	var tex := load(sheet_path) as Texture2D
	if tex == null:
		return false
	var frames := _slice_sheet(tex)
	if frames == null or frames.get_animation_names().is_empty():
		return false
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.name = "Sprite"
	_sprite.centered = true
	add_child(_sprite)
	return true


func _slice_sheet(tex: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var fw := def.frame_size.x
	var fh := def.frame_size.y
	var cols := maxi(1, def.sheet_columns)
	for anim_name in def.animations.keys():
		var info: Dictionary = def.animations[anim_name]
		var row: int = int(info.get("row", 0))
		var count: int = int(info.get("frames", 1))
		var fps: float = float(info.get("fps", 8.0))
		var loop: bool = bool(info.get("loop", true))
		if frames.has_animation(anim_name):
			frames.remove_animation(anim_name)
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, loop)
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * fw, row * fh, fw, fh)
			frames.add_frame(anim_name, atlas)
	return frames


func play(state_name: String, oneshot: bool = false, duration: float = 0.25) -> void:
	if oneshot:
		_oneshot = state_name
		_oneshot_t = duration
	else:
		if _oneshot != "" and state_name != "death":
			return
		_state = state_name
		if state_name == "death":
			_forced = "death"
	_apply_sprite_anim(state_name if oneshot else _state)


func force_state(state_name: String) -> void:
	_forced = state_name
	_state = state_name
	_oneshot = ""
	_apply_sprite_anim(state_name)


func clear_force() -> void:
	if _forced == "death":
		return
	_forced = ""


func play_oneshot(state_name: String, duration: float = 0.28) -> void:
	play(state_name, true, duration)


func set_facing_dir(dir: Vector2) -> void:
	if dir.length() < 0.08:
		return
	_facing = 1.0 if dir.x >= 0.0 else -1.0


func set_speed_factor(f: float) -> void:
	_speed_factor = clampf(f, 0.0, 1.0)


func set_chewing(active: bool) -> void:
	_chewing = active


func current_state() -> String:
	if _oneshot != "":
		return _oneshot
	if _forced != "":
		return _forced
	return _state


func _process(delta: float) -> void:
	_time += delta
	if _oneshot != "":
		_oneshot_t -= delta
		if _oneshot_t <= 0.0:
			var finished := _oneshot
			_oneshot = ""
			oneshot_finished.emit(finished)
			_apply_sprite_anim(_resolve_loco())
	elif _forced == "":
		var want := _resolve_loco()
		if want != _state and _state != "death":
			_state = want
			_apply_sprite_anim(_state)

	scale = Vector2(_facing * def.visual_scale, def.visual_scale)

	if mode == Mode.SILHOUETTE and _parts_root:
		_animate_silhouette(delta)


func _resolve_loco() -> String:
	if _forced != "":
		return _forced
	if _state == "death":
		return "death"
	if _chewing and _speed_factor < 0.15:
		return "chew"
	if _speed_factor > 0.15:
		return "run"
	return "idle"


func _apply_sprite_anim(anim_name: String) -> void:
	if mode != Mode.SPRITE or _sprite == null:
		return
	if not _sprite.sprite_frames.has_animation(anim_name):
		if _sprite.sprite_frames.has_animation("idle"):
			anim_name = "idle"
		else:
			return
	if _sprite.animation != anim_name or not _sprite.is_playing():
		_sprite.play(anim_name)


func _part(name: String) -> Node2D:
	if _parts_root == null:
		return null
	return _parts_root.find_child(name, true, false) as Node2D


func _reset_part(n: Node2D) -> void:
	if n == null:
		return
	if _base_pos.has(n.name):
		n.position = _base_pos[n.name]
	if _base_rots.has(n.name):
		n.rotation = _base_rots[n.name]
	if _base_scales.has(n.name):
		n.scale = _base_scales[n.name]


func _animate_silhouette(_delta: float) -> void:
	var st := current_state()
	var body := _part("body")
	var head := _part("head")
	var tail := _part("tail")
	var wing_l := _part("wing_l")
	var wing_r := _part("wing_r")
	var snout := _part("snout")
	var rotor_l := _part("rotor_l")
	var rotor_r := _part("rotor_r")
	var blade := _part("blade")

	for n in [body, head, tail, wing_l, wing_r, snout, rotor_l, rotor_r, blade]:
		_reset_part(n)

	match st:
		"idle":
			_bob(body, 1.6, 1.5)
			_sway(tail, 0.18, 2.2)
			_flap(wing_l, wing_r, 0.25, 8.0)
			_spin_rotors(rotor_l, rotor_r, 6.0)
		"run":
			var bounce := sin(_time * (10.0 + _speed_factor * 6.0)) * (2.0 + _speed_factor * 2.0)
			if body:
				body.position.y += bounce
				body.rotation = sin(_time * 9.0) * 0.08 * _speed_factor
			if head:
				head.position.y += bounce * 0.6
				head.rotation = -body.rotation * 0.5 if body else 0.0
			_sway(tail, 0.35, 9.0)
			_flap(wing_l, wing_r, 0.4, 14.0)
			_spin_rotors(rotor_l, rotor_r, 14.0)
		"dash":
			if body:
				body.scale = Vector2(1.35, 0.72)
				body.position.x += 4.0
			if head:
				head.position.x += 6.0
			if tail:
				tail.rotation = 0.55
				tail.scale = Vector2(0.85, 1.15)
		"chew":
			_bob(body, 1.0, 2.0)
			if head:
				head.rotation = sin(_time * 14.0) * 0.22
				head.position.y += sin(_time * 14.0) * 1.5
			if snout:
				snout.scale = Vector2(1.0 + sin(_time * 16.0) * 0.15, 1.0)
		"attack":
			if tail:
				tail.rotation = sin(_time * 28.0) * 0.9 - 0.4
				tail.scale = Vector2(1.2, 0.9)
			if body:
				body.rotation = -0.15
			if blade:
				blade.position.x += sin(_time * 20.0) * 6.0
		"hit":
			if body:
				body.position.x -= 3.0
				body.rotation = 0.2
			modulate = Color(1.4, 0.7, 0.7) if not is_elite else def.elite_tint * Color(1.3, 0.8, 0.8)
		"telegraph":
			if body:
				body.scale = Vector2(1.1, 0.9) * (1.0 + sin(_time * 12.0) * 0.05)
			modulate = Color(1.25, 1.05, 0.85)
		"lunge":
			if body:
				body.scale = Vector2(1.4, 0.7)
				body.position.x += 8.0
			if head:
				head.position.x += 4.0
		"death":
			if body:
				body.rotation = _time * 8.0
				body.scale = Vector2.ONE * maxf(0.15, 1.0 - _time * 0.8)
			modulate.a = maxf(0.0, 1.0 - _time * 0.9)
		_:
			_bob(body, 1.6, 1.5)

	if st != "hit" and st != "telegraph" and st != "death":
		modulate = def.elite_tint if is_elite else Color.WHITE


func _bob(n: Node2D, amp: float, hz: float) -> void:
	if n:
		n.position.y += sin(_time * hz * TAU * 0.5) * amp


func _sway(n: Node2D, amp: float, hz: float) -> void:
	if n:
		n.rotation += sin(_time * hz) * amp


func _flap(l: Node2D, r: Node2D, amp: float, hz: float) -> void:
	var a := sin(_time * hz) * amp
	if l:
		l.rotation = -0.3 + a
	if r:
		r.rotation = 0.3 - a


func _spin_rotors(l: Node2D, r: Node2D, hz: float) -> void:
	if l:
		l.rotation = _time * hz
	if r:
		r.rotation = -_time * hz
