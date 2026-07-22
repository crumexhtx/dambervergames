extends Node
## Exposed tuning knobs for balance pass (§15).

var wave_budget_mult: float = 1.0
var hp_mult: float = 1.0
var dmg_mult: float = 1.0
var player_damage_mult: float = 1.0
var xp_mult: float = 1.0
var breather_duration: float = 2.5
var node_hp_mult: float = 1.0


func reset_defaults() -> void:
	wave_budget_mult = 1.0
	hp_mult = 1.0
	dmg_mult = 1.0
	player_damage_mult = 1.0
	xp_mult = 1.0
	breather_duration = 2.5
	node_hp_mult = 1.0
