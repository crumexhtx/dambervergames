extends SceneTree

func _init() -> void:
	print("SMOKE_START")
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/run.tscn")
	if packed == null:
		printerr("FAIL load run.tscn")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	print("SMOKE_INSTANCED name=", scene.name)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var player := root.get_node_or_null("Run/World/Player")
	var enemies := root.get_node_or_null("Run/World/Enemies")
	print("SMOKE_PLAYER=", player != null)
	print("SMOKE_ENEMIES_ROOT=", enemies != null)
	if enemies:
		print("SMOKE_ENEMY_COUNT=", enemies.get_child_count())
	print("SMOKE_OK")
	quit(0)
