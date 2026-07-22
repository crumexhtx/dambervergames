extends RefCounted
class_name CharacterCatalog
## Built-in character defs. Drop sprite sheets under sprite_dir to override silhouettes.


static func get_def(character_id: String) -> CharacterDef:
	var d := CharacterDef.new()
	d.animations = CharacterDef.default_anims()
	match character_id:
		"beaver":
			d.id = "beaver"
			d.display_name = "Beaver"
			d.silhouette_key = "beaver"
			d.sprite_dir = "res://assets/sprites/characters/beaver"
			d.visual_scale = 1.0
		"hornet":
			d.id = "hornet"
			d.display_name = "Hornet"
			d.silhouette_key = "hornet"
			d.sprite_dir = "res://assets/sprites/characters/hornet"
			d.visual_scale = 1.0
		"rat", "flood_rat":
			d.id = "rat"
			d.display_name = "Flood Rat"
			d.silhouette_key = "rat"
			d.sprite_dir = "res://assets/sprites/characters/rat"
		"fox":
			d.id = "fox"
			d.display_name = "Fox"
			d.silhouette_key = "fox"
			d.sprite_dir = "res://assets/sprites/characters/fox"
		"drone", "logger_drone":
			d.id = "drone"
			d.display_name = "Logger Drone"
			d.silhouette_key = "drone"
			d.sprite_dir = "res://assets/sprites/characters/drone"
		"bulldozer":
			d.id = "bulldozer"
			d.display_name = "Bulldozer"
			d.silhouette_key = "bulldozer"
			d.sprite_dir = "res://assets/sprites/characters/bulldozer"
			d.frame_size = Vector2i(64, 64)
			d.visual_scale = 1.15
		_:
			d.id = character_id
			d.display_name = character_id.capitalize()
			d.silhouette_key = character_id
			d.sprite_dir = "res://assets/sprites/characters/%s" % character_id
	return d
