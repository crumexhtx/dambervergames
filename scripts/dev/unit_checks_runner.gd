extends Node
## Run via: godot --headless --path . res://scenes/dev/unit_checks.tscn --quit-after 120


func _ready() -> void:
	var failed := 0
	failed += _check_upgrade_once()
	failed += _check_burr_wording()
	failed += _check_meta_roundtrip()
	failed += _check_abandon_banks()
	failed += _check_pickup_guard_exists()
	failed += _check_character_animator()
	if failed == 0:
		print("UNIT_CHECKS_OK")
		get_tree().quit(0)
	else:
		printerr("UNIT_CHECKS_FAILED count=", failed)
		get_tree().quit(1)


func _check_upgrade_once() -> int:
	GameState.start_run()
	GameState.thorns_dps = 8.0
	GameState.decoy_enabled = true
	GameState.overbite_enabled = true
	var offers := UpgradePool.roll_offers(3)
	for o in offers:
		if str(o.id) in ["RARE_THORN", "RARE_DECOY", "RARE_OVERBITE"]:
			printerr("FAIL: one-time rare still offered: ", o.id)
			return 1
	print("OK upgrade_once")
	return 0


func _check_burr_wording() -> int:
	for c in UpgradePool.CARDS:
		if c.id == "RARE_THORN":
			if "every 0.5s" not in str(c.desc):
				printerr("FAIL: Burr Coat desc unclear: ", c.desc)
				return 1
	print("OK burr_wording")
	return 0


func _check_meta_roundtrip() -> int:
	var before := MetaProgression.banked_wood
	MetaProgression.bank_wood(3)
	MetaProgression.save()
	MetaProgression.banked_wood = before
	MetaProgression.load_save()
	if MetaProgression.banked_wood < before + 3:
		printerr("FAIL: meta save/load wood")
		return 1
	print("OK meta_roundtrip")
	return 0


func _check_abandon_banks() -> int:
	GameState.start_run()
	GameState.wave = 7
	GameState.wood = 40
	var before := MetaProgression.banked_wood
	GameState.abandon_run()
	if MetaProgression.banked_wood < before + 10:
		printerr("FAIL: abandon partial bank expected +10")
		return 1
	if GameState.run_active:
		printerr("FAIL: run still active after abandon")
		return 1
	print("OK abandon_banks")
	return 0


func _check_pickup_guard_exists() -> int:
	# Source-level contract: pickup scripts expose _collected via script source
	var pickup_src := FileAccess.get_file_as_string("res://scripts/loot/pickup.gd")
	var gem_src := FileAccess.get_file_as_string("res://scripts/loot/xp_gem.gd")
	if "_collected" not in pickup_src or "_collected" not in gem_src:
		printerr("FAIL: missing _collected guard")
		return 1
	print("OK pickup_guard")
	return 0


func _check_character_animator() -> int:
	var def := CharacterCatalog.get_def("beaver")
	if def.silhouette_key != "beaver" or def.sprite_dir.is_empty():
		printerr("FAIL: beaver catalog def")
		return 1
	var host := Node2D.new()
	add_child(host)
	var anim := CharacterAnimator.new()
	host.add_child(anim)
	anim.setup("beaver")
	if anim.mode != CharacterAnimator.Mode.SILHOUETTE:
		printerr("FAIL: expected silhouette mode without sheet")
		return 1
	var body := anim.find_child("body", true, false)
	var head := anim.find_child("head", true, false)
	var tail := anim.find_child("tail", true, false)
	if body == null or head == null or tail == null:
		printerr("FAIL: beaver missing articulated parts")
		return 1
	anim.play_oneshot("attack", 0.1)
	anim.force_state("telegraph")
	anim.clear_force()
	anim.play("death")
	if anim.current_state() != "death":
		printerr("FAIL: death state not forced")
		return 1
	var fox_def := CharacterCatalog.get_def("fox")
	if fox_def.silhouette_key != "fox":
		printerr("FAIL: fox catalog")
		return 1
	print("OK character_animator")
	host.queue_free()
	return 0
