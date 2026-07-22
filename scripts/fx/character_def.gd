extends Resource
class_name CharacterDef
## Data for a playable/enemy visual: silhouette key + optional sprite sheet drop-in.

@export var id: String = ""
@export var display_name: String = ""
## Silhouettes builder key: beaver, hornet, rat, fox, drone, bulldozer
@export var silhouette_key: String = "hornet"
@export var sprite_dir: String = ""
@export var frame_size: Vector2i = Vector2i(48, 48)
@export var sheet_columns: int = 6
@export var visual_scale: float = 1.0
@export var elite_tint: Color = Color(1.15, 0.85, 0.75)
## Animation layout on the sheet: name -> { "row": int, "frames": int, "fps": float, "loop": bool }
@export var animations: Dictionary = {}


static func default_anims() -> Dictionary:
	return {
		"idle": {"row": 0, "frames": 4, "fps": 6.0, "loop": true},
		"run": {"row": 1, "frames": 6, "fps": 10.0, "loop": true},
		"dash": {"row": 2, "frames": 3, "fps": 14.0, "loop": false},
		"chew": {"row": 3, "frames": 4, "fps": 12.0, "loop": true},
		"attack": {"row": 4, "frames": 4, "fps": 14.0, "loop": false},
		"hit": {"row": 5, "frames": 2, "fps": 12.0, "loop": false},
		"death": {"row": 6, "frames": 4, "fps": 10.0, "loop": false},
		"telegraph": {"row": 7, "frames": 2, "fps": 8.0, "loop": true},
		"lunge": {"row": 8, "frames": 3, "fps": 14.0, "loop": false},
	}
